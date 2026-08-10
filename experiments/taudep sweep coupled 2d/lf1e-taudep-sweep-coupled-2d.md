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

## Coarse grid results (8x8, 50 members)

Run completed 2026-08-10 on Stratus (4 workers, ~50 min wall-clock). 50/50
members successful. The 8x8 grid includes the 7x7 regular grid plus the
calibrated anchor at (log10_tau_dep=1.82, log10_tau_ce=2.00).

### Cloud survival requires both slow glaciation AND fast condensation

34 of 50 members have zero cloud hours. Cloud liquid persists only when
tau_dep >= 10^4 (glaciation slow enough to not destroy the cloud) AND
tau_ce <= 10^4 (condensation fast enough to maintain the cloud). Neither
condition alone is sufficient: at tau_dep=10^7 with tau_ce=10^7, there are
zero cloud hours; at tau_dep=10^1 with tau_ce=10^1, there are also zero
cloud hours (glaciation destroys the cloud before it can accumulate).

The cloud-sustaining region occupies the high-tau_dep, low-tau_ce corner of
the parameter space, not a diagonal band.

### tau_ce is a sharp threshold near 10^5 s

At tau_dep=10^7 (glaciation effectively off):
- tau_ce=10^4: 191 cloud hours, ts_end=260 K
- tau_ce=10^5: 2 cloud hours, ts_end=244 K

This 2-decade drop is nearly a complete shutoff. When condensation is slower
than ~10^5 s, the vapor-to-liquid pathway cannot sustain the cloud regardless
of how slow the ice channel is.

### tau_ce modulates the tau_dep transition location

1D slices at fixed tau_ce (fig2b) show the tau_dep transition curve shifting:
- tau_ce=10^1 s: onset at tau_dep~10^3, rapid rise to ~200h by tau_dep=10^6
- tau_ce=10^4 s: onset at tau_dep~10^4, slower rise to ~130h by tau_dep=10^7
- tau_ce=10^7 s: flat zero at all tau_dep values (condensation too slow)

Subexperiment A's 1D transition (stock microphysics, slab surface) falls
between the tau_ce=10^1 and tau_ce=10^4 slices, consistent with its stock
tau_ce being in that range (~10^2 s).

### Non-monotonic behavior at very fast condensation

At tau_dep=10^7, the tau_ce=10^1 member (203 cloud hours) has FEWER cloud
hours than the tau_ce=10^2 member (383 cloud hours). Very fast condensation
may trigger thicker cloud formation that feeds ice growth or precipitation,
limiting cloud persistence.

### Surface temperature and cloud radiative feedback (fig3)

Clear-sky members cluster at ts_end~214 K. Cloudy members range from 215 K
(short-lived clouds) to 260 K (long-lived). The 45 K surface temperature
range maps monotonically onto mean downwelling LW (fig3b), spanning
~130 W/m^2 (clear) to ~253 W/m^2 (persistent cloud). This confirms the
cloud radiative effect as the dominant surface energy budget term: cloud
insulation keeps the surface 30 to 45 K warmer than the clear-sky
equilibrium.

### Peak cloud lifetime: 383 of 480 hours

At (tau_dep=10^7, tau_ce=10^2): 383 cloud hours, max_clw=0.36 g/kg,
ts_end=257.6 K, rlds_mean=247.7 W/m^2. This is the most cloud-sustaining
point on the coarse grid.

## Figures

See `experiments/taudep sweep coupled 2d/figures/`:
- fig1_2d_regime_map: cloud metrics as 4-panel heatmap
- fig2_2d_transition: gradient magnitude + 1D slices (with subexp A overlay)
- fig3_2d_surface: surface temperature heatmap + ts_end vs rlds scatter

# TODO

- ~~Run the coarse 7x7 grid and review heatmaps.~~ Done (2026-08-10).
- If a transition ridge is visible, add refinement points. The tau_dep=4 to 6
  band at tau_ce <= 4 shows the sharpest gradient; half-decade refinement there
  would better resolve the transition boundary.
- ~~Comparative analysis: overlay 1D slices (fixed tau_ce) against
  subexperiment A's transition curve.~~ Done (fig2b).
- Joint LWP/IWP analysis: map (tau_dep, tau_ce) to (LWP, IWP) and
  characterize the geometry of the image.
