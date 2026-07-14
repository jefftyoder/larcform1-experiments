# Representation of Arctic Winter Atmospheric Boundary Layer Stability Over Sea Ice in CMIP6 Models

Duffey, A., R. Mallett, V. R. Dutch, J. Steckling, A. Hermant, J. Day, and F. Pithan (2025),
*Journal of Geophysical Research: Atmospheres*, 130, e2024JD041412,
doi:10.1029/2024JD041412.
Received 19 Apr 2024; accepted 23 May 2025. Open access (CC BY).
Code: https://doi.org/10.5281/zenodo.13763472 (Duffey, 2024).

> **Note on this file:** re-transcribed 2026-07-14 from the source PDF
> (`~/Zotero/storage/BVQ3DTLE/`), replacing an earlier automated PDF text dump
> (recoverable in git history). Tables, equations, and figure captions are
> verbatim; running prose is a faithful condensed rendering, not a word-for-word
> copy — consult the PDF for exact wording.

**Author affiliations**

1. Centre for Polar Observation and Modelling, Earth Sciences, University College London, London, UK
2. Earth Observation Group, Department of Physics and Technology, UiT The Arctic University of Norway, Tromsø, Norway
3. Department of Geography and Environmental Sciences, Northumbria University, Newcastle, UK
4. School of Environmental Sciences, University of East Anglia, Norwich, UK
5. School of Integrated Climate and Earth System Sciences, Universität Hamburg, Hamburg, Germany
6. Bjerknes Centre for Climate Research, Geophysical Institute, University of Bergen, Bergen, Norway
7. Climate and Environmental Physics, Physics Institute, University of Bern, Bern, Switzerland
8. Oeschger Centre for Climate Change Research, University of Bern, Bern, Switzerland
9. European Centre for Medium-Range Weather Forecasts, Reading, UK
10. Helmholtz Centre for Polar and Marine Research, Alfred Wegener Institute, Bremerhaven, Germany

**Key points**
- A cloudy state, without strong low-level stability (LLS), is often observed over
  winter Arctic sea ice but is absent in most Coupled Model Intercomparison Project
  (CMIP6) models
- CMIP6 models show a realistic representation of the dependence of LLS on near-surface
  air temperature and wind speed
- Observations show a decreasing trend in Arctic winter LLS, which CMIP6 models project
  will continue under warming

## Abstract (condensed)

The Arctic winter atmospheric boundary layer often features strong and persistent
low-level stability (LLS) arising from longwave radiative cooling of the surface during
the polar night. This stable stratification produces a positive lapse rate feedback, a
major contributor to Arctic amplification. A second state, with cloudy conditions,
weaker stability, and near-zero net surface longwave flux, is also observed. Previous
work showed that many CMIP5 models fail to partition water appropriately between liquid
and ice phases in mixed-phase clouds, leading to a lack of this cloudy state. Here the
authors assess the representation of the Arctic winter boundary layer in CMIP6, comparing
boundary layer process relationships to surface-based and radiosonde observations from
MOSAiC (2019–2020), SHEBA (1997–1998), and the North Pole drifting stations (1955–1991).
The majority of CMIP6 models fail to realistically represent the cloudy state over winter
Arctic sea ice. Despite this, the CMIP6 multimodel mean LLS falls within the observational
range, and models mostly capture the observed dependence of LLS on near-surface air
temperature and wind speed. CMIP6 models predict a decline in winter LLS with Arctic
warming, with mean stability falling below zero by 2100 under SSP2-4.5. The failure to
accurately simulate mixed-phase clouds is an important limitation on representing a
realistic Arctic winter boundary layer in many CMIP6 models.

## Plain Language Summary (condensed)

The atmospheric boundary layer is the lowest part of the atmosphere, directly influenced
by contact with the Earth's surface. In the Arctic winter this layer is often coldest
nearest the surface, making it stable against vertical mixing — part of the explanation
for Arctic amplification. Comparing climate models against MOSAiC, SHEBA, and the North
Pole drifting stations shows cloudy conditions are underrepresented in many models.
However, models mostly succeed in representing how stability varies with temperature and
wind speed. As the Arctic warms, low-level stability is expected to decrease, and models
project the stable state will no longer be dominant in the Arctic winter before the end of
the century under a medium emissions scenario.

## 1. Introduction

- The Arctic is warming roughly four times faster than the global average (Chylek et al.,
  2022; Rantanen et al., 2022), and late-summer sea ice extent has declined by 50% in
  40 years (Fetterer et al., 2017, updated 2023). Consequences include earlier crossing of
  the Paris 1.5 °C threshold (Duffey et al., 2023), albedo feedback (Pistone et al., 2014),
  Greenland-driven sea level rise (Pattyn et al., 2018), permafrost carbon release
  (Comyn-Platt et al., 2018), and — controversially — changes in midlatitude extreme
  weather.
- Arctic amplification is driven by the weaker (negative) Arctic Planck feedback,
  increasing solar absorption with declining snow/ice, atmospheric heat transport, and the
  latitudinal variation in deviation from vertically uniform warming. This last term — the
  lapse rate feedback — arises because Arctic warming is more strongly confined near the
  surface, and is one of the largest contributors to Arctic amplification in climate models
  (Goosse et al., 2018; Hahn et al., 2021; Lu & Cai, 2010).
- Arctic warming amplification is strongest during late autumn and winter. In winter the
  atmosphere often shows strong, long-lived **low-level stability (LLS)** arising from
  longwave radiative cooling of the surface (Boeke et al., 2021; Wexler, 1936). Stable
  stratification concentrates heating near the surface as the Arctic warms → greater
  surface temperature increase than in the upper troposphere → positive lapse rate feedback
  (Bintanja et al., 2011; Boeke et al., 2021). This contrasts with the tropics, where
  convection restores the profile close to the moist adiabat and the lapse rate feedback is
  negative (Hansen et al., 1997).
- Accurate simulation of LLS has been hampered by persistent model biases (Inoue et al.,
  2021; Pithan et al., 2014; Sedlar et al., 2020; Solomon et al., 2023; Tjernström et al.,
  2008). In CMIP5, many models mis-partition liquid and ice in mixed-phase clouds, biasing
  modeled LLS (Pithan et al., 2014); similar biases exist in NWP models, regional climate
  models, and CMIP3. Since CMIP5, modeling centers have improved vertical resolution and
  convection/microphysics schemes (e.g., Gettelman et al., 2019), but the extent of these
  biases in CMIP6 had not been assessed.
- Two boundary-layer states (Persson et al., 2002; Stramler et al., 2011): a **clear**
  state with clear-sky conditions and strong longwave surface cooling (≳50 W m⁻²) due to a
  lower atmosphere relatively transparent to outgoing radiation; and a **cloudy** state in
  which surface net longwave radiation is close to zero due to opaque low-level mixed-phase
  clouds. The clear state has stronger inversions; the cloudy state has weaker inversions
  found further aloft. This bimodality is restored in the CMIP5 ensemble (Pithan et al.,
  2014), but few CMIP5 models showed a realistic cloudy state, in part due to freezing of
  supercooled water droplets at excessively warm temperatures, preventing formation of
  mixed-phase clouds with high emissivity.
- Wind speed and shear are also potential sources of bias in LLS: higher near-surface wind
  speeds are associated with increased near-surface air temperature and a reduction in
  near-surface inversion strength over Arctic sea ice (Chechin et al., 2019; Wiel et al.,
  2017), because increased turbulent heat fluxes under high wind speed/shear prevent
  formation of strong stability.
- This study: investigate the representation of Arctic winter LLS over sea ice and the
  processes controlling it in CMIP6 (Eyring et al., 2016), comparing against MOSAiC
  (2019–2020; Shupe et al., 2022), SHEBA (1997–1998; Uttal et al., 2002), and 21 North Pole
  (NP) drifting stations (1954–1990; Kahl et al., 1999).

## 2. Data and Methods

### 2.1 CMIP6 Data

- The CMIP6 ensemble is defined by data availability at different time resolutions on the
  UK CEDA archive (Table S1 lists all models and DOIs). At monthly resolution, 45 CMIP6
  models are generally analyzed. For the cloud water content and surface heat flux analysis
  in Figure 6, only 37 models have the required data. For future projections under SSP2-4.5
  (Section 3.5), a slightly different set of models was available (Tables S1 and S2).
- For high time resolution data (6-hourly and daily), availability is more limited: a
  20-model subset of the original 45 is analyzed. The first ensemble member only is used
  for each model.
- Except for future projections, the time period selected is the final 20 years of the
  historical scenario (1995–2015) for monthly outputs (Figure 1) and the final 5 years
  (2010–2015) for daily and subdaily outputs (Figures 2–5).
- Model output is shown over the extended winter (November–March, inclusive) sea ice
  domain: each model's monthly sea ice concentration is regridded onto that model's
  atmospheric grid by bilinear interpolation, then a time-varying sea ice mask includes only
  grid points with over 95% sea ice concentration in a given month.
- Future trends use one emissions scenario, SSP2-4.5, a medium scenario broadly in line
  with current global emissions mitigation policies (Hausfather & Peters, 2020).

### 2.2 Observational Data

- **MOSAiC** (Shupe et al., 2022), October 2019 – October 2020: radiosonde data from
  Maturilli et al. (2021) and tower radiation data from ARM (Reynolds & Riihimaki, 2019).
  Sondes were generally launched four times per day, with increased frequency during
  exceptional weather events (Peng et al., 2023) — the nonuniformity in time sampling is
  accounted for (Section 2.3). 340 winter atmospheric profiles are analyzed.
- **SHEBA** (Uttal et al., 2002), October 1997 – October 1998: radiosonde profiles and
  surface radiative flux data. Radiative flux details in Persson et al. (2002); radiosonde
  campaign in Beesley et al. (2000) and Bretherton et al. (1999). Sondes generally launched
  twice daily, resulting in 276 valid winter atmospheric profiles.
- **North Pole drifting stations (NP)** (Kahl et al., 1999), 1954–1991: 31 stations existed
  in the period, but the US NSIDC archive does not contain usable observations from stations
  1, 2, 18, 20, 23, 24, 25, 27, 29, and 30. The remaining 21 stations leave 6,999 valid
  winter atmospheric profiles.
- Combined: more than 7,500 winter radiosondes, of which 593 (from MOSAiC and SHEBA) can be
  matched to contemporaneous (within 5 min) surface radiative flux measurements. MOSAiC's
  icebreaker was surrounded by a loose assemblage of second-year ice (Krumpen et al., 2021);
  SHEBA by multiyear ice (Perovich et al., 2003).

**Figure 1.** Location of winter (November-March) radiosonde observations used in this
study, from the MOSAiC (2019–2020) and SHEBA (1997–1998) campaigns, and from the North Pole
drifting stations (NP) (1954–1990). The Arctic Ocean shading shows the mean winter sea-ice
concentration over the period 1950–2020 (Walsh & Stewart, 2019). The NP (MOSAiC region) and
NP (SHEBA region) points, refer, respectively, to subsets of the NP data which lie within
300 km of an observation from the MOSAiC and SHEBA campaigns.

### 2.3 Methods

- The analysis focuses on model representation of boundary layer processes, assessed
  through *relationships between model variables* over all model data points in time and
  space during the extended winter (November–March), rather than on comparison of model mean
  states with observations (the observations sample different regions, single years, and
  different greenhouse gas forcing, and are instantaneous point measurements versus model
  time-step/grid-cell means).
- Where the mean state *is* compared (e.g., Figure 2), inconstant temporal sampling over the
  campaign period is accounted for in two steps: (a) group individual sonde observations by
  date, so the mean is not biased toward days with additional sonde launches (most impactful
  for MOSAiC); (b) account for inconstant seasonal sampling by first grouping the
  observational data by month and then taking the full winter mean. Any quoted "mean" over
  time refers to a temporally representative value obtained this way.
- Bimodality in surface net longwave radiation is used as the metric for whether a model
  shows distinct clear and cloudy states (Pithan et al., 2014; Stramler et al., 2011). An
  objective measure uses **Hartigan's Dip test** (J. A. Hartigan & Hartigan, 1985;
  P. M. Hartigan, 1985), via the Python port "diptest" of the R package (Maechler, 2024) — a
  statistical test of whether a unimodal or multimodal distribution better fits the data.
  Models are called "bimodal" when this test rejects unimodality at the 95% significance
  level.
- Following Medeiros et al. (2011) and Pithan et al. (2014), **bulk LLS** is defined as the
  difference between the 850-hPa level temperature and the near-surface (2 m) air
  temperature, as a proxy for the temperature inversion. LLS is positive when the temperature
  is warmer aloft. This proxy is useful given the low and variable vertical resolution of
  CMIP6 models.
- Suppression of LLS by wind is assessed by retrieving the surface wind speed of individual
  sondes in the three observational data sets and pairing the speeds with the LLS observed by
  the same sondes: 189, 341, and 7,753 paired points from MOSAiC, SHEBA, and the North Pole
  stations, respectively. Surface wind speeds from the NP sondes were recorded only to the
  nearest m s⁻¹.

## 3. Results

### 3.1 Mean-State Low-Level Stability

- Mean LLS values in MOSAiC, SHEBA, and NP are **5.0 ± 0.3, 8.3 ± 0.4, and 9.5 ± 0.1 °C**,
  respectively (errors = standard error of the mean), accounting for uneven temporal sampling.
- Regional sampling explains only a small fraction of the variation: NP stations within
  300 km of the MOSAiC campaign have mean LLS of 9.3 ± 0.1 °C, only 0.2 °C lower than the
  full NP mean, compared to the 4.5 °C difference between MOSAiC and NP. NP stations within
  300 km of SHEBA have mean LLS 9.3 ± 0.3 °C, again closer to the full NP mean than to the
  SHEBA mean.
- Other contributors: interannual variability (SHEBA and MOSAiC each represent a single
  winter) and any long-term trend over 1950–2020. The standard deviation of the mean LLS for
  each NP station is 0.94 °C (a rough estimate of interannual variability), and the minimum
  mean for a station is 7.6 °C. The three data sets show a chronological reduction in LLS,
  with the earliest (NP) having the strongest LLS — likely representative of a wider Arctic
  trend, as expected given the negative trend under warming in CMIP6 (Section 3.5).
- CMIP6 multimodel mean winter boundary layer over sea ice: **mean LLS of 6.6 °C**
  (1995–2015), within the range of observed mean states (5–10 °C). Two models out of 45
  (**CESM2-WACCM-FV2** and **E3SM-1-0**) have negative winter mean LLS over sea ice.
- A large majority of models show strong differentiation between open ocean and sea ice
  regions, without LLS over open ocean; only 3 of 45 (**GISS-E2-1-H, GISS-E2-2-H, NorCPM1**)
  have positive winter mean-state LLS over open ocean north of 65 °N.
- Standard deviation in mean-state LLS across the ensemble is **3.3 °C**; the range between
  the most and least stable models is **14.0 °C**. Pithan et al. (2014) show similar values
  for CMIP5 — standard deviation 2.8 °C and range 11.4 °C (albeit for a slightly different
  quantity). Medeiros et al. (2011) show a standard deviation of 3.1 °C and range of ~10.9 °C
  for the stable-mode LLS across CMIP3. **No substantial reduction in intermodel spread of
  mean-state LLS over the winter sea ice between CMIP3, CMIP5, and CMIP6.**

**Figure 2.** (a) Distribution of winter low-level stability (LLS) over Arctic sea ice
(>95% concentration) in CMIP6 models (gray) and field campaigns (colors). LLS is defined as
the difference between temperature at 850 hPa and the 2-m air temperature. The bold black
line is the multimodel distribution. For all models, the distribution shown is over all grid
points in time and space where sea ice concentration is greater than 95%, over the period
1995–2015, and the region north of 65 °N. Vertical dashed lines denote mean values. (b) Mean
LLS over Arctic sea ice in the winter months (November–March) in CMIP6 models and
observations. The "whiskers" on the CMIP6 and NP boxes show the 5th and 95th percentiles of
the distribution across models and stations, respectively.

### 3.2 Near-Surface Air Temperature as a Control on Low-Level Stability

- Observations display a linear relationship between LLS and near-surface air temperature
  (Figure 3), consistent with Liu et al. (2006) and with all three observational data sets:
  **LLS decreases by approximately 0.5 °C per 1 °C increase in near-surface air
  temperature** — that is, the temperature at 850 hPa increases only approximately 0.5 °C per
  1 °C increase at the surface.
- The relationship also holds consistently across the high-time-resolution CMIP6 ensemble:
  the multimodel mean change in LLS with near-surface air temperature is **−0.47 °C per °C**,
  with a standard deviation across models of **0.06 °C per °C**. CMIP6 models therefore
  successfully capture the observed short-timescale coupling.
- Across the model ensemble (mean states, Figure S2), a similar linear relationship between
  near-surface and temperature aloft is seen, with a model's mean temperature aloft increasing
  by **0.4 °C for each 1 °C** increase in mean near-surface Arctic winter temperature.

**Figure 3.** Relationship between winter near-surface air temperature and low-level
stability, in observations (a–c) and CMIP6 models over sea ice (d). Individual radiosondes are
plotted for the observations, and the relative density of time and grid point instances with
normalized density units is plotted for CMIP6 models. Data for all models are 6-hourly, except
for NorESM2-LM, IPSL-CM6A-LR, EC-Earth3-CC, and TaiESM1, which use daily mean outputs. Solid
lines are linear regressions, with one gray line for each CMIP6 model assessed. In the North
Pole drifting stations (NP) case, we also show regressions on the subsets of observations under
"clear" and "cloudy" conditions defined as less than and greater than 50% cloud cover by visual
assessment, respectively. Panel (e) shows the slopes of the regressions given in (a–d).

### 3.3 Clear and Cloudy States

- Plotting bivariate histograms of LLS and net surface longwave (Figure 4), distinct
  clear/cloudy bimodality is found in the MOSAiC and SHEBA data. A threshold of **−25 W m⁻²**
  approximately distinguishes the two modes: any observation with surface net longwave more
  negative than −25 W m⁻² is defined as the clear state, accounting for approximately 60% of
  observations (**MOSAiC 65%, SHEBA 59%, and NP 63%**).
- Surface longwave fluxes time-matched to radiosonde observations were not available for NP,
  so LLS observations are split into two states with the clear state defined as less than 50%
  cloud cover by visual assessment. The proportion of NP observations in the clear state is
  not strongly sensitive to the threshold, because 79% of visual observations are either under
  10% cloud cover, or over 80% cloud cover. Alternative clear-sky thresholds of less than 30%
  or less than 70% would give the clear state accounting for **57% and 66%** of observations,
  respectively.
- Across the CMIP6 models, the representation of the two states is inconsistent. A visual
  assessment shows some models, such as MRI-ESM2-0, with a second center of density at close
  to zero net longwave flux, attributed to the cloudy state; other models, such as TaiESM1,
  have a single mode at approximately **−50 W m⁻²** net longwave flux, identified as having
  only a clear state. A lack of the cloudy state refers to the lack of high-emissivity,
  liquid-containing low clouds that prevent longwave cooling of the surface — it does *not*
  mean the total cloud fraction (including ice clouds) is zero.
- Using the dip test on the distribution of 6-hourly net surface longwave flux in each model,
  **7 out of 20 models show a bimodal distribution**, with both clear and cloudy atmospheric
  states (denoted with a * in Figure 4). Ordering models by their mean column cloud condensed
  water content (ice water path plus liquid water path) also supports the association of the
  lack of second mode in LLS with lack of a cloudy state; models lacking the cloudy state show
  the least atmospheric cloud water content.
- The spread among models in cloud condensed water content is very large, ranging between
  **1 and 65 g m⁻²**. The equivalent mean value for MOSAiC is approximately **80 g m⁻²**, as
  calculated from the data set of Saavedra Garfias et al. (2023) produced from MOSAiC
  microwave and radar observations. The higher end of the model range appears more likely to
  be realistic, although the MOSAiC mean state would be expected to be higher than the regional
  average shown for the models because moist intrusions are more common in the Atlantic sector
  (Woods & Caballero, 2016).
- For the seven models showing a bimodal LLS distribution, a −25 W m⁻² cutoff assigns data
  points into one of the two states (Table S3). **Four models (BCC-CSM2-MR, MPI-ESM1-2-LR,
  MPI-ESM1-2-HR, and NorESM2-LM)** show an over-representation of the cloudy state relative to
  observations; possible causes include cloud microphysics (e.g., excess liquid water) and
  excess moisture flux into the Arctic (Section 3.4).
- Within the MPI-ESM1 family, model *physics* rather than resolution appears the greater
  control on realistically representing these states. **MPI-ESM-1-2-HAM**, which has interactive
  aerosols as well as altered mixed-phase microphysics, has improved realism in the distribution
  of clear and cloudy states relative to MPI-ESM1-2-LR and MPI-ESM1-2-HR. Both of the latter have
  a minority of data points in the clear state, while MPI-ESM-1-2-HAM has **60%** of points in
  the clear state, broadly in line with the observations. Alongside the over-representation of
  the cloudy state, MPI-ESM1-2-LR and MPI-ESM1-2-HR also have mean LLS of **5.7 and 5.0 °C**,
  respectively, at the low end of the CMIP6 range, while MPI-ESM-1-2-HAM has stronger stability
  of **7.7 °C**.
- Intermodel spread in LLS is determined not only by the relative frequency of the two modes
  but also by the central LLS value within each mode. For example, while MRI-ESM2-0 has a
  realistic **63%** of points with under −25 W m⁻² net longwave (the cloudy state), it has the
  lowest mean LLS of the models in Figure 4 because both modes are found at too negative values
  of LLS.

**Figure 4.** Bivariate histograms of net longwave radiation at the surface (positive downward)
against low-level stability over sea ice, during the winter months (November–March). Histogram
units are normalized as the total count of points varies between subplots. Surface radiative flux
was not available for the North Pole drifting stations, so NP data are partitioned based on visual
assessment of cloud coverage, with coverage of >50% denoted Cloudy. Data for all models are
6-hourly, except for NorESM2-LM, IPSL-CM6A-LR, EC-Earth3-CC, and TaiESM1, which use daily mean
outputs. Vertical black dashed lines show the −25 W m⁻² threshold. The values in brackets in each
title are the mean-state atmosphere mass content of cloud condensed water (grams m⁻²) for each
model over the same region and the time period; the models are shown in ascending order in this
quantity. Starred models are not unimodal in net longwave radiation, according to a dip test at 95%
significance (see Section 2.3 and Figure S4 in Supporting Information S1).

*Panel labels and mean-state cloud condensed water content (g m⁻²) as given in Figure 4:*

| Panel | Model | Cloud condensed water (g m⁻²) | Bimodal (*) |
|---|---|---|---|
| (d) | CMCC-ESM2 | 1.1 | |
| (e) | CMCC-CM2-SR5 | 1.3 | |
| (f) | IPSL-CM6A-LR | 9.5 | |
| (g) | TaiESM1 | 9.6 | |
| (h) | MPI-ESM-1-2-HAM | 15.1 | * |
| (i) | MPI-ESM1-2-LR | 20.9 | * |
| (j) | GFDL-CM4 | 23.3 | |
| (k) | MPI-ESM1-2-HR | 25.2 | * |
| (l) | KIOST-ESM | 27.5 | |
| (m) | EC-Earth3-AerChem | 28.1 | |
| (n) | HadGEM3-GC31-MM | 28.6 | |
| (o) | HadGEM3-GC31-LL | 29.4 | |
| (p) | EC-Earth3 | 29.6 | |
| (q) | EC-Earth3-CC | 30.5 | |
| (r) | MIROC6 | 30.7 | |
| (s) | MRI-ESM2-0 | 33.3 | * |
| (t) | NorESM2-LM | 44.5 | * |
| (u) | GISS-E2-1-G | 47.7 | * |
| (v) | CMCC-CM2-HR4 | 60.8 | |
| (w) | BCC-CSM2-MR | 64.7 | * |

### 3.4 Other Controls on Low-Level Stability

- The observed relationship between near-surface inversions and wind speed is nonlinear, with
  several studies finding transition wind speeds above which the surface inversion strength
  sharply decreases to near zero (Baas et al., 2019; Vignon et al., 2017; Wiel et al., 2017). At
  the larger vertical scale of this analysis such a transition is not apparent (Figures 5a–5c),
  so a linear regression is used as a first-order approximation.
- The three sets of observations show clear and highly statistically significant reductions in
  LLS with faster surface wind speed of **−0.55, −0.67, and −0.63 °C per m s⁻¹** in MOSAiC,
  SHEBA, and NP, respectively, with **R² values of approximately 0.1** in each case. For NP, this
  reduction holds across all stations, and within every individual station.
- CMIP6 models show a diverse set of wind speed–LLS relationships. Several models (e.g.,
  IPSL-CM6A-LR) recreate the observed wind suppression closely, with a slope of approximately
  **−0.6 °C per m s⁻¹** and wind speed accounting for approximately 10% of the variance in LLS.
  However, one model (**BCC-CSM2-MR**) shows a strong and significant *increase* in LLS with wind
  speed, and another (**MRI-ESM2-0**) shows almost no relationship, with **R² less than 0.01**.
- Part of this variation is likely driven by differences in mean-state wind shear among the
  models: an increase in wind-driven atmospheric turbulent heat fluxes is expected with stronger
  wind shear (Chechin et al., 2023), and as a result a stronger suppression of LLS. This
  relationship is seen (not shown) in the NP station data, for which there is a positive
  correlation (significant at 90% confidence) between the mean-state wind shear at a particular
  station and the reduction in stability with wind speed at that station.
- Possible contributors to lack of the cloudy state in some models include synoptic-scale
  meteorology (e.g., not enough moisture flux into the Arctic), column physics/surface-atmosphere
  coupling (e.g., bias in vertical turbulent heat fluxes at the surface), and cloud microphysics
  (e.g., early freezing of supercooled water droplets; Pithan et al., 2014). Figure 6a shows the
  relationship between cloud ice fraction and mean-state LLS: the **positive** relationship
  suggests that freezing of supercooled liquid droplets at excessively warm temperatures — and the
  resulting inability to maintain high-emissivity mixed-phase clouds — may persist in CMIP6 models
  that lack a cloudy state. However, because this is only a correlation across the ensemble, the
  reverse relationship is also possible; models with strong LLS and thus a cold boundary layer may
  see greater condensate freezing.
- Across the CMIP6 ensemble there is a **strong negative relationship between mean-state surface
  upward sensible heat flux and LLS** over sea ice during the winter months (Figure 6b),
  explainable in terms of the stronger downward fluxes expected given a steeper temperature
  gradient. However, as suggested by Pithan et al. (2014), excessive upward heat fluxes from the
  warmer underlying ocean due to overestimated ice and snow conductivity may also contribute to
  reducing LLS in some models.

**Figure 5.** Relationship between low-level stability and surface wind speed during the winter
months (November–March) in each of the three sets of observations (a–c) and the 12 models for which
wind data were available (d–o). Solid lines are linear regressions, and colors are bivariate
histograms with normalized density units (as the total count of points varies between subplots). For
the North Pole drifting stations (NP) (panel c), gray solid lines show the linear regression as
calculated for each individual station. All regressions plotted have a p-value less than 0.001. Panel
(p) shows the values of the slopes of each linear regression. BCC-CSM2-MR, which has a strongly
positive slope, is excluded from (p) and from the CMIP6 distribution shown as a box. For NP, the
distribution of slopes across individual stations is shown as a box.

**Figure 6.** (a) Ratio of atmospheric column cloud ice to atmospheric column condensed water across
the multimodel ensemble in the mean state. (b) Relationship between low-level stability (LLS) and
surface sensible heat flux scaled by the surface wind speed. In both panels, each point represents the
mean of all monthly instances of LLS and each variable for the first ensemble member over the winter
months (November–March) over the sea ice region in a given model over the final two decades of the
historical simulation (1995–2015).

### 3.5 Projected Decline in Low-Level Stability Under Warming

- Section 3.2 showed LLS and near-surface air temperature are negatively correlated in both CMIP6
  models and observations on short timescales from hours to days, such that temperatures aloft at
  850 hPa increase by ~0.5 °C for each 1 °C increase at the surface. Figure S5 demonstrates that this
  linear relationship also applies on climatic timescales in each individual CMIP6 model.
- Over the 250 years of the historical and SSP2-4.5 runs, a significant (*p* > 99%) negative linear
  relationship between winter near-surface air temperature over Arctic sea ice and LLS is found in all
  40 models assessed. In the multimodel mean, there is a decrease in LLS with near-surface warming of
  **−0.6 ± 0.1 °C per °C**, equivalent to an increase in temperature aloft (850 hPa) of **+0.4 °C per
  °C** near-surface warming.
- The 0.4 °C warming aloft per °C surface warming of the multimodel mean (i.e., 2.5 times faster
  warming at the surface than aloft) is a reasonable approximation for the relationship between the
  trends across the full model ensemble (gray dotted line in Figure S6), although it is not the best
  linear fit (the black dashed line), which has a nonzero y-intercept of **0.12 °C per decade** and
  slope of **0.33 °C per °C**.
- Every model tested shows faster surface warming than warming at 850 hPa over the 21st century. In
  each model, therefore, winter LLS declines with the amplified Arctic warming over the 21st century
  under SSP2-4.5. Northward of 75 °N, the multimodel mean LLS declines from **6.9 °C** in the
  preindustrial period to become negative before the end of the 21st century, with the 10-year rolling
  mean crossing the zero line in **2083**.
- The rate of decline in LLS across the observations, of **−0.85 °C per decade**, is nearly twice as
  large as the **−0.45 °C per decade** trend seen in the CMIP6 multimodel mean over the same period.
  Contributions to this difference could include internal variability and the spatial variation in
  observation sites, as well as any model limitations.

**Figure 7.** Time series of the CMIP6 multimodel ensemble projections for (a) high Arctic (>75 °N)
winter near-surface air temperature change and (b) high Arctic (>75 °N) low-level stability. The black
line is the multimodel mean of 10-year centered rolling means, and the shaded region is the 10–90th
percentile range. The colored dots show the mean values in each observational campaign, with smaller
crosses for individual North Pole (NP) stations.

## 4. Discussion and Conclusions

- Radiosondes from the three data sets find mean wintertime LLS over sea ice of between **5 and
  10 °C**, with the large range likely arising at least in part from a decreasing trend in LLS over the
  70-year time span between the campaigns. The CMIP6 multimodel mean LLS over winter sea ice sits within
  this range at **6.6 °C**. However, individual models show a large range of mean states; several models
  have negative LLS and thus fail to show a typically stable winter boundary layer, while several others
  show a mean stability several degrees stronger than the maximum of the observational range. The
  intermodel spread in mean-state stability over winter sea ice for CMIP6 does not show a reduction
  relative to CMIP5 and CMIP3.
- Models with high LLS often lack a cloudy state. This lack of a cloudy state — characterized by
  near-zero net surface longwave flux and weaker, elevated inversions, reported by Pithan et al. (2014)
  for CMIP5 — still applies for a majority of models in this newer CMIP6 generation. **Improvements in
  mixed-phase cloud microphysics are still necessary** for model development toward accurate simulation
  of the Arctic winter atmosphere.
- Despite this, for the most part CMIP6 models qualitatively capture the local processes driving
  variation in LLS. All models assessed reproduce the observed negative linear relationship between
  near-surface air temperature and LLS in the Arctic winter over sea ice, with approximately a **0.5 °C
  decrease in LLS per °C warming at the surface**. Suppression of stability with greater surface winds is
  also found in the CMIP6 models, albeit less consistently. Both the NP drifting stations and the CMIP6
  models show greater wind suppression with increased wind shear. The negative linear relationship
  between near-surface air temperature and LLS also holds on centennial timescales in the CMIP6 models,
  due to surface-dominant Arctic warming.
- Limitations: remote drivers of variation in LLS (moisture and heat fluxes into the Arctic) are not
  considered. Only free-running CMIP6 model simulations are used, restricting the study to a
  qualitative, process-orientated approach (e.g., Eyring et al., 2005). "Nudged" model runs (e.g.,
  Pithan et al., 2023) would allow more direct comparison of model outputs against observations on a
  given day and location. The assessment of model performance is necessarily limited by the extent of
  observations; higher spatial and temporal resolution of central Arctic observations during winter would
  allow a more quantitative comparison.
- As the Arctic warms, the multimodel CMIP6 mean shows winter LLS decreasing to zero in the central
  Arctic before the end of the century under SSP2-4.5. Accurate representation of the less-stable cloudy
  state may become increasingly important for near-term projections of Arctic climate change under
  increasing warming. This transition away from a typically stably stratified wintertime boundary layer
  marks yet another profound shift in Arctic climate projected to occur in the coming decades.

## Data Availability Statement

All data used in this work are publicly available. CMIP6 data: Earth System Grid Federation CMIP6
archive (https://esgf-index1.ceda.ac.uk/search/cmip6-ceda/). North Pole drifting stations observations:
NSIDC (Colony & Thorndike, 1984). MOSAiC data: Pangea (Maturilli et al., 2021); MOSAiC tower radiation
data (Reynolds & Riihimaki, 2019) from https://www.arm.gov. SHEBA data:
https://atmos.uw.edu/~roode/SHEBA.html. Analysis and plotting code on Zenodo at
https://zenodo.org/records/13763472 (Duffey, 2024).

## References

Baas, P., van de Wiel, B. J. H., van Meijgaard, E., Vignon, E., Genthon, C., van der Linden, S. J. A.,
& de Roode, S. R. (2019). Transitions in the wintertime near-surface temperature inversion at Dome C,
Antarctica. *Q. J. R. Meteorol. Soc.*, 145(720), 930–946. https://doi.org/10.1002/qj.3450

Beesley, J. A., Bretherton, C. S., Jakob, C., Andreas, E. L., Intrieri, J. M., & Uttal, T. A. (2000). A
comparison of cloud and boundary layer variables in the ECMWF forecast model with observations at Surface
Heat Budget of the Arctic Ocean (SHEBA) ice camp. *J. Geophys. Res.*, 105(D10), 12337–12349.
https://doi.org/10.1029/2000JD900079

Bintanja, R., Graversen, R. G., & Hazeleger, W. (2011). Arctic winter warming amplified by the thermal
inversion and consequent low infrared cooling to space. *Nat. Geosci.*, 4(11), 758–761.
https://doi.org/10.1038/ngeo1285

Blackport, R., & Screen, J. A. (2020). Weakened evidence for mid-latitude impacts of Arctic warming.
*Nat. Clim. Change*, 10(12), 1065–1066. https://doi.org/10.1038/s41558-020-00954-y

Boeke, R. C., Taylor, P. C., & Sejas, S. A. (2021). On the nature of the Arctic's positive lapse-rate
feedback. *Geophys. Res. Lett.*, 48(1), e2020GL091109. https://doi.org/10.1029/2020GL091109

Bretherton, C. S., de Roode, S. R., Jakob, C., Andreas, E. L., Intrieri, J., & Persson, P. O. G. (1999).
A comparison of the ECMWF forecast model with observations over the annual cycle at SHEBA. *J. Geophys.
Res.* (FIRE Arctic Clouds Experiment Special Issue).

Cai, Z., You, Q., Chen, H. W., Zhang, R., Chen, D., Chen, J., et al. (2022). Amplified wintertime Barents
Sea warming linked to intensified Barents oscillation. *Environ. Res. Lett.*, 17(4), 044068.
https://doi.org/10.1088/1748-9326/ac5bb3

Chechin, D. G., Lüpkes, C., Hartmann, J., Ehrlich, A., & Wendisch, M. (2023). Turbulent structure of the
Arctic boundary layer in early summer driven by stability, wind shear and cloud-top radiative cooling:
ACLOUD airborne observations. *Atmos. Chem. Phys.*, 23(15), 4685–4707.
https://doi.org/10.5194/acp-23-4685-2023

Chechin, D. G., Makhotina, I. A., Lüpkes, C., & Makshtas, A. P. (2019). Effect of wind speed and leads on
clear-sky cooling over Arctic sea ice during polar night. *J. Atmos. Sci.*, 76(8), 2481–2503.
https://doi.org/10.1175/JAS-D-18-0277.1

Chylek, P., Folland, C., Klett, J. D., Wang, M., Hengartner, N., Lesins, G., & Dubey, M. K. (2022). Annual
mean Arctic amplification 1970–2020: Observed and simulated by CMIP6 climate models. *Geophys. Res. Lett.*,
49(13), e2022GL099371. https://doi.org/10.1029/2022GL099371

Cohen, J., Screen, J. A., Furtado, J. C., Barlow, M., Whittleston, D., Coumou, D., et al. (2014). Recent
Arctic amplification and extreme mid-latitude weather. *Nat. Geosci.*, 7(9), 627–637.
https://doi.org/10.1038/ngeo2234

Cohen, J., Zhang, X., Francis, J., Jung, T., Kwok, R., Overland, J., et al. (2020). Divergent consensuses
on Arctic amplification influence on midlatitude severe winter weather. *Nat. Clim. Change*, 10(1), 20–29.
https://doi.org/10.1038/s41558-019-0662-y

Colony, R., & Thorndike, A. S. (1984). *Arctic Ocean drift tracks from ships, buoys, and manned research
stations, 1872–1973, version 1*. NSIDC. https://doi.org/10.7265/N5D798B1

Comyn-Platt, E., Hayman, G., Huntingford, C., Chadburn, S. E., Burke, E. J., Harper, A. B., et al. (2018).
Carbon budgets for 1.5 and 2 °C targets lowered by natural wetland and permafrost feedbacks. *Nat. Geosci.*,
11(8), 568–573. https://doi.org/10.1038/s41561-018-0174-9

Duffey, A. (2024). alistairduffey/ABL_cmip6:v1. *Zenodo*. https://doi.org/10.5281/zenodo.13763472

Duffey, A., Mallett, R., Irvine, P. J., Tsamados, M., & Stroeve, J. (2023). ESD Ideas: Arctic
amplification's contribution to breaches of the Paris Agreement. *Earth Syst. Dyn.*, 14(6), 1165–1169.
https://doi.org/10.5194/esd-14-1165-2023

England, M. R., Eisenman, I., Lutsko, N. J., & Wagner, T. J. W. (2021). The recent emergence of Arctic
amplification. *Geophys. Res. Lett.*, 48(15), e2021GL094086. https://doi.org/10.1029/2021GL094086

Eyring, V., Bony, S., Meehl, G. A., Senior, C. A., Stevens, B., Stouffer, R. J., & Taylor, K. E. (2016).
Overview of the Coupled Model Intercomparison Project Phase 6 (CMIP6) experimental design and organization.
*Geosci. Model Dev.*, 9(5), 1937–1958. https://doi.org/10.5194/gmd-9-1937-2016

Eyring, V., Harris, N. R. P., Rex, M., Shepherd, T. G., Fahey, D. W., Amanatidis, G. T., et al. (2005). A
strategy for process-oriented validation of coupled chemistry–climate models. *Bull. Am. Meteorol. Soc.*,
86(8), 1117–1134. https://doi.org/10.1175/BAMS-86-8-1117

Feldl, N., Po-Chedley, S., Singh, H. K. A., Hay, S., & Kushner, P. J. (2020). Sea ice and atmospheric
circulation shape the high-latitude lapse rate feedback. *npj Clim. Atmos. Sci.*, 3(1), 1–9.
https://doi.org/10.1038/s41612-020-00146-7

Fetterer, F., Knowles, K., Meier, W. N., Savoie, M., & Windnagel, A. K. (2017). *Sea ice index, version 3*.
NSIDC. https://doi.org/10.7265/N5K072F8

Gettelman, A., Hannay, C., Bacmeister, J. T., Neale, R. B., Pendergrass, A. G., Danabasoglu, G., et al.
(2019). High climate sensitivity in the Community Earth System Model version 2 (CESM2). *Geophys. Res.
Lett.*, 46(14), 8329–8337. https://doi.org/10.1029/2019GL083978

Goosse, H., Kay, J. E., Armour, K. C., Bodas-Salcedo, A., Chepfer, H., Docquier, D., et al. (2018).
Quantifying climate feedbacks in polar regions. *Nat. Commun.*, 9(1), 1919.
https://doi.org/10.1038/s41467-018-04173-0

Hahn, L. C., Armour, K. C., Zelinka, M. D., Bitz, C. M., & Donohoe, A. (2021). Contributions to polar
amplification in CMIP5 and CMIP6 models. *Front. Earth Sci.*, 9, 710036.
https://doi.org/10.3389/feart.2021.710036

Hansen, J., Sato, M., & Ruedy, R. (1997). Radiative forcing and climate response. *J. Geophys. Res.*,
102(D6), 6831–6864. https://doi.org/10.1029/96JD03436

Hartigan, J. A., & Hartigan, P. M. (1985). The dip test of unimodality. *Ann. Stat.*, 13(1), 70–84.
https://doi.org/10.1214/aos/1176346577

Hartigan, P. M. (1985). Computation of the dip statistic to test for unimodality. *J. R. Stat. Soc. Ser. C
(Appl. Stat.)*, 34(3), 320–325. https://doi.org/10.2307/2347485

Hausfather, Z., & Peters, G. P. (2020). RCP8.5 is a problematic scenario for near-term emissions. *Proc.
Natl. Acad. Sci.*, 117(45), 27791–27792. https://doi.org/10.1073/pnas.2017124117

Henry, M., Merlis, T. M., Lutsko, N. J., & Rose, B. E. J. (2021). Decomposing the drivers of polar
amplification with a single-column model. *J. Clim.*, 34(6), 2355–2365.
https://doi.org/10.1175/JCLI-D-20-0178.1

Horton, D. E., Johnson, N. C., Singh, D., Swain, D. L., Rajaratnam, B., & Diffenbaugh, N. S. (2015).
Contribution of changes in atmospheric circulation patterns to extreme temperature trends. *Nature*,
522(7557), 465–469. https://doi.org/10.1038/nature14550

Inoue, J., Sato, K., Rinke, A., Cassano, J. J., Fettweis, X., Heinemann, G., et al. (2021). Clouds and
radiation processes in regional climate models evaluated using observations over the ice-free Arctic Ocean.
*J. Geophys. Res. Atmos.*, 126(11), e2020JD033904. https://doi.org/10.1029/2020JD033904

Kahl, J. D. W., Zaitseva, N. A., Khattatov, V., Schnell, R. C., Bacon, D. M., Bacon, J., et al. (1999).
Radiosonde observations from the former Soviet "North Pole" series of drifting ice stations, 1954–90. *Bull.
Am. Meteorol. Soc.*, 80(10), 2019–2026.
https://doi.org/10.1175/1520-0477(1999)080<2019:rofts>2.0.co;2

Krumpen, T., von Albedyll, L., Goessling, H. F., Hendricks, S., Juhls, B., Spreen, G., et al. (2021).
MOSAiC drift expedition from October 2019 to July 2020: Sea ice conditions from space and comparison with
previous years. *The Cryosphere*, 15(8), 3897–3920. https://doi.org/10.5194/tc-15-3897-2021

Liu, Y., Key, J. R., Schweiger, A., & Francis, J. (2006). Characteristics of satellite-derived clear-sky
atmospheric temperature inversion strength in the Arctic, 1980–96. *J. Clim.*, 19(19), 4902–4913.
https://doi.org/10.1175/JCLI3915.1

Lu, J., & Cai, M. (2010). Quantifying contributions to polar warming amplification in an idealized coupled
general circulation model. *Clim. Dyn.*, 34(5), 669–687. https://doi.org/10.1007/s00382-009-0673-x

Maechler, M. (2024). diptest: Hartigan's Dip test for unimodality. https://github.com/mmaechler/diptest

Manabe, S., & Wetherald, R. T. (1975). The effects of doubling the CO₂ concentration on the climate of a
general circulation model. *J. Atmos. Sci.*, 32(1), 3–15.
https://doi.org/10.1175/1520-0469(1975)032<0003:TEODTC>2.0.CO;2

Maturilli, M., Holdridge, D. J., Dahlke, S., Graeser, J., Sommerfeld, A., Jaiser, R., et al. (2021).
Initial radiosonde data from 2019-10 to 2020-09 during project MOSAiC. *PANGAEA*.
https://doi.org/10.1594/PANGAEA.928656

Medeiros, B., Deser, C., Tomas, R. A., & Kay, J. E. (2011). Arctic inversion strength in climate models.
*J. Clim.*, 24(17), 4733–4740. https://doi.org/10.1175/2011JCLI3968.1

Pattyn, F., Ritz, C., Hanna, E., Asay-Davis, X., DeConto, R., Durand, G., et al. (2018). The Greenland and
Antarctic ice sheets under 1.5 °C global warming. *Nat. Clim. Change*, 8(12), 1053–1061.
https://doi.org/10.1038/s41558-018-0305-8

Peng, S., Yang, Q., Shupe, M. D., Xi, X., Han, B., Chen, D., et al. (2023). The characteristics of
atmospheric boundary layer height over the Arctic Ocean during MOSAiC. *Atmos. Chem. Phys.*, 23(15),
8683–8703. https://doi.org/10.5194/acp-23-8683-2023

Perovich, D. K., Grenfell, T. C., Richter-Menge, J. A., Light, B., Tucker, III, W. B., & Eicken, H. (2003).
Thin and thinner: Sea ice mass balance measurements during SHEBA. *J. Geophys. Res.*, 108(C3), 8050.
https://doi.org/10.1029/2001JC001079

Persson, P. O. G., Fairall, C. W., Andreas, E. L., Guest, P. S., & Perovich, D. K. (2002). Measurements
near the atmospheric surface flux group tower at SHEBA: Near-surface conditions and surface energy budget.
*J. Geophys. Res.*, 107(C10), 21. https://doi.org/10.1029/2000JC000705

Pistone, K., Eisenman, I., & Ramanathan, V. (2014). Observational determination of albedo decrease caused
by vanishing Arctic sea ice. *Proc. Natl. Acad. Sci.*, 111(9), 3322–3326.
https://doi.org/10.1073/pnas.1318201111

Pithan, F., Ackerman, A., Angevine, W. M., Hartung, K., Ickes, L., Kelley, M., et al. (2016). Select
strengths and biases of models in representing the Arctic winter boundary layer over sea ice: The Larcform 1
single column model intercomparison. *J. Adv. Model. Earth Syst.*, 8(3), 1345–1357.
https://doi.org/10.1002/2016MS000630

Pithan, F., Athanase, M., Dahlke, S., Sánchez-Benítez, A., Shupe, M. D., Sledd, A., et al. (2023). Nudging
allows direct evaluation of coupled climate models with in situ observations: A case study from the MOSAiC
expedition. *Geosci. Model Dev.*, 16(7), 1857–1873. https://doi.org/10.5194/gmd-16-1857-2023

Pithan, F., & Mauritsen, T. (2014). Arctic amplification dominated by temperature feedbacks in contemporary
climate models. *Nat. Geosci.*, 7(3), 181–184. https://doi.org/10.1038/ngeo2071

Pithan, F., Medeiros, B., & Mauritsen, T. (2014). Mixed-phase clouds cause climate model biases in Arctic
wintertime temperature inversions. *Clim. Dyn.*, 43(1), 289–303.
https://doi.org/10.1007/s00382-013-1964-9

Previdi, M., Smith, K. L., & Polvani, L. M. (2021). Arctic amplification of climate change: A review of
underlying mechanisms. *Environ. Res. Lett.*, 16(9), 093003. https://doi.org/10.1088/1748-9326/ac1c29

Rantanen, M., Karpechko, A. Y., Lipponen, A., Nordling, K., Hyvärinen, O., Ruosteenoja, K., et al. (2022).
The Arctic has warmed nearly four times faster than the globe since 1979. *Commun. Earth Environ.*, 3(1),
1–10. https://doi.org/10.1038/s43247-022-00498-3

Reynolds, R., & Riihimaki, L. (2019). Arm: Iceradl. https://doi.org/10.5439/1608608

Saavedra Garfias, P., Kalesse-Los, H., von Albedyll, L., Griesche, H., & Spreen, G. (2023). Asymmetries in
cloud microphysical properties ascribed to sea ice leads via water vapour transport in the central Arctic.
*Atmos. Chem. Phys.*, 23(22), 14521–14546. https://doi.org/10.5194/acp-23-14521-2023

Sedlar, J., Tjernström, M., Rinke, A., Orr, A., Cassano, J., Fettweis, X., et al. (2020). Confronting
Arctic troposphere, clouds, and surface energy budget representations in regional climate models with
observations. *J. Geophys. Res. Atmos.*, 125(6), e2019JD031783. https://doi.org/10.1029/2019JD031783

Serreze, M. C., Barrett, A. P., Stroeve, J. C., Kindig, D. N., & Holland, M. M. (2009). The emergence of
surface-based Arctic amplification. *The Cryosphere*, 3(1), 11–19. https://doi.org/10.5194/tc-3-11-2009

Serreze, M. C., & Francis, J. A. (2006). The Arctic amplification debate. *Clim. Change*, 76(3), 241–264.
https://doi.org/10.1007/s10584-005-9017-y

Shupe, M. D., Rex, M., Blomquist, B., Persson, P. O. G., Schmale, J., Uttal, T., et al. (2022). Overview of
the MOSAiC expedition: Atmosphere. *Elementa: Sci. Anthropocene*, 10(1), 00060.
https://doi.org/10.1525/elementa.2021.00060

Solomon, A., Shupe, M. D., Svensson, G., Barton, N. P., Batrak, Y., Bazile, E., et al. (2023). The winter
central Arctic surface energy budget: A model evaluation using observations from the MOSAiC campaign.
*Elementa: Sci. Anthropocene*, 11(1), 00104. https://doi.org/10.1525/elementa.2022.00104

Stramler, K., Genio, A. D. D., & Rossow, W. B. (2011). Synoptically driven Arctic winter states. *J. Clim.*,
24(6), 1747–1762. https://doi.org/10.1175/2010JCLI3817.1

Svensson, G., & Karlsson, J. (2011). On the Arctic wintertime climate in global climate models. *J. Clim.*,
24(2), 5757–5771. https://doi.org/10.1175/2011JCLI4012.1

Taylor, P. C., Boeke, R. C., Boisvert, L. N., Feldl, N., Henry, M., Huang, Y., et al. (2022). Process
drivers, inter-model spread, and the path forward: A review of amplified Arctic warming. *Front. Earth Sci.*,
9, 758361. https://doi.org/10.3389/feart.2021.758361

Tjernström, M., Sedlar, J., & Shupe, M. D. (2008). How well do regional climate models reproduce radiation
and clouds in the Arctic? An evaluation of ARCMIP simulations. *J. Appl. Meteorol. Climatol.*, 47(9),
2405–2422. https://doi.org/10.1175/2008JAMC1845.1

Uttal, T., Curry, J. A., McPhee, M. G., Perovich, D. K., Moritz, R. E., Maslanik, J. A., et al. (2002).
Surface heat budget of the Arctic Ocean. *Bull. Am. Meteorol. Soc.*, 83(2), 255–276.
https://doi.org/10.1175/1520-0493(1936)064<0122:CITLAA>2.0.CO;2 [as printed]

Vignon, E., van de Wiel, B. J. H., van Hooijdonk, I. G. S., Genthon, C., van der Linden, S. J. A., van
Hooft, J. A., et al. (2017). Stable boundary-layer regimes at Dome C, Antarctica: Observation and analysis.
*Q. J. R. Meteorol. Soc.*, 143(704), 1241–1253. https://doi.org/10.1002/qj.2998

Walsh, W. L. C. F. F. J. E., & Stewart, J. S. (2019). *Gridded monthly sea ice extent and concentration,
1850 onward. Version 2*. NSIDC. https://doi.org/10.7265/jj4s-tq79

Wexler, H. (1936). Cooling in the lower atmosphere and the structure of polar continental air. *Mon. Weather
Rev.*, 64(4), 122–136. https://doi.org/10.1175/1520-0493(1936)064<0122:CITLAA>2.0.CO;2

Wiel, B. J. H. V. D., Vignon, E., Baas, P., Hooijdonk, I. G. S. V., Linden, S. J. A. V. D., Hooft, J. A. V.,
et al. (2017). Regime transitions in near-surface temperature inversions: A conceptual model. *J. Atmos.
Sci.*, 74(4), 1057–1073. https://doi.org/10.1175/JAS-D-16-0180.1

Woods, C., & Caballero, R. (2016). The role of moist intrusions in winter Arctic warming and sea ice decline.
*J. Clim.*, 29(12), 4473–4485. https://doi.org/10.1175/JCLI-D-15-0773.1

Woods, C., Caballero, R., & Svensson, G. (2013). Large-scale circulation associated with moisture intrusions
into the Arctic during winter. *Geophys. Res. Lett.*, 40(17), 4717–4721. https://doi.org/10.1002/grl.50912

Zhang, R., & Screen, J. A. (2021). Diverse Eurasian winter temperature responses to barents-Kara Sea ice
anomalies of different magnitudes and seasonality. *Geophys. Res. Lett.*, 48(13), e2021GL092726.
https://doi.org/10.1029/2021GL092726

Zhang, R., Screen, J. A., & Zhang, R. (2022). Arctic and Pacific Ocean conditions were favorable for cold
extremes over Eurasia and North America during winter 2020/21. *Bull. Am. Meteorol. Soc.*, 103(10),
E2285–E2301. https://doi.org/10.1175/BAMS-D-21-0264.1
