# Phase 2: Larcform1 SCM coupled to ClimaSeaIce ice + snow via ClimaCoupler.
#
# Includes the custom `clima_seaice_column` component (registered via Interfacer
# Val-dispatch — no ClimaCoupler fork), merges the validated standalone atmos
# config with a coupler overlay (configs/lf1_clima_seaice_column_overlay.yml),
# validates that every key is actually recognized by the coupler or atmos
# (guarding against silently ignored config arguments), then builds and runs
# the CoupledSimulation.
#
# Usage (from repo root):
#   julia --project experiments/sea-ice/run_clima_seaice_column.jl
#   julia --project experiments/sea-ice/run_clima_seaice_column.jl --dry-run   # setup + config check only
#
# Snow on/off: point the overlay's `coupler_toml` at a parameter file containing
#   [seaice_column_enable_snow]
#   value = false
#   type = "bool"

import YAML
import ClimaAtmos            # triggers ClimaCouplerClimaAtmosExt
import ClimaCoupler
import ClimaCoupler: Input, CoupledSimulation, run!

# Register the custom ice component before the coupler constructs component models.
include(joinpath(@__DIR__, "components", "clima_seaice_column.jl"))

# The coupler's Input module parses the process ARGS internally; strip our own
# flag first so ArgParse never sees it.
const DRY_RUN = "--dry-run" in ARGS
filter!(a -> a != "--dry-run", ARGS)

const REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const ATMOS_CONFIG = joinpath(
    REPO_ROOT,
    "ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml",
)
const OVERLAY_CONFIG = joinpath(@__DIR__, "configs/lf1_clima_seaice_column_overlay.yml")

atmos_dict = YAML.load_file(ATMOS_CONFIG)
overlay_dict = YAML.load_file(OVERLAY_CONFIG)

# --- Config hygiene: fail loudly on keys neither the coupler nor atmos knows ---
coupler_defaults = Input.parse_commandline(Input.argparse_settings())
atmos_defaults = Input.atmos_default_config_dict()
known_keys = union(keys(coupler_defaults), keys(atmos_defaults))
ours = union(keys(atmos_dict), keys(overlay_dict))
unknown = sort(collect(setdiff(ours, known_keys)))
if !isempty(unknown)
    error(
        "Config keys not recognized by ClimaCoupler or ClimaAtmos defaults " *
        "(would be silently ignored): $unknown",
    )
end

# Report which standalone atmos keys the overlay overrides, then merge (overlay wins)
overridden = sort(collect(intersect(keys(atmos_dict), keys(overlay_dict))))
isempty(overridden) || @info "Overlay overrides standalone atmos keys" overridden
merged = merge(atmos_dict, overlay_dict)

# Write the merged config and hand it to the coupler's own entrypoint, so the
# default-merging, component-dt parsing, and restart handling are all upstream code.
merged_path = joinpath(@__DIR__, "configs/generated_lf1_clima_seaice_column.yml")
YAML.write_file(merged_path, merged)
@info "Merged config written" merged_path

cs = CoupledSimulation(merged_path)

if DRY_RUN
    @info "Dry run: CoupledSimulation constructed successfully; skipping run!" typeof(cs)
else
    run!(cs)

    ice_sim = cs.model_sims.ice_sim
    @info "Sea-ice conservation check (ΔE vs −∫Q dt)" report = conservation_report(ice_sim)

    # Dump the per-coupled-step ice state history (the component keeps it in
    # memory; the coupler's NetCDF diagnostics don't cover custom ice fields).
    history_path =
        joinpath(dirname(cs.dir_paths.atmos_output_dir), "seaice_column_history.csv")
    cols = keys(first(ice_sim.history))
    open(history_path, "w") do io
        println(io, join(string.(cols), ','))
        for row in ice_sim.history
            println(io, join((string(getindex(row, c)) for c in cols), ','))
        end
    end
    @info "Sea-ice history written" history_path n = length(ice_sim.history)

    # Summary plots. The upstream `postprocess(cs)` mishandles column output
    # (see postprocess_plots.jl header); use the column-aware helper instead.
    # The NetCDF diagnostics are written during run! regardless.
    try
        include(joinpath(@__DIR__, "postprocess_plots.jl"))
        make_column_diagnostics_plots(
            dirname(cs.dir_paths.atmos_output_dir);
            artifacts_dir = cs.dir_paths.artifacts_dir,
        )
    catch err
        @warn "summary plotting failed; NetCDF output is unaffected" err
    end
end
