# Phase 2 sea-ice component: ClimaSeaIce slab ice + optional snow for the
# Larcform1 SCM, registered as `ice_model: "clima_seaice_column"`.
#
# A thermodynamics-only `ClimaSeaIce.SeaIceModel` on a single-point Oceananigans
# grid, bypassing ClimaOcean (Pithan prescribes the ocean at the freezing point,
# so no ocean model is needed: the ice bottom boundary is `PrescribedTemperature`
# and the ocean heat flux is a constant, default 0). Coupler-facing methods are
# adapted from ClimaCoupler's CMIP extension `clima_seaice.jl` (Apache 2.0;
# vendored copy in ../reference/clima_seaice.jl), with the spectral↔Oceananigans
# remapping replaced by trivial point-value copies.
#
# Surface energy balance: the model's external top heat flux is a temperature-
# dependent `FluxFunction`
#
#   Q_top(T_sfc) = ϵ σ T_sfc⁴ − (1 − α) SW_d − ϵ LW_d + F_turb     [+ up]
#
# whose SW_d/LW_d/F_turb values the coupler refreshes every coupling step
# (radiation via `update_field!`, turbulent flux via `update_turbulent_fluxes!`,
# both evaluated by the coupler at the previous step's T_sfc — explicit lagged
# coupling, fine at dt_cpl = 30 s). ClimaSeaIce's `MeltingConstrainedFluxBalance`
# then solves Q_top(T) = Q_conductive(T) for the new T_sfc with the snow+ice
# resistors-in-series conductance, caps it at melting, and converts any residual
# flux into snow/ice melt; bottom growth follows from conduction minus the ocean
# heat flux. Snow accumulates from the coupler's snowfall (sign flipped), and
# snow→ice flooding conserves mass.
#
# Snow on/off is a TOML switch (`seaice_column_enable_snow`); Pithan initial
# conditions are 1 m ice + 0.1 m water-equivalent snow at T_sfc = 250 K.
# ClimaSeaIce works in Celsius internally; all coupler-facing temperatures are
# Kelvin, converted with C_to_K = `temperature_water_freeze`.

import ClimaCore as CC
import Oceananigans as OC
import ClimaUtilities.TimeManager: ITime
import ClimaCoupler: FluxCalculator, Interfacer
using ClimaSeaIce:
    SeaIceModel,
    MeltingConstrainedFluxBalance,
    PrescribedTemperature,
    PhaseTransitions,
    ConductiveFlux,
    FluxFunction,
    SlabThermodynamics,
    snow_slab_thermodynamics

struct ClimaSeaIceColumnSimulation{M, P, F, A, H} <: Interfacer.AbstractSeaIceSimulation
    model::M            # ClimaSeaIce.SeaIceModel (thermodynamics only)
    params::P           # NamedTuple of coupler-facing parameters
    forcing::F          # NamedTuple of Refs shared with the model's top FluxFunction
    area_fraction::A    # ClimaCore field on the exchange (point) space
    model_Δt::Float64
    history::H          # per-coupled-step state records (in memory)
    flux_integral::Base.RefValue{Float64}  # ∫(Q_top − Q_ocean) dt   [J m⁻²]
    snow_integral::Base.RefValue{Float64}  # ∫ ℒ (−P_snow) ℵ dt      [J m⁻²]
end

function Interfacer.SeaIceSimulation(
    ::Type{FT},
    ::Val{:clima_seaice_column};
    kwargs...,
) where {FT}
    return ClimaSeaIceColumnSimulation(FT; kwargs...)
end

# Snow-off variant under its own `ice_model` name. A `coupler_toml` switch
# cannot do this under ClimaCoupler v0.2.2: `coupler_toml` *replaces* the atmos
# `toml` list (ClimaCouplerClimaAtmosExt), and its entries are merged into the
# atmos parameter dict, whose strict unused-parameter check runs before any
# surface component reads its parameters — so a surface-only TOML entry aborts
# the run. TODO: report upstream alongside #1860.
function Interfacer.SeaIceSimulation(
    ::Type{FT},
    ::Val{:clima_seaice_column_nosnow};
    kwargs...,
) where {FT}
    return ClimaSeaIceColumnSimulation(FT; force_enable_snow = false, kwargs...)
end

# The top FluxFunction kernel: net upward atmospheric flux at snow/ice surface
# temperature Tu (Celsius). Forcing values live in Refs the coupler mutates.
@inline function _column_top_heat_flux(i, j, grid, Tu, clock, fields, p)
    T_K = Tu + p.C_to_K
    return p.ϵ * p.σ * T_K^4 - (1 - p.α) * p.SW_d[] - p.ϵ * p.LW_d[] + p.F_turb[]
end

"""
    ClimaSeaIceColumnSimulation(FT; ...)

Pithan et al. (2016) defaults, each overridable by adding the corresponding
`seaice_column_*` entry to a `coupler_toml` parameter file, e.g.

    [seaice_column_enable_snow]
    value = false
    type = "bool"

Parameters (TOML name → default): ice_thickness → 1 m, snow_water_equivalent →
0.1 m, enable_snow → true, ice_conductivity → 2, snow_conductivity → 0.31,
ice_density → 900, snow_density → 330, roughness_momentum/buoyancy → 1e-3 m,
albedo → 0.65, emissivity → 1, base_temperature → 271.35 K (ocean at the
freezing point of sea water), ocean_heat_flux → 0 W m⁻²,
initial_surface_temperature → 250 K.
"""
function ClimaSeaIceColumnSimulation(
    ::Type{FT};
    boundary_space,
    coupled_param_dict,
    dt,
    force_enable_snow = nothing,
    extra_kwargs...,
) where {FT}
    # The ice model runs internally in Float64 regardless of the exchange float
    # type: at dt = 30 s the per-step thickness increment (~1e-6 m on h ~ 1 m)
    # is only ~10x Float32 eps, and the accumulated roundoff breaks energy
    # conservation at the percent level. Coupler-facing getters convert to FT.
    p(name, default) =
        Float64(
            haskey(coupled_param_dict.data, "seaice_column_$name") ?
            coupled_param_dict["seaice_column_$name"] : default,
        )
    C_to_K = Float64(coupled_param_dict["temperature_water_freeze"])
    σ = Float64(coupled_param_dict["stefan_boltzmann_constant"])

    enable_snow =
        isnothing(force_enable_snow) ?
        Bool(
            haskey(coupled_param_dict.data, "seaice_column_enable_snow") ?
            coupled_param_dict["seaice_column_enable_snow"] : true,
        ) : Bool(force_enable_snow)
    k_ice = p("ice_conductivity", 2)
    k_snow = p("snow_conductivity", 0.31)
    ρ_ice = p("ice_density", 900)
    ρ_snow = p("snow_density", 330)
    ρ_water = p("water_density", 1025)  # sea water: sets flotation/flooding
    α = p("albedo", 0.65)
    ϵ = p("emissivity", 1)
    T_bottom_C = p("base_temperature", 271.35) - C_to_K
    Q_ocean = p("ocean_heat_flux", 0)
    h_ice_init = p("ice_thickness", 1)
    swe_init = p("snow_water_equivalent", 0.1)
    T_sfc_init_C = p("initial_surface_temperature", 250) - C_to_K

    params = (;
        FT,
        z0m = FT(p("roughness_momentum", 1e-3)),
        z0b = FT(p("roughness_buoyancy", 1e-3)),
        α,
        ϵ,
        σ,
        C_to_K,
        Q_ocean,
        ρ_ice,
        ρ_snow,
    )

    forcing = (;
        SW_d = Ref(0.0),
        LW_d = Ref(0.0),
        F_turb = Ref(0.0),
        σ,
        ϵ,
        α,
        C_to_K,
    )

    grid = OC.RectilinearGrid(Float64; size = (), topology = (OC.Flat, OC.Flat, OC.Flat))

    ice_thermodynamics = SlabThermodynamics(
        grid;
        top_heat_boundary_condition = MeltingConstrainedFluxBalance(),
        bottom_heat_boundary_condition = PrescribedTemperature(T_bottom_C),
        internal_heat_flux = ConductiveFlux(Float64; conductivity = k_ice),
    )
    snow_thermodynamics =
        enable_snow ?
        snow_slab_thermodynamics(
            grid;
            conductivity = k_snow,
            top_heat_boundary_condition = MeltingConstrainedFluxBalance(),
        ) : nothing

    top_heat_flux = FluxFunction(
        _column_top_heat_flux;
        parameters = forcing,
        top_temperature_dependent = true,
    )
    # Snowfall must be a writable Field (the default `snowfall = 0` is constant)
    snowfall = OC.Field{OC.Center, OC.Center, Nothing}(grid)

    model = SeaIceModel(
        grid;
        ice_thermodynamics,
        snow_thermodynamics,
        timestepper = :ForwardEuler,
        sea_ice_density = ρ_ice,
        snow_density = ρ_snow,
        # liquid_density sets flotation: with the fresh-water default (999.8),
        # 1 m ice + 0.1 m w.e. snow sits exactly at the flooding threshold and
        # snow-ice formation activates immediately; sea water gives freeboard.
        # The heat capacities set the latent heat's temperature dependence
        # ℒ(T) = ℒ₀ + (ρℓcℓ/ρᵢ − cᵢ)(T − T₀) (Stefan correction); setting
        # cℓ = cᵢρᵢ/ρℓ makes ℒ constant, in which case conservation_report's
        # residual drops to machine precision (used by the component test).
        phase_transitions = PhaseTransitions(
            Float64;
            liquid_density = ρ_water,
            heat_capacity = p("ice_heat_capacity", 2000),
            liquid_heat_capacity = p("liquid_heat_capacity", 4186),
            reference_latent_heat = p("latent_heat_fusion", 334e3),
        ),
        top_heat_flux,
        bottom_heat_flux = Q_ocean,
        snowfall,
    )

    # Pithan initial conditions: full cover, 1 m ice, 0.1 m w.e. snow, T_sfc = 250 K
    OC.set!(model, h = h_ice_init, ℵ = 1)
    hs_init = 0.0
    if enable_snow
        hs_init = swe_init * 1000.0 / ρ_snow  # water equivalent → snow depth
        OC.set!(model.snow_thickness, hs_init)
    end
    top_thermo = _top_thermodynamics(model)
    OC.set!(top_thermo.top_surface_temperature, T_sfc_init_C)
    if enable_snow
        # Snow-ice interface temperature consistent with the initial linear profile
        R_ice = h_ice_init / k_ice
        R_snow = hs_init / k_snow
        T_si = T_bottom_C + (T_sfc_init_C - T_bottom_C) * R_ice / (R_ice + R_snow)
        OC.set!(model.ice_thermodynamics.top_surface_temperature, T_si)
    end

    sim = ClimaSeaIceColumnSimulation(
        model,
        params,
        forcing,
        ones(boundary_space),
        Float64(float(dt)),
        NamedTuple[],
        Ref(0.0),
        Ref(0.0),
    )
    @info "ClimaSeaIceColumnSimulation initialized" enable_snow h_ice_init hs_init T_sfc_init_C T_bottom_C Q_ocean
    push!(sim.history, _column_state(sim))
    return sim
end

_top_thermodynamics(model) =
    isnothing(model.snow_thermodynamics) ? model.ice_thermodynamics :
    model.snow_thermodynamics

# Point-value accessors (single-point grid ⇒ every field has one interior value)
_point(f) = first(OC.interior(f))
_point(x::Number) = x
# Exchange-space (PointSpace) fields and their broadcasts also hold one value
_point(f::CC.Fields.Field) = first(parent(f))

_T_sfc_K(sim) = _point(_top_thermodynamics(sim.model).top_surface_temperature) + sim.params.C_to_K

function _column_state(sim)
    model = sim.model
    hs = isnothing(model.snow_thickness) ? zero(Float64) : Float64(_point(model.snow_thickness))
    return (;
        t = Float64(model.clock.time),
        h_ice = Float64(_point(model.ice_thickness)),
        h_snow = hs,
        concentration = Float64(_point(model.ice_concentration)),
        T_sfc = Float64(_T_sfc_K(sim)),
        Q_top = Float64(_current_top_flux(sim)),
        E = latent_energy(sim),
    )
end

# Evaluate the top-flux formula at the current (solved) surface temperature —
# identical to the kernel's `getflux` evaluation, since Q_top depends only on
# T_sfc and the forcing Refs.
function _current_top_flux(sim)
    p = sim.forcing
    T_C = _point(_top_thermodynamics(sim.model).top_surface_temperature)
    return _column_top_heat_flux(1, 1, sim.model.grid, T_C, nothing, nothing, p)
end

"""
    latent_energy(sim::ClimaSeaIceColumnSimulation)

Latent energy content of the column relative to liquid water [J m⁻²]:
E = −ℒ (ρᵢ hᵢ + ρₛ hₛ) ℵ. Together with the accumulated flux and snowfall
integrals this gives the conservation check ΔE = −∫(Q_top − Q_ocean) dt + ∫ℒ(−P_snow)ℵ dt
(slab thermodynamics carry no sensible heat content).
"""
function latent_energy(sim::ClimaSeaIceColumnSimulation)
    model = sim.model
    ℒ = model.phase_transitions.reference_latent_heat
    ℵ = _point(model.ice_concentration)
    E_ice = sim.params.ρ_ice * ℒ * _point(model.ice_thickness) * ℵ
    E_snow =
        isnothing(model.snow_thickness) ? zero(E_ice) :
        sim.params.ρ_snow * ℒ * _point(model.snow_thickness) * ℵ
    return -Float64(E_ice + E_snow)
end

"""
    conservation_report(sim::ClimaSeaIceColumnSimulation)

Energy-conservation check. Freezing (net upward flux Q_top > Q_ocean) grows ice
volume and lowers the latent energy E = −ℒ(ρᵢhᵢ + ρₛhₛ)ℵ; snowfall adds frozen
mass and also lowers E. So

    ΔE = −∫(Q_top − Q_ocean) dt − ∫ ℒ snowfall ℵ dt

Return `(; ΔE, expected, residual)`. With the default `PhaseTransitions` the
latent heat is temperature-dependent (Stefan correction), so this ρℒ₀V-based
accounting carries an expected residual of order (ρℓcℓ/ρᵢ − cᵢ)ΔT/ℒ₀ ≈ 1%.
Overriding `seaice_column_liquid_heat_capacity = cᵢρᵢ/ρℓ` makes ℒ constant and
the residual drops to machine precision (the component-validation configuration,
per the NumericalEarth `coupled_conservation` demonstration).
"""
function conservation_report(sim::ClimaSeaIceColumnSimulation)
    ΔE = latent_energy(sim) - sim.history[1].E
    expected = -sim.flux_integral[] - sim.snow_integral[]
    return (; ΔE, expected, residual = ΔE - expected)
end

###############################################################################
### Interfacer / FluxCalculator methods
###############################################################################

function _step_column!(sim::ClimaSeaIceColumnSimulation, t_target_s::Float64)
    model = sim.model
    ℒ = model.phase_transitions.reference_latent_heat
    n_steps = round(Int, (t_target_s - Float64(model.clock.time)) / sim.model_Δt)
    for _ in 1:n_steps
        OC.TimeSteppers.time_step!(model, sim.model_Δt)
        # Conservation bookkeeping: Q_top evaluated at the post-solve T_sfc is
        # exactly what the thermodynamic kernel used this step.
        ℵ = Float64(_point(model.ice_concentration))
        sim.flux_integral[] +=
            sim.model_Δt * (Float64(_current_top_flux(sim)) - Float64(sim.params.Q_ocean))
        # Snowfall only adds mass when the model carries a snow layer
        isnothing(model.snow_thermodynamics) || (
            sim.snow_integral[] +=
                sim.model_Δt * Float64(ℒ) * Float64(_point(model.snowfall)) * ℵ
        )
    end
    push!(sim.history, _column_state(sim))
    return nothing
end

Interfacer.step!(sim::ClimaSeaIceColumnSimulation, t::Float64) = _step_column!(sim, t)
Interfacer.step!(sim::ClimaSeaIceColumnSimulation, t::ITime) =
    _step_column!(sim, Float64(float(t)))

Interfacer.sim_dt(sim::ClimaSeaIceColumnSimulation) = sim.model_Δt
Interfacer.will_step(sim::ClimaSeaIceColumnSimulation, t) =
    (Float64(float(t)) - Float64(sim.model.clock.time)) >= sim.model_Δt

# Coupler-facing values are converted to the exchange float type FT (the ice
# model itself runs in Float64; see the constructor).
Interfacer.get_field(sim::ClimaSeaIceColumnSimulation, ::Val{:area_fraction}) =
    sim.area_fraction
Interfacer.get_field(sim::ClimaSeaIceColumnSimulation, ::Val{:ice_concentration}) =
    sim.params.FT(_point(sim.model.ice_concentration))
Interfacer.get_field(sim::ClimaSeaIceColumnSimulation, ::Val{:ice_thickness}) =
    sim.params.FT(_point(sim.model.ice_thickness))
Interfacer.get_field(sim::ClimaSeaIceColumnSimulation, ::Val{:snow_thickness}) =
    isnothing(sim.model.snow_thickness) ? zero(sim.params.FT) :
    sim.params.FT(_point(sim.model.snow_thickness))
Interfacer.get_field(sim::ClimaSeaIceColumnSimulation, ::Val{:emissivity}) =
    sim.params.FT(sim.params.ϵ)
Interfacer.get_field(sim::ClimaSeaIceColumnSimulation, ::Val{:height_disp}) =
    zero(sim.params.FT)
Interfacer.get_field(sim::ClimaSeaIceColumnSimulation, ::Val{:roughness_buoyancy}) =
    sim.params.z0b
Interfacer.get_field(sim::ClimaSeaIceColumnSimulation, ::Val{:roughness_momentum}) =
    sim.params.z0m
Interfacer.get_field(
    sim::ClimaSeaIceColumnSimulation,
    ::Union{Val{:surface_direct_albedo}, Val{:surface_diffuse_albedo}},
) = sim.params.FT(sim.params.α)
Interfacer.get_field(sim::ClimaSeaIceColumnSimulation, ::Val{:roughness_model}) = :constant
Interfacer.get_field(sim::ClimaSeaIceColumnSimulation, ::Val{:surface_temperature}) =
    sim.params.FT(_T_sfc_K(sim))
Interfacer.get_field(sim::ClimaSeaIceColumnSimulation, ::Val{:energy}) =
    latent_energy(sim)

function Interfacer.update_field!(
    sim::ClimaSeaIceColumnSimulation,
    ::Val{:area_fraction},
    field::CC.Fields.Field,
)
    sim.area_fraction .= field
    return nothing
end
function Interfacer.update_field!(sim::ClimaSeaIceColumnSimulation, ::Val{:SW_d}, field)
    sim.forcing.SW_d[] = Float64(_point(field))
    return nothing
end
function Interfacer.update_field!(sim::ClimaSeaIceColumnSimulation, ::Val{:LW_d}, field)
    sim.forcing.LW_d[] = Float64(_point(field))
    return nothing
end
function Interfacer.update_field!(
    sim::ClimaSeaIceColumnSimulation,
    ::Val{:turbulent_energy_flux},
    field,
)
    sim.forcing.F_turb[] = Float64(_point(field))
    return nothing
end
# Snowfall drives snow accumulation. Sign flip: the coupler provides snowfall as
# a negative (downward) surface mass flux; ClimaSeaIce expects a positive rate.
function Interfacer.update_field!(
    sim::ClimaSeaIceColumnSimulation,
    ::Val{:snow_precipitation},
    field,
)
    OC.set!(sim.model.snowfall, -Float64(_point(field)))
    return nothing
end
# Rain on ice/snow and sublimation mass loss are ignored, matching the upstream
# CMIP ClimaSeaIce component (constant-salinity ice, no melt-pond model).
Interfacer.update_field!(
    sim::ClimaSeaIceColumnSimulation,
    ::Val{:liquid_precipitation},
    field,
) = nothing
Interfacer.update_field!(
    sim::ClimaSeaIceColumnSimulation,
    ::Val{:turbulent_moisture_flux},
    field,
) = nothing

function FluxCalculator.update_turbulent_fluxes!(
    sim::ClimaSeaIceColumnSimulation,
    fields::NamedTuple,
)
    Interfacer.update_field!(sim, Val(:turbulent_energy_flux), fields.F_lh .+ fields.F_sh)
    return nothing
end
