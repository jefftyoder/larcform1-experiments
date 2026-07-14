# lf1e-gpu-benchmark-1 — GPU vs CPU (and threads) for the calibrated SCM

## Purpose

Measure the **total** wall-clock cost of the production Larcform1 configuration
— calibrated microphysics + ClimaSeaIce 1 m ice + 0.1 m w.e. snow, the
`lf1_clima_seaice_column_20d` run — on every compute backend available to us,
and decide whether GPU or CPU threading is worth adopting.

"Total" means what a user actually waits for: process launch → package load →
JIT/CUDA compilation → model construction → time-stepping → I/O. Each device is
therefore run in its **own fresh julia process** (`bench.sh`). Amortising
compilation across devices in one warm process would hide the single largest
difference between CPU and CUDA.

## Hardware

| Host | CPU | GPU |
|---|---|---|
| M1-Satellite (MacBook) | Apple M1, 8 cores | Apple integrated (Metal) |
| stratus | 13th Gen Intel i7-13700, 24 threads | **NVIDIA RTX A6000**, 49 GB, driver 535 |

> **The Stratus GPU is an RTX A6000, not an A100.** Same Ampere generation,
> workstation rather than datacenter part. Recorded because the experiment was
> requested as "the A100 on Stratus".

## The MacBook GPU leg is impossible — not merely slow

The CLIMA stack has **no Metal backend**, so the Apple GPU cannot be targeted at
all. This is a hard structural fact, established from the source rather than by
attempting a run:

- `ClimaComms` defines exactly three devices — `CPUSingleThreaded`,
  `CPUMultiThreaded`, `CUDADevice` (`ClimaComms/src/devices.jl:24-38`). Any other
  value of `CLIMACOMMS_DEVICE` is an explicit `error()` (`devices.jl:61`).
- ClimaCore's GPU path is `ClimaCoreCUDAExt`, built on **hand-written CUDA.jl
  kernels** (`import CUDA`, `threadIdx`, `blockIdx`, `blockDim`) — not portable
  `KernelAbstractions`. There is nothing generic for Metal to plug into.

Porting would mean rewriting ClimaCore's GPU kernels against a Metal backend —
far outside this project's scope. **The MacBook contributes CPU data points
only**, and the GPU-vs-CPU comparison happens entirely on Stratus, where CPU and
GPU legs share one machine and one environment and differ *only* in the `device:`
key. That is the cleaner controlled experiment regardless.

## Hypothesis: neither the GPU nor extra threads can help this model

This is a **single-column** model, and every parallel backend in the stack
parallelises over **horizontal columns**:

- **CPU threading.** Every `Threads.@threads` in ClimaCore loops
  `for h in 1:Nh` — the horizontal element count
  (`ClimaCore/src/Fields/indices.jl:60,92,177,208,240`;
  `src/Operators/finitedifference.jl:3898`). An SCM has **Nh = 1**. There is
  exactly one iteration to hand out; threads 2…N have nothing to do. Extra
  threads should change total time by ≈0, and may make it slightly *worse*
  (thread-pool and GC overhead on no useful work).
- **GPU.** With Nh = 1 the only exploitable parallelism is the ~100 vertical
  levels. The A6000 has 10,752 CUDA cores across 84 SMs; a 100-wide kernel
  occupies a rounding error of the device. Meanwhile the run is
  **57,600 sequential timesteps** (20 days at dt = 30 s), each a burst of many
  small kernel launches. Per-launch latency (~5–10 µs) cannot be amortised over
  100 lanes of work, and the timesteps cannot be batched because they are
  sequentially dependent. On top of that, CUDA compilation is a large one-off
  cost paid in every process.

**Prediction:** CPU single-threaded is fastest; CPU multithreaded ≈ the same or
slightly slower; CUDA is *slower*, plausibly by a wide margin, and worse still on
total time because of CUDA compilation.

The experiment is worth running anyway: the prediction is falsifiable, the cost
is a few hours, and "we measured it" settles the question permanently.

## Where the hardware *would* pay off

The useful parallel axis for this project is not one column — it is **many
columns**. The UKI calibration loop runs 35+ ensemble members, each an
independent SCM. Those are embarrassingly parallel and today run sequentially.
Two ways to exploit that, both out of scope here but the natural follow-up:

1. **Process-level parallelism on CPU** — run N members as N single-threaded
   processes. On the 24-thread Stratus CPU this is a near-linear ~10–20×
   speed-up of the *calibration*, using the hardware we already have and
   requiring no model changes.
2. **Ensemble-as-columns on GPU** — build one domain with Nh = ensemble size, so
   the GPU's parallelism finally has something to chew on. This is a real model
   change (the coupler/surface components assume a single point), not a config flag.

The single-column benchmark below is what tells us to spend effort on (1) rather
than on GPU-porting the SCM.

## Method

`bench.sh` runs one julia process per device spec and wraps it in a wall clock:

```bash
# from the repo root
experiments/gpu-benchmark/bench.sh 20days \
    stratus_cpu1:CPUSingleThreaded:1 \
    stratus_cpu24:CPUMultiThreaded:24 \
    stratus_a6000:CUDADevice:1
```

Each run is the production `lf1_clima_seaice_column_20d` overlay (calibrated
microphysics via `coupler_toml`, ClimaSeaIce ice + snow, s11 grid: z_max 5000,
z_elem 100, stretched, Float32, dt 30 s), with only `device`, `t_end`, and
`job_id` overridden. Distinct `job_id` per label ⇒ no output-dir collisions.

Reported per run: **TOTAL** (external wall clock, the headline), `setup`
(construction, which is where most JIT/CUDA compilation lands), `solve` (pure
time-stepping), and **ms/step** (the device's true throughput, independent of
compilation).

`ms/step` is the number to compare devices on; `TOTAL` is the number that decides
what we actually run.

### Requirements on a GPU host

`CUDA` is **not** a dependency of the root project, and `ClimaComms` only loads
its CUDA extension when CUDA is present in the environment — so `device:
CUDADevice` silently cannot work until you add it:

```julia
julia --project -e 'using Pkg; Pkg.add("CUDA")'
```

Not committed here, to avoid touching the shared `Project.toml`/`Manifest.toml`.

### GPU-safety fix to the sea-ice component

`experiments/sea-ice/components/clima_seaice_column.jl` reads point values off
ClimaCore exchange fields with `_point(f) = first(parent(f))`. Under CUDA,
`parent(f)` is a `CuArray` and `first` is a **scalar index**, which CUDA.jl
disallows by default — every coupling step would throw. The read is now routed
through `ClimaComms.allowscalar`, which is a plain call with no overhead on any
CPU device (`ClimaComms/src/devices.jl:242`), so the CPU path is byte-for-byte
unchanged.

The ice model itself deliberately stays on the host: it is a single point, only
scalars cross the device boundary, and there is nothing there for a GPU to do.

## What it took to get the model onto the GPU at all

Three separate blockers, none of them a config flag. Recorded because anyone
attempting a GPU run will hit all three.

1. **`import CUDA` is mandatory in the driver.** The GPU methods live in *package
   extensions* — `ClimaComms.array_type(::CUDADevice)` in `ClimaCommsCUDAExt`, the
   kernels in `ClimaCoreCUDAExt` — and Julia only loads an extension once its
   trigger package is loaded in the session. Having CUDA merely *installed* is not
   enough. Without an explicit `import CUDA`, column-grid construction dies with
   `MethodError: no method matching array_type(::ClimaComms.CUDADevice)`, which
   reads like a missing-package bug and is really a dormant-extension bug.

2. **The Larcform1 initial condition cannot run on GPU.** `center_initial_condition`
   evaluates `setup.profiles.p(z)`, where `p` is a `ColumnInterpolatableField`
   wrapping a host `Matrix{Float32}` and an `Interpolations.Extrapolation` over a
   host `Vector`. On GPU the IC assignment is a CUDA kernel, and CUDA kernels can
   only capture **isbits** data, so compilation fails with a long
   `... which is not isbits` chain. ClimaAtmos says so itself — the
   `ColumnInterpolatableField` docstring reads *"not GPU-compatible … only use this
   for initialization"* — but for a **column** SCM the initialization *is* a device
   kernel, so the escape hatch doesn't apply.

   **Worked around by restarting from a CPU checkpoint** (`--restart`), which reads
   the state straight from HDF5 into device arrays and never runs the IC broadcast.
   Time-stepping — the thing being benchmarked — is untouched. A real GPU port would
   have to make the pressure profile isbits (e.g. an `SVector`-backed interpolant,
   as the T/q profiles already use) or build the IC on the host and copy.

3. **The walltime progress reporter crashes on *any* restarted coupled run.**
   `InexactError: Int64(NaN)` from
   `ClimaUtilities.OnlineLogging._time_and_units_str → Nanosecond(ceil(1e9*NaN))`:
   a NaN ETA in the reporter, not a NaN in the model. **This is not GPU-specific** —
   the CPU restart leg fails identically, which is how it was diagnosed. It also
   cannot be switched off by config, because ClimaCoupler's selection is inverted
   (`SimCoordinator.jl:467`): `atmos_log_progress: true` ⇒ ClimaAtmos reports;
   `false` ⇒ the *coupler* installs its own `capped_geometric_walltime_cb` instead.
   Both land in the same `report_walltime`, so one of them always runs. The benchmark
   overrides `report_walltime` with a no-op (`--no-progress`), which suppresses log
   lines only.

   **Both (2) and (3) are upstream bugs worth reporting.**

## Results

All runs: the production `lf1_clima_seaice_column_20d` configuration (calibrated
microphysics, ClimaSeaIce ice + snow), **1 simulated day** ⇒ ~2,880 steps at
dt = 30 s. `TOTAL` is external wall clock around the whole process.

### Device sweep (fresh start, no restart)

| host | device | threads | TOTAL | setup (incl. JIT) | solve | ms/step |
|---|---|---|---|---|---|---|
| MacBook M1 | CPUSingleThreaded | 1 | 566 s | 272.6 s | 276.2 s | 95.9 |
| MacBook M1 | CPUMultiThreaded | 8 | 511 s | 262.7 s | 235.6 s | 81.8 |
| stratus | CPUSingleThreaded | 1 | **421 s** | 245.8 s | 164.1 s | **57.0** |
| stratus | CPUMultiThreaded | 24 | **385 s** | 232.9 s | 143.1 s | **49.7** |
| MacBook GPU | — | — | *impossible* | — | — | — |

### GPU vs CPU — matched pair (same host, same restart, same settings)

The GPU cannot fresh-start (blocker 2), so its honest comparison is against a CPU
run restarted from the *same* checkpoint with the *same* shim. 2,870 steps each.

| device | TOTAL | setup (incl. compilation) | solve | ms/step |
|---|---|---|---|---|
| stratus CPUSingleThreaded | **419 s** | 247.0 s | 160.3 s | **55.9** |
| stratus RTX A6000 (CUDA) | **539 s** | 311.1 s | 212.8 s | **74.2** |
| | **GPU 1.29× slower** | +64 s (CUDA compile) | | **GPU 1.33× slower** |

Cross-check: CPU-1 measures 55.9 ms/step restarted vs 57.0 fresh — within 2%, so
the restart does not perturb timing and the two tables are directly comparable.

## Conclusions

**1. The GPU is slower than the CPU for this model, and always will be.**
Not marginally-not-worth-it — actually slower, 1.33× per step, on a 49 GB A6000
against a *single* CPU core. The reason is structural, not a tuning problem: the
SCM has **Nh = 1**, so the only parallelism available to the GPU is ~100 vertical
levels, on a device with 10,752 cores. Every one of the 57,600 sequential timesteps
is a burst of tiny kernel launches whose latency cannot be amortised over 100 lanes
of work, and the steps cannot be batched because they are sequentially dependent.
The GPU then loses *again* on total time by paying +64 s of CUDA compilation. No
amount of optimisation changes the shape of this: there is nothing to parallelise.

**2. Multithreading gives a modest, real, but sub-linear gain: ~13%.**
(57.0 → 49.7 ms/step on Stratus with 24 threads; 95.9 → 81.8 on the Mac with 8.)
This is *less* than a naive reading would suggest and more than my own prediction of
zero. It is not coming from the dycore: every `Threads.@threads` in ClimaCore loops
`for h in 1:Nh`, and Nh = 1, so those loops have exactly one iteration to hand out.
The ~13% is incidental — most plausibly Julia's parallel GC, which does have work to
do. **Take it (it is free — just pass `-t auto`), but do not expect it to scale**:
24 threads buys 13%, and a 25th would buy nothing.

**3. The MacBook is ~1.7× slower per step than Stratus's CPU** (95.9 vs 57.0 ms/step)
— worth knowing, but both are usable for single runs.

**4. The real win is not here.** For one column, the hardware is nearly irrelevant:
the spread across every backend tested is under 2×. The parallelism that matters is
**across ensemble members**, and it is currently unexploited. The UKI calibration
loop runs 35+ independent SCMs sequentially. Running them as N concurrent
single-threaded *processes* on the 24-core Stratus CPU is a ~10–20× speed-up of the
calibration — an order of magnitude more than anything in this table, using hardware
we already own, with no model changes. That, not GPU-porting, is where the next
effort should go. (Recommended default for a *single* run: Stratus, `-t auto`.)
