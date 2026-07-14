# Phase 1 sea-ice component: Pithan et al. (2016)-correct slab ice for the
# Larcform1 SCM, registered as `ice_model: "larcform1_ice"`.
#
# Adapted from ClimaCoupler.jl `src/Models/prescr_seaice.jl` (Apache 2.0; vendored
# copy in ../reference/prescr_seaice.jl). Same Holloway & Manabe (1971) slab energy
# equation, with the HadISST/ERA5 concentration machinery removed (the Pithan case
# is full ice cover with deterministic initial conditions):
#
#   (h ρ c) dT_bulk/dt = -F_turb + (1 - α) SW_d + ϵ (LW_d - σ T_sfc⁴) + F_conductive
#   F_conductive = k_ice (T_base - T_sfc) / h
#   T_sfc = clamp(2 T_bulk - T_base, T_sfc_min, T_freeze)
#
# Pithan protocol defaults (all overridable via `coupler_toml`, see
# Larcform1IceParameters): h = 1 m, z0m = z0b = 1e-3 m (intercomparison modal
# value), T_base = T_freeze = 271.35 K (ocean at the freezing point of sea water),
# initial T_sfc = 250 K (encoded as T_bulk = (T_sfc + T_base)/2).

import ClimaCore as CC
import ClimaTimeSteppers as CTS
import ClimaComms
import ClimaCoupler: Checkpointer, FluxCalculator, Interfacer, Utilities

struct Larcform1IceSimulation{P, I} <: Interfacer.AbstractSeaIceSimulation
    params::P
    integrator::I
end

Base.@kwdef struct Larcform1IceParameters{FT <: AbstractFloat}
    h::FT           # ice thickness [m]
    ρ::FT           # density of sea ice [kg / m3]
    c::FT           # specific heat of sea ice [J / kg / K]
    T_base::FT      # temperature of sea water at the ice base [K]
    z0m::FT         # roughness length for momentum [m]
    z0b::FT         # roughness length for tracers [m]
    T_freeze::FT    # freezing temperature of sea water [K]
    k_ice::FT       # thermal conductivity of sea ice [W / m / K]
    α::FT           # albedo of sea ice (irrelevant in polar night)
    ϵ::FT           # emissivity of sea ice
    σ::FT           # Stefan-Boltzmann constant [W / m2 / K4]
    T_sfc_min::FT   # minimum allowed surface temperature [K]
    T_sfc_init::FT  # initial surface temperature [K]
end

"""
    Larcform1IceParameters{FT}(coupled_param_dict)

Pithan et al. (2016) defaults, each overridable by adding the corresponding
`larcform1_ice_*` entry to a `coupler_toml` parameter file, e.g.

    [larcform1_ice_thickness]
    value = 1.5
    type = "float"

so calibration experiments can sweep ice parameters without code edits.
`T_base` defaults to `T_freeze` (Pithan: ocean at the freezing point).
"""
function Larcform1IceParameters{FT}(coupled_param_dict) where {FT}
    p(name, default) =
        haskey(coupled_param_dict.data, name) ? FT(coupled_param_dict[name]) :
        FT(default)
    T_freeze = p("larcform1_ice_freezing_temperature", 271.35)
    return Larcform1IceParameters{FT}(;
        h = p("larcform1_ice_thickness", 1),
        ρ = p("larcform1_ice_density", 900),
        c = p("larcform1_ice_specific_heat", 2100),
        T_base = p("larcform1_ice_base_temperature", T_freeze),
        z0m = p("larcform1_ice_roughness_momentum", 1e-3),
        z0b = p("larcform1_ice_roughness_buoyancy", 1e-3),
        T_freeze,
        k_ice = p("larcform1_ice_conductivity", 2),
        α = p("larcform1_ice_albedo", 0.65),
        ϵ = p("larcform1_ice_emissivity", 1),
        σ = coupled_param_dict["stefan_boltzmann_constant"],
        T_sfc_min = p("larcform1_ice_min_surface_temperature", 200),
        T_sfc_init = p("larcform1_ice_initial_surface_temperature", 250),
    )
end

function Interfacer.SeaIceSimulation(
    ::Type{FT},
    ::Val{:larcform1_ice};
    kwargs...,
) where {FT}
    return Larcform1IceSimulation(FT; kwargs...)
end

function Larcform1IceSimulation(
    ::Type{FT};
    tspan,
    dt,
    saveat,
    boundary_space,
    coupled_param_dict,
    thermo_params,
    stepper = CTS.RK4(),
    extra_kwargs...,
) where {FT}
    params = Larcform1IceParameters{FT}(coupled_param_dict)

    # Linear temperature profile through the ice: T_bulk = (T_sfc + T_base)/2
    T_bulk_init = (params.T_sfc_init + params.T_base) / 2
    Y = CC.Fields.FieldVector(T_bulk = ones(boundary_space) .* T_bulk_init)

    cache = (;
        F_turb_energy = CC.Fields.zeros(boundary_space),
        SW_d = CC.Fields.zeros(boundary_space),
        LW_d = CC.Fields.zeros(boundary_space),
        area_fraction = ones(boundary_space),
        dt = dt,
        thermo_params = thermo_params,
        dss_buffer = Utilities.init_dss_buffer(Y),
    )

    ode_algo = CTS.ExplicitAlgorithm(stepper)
    ode_function = CTS.ClimaODEFunction(
        T_exp! = larcform1_ice_rhs!,
        dss! = (Y, p, t) -> Utilities.apply_dss!(Y, p.dss_buffer),
    )
    if dt isa Number
        dt = Float64(dt)
        tspan = Float64.(tspan)
        saveat = Float64.(saveat)
    end

    problem = CTS.ODEProblem(ode_function, Y, tspan, (; cache..., params = params))
    integrator = CTS.init(problem, ode_algo; dt, saveat, adaptive = false)

    sim = Larcform1IceSimulation(params, integrator)
    Utilities.apply_dss!(sim.integrator.u, sim.integrator.p.dss_buffer)
    return sim
end

ice_surface_temperature(T_bulk, T_base, T_sfc_min, T_freeze) =
    clamp(2 * T_bulk - T_base, T_sfc_min, T_freeze)

function larcform1_ice_rhs!(dY, Y, p, t)
    (; k_ice, h, T_base, ρ, c, ϵ, α, T_freeze, σ, T_sfc_min) = p.params

    T_sfc = @. ice_surface_temperature(Y.T_bulk, T_base, T_sfc_min, T_freeze)
    F_conductive = @. k_ice / h * (T_base - T_sfc)

    rhs = @. (
        -p.F_turb_energy + (1 - α) * p.SW_d + ϵ * (p.LW_d - σ * T_sfc^4) +
        F_conductive
    ) / (h * ρ * c)

    # If tendencies lead to temperature above freezing, set temperature to freezing
    @. dY.T_bulk = min(rhs, (T_freeze - Y.T_bulk) / float(p.dt))
end

"""
    conductive_flux(sim::Larcform1IceSimulation)

Upward conductive flux through the ice [W / m2] at the current state. The full
time series is recoverable offline from the saved `integrator.sol` T_bulk history
(or from the atmos `ts` output): F_c = k_ice (T_base - T_sfc) / h.
"""
function conductive_flux(sim::Larcform1IceSimulation)
    (; k_ice, h, T_base, T_sfc_min, T_freeze) = sim.params
    return @. k_ice / h * (
        T_base - ice_surface_temperature(
            sim.integrator.u.T_bulk,
            T_base,
            T_sfc_min,
            T_freeze,
        )
    )
end

# extensions required by Interfacer
Interfacer.get_field(sim::Larcform1IceSimulation, ::Val{:area_fraction}) =
    sim.integrator.p.area_fraction
Interfacer.get_field(sim::Larcform1IceSimulation, ::Val{:ice_concentration}) =
    sim.integrator.p.area_fraction
Interfacer.get_field(sim::Larcform1IceSimulation, ::Val{:emissivity}) =
    sim.integrator.p.params.ϵ
Interfacer.get_field(sim::Larcform1IceSimulation, ::Val{:roughness_buoyancy}) =
    sim.integrator.p.params.z0b
Interfacer.get_field(sim::Larcform1IceSimulation, ::Val{:roughness_momentum}) =
    sim.integrator.p.params.z0m
Interfacer.get_field(
    sim::Larcform1IceSimulation,
    ::Union{Val{:surface_direct_albedo}, Val{:surface_diffuse_albedo}},
) = sim.integrator.p.params.α
Interfacer.get_field(sim::Larcform1IceSimulation, ::Val{:roughness_model}) = :constant
Interfacer.get_field(sim::Larcform1IceSimulation, ::Val{:surface_temperature}) =
    ice_surface_temperature.(
        sim.integrator.u.T_bulk,
        sim.integrator.p.params.T_base,
        sim.integrator.p.params.T_sfc_min,
        sim.integrator.p.params.T_freeze,
    )
Interfacer.get_field(sim::Larcform1IceSimulation, ::Val{:energy}) =
    sim.integrator.p.params.ρ .* sim.integrator.p.params.c .*
    sim.integrator.u.T_bulk .* sim.integrator.p.params.h

function Interfacer.update_field!(
    sim::Larcform1IceSimulation,
    ::Val{:area_fraction},
    field::CC.Fields.Field,
)
    sim.integrator.p.area_fraction .= field
    return nothing
end
function Interfacer.update_field!(sim::Larcform1IceSimulation, ::Val{:SW_d}, field)
    Interfacer.remap!(sim.integrator.p.SW_d, field)
end
function Interfacer.update_field!(sim::Larcform1IceSimulation, ::Val{:LW_d}, field)
    Interfacer.remap!(sim.integrator.p.LW_d, field)
end
function Interfacer.update_field!(
    sim::Larcform1IceSimulation,
    ::Val{:turbulent_energy_flux},
    field,
)
    Interfacer.remap!(sim.integrator.p.F_turb_energy, field)
end
Interfacer.update_field!(
    sim::Larcform1IceSimulation,
    ::Val{:turbulent_moisture_flux},
    field,
) = nothing

function FluxCalculator.update_turbulent_fluxes!(
    sim::Larcform1IceSimulation,
    fields::NamedTuple,
)
    Interfacer.update_field!(sim, Val(:turbulent_energy_flux), fields.F_lh .+ fields.F_sh)
    return nothing
end

Checkpointer.get_model_prog_state(sim::Larcform1IceSimulation) = sim.integrator.u
Checkpointer.get_model_cache(sim::Larcform1IceSimulation) = sim.integrator.p

function Checkpointer.restore_cache!(sim::Larcform1IceSimulation, new_cache)
    old_cache = Checkpointer.get_model_cache(sim)
    for p in propertynames(old_cache)
        if getproperty(old_cache, p) isa CC.Fields.Field
            ArrayType = ClimaComms.array_type(getproperty(old_cache, p))
            parent(getproperty(old_cache, p)) .=
                ArrayType(parent(getproperty(new_cache, p)))
        end
    end
end
