# Tools for the tau_dep transition sweep (lf1e-taudep-1).
#
# Everything here is transport-agnostic: the same entry points work from
# run_sweep.jl in tmux, a hand-driven REPL, or (later) a Kaimon session.
#
# Members are configured fully in memory (no per-member YAML/TOML config files
# in the repo): the base config YAML is loaded as a Dict, sweep overrides are
# merged on top, and the parameter override is a 2-line TOML written under the
# member's own output tree. Provenance per member: the run's auto-saved
# `<job_id>_parameters.toml` plus the manifest entry.
#
# The base config on disk has drifted since the speed tests validated the
# s10/s11/s13 grid family (dz_bottom moved 10 -> 20 on 2026-07-XX, commit
# 2bbdfa542 in ClimaAtmos.jl), so ALL grid keys are pinned explicitly here
# rather than inherited.

import YAML
import TOML
import Random
import Dates
import ClimaAtmos as CA
try
    import NCDatasets
catch
    error("""NCDatasets is required to compute sweep metrics but is not loadable.
           Install it into the global environment (not the repo project):
             julia +1.12 -e 'using Pkg; Pkg.activate(); Pkg.add("NCDatasets")'""")
end

const REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const BASE_YML = joinpath(REPO_ROOT, "ClimaAtmos.jl", "config", "model_configs",
    "larcform1_1M_prognostic_edmfx.yml")
const BASE_TOML = joinpath(REPO_ROOT, "ClimaAtmos.jl", "toml",
    "larcform1_1M_prognostic_edmfx.toml")
# Root output/ is what scripts/sync_from_remote.sh pulls back.
const OUTPUT_ROOT = joinpath(REPO_ROOT, "output", "lf1e-taudep-1")
const MANIFEST_PATH = joinpath(OUTPUT_ROOT, "manifest.toml")

# Liquid threshold from the clw experiment (Pithan 2016: 0.1 g/kg).
const CLW_THRESHOLD = 1e-4      # kg/kg, on max_z clw
const CLWVI_CLEAR = 1e-3        # kg/m^2, "column effectively liquid-free"
const CLIVI_CLEAR = 1e-4        # kg/m^2, "column effectively ice-free"

# ---------------------------------------------------------------------------
# Member naming and configuration
# ---------------------------------------------------------------------------

"""Tag for a tau value, stable and filesystem-safe: x<log10 tau with p for '.'>.
E.g. tau = 10^3.5 -> "x3p50"."""
tau_tag(tau::Real) = "x" * replace(string(round(log10(tau), digits = 2)), "." => "p", "-" => "m")

member_id(tau::Real) = "lf1e_taudep1_" * tau_tag(tau)

"""
    member_config(tau; z_elem, t_end, physics_variant, job_id)

Config dict for one sweep member, built in memory. `physics_variant` is
`:constant` (the sweep: default ConstantTimescale deposition with
sublimation_deposition_timescale = tau) or `:tdep` (TemperatureDependent, used
by the grid pilot where tau is ignored for physics but still names the run).
"""
function member_config(tau::Real;
    z_elem::Int = 100,
    t_end::AbstractString = "5days",
    physics_variant::Symbol = :constant,
    job_id::AbstractString = member_id(tau),
)
    cfg = YAML.load_file(BASE_YML)

    # Validated fast grid (s10/s11/s13 family) — pinned explicitly, see header.
    cfg["z_max"] = 5000.0
    cfg["z_elem"] = z_elem
    cfg["z_stretch"] = true
    cfg["dz_bottom"] = 10.0
    cfg["dt_rad"] = "30mins"

    cfg["t_end"] = t_end
    cfg["job_id"] = job_id
    cfg["output_dir"] = joinpath(OUTPUT_ROOT, job_id)
    cfg["output_dir_style"] = "ActiveLink"

    if physics_variant === :constant
        # 2-line override TOML kept under the member's output tree (synced back
        # with results; nothing accumulates in the experiment folder).
        override_dir = joinpath(OUTPUT_ROOT, job_id)
        mkpath(override_dir)
        override_path = joinpath(override_dir, "tau_override.toml")
        open(override_path, "w") do io
            println(io, "[sublimation_deposition_timescale]")
            println(io, "value = ", Float64(tau))
        end
        cfg["toml"] = [BASE_TOML, override_path]
    elseif physics_variant === :tdep
        cfg["toml"] = [BASE_TOML]
        cfg["cloud_ice_formation"] = "TemperatureDependent"
    else
        error("unknown physics_variant $physics_variant")
    end
    return cfg
end

# ---------------------------------------------------------------------------
# Running one member
# ---------------------------------------------------------------------------

"""
    run_member!(tau; kwargs...) -> NamedTuple

Runs one member to completion in-process (run_batch.jl pattern: AtmosConfig
built directly, so the config dict's job_id is respected). Catches crashes.
Records the member in the manifest and returns the manifest entry.
"""
function run_member!(tau::Real; stage::AbstractString = "?", kwargs...)
    cfg = member_config(tau; kwargs...)
    job_id = cfg["job_id"]
    man = load_manifest()
    if haskey(man, job_id) && get(man[job_id], "ret_code", "") == "success"
        @info "Member already in manifest with ret_code success; skipping" job_id
        return man[job_id]
    end
    @info "Starting member" job_id tau stage
    t0 = time()
    ret_code = :setup_error
    try
        Random.seed!(1234)
        config = CA.AtmosConfig(cfg)
        simulation = CA.get_simulation(config)
        sol_res = CA.solve_atmos!(simulation)
        ret_code = sol_res.ret_code
    catch e
        @error "Member failed before/during setup" job_id exception = (e, catch_backtrace())
    end
    walltime = time() - t0
    entry = Dict{String, Any}(
        "tau" => Float64(tau),
        "log10_tau" => log10(Float64(tau)),
        "stage" => stage,
        "ret_code" => string(ret_code),
        "walltime_s" => round(walltime, digits = 1),
        "finished_at" => string(Dates.now()),
        "z_elem" => get(cfg, "z_elem", -1),
        "t_end" => cfg["t_end"],
    )
    if ret_code == :success
        try
            entry["metrics"] = metrics(active_output_dir(job_id))
        catch e
            @error "Metrics computation failed" job_id exception = (e, catch_backtrace())
            entry["metrics_error"] = sprint(showerror, e)
        end
    end
    man[job_id] = entry
    save_manifest(man)
    @info "Finished member" job_id ret_code walltime = round(walltime, digits = 1)
    return entry
end

active_output_dir(job_id) = joinpath(OUTPUT_ROOT, job_id, "output_active")

# ---------------------------------------------------------------------------
# Manifest (TOML stdlib: no extra dependencies)
# ---------------------------------------------------------------------------

load_manifest() = isfile(MANIFEST_PATH) ? TOML.parsefile(MANIFEST_PATH) : Dict{String, Any}()

function save_manifest(man)
    mkpath(OUTPUT_ROOT)
    tmp = MANIFEST_PATH * ".tmp"
    open(tmp, "w") do io
        TOML.print(io, man)
    end
    mv(tmp, MANIFEST_PATH; force = true)
end

# ---------------------------------------------------------------------------
# Metrics (order parameters) from the hourly NetCDF diagnostics
# ---------------------------------------------------------------------------

"""Load a diagnostic variable; returns (time_hours, A) with time as first dim
of A and all spatial dims flattened into the second."""
function load_diag(outdir::AbstractString, short_name::AbstractString)
    path = joinpath(outdir, short_name * "_1h_average.nc")
    isfile(path) || error("diagnostic file not found: $path")
    NCDatasets.NCDataset(path) do ds
        t = Float64.(ds["time"][:]) ./ 3600.0   # seconds -> hours
        A = Array(ds[short_name])
        nt = length(t)
        tdim = findfirst(==(nt), size(A))
        tdim === nothing && error("no dim of $short_name matches time length $nt")
        A = permutedims(A, vcat(tdim, setdiff(1:ndims(A), tdim)))
        return t, reshape(Float64.(A), nt, :)
    end
end

"""
    metrics(outdir) -> Dict

Order parameters for one member, from the run's hourly diagnostics.
"""
function metrics(outdir::AbstractString)
    t, clw = load_diag(outdir, "clw")          # (time, z)
    _, lwp = load_diag(outdir, "lwp")          # (time, 1)
    _, clivi = load_diag(outdir, "clivi")
    _, ts = load_diag(outdir, "ts")

    nt = length(t)
    dt_days = nt > 1 ? (t[2] - t[1]) / 24.0 : 0.0
    colmax = vec(maximum(clw, dims = 2))
    cloudy = colmax .> CLW_THRESHOLD
    lwpv = vec(lwp[:, 1])
    cliviv = vec(clivi[:, 1])

    m = Dict{String, Any}(
        "n_hours" => nt,
        "max_clw" => maximum(colmax),
        "cloud_hours" => count(cloudy),
        "onset_hour" => any(cloudy) ? t[findfirst(cloudy)] : -1.0,
        "collapse_hour" => any(cloudy) ? t[findlast(cloudy)] : -1.0,
        "max_lwp" => maximum(lwpv),
        "lwp_int" => sum(lwpv) * dt_days,      # kg/m^2 * day
        "clivi_end" => cliviv[end],
        "max_clivi" => maximum(cliviv),
        "ts_end" => ts[end, 1],
    )
    # Clear state: last hour the column still carries meaningful condensate.
    condensed = (lwpv .> CLWVI_CLEAR) .| (cliviv .> CLIVI_CLEAR)
    m["clear_hour"] = any(condensed) ? t[findlast(condensed)] : 0.0

    # Hour-24 cloud base/top pressure (hPa), for grid-pilot comparisons.
    h24 = findfirst(>=(24.0), t)
    if h24 !== nothing
        try
            _, pfull = load_diag(outdir, "pfull")
            layer = clw[h24, :] .> CLW_THRESHOLD
            if any(layer)
                p = pfull[h24, :] ./ 100.0
                m["cloud_base_h24_hPa"] = maximum(p[layer])
                m["cloud_top_h24_hPa"] = minimum(p[layer])
            end
        catch e
            @warn "pfull-based cloud base/top skipped" exception = e
        end
    end
    try
        _, rlds = load_diag(outdir, "rlds")
        m["rlds_mean"] = sum(rlds[:, 1]) / nt
    catch e
        @warn "rlds mean skipped" exception = e
    end
    return m
end

# ---------------------------------------------------------------------------
# Adaptive refinement (Stage B): deterministic greedy bisection in log10 tau
# ---------------------------------------------------------------------------

# Metrics driving refinement, with the transform used before range-normalizing.
const REFINEMENT_METRICS = (
    ("cloud_hours", identity),
    ("max_clw", identity),
    ("clivi_end", x -> log10(x + 1e-8)),
)

"""
    next_tau(man; min_dx = 0.1, tol = 0.15, dense_dx = 0.05, dense_jump = 0.5)

Next tau to run, or `nothing` when converged. Considers successful members
with metrics, sorted in log10 tau. Picks the interval with the largest
normalized metric jump; refines until every jump < `tol` or the interval is
narrower than `min_dx` (`dense_dx` where the jump exceeds `dense_jump`,
i.e. inside the sharpest transition).
"""
"""Successful sweep members (pilot runs excluded) as (log10_tau, metrics),
sorted in log10 tau."""
function sweep_points(man)
    pts = [(e["log10_tau"], e["metrics"])
           for e in values(man)
           if get(e, "ret_code", "") == "success" && haskey(e, "metrics") &&
              get(e, "stage", "") in ("anchor", "coarse", "adaptive", "dense")]
    sort!(pts, by = first)
    return pts
end

function next_tau(man; min_dx = 0.1, tol = 0.15, dense_dx = 0.05, dense_jump = 0.5)
    pts = sweep_points(man)
    length(pts) < 2 && return nothing
    xs = first.(pts)

    # Range-normalize each refinement metric across current members.
    norms = map(REFINEMENT_METRICS) do (name, f)
        vals = [f(p[2][name]) for p in pts]
        lo, hi = extrema(vals)
        hi - lo < eps() ? zero.(vals) : (vals .- lo) ./ (hi - lo)
    end

    best_x, best_jump = nothing, 0.0
    for i in 1:(length(pts) - 1)
        dx = xs[i + 1] - xs[i]
        jump = maximum(abs(n[i + 1] - n[i]) for n in norms)
        floor_dx = jump > dense_jump ? dense_dx : min_dx
        dx <= floor_dx && continue
        if jump > tol && jump > best_jump
            best_jump = jump
            best_x = (xs[i] + xs[i + 1]) / 2
        end
    end
    return best_x === nothing ? nothing : 10.0^best_x
end

"""Stage C helper: uniform dense tau values across the sharpest interval,
extended +-`halfwidth` decades around its center."""
function critical_window(man; n = 10, halfwidth = 0.25)
    pts = sweep_points(man)
    length(pts) < 2 && return Float64[]
    xs = first.(pts)
    norms = map(REFINEMENT_METRICS) do (name, f)
        vals = [f(p[2][name]) for p in pts]
        lo, hi = extrema(vals)
        hi - lo < eps() ? zero.(vals) : (vals .- lo) ./ (hi - lo)
    end
    jumps = [maximum(abs(n[i + 1] - n[i]) for n in norms) for i in 1:(length(pts) - 1)]
    i = argmax(jumps)
    c = (xs[i] + xs[i + 1]) / 2
    return [10.0^x for x in range(c - halfwidth, c + halfwidth, length = n)]
end

# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------

function summary_table(man = load_manifest())
    rows = sort(collect(man), by = kv -> get(kv[2], "log10_tau", Inf))
    println(rpad("job_id", 26), rpad("log10", 7), rpad("ret", 10), rpad("hrs", 5),
        rpad("max_clw", 10), rpad("lwp_int", 9), rpad("clivi_end", 10), "clear_h")
    for (job_id, e) in rows
        m = get(e, "metrics", Dict())
        fmt(k, d = "-") = haskey(m, k) ? string(round(m[k], sigdigits = 3)) : d
        println(rpad(job_id, 26),
            rpad(string(round(get(e, "log10_tau", NaN), digits = 2)), 7),
            rpad(get(e, "ret_code", "?"), 10),
            rpad(fmt("cloud_hours"), 5),
            rpad(fmt("max_clw"), 10),
            rpad(fmt("lwp_int"), 9),
            rpad(fmt("clivi_end"), 10),
            fmt("clear_hour"))
    end
end
