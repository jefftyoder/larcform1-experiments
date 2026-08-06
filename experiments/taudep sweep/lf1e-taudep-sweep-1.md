# tau_dep transition sweep #1 (lf1e-taudep-1)
## author: Jeffrey Yoder
## date: August 06, 2026

# Goal

Characterize how the Larcform1 transient responds to the constant vapor to cloud ice
deposition timescale, `sublimation_deposition_timescale` (tau_dep), across its full
plausible range (10 s to 1e9 s). The clw sensitivity experiment
(`experiments/clw sensitivity experiments/lf1e-clw-sensitivity-experiment-1.md`)
established the mechanism (unbounded WBF scavenging under the ConstantTimescale
default kills supercooled liquid) and left five coarse points showing two regime
changes: no liquid to transient liquid somewhere in (1e3, 1e4) s, and transient to
sustained liquid with negligible ice somewhere in (1e4, 1e9) s. This experiment
locates and characterizes those transitions with a dense, adaptively refined sweep,
turning the abstract's qualitative claim into a proper sensitivity analysis.

Framing: we borrow from bifurcation and orbit diagram practice, with tau_dep as the
control parameter, but the system under study is a finite transient (the Pithan 2016
four stage arc toward the clear state), not an attractor. The "order parameters" are
therefore transient summary metrics per run, and sampling is coarse where the response
is flat, dense near the transitions.

# Protocol

## Setup

Standalone ClimaAtmos path (SlabOceanSST initialized to 250 K standing in for the
interactive surface; see the clw experiment's Setup section for the caveats that
implies), 1M microphysics, prognostic EDMFx. Base configuration:
`ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml` with the
speed test validated fast grid pinned explicitly:

- z_max 5000 m, z_stretch true, dz_bottom 10 m, z_elem from the grid pilot below
- dt 30 s, dt_rad 30 min, minimal hourly diagnostics (already in the base yml)
- t_end 5 days for sweep members (captures onset, glaciation near day 3, collapse)
- FLOAT_TYPE Float32, fixed RNG seed 1234 per member: runs are deterministic

Note the grid keys are pinned in code because the base yml drifted after the speed
tests validated this family (dz_bottom moved 10 to 20 in ClimaAtmos commit
2bbdfa542); inheriting the current base would silently leave the validated grid.

Environment: `julia +1.12 -t 1 --project=ClimaAtmos.jl/.buildkite`, the same env
as every prior standalone Larcform1 baseline (clw experiments, speed tests), with
ClimaAtmos dev'd from the submodule and NCDatasets/YAML as direct deps. This env
carries registered CloudMicrophysics, which is fine here: ConstantTimescale needs
no vendored patch. Two caveats discovered 2026-08-06: (1) the repo root env on
Stratus is currently unusable for standalone runs (ClimaAtmos appears there as a
registered, undownloaded package, contradicting CLAUDE.md's dev'd setup; flagged
to Jeff); (2) a future Frostenberg a/b sweep must not run in the buildkite env,
since the vendored CloudMicrophysics patch is inert there. Revisit the env before
that sweep.

## Stage -1: grid pilot (decision point)

The speed tests measured only two stretched spacings at z_max 5000: z_elem 30 (s4,
not converged: max clw +14%, cloud top 5 hPa low) and z_elem 100 (s10/s11,
converged). Whether 60 or 80 levels suffices was never measured. The pilot closes
that gap before the sweep spends any members:

- z_elem 100, 80, 60; each runs 2 days twice: once with
  `cloud_ice_formation: "TemperatureDependent"` (so there is a cloud to compare)
  and once with v1 physics (the discriminator: clw must be exactly zero).
- The z100 TemperatureDependent run is the acceptance reference (same code, same
  current base config); the published s11 numbers are printed only as a drift check.
- Acceptance per candidate grid: max clw within 5% of z100, onset within 1 h,
  cloud hours within 2, hour 24 cloud base and top within 2 hPa, clivi_end within
  half a decade, and the discriminator exactly zero.
- Decision rule: adopt the coarsest passing grid; if none passes, z_elem 100.
  Reviewed by hand; the sweep does not start itself.

Run: `julia +1.12 -t 1 --project "experiments/taudep sweep/run_sweep.jl" pilot`

## Sweep stages

Control parameter x = log10(tau_dep) on [1, 9]. Order parameters per member, from
the hourly diagnostics (computed by `metrics` in `sweep_tools.jl`):

| metric | meaning |
|---|---|
| max_clw | max over (time, level) of clw, kg/kg |
| cloud_hours | hours with max_z clw > 1e-4 kg/kg |
| onset_hour, collapse_hour | first and last hour above that threshold |
| max_lwp, lwp_int | peak and time integrated liquid water path |
| clivi_end, max_clivi | column ice at end and peak (separates the liquid only regime) |
| clear_hour | last hour with meaningful condensate (lwp > 1e-3 or clivi > 1e-4 kg/m2) |
| ts_end | final surface temperature (four stage arc diagnostic) |

Stages, all in one Julia process (JIT paid once, members solved serially, manifest
written after every member, successful members skipped on rerun):

0. Anchors with hard signature checks: tau = 100 must give clw identically zero
   (s13 result), tau = 1e9 must give sustained liquid with negligible ice (v12
   signature). A failed anchor aborts the sweep: it means the pipeline is wrong,
   not the physics.
1. Coarse scan: 2 points per decade, tau = 10^{1.0, 1.5, ..., 9.0}.
2. Adaptive refinement (budget 25 by default): repeatedly bisect, in log space,
   the interval with the largest range normalized jump in (cloud_hours, max_clw,
   log10 clivi_end); stop at jump tolerance 0.15 or interval width 0.1 decades
   (0.05 inside jumps above 0.5, the sharpest transition). Deterministic greedy
   bisection: no human in the loop required.
3. Optional dense window (`--stageC`): 10 uniform points across plus or minus 0.25
   decades around the sharpest transition, to establish whether cloud_hours grows
   continuously (second order like) or jumps (first order like), and the width.

Run: `julia +1.12 -t 1 --project "experiments/taudep sweep/run_sweep.jl" sweep --z_elem <N> [--budget 25] [--t_end 5days] [--stageC]`

Budget: about 52 members maximum (6 pilot runs + 2 anchors + 15 coarse + 25
adaptive + 10 dense), roughly 1 to 2 hours of serial solve on Stratus at z_elem
100, less on a coarser passing grid. The sweep is useful from the coarse scan
onward; it can stop at any point past Stage A and still yield a complete curve.

## Configuration mechanics (why there are no per member config files)

Members are configured in memory: the base yml is loaded as a Dict, sweep keys are
merged on top, and `CA.AtmosConfig(dict)` is called directly (run_batch.jl pattern,
which also avoids the ci_driver job_id shadowing bug). Parameter mechanics, learned
the hard way during the pilot (2026-08-06): a `toml: [base, override]` pair does
NOT work, because AtmosConfig merges the list via `ClimaParams.merge_toml_files`,
which errors on duplicate keys instead of overriding
("Duplicate TOML entry: sublimation_deposition_timescale"); this, not YAML overlay
merging, is the real reason the clw experiment used full copy TOMLs. Instead the
full member TOML is generated programmatically (stdlib TOML: parse base, replace
the one value, print) into the member's own output tree and passed as the single
`toml:` entry, so it is synced back with results.
Provenance per member: the run's auto saved `<job_id>_parameters.toml` (grep it to
confirm the swept value landed, per project convention) plus the manifest entry
(tau, stage, ret_code, walltime, z_elem, t_end, metrics) in
`output/lf1e-taudep-1/manifest.toml`.

## Execution on Stratus

Kaimon was the preferred transport but is not working on Stratus as of 2026-08-06;
the sweep runs through the proven tmux path instead. The entry points are transport
agnostic, so a Kaimon REPL can drive the same functions later.

1. `bash scripts/sync_to_remote.sh` (refuses while julia is live on Stratus).
2. Pilot: `ssh stratus "bash '~/clima/larcform1-experiments/experiments/taudep sweep/launch_pilot.sh'"`
   (tmux session lf1pilot). Review the printed table, decide z_elem with Jeff.
3. Sweep: `ssh stratus "bash '~/clima/larcform1-experiments/experiments/taudep sweep/launch_sweep.sh' <z_elem>"`
   (tmux session lf1sweep; extra run_sweep args pass through).
4. Monitor: `ssh stratus 'tmux capture-pane -pt lf1sweep -S -50'` and read the
   manifest; no `tmux attach` from Claude Code. `monitor_pilot.sh <session>` polls
   from the Mac and prints progress lines.
5. `bash scripts/sync_from_remote.sh` pulls `output/lf1e-taudep-1/` (manifest,
   NetCDF, logs) back for analysis.

## Analysis

`analysis.py` (written once data exists; load the agu-figures skill first):
transition diagrams (each order parameter vs log10 tau, points labeled by stage)
and a small multiples panel of lwp(t) traces colored by tau showing the transient
families. Everything re derivable from manifest.toml plus the synced NetCDF; no
state trapped in any REPL.

# Findings (2026-08-06, sweep complete: 39 members, all successful)

## Grid pilot

z80 and z60 both pass every convergence criterion against the same code z100
reference (z60: max clw +2.9%, onset and persistence identical, hour 24 cloud
top within 0.4 hPa, clivi within 8%), and the v1 discriminator gives clw
exactly zero on all three grids. z60 adopted; roughly half the z100 solve cost.
The z100 reference also matches the published s11 numbers (max clw 4.08e-4 vs
4.19e-4, rlds 223.4 vs 223.8), so base config drift since the speed tests does
not affect the science. Note the 30 level grid (s4) remains unconverged; 60 is
the floor, not 30.

## Transition structure (figures/fig1, fig2)

- Liquid onset is at tau_dep of roughly 1.3e3 s: max_z clw first exceeds the
  0.1 g/kg threshold between log10 tau 3.0 and 3.12. Below that, clw is not
  exactly zero from 10^2.5 up (max clw 1.6e-5 at 10^2.5, 7.5e-5 at 10^3), so
  the liquid gate opens continuously; only tau at or below the 100 s default
  gives the exact zero.
- Cloud lifetime (hours above threshold, of 120) grows continuously and
  monotonically across three and a half decades: 2 h at 10^3.1, 18 h at
  10^3.5, 32 h at 10^4, 67 h at 10^5, 116 h at 10^6, saturating at 120 by
  10^6.5. No first order jump anywhere; second order like in the transient
  sense. The steepest normalized change sits in log10 tau of 3.1 to 3.8,
  where the adaptive and dense stages concentrated 15 members.
- Peak liquid intensity saturates much earlier than lifetime: max clw reaches
  its ceiling of about 4.1e-4 kg/kg by 10^4.25 while integrated LWP is still
  30x below its large tau limit. The transition is about persistence, not
  intensity: fig2 shows all cloudy members share one LWP growth envelope and
  differ almost purely in when they glaciate and collapse off it.
- Ice is unaffected through the liquid transition: clivi_end holds near
  6.5e-3 kg/m2 from 10^1 to 10^5, then decays smoothly to 8.9e-5 at 10^9.
  The 5 day liquid only regime (v12's signature) emerges gradually above
  10^7 rather than at a sharp boundary.
- Protocol note: no member reaches a fully clear column in 5 days (ice
  persists everywhere; clear_hour 119 throughout), so characterizing the full
  four stage arc to the clear state needs longer runs. Recorded as follow up.

## Execution notes

- 39 members: 2 anchors (signature checks passed: tau 100 gives clw identically
  zero at 5 days on z60; tau 1e9 sustains liquid with negligible ice), 15
  coarse, 13 adaptive, 9 dense. Walltime about 36 s per warm member (z60,
  5 days, Stratus single thread).
- Serial phase throughput 101 members/hr; 4 worker phase 254 members/hr
  (2.5x; per member walltime inflation only 1.11x, the rest is adaptive batch
  barriers). Dedicated scaling test (workers 1/2/4/6) run separately.
- Restart semantics verified in production: the parallel relaunch skipped all
  6 members the killed serial run had completed.

# TODO (deferred by decision, 2026-08-06)

- IC perturbation ensembles near the critical tau window, to separate parameter
  sensitivity from internal variability. Deferred to keep this experiment simple.
- Same protocol for `condensation_evaporation_timescale`.
- Same protocol for the Frostenberg a and b parameters of the TemperatureDependent
  scheme. Must run in the root env where the vendored CloudMicrophysics patch is
  active; the buildkite env silently reverts to registered CloudMicrophysics.
- Optional dt 30 s to 60 s speedup validation if more members are ever needed
  (listed as a speed test follow up; anchors must be unchanged).
- Retry Kaimon driven execution once Kaimon works on Stratus again.
