# lf1e clw calibration — UKI driver
#
# Usage (from repo root):
#   julia -t 1 --project="experiments/clw calibration" \
#       "experiments/clw calibration/run_calibration.jl" [n_iterations] [run_name]
#
# Defaults: n_iterations = 6, run_name = "uki_1".
# Output lands in experiments/clw calibration/output/<run_name>/.
#
# Calibrates 6 microphysics parameters against EC-Earth day-2 clw/cli profiles
# (log10, 995-905 hPa) with TransformUnscented (UKI): 2n+1 = 13 members per
# iteration, run sequentially in-process (JuliaBackend — JIT is paid once).
# The Frostenberg a/b coefficients are live only through the vendored
# CloudMicrophysics patch (see Project.toml [sources] and the experiment md).

import ClimaCalibrate
import EnsembleKalmanProcesses as EKP
import EnsembleKalmanProcesses.ParameterDistributions as PD
import Random

include(joinpath(@__DIR__, "model_interface.jl"))

n_iterations = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 6
run_name = length(ARGS) >= 2 ? ARGS[2] : "uki_1"

output_dir = joinpath(EXPERIMENT_DIR, "output", run_name)
mkpath(output_dir)
interface = Larcform1CalibrationInterface(FORWARD_CONFIG, output_dir)

observation = load_ecearth_observation()

# Priors centered on the current configuration's values (the two timescales are
# 100 in the original larcform1 toml; the autoconversion pair are ClimaParams
# defaults). Rationale in lf1e-clw-calibration-1.md.
priors = [
    PD.constrained_gaussian("sublimation_deposition_timescale", 100.0, 100.0, 1.0, Inf),
    PD.constrained_gaussian("condensation_evaporation_timescale", 100.0, 100.0, 1.0, Inf),
    PD.constrained_gaussian(
        "cloud_liquid_water_specific_humidity_autoconversion_threshold",
        5e-4,
        4e-4,
        1e-6,
        Inf,
    ),
    PD.constrained_gaussian("snow_autoconversion_timescale", 100.0, 100.0, 1.0, Inf),
    # INP curve (patched CloudMicrophysics): INPC = (-b·T_c/10)^9 / a.
    # a: concentration divisor — wide, INPC uncertainty is order-of-magnitude
    # (paper lognormal σ = 1.37 ≈ factor 4). b: temperature rescale — tight,
    # the ^9 amplifies it (b = 1.2 → ×5 INPC).
    PD.constrained_gaussian("Frostenberg2023_a_coefficient", 1.0, 2.0, 1e-3, Inf),
    PD.constrained_gaussian("Frostenberg2023_b_coefficient", 1.0, 0.2, 0.3, 3.0),
]
prior = EKP.combine_distributions(priors)

rng = Random.MersenneTwister(1234)
ekp = EKP.EnsembleKalmanProcess(
    observation,
    EKP.TransformUnscented(prior, impose_prior = true);
    verbose = true,
    rng,
    scheduler = EKP.DataMisfitController(terminate_at = 1_000_000),
)

@info "Starting calibration" n_iterations run_name ensemble_size = EKP.get_N_ens(ekp)

eki = ClimaCalibrate.calibrate(
    ClimaCalibrate.JuliaBackend(),
    ekp,
    interface,
    n_iterations,
    prior,
    output_dir,
)

# NB: report from the RETURNED process — `calibrate` checkpoints state via
# JLD2 and does not update the in-memory `ekp` we constructed above.
@info "Final constrained parameter means:" EKP.get_ϕ_mean_final(prior, eki)
try
    @info "Misfit per iteration:" EKP.get_error(eki)
catch e
    # get_error can throw a KeyError depending on where the scheduler stopped
    @warn "Could not retrieve misfit history"
end
