# read in ARGS
atmos_output_dir = ARGS[1]

@info "Activating buildkite environment"
atmospath = joinpath(@__DIR__, "..", "ClimaAtmos.jl")
import Pkg; Pkg.activate(joinpath(atmospath, ".buildkite"))

@info "Loading ci_plots.jl"
include(joinpath(atmospath, "post_processing", "ci_plots.jl"))

# copy call to make_plots pattern from ./buildkite/ci_driver.jl
# Try making plots over only first 10 days?
@info "Making plots"
make_plots(Val(:larcform1), [atmos_output_dir])

# Convert to Pithan2016-compatible NetCDF
@info "Converting output to Pithan2016 format"
pithan_script = joinpath(@__DIR__, "..", "scripts", "convert_to_pithan.py")
try
    run(`python3 $pithan_script
        --nc-dir $(atmos_output_dir)
        --suffix 1h_average
        --model-name ClimaLarcform1_coupled`)
catch e
    @warn "convert_to_pithan.py failed — skipping Pithan conversion" exception=e
end



#=
Need to activate path with Makie, GeoMakie, etc.
@info "running coupler postprocessing"
using Makie, GeoMakie, CairoMakie, ClimaCoreMakie, Poppler_jll, Printf
postprocess(cs)
=#
