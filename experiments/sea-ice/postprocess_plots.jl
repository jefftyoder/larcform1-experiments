# Column-aware summary plots for coupled SCM runs.
#
# ClimaCoupler's `postprocess`/`make_diagnostics_plots` (v0.2.2) mishandles
# column output in two ways:
#   1. Surface diagnostics in a column have only a `time` dimension, but the
#      surface group is still plotted with `time = LAST_SNAP`, slicing to zero
#      dimensions ("Sliced variable has 0 dimensions"). The right plot is a
#      time series with no time slicing.
#   2. `make_plots_generic` never flushes its final page when constant/NaN
#      variables are skipped after a plotted one, silently dropping plots.
# TODO: report both against CliMA/ClimaCoupler.jl (with #1860 column-mode SIC bug).
#
# This helper reuses the upstream extension internals but plots profiles at the
# last snapshot and surface variables as time series, pre-filtering constant
# variables. Requires the Makie stack (CairoMakie, ClimaCoreMakie, GeoMakie,
# Poppler_jll) — carried by the root Project.toml.

import CairoMakie, ClimaCoreMakie, GeoMakie, Poppler_jll, Printf
import ClimaAnalysis
import ClimaCoupler

"""
    make_column_diagnostics_plots(output_dir; artifacts_dir)

Make summary PDFs (profiles at final time, surface time series) for every
component diagnostics directory under `output_dir` (e.g. `clima_atmos`,
`clima_coupler`) that contains NetCDF output. Plots land in `artifacts_dir`
(default: `joinpath(output_dir, "artifacts")`).
"""
function make_column_diagnostics_plots(
    output_dir::AbstractString;
    artifacts_dir = joinpath(output_dir, "artifacts"),
)
    ext = Base.get_extension(ClimaCoupler, :ClimaCouplerMakieExt)
    isnothing(ext) &&
        error("ClimaCouplerMakieExt not loaded; import the Makie stack first")
    CAN = ClimaAnalysis
    mkpath(artifacts_dir)

    for component in readdir(output_dir)
        component_dir = joinpath(output_dir, component)
        isdir(component_dir) || continue
        simdir = CAN.SimDir(component_dir)
        short_names = CAN.available_vars(simdir)
        isempty(short_names) && continue
        prefix = replace(component, "clima_" => "") * "_"

        vars = map(collect(short_names)) do short_name
            reductions = CAN.available_reductions(simdir; short_name)
            reduction = "average" in reductions ? "average" : first(reductions)
            periods = CAN.available_periods(simdir; short_name, reduction)
            period = "1d" in periods ? "1d" : first(periods)
            get(simdir; short_name, reduction, period)
        end
        # Skip constant fields up front (also dodges the last-page flush bug)
        constant = filter(v -> minimum(v.data) == maximum(v.data), vars)
        isempty(constant) || @info "Skipping constant $(component) diagnostics" *
              " " * join(CAN.short_name.(constant), ", ")
        vars = filter(v -> minimum(v.data) != maximum(v.data), vars)
        isempty(vars) && continue

        is_3d = v -> CAN.has_altitude(v) || CAN.has_pressure(v)
        profiles = filter(is_3d, vars)
        timeseries = filter(!is_3d, vars)

        isempty(profiles) || ext.make_plots_generic(
            component_dir,
            artifacts_dir,
            profiles;
            time = ext.LAST_SNAP,
            output_name = prefix * "summary_profiles",
            more_kwargs = ext.YLINEARSCALE,
        )
        isempty(timeseries) || ext.make_plots_generic(
            component_dir,
            artifacts_dir,
            timeseries;
            output_name = prefix * "summary_timeseries",
        )
    end
    @info "Summary plots written" artifacts_dir readdir(artifacts_dir)
    return artifacts_dir
end
