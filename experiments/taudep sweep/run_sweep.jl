# Non-interactive driver for the tau_dep transition sweep (lf1e-taudep-1).
#
# Usage (from repo root, in the SAME env as every prior standalone Larcform1
# baseline — the clw experiments and speed tests all ran here, and this env has
# ClimaAtmos dev'd from the submodule plus NCDatasets/YAML as direct deps):
#
#   julia +1.12 -t 1 --startup-file=no --project=ClimaAtmos.jl/.buildkite \
#       "experiments/taudep sweep/run_sweep.jl" pilot
#   julia +1.12 -t 1 --startup-file=no --project=ClimaAtmos.jl/.buildkite \
#       "experiments/taudep sweep/run_sweep.jl" sweep \
#       --z_elem 60 [--workers 4] [--budget 25] [--t_end 5days] [--stageC]
#
# Parallelism: --workers N (default 4) runs members N at a time on Distributed
# workers; the coordinator alone touches the manifest, and the batched
# refinement rule (next_taus, top-k intervals) keeps the adaptive stage
# informed by all completed members. Cap chosen for memory, not cores: each
# member peaks ~9 GB RSS on Stratus (62 GB), and swap kills performance, so 4
# leaves safe headroom. --workers 1 recovers the serial behavior.
#
# `pilot` answers the grid question (is z_elem 60 or 80 converged vs 100?) and
# reruns the s13 discriminator on each candidate grid. Review its table before
# launching `sweep` — the grid choice is a decision point, not automated.
# Result 2026-08-06: z60 and z80 both pass everything; z60 adopted.
#
# `sweep` runs Stage 0 (anchors + signature checks) -> Stage A (coarse log
# scan) -> Stage B (batched adaptive bisection, up to --budget members) ->
# optional Stage C (dense critical window) in one process tree; JIT is paid
# once per worker. The manifest (output/lf1e-taudep-1/manifest.toml) is
# updated after every batch, and members already recorded successful are
# skipped, so the driver is safe to re-run after an interruption.
#
# NOTE: this env has REGISTERED CloudMicrophysics — fine for this sweep
# (ConstantTimescale needs no vendored patch), but a future Frostenberg a/b
# sweep must NOT run here; revisit the environment then.

using Distributed

import ClimaComms
ClimaComms.@import_required_backends

include(joinpath(@__DIR__, "sweep_tools.jl"))

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

function getarg(flag, default)
    i = findfirst(==(flag), ARGS)
    i === nothing ? default : ARGS[i + 1]
end

const MODE = isempty(ARGS) ? "help" : ARGS[1]

# ---------------------------------------------------------------------------
# Worker pool and batch runner
# ---------------------------------------------------------------------------

"""Spawn `n` Distributed workers (n concurrent members; the coordinator only
orchestrates) and load the sweep tools on each. No-op for n <= 1 (serial)."""
function setup_workers(n::Int)
    n <= 1 && return
    exeflags = ["--startup-file=no", "-t 1", "--project=$(Base.active_project())"]
    addprocs(n; exeflags)
    @info "Spawned workers; loading ClimaAtmos on each (JIT paid once per worker)" nworkers()
    # Separate eval calls: a macro from a just-imported module cannot be
    # expanded in the same expression that imports it.
    Distributed.remotecall_eval(Main, workers(), :(import ClimaComms))
    Distributed.remotecall_eval(Main, workers(), :(ClimaComms.@import_required_backends))
    Distributed.remotecall_eval(Main, workers(),
        :(include($(joinpath(@__DIR__, "sweep_tools.jl")))))
end

"""
    run_batch!(taus; stage, z_elem, t_end) -> n_new

Run the given tau values (members not already successful), k at a time on the
worker pool. Only the coordinator writes the manifest. Returns how many
members actually ran.
"""
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
# Grid pilot
# ---------------------------------------------------------------------------

# s11/s13 published values (2-day runs, old base config) — printed as a drift
# check only; acceptance is judged against the same-code z100 reference below.
const S11_REF = (max_clw = 4.19e-4, cloud_hours = 48, onset = 0.0,
    base_hPa = 1004.0, top_hPa = 966.0, rlds = 223.8)

function pilot()
    entries = Dict{Int, Dict{String, Any}}()
    v1 = Dict{Int, Dict{String, Any}}()
    for z in (100, 80, 60)
        e = run_member!(100; z_elem = z, t_end = "2days", physics_variant = :tdep,
            job_id = "lf1e_taudep1_pilot_tdep_z$z", stage = "pilot")
        entries[z] = e
        # Discriminator: v1 physics (tau = 100 s default) must give clw == 0.
        d = run_member!(100; z_elem = z, t_end = "2days", physics_variant = :constant,
            job_id = "lf1e_taudep1_pilot_v1_z$z", stage = "pilot")
        v1[z] = d
    end

    println("\n=== Grid pilot: TemperatureDependent 2-day runs vs z100 reference ===")
    ref = get(entries[100], "metrics", nothing)
    ref === nothing && (println("z100 reference failed; no comparison possible"); return)
    println("s11 published (old base, drift check): max_clw $(S11_REF.max_clw), ",
        "hrs $(S11_REF.cloud_hours)/48, onset h$(S11_REF.onset), ",
        "base/top $(S11_REF.base_hPa)/$(S11_REF.top_hPa) hPa, rlds $(S11_REF.rlds)")
    for z in (100, 80, 60)
        m = get(entries[z], "metrics", nothing)
        if m === nothing
            println("z$z: RUN FAILED ($(entries[z]["ret_code"]))")
            continue
        end
        dclw = 100 * (m["max_clw"] / ref["max_clw"] - 1)
        checks = z == 100 ? String[] : [
            abs(dclw) <= 5 ? "max_clw OK ($(round(dclw, digits=1))%)" :
                "max_clw FAIL ($(round(dclw, digits=1))%)",
            abs(m["onset_hour"] - ref["onset_hour"]) <= 1 ? "onset OK" : "onset FAIL",
            abs(m["cloud_hours"] - ref["cloud_hours"]) <= 2 ? "hours OK" : "hours FAIL",
            (haskey(m, "cloud_top_h24_hPa") && haskey(ref, "cloud_top_h24_hPa") &&
             abs(m["cloud_top_h24_hPa"] - ref["cloud_top_h24_hPa"]) <= 2 &&
             abs(m["cloud_base_h24_hPa"] - ref["cloud_base_h24_hPa"]) <= 2) ?
                "base/top OK" : "base/top FAIL",
            (m["clivi_end"] > 0 && ref["clivi_end"] > 0 &&
             abs(log10(m["clivi_end"] / ref["clivi_end"])) <= 0.5) ?
                "clivi OK" : "clivi FAIL",
        ]
        println("z$z: max_clw $(round(m["max_clw"], sigdigits=3)), ",
            "hrs $(m["cloud_hours"])/$(m["n_hours"]), onset h$(m["onset_hour"]), ",
            "base/top $(round(get(m, "cloud_base_h24_hPa", NaN), digits=1))/",
            "$(round(get(m, "cloud_top_h24_hPa", NaN), digits=1)) hPa, ",
            "clivi_end $(round(m["clivi_end"], sigdigits=2))",
            isempty(checks) ? "  [reference]" : "  [" * join(checks, ", ") * "]")
    end
    println("\n=== Discriminator (v1 physics, must be exactly zero) ===")
    for z in (100, 80, 60)
        m = get(v1[z], "metrics", nothing)
        status = m === nothing ? "RUN FAILED ($(v1[z]["ret_code"]))" :
            m["max_clw"] == 0.0 ? "clw == 0 exactly: PASS" :
            "clw NONZERO ($(m["max_clw"])): FAIL"
        println("z$z: ", status)
    end
    println("\nAdopt the coarsest grid whose checks all pass AND whose discriminator passes.")
end

# ---------------------------------------------------------------------------
# Sweep stages
# ---------------------------------------------------------------------------

function sweep(; z_elem::Int, t_end::AbstractString, budget::Int, stageC::Bool,
    workers_n::Int)
    setup_workers(workers_n)

    # Stage 0: anchors with signature checks (run as one parallel batch).
    run_batch!([100.0, 1e9]; stage = "anchor", z_elem, t_end)
    man = load_manifest()
    m1 = get(get(man, member_id(100.0), Dict{String, Any}()), "metrics", nothing)
    if m1 === nothing || m1["max_clw"] != 0.0
        error("Anchor tau=100 failed its signature (expect clw == 0 exactly; " *
              "got $(m1 === nothing ? "no metrics" : m1["max_clw"])). " *
              "Pipeline problem — aborting before spending the sweep.")
    end
    m2 = get(get(man, member_id(1e9), Dict{String, Any}()), "metrics", nothing)
    if m2 === nothing || m2["cloud_hours"] < m2["n_hours"] ÷ 2 || m2["clivi_end"] > 1e-3
        error("Anchor tau=1e9 failed its signature (expect sustained liquid, " *
              "negligible ice; got $(m2)). Aborting.")
    end
    @info "Stage 0 anchors passed signature checks"

    # Stage A: coarse log scan, 2 points/decade, workers_n at a time.
    run_batch!([10.0^x for x in 1.0:0.5:9.0]; stage = "coarse", z_elem, t_end)
    @info "Stage A complete"
    summary_table()

    # Stage B: batched adaptive bisection — top-k intervals per round, all
    # completed members inform each round's picks.
    spent = 0
    while spent < budget
        k = min(max(nworkers(), 1), budget - spent)
        batch = next_taus(load_manifest(); k)
        if isempty(batch)
            @info "Refinement converged after $spent adaptive members"
            break
        end
        n_new = run_batch!(batch; stage = "adaptive", z_elem, t_end)
        n_new == 0 && break   # everything proposed already exists; done
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
# Extended runs (longer t_end over a tau ladder; distinct job ids so they
# coexist with the 5-day sweep members in the same manifest)
# ---------------------------------------------------------------------------

ext_id(tau, t_end) = "lf1e_taudep1_" * t_end * "_" * tau_tag(tau)

function extend(; z_elem::Int, t_end::AbstractString, workers_n::Int)
    setup_workers(workers_n)
    taus = [10.0^x for x in 1.0:0.5:9.0]
    man = load_manifest()
    todo = [t for t in taus if
        get(get(man, ext_id(t, t_end), Dict{String, Any}()), "ret_code", "") != "success"]
    @info "Extended runs" t_end n_total = length(taus) n_todo = length(todo)
    isempty(todo) && return
    results = pmap(t -> build_and_run(t; stage = "extended", z_elem, t_end,
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
# Worker-scaling test
# ---------------------------------------------------------------------------

# Fixed member list spanning the regimes (cost is roughly tau-independent);
# rerun at each worker count under distinct job_ids so nothing is skipped.
const SCAL_TAUS = [10.0^x for x in (1.5, 2.5, 3.25, 3.75, 4.5, 5.5, 7.0, 8.5)]

"""
    scaling(; z_elem, t_end, counts)

Measure sweep throughput vs worker count: warm every worker's JIT with a short
member, then run the same `SCAL_TAUS` list through WorkerPool subsets of size
`counts[i]`, timing each round's makespan. All members land in the manifest
(stage "scaling"/"scalwarm") for provenance. Watch swap during the largest
count — the memory ceiling, not cores, is the constraint on Stratus.
"""
function scaling(; z_elem::Int, t_end::AbstractString, counts::Vector{Int})
    nmax = maximum(counts)
    setup_workers(nmax)
    ws = workers()

    @info "Warmup: one short member per worker to pay JIT before timing"
    pmap(WorkerPool(ws), 1:length(ws)) do i
        build_and_run(10.0^(1.1 + 0.01i); stage = "scalwarm", z_elem,
            t_end = "12hours", job_id = "lf1e_taudep1_scal_warm_w$i")
    end

    rows = NamedTuple[]
    for n in sort(counts)
        pool = WorkerPool(ws[1:n])
        t0 = time()
        results = pmap(pool, collect(enumerate(SCAL_TAUS))) do (i, tau)
            build_and_run(tau; stage = "scaling", z_elem, t_end,
                job_id = "lf1e_taudep1_scal_w$(n)_m$i")
        end
        makespan = time() - t0
        man = load_manifest()
        for (job_id, entry) in results
            man[job_id] = entry
        end
        save_manifest(man)
        walltimes = [e["walltime_s"] for (_, e) in results]
        push!(rows, (; n, makespan, mean_member = sum(walltimes) / length(walltimes)))
        @info "Scaling round done" n makespan = round(makespan, digits = 1)
    end

    println("\n=== Worker scaling ($(length(SCAL_TAUS)) members, t_end $t_end, z_elem $z_elem) ===")
    println(rpad("workers", 9), rpad("makespan_s", 12), rpad("members/hr", 12),
        rpad("speedup", 9), rpad("efficiency", 11), "mean member walltime_s")
    for r in rows
        su = rows[1].makespan / r.makespan          # vs smallest measured count
        eff = su / (r.n / rows[1].n)                # 1.0 = ideal linear scaling
        println(rpad(r.n, 9), rpad(round(r.makespan, digits = 1), 12),
            rpad(round(3600 * length(SCAL_TAUS) / r.makespan, digits = 1), 12),
            rpad(round(su, digits = 2), 9),
            rpad(round(eff, digits = 2), 11),
            round(r.mean_member, digits = 1))
    end
end

# ---------------------------------------------------------------------------

if MODE == "pilot"
    pilot()
elseif MODE == "sweep"
    sweep(;
        z_elem = parse(Int, getarg("--z_elem", "60")),
        t_end = getarg("--t_end", "5days"),
        budget = parse(Int, getarg("--budget", "25")),
        stageC = "--stageC" in ARGS,
        workers_n = parse(Int, getarg("--workers", "4")),
    )
elseif MODE == "scaling"
    scaling(;
        z_elem = parse(Int, getarg("--z_elem", "60")),
        t_end = getarg("--t_end", "2days"),
        counts = parse.(Int, split(getarg("--counts", "1,2,4,6"), ",")),
    )
elseif MODE == "extend"
    extend(;
        z_elem = parse(Int, getarg("--z_elem", "60")),
        t_end = getarg("--t_end", "20days"),
        workers_n = parse(Int, getarg("--workers", "4")),
    )
else
    println("usage: run_sweep.jl pilot | sweep --z_elem N [--workers 4] [--budget 25] [--t_end 5days] [--stageC] | scaling [--counts 1,2,4,6] [--t_end 2days] | extend [--t_end 20days] [--workers 4]")
end
