# tau_dep x tau_ce 2D transition sweep, coupled surface (lf1e-taudep-1, subexperiment C)
## author: Jeffrey Yoder
## date: August 07, 2026

# Goal

Jointly sweep sublimation_deposition_timescale (tau_dep) and
condensation_evaporation_timescale (tau_ce) on a 2D grid, with UKI-calibrated
microphysics and the ClimaSeaIce+snow coupled surface. Ice formation uses
ConstantTimescale (the ClimaAtmos default), making both timescales physically
active.

The scientific question: how do the two WBF-relevant relaxation timescales
jointly control the cloud liquid-to-ice transition when the surface temperature
evolves interactively?

## Relationship to prior subexperiments

- **A** (`experiments/taudep sweep/`): standalone, stock microphysics,
  ConstantTimescale, slab ocean at 250 K. 1D sweep over tau_dep. Found a
  multi-decade transition centered at log10(tau_dep) ~ 4.6.
- **B** (`experiments/taudep sweep coupled/`): coupled ClimaSeaIce, calibrated
  microphysics, TemperatureDependent ice formation. 1D sweep over tau_dep.
  Null result: tau_dep has no effect because the Frostenberg INP pathway
  controls glaciation independently of the WBF timescale.
- **C** (this experiment): coupled ClimaSeaIce, calibrated microphysics,
  ConstantTimescale. 2D grid sweep over tau_dep x tau_ce. Extends A's
  transition characterization to the condensation axis with an interactive
  surface and calibrated parameters.

# Protocol

## Setup

Coupled ClimaAtmos + ClimaCoupler + ClimaSeaIce path. Base atmosphere
configuration: `ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml`
with the same fast grid validated by subexperiment A's pilot (z_max 5000 m,
z_elem 60, z_stretch true, dz_bottom 10 m, dt 30 s, dt_rad 30 min).

Surface model: `ClimaSeaIceColumnSimulation` (registered as
`ice_model: "clima_seaice_column"`), same as subexperiment B.

Ice formation: ConstantTimescale (the ClimaAtmos default). No
`cloud_ice_formation` override in the YAML.

Run length: 20 days.

Environment: `julia +1.12 -t 1 --startup-file=no --project` (root env).

## Calibrated microphysics baseline

All 6 UKI-calibrated parameters from `calibrated_uki1_final.toml`. The sweep
varies tau_dep and tau_ce while holding the other 4 fixed:

| Parameter | Calibrated value | Swept? |
|---|---|---|
| sublimation_deposition_timescale | 66.59 s | Yes |
| condensation_evaporation_timescale | 101.07 s | Yes |
| cloud_liquid_water_specific_humidity_autoconversion_threshold | 3.77e-4 | No |
| snow_autoconversion_timescale | 831.87 s | No |
| Frostenberg2023_a_coefficient | 0.254 | No (inert under ConstantTimescale) |
| Frostenberg2023_b_coefficient | 1.194 | No (inert under ConstantTimescale) |

## Sweep design

2D regular grid over log10(tau_dep) x log10(tau_ce), domain [1, 7] x [1, 7].

**Coarse grid (7 x 7 = 49 points):**
- tau_dep: log10 = 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0
- tau_ce:  log10 = 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0

**Refinement (after reviewing coarse):** Half-decade or quarter-decade
resolution around any transition ridge visible in the heatmaps.

## Budget

After JIT (~5 min), each 20-day coupled member runs in ~3 min wall-clock.
49-point coarse grid with 4 workers: ~50 min.

## Execution

1. `bash scripts/sync_to_remote.sh`
2. `ssh stratus "bash 'experiments/taudep sweep coupled 2d/launch_sweep.sh'"`
3. Monitor: `ssh stratus 'tmux capture-pane -pt lf1sweep2d -S -50'`
4. `bash scripts/sync_from_remote.sh` pulls `output/lf1e-taudep-1-coupled-2d/`

# Findings

(Pending: sweep not yet run.)

# TODO

- Run the coarse 7x7 grid and review heatmaps.
- If a transition ridge is visible, add refinement points.
- Comparative analysis: overlay 1D slices (fixed tau_ce) against
  subexperiment A's transition curve to see how tau_ce modulates the
  transition location.
- Joint LWP/IWP analysis: map (tau_dep, tau_ce) to (LWP, IWP) and
  characterize the geometry of the image.
