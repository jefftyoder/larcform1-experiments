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

# Findings (2026-08-06, sweep complete: 31 members)

## Coupling bug: atmosphere ignores the interactive surface temperature

**Root cause.** The Larcform1 setup (`ClimaAtmos.jl/src/setups/Larcform1.jl:94`)
returns `AnalyticTemperature(Returns(FT(250)))` as the surface temperature model.
When `prognostic_surface == "PrescribedSST"`, this is used by
`model_getters.jl:837`: `@something(setup_pieces.temperature, ...)`. During each
atmosphere timestep, `update_surface_conditions!` calls
`surface_temperature(AnalyticTemperature(Returns(250)), ...)` which resets
`sfc_conditions.T_sfc` to 250 K, overwriting whatever the coupler wrote via
`update_field!(atmos_sim, Val(:surface_temperature), csf.T_sfc)`.

The coupler never sets the atmosphere's `surface.temperature` type to
`CoupledTemperature` (the type that reads from the coupler's field). The coupler
extension (`ClimaCouplerClimaAtmosExt.jl`) only defines `update_field!` for
`:surface_temperature`, which writes to `sfc_conditions.T_sfc`, but this is
clobbered by `update_surface_conditions!` on the next atmos step.

**Evidence.** Every member (19 sweep + 2 anchors + 10 adaptive = 31 total) shows:
- `ts` = 250.0 K for all 480 hours (no variation whatsoever)
- `rlus` = 221.49 W/m² throughout (= sigma times 250^4, confirming the atmosphere
  radiates from a 250 K surface)
- `hfss` grows from -9.5 to +340 W/m² (consistent with the air cooling below
  250 K while the surface stays pinned, driving increasing upward sensible heat)
- Coupler `F_turb_energy` varies from -11.2 to +11.1 W/m² (fluxes ARE computed)
- Sea ice concentration `siconca` = 100% throughout (component is present)
- Sea ice output directory is empty (no diagnostics written, but this is
  expected: no sea-ice diagnostics are configured in the YAML)

**Implication for the sea-ice experiment.** The sea-ice experiment
(`experiments/sea-ice/run_20day_suite.jl`) uses the identical config keys
(`surface_setup: "PrescribedSurface"`, `prognostic_surface: "PrescribedSST"`) and
the same Larcform1 initial condition. It likely suffers from the same bug: the
sea-ice model evolves internally (its T_sfc cools to ~214.5 K as reported from
the model's in-memory `history`), but the atmosphere always sees 250 K. The sea-ice
experiment's published T_sfc evolution came from `_column_state(sim).T_sfc` (the
model's internal thermodynamics), not from the atmosphere's `ts` diagnostic. This
means the atmosphere's radiation, turbulent fluxes, and cloud microphysics were
NOT responding to the surface cooling in any prior coupled run.

**Fix.** The atmosphere must use `CoupledTemperature` in coupled mode so that
`update_surface_conditions!` reads from the coupler's field instead of returning
a prescribed value. Options:
1. Override `Setups.surface_temperature_model(::Larcform1)` to return nothing
   when running coupled (requires detecting coupled mode in the setup, which is
   architecturally awkward).
2. Have the coupler set `atmos.surface.temperature` to `CoupledTemperature(field)`
   after constructing the `AtmosModel` (cleanest; upstream fix in ClimaCoupler).
3. Add a config key (e.g. `coupled_surface_temperature: true`) that makes
   `model_getters.jl` choose `CoupledTemperature` instead of the setup's
   `AnalyticTemperature`.

## Sweep results (atmosphere at fixed 250 K)

Because the atmosphere sees a fixed 250 K surface (identical to subexperiment A's
slab ocean), the sweep results reflect the interaction between
TemperatureDependent ice formation and the calibrated microphysics, not the
interactive surface. Key finding:

**The cloud response is completely flat across 8 decades of tau_dep.**
Every member produces cloud_hours = 54 +/- 1, max_clw ~ 3.65e-4, clivi_end ~
4.95e-3, collapse_hour ~ 54. There is no transition: under TemperatureDependent
ice formation with calibrated Frostenberg parameters (a = 0.254, b = 1.194), the
sublimation_deposition_timescale has no effect on the cloud lifecycle.

This contrasts sharply with subexperiment A (ConstantTimescale), where a
multi-decade transition centered at tau ~ 4.4e4 s separated the no-liquid regime
from sustained liquid. The TemperatureDependent scheme produces liquid at all
tau_dep values; the INP pathway (Frostenberg) controls glaciation independently
of the WBF vapor deposition timescale.

The cloud collapses at hour 54 in all members. This is about 2.25 days, earlier
than subexperiment A's 5-day window captured. The collapse is likely driven by
boundary layer dynamics (radiative cooling of the air, not surface cooling which
is pinned at 250 K), combined with the Frostenberg INP glaciation.

Adaptive refinement (Stage B) spent 10 members chasing 54/55 cloud_hours noise
before the budget was exhausted. No real transition was found.

# TODO

- **Fix the AnalyticTemperature coupling bug and re-run.** The entire point of
  subexperiment B is the interactive surface; all 31 members ran with a pinned
  surface. See the fix options above.
  Likely approach: override `Setups.surface_temperature_model(::Larcform1)` in the
  sweep_tools.jl after loading ClimaAtmos (monkey-patch), or add a post-construction
  hook in the coupler extension.
- Comparative analysis: overlay subexperiment A and B transition curves to
  quantify the shift in transition location and width.
- Sweep other calibrated parameters (condensation_evaporation_timescale,
  Frostenberg a/b) while holding tau_dep at calibrated value.
- IC-perturbation ensembles near the critical tau window.
