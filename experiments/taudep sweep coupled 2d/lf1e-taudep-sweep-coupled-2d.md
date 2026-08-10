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

## Reference

Pithan et al. (2016), *JGR Atmospheres*: SCM intercomparison for Arctic
boundary layer. Location 80 N, January start (zero insolation throughout),
20-day run, initial surface temperature 250 K. See CLAUDE.md for the full
Pithan protocol tables.

## Atmosphere model

Coupled ClimaAtmos + ClimaCoupler + ClimaSeaIce path. Base atmosphere
configuration: `ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml`.

| Component | Setting |
|---|---|
| Turbulence/convection | Prognostic EDMFx (generalized entrainment/detrainment) |
| Cloud fraction | Quadrature |
| Microphysics | 1-moment (1M), ConstantTimescale ice formation |
| Radiation | AllSkyWithClear (RRTMGP), dt_rad = 30 min |
| Insolation | Larcform1 (80 N, Jan 1, polar night: zero throughout) |
| Prognostic TKE | Yes |
| Time integration | ARS222, dt = 30 s |
| Precision | Float32 |
| Sponge | Rayleigh sponge at domain top |

## Grid

| Parameter | Value |
|---|---|
| Domain type | Single column |
| z_max | 5000 m |
| z_elem | 60 levels (stretched) |
| dz_bottom | 10 m |

## Atmospheric initial conditions (Pithan Table 1)

Temperature, humidity, and geostrophic wind profiles follow Pithan et al.
(2016) Table 1, implemented in `AtmosphericProfilesLibrary/Larcform1.jl`:

- **Temperature**: T(z) = 273 K with lapse rate 8 K/km from the surface
  (1013 hPa) to 300 hPa; isothermal above 300 hPa.
- **Humidity**: relative humidity w.r.t. liquid water, linearly interpolated
  in pressure: 80% at the surface (1013 hPa), 20% at 600 hPa and above.
  Above 300 hPa: specific humidity fixed at 3e-6 kg/kg.
- **Geostrophic wind**: u_g = 5 m/s below 300 hPa, 0 above; v_g = 0.
- **Location**: 80 N, 0 E. Coriolis f = 1.432e-4 s^-1.
- **Start date**: January 1 (polar night, zero insolation).

## Greenhouse gas concentrations (Pithan Table 2)

| GHG | Volume-mixing ratio |
|---|---|
| CO2 | 360e-6 |
| N2O | 309.5e-9 |
| CH4 | 1693.6e-9 |
| CFC-11 | 252.8e-12 |
| CFC-12 | 466.2e-12 |

## Surface model

ClimaSeaIceColumnSimulation (registered as `ice_model: "clima_seaice_column"`),
the same coupled sea-ice component used in subexperiment B.

| Parameter | Value |
|---|---|
| Initial surface temperature | 250 K |
| Ice thickness | 1.0 m |
| Snow on ice | 0.1 m water equivalent |
| Ice concentration | 1.0 (full cover) |
| Bottom temperature | 271.35 K (seawater freezing point) |
| Ocean heat flux | 0 W/m^2 |
| Surface albedo | 0.65 |
| Emissivity | 1.0 |
| Roughness lengths (z0m, z0b) | 1e-3 m |
| Ice conductivity | 2.0 W/m/K |
| Snow conductivity | 0.31 W/m/K |
| Thermodynamics | SlabThermodynamics, MeltingConstrainedFluxBalance (top), PrescribedTemperature (bottom) |

## Coupling

| Parameter | Value |
|---|---|
| Coupler | ClimaCoupler v0.2.2 |
| Mode | AMIP (CoupledSimulation) |
| Coupling timestep (dt_cpl) | 30 s |
| Surface type | scm_surface_type: sea_ice |
| Flux calculation | Monin-Obukhov via SurfaceFluxes.jl |

All parameter TOMLs routed through `coupler_toml:` (not atmos `toml:`) to
work around the ClimaCoupler v0.2.2 parameter-clobber bug (see CLAUDE.md).

## Ice formation scheme

ConstantTimescale (the ClimaAtmos default). No `cloud_ice_formation` override
in the YAML. This is the key difference from subexperiment B, which used
TemperatureDependent (Frostenberg INP pathway). Under ConstantTimescale,
both tau_dep and tau_ce are physically active: tau_dep controls the
vapor-to-ice deposition and sublimation rate, tau_ce controls the
vapor-to-liquid condensation and evaporation rate.

Run length: 20 days.

Environment: `julia +1.12 -t 1 --startup-file=no --project` (root env).

## Diagnostics

Hourly averages: ta, thetaa, pfull, rhoa, hus, hur, ts, tas, ua, va, wa,
cl, clw, cli, lwp, clivi, rlu, rld, rlut, rlus, rlds, rsdt, rlutcs,
rldscs, pr, prsn, evspsbl, husra, hussn, hfss, hfls.

10-minute averages: EDMF updraft and environment profiles (arup, waup,
taup, waen, taen, tke, entr, detr, lmix, bgrad, strain, edt, evu).

10-minute instantaneous: full 1M microphysics tendency decomposition
(grid-mean, updraft, environment) for all phase-change, autoconversion,
accretion, and melting processes.

Output: `netcdf_output_at_levels: true` (raw model levels, no vertical
interpolation). Default diagnostics disabled.

## Calibrated microphysics baseline

Two TOML files are loaded via `coupler_toml:` in order:

1. `experiments/clw calibration/configs/toml/larcform1_calibration_base.toml`:
   EDMF parameters (entrainment/detrainment coefficients, area limiters,
   mixing length, pressure normalmode, sponge heights).

2. `experiments/clw calibration/configs/toml/calibrated_uki1_final.toml`:
   UKI iteration-7 posterior means for 6 microphysics parameters.

The sweep varies tau_dep and tau_ce while holding the other 4 fixed:

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

## Coarse grid results (7x7 + anchor, 50 members)

Run completed 2026-08-10 on Stratus (4 workers, ~50 min wall-clock). 50/50
members successful. The sweep includes the 7x7 regular grid (49 points at
integer log10 values 1 through 7 on both axes) plus the calibrated anchor
at (log10_tau_dep=1.82, log10_tau_ce=2.00).

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
- tau_ce=10^4: 191 cloud hours, ts_end=259.8 K
- tau_ce=10^5: 2 cloud hours, ts_end=243.9 K

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

Most clear-sky members (29 of 34 with zero cloud hours) cluster at
ts_end ~ 214 to 216 K, though 5 zero-cloud members at high tau_dep with
high tau_ce reach 218 to 238 K (partial condensation warming without
sustained cloud). Cloudy members range from 244 K (short-lived clouds)
to 260 K (long-lived). The 46 K total surface temperature range
(213.5 to 259.8 K) maps monotonically onto mean downwelling LW (fig3b),
spanning ~132 W/m^2 (clear) to ~253 W/m^2 (persistent cloud). This
confirms the cloud radiative effect as the dominant surface energy budget
term: cloud insulation keeps the surface 30 to 46 K warmer than the
clear-sky equilibrium.

### Peak cloud lifetime: 383 of 480 hours

At (tau_dep=10^7, tau_ce=10^2): 383 cloud hours, max_clw=0.36 g/kg,
ts_end=257.6 K, rlds_mean=247.7 W/m^2. This is the most cloud-sustaining
point on the coarse grid.

## Figures

See `experiments/taudep sweep coupled 2d/figures/`:
- fig1_2d_regime_map: cloud metrics as 4-panel heatmap
- fig2_2d_transition: cloud hours heatmap with contours + 1D slices (with subexp A overlay)
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
