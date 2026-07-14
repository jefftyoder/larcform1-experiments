# Phase 0: Larcform1 SCM coupled to prescribed slab sea ice via ClimaCoupler.
#
# Merges the validated standalone atmos config with a coupler overlay
# (configs/lf1_prescribed_ice_overlay.yml), validates that every key is
# actually recognized by the coupler or atmos (guarding against silently
# ignored config arguments), then builds and runs the CoupledSimulation.
#
# Usage (from repo root):
#   julia --project experiments/sea-ice/run_prescribed_ice.jl
#   julia --project experiments/sea-ice/run_prescribed_ice.jl --dry-run   # setup + config check only

import YAML
import ClimaAtmos            # triggers ClimaCouplerClimaAtmosExt
import ClimaCoupler
import ClimaCoupler: Input, CoupledSimulation, run!
# Upstream bug workaround (ClimaCoupler v0.2.2, SCM sea_ice mode): the
# PrescribedIceSimulation's daily SIC callback re-reads HadISST data with no
# column-mode guard, clobbering the init-time `ice_fraction = 1` and tripping
# the area-fraction ≈ 1 assertion in `update_surface_fractions!` (at 80°N 0°E
# the January value is ~0.44 — near the real ice edge — so this crashes at the
# first day boundary). The ice cache already carries `domain_type`; keep full
# cover in column mode, matching both the init path and the ice_rhs! guard.
# TODO: remove once fixed upstream (report against CliMA/ClimaCoupler.jl#1860).
function ClimaCoupler.Models.read_sic_data!(integrator)
    if integrator.p.domain_type == "column"
        integrator.p.area_fraction .= 1
    else
        ClimaCoupler.Models.evaluate!(
            integrator.p.area_fraction,
            integrator.p.SIC_timevaryinginput,
            integrator.t,
        )
    end
end

# The coupler's Input module parses the process ARGS internally; strip our own
# flag first so ArgParse never sees it.
const DRY_RUN = "--dry-run" in ARGS
filter!(a -> a != "--dry-run", ARGS)

const REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const ATMOS_CONFIG = joinpath(
    REPO_ROOT,
    "ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml",
)
const OVERLAY_CONFIG = joinpath(@__DIR__, "configs/lf1_prescribed_ice_overlay.yml")

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
merged_path = joinpath(@__DIR__, "configs/generated_lf1_prescribed_ice.yml")
YAML.write_file(merged_path, merged)
@info "Merged config written" merged_path

cs = CoupledSimulation(merged_path)

if DRY_RUN
    @info "Dry run: CoupledSimulation constructed successfully; skipping run!" typeof(cs)
else
    run!(cs)
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
