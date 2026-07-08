# lf1e-20day-1 — full 20-day Larcform1 run vs the Pithan 2016 ensemble

**Date started**: 2026-07-06
**Status**: complete (2026-07-06)

## Goal

Run the calibrated ClimaAtmos Larcform1 SCM (modified SlabOceanSST surface)
for the full 20-day Pithan 2016 intercomparison record (481 hourly steps) and
compare against the 15-member ensemble in "Pithan 2016 Intercomparison Data/".
Previous validation stopped at 5 days ("experiments/clw calibration/",
verify5d); the ensemble records nearly all run 481 hourly steps (ECHAM6.2:
465, wurd91: 480; the two GISS files need decode_times=False).

## Configuration

- **Config**: `configs/lf1e_20day_calibrated.yml` — the validated calibration
  forward model (s11 grid: z_max 5 km, z_elem 100 stretched, dt 30 s, dt_rad
  30 min, TemperatureDependent ice formation, Float32) with t_end 20days and
  the full Pithan diagnostic set at 1-hour averages.
- **Parameters**: calibration base toml + `configs/toml/calibrated_params.toml`
  (uki_1 final means, copied from clw calibration output/verify5d): Frostenberg
  a 0.254 / b 1.194, snow autoconversion τ 832 s, clw autoconversion threshold
  3.77e-4, subl/dep τ 66.6 s, cond/evap τ 101.1 s.
- **Runner**: `run_20day.jl`
  (`julia -t 1 --project="experiments/clw calibration" "experiments/20day run/run_20day.jl"`).
  Cost: ~6 min solve (12.8 SYPD) + ~8 min JIT.

## Environment trap found on the first attempt (2026-07-06)

The first 20-day run used `--project=ClimaAtmos.jl/.buildkite`, whose Manifest
resolves **registered** CloudMicrophysics 0.36.0 — upstream ignores
`Frostenberg2023_a/b_coefficient`, so the calibrated INP curve (a 0.254,
b 1.194) was silently inert. Result: day-2 clwvi 0.166 (vs verify5d's 0.078),
glaciation h76 (vs h55). Config and merged parameter toml were bit-identical
to verify5d — only the environment differed. Runs needing the calibrated
Frostenberg parameters must use the clw-calibration project, which devs the
vendored `CloudMicrophysics.jl` (patched in commit 654e33e). The contaminated
output is quarantined in `output/calibrated_WRONG_registered_CM/`.

## Known caveats going in

- The s11 grid was validated for 2-day science and run 5 days in verify5d;
  20 days is extrapolation. Check the ice cloud stays well below the 5 km
  domain top over the ice-only phase (days 3–20).
- Residual calibrated-model biases from verify5d: day-2 clwvi ≈1.9× high,
  post-glaciation clivi ≈3× low vs EC-Earth.
- Surface is the modified slab ocean (SST forced to 250 K), not the Pithan
  prescribed-surface/sea-ice protocol — ts comparisons carry that caveat.

## Analysis plan

1. Convert with `scripts/convert_to_pithan.py --suffix 1h_average`.
2. Compare vs ensemble: ts, clwvi, clivi, rlds/rlus/rlut, precs time series;
   glaciation timing (last liquid hour); day-2 and day-10 profiles (t, clw, cli).
3. Score liquid/ice phase behavior against EC-Earth (the record used for
   calibration) and place ClimaAtmos within the ensemble spread.

## Results (2026-07-06)

Run: `:success`, 552 s solve (8.6 SYPD) + JIT. The first 120 h are
**bit-for-bit identical** to verify5d's calibrated run (max |Δlwp| = 0.0),
confirming the environment fix and making this the authoritative calibrated
20-day record. Figures in `figures/`; metrics from
`scripts/compare_ensemble.py` (day-2 = mean over h24–48; glaciation =
last hour clwvi > 1e-3 kg/m², which gives EC-Earth h53).

### Cloud life cycle — the headline

| metric | ClimaAtmos | EC-Earth | ensemble range (n=15) |
|---|---|---|---|
| glaciation hour | **55** | 53 | never-liquid (3 models) … h438 |
| day-2 clwvi (kg/m²) | 0.078 | 0.042 | 0 – 0.259 |
| max clwvi | 0.091 | 0.055 | 0 – 0.400 |
| clivi mean days 5–20 | 0.0125 | 0.0154 | 0.0009 – 0.043 |

- **Glaciation timing lands on EC-Earth almost exactly** (h55 vs h53) in an
  ensemble whose spread on this metric is the entire record: three members
  never form liquid, CAM5.3ps holds it to day 18, GISS baseline loses it at
  h16. In the persistence ranking ClimaAtmos sits directly beside EC-Earth.
  This extends the verify5d result (calibrated on a day-2 snapshot only) to
  the full record.
- **Day-2 liquid remains ~1.9× EC-Earth** — the known residual calibration
  bias, unchanged, and well inside the ensemble envelope.
- **The ice-phase deficit shrinks over the record**: verify5d flagged
  day-4/5 clivi ≈3× low; over days 5–20 the mean is only ~19% below EC-Earth
  (0.0125 vs 0.0154), third-closest in the ensemble. EC-Earth's ice decays
  through the record while ClimaAtmos builds ice through days 12–20 in
  quasi-periodic growth/fallout sawteeth — similar in character to
  EC-Earth's own sawteeth (days 5–11), but arriving later with larger
  amplitude.
- Day-2 profiles: inversion and mixed-layer top (~900 hPa) match EC-Earth
  closely; the clw peak is at the right level but ~3× the EC-Earth peak
  mixing ratio. Day-10 ice profile lies essentially on EC-Earth's.

### Surface — dominated by the slab-ocean caveat, as expected

ts is pinned at ~249.5 K by the 250 K slab while the ensemble cools to
207–239 K (EC-Earth, the warmest member, reaches 238 K). By day 20 our
surface is ~11 K warmer than the warmest ensemble member, and the day-10
temperature profile is correspondingly ~5 K warm at all levels. rlds
(mean 166 W/m²) nonetheless sits mid-ensemble (range 125–203). Days 5–20
surface/thermodynamic comparisons are therefore statements about the
boundary condition, not the atmosphere model — coupling to a real surface
energy budget (ClimaSeaIce or the Pithan ice slab) is the obvious next step.

### Caveats

- Trace ice (cli ≤ 1e-6 kg/kg, two orders below the cloud layer) reaches
  ~4950 m — the domain top — late in the record, carrying up to ~14%
  (mean 7%) of the then-small column ice in the final days. If days 15–20
  ever matter quantitatively, re-check with a deeper domain.
- clivi includes snow (1M convention, see convert_to_pithan.py); the
  intercomparison models' clivi definitions vary similarly.
- The environment trap above means any historical run made from the
  buildkite env with Frostenberg parameters in the toml needs re-checking.
