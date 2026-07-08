# 20-day calibrated Larcform1 run (lf1e-20day-1).
#
# Runs the calibrated model (uki_1 final means on the s11 grid) for the full
# 20-day Pithan 2016 record length. Modeled on
# "experiments/clw calibration/scripts/run_verification_pair.jl" but a single
# standalone forward run.
#
# ENVIRONMENT MATTERS: must run with the clw-calibration project — it devs the
# vendored CloudMicrophysics.jl where Frostenberg2023_a/b are wired in. The
# ClimaAtmos.jl/.buildkite Manifest resolves REGISTERED CloudMicrophysics 0.36,
# where those calibrated coefficients are silently dead (verified 2026-07-06:
# same config there gives day-2 clwvi 0.166 vs 0.078, glaciation h76 vs h55).
#
# NB: configs/toml/calibrated_params.toml carries only the six calibrated
# parameters; everything else comes from the calibration base toml, which has
# the two relaxation timescales removed (duplicate-entry workaround) — the
# calibrated toml MUST therefore be listed after it, and the stock larcform1
# toml must NOT be used underneath (same trap as the verification baseline).
#
# Usage (from repo root):
#   julia -t 1 --project="experiments/clw calibration" "experiments/20day run/run_20day.jl"

import ClimaComms
ClimaComms.@import_required_backends
import ClimaAtmos as CA
import Random
Random.seed!(1234)

const EXPERIMENT_DIR = @__DIR__
const REPO_ROOT = dirname(dirname(EXPERIMENT_DIR))
const CONFIG = joinpath(EXPERIMENT_DIR, "configs", "lf1e_20day_calibrated.yml")
const CAL_BASE_TOML = joinpath(REPO_ROOT, "experiments", "clw calibration",
    "configs", "toml", "larcform1_calibration_base.toml")
const CALIBRATED_TOML =
    joinpath(EXPERIMENT_DIR, "configs", "toml", "calibrated_params.toml")

config_dict = CA.load_yaml_file(CONFIG)
config_dict["toml"] = [CAL_BASE_TOML, CALIBRATED_TOML]
config_dict["output_dir"] = joinpath(EXPERIMENT_DIR, "output", "calibrated")

t0 = time()
simulation = CA.get_simulation(CA.AtmosConfig(config_dict))
sol_res = CA.solve_atmos!(simulation)
walltime = round(time() - t0, digits = 1)
@info "20-day run finished" ret_code = sol_res.ret_code walltime
sol_res.ret_code == :success || exit(1)
