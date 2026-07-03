# Run a batch of Larcform1 variation overlays in a single persistent Julia process.
#
# Unlike ClimaAtmos.jl/.buildkite/ci_driver.jl, this driver:
#   - builds AtmosConfig directly (not via CA.commandline_kwargs()), so each
#     overlay's `job_id:` key is respected instead of being shadowed by
#     ArgParse's `--job_id` default (see cli_options.jl:12-15)
#   - loops over multiple variations in one process, so package load + JIT
#     compilation is paid once per batch, not once per variation
#   - does not tar+delete the output .nc/.hdf5 files, and does not force
#     make_plots — raw diagnostics are left in place for postprocessing
#   - keeps going after a crashed variation (solve_atmos! already catches
#     crashes internally and returns :simulation_crashed instead of throwing)
#
# Usage:
#   julia -t 1 --project=ClimaAtmos.jl/.buildkite \
#     "experiments/clw sensitivity experiments/run_batch.jl" \
#     "experiments/clw sensitivity experiments/configs/v1_base.yml" \
#     "experiments/clw sensitivity experiments/configs/v5_subltime10.yml" \
#     ...
#
# Each overlay is merged on top of the Larcform1 base config below; set
# `job_id` and `output_dir` in each overlay to keep variations separated.

import ClimaComms
ClimaComms.@import_required_backends
import ClimaAtmos as CA
import Random
Random.seed!(1234)

const BASE_CONFIG =
    joinpath(@__DIR__, "..", "..", "ClimaAtmos.jl", "config", "model_configs",
        "larcform1_1M_prognostic_edmfx.yml")

isempty(ARGS) && error("Usage: julia run_batch.jl <overlay1.yml> [overlay2.yml ...]")

function fmt_duration(seconds)
    seconds < 60 && return "$(round(seconds, digits=1))s"
    m, s = divrem(round(Int, seconds), 60)
    m < 60 && return "$(m)m$(s)s"
    h, m = divrem(m, 60)
    return "$(h)h$(m)m$(s)s"
end

batch_t0 = time()
n = length(ARGS)

results = map(enumerate(ARGS)) do (i, overlay)
    @info "Starting variation [$i/$n]" overlay
    t0 = time()
    ret_code = :config_error
    job_id = overlay
    try
        config = CA.AtmosConfig([BASE_CONFIG, overlay])
        simulation = CA.get_simulation(config)
        job_id = simulation.job_id
        sol_res = CA.solve_atmos!(simulation)
        ret_code = sol_res.ret_code
    catch e
        @error "Variation failed before/during setup" overlay exception = (e, catch_backtrace())
        ret_code = :setup_error
    end
    walltime = time() - t0
    @info "Finished variation [$i/$n]" overlay job_id ret_code walltime = fmt_duration(walltime)
    (; overlay, job_id, ret_code, walltime)
end

batch_walltime = time() - batch_t0

println()
println("=== Batch summary ===")
for r in results
    status = r.ret_code == :success ? "OK" : "FAILED ($(r.ret_code))"
    println(rpad(r.job_id, 40), rpad(status, 20), rpad(fmt_duration(r.walltime), 12), r.overlay)
end
println()
println("Total batch wall time: ", fmt_duration(batch_walltime), " for $n variations")

n_failed = count(r -> r.ret_code != :success, results)
n_failed > 0 && @warn "$n_failed / $(length(results)) variations failed"
