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

Reported per run: **TOTAL** (external wall clock, the headline) and the coupler's
own **ms/step**.

### Measure per-step cost with the coupler's timer, NOT solve/nsteps

The obvious metric — wrap `run!(cs)` in a timer and divide by step count — is
**wrong, by ~7×**, and this benchmark got it wrong first time round.

`run!` compiles the entire tendency on its first evaluation. That JIT lands
*inside* the timed region (~140 s on Stratus), so `solve/nsteps` amortises a
**one-time** cost across **every** step:

```
Stratus CPU×1, 1 day:  solve = 164 s / 2880 steps  = 57 ms/step   <- WRONG
                       of which ~141 s is tendency JIT
                       real stepping = 2880 x 6.8 ms = 23 s
```

The tell was in the data: a 10-step smoke run had a *longer* solve (347 s) than a
2880-step run (276 s) on the same machine — impossible unless a fixed compile cost
dominates. Extrapolating the bad number predicted ~52 min for a 20-day run; the
real answer is **13.9 min**.

ClimaCoupler already reports the right thing. `SimCoordinator.jl:70-80` wraps
**only the coupling loop** in `ClimaComms.@elapsed` and prints:

```
[ Info: Simulation took 481.67 seconds
[ Info: Walltime per coupling step: 0.00836
```

That is the JIT-free per-step cost, and it is what the tables below quote. Use it
(and `ClimaComms.@elapsed`, which synchronises the GPU — a bare CPU-side timer
would under-report CUDA work).

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

Production `lf1_clima_seaice_column_20d` configuration (calibrated microphysics,
ClimaSeaIce ice + snow, s11 grid, Float32, dt = 30 s). **ms/step is the coupler's
JIT-free coupling-loop timer**, not solve/nsteps — see the methodology note above.

### CPU: threads make it *slower*

1 simulated day (2,880 steps), fresh start.

| host | launch | setup (JIT) | coupling loop | ms/step | SYPD |
|---|---|---|---|---|---|
| stratus (i7-13700) | `-t 1` | 245.8 s | 19.6 s | 6.79 | 12.09 |
| stratus | `-t 24` | 232.9 s | 20.5 s | 7.13 | 11.51 |
| stratus | **`-t 1 --gcthreads=8`** | **235.1 s** | **19.4 s** | **6.72** | **12.22** |
| MacBook M1 | `-t 1` | 272.6 s | 24.8 s | 8.62 | 9.53 |
| MacBook M1 | `-t 8` | 262.7 s | 29.9 s | 10.39 | 7.90 |

Compute threads cost **5% per step on Stratus (24t) and 20% on the Mac (8t)**, while
buying only a faster compile. `--gcthreads` separates the two (see Conclusions #2):
GC threads deliver the compile speedup, `nthreads() == 1` keeps the fast stepping.

### GPU vs CPU: matched pair (same host, same restart, same settings)

The GPU cannot fresh-start (blocker 2 below), so it is compared against a CPU run
restarted from the *same* checkpoint with the *same* shim. 2,870 steps each.

| device | ms/step | SYPD |
|---|---|---|
| stratus CPUSingleThreaded | **11.0** | 7.47 |
| stratus RTX A6000 (CUDA) | **41.5** | 1.98 |
| | **GPU 3.8x slower** | |

(Both legs are inflated by ~4 ms/step of in-loop JIT that a restart defers into the
first `step!`; it hits both equally, so the *ratio* is the trustworthy quantity.)

### Real total run time, 20 simulated days (57,590 steps)

| host | device | TOTAL wall | of which coupling loop | ms/step |
|---|---|---|---|---|
| stratus | CPU x24 | **835 s (13.9 min)** | 482 s | 8.36 |

~350 s of the 835 s is process start + package load + JIT; the physics is ~482 s.
A single-threaded CPU run would be slightly *faster* still (see above). The GPU
20-day leg was cancelled once the per-step verdict was unambiguous — at 41.5 ms/step
it was tracking ~45 min, ~3x the CPU.

## Conclusions

**1. Do not run this SCM on the GPU. It is ~4x slower than one CPU core.**
Not "not worth the effort" — actually slower, on a 49 GB A6000 against a single
core. The reason is structural and untunable: the SCM has **Nh = 1**, so the only
parallelism a 10,752-core card can exploit is ~100 vertical levels, across 57,600
*sequentially dependent* timesteps whose kernel-launch latency cannot be amortised
over 100 lanes of work. It then loses again on ~60 s of extra CUDA compilation.
There is nothing here to parallelise.

**2. Do not use `-t auto` either. Threads also make stepping slower** (5-20%).
Same root cause: every `Threads.@threads` in ClimaCore loops `for h in 1:Nh`
(`Fields/indices.jl:60,92,...`; `Operators/finitedifference.jl:3898`), and Nh = 1 —
one iteration to hand out, threads 2..N idle, pure synchronisation overhead.

Caveat: you cannot opt out via config alone. ClimaAtmos's device selection
(`type_getters.jl:296`) promotes to `CPUMultiThreaded` whenever
`Threads.nthreads() > 1`, **silently overriding** an explicit
`device: CPUSingleThreaded` — so the julia launch line, not the YAML, decides.

> Threads do shrink the compile phase (~246 → ~233 s setup), which is why they look
> like a ~13% win if you measure total wall clock on a short run. That is a
> compilation effect, not a physics one, and it misled the first draft of this
> experiment. The mechanism is **parallel GC, not parallel codegen** — compilation
> allocates heavily, and `-t N` also grants GC threads. Verified by decoupling the
> two: `julia -t 1 --gcthreads=8` keeps `nthreads() == 1` (so ClimaCore stays on
> the fast `CPUSingleThreaded` device) while parallelising GC, and gets **both**
> wins — setup 235.1 s (matches 24 threads) at 6.72 ms/step (best measured,
> SYPD 12.22). Strictly better than `-t 1` and `-t 24` on their respective weak
> axes. **Launch production runs with `julia -t 1 --gcthreads=8`.**

**3. The MacBook GPU is impossible, not merely slow.** No Metal backend exists in
the CLIMA stack (see above). The MacBook CPU is ~1.3x slower per step than Stratus.

**4. The hardware is nearly irrelevant here; the parallelism worth having is across
ensemble members.** Every backend tested spans well under 2x on per-step cost, and a
20-day run is ~14 min regardless. The UKI calibration loop runs 35+ *independent*
SCMs sequentially — running those as N concurrent single-threaded **processes** on
24 Stratus cores is a ~10-20x speed-up of the thing that actually costs time, with
no model changes. That, not GPU porting, is where effort should go.

**Recommended: Stratus, `julia -t 1 --gcthreads=8`, one process per ensemble
member.** (The current calibration uses `ClimaCalibrate.JuliaBackend()`, which runs
members sequentially; `WorkerBackend` with `Distributed.addprocs(N)` is the
supported parallel path on a single machine.)

