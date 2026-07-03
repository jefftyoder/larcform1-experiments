# clw sensitivity test #1
## author: Jeffrey Yoder
## date: July 02, 2026

# Goal
The goal of this experiment is to investigate the missing cloud liquid and low cloud ice in
current Larcform1 model runs using ClimaAtmos.jl 

# Protocol

## Setup
This experiment is based on my implementation of the Larcform1 experiment in ClimaAtmos.jl.
The original Larcform1 protocol is outlined in @cite{Pithan 2016}.
This implementation uses a modified SlabOceanSST initialized to 250K as the surface boundary
condition to approximate the 250K sea ice // sea ice + snow models used in the original 
intercomparison.

## Variations
Only vary one .yml or .toml setting per run.
0) EC-Earth Data
1) Base (`ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml`)
2) 0M microphysics
3) 2M microphysics (expect will not be stable)
4) All microphys processes disabled except cloud formation (see default_config.yml)
5) `sublimation_deposition_timescale` = `10`
6) `sublimation_deposition_timescale` = `400`
7) `sublimation_deposition_timescale` = `1_000`
8) `sublimation_deposition_timescale` = `10_000`
9) `condensation_evaporation_timescale` = `10`

If none of these succceed, we may begin tweaking other fields in the settings. Focus on 
cloud and microphysics processes.


## Validation
Results will be compared against the EC-Earth model from the Pithan 2016 intercomparison 
dataset (see the netcdf files in `REPO_ROOT/Pithan 2016 Intercomparison Data/`). Comparisons
will be against EC-Earth data, as the EC-Earth model is the closest model to our 
implementation which does manage to produce significant clw (q_cl,l > .1g/kg = 1e-4kg/kg).
Note that EC-Earth does not follow the same data naming conventions as ClimaAtmos.jl. We 
must be careful in handling the conversion and comparison.

Steps:
1) Check if each variation for whether surpasses threshold of .1g/kg
if step (1) passes, stop running models and check the following:
2) Compare cloud ice (cli) to values
3) Compare total specific humidity
4) Compare relative humidity
5) Compare vertically integrated cloud water (clwvi)
6) Compare vertically integrated cloud ice (clivi)
7) Compare precipitation rate for rain (prra)
8) Compare precipitation rate for snow (prsn)

## Running the Simulations

### Driver
This experiment uses `SlabOceanSST` as the surface (see Setup), which is the standalone
ClimaAtmos path — not the coupled sea-ice driver (`experiments/larcform1_driver.jl`). Run
each variation through `.buildkite/ci_driver.jl`, layering the base config with a
variation-specific overlay (`--config_file` merges in order, later files win on conflicts):

```bash
julia --project=ClimaAtmos.jl/.buildkite ClimaAtmos.jl/.buildkite/ci_driver.jl \
  --config_file ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml \
  --config_file "experiments/clw sensitivity experiments/configs/v2_0M.yml"
```

### Variation config files
One overlay YAML per variation under `experiments/clw sensitivity experiments/configs/`,
setting only `job_id`, `output_dir`, and the single changed key — this makes the overlay
file itself the record of what changed, enforcing "only vary one setting per run".

Caveat: `toml:` is a list and config merging is a plain `Dict` merge — a later config file
does not append to it, it replaces it wholesale. So overlays for the timescale sweeps
(variations 5–9) must specify the *full* toml list, not just the new file:

```yaml
# v5_subltime10.yml
toml: [toml/larcform1_1M_prognostic_edmfx.toml, "experiments/clw sensitivity experiments/toml/subltime10.toml"]
```
```toml
# toml/subltime10.toml
[sublimation_deposition_timescale]
value = 10
```

### Output location
`default_config.yml` exposes `output_dir` and `output_dir_style` directly
([default_config.yml:138](ClimaAtmos.jl/config/default_configs/default_config.yml#L138)) —
set these explicitly per variation instead of relying on `job_id` to derive the path:

```yaml
output_dir: "experiments/clw sensitivity experiments/output/lf1e-clw-1/v2_0M"
output_dir_style: "ActiveLink"   # default; numbers subfolders output_0001, output_0002, ...
                                  # output_active always points at the latest
```

Each variation gets its own subfolder under `experiments/clw sensitivity experiments/output/lf1e-clw-1/`,
so reruns don't clobber earlier results and postprocessing can glob
`lf1e-clw-1/v*/output_active/` to pick up the latest run of every variation.

### Batch execution
With 9 variations, script the loop rather than invoking each by hand, to avoid a typo
changing two settings instead of one. Use `experiments/clw sensitivity experiments/run_batch.jl`
instead of `ci_driver.jl` directly — it builds `AtmosConfig` itself rather than going through
`CA.commandline_kwargs()`, which sidesteps a real bug: `ci_driver.jl`'s `--job_id` always has
a non-`nothing` ArgParse default ([cli_options.jl:12-15](ClimaAtmos.jl/src/config/cli_options.jl#L12)),
so `@something(job_id, yaml_job_id, ...)` silently ignores each overlay's `job_id:` key and
every run gets labeled `"default_config"`. `run_batch.jl` also loops over multiple variation
configs in one persistent Julia process, redirects each run's stdout to a per-variation log,
and keeps going after a crash (`solve_atmos!` already catches crashes internally rather than
throwing) — useful for variation 3 (2M), which is expected to be unstable and should have its
failure mode documented rather than silently rerun.

### Local sequential execution (current plan — Stratus offline as of 2026-07-02)

Stratus is unreachable, so all 9 variations run on this 16 GB laptop instead. Per the local
findings below, this machine cannot safely run more than **one ClimaAtmos process at a
time** — so "batch" here means sequential, not parallel. The lever that's still available
locally is compile-cost amortization: run all 9 variations through one `run_batch.jl`
invocation so the ~9–10 min fixed package-load/JIT cost is paid once for the whole set, not
once per variation, with additional (smaller) recompiles only when the `AtmosModel` type
actually changes (variations 2, 3, 4).

```bash
mkdir -p "output/lf1e-clw-1"
julia -t 1 --project=ClimaAtmos.jl/.buildkite \
  "experiments/clw sensitivity experiments/run_batch.jl" \
  "experiments/clw sensitivity experiments/configs/v1_base.yml" \
  "experiments/clw sensitivity experiments/configs/v2_0M.yml" \
  "experiments/clw sensitivity experiments/configs/v3_2M.yml" \
  "experiments/clw sensitivity experiments/configs/v4_cloudonly.yml" \
  "experiments/clw sensitivity experiments/configs/v5_subltime10.yml" \
  "experiments/clw sensitivity experiments/configs/v6_subltime400.yml" \
  "experiments/clw sensitivity experiments/configs/v7_subltime1000.yml" \
  "experiments/clw sensitivity experiments/configs/v8_subltime10000.yml" \
  "experiments/clw sensitivity experiments/configs/v9_condtime10.yml" \
  2>&1 | tee "output/lf1e-clw-1/local_run_$(date +%Y%m%d_%H%M%S).log"
```

Order doesn't affect correctness — Julia's method cache is reused across all 9 regardless of
sequence — but keeping 1/5/6/7/8/9 together is still worth doing for readability, since they
share compiled code and 2/3/4 don't.

**Rough time budget** (extrapolated from the 10-simulated-minute probes, not yet measured on
a full 20-day run — treat as an estimate to revise once the first variation finishes): ~9–10
min fixed cost, paid once, + ~24 min steady-state solve per variation × 9, + a smaller
re-compile (untested, budget a few minutes) for each of variations 2/3/4 where the model type
changes. Total plausibly **3.5–4.5 hours**, dominated by solve time, not compile. Variation 3
(2M) may finish faster than this if it crashes early as expected.

**Run this unattended, in the background** — this is multi-hour and single-threaded; don't
block on it in a foreground shell. Close other memory-heavy applications first if possible
(the VSCode Julia language server processes were already consuming noticeable RAM during
testing, and this machine's swap filled to 13.8/14.3 GB under much lighter concurrent load
than a single full run should need — better to have headroom than not).

`run_batch.jl` prints `=== Batch summary ===` with a per-variation `ret_code` at the very
end, and an `[ Info: Finished variation ...]` line after each one completes — grep the log
for either to check progress without reading the full (very verbose) output.

### Remote parallel execution (Stratus) — for when it's back

**Why remote at all.** Measured locally (16 GB RAM): a single fresh `julia ... ci_driver.jl`
process pays ~9–10 minutes of fixed package-load/JIT cost before the solve itself starts, and
a *second* concurrent process pushed the machine into heavy swapping (12.1 of 13.3 GB swap in
use), turning "parallel" into slower-than-serial. CPU threading doesn't help either — the devs
confirm CPU parallelism isn't developed for SCM runs, so `-t 1` throughout. Net effect: this
machine can safely run **one variation at a time**. Real parallelism needs a box with more
headroom than this laptop — hence Stratus.

**Step 1 — check Stratus's actual budget before assuming any concurrency.**
```bash
ssh stratus 'nproc; free -h'
```
Concurrency is memory-bound, not core-bound (per the local finding above) — don't schedule N
concurrent workers without first confirming N × (peak RSS per run) fits with headroom to
spare. Peak RSS for a 10-minute toy run was ~3–5 GB locally; a full 20-day run with the full
diagnostics list will be higher — budget conservatively (e.g. treat 8–10 GB/process as the
planning number) until a real 20-day run is measured on Stratus.

**Step 2 — sync the repo, including the generated variation configs.**
```bash
bash scripts/sync_to_remote.sh
```
This must happen *after* the variation overlay YAML/TOML files (see above) are generated
locally, so they land on Stratus in the same repo-relative layout.

**Step 3 — group variations to amortize the compile cost, then launch one tmux session per
group.** Compilation is retriggered whenever the concrete `AtmosModel` type changes, not just
whenever a YAML value changes — variations that only change a TOML *value* share compiled
code within one `run_batch.jl` process; variations that change `microphysics_model` or null
out process fields (→ `Nothing` in the type) do not.

| Worker | Variations | Why grouped |
|---|---|---|
| A | 1 (Base), 5, 6, 7, 8, 9 | same `AtmosModel` type — only timescale TOML values differ |
| B | 2 (0M) | different `microphysics_model` type |
| C | 3 (2M) | different type; isolate so the expected instability doesn't affect others |
| D | 4 (processes nulled) | several fields flip `T → Nothing`, a different concrete type |

```bash
ssh stratus 'export PATH=/home/yoder/.juliaup/bin:$PATH && cd ~/clima/larcform1-experiments && \
  tmux new-session -d -s lf1_worker_A \
    "julia -t 1 --project=ClimaAtmos.jl/.buildkite \
      \"experiments/clw sensitivity experiments/run_batch.jl\" \
      \"experiments/clw sensitivity experiments/configs/v1_base.yml\" \
      \"experiments/clw sensitivity experiments/configs/v5_subltime10.yml\" \
      \"experiments/clw sensitivity experiments/configs/v6_subltime400.yml\" \
      \"experiments/clw sensitivity experiments/configs/v7_subltime1000.yml\" \
      \"experiments/clw sensitivity experiments/configs/v8_subltime10000.yml\" \
      \"experiments/clw sensitivity experiments/configs/v9_condtime10.yml\" \
      2>&1 | tee output/lf1e-clw-1/worker_A_$(date +%Y%m%d_%H%M%S).log"'
```
Repeat for workers B, C, D with their own tmux session names and config lists. If step 1
shows enough headroom, launch all four `tmux new-session` calls back to back — they run
concurrently since each is detached. If not, stagger: start worker A alone (it's the
long pole, ~6 runs), then B/C/D together once A frees memory, or interleave based on what
`free -h` shows mid-run.

**Step 4 — monitor without an interactive TTY** (per project convention, `tmux attach`
doesn't work from Claude Code):
```bash
ssh stratus 'tmux capture-pane -pt lf1_worker_A -S -50'
```
Check all four sessions periodically; `run_batch.jl` prints a `=== Batch summary ===` block
with per-variation `ret_code` when a worker finishes, so a quick grep for that string (or for
`FAILED`) across the worker logs tells you what's done without reading full output.

**Step 5 — pull results back.**
```bash
bash scripts/sync_from_remote.sh
```
Run this after all four `tmux` sessions have exited (check `ssh stratus 'tmux ls'` — a
finished session disappears from the list). Postprocessing then proceeds exactly as described
below, against the local `output/lf1e-clw-1/v*/output_active/` directories.

## Postprocessing

### Data processing
Reuse `scripts/convert_to_pithan.py` — it already does more than reshape the data: it
renames ClimaAtmos variables into EC-Earth's own vocabulary (`hus`→`q`, `ta`→`t`,
`pfull`→`p`, `hur`→`rh`, `lwp`→`clwvi`, `cl`→`cl` as 0–1 fraction, derives `precr` from
`pr − prsn`), and fixes CliMA's sign conventions to match Pithan2016. After conversion, our
output and `EC-Earth.nc` share variable names directly — no separate renaming layer needed
in the notebook.

Two things the converter does *not* handle, which the notebook must:

1. **Diagnostic period mismatch.** The converter defaults to `--suffix 3h_average`, but
   `larcform1_1M_prognostic_edmfx.yml` diagnoses everything at `period: 1hours`
   ([larcform1_1M_prognostic_edmfx.yml:74-91](ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml#L74-L91)).
   Every call must pass `--suffix 1h_average` explicitly.
2. **Vertical grid mismatch.** The converter's `lev` coordinate is z-height (metres), not
   pressure — it's a per-model raw level index, and ClimaAtmos's stretched z-grid does not
   line up level-for-level with EC-Earth's `nlev`. Both files carry their own `p(time, lev)`
   though, so profile comparisons must interpolate onto a common pressure grid via `p`
   rather than comparing by level index. EC-Earth's `ps` is constant at 101300 Pa for the
   full run, so its `p(nlev)` is effectively time-invariant — interpolate ClimaAtmos's
   profiles onto EC-Earth's fixed pressure levels once, not per-timestep.

Conversion call, one per variation:
```bash
python scripts/convert_to_pithan.py \
  --nc-dir "experiments/clw sensitivity experiments/output/lf1e-clw-1/v2_0M/output_active" \
  --suffix 1h_average \
  --model-name v2_0M \
  --out "experiments/clw sensitivity experiments/output/pithan_format/v2_0M.nc"
```
Do this for all variations in a loop (matching the glob-per-variation pattern from Running
the Simulations) rather than one-off by hand.

Open question to verify in the notebook, not blocking: EC-Earth's `clw`/`cli` are labeled
unit `"1"` — confirm by magnitude that this is actually kg/kg matching ClimaAtmos, not some
other normalization, before trusting direct comparison.

### Build check tables

This is a 2-day sensitivity screen, not the full 20-day Pithan 2016 run (see `t_end: 2days`
in `larcform1_1M_prognostic_edmfx.yml:22`, unchanged by any of the 9 overlays) — an earlier
draft of this section analyzed "the first 10 days," carried over from the full-protocol
analysis window rather than this experiment's actual run length. The comparison window here
is **the full 2-day run** (i.e. no truncation — all available ClimaAtmos output), matched
against EC-Earth's own first 2 days (EC-Earth.nc covers the full 20-day protocol run, so it
must be truncated to line up with our shorter window). If a variation looks promising here,
extend it to the full 20-day run before treating it as a real result against the Pithan
protocol.

- **Threshold table** (Validation step 1): for each variation, load the converted file,
  compute `max(clw)` over `(time, lev)` across the full 2-day run, flag pass/fail against
  1e-4 kg/kg (0.1 g/kg). Columns: variation, job_id, max_clw_kgkg, passes_threshold, notes
  (e.g. document variation 3's instability/failure mode from `run.log` here rather than
  silently excluding it).
- **Extended comparison table** (Validation steps 2–8), only for variations that pass step
  1: mean bias / RMSE of `cli`, `q`, `rh` profiles and `clwvi`, `clivi`, `precr`, `precs`
  time series against EC-Earth, computed on the pressure-regridded data, over the full 2-day
  run vs. EC-Earth's first 2 days.

### Plotting
- **Profiles** (time-mean over the full 2-day run, plotted against pressure `p`, inverted
  axis): `t`, `q`, `rh`, `clw`, `cli` — one ClimaAtmos variation vs EC-Earth per panel.
- **Time series** (first 2 days): `clwvi`, `clivi`, `precr`, `precs` — variation vs
  EC-Earth, one plot per variable, variations overlaid or faceted.
- Follow the `dataviz` skill for palette/styling once chart code is written.

Implementation order in `analysis.ipynb`:
1. Imports, paths, glob `output/lf1e-clw-1/v*/output_active/`
2. Call `convert_to_pithan.convert()` per variation (import directly, not subprocess)
3. Load `EC-Earth.nc`
4. Pressure-regrid helper (ClimaAtmos `p(time,lev)` → EC-Earth's fixed `p(lev)`)
5. Threshold + comparison tables
6. Profile plots
7. Time-series plots