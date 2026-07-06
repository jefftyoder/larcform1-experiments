# 5-day verification pair for the uki_1 calibration.
#
# Runs two 5-day forward simulations on the calibration grid:
#   calibrated — final mean parameters from output/uki_1 (written to a toml here)
#   baseline   — stock v10 physics (original larcform1 toml: timescales 100/100)
#
# NB: the baseline MUST use the original ClimaAtmos toml, not the calibration
# base toml — the latter has the two timescales removed (duplicate-entry
# workaround) and would silently fall back to the ClimaParams defaults (10 s).
#
# Questions this answers (see lf1e-clw-calibration-1.md, EC-Earth record caveat):
#   1. hours 0-48: does the calibrated model reproduce EC-Earth's mixed-phase
#      profiles when run standalone?
#   2. days 3-5: does it glaciate like EC-Earth (liquid dies day 3) or hold
#      its supercooled liquid — and did the calibration change that behavior
#      relative to baseline?
#
# Usage (from the experiment dir):
#   julia -t 1 --project=. scripts/run_verification_pair.jl

import ClimaAtmos as CA
import JLD2
import EnsembleKalmanProcesses as EKP
import Random

const EXPERIMENT_DIR = dirname(@__DIR__)
const REPO_ROOT = dirname(dirname(EXPERIMENT_DIR))
const FORWARD_CONFIG = joinpath(EXPERIMENT_DIR, "configs", "forward_model.yml")
const CAL_BASE_TOML =
    joinpath(EXPERIMENT_DIR, "configs", "toml", "larcform1_calibration_base.toml")
const STOCK_TOML =
    joinpath(REPO_ROOT, "ClimaAtmos.jl", "toml", "larcform1_1M_prognostic_edmfx.toml")
const OUT = joinpath(EXPERIMENT_DIR, "output", "verify5d")

# Order must match the prior in run_calibration.jl
const PARAM_NAMES = [
    "sublimation_deposition_timescale",
    "condensation_evaporation_timescale",
    "cloud_liquid_water_specific_humidity_autoconversion_threshold",
    "snow_autoconversion_timescale",
    "Frostenberg2023_a_coefficient",
    "Frostenberg2023_b_coefficient",
]

function write_calibrated_toml()
    eki = JLD2.load_object(joinpath(EXPERIMENT_DIR, "output", "uki_1", "iteration_007", "eki_file.jld2"))
    prior = JLD2.load_object(joinpath(EXPERIMENT_DIR, "output", "uki_1", "iteration_001", "prior.jld2"))
    phi = EKP.get_ϕ_mean_final(prior, eki)
    path = joinpath(OUT, "calibrated_params.toml")
    open(path, "w") do io
        for (name, value) in zip(PARAM_NAMES, phi)
            println(io, "[", name, "]")
            println(io, "value = ", value)
            println(io, "type = \"float\"")
            println(io)
        end
    end
    @info "Calibrated final means" Dict(zip(PARAM_NAMES, phi))
    return path
end

function run_5day(name, tomls)
    Random.seed!(1234)
    config_dict = CA.load_yaml_file(FORWARD_CONFIG)
    config_dict["job_id"] = "lf1e_clw_cal_verify5d_" * name
    config_dict["t_end"] = "5days"
    config_dict["output_dir"] = joinpath(OUT, name)
    config_dict["dt_save_state_to_disk"] = "Inf"
    config_dict["toml"] = tomls
    simulation = CA.get_simulation(CA.AtmosConfig(config_dict))
    CA.solve_atmos!(simulation)
    return nothing
end

mkpath(OUT)
calibrated_params = write_calibrated_toml()
@info "Running 5-day calibrated"
run_5day("calibrated", [CAL_BASE_TOML, calibrated_params])
@info "Running 5-day baseline"
run_5day("baseline", [STOCK_TOML])
@info "Verification pair complete" output = OUT
