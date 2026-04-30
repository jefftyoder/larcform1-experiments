# Larcform1 Coupled SCM Driver 
#
# Run from the repo root:
#   julia -t auto --project experiments/larcform1/larcform1_driver.jl
#
# Or interactively:
#   julia -t auto --project
#   julia> include("experiments/larcform1_driver.jl")
#
# To use a different config:
#   julia -t auto --project experiments/larcform1_driver.jl \
#     --config_file path/to/other_config.yml


# Prepare environment
# --------------------------------------------------------------------------------------------
# Abbreviated stacktraces (ClimaCore types are heavily parametrized)
redirect_stderr(IOContext(stderr, :stacktrace_types_limited => Ref(true)))

import Random                    # is this import necessary?
Random.seed!(1234)
using ClimaCoupler               # brings in CoupledSimulation, run!, postprocess, Input
# Trigger ClimaCouplerClimaAtmosExt (required — provides AtmosSimulation)
import ClimaAtmos  # triggers ClimaCouplerClimaAtmosExt; ClimaAtmos itself imports AtmosphericProfilesLibrary
# Resolve config file: command-line arg or default to our Larcform1 slabocean config
const DEFAULT_CONFIG = joinpath(@__DIR__, "..", "configs", "larcform1_full_slabocean.yml")

config_file = if "--config_file" in ARGS
    ARGS[findfirst(==("--config_file"), ARGS) + 1]
else
    DEFAULT_CONFIG
end

# Instantiate simulation
# --------------------------------------------------------------------------------------------
@info "Config: $config_file"
# Set up and run the coupled simulation
cs = CoupledSimulation(config_file)

# Run simulation
# --------------------------------------------------------------------------------------------
try
    @info "Beginning simulation run"
    @time run!(cs)
catch e
    @error "Simulation run failed with error" exception=e
    rethrow(e)
end

# Postprocessing
# --------------------------------------------------------------------------------------------
@info "Beginning postprocessing"
@info "Activating buildkite environment"
atmospath = joinpath(@__DIR__, "..", "ClimaAtmos.jl")
import Pkg; Pkg.activate(joinpath(atmospath, ".buildkite"))

@info "Loading ci_plots.jl"
include(joinpath(atmospath, "post_processing", "ci_plots.jl"))

# copy call to make_plots pattern from ./buildkite/ci_driver.jl
# Try making plots over only first 10 days?
@info "Making plots"
make_plots(Val(:larcform1), [cs.dir_paths.atmos_output_dir])

# Convert to Pithan2016-compatible NetCDF
@info "Converting output to Pithan2016 format"
pithan_script = joinpath(@__DIR__, "..", "scripts", "convert_to_pithan.py")
try
    run(`python3 $pithan_script
        --nc-dir $(cs.dir_paths.atmos_output_dir)
        --suffix 1h_average
        --model-name ClimaLarcform1`)
catch e
    @warn "convert_to_pithan.py failed — skipping Pithan conversion" exception=e
end

@info "run using: $config_file complete."
@info "Output at: $(cs.dir_paths.atmos_output_dir)" 