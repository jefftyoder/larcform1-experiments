# Sea-ice surface for the Larcform1 SCM — plan & status

*Started 2026-07-09. Coupling the Larcform1 SCM (ClimaAtmos) to a sea-ice surface,
with and without snow, via ClimaCoupler.*

## Status

| Phase | Deliverable | State |
|---|---|---|
| 0 | Coupled SCM over upstream prescribed slab ice | ✅ **complete** (2026-07-09) |
| 1 | `larcform1_ice`: Pithan-correct slab ice component | ✅ **complete** (2026-07-09) |
| 2 | `clima_seaice_column`: ClimaSeaIce ice + snow component | ✅ **complete** (2026-07-09) |
| — | 20-day suite, calibrated + uncalibrated | ✅ **complete** (2026-07-10) |
| — | Analysis in the paper's framework | ✅ → `experiments/pithan-reproduction/` |
| 3 | (optional) Eisenman port | not started |

**Depends on a local-only ClimaAtmos fix:** every coupled run here needs the
`PrescribedSurface`-wins-over-setup-flux-scheme fix in
`ClimaAtmos.jl/src/config/model_getters.jl` (Phase 0 finding 1) — without it
atmos and the coupler both compute surface fluxes and nothing errors. It is
committed as `e4651309d` on the submodule's `jy/coldslab` branch and pinned by
the parent repo, but **that branch has not been pushed**, so these results are
not reproducible from a fresh clone until it is. Owed: push `jy/coldslab`, then
upstream the `model_getters.jl` hunk to CliMA/ClimaAtmos.jl.

### Known open items

- Three upstream ClimaCoupler bugs found and worked around here, **none yet
  reported**: column-mode SIC callback (belongs on
  [#1860](https://github.com/CliMA/ClimaCoupler.jl/issues/1860)), the
  `coupler_toml` clobber (below), and `postprocess` failing on column output.
- Clear-state radiative cooling is too strong on every bare surface (10-day loss
  37–40 MJ m⁻² vs the published worst case 27.3) — the main open science
  question; see `experiments/pithan-reproduction/README.md`.

### Phase 0 outcome

Clean 2-day coupled run at 80°N: ClimaAtmos (Larcform1 IC, prognostic EDMF, 1M
microphysics, allsky radiation, dt = 30 s, Float32) + `PrescribedIceSimulation`
(dt_cpl = 30 s), via registered ClimaCoupler v0.2.2 with no fork.

- **Result:** T_sfc 261.5 → 257.2 K, smooth polar-night cooling; rlus ≈ σT⁴
  self-consistent; hfss ≈ −1 W m⁻² (stable BL); rlds 190–212 W m⁻².
- **Trusted output:** `output/lf1_prescribed_ice/lf1_prescribed_ice/output_0003/`.
  `output_0000–0002` are scratch/corrupted (two concurrent sessions shared a job_id;
  see Working practices).
- **Performance:** full 2-day run in 61 s wall, warm and single-threaded (~7 ms per
  coupled step). A 20-day Pithan run is ~5 min warm, ~20 min from a cold script
  launch. SCM runs do not need Stratus unless sweeping many configs in parallel.
  Note: the coupler's wall-time ETA / `estimated_sypd` average over all wall-clock
  since construction — meaningless in interactive sessions; trust `instantaneous_sypd`.
- **Run it:** `julia --project experiments/sea-ice/run_prescribed_ice.jl` (add
  `--dry-run` for setup + config validation only). The driver merges the standalone
  atmos YAML with `configs/lf1_prescribed_ice_overlay.yml` (overlay wins) and errors
  on any key unrecognized by coupler + atmos defaults.

### Phase 0 findings (bugs found & fixed)

1. **Atmos flux-ownership bug (fixed in dev ClimaAtmos):** `AtmosSurface` let the
   Larcform1 setup's `MoninObukhov` flux scheme override
   `surface_setup: PrescribedSurface`, so atmos and the coupler would both compute
   surface fluxes with no error. Fixed in `ClimaAtmos.jl/src/config/model_getters.jl`
   (PrescribedSurface now wins over setup pieces).
2. **Upstream SCM sea-ice bug (workaround in driver; report against
   [#1860](https://github.com/CliMA/ClimaCoupler.jl/issues/1860)):** the
   prescribed-ice daily SIC callback `read_sic_data!` has no column-mode guard and
   overwrites `area_fraction = 1` with HadISST data — ~0.44 at (80°N, 0°E) in January
   (real Greenland Sea ice edge) — crashing the coupler's area-fraction assertion at
   the first day boundary. Ice physics is unaffected (`ice_rhs!` has its own column
   guard). Worked around via a method override in `run_prescribed_ice.jl`; Phase 1
   removes the need entirely.
3. `prognostic_surface: "false"` (seen in old `coupled_configs/`) is invalid in the
   dev'd ClimaAtmos; coupled runs need `"PrescribedSST"` (initial T_sfc then comes
   from the Larcform1 setup = 250 K, and the coupler overwrites it each step).

### Phase 0 accepted compromises (fixed by Phase 1)

`PrescribedIceSimulation` hardcodes h = 2 m (Pithan: 1 m), z0m = z0b = 1e-4 m
(Pithan modal: 1e-3 m), T_base = 271.2 K, and inits T_bulk = T_freeze − 5 K
(→ T_sfc ≈ 261 K, not Pithan's 250 K). None are config-reachable upstream.

### Phase 1 outcome

Custom component `components/larcform1_ice.jl` (`Larcform1IceSimulation`), a
SIC-free adaptation of upstream `prescr_seaice.jl`, registered via
`Interfacer.SeaIceSimulation(FT, Val(:larcform1_ice))` — no ClimaCoupler fork,
no `read_sic_data!` workaround needed. Clean 2-day coupled smoke run
(dt = dt_cpl = 30 s, 50 s wall, 9.4 SYPD).

- **Pithan-correct init verified at runtime:** h = 1 m, z0m = z0b = 1e-3 m,
  T_base = T_freeze = 271.35 K, T_bulk₀ = 260.675 K → T_sfc₀ = 250.0 K,
  F_conductive₀ = 42.7 W m⁻².
- **Result:** T_sfc 250.0 → 251.6 K — the surface *warms* toward the
  conductive–radiative equilibrium σT⁴ ≈ LW_d + F_cond (≈ 251 K for
  LW_d ≈ 186, F_cond ≈ 40 W m⁻²); the 1 m ice conducts ~2× the heat of
  Phase 0's 2 m slab. Self-consistency: rlus(end) = 227.2 = σT_sfc⁴ ✓,
  F_cond(end) = 39.5 = k(T_base − T_sfc)/h ✓. hfss −3.8 → −1.0 W m⁻²
  (stable BL), LWP ≡ 0 / IWP → 3.8 g m⁻² (expected with base toml; see
  Deferred TODOs).
- **Trusted output:** `output/lf1_larcform1_ice/lf1_larcform1_ice/output_0000/`.
- **Run it:** `julia --project experiments/sea-ice/run_larcform1_ice.jl`
  (`--dry-run` for setup + config validation only). Same merge/hygiene driver
  pattern as Phase 0.
- **Parameter sweeps:** every ice parameter is TOML-overridable via
  `coupler_toml` entries named `larcform1_ice_*` (see `Larcform1IceParameters`
  docstring), e.g. `larcform1_ice_thickness`.
- **F_conductive:** `conductive_flux(ice_sim)` gives the current field; the
  full series is recoverable offline from `ts` output since k, h, T_base are
  constants.
- **Plotting (resolved 2026-07-09):** the root env now carries the
  ClimaCouplerMakieExt trigger packages (CairoMakie, ClimaCoreMakie, GeoMakie,
  Poppler_jll; key pins unchanged). Upstream `postprocess` still fails on
  column output — surface diagnostics are `(time,)`-only and it slices them at
  `LAST_SNAP` to 0 dims, and `make_plots_generic` drops its last page when
  skipped-constant vars follow a plotted one — so both drivers instead call
  `make_column_diagnostics_plots` from `postprocess_plots.jl` (profiles at
  final time + surface time series → `artifacts/*.pdf`). TODO: report both
  bugs upstream alongside the #1860 column-mode SIC bug. Benign
  `update_field!` warnings for `liquid_precipitation`/`snow_precipitation`
  (slab ice ignores precip, same as upstream prescribed ice).

### Phase 2 outcome

Custom component `components/clima_seaice_column.jl` (`ClimaSeaIceColumnSimulation`),
registered via `Interfacer.SeaIceSimulation(FT, Val(:clima_seaice_column))`: a
thermodynamics-only `ClimaSeaIce.SeaIceModel` (slab ice + optional slab snow,
prognostic thickness/concentration, snow-ice flooding) on a single-point
Oceananigans grid — no ClimaOcean, no ocean model (Pithan: prescribed bottom at
271.35 K via `PrescribedTemperature`, ocean heat flux 0). Clean 2-day coupled
smoke run (dt = dt_cpl = 30 s, 9.7 SYPD / 8.5 ms per coupled step).

- **Coupling design:** top BC `MeltingConstrainedFluxBalance` + a
  T-dependent `FluxFunction` Q_top(T) = ϵσT⁴ − (1−α)SW↓ − ϵLW↓ + F_turb whose
  radiative/turbulent values the coupler refreshes each step (`update_field!` /
  `update_turbulent_fluxes!`, evaluated at the previous step's T_sfc — explicit
  lagged coupling). ClimaSeaIce's secant solve then gives T_sfc with the
  snow+ice resistors-in-series conductance; snowfall accumulates from `P_snow`
  (sign flip). The ice model runs internally in **Float64** regardless of the
  exchange FT (Float32 thickness increments broke conservation at ~1%).
- **Conservation validated at machine precision** (relative 1e-10 over 2
  days, `conservation_report`): ΔE_latent = −∫(Q_top−Q_ocean)dt − ∫ℒ·snowfall·ℵ dt,
  in the constant-latent-heat configuration
  (`seaice_column_liquid_heat_capacity = cᵢρᵢ_pt/ρℓ`). The default config keeps
  ClimaSeaIce's T-dependent latent heat (Stefan correction) and carries a
  documented ~1.3% accounting residual against the ρℒ₀V functional.
- **Standalone cross-checks:** no-snow branch reproduces Phase 1's bare-ice
  equilibrium (251.49 K vs 251.6 K); snow branch equilibrates ~6 K colder
  (snow triples the conductive resistance).
- **Coupled result (with snow):** T_sfc 250 → 242.5 K (insulated surface +
  rlds feedback: 212 → 180 W m⁻², lower than Phase 1's 187), h_ice 1 → 1.0096 m
  (bottom growth), h_snow 0.3030 → 0.3055 m (= snowfall exactly; no flooding).
  rlus(end) ≈ σT⁴ ✓, prsn ↔ Δh_snow ✓, IWP → 4.5 g m⁻², LWP ≡ 0 (base toml).
- **Flotation is near-critical:** Pithan's 1 m ice + 0.1 m w.e. snow has only
  +2.4 cm freeboard with sea-water density (`seaice_column_water_density = 1025`;
  the ClimaSeaIce fresh-water default sits at *exactly* zero freeboard). At
  ~2.6 mm/day snowfall, snow-ice flooding will genuinely activate ~1 week into
  a 20-day run — physical, but remember it when reading h_ice/h_snow series.
- **Trusted output:** `output/lf1_clima_seaice_column/lf1_clima_seaice_column/output_0000/`
  (+ `artifacts/*.pdf`, `seaice_column_history.csv` — per-step ice state, since
  the coupler NetCDF diagnostics don't cover custom ice fields).
- **Run it:** `julia --project experiments/sea-ice/run_clima_seaice_column.jl`
  (`--dry-run` for setup + config validation). Snow off:
  `ice_model: "clima_seaice_column_nosnow"` (a registered variant — the
  `coupler_toml` route is unusable under ClimaCoupler v0.2.2: `coupler_toml`
  *replaces* the atmos `toml` list and its entries trip the atmos strict
  unused-parameter check before any surface component reads them; TODO report
  upstream with #1860). Physics parameters are `seaice_column_*` TOML entries
  (thicknesses, conductivities, densities, heat capacities, albedo/emissivity,
  roughness, base temperature, ocean heat flux) — but note the same
  `coupler_toml` limitation applies to sweeping them in coupled runs.
- **Limitations:** no Checkpointer methods (set `checkpoint_dt` > `t_end`);
  sublimation mass loss and rain-on-snow ignored (matches upstream CMIP
  component); ice state time series lives in `sim.history` (memory) → CSV.
- **REPL caveat:** driving `run!(cs)` through Kaimon hits the gate's 10-min
  no-output timeout during first-step compilation; the async task survives and
  completes, but the result is lost — check `cs.model_sims.ice_sim.history`
  afterwards, or use the driver script in a separate process.

## 20-day production suite vs Pithan ensemble (2026-07-09, uncalibrated)

> **CORRECTION (2026-07-10): the runs described in this section were NOT
> calibrated — and this section's numbers are the uncalibrated ones.** The
> calibrated TOMLs were passed via the atmos `toml:` key, which ClimaCoupler
> v0.2.2 silently reverts to ClimaParams defaults (see "coupler_toml clobber
> bug" below). The saved parameter logs confirm defaults (Frostenberg a = 1,
> snow autoconversion τ = 100 s). The runs did have
> `cloud_ice_formation: "TemperatureDependent"` (a YAML key, unaffected), so
> they are "default parameters + v10 ice-nucleation physics".
>
> **RESOLVED (2026-07-10): overlays fixed to `coupler_toml:` and the suite was
> rerun.** Calibrated outputs are `analysis/converted/*_cal.nc` (bare names =
> these uncalibrated runs; both sets are kept deliberately, and the cal/uncal
> contrast is itself a result — see `experiments/pithan-reproduction/`).
> Calibration landing was verified by grepping the saved parameter log.
> `analysis/figures/metrics_table.txt` (below) is still the **uncalibrated**
> suite vs the ensemble; `calibration_comparison_metrics.txt` is cal vs uncal.

**What calibration changed** (`calibration_comparison_metrics.txt`): the
correction's prediction held — surface energy balance is robust, clouds are not.
ts_end moves < 1 K (slab ice 237.1 → 237.7, bare 232.0 → 232.8, snow
214.5 → 215.1), so the ts ordering and the snow-insulation conclusion survive
unchanged. But glaciation happens ~0.8–1.0 day *earlier* (slab ice day 3.08 →
2.29, bare 3.46 → 2.50, snow 3.25 → 2.46) and day-2 clwvi roughly halves
(0.20 → 0.077 slab ice), moving our liquid load from the top of the published
spread toward its middle. Read every cloud/glaciation number below as the
uncalibrated variant.

Three 20-day coupled runs (reference s11 atmosphere
numerics — differences attributable to the surface model) ran on Stratus via
`run_20day_suite.jl` (tmux `lf1run`, julia 1.12 `--startup-file=no`, ~6 min/run
at 10–15 SYPD). Outputs pulled to `output/lf1_*_20d/`, converted via
`scripts/convert_to_pithan.py` into `analysis/converted/`, compared by
`analysis/compare_20day_surfaces.py` (figures + metrics table in
`analysis/figures/`) against the calibrated slab-ocean reference
(`experiments/20day run/`) and the 15-member Pithan ensemble.

Headline (metrics_table.txt): the coupled runs bring ts inside the ensemble
envelope — ts_end slab ice 237.1 K, bare ClimaSeaIce 232.0 K, ClimaSeaIce+snow
214.5 K (ensemble 206.8–239.5; slab-ocean reference pinned at 249.2). All
three show the two-state cycle: cloudy state (~260 K) days 0–3, glaciation at
h74–83 (EC-Earth 53, calibrated slab ocean 55 — the colder interactive surface
holds liquid ~1 day longer), then radiatively-clear cooling at a rate set by
the surface (snow insulates → coldest). Day-2 clwvi 0.18–0.20 (high vs
EC-Earth 0.042 but inside the ensemble; ECHAM6.2 = 0.259); clivi days-5+
~0.0045 (low vs EC-Earth 0.0154, inside ensemble). Sea-ice conservation
residuals ~1.4% (documented Stefan-correction accounting). Unlike the pinned
slab ocean (which regenerates cloud late-record), the cold coupled surfaces
stay cloud-free after glaciation.

## Working practices

- **One simulation at a time on this machine, unless deliberately planned.** Two
  lessons from Phase 0: (a) simulations with the same `job_id` share
  `output/<job_id>/` and the `RemovePreexisting`/versioned-dir logic lets one
  construction delete another live run's output; (b) concurrent runs contend for
  memory bandwidth (~2× slowdown observed). Before constructing/running: check
  `ps aux | grep julia` for live sims, and if parallel runs are truly wanted, give
  each a unique `job_id` and plan core/memory budgets.
- **Config hygiene** (coupler configs have silently ignored keys before):
  1. The driver's built-in check errors on keys unknown to both
     `Input.parse_commandline(Input.argparse_settings())` and
     `Input.atmos_default_config_dict()` — keep it in any new driver.
  2. `validate_model_types_for_mode` warn-and-*replaces* model choices in global
     mode and nulls non-selected surfaces in column mode — read the
     `Component models initialized: ...` log line on every run.
  3. Keep atmos physics keys in the standalone ClimaAtmos config (single source of
     truth) and put only coupler wiring + necessary overrides in the overlay YAML.
- **Interactive REPL caveats:** long evals via Kaimon are promoted to background
  jobs (results visible only on completion); the user's terminal sees Progress live.

## Plan (remaining phases)

### Phase 3 (optional) — Eisenman port

Only if we want prognostic ice thickness without the Oceananigans dependency chain.
Port `reference/eisenman_seaice.jl` (412 lines, self-contained) to the current
Interfacer API using `prescr_seaice.jl` as the template. No snow, so it doesn't serve
the snow experiments.

## Calibrated microphysics in coupled runs (wired 2026-07-09, fixed 2026-07-10)

### coupler_toml clobber bug (found 2026-07-10)

The original wiring below via the atmos `toml:` key **never delivered the
calibrated values**: `SimCoordinator.jl:257` builds `coupled_param_dict` from
`coupler_toml` alone (= full ClimaParams defaults when empty) and
`ClimaCouplerClimaAtmosExt.jl:668` passes it as the *override* side of
`merge_override_default_values`, reverting every atmos-toml value to default —
and discarding atmos's override tracking, so the strict unused-parameter check
never flags it. This contradicts the documented fallback ("only if there is no
coupler TOML will the atmosphere-specific TOML be used") — third
`coupler_toml`-related item for the upstream bug report. **Fix:** all four
overlays now use `coupler_toml:` (paths resolve cwd-first, then
`pkgdir(ClimaCoupler)`); verified 2026-07-10 by dry-run construction — all six
uki_1 values appear in the saved `*_parameters.toml` (Frostenberg a = 0.2537,
b = 1.1944, τ_snow_auto = 831.87 s, τ_subdep = 66.59 s, τ_condevap = 101.07 s,
q_liq threshold = 3.772e-4). Verification rule: always grep the run's saved
parameter log. The 20-day suite was rerun with the fix on 2026-07-10
(`analysis/converted/*_cal.nc`); see "What calibration changed" above.

The Phase 2 overlay now runs the calibrated v10 physics:

- Root env has the **vendored patched CloudMicrophysics.jl dev'd**
  (`Pkg.develop(path="CloudMicrophysics.jl")`; Frostenberg a/b wired into
  `INP_concentration_mean` — verified live: INPC(−15 °C) = 38.44, ÷10 at a = 10,
  ×1.2⁹ at b = 1.2, matching lf1e-clw-calibration-1.md).
- The uki_1 final means were promoted from gitignored output to
  `experiments/clw calibration/configs/toml/calibrated_uki1_final.toml`.
- `lf1_clima_seaice_column_overlay.yml` adds
  `cloud_ice_formation: "TemperatureDependent"` and points `coupler_toml:`
  (originally the atmos `toml:` key — see the clobber bug above) at
  `larcform1_calibration_base.toml` + `calibrated_uki1_final.toml`
  (base-minus-timescales + calibrated values; duplicate-entry workaround).
  Paths resolve from the repo root (`isfile` on cwd first).
- Phase 0/1 overlays intentionally stay on stock physics (machinery archives);
  `output_0000` of lf1_clima_seaice_column is the last stock-physics run —
  calibrated runs start at `output_0001`.
- Expectation for calibrated coupled runs: mixed-phase cloud (LWP > 0),
  glaciation around hour ~54 per the 5-day standalone verification —
  though the interactive (colder) sea-ice surface may shift both.

## Viability findings (2026-07-09 investigation, kept for reference)

1. **ClimaCoupler SCM support is native since PR
   [#1803](https://github.com/CliMA/ClimaCoupler.jl/pull/1803)** (2026-04-03):
   `domain_type: "column"`, `column_latlon`, `scm_surface_type`; exchange grid is a
   `PointSpace`, DSS no-op'd; CI config `scm_amip_ice.yml` runs SCM over sea ice.
   Column mode forces ice fraction = 1 at init. v0.2.2 (registered) pins
   `ClimaAtmos = "0.41"` (matches our dev version) and `ClimaSeaIce = "0.5"`.
2. **ClimaSeaIce-in-the-coupler** (`ext/ClimaCouplerCMIPExt/clima_seaice.jl`) has full
   snow support but takes its grid from a live `OceananigansSimulation` with
   spectral↔Oceananigans remapping and ECCO ICs. SCM support is open issue #1860 —
   deferred from #1803, unassigned, unstarted as of July 2026.
3. **Eisenman model** was deleted in PR
   [#1284](https://github.com/CliMA/ClimaCoupler.jl/pull/1284) (2025-04-22):
   prognostic thickness + mixed-layer temperature, melt/freeze transitions, no snow,
   gray-radiation assumption. Retrieved to `reference/`.
4. **NumericalEarth `coupled_conservation.jl`** demonstrates the target physics
   (ClimaSeaIce thermo-only single column, 1 m ice + 0.1 m snow, machine-precision
   conservation) but with a *prescribed* atmosphere; it's the architectural blueprint
   for Phase 2, not a dependency.
5. **Old repo state:** the pre-#1803 ClimaCoupler submodule (branch `jy/slabocean`) is
   gone and the branch no longer exists on the CliMA remote; `coupled_configs/*.yml`
   and the CLAUDE.md coupler sections predate upstream SCM support — do not trust
   them (JY confirmed keys were silently ignored historically).

## Reference files (`reference/`, from CliMA/ClimaCoupler.jl, Apache 2.0)

| file | provenance | role |
|---|---|---|
| `scm_amip_ice.yml` | main @ 2026-07 | known-good SCM sea-ice config keys |
| `prescr_seaice.jl` | main @ 2026-07 | template for Phase 1 component |
| `clima_seaice.jl` | main @ 2026-07 (CMIP ext) | coupler-facing methods to crib for Phase 2 |
| `eisenman_seaice.jl` | parent of PR #1284 merge | Phase 3 source |
