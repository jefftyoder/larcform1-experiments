# tau_dep transition sweep, coupled surface (lf1e-taudep-1, subexperiment B)
## author: Jeffrey Yoder
## date: August 06, 2026

# Goal

Repeat the tau_dep sensitivity sweep of subexperiment A
(`experiments/taudep sweep/lf1e-taudep-sweep-1.md`) with two key changes:

1. **UKI-calibrated microphysics baseline** from the clw calibration experiment
   (`experiments/clw calibration/lf1e-clw-calibration-1.md`), using 6 parameters
   fitted to the EC-Earth day-2 clw/cli reference via unscented Kalman inversion.
2. **ClimaSeaIce+snow coupled surface** from the sea-ice experiment
   (`experiments/sea-ice/`, Phase 2), replacing the standalone SlabOceanSST.

The scientific question: how does the cloud liquid transition shift when (a) the
microphysics is calibrated to reproduce EC-Earth's cloud lifecycle and (b) the
surface temperature evolves interactively (cooling from 250 K toward ~214.5 K
over 20 days with snow insulation)?

Subexperiment A showed a continuous, multi-decade transition centered at
tau_dep ~ 4.4e4 s under stock microphysics with a pinned 250 K slab surface.
The calibrated microphysics and interactive surface may shift the transition
location, width, or character.

# Protocol

## Setup

Coupled ClimaAtmos + ClimaCoupler + ClimaSeaIce path. Base atmosphere
configuration: `ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml`
with the same fast grid validated by subexperiment A's pilot (z_max 5000 m,
z_elem 60, z_stretch true, dz_bottom 10 m, dt 30 s, dt_rad 30 min).

Surface model: `ClimaSeaIceColumnSimulation` (registered as
`ice_model: "clima_seaice_column"`), providing:
- Prognostic surface temperature (initialized at 250 K)
- 1 m ice, 0.1 m water-equivalent snow
- MeltingConstrainedFluxBalance top boundary
- Resistors-in-series conduction (snow + ice)
- Ocean at freezing point of sea water (271.35 K), zero ocean heat flux

Coupler configuration: `domain_type: "column"`, `dt_cpl: "30secs"`,
`scm_surface_type: "sea_ice"`, `mode_name: "amip"`.

Ice formation: `cloud_ice_formation: "TemperatureDependent"` (required for
Frostenberg a/b INP parameters to be active).

Run length: 20 days (the coupled surface evolves, so the full Pithan arc matters).

Environment: `julia +1.12 -t 1 --startup-file=no --project` (root env). The
vendored CloudMicrophysics.jl with the Frostenberg a/b INP patch is dev'd only
in the root env; the buildkite env has registered CloudMicrophysics where those
knobs are dead. The sea-ice experiment validated this env for coupled runs.

## Calibrated microphysics baseline

All 6 UKI-calibrated parameters from `experiments/clw calibration/configs/toml/calibrated_uki1_final.toml`:

| Parameter | Calibrated value | Stock default |
|---|---|---|
| sublimation_deposition_timescale | 66.59 s | 100 s |
| condensation_evaporation_timescale | 101.07 s | 100 s |
| cloud_liquid_water_specific_humidity_autoconversion_threshold | 3.77e-4 | 5e-4 |
| snow_autoconversion_timescale | 831.87 s | 1000 s |
| Frostenberg2023_a_coefficient | 0.254 | (dead in stock) |
| Frostenberg2023_b_coefficient | 1.194 | (dead in stock) |

The sweep varies sublimation_deposition_timescale while holding the other 5 at
their calibrated values. Parameters are delivered via `coupler_toml:` (not atmos
`toml:`) to avoid the ClimaCoupler v0.2.2 clobber bug.

## Sweep stages

Control parameter: x = log10(tau_dep), domain [1, 9]. Same order parameters as
subexperiment A (max_clw, cloud_hours, onset/collapse, lwp_int, clivi_end,
ts_end, clear_hour). ts_end is now physically meaningful (interactive surface
cooling vs pinned 250 K in A).

0. **Stage 0, anchors (2 members):** tau = 66.59 (calibrated default; expect
   liquid production under TemperatureDependent ice formation) and tau = 1e9
   (expect sustained liquid, negligible ice). Validates the coupled pipeline.
1. **Stage A, coarse scan (~17 members):** 2 points per decade, tau = 10^{1.0,
   1.5, ..., 9.0}.
2. **Stage B, adaptive refinement (budget 15):** same deterministic greedy
   bisection as subexperiment A, but with a smaller budget (coupled members
   cost ~6 min each vs ~36 s standalone).
3. **Stage C, critical-window characterization (~10 members, optional):** uniform
   dense sampling across the sharpest transition.

Budget: ~34 members maximum (2 anchors + 17 coarse + 15 adaptive), roughly
3.5 hours on Stratus at 4 workers.

## Execution

Same Stratus tmux pattern as subexperiment A:
1. `bash scripts/sync_to_remote.sh`
2. `ssh stratus "bash 'experiments/taudep sweep coupled/launch_sweep.sh'"`
3. Monitor: `ssh stratus 'tmux capture-pane -pt lf1sweepc -S -50'`
4. `bash scripts/sync_from_remote.sh` pulls `output/lf1e-taudep-1-coupled/`

# Findings

## First run (2026-08-06, 31 members): invalidated by flux_scheme priority bug

The first sweep ran with ClimaAtmos loaded from the Julia registry (v0.42.0)
rather than the dev'd submodule. This triggered a priority bug in
`model_getters.jl:844-846`: the registered code checks
`setup_pieces.flux_scheme` before checking `surface_setup == "PrescribedSurface"`.
Since Larcform1's `surface_condition` returns `MoninObukhov(; z0 = 1e-3)` (not
nothing), the `PrescribedSurface` branch is never reached, so `flux_scheme`
remains non-null. With a non-null `flux_scheme`, `update_surface_conditions!` runs
every ODE step, calling `surface_temperature(AnalyticTemperature(Returns(250)))`
which resets `sfc_conditions.T_sfc` to 250 K, overwriting the coupler's
interactive sea-ice temperature.

The dev'd submodule (`ClimaAtmos.jl/src/config/model_getters.jl:847-848`) has the
correct priority: `PrescribedSurface` is checked first, so `flux_scheme` is set
to `nothing`, and `update_surface_conditions!` bails immediately. The coupler then
owns T_sfc entirely via `update_field!`. Jeff's upstream fix branch is
`copilot/fix-surface-temperature-overwrite`.

**Symptom.** All 31 members showed ts = 250.0 K for all 480 hours (no variation).

**Fix applied 2026-08-07.** `Pkg.develop(path="ClimaAtmos.jl")` on Stratus to
load the submodule instead of the registry. Verified with a 3-hour test:
ts = [258.4, 256.0, 253.7] K (evolving correctly from the sea-ice surface).

**Note on the prior session's diagnosis.** An earlier session (commit 1cb0974)
incorrectly attributed this to `AnalyticTemperature` overwriting the coupler's
T_sfc directly. The actual mechanism is that the registered package's
`flux_scheme` priority prevents `PrescribedSurface` from disabling
`update_surface_conditions!`. The `AnalyticTemperature` is only a problem because
the guard (`isnothing(flux_scheme)`) that should protect the coupler's T_sfc never
fires when the wrong code path is taken.

**Implication for the sea-ice experiment.** The sea-ice experiment ran with a
pre-v0.42.0 ClimaAtmos where this bug did not exist (confirmed by ts output
showing cooling from ~258.5 K to ~215 K). Those results are valid.

## Second run (2026-08-07): pending

Sweep re-run with the dev'd submodule. Old manifest cleared; fresh 34-member
sweep to launch.

# TODO

- ~~Fix the coupling bug and re-run.~~ Fixed 2026-08-07: root cause was
  registered ClimaAtmos v0.42.0 flux_scheme priority bug; fix is
  `Pkg.develop(path="ClimaAtmos.jl")` on Stratus. Sweep re-run launched.
- Comparative analysis: overlay subexperiment A and B transition curves to
  quantify the shift in transition location and width.
- **Plot LWP and IWP jointly over the tau_dep sweep.** Map tau_dep to (LWP, IWP)
  and characterize the geometry: is the image a 2D surface (independent LWP/IWP
  responses), a 1D curve embedded in 3D (a single degree of freedom trades liquid
  for ice), or something else (e.g. bifurcation, hysteresis loop)? This tells us
  whether the transition is a simple liquid-to-ice partitioning or involves
  distinct cloud regimes. Plot as a 3D trajectory (tau_dep, LWP, IWP) and as
  a 2D LWP-vs-IWP scatter colored by log10(tau_dep). Do for both subexperiments
  A and B once valid coupled data exists.
- Sweep other calibrated parameters (condensation_evaporation_timescale,
  Frostenberg a/b) while holding tau_dep at calibrated value.
- IC-perturbation ensembles near the critical tau window.
