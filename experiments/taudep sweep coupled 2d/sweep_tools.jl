# Tools for the coupled 2D tau sweep (lf1e-taudep-1, subexperiment C).
#
# 2D grid sweep over sublimation_deposition_timescale (tau_dep) and
# condensation_evaporation_timescale (tau_ce), with:
#   1. UKI-calibrated microphysics parameters as baseline (lf1e-clw-calibration-1)
#   2. ClimaSeaIce+snow coupled surface (experiments/sea-ice/ Phase 2 component)
#   3. ConstantTimescale ice formation (default; NOT TemperatureDependent)
#
# Execution path: ClimaCoupler CoupledSimulation (not standalone ClimaAtmos).
# Environment: root env (--project), NOT buildkite.
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

const OUTPUT_ROOT = joinpath(REPO_ROOT, "output", "lf1e-taudep-1-coupled-2d")
const MANIFEST_PATH = joinpath(OUTPUT_ROOT, "manifest.toml")

const CLW_THRESHOLD = 1e-4      # kg/kg, on max_z clw
const CLWVI_CLEAR = 1e-3        # kg/m^2, "column effectively liquid-free"
const CLIVI_CLEAR = 1e-4        # kg/m^2, "column effectively ice-free"

# Calibrated baseline values.
const CALIBRATED_TAU_DEP = 66.59059810650213
const CALIBRATED_TAU_CE  = 101.06738506498924

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

function tau_tag(tau_dep::Real, tau_ce::Real)
    dep = replace(string(round(log10(tau_dep), digits = 2)), "." => "p", "-" => "m")
    ce  = replace(string(round(log10(tau_ce),  digits = 2)), "." => "p", "-" => "m")
    return "dep$(dep)_ce$(ce)"
end

member_id(tau_dep::Real, tau_ce::Real) = "lf1e_taudep2d_" * tau_tag(tau_dep, tau_ce)

"""
    member_config(tau_dep, tau_ce; z_elem, t_end, job_id) -> config_path

Build a coupled-mode config for one 2D sweep member. Returns the path to a
generated YAML file (CoupledSimulation takes a path, not a dict).

The per-member TOML starts from the UKI-calibrated values and replaces both
sublimation_deposition_timescale and condensation_evaporation_timescale with
the swept values. All other calibrated parameters remain at their calibrated
values. Ice formation uses ConstantTimescale (the ClimaAtmos default).
"""
function member_config(tau_dep::Real, tau_ce::Real;
    z_elem::Int = 60,
    t_end::AbstractString = "20days",
    job_id::AbstractString = member_id(tau_dep, tau_ce),
)
    cfg = YAML.load_file(BASE_YML)

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
    # No cloud_ice_formation override: defaults to ConstantTimescale.

    cfg["coupler_output_dir"] = OUTPUT_ROOT

    # Per-member TOML: calibrated values with both timescales replaced.
    member_toml = TOML.parsefile(CALIBRATED_TOML)
    member_toml["sublimation_deposition_timescale"] =
        Dict("value" => Float64(tau_dep), "type" => "float")
    member_toml["condensation_evaporation_timescale"] =
        Dict("value" => Float64(tau_ce), "type" => "float")
    toml_dir = joinpath(OUTPUT_ROOT, job_id)
    mkpath(toml_dir)
    toml_path = joinpath(toml_dir, "member_params.toml")
    open(toml_path, "w") do io
        TOML.print(io, member_toml)
    end
    cfg["coupler_toml"] = [CALIBRATION_BASE_TOML, toml_path]

    check_config_keys!(cfg)

    cfg_path = joinpath(toml_dir, "generated_config.yml")
    YAML.write_file(cfg_path, cfg)
    return cfg_path
end

# ---------------------------------------------------------------------------
# Running one member
# ---------------------------------------------------------------------------

"""
    build_and_run(tau_dep, tau_ce; kwargs...) -> (job_id, entry)

Worker-side member execution. Catches crashes. Does NOT touch the manifest.
"""
function build_and_run(tau_dep::Real, tau_ce::Real; stage::AbstractString = "?",
    job_id::AbstractString = member_id(tau_dep, tau_ce), kwargs...)
    cfg_path = member_config(tau_dep, tau_ce; job_id, kwargs...)
    @info "Starting member" job_id tau_dep tau_ce stage
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
        "tau_dep" => Float64(tau_dep),
        "log10_tau_dep" => log10(Float64(tau_dep)),
        "tau_ce" => Float64(tau_ce),
        "log10_tau_ce" => log10(Float64(tau_ce)),
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

function run_member!(tau_dep::Real, tau_ce::Real; stage::AbstractString = "?", kwargs...)
    job_id = string(get(kwargs, :job_id, member_id(tau_dep, tau_ce)))
    man = load_manifest()
    if haskey(man, job_id) && get(man[job_id], "ret_code", "") == "success"
        @info "Member already in manifest with ret_code success; skipping" job_id
        return man[job_id]
    end
    job_id, entry = build_and_run(tau_dep, tau_ce; stage, kwargs...)
    man = load_manifest()
    man[job_id] = entry
    save_manifest(man)
    return entry
end

function active_output_dir(job_id)
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
# Grid generation
# ---------------------------------------------------------------------------

function coarse_grid()
    xs = [10.0^e for e in 1.0:1.0:7.0]
    return [(d, c) for d in xs for c in xs]
end

function refine_grid(; dep_range, ce_range, step = 0.5)
    deps = [10.0^e for e in dep_range[1]:step:dep_range[2]]
    ces  = [10.0^e for e in ce_range[1]:step:ce_range[2]]
    return [(d, c) for d in deps for c in ces]
end

# ---------------------------------------------------------------------------
# Metrics (same as subexperiments A/B)
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
# Reporting
# ---------------------------------------------------------------------------

function summary_table(man = load_manifest())
    rows = sort(collect(man),
        by = kv -> (get(kv[2], "log10_tau_dep", Inf), get(kv[2], "log10_tau_ce", Inf)))
    println(rpad("job_id", 40), rpad("lg_dep", 7), rpad("lg_ce", 7), rpad("ret", 10),
        rpad("hrs", 5), rpad("max_clw", 10), rpad("lwp_int", 9),
        rpad("clivi_end", 10), rpad("ts_end", 8), "clear_h")
    for (job_id, e) in rows
        m = get(e, "metrics", Dict())
        fmt(k, d = "-") = haskey(m, k) ? string(round(m[k], sigdigits = 3)) : d
        println(rpad(job_id, 40),
            rpad(string(round(get(e, "log10_tau_dep", NaN), digits = 2)), 7),
            rpad(string(round(get(e, "log10_tau_ce", NaN), digits = 2)), 7),
            rpad(get(e, "ret_code", "?"), 10),
            rpad(fmt("cloud_hours"), 5),
            rpad(fmt("max_clw"), 10),
            rpad(fmt("lwp_int"), 9),
            rpad(fmt("clivi_end"), 10),
            rpad(fmt("ts_end"), 8),
            fmt("clear_hour"))
    end
end
