# Non-interactive driver for the coupled 2D tau sweep
# (lf1e-taudep-1, subexperiment C).
#
# 2D grid sweep over tau_dep x tau_ce with:
#   - UKI-calibrated microphysics baseline
#   - ClimaSeaIce+snow coupled surface
#   - ConstantTimescale ice formation (default)
#   - 20-day run length (interactive surface evolves)
#
# Usage (from repo root, in the ROOT env):
#
#   julia +1.12 -t 1 --startup-file=no --project \
#       "experiments/taudep sweep coupled 2d/run_sweep.jl" sweep \
#       [--workers 4] [--t_end 20days]
#
# Environment: root env (--project), NOT buildkite.

using Distributed

import ClimaComms
ClimaComms.@import_required_backends

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

function getarg(flag, default)
    i = findfirst(==(flag), ARGS)
    i === nothing ? default : ARGS[i + 1]
end

const MODE = isempty(ARGS) ? "help" : ARGS[1]
const PARSED_ARGS = (;
    z_elem = parse(Int, getarg("--z_elem", "60")),
    t_end = getarg("--t_end", "20days"),
    workers_n = parse(Int, getarg("--workers", "4")),
)
empty!(ARGS)

include(joinpath(@__DIR__, "sweep_tools.jl"))

# ---------------------------------------------------------------------------
# Worker pool and batch runner
# ---------------------------------------------------------------------------

function setup_workers(n::Int)
    n <= 1 && return
    exeflags = ["--startup-file=no", "-t 1", "--project=$(Base.active_project())"]
    addprocs(n; exeflags)
    @info "Spawned workers; loading coupled stack on each" nworkers()
    Distributed.remotecall_eval(Main, workers(), :(import ClimaComms))
    Distributed.remotecall_eval(Main, workers(), :(ClimaComms.@import_required_backends))
    Distributed.remotecall_eval(Main, workers(),
        :(include($(joinpath(@__DIR__, "sweep_tools.jl")))))
end

function run_batch!(points; stage, z_elem, t_end)
    man = load_manifest()
    todo = [(d, c) for (d, c) in points if
        get(get(man, member_id(d, c), Dict{String, Any}()), "ret_code", "") != "success"]
    for (d, c) in setdiff(points, todo)
        @info "Member already successful; skipping" member_id(d, c)
    end
    isempty(todo) && return 0
    runner = ((d, c),) -> build_and_run(d, c; stage, z_elem, t_end)
    results = nworkers() > 1 ? pmap(runner, todo) : map(runner, todo)
    man = load_manifest()
    for (job_id, entry) in results
        man[job_id] = entry
    end
    save_manifest(man)
    return length(todo)
end

# ---------------------------------------------------------------------------
# Sweep
# ---------------------------------------------------------------------------

function sweep(; z_elem::Int, t_end::AbstractString, workers_n::Int)
    setup_workers(workers_n)

    # Stage 0: anchor at calibrated baseline.
    anchor = [(CALIBRATED_TAU_DEP, CALIBRATED_TAU_CE)]
    run_batch!(anchor; stage = "anchor", z_elem, t_end)
    man = load_manifest()
    m0 = get(get(man, member_id(CALIBRATED_TAU_DEP, CALIBRATED_TAU_CE),
        Dict{String, Any}()), "metrics", nothing)
    if m0 === nothing
        error("Anchor at calibrated baseline failed. Aborting.")
    end
    @info "Anchor completed" cloud_hours=m0["cloud_hours"] max_clw=m0["max_clw"] ts_end=m0["ts_end"]

    # Stage A: coarse 7x7 grid.
    run_batch!(coarse_grid(); stage = "coarse", z_elem, t_end)
    @info "Coarse grid complete"
    summary_table()
end

# ---------------------------------------------------------------------------

if MODE == "sweep"
    sweep(;
        z_elem = PARSED_ARGS.z_elem,
        t_end = PARSED_ARGS.t_end,
        workers_n = PARSED_ARGS.workers_n,
    )
else
    println("usage: run_sweep.jl sweep [--z_elem 60] [--workers 4] [--t_end 20days]")
end
