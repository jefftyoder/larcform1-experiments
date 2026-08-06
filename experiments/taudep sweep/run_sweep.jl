# Non-interactive driver for the tau_dep transition sweep (lf1e-taudep-1).
#
# Usage (from repo root, in the SAME env as every prior standalone Larcform1
# baseline — the clw experiments and speed tests all ran here, and this env has
# ClimaAtmos dev'd from the submodule plus NCDatasets/YAML as direct deps):
#
#   julia +1.12 -t 1 --project=ClimaAtmos.jl/.buildkite \
#       "experiments/taudep sweep/run_sweep.jl" pilot
#   julia +1.12 -t 1 --project=ClimaAtmos.jl/.buildkite \
#       "experiments/taudep sweep/run_sweep.jl" sweep \
#       --z_elem 100 [--budget 25] [--t_end 5days] [--stageC]
#
# NOTE: this env has REGISTERED CloudMicrophysics — fine for this sweep
# (ConstantTimescale needs no vendored patch), but a future Frostenberg a/b
# sweep must NOT run here; revisit the environment then. The repo-root env is
# currently not usable for standalone runs on Stratus (ClimaAtmos appears as a
# registered, undownloaded package there, contradicting CLAUDE.md — flagged to
# Jeff 2026-08-06).
#
# `pilot` answers the grid question (is z_elem 60 or 80 converged vs 100?) and
# reruns the s13 discriminator on each candidate grid. Review its table before
# launching `sweep` — the grid choice is a decision point, not automated.
#
# `sweep` runs Stage 0 (anchors + signature checks) -> Stage A (coarse log
# scan) -> Stage B (adaptive bisection, up to --budget members) -> optional
# Stage C (dense critical window) in one process; JIT is paid once. The
# manifest (output/lf1e-taudep-1/manifest.toml) is updated after every member,
# and members already recorded as successful are skipped, so the driver is
# safe to re-run after an interruption.

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

function sweep(; z_elem::Int, t_end::AbstractString, budget::Int, stageC::Bool)
    runm(tau; stage) = run_member!(tau; z_elem, t_end, stage)

    # Stage 0: anchors with signature checks.
    a1 = runm(100; stage = "anchor")
    m1 = get(a1, "metrics", nothing)
    if m1 === nothing || m1["max_clw"] != 0.0
        error("Anchor tau=100 failed its signature (expect clw == 0 exactly; " *
              "got $(m1 === nothing ? a1["ret_code"] : m1["max_clw"])). " *
              "Pipeline problem — aborting before spending the sweep.")
    end
    a2 = runm(1e9; stage = "anchor")
    m2 = get(a2, "metrics", nothing)
    if m2 === nothing || m2["cloud_hours"] < m2["n_hours"] ÷ 2 || m2["clivi_end"] > 1e-3
        error("Anchor tau=1e9 failed its signature (expect sustained liquid, " *
              "negligible ice; got $(m2)). Aborting.")
    end
    @info "Stage 0 anchors passed signature checks"

    # Stage A: coarse log scan, 2 points/decade.
    for x in 1.0:0.5:9.0
        runm(10.0^x; stage = "coarse")
    end
    @info "Stage A complete"
    summary_table()

    # Stage B: adaptive bisection.
    for i in 1:budget
        tau = next_tau(load_manifest())
        if tau === nothing
            @info "Refinement converged after $(i - 1) members"
            break
        end
        runm(tau; stage = "adaptive")
    end

    # Stage C: dense uniform sampling across the sharpest transition.
    if stageC
        for tau in critical_window(load_manifest())
            runm(tau; stage = "dense")
        end
    end

    println("\n=== Final sweep summary ===")
    summary_table()
end

# ---------------------------------------------------------------------------

if MODE == "pilot"
    pilot()
elseif MODE == "sweep"
    sweep(;
        z_elem = parse(Int, getarg("--z_elem", "100")),
        t_end = getarg("--t_end", "5days"),
        budget = parse(Int, getarg("--budget", "25")),
        stageC = "--stageC" in ARGS,
    )
else
    println("usage: run_sweep.jl pilot | sweep --z_elem N [--budget 25] [--t_end 5days] [--stageC]")
end
