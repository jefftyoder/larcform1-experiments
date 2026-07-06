# lf1e SCM speed test #1 — lightweight config for parameter calibration

## Purpose

The clw sensitivity screen (see `../clw sensitivity experiments/lf1e-clw-sensitivity-experiment-1.md`)
established that `cloud_ice_formation: "TemperatureDependent"` (v10) reproduces the
Larcform1 supercooled liquid cloud. The next step is tuning microphysics parameters
toward the EC-Earth clw/cli profiles, which needs ~35+ forward runs (UKI ensemble).
At the current config (~12 min, ~9–11 GiB per 2-day run) that is an overnight job;
this experiment tests whether a much lighter SCM config **replicates the v10 result**
so calibration runs cost a few minutes each.

Speed-up axes considered:
- **Domain top**: 9 km → 5 km. The cloud sits at ~300 m, inversion well below 2 km;
  nothing dynamical happens above 5 km. Radiation exposure: RRTMGP caps the column
  with a single isothermal boundary layer to p≈0 (`RRTMGPInterface.jl`,
  `add_isothermal_boundary_layer = true`), so a 5 km top makes that layer stand in
  for the whole 5 km→TOA atmosphere → possible rlds shift.
- **Vertical resolution**: 90 → 50 or 30 levels. Riskiest axis — base config warns
  "clw and z-banding both appear very sensitive to this" at `z_elem`/`z_stretch`.
- **Stretched grid**: `z_stretch: true` → `HyperbolicTangentStretching(dz_bottom)`
  (ClimaAtmos `grids.jl:348`) with `dz_bottom: 10.0` from the base config: ~10 m
  layers at the surface growing toward the top — *finer* than base at cloud height
  with 3× fewer levels, but stretch is the specifically flagged landmine.
- **Radiation timestep**: 5 min → 30 min (6× fewer RRTMGP calls; EC-Earth runs
  radiation hourly). Polar-night LW-only case evolving over hours → low risk.
- **Diagnostics**: minimal set (20 vars @ 1 h — exactly what `convert_to_pithan.py`
  consumes) instead of the base's ~30 1-h vars + 54 vars at 10-min cadence.
  Applied to **all** runs in this experiment, so its speed contribution is not
  isolated (it is bundled into every comparison against the reference).

## Reference

- **Science reference**: v10 full-res run, physics identical
  (`../clw sensitivity experiments/output/pithan_format/v10_tdepice.nc`):
  max clw 5.105e-4 at ~1005 hPa, onset hour ~5, 43/48 hrs above 1e-4,
  clivi → 5.0e-3 by hour 48, precs end 7.5e-6, rlds ~225 W/m².
- **Timing reference**: v10-era full runs took ~12 min each (with full diagnostics,
  warm julia process, single-threaded).
- Base config: `ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml`
  (9 km top, 90 uniform levels → dz = 100 m, dt = 30 s, dt_rad = 5 min, Float32, 2 days).

All variations carry `cloud_ice_formation: "TemperatureDependent"` (v10 physics)
and the minimal diagnostics block.

## Run matrix

Group A — one axis at a time:

| run | z_max | z_elem | dz | z_stretch | dt_rad | isolates |
|---|---|---|---|---|---|---|
| s1_ztop5km | 5000 | 50 | 100 m | false | 5 min | domain top (dz preserved) |
| s2_dtrad30min | 9000 | 90 | 100 m | false | 30 min | radiation timestep |
| s3_dz167 | 5000 | 30 | ~167 m | false | 5 min | coarse resolution (vs s1) |
| s4_stretch | 5000 | 30 | 10 m @ sfc, tanh | true | 5 min | stretched grid (vs s3) |

Group B — combined speed-ups:

| run | z_max | z_elem | dz | z_stretch | dt_rad | |
|---|---|---|---|---|---|---|
| s5_combo_conservative | 5000 | 50 | 100 m | false | 30 min | s1 + s2 |
| s6_combo_aggressive | 5000 | 30 | ~167 m | false | 30 min | s3 + s2 |

Attribution notes: s3 confounds top + resolution, but s3−s1 isolates resolution;
s4−s3 isolates stretch. If s4 (stretch) turns out both fast and faithful, a
stretch-based combo can be added as a follow-up (s7).

## Execution

From the repo root, one persistent julia process for the whole batch (JIT paid once):

```
julia -t 1 --project=ClimaAtmos.jl/.buildkite \
  "experiments/scm speed tests/run_batch.jl" \
  "experiments/scm speed tests/configs/s1_ztop5km.yml" \
  "experiments/scm speed tests/configs/s2_dtrad30min.yml" \
  "experiments/scm speed tests/configs/s3_dz167.yml" \
  "experiments/scm speed tests/configs/s4_stretch.yml" \
  "experiments/scm speed tests/configs/s5_combo_conservative.yml" \
  "experiments/scm speed tests/configs/s6_combo_aggressive.yml"
```

- Run a short warmup overlay (t_end: 600secs, output to scratchpad) as the first
  batch entry, or discount run 1's walltime: the first variation pays compilation.
- Runs are sequential; RAM limits us to one julia process at a time (~9–11 GiB at
  90 levels; expect less at 30–50).
- Record per-run walltime from the batch summary and RSS from the log.

## Conversion & analysis

Convert each run with `scripts/convert_to_pithan.py` (`_SUFFIX = "1h_average"`) into
`output/pithan_format/<run>.nc` in **this** folder; the converter regrids to
EC-Earth's fixed pressure grid, so grids of different z_elem compare directly.

## Acceptance criteria (vs full-res v10)

1. Cloud at the same height (peak clw ~1005 hPa) and onset (~hour 5).
2. Max clw within ~20% of 5.105e-4; hours > 1e-4 threshold comparable to 43/48.
3. clivi trajectory same shape and magnitude (end ~5.0e-3).
4. rlds within a few W/m² (checks the 5 km isothermal-cap radiation bias).
5. Walltime: report speed-up factor per run vs the ~12 min reference.

Decision rule: adopt the fastest config that passes 1–4. If only s5 passes, a
~2.5–3× speed-up is still sufficient for calibration.

# Results (2026-07-04)

All 7 batch entries (warmup + s1–s6) completed with `ret_code :success`; every run
simulated the full 48 h. Log: `output/lf1e-speed-1/local_run_20260704_211331.log`.

## Timing

`solve!` walltime (pure time-stepping, setup/JIT excluded) vs ~660 s for the
original full config:

| run | solve! | speed-up | batch walltime |
|---|---|---|---|
| s1_ztop5km | 32.8 s | ~20× | 4m27s (JIT: new z_elem) |
| s2_dtrad30min | 26.5 s | ~25× | 4m25s (JIT) |
| s3_dz167 | 15.2 s | ~43× | 18.6 s |
| s4_stretch | 21.5 s | ~31× | 4m4s (JIT: mesh type) |
| s5_combo_conservative | 16.5 s | ~40× | 20.1 s |
| s6_combo_aggressive | 11.7 s | ~56× | 15.2 s |

Two surprises:

1. **The 10-min tendency/EDMF diagnostics were the dominant cost of the original
   config, not radiation or resolution.** s2 keeps the full 90-level grid and only
   changes dt_rad + diagnostics, yet solves in 26.5 s. Accumulated-average
   diagnostics are computed every timestep; the 54-variable microphysics/EDMF set
   was consuming ~90% of the original ~11 min runtime.
2. **ClimaCore encodes the vertical level count (and mesh type) in its types**, so
   every distinct z_elem / z_stretch pays full recompilation (~4 min). In a
   calibration loop the config is fixed → paid once per worker, irrelevant.
   Radiation cost per call: ~34 ms at 50 levels, ~7 ms at 30 (s1−s5, s3−s6 differences).

## Science (vs full-res v10; converted files in `output/pithan_format/`)

| run | max clw | hrs>1e-4 | onset | peak lev | clivi end | clwvi mean | rlds bias |
|---|---|---|---|---|---|---|---|
| v10 ref | 5.105e-4 | 43/48 | h5 | 50 m | 5.01e-3 | 0.113 | — |
| s1 | 5.096e-4 | 43/48 | h5 | 50 m | 4.58e-3 | 0.120 | +0.2 W/m² |
| s2 | 5.158e-4 | 41/48 | h6 | 50 m | 4.30e-3 | 0.112 | −0.4 |
| s3 | 4.838e-4 | 40/48 | h7 | 83 m | 4.28e-3 | 0.102 | −2.8 |
| s4 | 4.527e-4 | 48/48 | h2 | 220 m | 4.71e-3 | 0.129 | −0.3 |
| s5 | 5.155e-4 | 42/48 | h6 | 50 m | 4.49e-3 | 0.119 | −0.4 |
| s6 | 4.835e-4 | 39/48 | h7 | 83 m | 3.88e-3 | 0.099 | −3.0 |

(Peak-lev differences of 50 m vs 83 m are one grid cell at the coarser dz.)

- **s1, s2, s5 pass cleanly** — max clw within 1%, same peak cell, onset within
  1 h, clivi within 15%, rlds within 0.5 W/m². The 5 km isothermal-cap radiation
  bias is negligible (+0.2 W/m²).
- **s3/s6 (dz 167 m) are borderline**: max clw −5%, onset +2 h, clivi −14/−23%,
  rlds ≈ −3 W/m². Usable, but grid error of that size would fold into calibrated
  parameters.
- **s4 (stretch) confirms the config warning in character**: no crash or banding,
  but a different cloud — onset h2, 48/48 h persistence, peak at 220 m, clwvi +14%.
  The grid changes the answer more than any other single axis. Avoid.

## Decision

**Adopt s5_combo_conservative** as the calibration config: ~40× speed-up
(16.5 s solve, ~20 s per run warm) with science indistinguishable from full-res
v10 at the level of the quantities we will calibrate against. s6's extra 5 s is
not worth a −23% cli baseline shift when cli is a calibration target.

# Convergence tests (added 2026-07-04, after Results)

s4's deviation from the uniform-grid runs raised the question: is the stretched
grid *more faithful* (EC-Earth onset h1 / 47 of 48 h persistence looks like s4's
h0 / 48 of 48, not s5's h4 / 42 of 48), or is stretch introducing artifacts (the
base config's z-banding warning)? Note EC-Earth's fine near-surface spacing is
native to its hybrid sigma-pressure coordinates, not a grid-design choice — so
the discriminator is convergence, not analogy.

| run | grid | z_elem | isolates |
|---|---|---|---|
| s7_dz50 | uniform 50 m | 100 | uniform ladder rung 1 |
| s8_dz25 | uniform 25 m | 200 | uniform ladder rung 2 |
| s9_dz10 | uniform 10 m | 500 | uniform ladder anchor (= s4's near-surface dz everywhere) |
| s10_stretch100 | tanh, 10 m bottom | 100 | is s4 converged within the stretched family? |

All: 5 km top, dt_rad 5 min (comparable with s3/s4), v10 physics, minimal
diagnostics, dt 30 s. No warmup run: every distinct grid recompiles anyway, so
per-run timing comes from the logged `solve!` walltime.

Interpretation rules:
- Uniform ladder (s3 → s7 → s8 → s9) marches toward s4's answer → 100 m was
  under-resolved; s4-like behavior is the faithful answer; revisit the choice of
  s5 as calibration config.
- Ladder converges near s5's answer while s4/s10 sit apart → stretch distorts;
  s5 stands.
- s10 ≈ s4 → stretched answer is resolution-stable aloft (whatever its fidelity).

## Convergence results (2026-07-04)

> **EC-Earth caveat (added 2026-07-05)**: the EC-Earth reference file spans
> **20 days (481 hourly steps)**, not 2; every EC-Earth number in this
> document (onset h1, 47/48 hrs, clwvi mean 0.038, clivi end 2.3e-2) describes
> only its first 48 h. The full record shows EC-Earth's cloud **glaciating on
> day 3** (liquid ≡ 0 from day 4, ice-only thereafter), so model-vs-EC-Earth
> persistence statements here apply to the day-1–2 mixed-phase window only.
> Details in "experiments/clw calibration/lf1e-clw-calibration-1.md".

All four completed (`local_run_convergence_20260704_215607.log`). solve! walltimes:
s7 38 s, s8 62 s, s9 130 s, s10 43 s.

| run | grid | max clw | hrs>1e-4 | onset | clivi end | clwvi mean | h24 cloud base/top (hPa) |
|---|---|---|---|---|---|---|---|
| EC-Earth | hybrid-p L60 | 6.81e-4 | 47/48 | h1 | 2.3e-2 | 0.038 | thin layer at 979 |
| v10 ref | uniform 100 m | 5.11e-4 | 43/48 | h3 | 5.0e-3 | 0.113 | 1002/976 |
| s3 | uniform 167 m | 4.84e-4 | 40/48 | h5 | 4.3e-3 | 0.102 | single cell 993 |
| s7 | uniform 50 m | 5.37e-4 | 45/48 | h2 | 4.5e-3 | 0.134 | 1001/962 |
| s8 | uniform 25 m | 5.01e-4 | 47/48 | h1 | 4.1e-3 | 0.138 | 1003/963 |
| s9 | uniform 10 m | 3.98e-4 | 48/48 | h0 | 3.7e-3 | 0.136 | 1004/964 |
| s4 | stretch, 30 lev | 4.53e-4 | 48/48 | h0 | 4.7e-3 | 0.129 | 1004/969 |
| s10 | stretch, 100 lev | 3.97e-4 | 48/48 | h0 | 4.1e-3 | 0.138 | 1004/964 |

**The uniform ladder marches monotonically toward the stretched answer on every
timing/persistence metric** (onset h5→h4→h2→h1→h0; persistence 40→42→45→47→48 of
48). 100 m was under-resolved; the stretch was not distorting — it was resolving.
The z-banding warning did not materialize under v10 physics.

- **s10 ≈ s9** (max clw 3.97 vs 3.98e-4, onset h0, 48/48, clwvi 0.138 vs 0.136,
  h24 cloud base/top within 1 hPa): the converged answer, at 1/3 of s9's cost.
  s4 (30 stretched levels) is close but not fully converged (max clw +14%,
  cloud top 5 hPa low).
- **Onset/persistence vs EC-Earth was a resolution artifact, not microphysics**:
  converged runs (h0, 48/48) bracket EC-Earth (h1, 47/48). The remaining
  EC-Earth gaps are amount-type: converged max clw ~4.0e-4 vs 6.8e-4, clwvi mean
  ~0.137 vs 0.038, clivi 4e-3 vs 2.3e-2 — these are the calibration targets.
- Peak clw sits at cloud top (~964–969 hPa) in all converged runs; EC-Earth's
  single-level cloud at 979 hPa is consistent with that structure at L60
  resolution.
- **Literature counterpoint (added 2026-07-05, Pithan 2016)**: the canonical
  Larcform1 resolution result points the OTHER way — the paper's
  high-resolution WRF-200l *lost* its liquid cloud while WRF-90l kept it,
  because WRF-200l's 1.2 m-thick lowest level dried to the surface via frost
  deposition (ice-saturated but never water-saturated). Our ladder (finer →
  earlier onset, more persistent liquid) does NOT reproduce that
  surface-drying failure mode at any resolution tested — plausibly because our
  thinnest layer is 10 m (dz_bottom), and the slab-ocean surface supplies
  heat/moisture differently from WRF's ice surface. Different model, different
  mechanism, so no contradiction — but the on-point literature result is
  opposite in direction, and our fine grids' immunity to it is a real
  (previously unremarked) robustness check passed.

**Revised decision**: prefer **s10's grid (z_elem 100, z_stretch true, 5 km top)**
over s5 for calibration — converged science at 43 s solve (still ~15× vs the old
config; ~35 s expected with dt_rad 30 min, to be validated as "s11" if adopted).
Calibrating on s5's unconverged grid would tune parameters against a resolution
artifact (late onset / intermittency) that isn't a microphysics deficiency.

## Base-config update (2026-07-04)

Applied the validated speed-ups to the top-level
`ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml`:
`dt_rad: 5mins → 30mins` and diagnostics reduced to the minimal 20-var converter
set (the 10-min EDMF/microphysics-tendency groups live in git history; restore
via overlay when debugging microphysics). Grid (9 km / 90 / uniform) and dt
unchanged. dt_rad 1 h was considered and deferred until validated.
Consequence: experiment overlays that do not set `dt_rad`/`diagnostics`
(clw-sensitivity v1–v12; speed-test s1/s3/s4, s7–s10) now inherit the new values
on RE-runs — recorded outputs and findings in this and the clw experiment are
from the old base (dt_rad 5 min).

# Validation runs (s11–s13, 2026-07-04)

Three runs on the converged s10 grid (z_max 5000, z_elem 100, z_stretch true),
minimal diagnostics, batch log `local_run_validation_20260704_230520.log`:

- **s11** — dt_rad 30 min, TemperatureDependent (the calibration candidate).
- **s12** — dt_rad 1 h, TemperatureDependent (evidence for the deferred base change).
- **s13** — dt_rad 30 min, NO cloud_ice_formation override → default
  ConstantTimescale (v1 physics control / falsification test).

## Validation results

| run | solve | max clw | hrs>1e-4 | onset | clwvi mean | rlds mean | h24 base/top (hPa) |
|-----|-------|---------|----------|-------|------------|-----------|--------------------|
| s10 (rad 5 min, ref) | 43 s | 3.97e-4 | 48/48 | h0 | 0.1384 | 224.6 | 1004/964 |
| s11 (rad 30 min) | 42 s | 4.19e-4 (+5.5%) | 48/48 | h0 | 0.1300 (−6.1%) | 223.8 (−0.8) | 1004/966 |
| s12 (rad 1 h) | 33 s | 4.19e-4 (+5.4%) | 47/48 | h1 | 0.1227 (−11.3%) | 223.0 (−1.6) | 1004/969 |
| s13 (v1 physics) | 27 s | **0.000e0 exactly** | 0/48 | — | 0.0000 | 189.3 | no cloud |
| EC-Earth | — | 6.81e-4 | 47/48 | h1 | 0.0376 | 238.6 | 979 (single level) |

**s11 — PASS (calibration config validated).** Onset h0, 48/48 persistence,
max clw +5.5% (criterion ±10%), rlds −0.83 W/m² (criterion ±1), cloud base
within 0.1 hPa, no sawtooth in hourly clwvi increments (0 sign flips h6+; the
30-min-stale heating does not induce cloud-top flicker on 10 m layers). Two
metrics land just outside the tightest wording: clwvi mean −6.1% ("a few %")
and h24 cloud top +2.5 hPa (~2 hPa) — both deviations are *toward* EC-Earth,
are ≲1 stretched level in size, and are far smaller than the amount-type gaps
calibration must close (clwvi 3.5× high, max clw 40% low). Accepted.

**s12 — marginal; do not move base to 1 h.** Onset slips to h1 and one hour
drops below threshold (matching EC-Earth, but a real change from s10), clwvi
−11.3%, rlds −1.6 W/m². The reward is only ~9 s per run over s11 — not worth
adding a second confounded factor before calibration. dt_rad stays 30 min.

**s13 — discriminator preserved; headline finding strengthened.** clw is
exactly zero at every level, every hour (not merely below threshold), while
ice/snow stay alive (clivi end 4.7e-3, precs mean 5.2e-6 — same magnitudes as
v1). With 10 m cloud-top resolution this closes the resolution loophole in the
clw experiment's root-cause claim: **no amount of vertical resolution rescues
Arctic mixed-phase liquid under default ConstantTimescale deposition** — the
unbounded WBF sink is a physics failure, not a discretization one. (Scope:
ClimaAtmos with this slab surface, 10–167 m grids. In the literature
resolution CAN change the liquid — Pithan 2016's WRF-200l lost its cloud at
high resolution via near-surface frost drying; see the counterpoint bullet in
Convergence results.) The light grid keeps full contrast on the parameters we
intend to calibrate.

**Decision: s11 (`configs/s11_stretch100_rad30.yml`) is the calibration
forward-model config** — converged science, discriminator intact, 42 s solve
(~16× vs the original config; JIT compile ~7 min paid once per session).

## Follow-ups after a winner is chosen

- ~~**Sensitivity-preservation control**: rerun the winning config with v1 physics
  (default `ConstantTimescale`) — it must still produce clw ≈ 0, confirming the
  light config preserves the discriminator we plan to calibrate against.~~
  Done: s13, passed (exact zeros).
- Optionally test dt 30 s → 60 s as a further speed-up (kept out of this matrix to
  avoid confounding solver stability with grid/radiation effects).
- Wire up the UKI calibration loop on s11's config (perfect_scm-style
  JuliaBackend runner; gcm_driven_scm-style log-clw + cli observation design;
  EC-Earth day-2 profiles as target; Frostenberg2023_a/b leading the prior).
