# Pithan et al. (2016) analysis reproduction — with our sensitivity tests

Reproduces the core Larcform1 diagnostics from Pithan et al. (2016, JAMES,
doi:10.1002/2016MS000630) with our ClimaAtmos/ClimaCoupler runs overlaid:
4 surfaces (slab ocean, Holloway-Manabe slab ice, ClimaSeaIce bare, ClimaSeaIce
+ snow) x 2 microphysics (calibrated uki_1 / uncalibrated ClimaParams defaults).

Paper source: clean transcription at
`experiments/clw calibration/papers/Pithan-etal-2016_Larcform1-SCM-intercomparison.md`
(re-done 2026-07-13 from the Zotero PDF).

## Contents

- `scripts/reproduce_pithan.py` — produces everything below in one run
- `figures/fig4_netlw_pdf.png` — paper Fig. 4: PDF of hourly surface net LW,
  days 1-10, 5 W/m2 bins (cal vs uncal panels; ensemble gray, EC-Earth red)
- `figures/fig5_6_profiles.png` — paper Figs. 5/6: T profiles (1 h avg) at
  day 2 and day 10, with skin temperature dots
- `figures/fig1_bivariate.png` — paper Figs. 1/3-style: bivariate PDF of
  low-level stability T(850)-T(sfc) vs surface net LW, per run + EC-Earth
- `figures/table5_metrics.txt` — paper Table 5: clear-state sensible heat flux,
  cloudy-state LWP, 10-day accumulated surface energy loss
  (clear/cloudy partition at net LW = -20 W/m2, fluxes positive down)

## Data (referenced in place, not copied)

- Our coupled sea-ice runs: `experiments/sea-ice/analysis/converted/*.nc`
  (`*_cal.nc` = 2026-07-10 corrected-coupler_toml reruns; bare names =
  2026-07-09 uncalibrated)
- Slab-ocean runs: `experiments/20day run/output/ClimaLarcform1*.nc`
- Published ensemble: `Pithan 2016 Intercomparison Data/*.nc`
  (PANGAEA doi:10.1594/PANGAEA.856770)

## Validation of the pipeline against published Table 5

Recomputing Table 5 from the PANGAEA archive reproduces the paper within
rounding for most models (energy loss: EC-Earth 27.1 vs 27.3, ECHAM6.2 17.3 vs
17.5, GISS 18.4 vs 18.3, ECMWF-IFS 24.3 vs 24.1; hs and clwvi similar). Known
archive quirks:
- WRF files store `hs` with the opposite sign to the paper (we get -11.7 where
  Table 5 lists +12.05).
- ECHAM6-HAMs1 gives cloudy clwvi 0.04 vs the paper's 0.39 (archive file may be
  a different variant than the published ECHAM-HAM run).
- wurd91 has no `hs` and zero net LW variability (lacks the clear state, as in
  the paper).

## Initial findings (our runs in the paper's framework)

1. **All 8 of our runs represent both BL states** (bimodal net-LW PDF, Table
   4's "with cloudy state" column) — expected, since our prognostic liquid/ice
   microphysics matches the class the paper found adequate.
2. **Clear-state radiative cooling is too strong.** Our clear-state peaks sit
   at -50..-70 W/m2 vs the ensemble/SHEBA ~-25..-45. Correspondingly our
   accumulated 10-day energy loss (37-40 MJ/m2 for no-snow surfaces) exceeds
   the paper's worst case (EC-Earth 27.3). The snow run (18.9-19.8 MJ/m2) lands
   in the middle of the published range — the insulating snowpack matters more
   than any other choice, exactly the paper's Sec. 3.2 conclusion.
3. **Cloudy-state LWP:** calibrated runs (0.055-0.10 kg/m2) sit at the upper
   half of the published spread (0.01-0.39); uncalibrated (0.14-0.20) near the
   top. Calibration moves us toward the observed (SHEBA-median-low) end.
4. **Bivariate plane:** our snow run occupies the paper's "strong stability in
   clear state" quadrant (stability +10..+15 K at -20..-40 W/m2, like
   ECHAM/WRF); bare ice sits at moderate stability but excessive cooling
   (-50..-65); slab ice/ocean reproduce the EC-Earth-like weak-stability
   failure mode. Calibration mainly moves points from the cloudy cluster to
   the clear cluster earlier (glaciation timing), not the cluster locations.

Caveat: our stability uses T interpolated to 850 hPa from model levels and
skin temperature for T(sfc), matching the paper's definition (sounding-based
850 hPa minus surface temperature).

## Known artifact: 2dz temperature banding (grid-insensitive, benign)

The slab-ocean/slab-ice profiles carry a standing 2dz zigzag in T (and
saturation-slaved q), imprinted at the glaciating cloud base (~2 K at day 2,
decaying to ~0.5 K by day 10, riding up with the mixed layer). Phase-locked in
time (r=1.00 across hours); absent from winds and all vertical integrals.

Grid sensitivity test (2026-07-13, slab ice calibrated, Stratus:
`lf1_slab_ice_dzb20_20d`, `lf1_slab_ice_nostretch_20d`; figure
`experiments/sea-ice/analysis/figures/dz_test_profiles.png`):

| grid              | banding      | glac (d) | LWP d2 | E loss | stab d3-10 |
|-------------------|--------------|---------|--------|--------|-----------|
| dz_bottom=10 (s11)| yes, 2dz     | 2.29    | 0.077  | 39.8   | -0.98     |
| dz_bottom=20      | yes, 2dz     | 2.33    | 0.075  | 39.9   | -1.07     |
| no stretch (50 m) | yes, 2dz     | 2.38    | 0.065  | 39.9   | -1.10     |

Conclusions: (1) the banding appears at 2dz on every grid -> scheme-level
(likely saturation/phase-partitioning flip-flop at cloud base), not a
resolution artifact; fix belongs upstream in ClimaAtmos/CloudMicrophysics.
(2) The physics is grid-converged - all suite/Pithan metrics move less than
the cal/uncal spread. The artifact is cosmetic for these analyses; it adds
<~0.5 K noise to T(850)-based stability late in the run.
