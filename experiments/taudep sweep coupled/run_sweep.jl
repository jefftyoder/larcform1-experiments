# Non-interactive driver for the coupled tau_dep transition sweep
# (lf1e-taudep-1, subexperiment B).
#
# Same protocol as subexperiment A but with:
#   - UKI-calibrated microphysics baseline (lf1e-clw-calibration-1)
#   - ClimaSeaIce+snow coupled surface (experiments/sea-ice/ Phase 2)
#   - 20-day default run length (interactive surface evolves)
#
# Usage (from repo root, in the ROOT env — vendored CloudMicrophysics required):
#
#   julia +1.12 -t 1 --startup-file=no --project \
#       "experiments/taudep sweep coupled/run_sweep.jl" sweep \
#       --z_elem 60 [--workers 4] [--budget 15] [--t_end 20days] [--stageC]
#
# No grid pilot: z_elem 60 was validated by subexperiment A's pilot (z60
# passes all convergence criteria against z100). The coupled path reuses
# the same atmosphere grid.
#
# Environment: root env (--project), NOT buildkite. The vendored
# CloudMicrophysics.jl with the Frostenberg a/b INP patch is dev'd only in
# the root env; the buildkite env has registered CloudMicrophysics where
# those knobs are dead. The sea-ice experiment validated this env for coupled
# runs.
#
# Coupled members cost ~6 min each (20-day) vs ~36 s (5-day standalone), so
# the default adaptive budget is 15 (not 25).

using Distributed

import ClimaComms
ClimaComms.@import_required_backends

# ---------------------------------------------------------------------------
# CLI — parse our args BEFORE loading sweep_tools (which loads ClimaCoupler,
# whose Input.get_coupler_config_dict parses ARGS via ArgParse; leftover
# sweep-specific flags like "--z_elem" cause it to error).
# ---------------------------------------------------------------------------

function getarg(flag, default)
    i = findfirst(==(flag), ARGS)
    i === nothing ? default : ARGS[i + 1]
end

const MODE = isempty(ARGS) ? "help" : ARGS[1]
const PARSED_ARGS = (;
    z_elem = parse(Int, getarg("--z_elem", "60")),
    t_end = getarg("--t_end", "20days"),
    budget = parse(Int, getarg("--budget", "15")),
    stageC = "--stageC" in ARGS,
    workers_n = parse(Int, getarg("--workers", "4")),
    counts = getarg("--counts", "1,2,4"),
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
    @info "Spawned workers; loading coupled stack on each (JIT paid once per worker)" nworkers()
    Distributed.remotecall_eval(Main, workers(), :(import ClimaComms))
    Distributed.remotecall_eval(Main, workers(), :(ClimaComms.@import_required_backends))
    Distributed.remotecall_eval(Main, workers(),
        :(include($(joinpath(@__DIR__, "sweep_tools.jl")))))
end

function run_batch!(taus; stage, z_elem, t_end)
    man = load_manifest()
    todo = [Float64(t) for t in taus if
        get(get(man, member_id(t), Dict{String, Any}()), "ret_code", "") != "success"]
    for t in setdiff(Float64.(taus), todo)
        @info "Member already successful; skipping" member_id(t)
    end
    isempty(todo) && return 0
    runner = t -> build_and_run(t; stage, z_elem, t_end)
    results = nworkers() > 1 ? pmap(runner, todo) : map(runner, todo)
    man = load_manifest()
    for (job_id, entry) in results
        man[job_id] = entry
    end
    save_manifest(man)
    return length(todo)
end

# ---------------------------------------------------------------------------
# Sweep stages
# ---------------------------------------------------------------------------

# Calibrated baseline tau_dep (from calibrated_uki1_final.toml).
const CALIBRATED_TAU = 66.59059810650213

function sweep(; z_elem::Int, t_end::AbstractString, budget::Int, stageC::Bool,
    workers_n::Int)
    setup_workers(workers_n)

    # Stage 0: anchors. Validates the coupled pipeline produces results.
    # Unlike subexperiment A (slab at 250 K), the interactive surface cools
    # dramatically (~214.5 K by day 20), so even tau=1e9 sees cloud collapse
    # around day 2–3. The anchor checks verify cloud FORMATION, not sustained
    # liquid — sustained liquid is not expected under interactive cooling.
    run_batch!([CALIBRATED_TAU, 1e9]; stage = "anchor", z_elem, t_end)
    man = load_manifest()

    m1 = get(get(man, member_id(CALIBRATED_TAU), Dict{String, Any}()), "metrics", nothing)
    if m1 === nothing
        error("Anchor tau=$(round(CALIBRATED_TAU, digits=1)) failed to produce metrics. " *
              "Pipeline problem — aborting before spending the sweep.")
    end
    @info "Anchor tau=$(round(CALIBRATED_TAU, digits=1)) completed" cloud_hours=m1["cloud_hours"] max_clw=m1["max_clw"]

    m2 = get(get(man, member_id(1e9), Dict{String, Any}()), "metrics", nothing)
    if m2 === nothing || m2["max_clw"] < CLW_THRESHOLD
        error("Anchor tau=1e9 failed: no cloud formed (max_clw below threshold). " *
              "Pipeline problem — aborting. Got: $(m2)")
    end
    @info "Anchor tau=1e9 completed" cloud_hours=m2["cloud_hours"] max_clw=m2["max_clw"] collapse_hour=m2["collapse_hour"]
    @info "Stage 0 anchors completed"

    # Stage A: coarse log scan, 2 points/decade.
    run_batch!([10.0^x for x in 1.0:0.5:9.0]; stage = "coarse", z_elem, t_end)
    @info "Stage A complete"
    summary_table()

    # Stage B: batched adaptive bisection.
    spent = 0
    while spent < budget
        k = min(max(nworkers(), 1), budget - spent)
        batch = next_taus(load_manifest(); k)
        if isempty(batch)
            @info "Refinement converged after $spent adaptive members"
            break
        end
        n_new = run_batch!(batch; stage = "adaptive", z_elem, t_end)
        n_new == 0 && break
        spent += n_new
    end

    # Stage C: dense uniform sampling across the sharpest transition.
    if stageC
        run_batch!(critical_window(load_manifest()); stage = "dense", z_elem, t_end)
    end

    println("\n=== Final sweep summary ===")
    summary_table()
end

# ---------------------------------------------------------------------------
# Extended runs (longer t_end over a tau ladder)
# ---------------------------------------------------------------------------

function extend(; z_elem::Int, t_end::AbstractString, workers_n::Int)
    setup_workers(workers_n)
    taus = [10.0^x for x in 1.0:0.5:9.0]
    man = load_manifest()
    todo = [t for t in taus if
        get(get(man, ext_id(t, t_end), Dict{String, Any}()), "ret_code", "") != "success"]
    @info "Extended runs" t_end n_total = length(taus) n_todo = length(todo)
    isempty(todo) && return
    results = nworkers() > 1 ?
        pmap(t -> build_and_run(t; stage = "extended", z_elem, t_end,
            job_id = ext_id(t, t_end)), todo) :
        map(t -> build_and_run(t; stage = "extended", z_elem, t_end,
            job_id = ext_id(t, t_end)), todo)
    man = load_manifest()
    for (job_id, entry) in results
        man[job_id] = entry
    end
    save_manifest(man)
    println("\n=== Extended-run summary ===")
    summary_table()
end

# ---------------------------------------------------------------------------

if MODE == "sweep"
    sweep(;
        z_elem = PARSED_ARGS.z_elem,
        t_end = PARSED_ARGS.t_end,
        budget = PARSED_ARGS.budget,
        stageC = PARSED_ARGS.stageC,
        workers_n = PARSED_ARGS.workers_n,
    )
elseif MODE == "extend"
    extend(;
        z_elem = PARSED_ARGS.z_elem,
        t_end = PARSED_ARGS.t_end,
        workers_n = PARSED_ARGS.workers_n,
    )
else
    println("usage: run_sweep.jl sweep [--z_elem 60] [--workers 4] [--budget 15] [--t_end 20days] [--stageC] | extend [--t_end 20days] [--workers 4]")
end
