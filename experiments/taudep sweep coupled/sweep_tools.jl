# Tools for the coupled tau_dep transition sweep (lf1e-taudep-1, subexperiment B).
#
# Same adaptive-sweep protocol as subexperiment A ("experiments/taudep sweep/"),
# but with two key differences:
#   1. UKI-calibrated microphysics parameters as baseline (lf1e-clw-calibration-1)
#   2. ClimaSeaIce+snow coupled surface (experiments/sea-ice/ Phase 2 component)
#
# Execution path: ClimaCoupler CoupledSimulation (not standalone ClimaAtmos).
# Environment: root env (--project), NOT buildkite — the vendored
# CloudMicrophysics.jl with the Frostenberg a/b patch is dev'd only here.
#
# Parameter routing: ALL parameter TOMLs go through `coupler_toml:` (not atmos
# `toml:`), because ClimaCoupler v0.2.2 silently reverts atmos-toml values to
# ClimaParams defaults (the clobber bug; see CLAUDE.md).

import YAML
import TOML
import Random
import Dates
import ClimaAtmos            # triggers ClimaCouplerClimaAtmosExt
import ClimaCoupler
import ClimaCoupler: Input, CoupledSimulation
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
const CALIBRATION_BASE_TOML = joinpath(REPO_ROOT,
    "experiments", "clw calibration", "configs", "toml",
    "larcform1_calibration_base.toml")
const CALIBRATED_TOML = joinpath(REPO_ROOT,
    "experiments", "clw calibration", "configs", "toml",
    "calibrated_uki1_final.toml")
const SEA_ICE_COMPONENT = joinpath(REPO_ROOT,
    "experiments", "sea-ice", "components", "clima_seaice_column.jl")

const OUTPUT_ROOT = joinpath(REPO_ROOT, "output", "lf1e-taudep-1-coupled")
const MANIFEST_PATH = joinpath(OUTPUT_ROOT, "manifest.toml")

const CLW_THRESHOLD = 1e-4      # kg/kg, on max_z clw
const CLWVI_CLEAR = 1e-3        # kg/m^2, "column effectively liquid-free"
const CLIVI_CLEAR = 1e-4        # kg/m^2, "column effectively ice-free"

# Register the sea-ice component so CoupledSimulation can construct it.
include(SEA_ICE_COMPONENT)

# ---------------------------------------------------------------------------
# Config hygiene (from run_20day_suite.jl)
# ---------------------------------------------------------------------------

const _COUPLER_DEFAULTS = Input.parse_commandline(Input.argparse_settings())
const _ATMOS_DEFAULTS = Input.atmos_default_config_dict()
const _KNOWN_KEYS = union(keys(_COUPLER_DEFAULTS), keys(_ATMOS_DEFAULTS))

function check_config_keys!(cfg::Dict)
    unknown = sort(collect(setdiff(keys(cfg), _KNOWN_KEYS)))
    isempty(unknown) || error(
        "Config keys not recognized by ClimaCoupler or ClimaAtmos defaults " *
        "(would be silently ignored): $unknown")
end

# ---------------------------------------------------------------------------
# Member naming and configuration
# ---------------------------------------------------------------------------

tau_tag(tau::Real) = "x" * replace(string(round(log10(tau), digits = 2)), "." => "p", "-" => "m")

member_id(tau::Real) = "lf1e_taudep1c_" * tau_tag(tau)

ext_id(tau::Real, t_end::AbstractString) =
    "lf1e_taudep1c_" * t_end * "_" * tau_tag(tau)

"""
    member_config(tau; z_elem, t_end, job_id) -> config_path

Build a coupled-mode config for one sweep member. Returns the path to a
generated YAML file (CoupledSimulation takes a path, not a dict).

The per-member TOML starts from the UKI-calibrated values and replaces
sublimation_deposition_timescale with the swept tau. All other calibrated
parameters (condensation_evaporation_timescale, autoconversion threshold,
snow_autoconversion_timescale, Frostenberg a, Frostenberg b) remain at
their calibrated values.
"""
function member_config(tau::Real;
    z_elem::Int = 60,
    t_end::AbstractString = "20days",
    job_id::AbstractString = member_id(tau),
)
    cfg = YAML.load_file(BASE_YML)

    # Validated fast grid (s10/s11/s13 family), same as subexperiment A.
    cfg["z_max"] = 5000.0
    cfg["z_elem"] = z_elem
    cfg["z_stretch"] = true
    cfg["dz_bottom"] = 10.0
    cfg["dt_rad"] = "30mins"

    cfg["t_end"] = t_end
    cfg["job_id"] = job_id

    # Coupled-mode overlay keys (from lf1_clima_seaice_column_20d_overlay.yml).
    cfg["domain_type"] = "column"
    cfg["column_latlon"] = [80.0, 0.0]
    cfg["scm_surface_type"] = "sea_ice"
    cfg["ice_model"] = "clima_seaice_column"
    cfg["dt_cpl"] = "30secs"
    cfg["mode_name"] = "amip"
    cfg["surface_setup"] = "PrescribedSurface"
    cfg["prognostic_surface"] = "PrescribedSST"
    cfg["start_date"] = "20010101"
    cfg["checkpoint_dt"] = "90days"
    cfg["cloud_ice_formation"] = "TemperatureDependent"

    # CoupledSimulation internally does: output_dir_root = joinpath(coupler_output_dir, job_id)
    # So set coupler_output_dir to OUTPUT_ROOT, and the job_id appended by the coupler
    # gives us OUTPUT_ROOT/<job_id>/ as the member's output tree.
    cfg["coupler_output_dir"] = OUTPUT_ROOT

    # Per-member TOML: calibrated values with tau_dep replaced.
    member_toml = TOML.parsefile(CALIBRATED_TOML)
    member_toml["sublimation_deposition_timescale"] =
        Dict("value" => Float64(tau), "type" => "float")
    toml_dir = joinpath(OUTPUT_ROOT, job_id)
    mkpath(toml_dir)
    toml_path = joinpath(toml_dir, "member_params.toml")
    open(toml_path, "w") do io
        TOML.print(io, member_toml)
    end
    cfg["coupler_toml"] = [CALIBRATION_BASE_TOML, toml_path]

    check_config_keys!(cfg)

    # CoupledSimulation takes a path; write the generated YAML.
    cfg_path = joinpath(toml_dir, "generated_config.yml")
    YAML.write_file(cfg_path, cfg)
    return cfg_path
end

# ---------------------------------------------------------------------------
# Running one member
# ---------------------------------------------------------------------------

"""
    build_and_run(tau; kwargs...) -> (job_id, entry)

Worker-side member execution for the coupled sweep. Catches crashes.
Does NOT touch the manifest.
"""
function build_and_run(tau::Real; stage::AbstractString = "?",
    job_id::AbstractString = member_id(tau), kwargs...)
    cfg_path = member_config(tau; job_id, kwargs...)
    @info "Starting member" job_id tau stage
    t0 = time()
    ret_code = :setup_error
    try
        Random.seed!(1234)
        cs = CoupledSimulation(cfg_path)
        ClimaCoupler.run!(cs)
        ret_code = :success
    catch e
        @error "Member failed" job_id exception = (e, catch_backtrace())
    end
    walltime = time() - t0

    entry = Dict{String, Any}(
        "tau" => Float64(tau),
        "log10_tau" => log10(Float64(tau)),
        "stage" => stage,
        "ret_code" => string(ret_code),
        "walltime_s" => round(walltime, digits = 1),
        "finished_at" => string(Dates.now()),
        "z_elem" => get(kwargs, :z_elem, 60),
        "t_end" => get(kwargs, :t_end, "20days"),
    )
    if ret_code == :success
        try
            outdir = active_output_dir(job_id)
            entry["metrics"] = metrics(outdir)
        catch e
            @error "Metrics computation failed" job_id exception = (e, catch_backtrace())
            entry["metrics_error"] = sprint(showerror, e)
        end
    end
    @info "Finished member" job_id ret_code walltime = round(walltime, digits = 1)
    return job_id, entry
end

function run_member!(tau::Real; stage::AbstractString = "?", kwargs...)
    job_id = string(get(kwargs, :job_id, member_id(tau)))
    man = load_manifest()
    if haskey(man, job_id) && get(man[job_id], "ret_code", "") == "success"
        @info "Member already in manifest with ret_code success; skipping" job_id
        return man[job_id]
    end
    job_id, entry = build_and_run(tau; stage, kwargs...)
    man = load_manifest()
    man[job_id] = entry
    save_manifest(man)
    return entry
end

function active_output_dir(job_id)
    # Coupled output layout (ClimaCoupler v0.2.2):
    #   <coupler_output_dir>/output_active/clima_atmos/
    # The coupler's OutputPathGenerator creates output_0000/ + output_active symlink,
    # and ClimaAtmos writes directly into clima_atmos/ (output_dir_style RemovePreexisting).
    base = joinpath(OUTPUT_ROOT, job_id)
    coupled_path = joinpath(base, "output_active", "clima_atmos")
    isdir(coupled_path) && return coupled_path
    error("Cannot find atmos output for $job_id; expected $coupled_path")
end

# ---------------------------------------------------------------------------
# Manifest
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
# Metrics (same as subexperiment A)
# ---------------------------------------------------------------------------

function load_diag(outdir::AbstractString, short_name::AbstractString)
    path = joinpath(outdir, short_name * "_1h_average.nc")
    isfile(path) || error("diagnostic file not found: $path")
    NCDatasets.NCDataset(path) do ds
        t = Float64.(ds["time"][:]) ./ 3600.0
        A = Array(ds[short_name])
        nt = length(t)
        tdim = findfirst(==(nt), size(A))
        tdim === nothing && error("no dim of $short_name matches time length $nt")
        A = permutedims(A, vcat(tdim, setdiff(1:ndims(A), tdim)))
        return t, reshape(Float64.(A), nt, :)
    end
end

function metrics(outdir::AbstractString)
    t, clw = load_diag(outdir, "clw")
    _, lwp = load_diag(outdir, "lwp")
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
        "lwp_int" => sum(lwpv) * dt_days,
        "clivi_end" => cliviv[end],
        "max_clivi" => maximum(cliviv),
        "ts_end" => ts[end, 1],
    )
    condensed = (lwpv .> CLWVI_CLEAR) .| (cliviv .> CLIVI_CLEAR)
    m["clear_hour"] = any(condensed) ? t[findlast(condensed)] : 0.0

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
# Adaptive refinement (identical to subexperiment A)
# ---------------------------------------------------------------------------

const REFINEMENT_METRICS = (
    ("cloud_hours", identity),
    ("max_clw", identity),
    ("clivi_end", x -> log10(x + 1e-8)),
)

function sweep_points(man)
    pts = [(e["log10_tau"], e["metrics"])
           for e in values(man)
           if get(e, "ret_code", "") == "success" && haskey(e, "metrics") &&
              get(e, "stage", "") in ("anchor", "coarse", "adaptive", "dense")]
    sort!(pts, by = first)
    return pts
end

function next_taus(man; k = 1, min_dx = 0.1, tol = 0.15, dense_dx = 0.05, dense_jump = 0.5)
    pts = sweep_points(man)
    length(pts) < 2 && return Float64[]
    xs = first.(pts)

    norms = map(REFINEMENT_METRICS) do (name, f)
        vals = [f(p[2][name]) for p in pts]
        lo, hi = extrema(vals)
        hi - lo < eps() ? zero.(vals) : (vals .- lo) ./ (hi - lo)
    end

    candidates = Tuple{Float64, Float64}[]
    for i in 1:(length(pts) - 1)
        dx = xs[i + 1] - xs[i]
        jump = maximum(abs(n[i + 1] - n[i]) for n in norms)
        floor_dx = jump > dense_jump ? dense_dx : min_dx
        dx <= floor_dx && continue
        jump > tol && push!(candidates, (jump, (xs[i] + xs[i + 1]) / 2))
    end
    sort!(candidates, by = first, rev = true)
    return [10.0^x for (_, x) in candidates[1:min(k, end)]]
end

function next_tau(man; kwargs...)
    taus = next_taus(man; k = 1, kwargs...)
    return isempty(taus) ? nothing : taus[1]
end

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
    println(rpad("job_id", 30), rpad("log10", 7), rpad("ret", 10), rpad("hrs", 5),
        rpad("max_clw", 10), rpad("lwp_int", 9), rpad("clivi_end", 10),
        rpad("ts_end", 8), "clear_h")
    for (job_id, e) in rows
        m = get(e, "metrics", Dict())
        fmt(k, d = "-") = haskey(m, k) ? string(round(m[k], sigdigits = 3)) : d
        println(rpad(job_id, 30),
            rpad(string(round(get(e, "log10_tau", NaN), digits = 2)), 7),
            rpad(get(e, "ret_code", "?"), 10),
            rpad(fmt("cloud_hours"), 5),
            rpad(fmt("max_clw"), 10),
            rpad(fmt("lwp_int"), 9),
            rpad(fmt("clivi_end"), 10),
            rpad(fmt("ts_end"), 8),
            fmt("clear_hour"))
    end
end
