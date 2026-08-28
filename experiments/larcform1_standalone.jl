# Larcform1 Standalone SCM — Script Interface
#
# Standalone ClimaAtmos single-column simulation for the Larcform1 Arctic
# boundary layer case (Pithan et al. 2016), using the script API rather than
# YAML configuration.
#
# Usage (from repo root):
#   julia +1.12 -t auto --project experiments/larcform1_standalone.jl
#
# Or interactively:
#   julia +1.12 -t auto --project
#   julia> include("experiments/larcform1_standalone.jl")

import ClimaAtmos as CA
import ClimaParams as CP
import Dates: DateTime

# ═══════════════════════════════════════════════════════════════════════════════
# Configuration — edit these for sensitivity experiments
# ═══════════════════════════════════════════════════════════════════════════════

const FT       = Float64
const DT       = 30            # timestep [s]
const T_END    = 20 * 86400    # integration length [s]  (20 days)
const DT_RAD   = 30            # radiation call frequency [s]
const JOB_ID   = "lf1_standalone"
const TOML_FILE = joinpath(pkgdir(CA), "toml",
                           "larcform1_1M_prognostic_edmfx.toml")

# ═══════════════════════════════════════════════════════════════════════════════
# Parameters (constructed first — needed by setup and model)
# ═══════════════════════════════════════════════════════════════════════════════

toml_dict = CP.create_toml_dict(FT; override_file = TOML_FILE)

params = CA.ClimaAtmosParameters(toml_dict;
    microphysics_model = CA.NonEquilibriumMicrophysics1M(),
)

# ═══════════════════════════════════════════════════════════════════════════════
# Grid
# ═══════════════════════════════════════════════════════════════════════════════

grid = CA.ColumnGrid(FT;
    z_elem = 90,
    z_max = 9000.0,
    z_stretch = true,
    dz_bottom = 20.0,
)

# ═══════════════════════════════════════════════════════════════════════════════
# Setup (initial conditions, surface conditions, forcings)
# ═══════════════════════════════════════════════════════════════════════════════

setup = CA.Setups.Larcform1(;
    prognostic_tke = true,
    thermo_params = params.thermodynamics_params,
)

# The script interface does NOT auto-wire surface_condition or coriolis_forcing
# from the setup (unlike the config path). Extract and pass them explicitly.
sfc = CA.Setups.surface_condition(setup, params)
cor = CA.Setups.coriolis_forcing(setup, FT)

# ═══════════════════════════════════════════════════════════════════════════════
# Model
# ═══════════════════════════════════════════════════════════════════════════════

model = CA.AtmosModel(;
    # Turbulence — eddy-diffusivity only (no mass-flux updrafts)
    turbconv_model = CA.EDOnlyEDMFX(),
    edmfx_model = CA.EDMFXModel(;
        entr_model = CA.InvZEntrainment(),
        detr_model = nothing,
        sgs_mass_flux = true,
        sgs_diffusive_flux = true,
        nh_pressure = true,
        vertical_diffusion = true,
        filter = true,
        scale_blending_method = CA.SmoothMinimumBlending(),
    ),
    # Radiation — RRTMGP all-sky with clear-sky diagnostics
    radiation_mode = CA.RRTMGPI.AllSkyRadiationWithClearSkyDiagnostics(),
    insolation = CA.Larcform1Insolation(),
    # Moisture — 1-moment non-equilibrium microphysics, quadrature clouds
    cloud_model = CA.QuadratureCloud(),
    microphysics_model = CA.NonEquilibriumMicrophysics1M(),
    microphysics_tendency_timestepping = CA.Implicit(),
    # Sponge
    rayleigh_sponge = CA.RayleighSponge(params),
    # Numerics
    diff_mode = CA.Explicit(),
    # Surface — from setup: MoninObukhov z₀=1e-3, T_sfc=250K, boundary overrides
    flux_scheme = sfc.flux_scheme,
    temperature = sfc.temperature,
    boundary_overrides = sfc.overrides,
    # SCM forcing — geostrophic wind + Coriolis
    scm_coriolis = cor,
    # Top-level
    disable_surface_flux_tendency = false,
)

# ═══════════════════════════════════════════════════════════════════════════════
# Diagnostics
# ═══════════════════════════════════════════════════════════════════════════════

diagnostics = CA.DiagnosticsConfig(;
    default = false,
    output_at_levels = true,
    additional = [
        Dict("short_name" => ["ta", "thetaa", "pfull", "rhoa", "hus", "hur", "ts", "tas"],
             "period" => "1hours", "reduction_time" => "average"),
        Dict("short_name" => ["ua", "va", "wa"],
             "period" => "1hours", "reduction_time" => "average"),
        Dict("short_name" => ["cl", "clw", "cli", "lwp", "clivi"],
             "period" => "1hours", "reduction_time" => "average"),
        Dict("short_name" => ["rlu", "rld", "rlut", "rlus", "rlds", "rsdt", "rlutcs", "rldscs"],
             "period" => "1hours", "reduction_time" => "average"),
        Dict("short_name" => ["pr", "prsn", "evspsbl", "husra", "hussn"],
             "period" => "1hours", "reduction_time" => "average"),
        Dict("short_name" => ["hfss", "hfls"],
             "period" => "1hours", "reduction_time" => "average"),
        Dict("short_name" => ["tke", "lmix", "bgrad", "strain", "edt", "evu"],
             "period" => "10mins", "reduction_time" => "average"),
    ],
)

# ═══════════════════════════════════════════════════════════════════════════════
# Simulation
# ═══════════════════════════════════════════════════════════════════════════════

simulation = CA.AtmosSimulation{FT}(;
    model,
    params,
    grid,
    setup,
    dt = DT,
    t_end = T_END,
    start_date = DateTime(2001, 1, 1),
    job_id = JOB_ID,
    checkpoint_frequency = 90 * 86400,
    log_to_file = true,
    diagnostics,
    callback_kwargs = (; dt_rad = DT_RAD),
    jacobian = CA.ManualSparseJacobian(approximate_solve_iters = 2),
    verbose = true,
)

# ═══════════════════════════════════════════════════════════════════════════════
# Run
# ═══════════════════════════════════════════════════════════════════════════════

@info "Beginning standalone Larcform1 simulation" job_id=JOB_ID dt=DT t_end=T_END
@time sol = CA.solve_atmos!(simulation)
@info "Simulation complete" output_dir=simulation.output_dir

# ═══════════════════════════════════════════════════════════════════════════════
# Postprocessing
# ═══════════════════════════════════════════════════════════════════════════════

@info "Beginning postprocessing"
atmos_output_dir = simulation.output_dir
atmospath = pkgdir(CA)
postprocess_script = joinpath(@__DIR__, "..", "postprocessing", "postprocess.jl")
run(`julia --project=$(joinpath(atmospath, ".buildkite")) $postprocess_script $atmos_output_dir`)
