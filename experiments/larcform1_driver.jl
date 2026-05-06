# Larcform1 Coupled SCM Driver 
#
# Run from the repo root:
#   julia -t auto --project experiments/larcform1_driver.jl
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

# Run with default config unless one is profided from the command line
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

@info "run using: $config_file complete."
@info "Output at: $(cs.dir_paths.atmos_output_dir)" 

@info "Beginning postprocessing"
atmospath = joinpath(@__DIR__, "..", "ClimaAtmos.jl")
atmos_output_dir = cs.dir_paths.atmos_output_dir
postprocess_script = joinpath(@__DIR__, "..", "postprocessing", "postprocess.jl")
run(`julia --project=$(joinpath(atmospath, ".buildkite")) $postprocess_script $atmos_output_dir`)