# Literature review — next steps beyond Larcform1

**Date**: 2026-07-08
**Status**: in progress — first pass of search, not yet scoped into a concrete next experiment.

## Context

Larcform1 (Pithan et al. 2016) is a fixed-location (80°N), no-advection, 20-day
free-running SCM protocol. Our calibrated ClimaAtmos run
(`experiments/20day run/`) reproduces the ensemble's headline metrics well
(glaciation timing h55 vs EC-Earth h53). This doc tracks candidate field
campaigns and follow-on model-intercomparison projects (MIPs) that could be
the next experiment, and what infrastructure each would require.

## Key finding: Pithan's own research has moved from fixed-column to Lagrangian

Felix Pithan is now an ERC Starting Grant group leader at AWI running
**A3M-transform** ("Understanding Arctic amplification through air-mass
transformations"). He co-authored:

- **HALO-(𝒜𝒞)³ campaign overview** (Wendisch et al. 2024, ACP) — airborne
  campaign over the Norwegian/Greenland Seas, Fram Strait, and central Arctic
  Ocean, March–April 2022. Studies air-mass transformation during warm-air
  intrusions (WAI) and cold-air outbreaks (CAO).
- **Lagrangian single-column modeling of Arctic air mass transformation
  during HALO-(𝒜𝒞)³** (ACP 2025) — an air-mass-following SCM (AOSCM) forced
  along a trajectory rather than held at a fixed point, validated against the
  12–14 March 2022 WAI event using observations, reanalysis, and forecast
  data.

This is the natural successor in spirit to Larcform1: same investigator, same
SCM methodology, but trading the stationary 20-day setup for a
trajectory-following one that directly targets air-mass transformation and
Arctic amplification mechanisms.

## Other campaigns / MIPs surveyed

1. **COMBLE / COMBLE-MIP** (Cold-air Outbreaks in the Marine Boundary Layer
   Experiment, March 2020, marginal ice zone). Active MIP combining LES + SCM
   against ARM ground/ship data; Part I preprint (model spec, observational
   constraints, preliminary findings) is on EGUsphere (2026). Preliminary
   finding: **mixed-phase SCMs underpredict ice's radiative impact vs. LES**
   because they don't reduce cloud cover enough once ice forms — a directly
   testable diagnostic against our cl/cli/clw pipeline. Case: 13 March 2020,
   strong/highly-supercooled convective CAO with a straight trajectory.
2. **ACLOUD/PASCAL** (June 2017, Ny-Ålesund). 11-model LES intercomparison of
   mixed-phase clouds and CCN-limited "tenuous cloud" regimes. Useful as an
   LES reference / forcing-data source (ESSD/ACP/AMT special issue) rather
   than an SCM protocol.
3. **ISDAC** (2008). Standard older LES intercomparison target for Arctic
   mixed-phase stratus. Well-documented forcing data; shorter and
   better-observed than Larcform1's idealized profile, but less novel.
4. **MOSAiC** (2019–2020 drift). Not itself an SCM protocol, but ground-based
   remote sensing has been used to benchmark systematic liquid-water-path
   biases in models. Candidate observational dataset for evaluating our
   slab-ocean/sea-ice coupled runs once we move past the idealized Pithan
   protocol.
5. **CONSTRAIN** (Jan 2010, North Atlantic). Precursor to COMBLE; mid-latitude
   marine cold-air outbreak, not Arctic, but shares the cloud-microphysics
   parameterization motivation.
6. **M-PACE (ARM Mixed-Phase Arctic Cloud Experiment)** — earlier (2004-era)
   precedent for SCM case-study intercomparison of single-layer and
   multilayer Arctic mixed-phase cloud (Klein et al., two-part series).
   Historical context for the Larcform1-style case-study approach.

## Recommendation (as of this pass)

Two most promising next steps, given current infrastructure (validated,
calibrated ClimaAtmos SCM on the Larcform1 protocol; working sea-ice/slab-ocean
coupling):

- **COMBLE-MIP** — closer to a drop-in extension: single trajectory/column,
  prescribed large-scale forcing, SCM-vs-LES-vs-obs comparison already
  established by others. Its headline bias (SCMs underpredicting ice's
  cloud-cover reduction) is directly testable against our calibrated
  Frostenberg/1M microphysics setup.
- **HALO-(𝒜𝒞)³ Lagrangian AOSCM case** — more novel, thematically aligned
  with where Pithan's group has taken this research (air-mass transformation,
  Arctic amplification). Requires building trajectory-following forcing
  (time-varying advection/geostrophic wind along a Lagrangian path) instead
  of the current fixed-point setup — a bigger infrastructure lift.

## Open threads / not yet done

- Pull COMBLE-MIP forcing-data format and check what it would take to adapt
  our config/diagnostics pipeline to consume it.
- Check whether HALO-(AC)³ trajectory/forcing data is publicly archived and
  in what format.
- Not yet reviewed: YOPP (Year of Polar Prediction) boundary-layer working
  group outputs, referenced in passing as an intended alignment point for
  MOSAiC/GASS boundary-layer studies but not investigated in detail.

## Sources

- [Pithan, F. et al. (2016): Larcform 1 — PANGAEA data](https://doi.pangaea.de/10.1594/PANGAEA.856770)
- [Select strengths and biases... Larcform 1 SCM intercomparison (OSTI)](https://www.osti.gov/pages/biblio/1360737)
- [ACP - Overview: quasi-Lagrangian observations of Arctic air mass transformations – HALO-(AC)3](https://acp.copernicus.org/articles/24/8865/2024/)
- [ACP - Lagrangian single-column modeling of Arctic air mass transformation during HALO-(AC)3](https://acp.copernicus.org/articles/25/13177/2025/)
- [ACP - Observed and modeled Arctic airmass transformations during WAI/CAO](https://acp.copernicus.org/articles/25/15047/2025/)
- [EGUsphere - COMBLE-MIP Part I: model spec, observational constraints, preliminary findings](https://egusphere.copernicus.org/preprints/2026/egusphere-2026-1237/)
- [ResearchGate - The COMBLE campaign: marine boundary layer clouds in Arctic cold-air outbreaks](https://www.researchgate.net/publication/358990149_The_COMBLE_campaign_a_study_of_marine_boundary-layer_clouds_in_Arctic_cold-air_outbreaks)
- [CONSTRAIN cold air outbreak case](https://appconv.metoffice.gov.uk/cold_air_outbreak/constrain_case/home.html)
- [ESSD special issue - Arctic mixed-phase clouds during ACLOUD/PASCAL ((AC)3)](https://essd.copernicus.org/articles/special_issue10_971.html)
- [ACP - Model intercomparison of CCN-limited tenuous clouds in the high Arctic](https://acp.copernicus.org/articles/18/11041/2018/)
- [Felix Pithan - AWI staff page](https://www.awi.de/en/about-us/organisation/staff/single-view/felix-pithan.html)
- [Felix Pithan - Google Scholar](https://scholar.google.com/citations?user=2WfOBlkAAAAJ&hl=en)
- [Intercomparison of model simulations of mixed-phase clouds during M-PACE, Part I](https://www.researchgate.net/publication/227503243_Intercomparison_of_model_simulations_of_mixed-phase_clouds_observed_during_the_ARM_Mixed-Phase_Arctic_Cloud_Experiment_I_Single-layer_cloud)
- [Intercomparison of model simulations of mixed-phase clouds during M-PACE, Part II](https://www.researchgate.net/publication/227841079_Intercomparison_of_model_simulations_of_mixed-phase_clouds_observed_during_the_ARM_Mixed-Phase_Arctic_Cloud_Experiment_II_Multilayer_cloud)
