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
condition, standing in for the interactive surface of the original protocol (Pithan 2016
§2.2: 1 m sea ice + 0.1 m snow water-equivalent over ocean at freezing, initialized 250 K).
A slab ocean has heat capacity but no ice/snow conductivity model, so the paper's
clear-state result (surface-based inversion buildup, which hinges on snowpack insulation)
is out of scope for this surface; only the cloudy-state liquid — this experiment's target —
is meaningfully comparable. Two mitigating notes: (a) our reference model EC-Earth is
itself one of the paper's "no snow, fixed ice" models (Table 3), so a no-snow slab is
closer to EC-Earth's surface than to the full protocol; (b) the paper attributes the
missing surface-based inversions in ECMWF-IFS and EC-Earth to exactly this lack of snow
insulation, so our comparisons inherit that shared limitation rather than adding a new one.

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

Added during execution after the source-code investigation (see Findings):

10) `cloud_ice_formation: "TemperatureDependent"` (Frostenberg 2023 INP-limited deposition)
11) `cloud_ice_formation: ~` (vapor→cloud-ice deposition disabled; falsification control)
12) `sublimation_deposition_timescale` = `1e9` (constant τ matched to v10's initial INP-limited value)

If none of these succceed, we may begin tweaking other fields in the settings. Focus on 
cloud and microphysics processes.


## Validation
Results will be compared against the EC-Earth model from the Pithan 2016 intercomparison 
dataset (see the netcdf files in `REPO_ROOT/Pithan 2016 Intercomparison Data/`). Comparisons
will be against EC-Earth data, as the EC-Earth model is the closest model to our 
implementation which sustains the cloudy state (max clw above the 1e-4 kg/kg = 0.1 g/kg
threshold). Note the framing: EC-Earth's LWP is at the LOW end of the intercomparison
(Pithan 2016 Table 5: 0.037, vs e.g. ECHAM-HAM at 0.39 — 10× more); it barely sustains
the cloud rather than producing "significant" liquid. That low value is actually closer
to SHEBA observations (the paper notes model LWPs generally run high), which is part of
why it is the right calibration target.
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

# Findings (as of 2026-07-04)

## Headline

**Root cause identified and confirmed: base ClimaAtmos kills supercooled liquid via
unbounded Wegener–Bergeron–Findeisen (WBF) scavenging in the `ConstantTimescale`
vapor→cloud-ice deposition scheme. Switching to `cloud_ice_formation:
"TemperatureDependent"` (v10) fixes it** — sustained clw at ~75% of EC-Earth's peak, at
the right height (~1005 hPa), temperature (~263 K), and onset time (hour ~5), with cloud
ice and snowfall spinning up to EC-Earth magnitude by day 2.

Three follow-up variations (v10–v12) were added beyond the original nine to isolate and
confirm the mechanism.

**Resolution loophole closed (2026-07-04, speed-test s13)**: rerunning v1 physics on a
converged grid (10 m cloud-top layers, `experiments/scm speed tests/` s13) still gives
clw exactly zero at every level and hour, with ice/snow alive. No amount of vertical
resolution rescues the liquid under `ConstantTimescale` — the WBF sink is a physics
failure, not a discretization artifact. (Scoped to ClimaAtmos with the slab surface:
in the original intercomparison resolution DID change the liquid, the other way —
Pithan 2016's WRF-200l lost its cloud at high resolution via 1.2 m-level frost drying,
a failure mode our 10 m grids do not exhibit; see the speed-test md counterpoint.)

**EC-Earth record caveat (2026-07-05)**: the EC-Earth reference file spans 20 days
(481 hourly steps), not 2; all EC-Earth numbers in this document describe its first
48 h only. The full record shows EC-Earth's own cloud **glaciating on day 3** (liquid
≡ 0 from day 4 onward). "Persistence" comparisons against EC-Earth therefore refer to
the day-1–2 mixed-phase window; EC-Earth is not a reference for long-lived supercooled
liquid. Details in "experiments/clw calibration/lf1e-clw-calibration-1.md".

## Results (2-day screen, threshold max(clw) > 1e-4 kg/kg)

| variation | change vs base | max clw (kg/kg) | hrs > 1e-4 (of 48) | outcome |
|---|---|---|---|---|
| v1_base | none | 0.0 exactly | 0 | fail — clw identically zero all run |
| v2_0M | `microphysics_model: 0M` | 1.41e-4 | 4 | marginal pass — liquid via equilibrium T-dependent phase partition (no kinetic WBF in 0M); decays after hour ~5; no precip diagnostics |
| v3_2M | `microphysics_model: 2M` | — | — | setup crash (anticipated): 2M + SGS quadrature "Not implemented yet" (`microphysics_wrappers.jl:609`) |
| v4_cloudonly | all nullable 1M processes off; cloud liquid+ice formation kept | 0.0 exactly | 0 | fail — rules out precipitation processes; cli piles up unbounded, isolating cloud-ice deposition as the liquid killer |
| v5_subltime10 | τ_subl = 10 | 0.0 | 0 | fail |
| v6_subltime400 | τ_subl = 400 | 0.0 | 0 | fail |
| v7_subltime1000 | τ_subl = 1 000 | 0.0 | 0 | fail |
| v8_subltime10000 | τ_subl = 10 000 | 4.80e-4 | 10 | transient — early liquid burst then killed anyway by the separate snow-deposition vapor sink (`snow_deposition_sublimation`), which τ_subl does not control; ~0 by end |
| v9_condtime10 | τ_cond = 10 | 0.0 | 0 | fail — faster liquid condensation can't help; the liquid gate (q_v > q_sat_liq) never opens |
| v10_tdepice | `cloud_ice_formation: "TemperatureDependent"` | 5.11e-4 | 43 | **pass — the fix.** Sustained liquid + ice + snow at EC-Earth-like magnitudes |
| v11_noicedep | `cloud_ice_formation: ~` (deposition off) | 5.11e-4 | 45 | pass, but unphysical: clivi ≡ 0, precs ≡ 0 — deposition is the *only* ice-initiation path in this setup |
| v12_subltime1e9 | τ_subl = 1e9 (ConstantTimescale) | 5.11e-4 | 45 | pass for liquid, but ≈ v11, not v10: clivi only 2.2e-5 at end (v10: 5.0e-3), precs negligible |
| *EC-Earth (ref)* | *Pithan 2016 data, first 2 days* | *6.81e-4* | *47 of 49* | *target: near-continuous supercooled liquid* |

## Mechanism (from CloudMicrophysics.jl source)

In the 1M scheme (`MicrophysicsNonEq.jl`):

- **Liquid** condenses only when `q_v > q_sat_liq` (`conv_q_vap_to_q_lcl`).
- **Ice** (`ConstantTimescale` default) deposits whenever `q_v > q_sat_ice`, at rate
  `(q_v − q_sat_ice)/(τ_subl·Γ)` with τ_subl = 100 s — with **no dependence on existing
  ice mass or INP availability** (`INP_limiter` only suppresses deposition above 0 °C,
  irrelevant here).
- Below freezing `q_sat_ice < q_sat_liq` always, so the 100 s ice sink pins vapor at ice
  saturation and the liquid gate never opens → clw ≡ 0.0. This is WBF with the physical
  brake (finite ice surface area) removed.

The `TemperatureDependent` alternative computes the deposition timescale from diffusional
growth onto INP-nucleated crystals: `τ_dep = 1/(4π·D_v·N_INP(T)·r)` with the Frostenberg
et al. (2023) Arctic INP climatology, `N_INP(T) = (−T_C/10)^9`. At this cloud's −10 °C,
N_INP ≈ 0.9, giving τ_dep ~1e9 s initially — deposition ~10⁷× slower than base, so liquid
wins the vapor competition. As ice mass grows, r grows and τ_dep shrinks, so deposition
accelerates: that bootstrap feedback is what builds the ice phase.

Confirmation chain:
- **v11** (deposition deleted): liquid nearly identical to v10 → at −10 °C, INP-limited
  deposition ≈ no deposition; and zero ice ever forms → deposition is the sole
  ice-initiation path here.
- **v12** (ConstantTimescale with τ matched to v10's initial 1e9 s): reproduces v10's
  *liquid* (max|Δclwvi| vs v11 only 2.4e-3 kg/m²) but not its *ice* — clivi stays ~200×
  below v10 and snow never develops. No single constant τ can emulate
  TemperatureDependent: small τ kills the liquid, huge τ kills the ice. The r-growth
  feedback, not the timescale value, is what matters.

## Remaining bias

v10's column liquid overshoots: clwvi mean 0.11 kg/m² vs EC-Earth 0.038, still rising at
day 2 (0.22 at end). In-cloud mixing ratios are right, so the liquid layer is too
deep/persistent rather than too concentrated. Candidate follow-ups: liquid→rain
autoconversion rate, riming, and whether EC-Earth's day-2 cloud thinning (its final-hour
max clw drops to 8e-5) has a forcing we're missing. Calibration-scale, not qualitative.

## Next steps

- Extend v10 to the full 20-day Pithan protocol run before treating it as a real result
  (per the screen's own caveat above).
- Consider raising the WBF/ConstantTimescale finding upstream (CliMA/ClimaAtmos.jl /
  CloudMicrophysics.jl): the default `cloud_ice_formation: ConstantTimescale` makes
  sustained mixed-phase Arctic clouds impossible in 1M runs. (Separate known issue: wrong
  `clivi` docstring at `core_diagnostics.jl:760-771`.)
- (tentative) Systematic τ parameter sweep with sensitivity curves: plot max(clw),
  max(cli), and liquid-cloud lifetime as functions of constant τ across a dense sampling
  of the 10–1e9 range. The existing 5-point sweep (v5–v8, v12) shows two regimes but
  doesn't characterize the transition between them. This would back the abstract's
  "suggest" with a proper sensitivity analysis.