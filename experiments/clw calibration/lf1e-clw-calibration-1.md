# lf1e clw calibration #1 — UKI parameter tuning toward EC-Earth clw/cli

## Purpose

The clw sensitivity experiment established that v10 physics
(`cloud_ice_formation: "TemperatureDependent"`) reproduces the Pithan 2016
Arctic mixed-phase cloud, and the SCM speed tests produced a validated
lightweight forward model (s11: 5 km top, 100 stretched levels, dt_rad 30 min,
42 s solve, converged science). The remaining EC-Earth gaps are amount-type,
not timing-type:

| metric (day-2-flavored) | s11 | EC-Earth | gap |
|---|---|---|---|
| clwvi mean (48 h) | 0.130 | 0.038 | ~3.5× high |
| max clw | 4.2e-4 | 6.8e-4 | ~40% low |
| clivi end | 3.4e-3 | 2.3e-2 | ~7× low |

This experiment tunes 4 microphysics parameters against EC-Earth day-2 clw/cli
profiles with unscented Kalman inversion (UKI), using
ClimaCalibrate + EnsembleKalmanProcesses locally (JuliaBackend, sequential).

## Parameter selection (and the INP-curve patch)

**Stock `Frostenberg2023_a_coefficient` / `b_coefficient` are dead knobs.**
ClimaParams defines them and the `CMP.Frostenberg2023` struct stores them, but
CloudMicrophysics (registered v0.36 AND upstream main, checked 2026-07-05)
never reads them: `INP_concentration_mean` hardcodes
`μ(T) = 9·log(−T_celsius/10)` (IceNucleation.jl:237, destructures only
`T_freeze`). In the paper (Frostenberg et al. 2023, Eq. 1) a [m³] and
b [°C⁻¹] are the normalization constants `ln(a·INPC) = μ(T)`,
`μ(T) = ln((−b·T/10)⁹)` — both 1 by definition, i.e. natural calibration
multipliers that were transcribed into ClimaParams but never wired up.

**Resolved by a vendored patch**: `CloudMicrophysics.jl/` at repo root is a
copy of the registered v0.36 tree with one change — `INP_concentration_mean`
returns `9·log(−b·T_c/10) − log(a)` (reduces to the stock curve at a = b = 1).
The calibration Project.toml `[sources]` points CloudMicrophysics at it, so
the whole stack (including ClimaAtmos) uses the patched curve inside this
environment only; nothing outside `experiments/clw calibration/` is affected.
Semantics: **a > 1 lowers INPC** (fewer INPs → slower deposition → less ice,
more liquid); **b > 1 raises INPC** with a cold-ward tilt (the ⁹ makes it
strong: b = 1.2 → ≈5× INPC). The stochastic-INPC frequency path (unused in
our deterministic runs) is left stock.

The six calibrated parameters (all verified live in the 1M +
TemperatureDependent code path):

| parameter | current | role / why it addresses a bias |
|---|---|---|
| `sublimation_deposition_timescale` | 100 (larcform1 toml) | sublimation arm of TemperatureDependent (`Microphysics1MOptions.jl:131`); proven leverage in clw experiment v5–v7 |
| `condensation_evaporation_timescale` | 100 (larcform1 toml) | liquid condensation/evaporation relaxation; sets how fast clw tracks saturation |
| `cloud_liquid_water_specific_humidity_autoconversion_threshold` | 5e-4 (default) | **rain autoconversion never fires in current runs** — model clw peaks at ~4.2e-4, below the threshold. Liquid has no precipitation sink → clwvi 3.5× high. Lowering the threshold opens the drain |
| `snow_autoconversion_timescale` | 100 (default) | ice → snow above a 1e-6 threshold with τ = 100 s — cloud ice is drained to snow almost immediately → clivi ~7× low. Raising τ retains cli |
| `Frostenberg2023_a_coefficient` | 1 (default) | INPC divisor (patched CM): sets how INP-limited deposition is overall — the direct control on the WBF/ice-production rate |
| `Frostenberg2023_b_coefficient` | 1 (default) | temperature rescale of the INP curve (patched CM): tilts where deposition switches on |

Priors (EKP `constrained_gaussian(name, mean, sd, lower, upper)`, centered on
current values, positive-bounded):

- `sublimation_deposition_timescale`: (100, 100, 1, Inf)
- `condensation_evaporation_timescale`: (100, 100, 1, Inf)
- `cloud_liquid_water_..._autoconversion_threshold`: (5e-4, 4e-4, 1e-6, Inf)
- `snow_autoconversion_timescale`: (100, 100, 1, Inf)
- `Frostenberg2023_a_coefficient`: (1, 2, 1e-3, Inf) — wide; the paper's INPC
  spread is order-of-magnitude (lognormal σ = 1.37 ≈ factor 4)
- `Frostenberg2023_b_coefficient`: (1, 0.2, 0.3, 3) — tight; the ⁹ amplifies it

6 parameters → `TransformUnscented` (UKI, `impose_prior = true`) → **13
ensemble members per iteration**, deterministic sigma points (no sampling
noise). a/b are partially degenerate with each other and with the snow
timescale (all shape the ice budget); `impose_prior = true` regularizes this.

### Duplicate-toml gotcha (handled)

Local ClimaAtmos merges toml files with `CP.merge_toml_files` without override
(atmos_config.jl:141): a parameter present in two files raises "Duplicate TOML
entry". Both timescales live in `toml/larcform1_1M_prognostic_edmfx.toml`, so
the forward model uses `configs/toml/larcform1_calibration_base.toml` — a copy
with those two entries removed; the per-member sampled toml is then their only
source. Keep the copy in sync with the original for non-calibrated entries.

## Observations

Target: EC-Earth day-2 (hours 25–48) time-mean clw and cli profiles, linearly
interpolated onto 10 fixed pressure levels (995 → 905 hPa, step 10 —
inside both EC-Earth's and the model's pressure range; the model's lowest cell
center sits at ~1000 hPa, which rules out levels below 995. Covers the cloud:
EC-Earth day-2 cloud spans ~908–1012 hPa, s11's ~901–1000 hPa; we lose only
EC-Earth's lowest ~15 hPa of ice, which the model grid cannot represent
anyway).

Transform: `log10(q + 1e-7)` — resolves the order-of-magnitude structure of
both profiles (clw spans 1e-6..9e-5, cli 2e-7..2e-5 in the window) and makes
"factor of N" errors additive. G-vector = [log10 clw(10); log10 cli(10)],
20 entries.

Cross-validation of the target (2026-07-05): our EC-Earth day-2 clwvi ≈ 0.038
from the .nc matches Pithan 2016 Table 5's EC-Earth cloudy-state mean of 0.037
— independent confirmation that the extraction is right. EC-Earth's LWP is at
the low end of the intercomparison (ECHAM-HAM: 0.39) and the paper notes model
LWPs generally run high vs SHEBA observations, so the low target is a feature:
we are calibrating toward the obs-adjacent end of the model spread.

Noise: diagonal, σ = 0.3 in log10 space (≈ factor-2 tolerance per level) —
a starting choice, revisit if UKI over/under-fits.

Built by `scripts/build_observations.py` (writes
`observations/ecearth_day2_profiles.csv`); the Julia side applies the same
floor/log transform to model output and observations.

### EC-Earth record caveat (discovered 2026-07-05, after the uki_1 run)

`EC-Earth.nc` is NOT a 2-day record: it has **481 hourly steps spanning 20
days**. Every analysis in this project before 2026-07-05 (clw sensitivity,
speed tests, and this calibration's target) sliced the first 48 h. The full
record shows **EC-Earth's cloud glaciates on day 3**: clwvi day-means 0.033
(d1), 0.042 (d2), 0.0055 (d3), ≡0 from d4; clivi ramps to a 0.034 peak on d4,
then decays to ~0.007 by d20.

Consequences: the day-2 observation window targets the *transient mixed-phase
phase* — the right window for supercooled liquid, but the cli target is
**ramping into glaciation**, not an equilibrium. Since the calibration boosted
ice production ~4–5× (Frostenberg a/b) to hit that target, whether the
calibrated model also glaciates after day 2 — or holds its liquid, as real
Arctic clouds (but not EC-Earth) do — is an open question, tested by the
5-day verification pair (`scripts/run_verification_pair.jl`,
`output/verify5d/`).

## Layout

```
experiments/clw calibration/
├── lf1e-clw-calibration-1.md        this file
├── Project.toml                     Julia env (ClimaAtmos by path, ClimaCalibrate, EKP)
├── run_calibration.jl               UKI driver (args: [n_iterations] [run_name])
├── model_interface.jl               forward_model + observation_map + obs loader
├── configs/
│   ├── forward_model.yml            standalone s11-grid config (NOT an overlay)
│   └── toml/larcform1_calibration_base.toml   de-duplicated parameter file
├── scripts/build_observations.py    EC-Earth → observations CSV
├── observations/ecearth_day2_profiles.csv
└── output/<run_name>/               ClimaCalibrate output (iteration_*/member_*/...)
```

## Execution

```bash
# once: build observations (already done)
conda run -n clenv python "experiments/clw calibration/scripts/build_observations.py"

# once: instantiate the Julia env
julia --project="experiments/clw calibration" -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# calibrate (from repo root; 6 iterations, run name uki_1)
julia -t 1 --project="experiments/clw calibration" \
    "experiments/clw calibration/run_calibration.jl" 6 uki_1 \
    > "experiments/clw calibration/output/run_uki_1_$(date +%Y%m%d_%H%M%S).log" 2>&1
```

JuliaBackend runs members sequentially in one process — JIT is paid once, and
peak memory stays at one simulation (~9.4 GiB RSS observed for this grid).

## Time estimate (measured, 2026-07-05 smoke runs)

Measured on two smoke calibrations (julia 1.12.6, single process, `-t 1`):
4 params/9 members (pre-INP-patch) took 14m26s; the final 6-param/13-member
configuration took **17m27s** for 1 iteration.

- one-time `Pkg.instantiate` + precompile: **~5 s** — every dependency version
  hit the existing `.buildkite` precompile caches (ClimaCalibrate 0.3.1 and
  EKP 2.7.1 are small). On a cold depot budget ~30–60 min instead.
  Re-precompile after the CloudMicrophysics patch: 25 s.
- per-session fixed cost (package load + first-member JIT): **~9 min**
- per member after JIT: **~38 s wall** (solve 31.5–37.6 s + config/IO; leaner
  than s11's 42 s because only 7 diagnostics are written)
- observation map + UKI update: seconds
- **per iteration: 13 × 38 s ≈ 8.2 min**

| scenario (6 params, 13 members) | estimate | basis |
|---|---|---|
| smoke (1 iteration) | **17m27s measured** | ~9 min fixed + 8.2 min members |
| 6-iteration calibration (78 runs) | **~58 min** | 9 + 6×8.2 |
| 10-iteration calibration (130 runs) | **~91 min** | 9 + 10×8.2 |

Memory: one simulation at a time, ~9.4 GiB RSS peak. Disk: ~5 MB per member.

## Validation (done 2026-07-05)

1. **Smoke** — `run_calibration.jl 1 smoke`: PASS. 9/9 members completed,
   G (20×9) has zero NaNs, ensemble updated, misfit 3.45 reported,
   DataMisfitController stepped (T=0.20). One cosmetic KeyError from
   `EKP.get_error` at the end of the driver — now guarded with try/catch.
2. **Sigma-point spread** — PASS. Mean per-entry G spread (max−min) 0.40
   log10 units; the low-threshold sigma point visibly drains liquid
   (peak log clw −4.08 vs −3.56 central). All four parameters reach the model
   (member parameter tomls differ one-at-a-time, UKI-style).
3. **First update moves the right knobs**: the central sigma point sits at the
   prior *medians* (τ ≈ 70.7/73.2, threshold 3.90e-4, τ_snow ≈ 70.7); after one
   iteration the autoconversion pair moved decisively — threshold
   3.90e-4 → 1.81e-4 (opens the rain drain; addresses clwvi 3.5× high) and
   snow τ → 96.3 (retains ice; addresses clivi ~7× low) — while the two
   relaxation timescales stayed near their central values.
4. **INP-patch smoke** (`run_calibration.jl 1 smoke6`, 6 params/13 members,
   2026-07-05): PASS. 13/13 members, G (20×13) zero NaNs, 17m27s. The
   INP sigma points visibly steer the ice: a-perturbed members move cli@965
   to −6.1/−6.23 (a>1 → fewer INPs), b-perturbed to −5.62/−5.57 with a
   liquid dip (−3.86/−3.73 — WBF). Patch verified analytically too:
   INPC(−15 °C) 38.4 → 3.84 at a=10 (exact ÷10), ×1.2⁹ at b=1.2, and
   toml-sampled a/b reach the struct. First update: a → 0.19, b → 1.21
   (both toward MORE ice — attacking the clivi deficit), threshold
   3.9e-4 → 3.1e-4, snow τ → 83; misfit 2.14 (vs 3.45 in the 4-param
   smoke — the INP knobs take over part of the ice work).
5. Full run + standalone verification of the final mean: DONE — see
   "Results — uki_1" below.

Note on output layout: ClimaCalibrate numbers iterations from `iteration_001`
(the prior ensemble); each iteration dir holds `member_00N/` (with
`parameters.toml` and `output_active/`), `G_ensemble.jld2`, and `eki_file.jld2`.
At the default misfit the wiring check gives χ²/dim ≈ 14 vs σ = 0.3 — plenty
of signal above the noise floor.

## Risks / notes

- UKI moves parameters, not physics: the INP curve itself is fixed (dead a/b),
  so if clivi can't reach EC-Earth by retaining ice longer
  (snow_autoconversion_timescale), the residual points at ice production, not
  tuning.
- σ = 0.3 diagonal noise is a first guess; DataMisfitController adapts step
  sizes but the posterior width is only as meaningful as the noise model.
- Float32 forward model vs Float64 parameters: ClimaParams casts on load; fine.
- Do not commit outputs; `output/` is run data like the other experiments.

# Results — uki_1 (2026-07-05)

Full calibration: 6 iterations × 13 members = 78 runs, 53m34s wall.

**Final constrained parameter means** (iteration-7 state; extract from
`output/uki_1/iteration_007/eki_file.jld2` — the driver's in-memory `ekp` is
NOT updated by `calibrate`, fixed in run_calibration.jl):

| parameter | prior center | final | physics |
|---|---|---|---|
| `Frostenberg2023_a_coefficient` | 1 | **0.254** | ≈4× more INPs |
| `Frostenberg2023_b_coefficient` | 1 | **1.194** | ≈×4.8 INPC, cold-ward tilt |
| `snow_autoconversion_timescale` | 100 s | **832 s** | ice retained ~8× longer |
| `clw_..._autoconversion_threshold` | 5e-4 | **3.77e-4** | rain drain now active |
| `sublimation_deposition_timescale` | 100 s | 66.6 s | minor |
| `condensation_evaporation_timescale` | 100 s | 101.1 s | untouched |

**Misfit trajectory** (χ²/dim in σ=0.3 units, actually-simulated central
member per iteration, then the final mean standalone): 12.77 → 6.20 → 5.70 →
4.76 → 3.62 → 2.29 → **1.73**. (EKP.get_error uses a different normalization:
2.14 → … → 0.47; same shape.) Still descending at iteration 6 — more
iterations or a revisited noise model (χ² > 1 ⇒ not yet within assumed σ)
could tighten further.

## 5-day verification (output/verify5d/, run_verification_pair.jl)

Three standalone 5-day runs: final mean ("calibrated"), iteration-6 mean, and
stock-v10 baseline. Scored on the day-2 window and on the full trajectory
against EC-Earth's 20-day record.

| run | day-2 χ²/dim | last liquid hour | day-2 clwvi | day-4/5 clivi |
|---|---|---|---|---|
| EC-Earth | 0 | 51 | 0.042 | 0.028–0.034 |
| **calibrated (final mean)** | **1.73** | **54** | 0.080 | 0.010 |
| iteration-6 mean | 2.29 | 54 | 0.085 | 0.009 |
| baseline (stock v10) | 14.33 | 74 | 0.204 | 0.005–0.007 |

**Verdict: calibration validated; adopt the final mean.** Calibrated only on
a day-2 snapshot, the model reproduces EC-Earth's full cloud life cycle:
day-1 clwvi 0.036 vs 0.033, glaciation at hour 54 vs 51 (baseline: hour 74
with 5× the liquid), ice-only aftermath. The glaciation timing was never in
the objective — it emerged from the calibrated ice physics, which is strong
evidence the parameters capture mechanism, not curve fit.

Residual biases: day-2 clwvi ≈1.9× high (profile peak slightly hot at
~975 hPa) and post-glaciation clivi ≈3× low. Candidate follow-ups: more
iterations; add day-3+ clivi to the observation vector (now that the 20-day
record is understood); revisit σ per variable.

**Analysis pitfall (recorded so it isn't repeated)**: a quick python rescoring
of the verification runs initially reported χ²/dim 7.5–8.3 and suggested the
final UKI update had overshot. It was a scripting bug (positional `[24:48]`
slicing + `np.interp` silently clamping out-of-range pressures). The julia
`g_vector` path — verified bit-for-bit against the training G-matrix — is the
authoritative scorer; score model output with `model_interface.jl`, not ad-hoc
python.
