# 20-day Pithan production suite: three coupled surface models under identical
# calibrated-microphysics atmospheres (the s11 reference numerics of
# "experiments/20day run/"), run sequentially in one process so JIT is paid once.
#
#   1. lf1_larcform1_ice_20d              — Phase 1 slab ice (Holloway–Manabe)
#   2. lf1_clima_seaice_column_nosnow_20d — ClimaSeaIce bare 1 m ice
#   3. lf1_clima_seaice_column_20d        — ClimaSeaIce 1 m ice + 0.1 m w.e. snow
#
# Usage (from repo root):
#   julia --project experiments/sea-ice/run_20day_suite.jl             # run all
#   julia --project experiments/sea-ice/run_20day_suite.jl --dry-run   # construct only
#
# On Stratus, launch via tmux (see PLAN.md / CLAUDE.md).

import YAML
import ClimaAtmos            # triggers ClimaCouplerClimaAtmosExt
import ClimaCoupler
import ClimaCoupler: Input, CoupledSimulation, run!

# Register both custom ice components before the coupler constructs models.
include(joinpath(@__DIR__, "components", "larcform1_ice.jl"))
include(joinpath(@__DIR__, "components", "clima_seaice_column.jl"))

# Plotting is optional (needs the Makie stack); load it once up front.
const HAVE_PLOTS = try
    include(joinpath(@__DIR__, "postprocess_plots.jl"))
    true
catch err
    @warn "plotting stack unavailable; runs will skip summary plots" err
    false
end

const DRY_RUN = "--dry-run" in ARGS
filter!(a -> a != "--dry-run", ARGS)

const REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const ATMOS_CONFIG = joinpath(
    REPO_ROOT,
    "ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml",
)
const OVERLAYS = [
    joinpath(@__DIR__, "configs/lf1_larcform1_ice_20d_overlay.yml"),
    joinpath(@__DIR__, "configs/lf1_clima_seaice_column_nosnow_20d_overlay.yml"),
    joinpath(@__DIR__, "configs/lf1_clima_seaice_column_20d_overlay.yml"),
]

# --- Config hygiene (same check as the single-run drivers) ---
coupler_defaults = Input.parse_commandline(Input.argparse_settings())
atmos_defaults = Input.atmos_default_config_dict()
known_keys = union(keys(coupler_defaults), keys(atmos_defaults))

function build_merged_config(overlay_path)
    atmos_dict = YAML.load_file(ATMOS_CONFIG)
    overlay_dict = YAML.load_file(overlay_path)
    ours = union(keys(atmos_dict), keys(overlay_dict))
    unknown = sort(collect(setdiff(ours, known_keys)))
    isempty(unknown) || error(
        "Config keys not recognized by ClimaCoupler or ClimaAtmos defaults " *
        "(would be silently ignored): $unknown",
    )
    merged = merge(atmos_dict, overlay_dict)
    merged_path = joinpath(
        @__DIR__,
        "configs/generated_$(merged["job_id"]).yml",
    )
    YAML.write_file(merged_path, merged)
    return merged_path
end

function postrun!(cs)
    ice_sim = cs.model_sims.ice_sim
    if ice_sim isa ClimaSeaIceColumnSimulation
        @info "Sea-ice conservation check (ΔE vs −∫Q dt)" report = conservation_report(ice_sim)
        history_path = joinpath(
            dirname(cs.dir_paths.atmos_output_dir),
            "seaice_column_history.csv",
        )
        cols = keys(first(ice_sim.history))
        open(history_path, "w") do io
            println(io, join(string.(cols), ','))
            for row in ice_sim.history
                println(io, join((string(getindex(row, c)) for c in cols), ','))
            end
        end
        @info "Sea-ice history written" history_path n = length(ice_sim.history)
    end
    HAVE_PLOTS && try
        Base.invokelatest(
            make_column_diagnostics_plots,
            dirname(cs.dir_paths.atmos_output_dir);
            artifacts_dir = cs.dir_paths.artifacts_dir,
        )
    catch err
        @warn "summary plotting failed; NetCDF output is unaffected" err
    end
    return nothing
end

results = String[]
for overlay in OVERLAYS
    merged_path = build_merged_config(overlay)
    @info "=== Suite run: $(basename(overlay)) ===" merged_path
    try
        cs = CoupledSimulation(merged_path)
        if DRY_RUN
            @info "Dry run: constructed OK" typeof(cs).name.name
            push!(results, "$(basename(overlay)): constructed OK (dry run)")
        else
            run!(cs)
            postrun!(cs)
            push!(results, "$(basename(overlay)): completed")
        end
        cs = nothing
        GC.gc()
    catch err
        @error "Suite member failed; continuing with the next one" overlay err
        push!(results, "$(basename(overlay)): FAILED ($(first(sprint(showerror, err, context = :limit => true), 200)))")
    end
end

@info "=== 20-day suite finished ===" results
