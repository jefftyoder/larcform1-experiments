# Device benchmark for the calibrated Larcform1 SCM over ClimaSeaIce ice + snow.
#
# Runs ONE (device, t_end) combination in ONE process and reports its timing
# breakdown. The driver (`bench.sh`) invokes this once per device so that
# *total* wall time — JIT/compilation included — is measured honestly: a warm
# process would hide the compilation cost, which is exactly the cost a user
# actually pays, and which differs enormously between CPU and CUDA.
#
# Usage:
#   julia --project experiments/gpu-benchmark/run_device_benchmark.jl \
#       --device CPUSingleThreaded --t-end 20days --label mac_cpu1
#
# --device is passed straight through to the ClimaAtmos/ClimaCoupler `device`
# config key: CPUSingleThreaded | CPUMultiThreaded | CUDADevice.
#
# NOTE on CPUMultiThreaded: the device must ALSO be given threads by the julia
# launcher (`julia -t N`). ClimaAtmos promotes to CPUMultiThreaded whenever
# Threads.nthreads() > 1 (src/config/type_getters.jl:296), so `-t N` alone
# already changes the device — we set the key explicitly anyway to keep the
# generated config self-describing.

const T_PROCESS_START = time()  # as early as possible; bash still wraps the true total

# --- CLI (parsed before the heavy imports, so we know whether to load CUDA) ---
function getflag(name, default)
    i = findfirst(==(name), ARGS)
    return isnothing(i) ? default : ARGS[i + 1]
end

const DEVICE = getflag("--device", "CPUSingleThreaded")
const T_END = getflag("--t-end", "20days")
const LABEL = getflag("--label", lowercase(DEVICE))

# --restart <hdf5>: start from a checkpoint instead of building the initial
# condition. Required on CUDA. The Larcform1 IC broadcasts `setup.profiles.p`,
# a `ColumnInterpolatableField`, into the state field; on GPU that broadcast is a
# CUDA kernel, and the object is NOT isbits (it wraps a host Matrix and an
# Interpolations.Extrapolation over a host Vector), so kernel compilation fails.
# ClimaAtmos says so itself: ColumnInterpolatableField's docstring reads "not
# GPU-compatible ... only use this for initialization" — but for a column SCM the
# initialization *is* a device kernel.
#
# Restarting sidesteps it: `handle_restart` reads Y straight from HDF5 into the
# device's array type and takes the spaces from Y (ClimaAtmos/src/simulation/
# restart.jl:44-70), so the IC broadcast never runs. Time-stepping — the thing
# being benchmarked — is untouched, and the state is bit-identical to the CPU
# run that produced the checkpoint.
const RESTART = getflag("--restart", "")
# Steps are counted from the restart time, not from zero.
const T_START = getflag("--t-start", "0secs")
# Every flag must be captured HERE, before `empty!(ARGS)` below.
const CHECKPOINT_DT = getflag("--checkpoint-dt", "")

# --no-progress: silence the walltime-progress reporter.
#
# On a RESTARTED run it crashes:
#   InexactError: Int64(NaN)
#   ClimaUtilities.OnlineLogging._time_and_units_str → Nanosecond(ceil(1e9*NaN))
# a NaN ETA in the *reporter*, not a NaN in the model state.
#
# It cannot be switched off by config, because ClimaCoupler's choice of reporter
# is inverted (SimCoordinator.jl:467): with `atmos_log_progress: true` ClimaAtmos
# reports; with `false` the COUPLER installs its own `capped_geometric_walltime_cb`
# instead — and both land in the same `report_walltime`. One of the two always
# runs. So override the function itself with a no-op (its signature is untyped,
# `report_walltime(wt, integrator)`, so this genuinely replaces it rather than
# adding a less-specific method that never gets dispatched to).
#
# This only suppresses log lines; it touches no physics and no timing.
const NO_PROGRESS = "--no-progress" in ARGS

DEVICE in ("CPUSingleThreaded", "CPUMultiThreaded", "CUDADevice") ||
    error("unknown --device $DEVICE")

# ClimaCoupler's `parse_commandline` reads the GLOBAL `ARGS`, and it rejects any
# flag it does not define — our `--t-end`/`--label` would make it print its usage
# and exit. Our flags are already captured above, so clear ARGS before any
# coupler config parsing happens (both in build_config and in CoupledSimulation).
empty!(ARGS)

import Dates
import YAML
import ClimaComms

# The GPU methods live in *package extensions* (`ClimaComms.array_type(::CUDADevice)`
# in ClimaCommsCUDAExt; the kernels in ClimaCoreCUDAExt), and Julia only loads an
# extension once its trigger package is loaded in the session. Having CUDA merely
# installed is NOT enough: without an explicit `import CUDA`, the extensions stay
# dormant and column-grid construction dies with
#   MethodError: no method matching array_type(::ClimaComms.CUDADevice)
# So load CUDA before the Clima stack, and assert it is actually usable rather
# than silently benchmarking a CPU fallback.
if DEVICE == "CUDADevice"
    @eval import CUDA
    CUDA.functional() ||
        error("--device CUDADevice, but CUDA.functional() == false on $(gethostname())")
    @info "CUDA loaded" gpu = CUDA.name(CUDA.device())
end

import ClimaAtmos            # triggers ClimaCouplerClimaAtmosExt
import ClimaCoupler
import ClimaCoupler: Input, CoupledSimulation, run!
import ClimaUtilities

# See the NO_PROGRESS comment above: replace the progress reporter with a no-op.
if NO_PROGRESS
    @eval ClimaUtilities.OnlineLogging report_walltime(wt, integrator) = nothing
    @info "progress reporter disabled (restart-safe benchmark shim)"
end

const REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))

# The sea-ice component registration must happen before the coupler builds models.
# This is the SAME component used by the production 20-day suite.
include(joinpath(REPO_ROOT, "experiments", "sea-ice", "components", "clima_seaice_column.jl"))

# --- Config ------------------------------------------------------------------
const ATMOS_CONFIG = joinpath(
    REPO_ROOT,
    "ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml",
)
# The production "calibrated + sea ice + snow" configuration.
const OVERLAY = joinpath(
    REPO_ROOT,
    "experiments/sea-ice/configs/lf1_clima_seaice_column_20d_overlay.yml",
)

# Unique job_id per (label): distinct output dirs, so concurrent or repeated
# benchmark runs cannot collide and corrupt each other's output.
const JOB_ID = "lf1_gpubench_$(LABEL)"

function build_config()
    merged = merge(YAML.load_file(ATMOS_CONFIG), YAML.load_file(OVERLAY))

    merged["device"] = DEVICE
    merged["t_end"] = T_END
    merged["job_id"] = JOB_ID
    merged["coupler_output_dir"] = joinpath("output", "gpu-benchmark", JOB_ID)

    if !isempty(RESTART)
        isfile(RESTART) || error("--restart file not found: $RESTART")
        merged["restart_file"] = RESTART
    end
    # Emit a checkpoint at the end of a short CPU run, to seed the GPU restart.
    isempty(CHECKPOINT_DT) || (merged["checkpoint_dt"] = CHECKPOINT_DT)

    # Guard against silently-ignored keys (the failure mode this repo has been
    # bitten by before): every key must be known to ClimaCoupler or ClimaAtmos.
    known = union(
        keys(Input.parse_commandline(Input.argparse_settings())),
        keys(Input.atmos_default_config_dict()),
    )
    unknown = sort(collect(setdiff(keys(merged), known)))
    isempty(unknown) && return merged
    error("config keys not recognized (would be silently ignored): $unknown")
end

# `coupler_toml` paths in the overlay resolve relative to cwd, so the benchmark
# must be launched from the repo root. Fail loudly rather than silently running
# with uncalibrated ClimaParams defaults.
isfile(joinpath(
    "experiments", "clw calibration", "configs", "toml", "calibrated_uki1_final.toml",
)) || error("run from the repo root: calibrated TOML not resolvable from $(pwd())")

const CONFIG = build_config()
const CONFIG_PATH = joinpath(@__DIR__, "configs", "generated_$(JOB_ID).yml")
mkpath(dirname(CONFIG_PATH))
YAML.write_file(CONFIG_PATH, CONFIG)

@info "Device benchmark starting" LABEL DEVICE T_END nthreads = Threads.nthreads() JOB_ID

# --- Timed phases ------------------------------------------------------------
# t_setup folds in the bulk of JIT/CUDA compilation (model construction compiles
# the tendency and, on CUDA, the GPU kernels). t_solve is pure time-stepping.
t0 = time()
cs = CoupledSimulation(CONFIG_PATH)
t_setup = time() - t0

device = ClimaComms.context(cs.model_sims.atmos_sim.integrator.u.c).device
@info "Constructed" device_in_use = typeof(device) t_setup

t1 = time()
run!(cs)
t_solve = time() - t1

t_total_internal = time() - T_PROCESS_START

# Steps actually taken, for a per-step cost that is comparable across t_end.
# Parsed locally rather than via a ClimaCoupler internal, so a rename upstream
# cannot crash the script *after* the expensive run has completed.
function duration_seconds(s::AbstractString)
    m = match(r"^(\d+(?:\.\d+)?)\s*(secs?|mins?|hours?|days?)$", strip(s))
    isnothing(m) && error("cannot parse duration: $s")
    n = parse(Float64, m.captures[1])
    unit = m.captures[2]
    mult = startswith(unit, "sec") ? 1 :
           startswith(unit, "min") ? 60 :
           startswith(unit, "hour") ? 3600 : 86400
    return n * mult
end

# A restarted run steps from T_START to T_END, not from zero — counting from zero
# would understate its ms/step and flatter the GPU.
nsteps = round(
    Int,
    (duration_seconds(T_END) - duration_seconds(T_START)) /
    duration_seconds(CONFIG["dt"]),
)

@info(
    "=== BENCHMARK RESULT ===",
    label = LABEL,
    device = DEVICE,
    threads = Threads.nthreads(),
    t_end = T_END,
    nsteps,
    t_setup_s = round(t_setup; digits = 1),
    t_solve_s = round(t_solve; digits = 1),
    t_total_internal_s = round(t_total_internal; digits = 1),
    ms_per_step = round(1000 * t_solve / nsteps; digits = 2),
)

# Machine-readable row; bash prepends the true process-total wall time.
resultdir = joinpath(REPO_ROOT, "experiments", "gpu-benchmark", "results")
mkpath(resultdir)
open(joinpath(resultdir, "timings.csv"), "a") do io
    println(
        io,
        join(
            [
                LABEL, DEVICE, string(Threads.nthreads()), T_END, string(nsteps),
                string(round(t_setup; digits = 2)),
                string(round(t_solve; digits = 2)),
                string(round(t_total_internal; digits = 2)),
                string(round(1000 * t_solve / nsteps; digits = 3)),
                string(Dates.now()),
            ],
            ",",
        ),
    )
end
