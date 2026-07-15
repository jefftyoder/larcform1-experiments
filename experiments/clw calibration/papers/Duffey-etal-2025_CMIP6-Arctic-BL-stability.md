# Representation of Arctic Winter Atmospheric Boundary Layer Stability Over Sea Ice in CMIP6 Models

Duffey, A., R. Mallett, V. R. Dutch, J. Steckling, A. Hermant, J. Day, and F. Pithan (2025),
*Journal of Geophysical Research: Atmospheres*, 130, e2024JD041412,
doi:10.1029/2024JD041412.
Received 19 Apr 2024; accepted 23 May 2025. Open access (CC BY).
Analysis code: https://zenodo.org/records/13763472 (Duffey, 2024).
Affiliations: ¹UCL Centre for Polar Observation and Modelling; ²UiT The Arctic University
of Norway; ³Northumbria University; ⁴University of East Anglia; ⁵Universität Hamburg;
⁶Bjerknes Centre / University of Bergen; ⁷⁸University of Bern & Oeschger Centre; ⁹ECMWF;
¹⁰Alfred Wegener Institute, Bremerhaven.

> **Note on this file:** re-transcribed 2026-07-14 from the source PDF
> (`~/Zotero/storage/BVQ3DTLE/`), replacing an earlier automated PDF text dump
> (recoverable in git history). Tables, equations, and figure captions are
> verbatim; running prose is a faithful condensed rendering, not a word-for-word
> copy — consult the PDF for exact wording.

**Key points**
- A cloudy state, without strong low-level stability (LLS), is often observed over winter
  Arctic sea ice but is absent in most Coupled Model Intercomparison Project (CMIP6) models
- CMIP6 models show a realistic representation of the dependence of LLS on near-surface
  air temperature and wind speed
- Observations show a decreasing trend in Arctic winter LLS, which CMIP6 models project
  will continue under warming

## Abstract (condensed)

The Arctic winter boundary layer often features strong, persistent low-level stability
(LLS) from longwave radiative cooling of the surface during polar night; this stable
stratification drives a positive lapse-rate feedback, a major contributor to Arctic
amplification. A second state — cloudy conditions, weaker stability, near-zero net surface
longwave flux — is also observed. Many CMIP5 models failed to appropriately partition
water between liquid and ice phases in mixed-phase clouds and therefore lacked the cloudy
state. This study assesses the Arctic winter boundary layer over sea ice in CMIP6 models
against surface-based and radiosonde observations from MOSAiC (2019–2020), SHEBA
(1997–1998), and the North Pole drifting stations (1955–1991). The majority of CMIP6
models fail to realistically represent the cloudy state over winter Arctic sea ice.
Despite this, the CMIP6 multimodel mean LLS falls within the observational range, and
models mostly capture the observed dependence of LLS on near-surface air temperature and
wind speed. CMIP6 models predict a decline in winter LLS with Arctic warming, with mean
stability falling below zero by 2100 under the SSP2-4.5 scenario. The failure to
accurately simulate mixed-phase clouds is an important limitation on representing a
realistic Arctic winter boundary layer in many CMIP6 models.

## Plain Language Summary (condensed)

In Arctic winter the boundary layer is often coldest nearest the surface (stable
stratification), part of the explanation for the much more rapid warming of the Arctic
(Arctic amplification). Comparing the winter Arctic boundary layer in climate models
against MOSAiC, SHEBA, and the often-underexploited North Pole drifting-station
observations shows that cloudy conditions are underrepresented in many models, though
models mostly succeed in representing how stability varies with temperature and wind
speed. As the Arctic warms, low-level stability is expected to decrease; models project
that the stable state will no longer be dominant in Arctic winter before the end of the
century under a medium emissions scenario.

## 1. Introduction

- The Arctic is warming roughly four times faster than the global average (Chylek et al.
  2022; England et al. 2021; Rantanen et al. 2022) — Arctic amplification (Previdi et al.
  2021; Serreze & Francis 2006; Serreze et al. 2009; Taylor et al. 2022). Late-summer sea
  ice extent has declined by 50% in 40 years (Fetterer et al. 2017, updated 2023).
  Additional warming from Arctic amplification accounts for ~5 years' difference in the
  expected crossing date for the Paris agreement's 1.5 °C threshold (Duffey et al. 2023).
  Other consequences: increased global warming via the albedo feedback (Pistone et al.
  2014), Greenland ice-sheet mass loss (Pattyn et al. 2018), increased greenhouse-gas
  burden from decomposing organic matter in thawed permafrost (Comyn-Platt et al. 2018),
  and potentially — but controversially — increased frequency of Northern Hemisphere
  midlatitude extreme weather (Cohen et al. 2014, 2020; Blackport & Screen 2020; Horton
  et al. 2015; Zhang & Screen 2021; Zhang et al. 2022).
- Arctic amplification drivers: the weaker (negative) Arctic Planck feedback, increasing
  solar absorption with declining reflective snow and ice, atmospheric heat transport
  (e.g., Cai et al. 2022), and the latitudinal variation in deviation from vertically
  uniform warming (Goosse et al. 2018; Henry et al. 2021; Pithan & Mauritsen 2014; Taylor
  et al. 2022). The last — the lapse-rate feedback — arises because Arctic warming is more
  strongly confined near the surface than at lower latitudes, and is one of the largest
  contributors to Arctic amplification in climate models (Goosse et al. 2018; Hahn et al.
  2021; Lu & Cai 2010). This contrasts with the tropics, where convection restores the
  profile close to the moist adiabat and the lapse-rate feedback is negative (Hansen et
  al. 1997).
- Amplified Arctic warming is strongest in late autumn and winter (Rantanen et al. 2022;
  Taylor et al. 2022). Winter LLS arises from longwave radiative cooling of the surface
  leading to temperature inversions (Boeke et al. 2021; Wexler 1936). This stratification
  concentrates warming near the surface (Manabe & Wetherald 1975) → positive local
  lapse-rate feedback (Bintanja et al. 2011; Boeke et al. 2021). Sea-ice retreat and
  atmospheric circulation also contribute to the surface-dominant warming profile (Feldl
  et al. 2020).
- Accurate LLS simulation has been hampered by persistent model biases (Inoue et al. 2021;
  Pithan et al. 2016; Sedlar et al. 2020; Solomon et al. 2023; Tjernström et al. 2008).
  In CMIP5, biases in mixed-phase-cloud liquid/ice partitioning impacted modeled LLS
  (Pithan et al. 2014); similar biases exist in NWP models (Solomon et al. 2023),
  regional climate models (Inoue et al. 2021; Sedlar et al. 2020), and CMIP3 (Svensson &
  Karlsson 2011). Since CMIP5, modeling centers have increased vertical resolution and
  changed convection and microphysics schemes (e.g., Gettelman et al. 2019), but the
  extent of these biases in CMIP6 had not been assessed.
- Two winter boundary-layer states (Persson et al. 2002; Stramler et al. 2011): a
  **"clear" state** with strong longwave surface cooling (≳50 W m⁻²) under a lower
  atmosphere relatively transparent to outgoing radiation, and a **"cloudy" state** with
  surface net longwave close to zero under opaque low-level mixed-phase clouds. The modes
  have distinct vertical temperature structures — stronger atmospheric inversions in the
  clear state, weaker inversions found further aloft under the cloudy state (Stramler et
  al. 2011). This bimodality in LLS is found in the CMIP5 ensemble (Pithan et al. 2014),
  but few CMIP5 models showed a realistic cloudy state, in part due to freezing of
  supercooled water droplets at excessively warm temperatures, preventing formation of
  mixed-phase clouds with high emissivity. Wind speed and shear are additional potential
  bias sources: higher near-surface wind speeds are associated with increased
  near-surface air temperature and reduced near-surface inversion strength over Arctic
  sea ice, because increased turbulent heat fluxes under high wind and shear prevent
  strong stability (Chechin et al. 2019, 2023; Wiel et al. 2017).
- This study assesses Arctic winter LLS over sea ice and the processes controlling it in
  the CMIP6 ensemble (Eyring et al. 2016) against MOSAiC (Shupe et al. 2022), SHEBA
  (Uttal et al. 2002), and 21 North Pole (NP) drifting stations 1954–1990 (Kahl et al.
  1999), building on the CMIP5-vs-SHEBA assessment of Pithan et al. (2014). Sequence:
  mean-state LLS; distribution of clear/cloudy states via net surface longwave;
  controlling processes (near-surface temperature, surface winds); future projections of
  LLS and its contribution to Arctic amplification.

## 2. Data and Methods

### 2.1 CMIP6 Data

- Ensemble defined by data availability on the UK CEDA archive (Table S1 in Supporting
  Information S1 lists all models and DOIs). Monthly resolution: 45 CMIP6 models. Cloud
  water content and surface heat flux analysis (Figure 6): 37 models had the required
  data. Future projections under SSP2-4.5 (Section 3.5): a slightly different set (Tables
  S1 and S2). High-time-resolution data (6-hourly and daily): a 20-model subset. First
  ensemble member only.
- Periods: final 20 years of the historical scenario (1995–2015) for monthly outputs
  (Figure 1); final 5 years (2010–2015) for daily and subdaily outputs (Figures 2–5).
- Domain: extended winter (November–March, inclusive) sea-ice domain — each model's
  monthly sea-ice concentration regridded onto that model's atmospheric grid (bilinear
  interpolation), then a time-varying sea-ice mask keeps only grid points with >95%
  sea-ice concentration in a given month.
- Future trends: one emissions scenario only, SSP2-4.5 (Eyring et al. 2016) — a medium
  emissions scenario broadly in line with current global emissions mitigation policies
  (Hausfather & Peters 2020).

### 2.2 Observational Data

- **MOSAiC** (Oct 2019–Oct 2020): radiosonde data from Maturilli et al. (2021) and ARM
  tower radiation data (Reynolds & Riihimaki 2019). Sondes generally launched 4×/day,
  more during exceptional weather events (Peng et al. 2023) — nonuniform sampling is
  accounted for in reported means (Section 2.3). 340 winter atmospheric profiles analyzed.
- **SHEBA** (Oct 1997–Oct 1998): radiosonde and surface radiative flux data (Uttal et al.
  2002; detail in Persson et al. 2002; Beesley et al. 2000; Bretherton et al. 1999;
  https://atmos.uw.edu/~roode/SHEBA.html). Sondes generally 2×/day in winter → 276 valid
  winter atmospheric profiles.
- **North Pole drifting stations (NP)** (Kahl et al. 1999), operated 1954–1991. Of the 31
  stations in the period, the archive at the US National Snow and Ice Data Centre lacks
  usable observations from stations 1, 2, 18, 20, 23, 24, 25, 27, 29, and 30; the
  remaining 21 stations give 6,999 valid winter atmospheric profiles.
- Combined: more than 7,500 winter radiosondes, of which 593 (from MOSAiC and SHEBA)
  match contemporaneous (within 5 min) surface radiative flux measurements. Ice
  conditions varied widely: the MOSAiC icebreaker was surrounded by a loose assemblage of
  second-year ice (Krumpen et al. 2021), SHEBA by multiyear ice (Perovich et al. 2003).
  Though sparse in time and space, the observations cover much of the Arctic Ocean domain
  over nearly 70 years; the NP stations also give valuable insight into interannual
  variability.

**Figure 1.** Location of winter (November-March) radiosonde observations used in this
study, from the MOSAiC (2019–2020) and SHEBA (1997–1998) campaigns, and from the North
Pole drifting stations (NP) (1954–1990). The Arctic Ocean shading shows the mean winter
sea-ice concentration over the period 1950–2020 (Walsh & Stewart, 2019). The NP (MOSAiC
region) and NP (SHEBA region) points, refer, respectively, to subsets of the NP data that
lie within 300 km of an observation from the MOSAiC and SHEBA campaigns.

### 2.3 Methods

- The analysis focuses on relationships between model variables over all model data
  points in time and space during winter over sea ice — not on matching model mean states
  to observed campaign means, because the observations have different regional samplings,
  represent single years (SHEBA, MOSAiC) or years with much reduced greenhouse-gas
  forcing (NP), and are instantaneous point values versus model time-step grid-cell means.
- Where mean states are compared (e.g., Figure 2), inconstant temporal sampling is
  handled in two steps: (a) group individual sonde observations by date, so the mean is
  not biased toward days with additional launches (most impactful for MOSAiC; Peng et al.
  2023); (b) group observational data by month, then take the full winter mean. Quoted
  observational "mean" values are temporally representative winter-season values, not
  simple means of all winter observations.
- **Bimodality metric**: Hartigan's "Dip" test (J. A. Hartigan & Hartigan 1985; P. M.
  Hartigan 1985), implemented via a Python port of the R package "diptest" (Maechler
  2024) — a statistical test of whether a unimodal or multimodal distribution better fits
  the data. A model is "bimodal" in surface net longwave radiation when the test rejects
  the null hypothesis of unimodality at the 95% significance level.
- **Bulk LLS** (following Medeiros et al. 2011 and Pithan et al. 2014): the difference
  between the 850-hPa temperature and the near-surface (2 m) air temperature — a proxy
  for the temperature inversion, positive when the temperature is warmer aloft. Useful
  given the low and variable vertical resolution of CMIP6 models, which complicates
  direct comparison to radiosonde profiles.
- **Wind suppression of LLS**: surface wind speeds of individual sondes paired with the
  LLS observed by the same sondes → 189, 341, and 7,753 paired data points from MOSAiC,
  SHEBA, and NP respectively (NP surface winds recorded only to the nearest m s⁻¹). Both
  the strength and gradient of the observed LLS–wind relationships are compared to CMIP6.

## 3. Results

### 3.1 Mean-State Low-Level Stability

- Mean winter LLS over Arctic sea ice: **MOSAiC 5.0 ± 0.3 °C, SHEBA 8.3 ± 0.4 °C, NP
  9.5 ± 0.1 °C** (errors are standard errors of the mean), accounting for uneven temporal
  sampling (Section 2.3).
- The three campaigns sampled different locations — weaker mean stability is expected in
  the Atlantic-sector MOSAiC than the Beaufort Gyre SHEBA (Liu et al. 2006). To estimate
  the impact of regional sampling, NP subsets within 300 km of MOSAiC and SHEBA
  observations are used (Figure 1); the 300 km threshold samples the same Arctic sector
  (separating the Pacific and Atlantic sectors, which differ in synoptic activity
  including warm/moist-air advection; Woods et al. 2013) while retaining reasonable
  sample sizes. NP stations within 300 km of MOSAiC: mean LLS **9.3 ± 0.1 °C** — lower
  than the full NP mean by only 0.2 °C, versus the 4.5 °C MOSAiC-vs-NP difference. NP
  stations within 300 km of SHEBA: **9.3 ± 0.3 °C**, again closer to the full NP mean
  than to SHEBA. Regional sampling therefore explains only a small fraction of the
  variation in observed LLS.
- Other contributors: interannual variability (SHEBA and MOSAiC each represent a single
  winter) and any long-term trend over 1950–2020. Standard deviation of the per-station
  NP mean LLS values is **0.94 °C** (a rough estimate of interannual variability);
  minimum station mean is **7.6 °C**. The three data sets show a chronological reduction
  in LLS (earliest = NP = strongest). Because the MOSAiC mean is well outside the NP
  station range, the decrease likely represents a wider Arctic trend — as expected given
  the clear negative trend under warming in the CMIP6 ensemble (Section 3.5).
- **CMIP6 multimodel mean winter LLS over sea ice = 6.6 °C** (final two decades of the
  historical simulation, 1995–2015) — within the 5–10 °C range of the observational
  means. Two models of 45 (CESM2-WACCM-FV2 and E3SM-1-0) show negative mean winter LLS
  over sea ice. Mean-state near-surface and 850-hPa temperatures per model: Figure S2.
  Most models strongly differentiate open ocean vs sea ice, with no LLS over open ocean
  in the monthly mean (Figure S1); only 3 of 45 (GISS-E2-1-H, GISS-E2-2-H, NorCPM1) have
  positive winter mean-state LLS over open ocean north of 65°N.
- Intermodel spread: standard deviation **3.3 °C**; range between most and least stable
  models **14.0 °C**. Pithan et al. (2014) show similar CMIP5 values — 2.8 °C and 11.4 °C
  (read from their Figure 4) — for a slightly different quantity (stable-mode LLS,
  "sea-ice" region defined over the ocean, November–February). Medeiros et al. (2011)
  show (read from their Figure 3) a standard deviation of 3.1 °C and range ~10.9 °C for
  stable-mode LLS across CMIP3. **No substantial reduction in intermodel spread of
  mean-state winter sea-ice LLS between CMIP3, CMIP5, and CMIP6.**

**Figure 2.** (a) Distribution of winter low-level stability (LLS) over Arctic sea ice
(>95% concentration) in CMIP6 models (gray) and field campaigns (colors). LLS is defined
as the difference between temperature at 850 hPa and the 2-m air temperature. The bold
black line is the multimodel distribution. For all models, the distribution shown is over
all grid points in time and space where sea ice concentration is greater than 95%, over
the period 1995–2015, and the region north of 65°N. Vertical dashed lines denote mean
values. (b) Mean LLS over Arctic sea ice in the winter months (November–March) in CMIP6
models and observations. The "whiskers" on the CMIP6 and NP boxes show the 5th and 95th
percentiles of the distribution across models and stations, respectively.

### 3.2 Near-Surface Air Temperature as a Control on Low-Level Stability

- Observations show a linear relationship between LLS and near-surface air temperature
  (Figure 3), consistent across all three data sets and previously reported by Liu et al.
  (2006): **LLS decreases by ~0.5 °C per 1 °C increase in near-surface air temperature**
  — i.e., the 850-hPa temperature increases only ~0.5 °C per 1 °C increase at the
  surface.
- The relationship is seen consistently across the high-time-resolution CMIP6 ensemble
  (also Figure S3): multimodel mean slope **−0.47 °C per °C**, standard deviation across
  models **0.06 °C per °C**. CMIP6 models therefore successfully capture the observed
  short-timescale coupling between surface temperature and LLS over winter sea ice.
  Across model mean states (Figure S2), a similar linear relationship holds: a model's
  mean temperature aloft increases by 0.4 °C for each 1 °C increase in mean near-surface
  Arctic winter temperature.

**Figure 3.** Relationship between winter near-surface air temperature and low-level
stability, in observations (a–c) and CMIP6 models over sea ice (d). Individual radiosondes
are plotted for the observations, and the relative density of time and grid point
instances over sea ice as a histogram with normalized density units is plotted for CMIP6
models. Data for all models are 6-hourly, except for NorESM2-LM, IPSL-CM6A-LR,
EC-Earth3-CC, and TaiESM1, which use daily mean outputs. Solid lines are linear
regressions, with one gray line for each CMIP6 model assessed. In the North Pole drifting
stations (NP) case, we also show regressions on the subsets of observations under "clear"
and "cloudy" conditions defined as less than and greater than 50% cloud cover by visual
assessment, respectively. Panel (e) shows the slopes of the regressions given in (a–d).

### 3.3 Clear and Cloudy States

- Bivariate histograms of LLS vs net surface longwave (Figure 4) show distinct
  clear/cloudy bimodality in the MOSAiC and SHEBA data. **Threshold: −25 W m⁻²**
  approximately distinguishes the two modes in both observations and models. The clear
  state (surface net longwave more negative than −25 W m⁻²) accounts for approximately
  60% of observations (MOSAiC 65%, SHEBA 59%, NP 63%).
- Time-matched surface longwave was unavailable for NP, so NP LLS observations are split
  by visual cloud assessment: clear = less than 50% cloud cover (Figure 4c). The
  clear-state proportion is not strongly sensitive to the threshold because 79% of visual
  observations are either under 10% or over 80% cloud cover; alternative thresholds of
  <30% or <70% give clear-state fractions of 57% and 66%.
- CMIP6 representation of the two states is inconsistent. Some models (e.g., MRI-ESM2-0)
  have a second density center at close-to-zero net longwave flux (a cloudy state);
  others (e.g., TaiESM1) have a single mode at approximately −50 W m⁻² (clear state
  only). Note: lack of the cloudy state means lack of high-emissivity, liquid-containing
  low clouds that prevent longwave cooling of the surface — not that total cloud fraction
  (including ice clouds) is zero.
- Dip test on each model's 6-hourly net surface longwave distribution (1-D histograms in
  Figure S4): **7 of the 20 models show a bimodal distribution** with both clear and
  cloudy states (starred in Figure 4). Ordering models by mean column cloud condensed
  water content (ice water path + liquid water path) supports associating the missing LLS
  mode with a missing cloudy state: models lacking the cloudy state (by longwave flux and
  LLS) also show the least atmospheric cloud water. Model spread in cloud condensed water
  is very large: **1 to 65 g m⁻²**. The equivalent MOSAiC mean is **~80 g m⁻²**
  (calculated from the Saavedra Garfias et al. 2023 data set of MOSAiC microwave and
  radar observations) — the higher end of the model range therefore appears more likely
  realistic, though the MOSAiC mean state should exceed the models' regional average
  because moist intrusions are more common in the Atlantic sector (Woods & Caballero
  2016).

**Mean-state atmosphere mass content of cloud condensed water (g m⁻²) per model, as given
in the Figure 4 subplot titles** (ascending order; * = not unimodal in net longwave
radiation by dip test at 95% significance):

| Model | Cloud condensed water (g m⁻²) | Bimodal (dip test) |
|---|---|---|
| CMCC-ESM2 | 1.1 | |
| CMCC-CM2-SR5 | 1.3 | |
| IPSL-CM6A-LR | 9.5 | |
| TaiESM1 | 9.6 | |
| MPI-ESM-1-2-HAM | 15.1 | * |
| MPI-ESM1-2-LR | 20.9 | * |
| GFDL-CM4 | 23.3 | |
| MPI-ESM1-2-HR | 25.2 | * |
| KIOST-ESM | 27.5 | |
| EC-Earth3-AerChem | 28.1 | |
| HadGEM3-GC31-MM | 28.6 | |
| HadGEM3-GC31-LL | 29.4 | |
| EC-Earth3 | 29.6 | |
| EC-Earth3-CC | 30.5 | |
| MIROC6 | 30.7 | |
| MRI-ESM2-0 | 33.3 | * |
| NorESM2-LM | 44.5 | * |
| GISS-E2-1-G | 47.7 | * |
| CMCC-CM2-HR4 | 60.8 | |
| BCC-CSM2-MR | 64.7 | * |

- For the seven bimodal models, data points are assigned to states with the −25 W m⁻²
  cutoff (Table S3). Four models (BCC-CSM2-MR, MPI-ESM1-2-LR, MPI-ESM1-2-HR, NorESM2-LM)
  **over-represent the cloudy state** relative to observations; possible causes include
  cloud microphysics (e.g., excess liquid water) and excess moisture flux into the Arctic
  (see also Section 3.4). Within the MPI-ESM1 family, model physics rather than
  resolution appears to be the greater control on realistically representing the states:
  MPI-ESM-1-2-HAM (interactive aerosols and altered mixed-phase microphysics) has
  improved realism in the clear/cloudy distribution — 60% of points in the clear state,
  broadly in line with observations — whereas MPI-ESM1-2-LR and MPI-ESM1-2-HR both have a
  minority of points in the clear state. Alongside the over-represented cloudy state,
  MPI-ESM1-2-LR and MPI-ESM1-2-HR have mean LLS of 5.7 and 5.0 °C respectively (low end
  of the CMIP6 range), while MPI-ESM-1-2-HAM has stronger stability of 7.7 °C.
- Comparing Figure 4 with the mean-state LLS in Figure 2: intermodel spread in LLS is set
  not only by the relative frequency of the two modes but also by the central LLS value
  within each mode. MRI-ESM2-0 has a realistic 63% of points under −25 W m⁻² net longwave
  (the cloudy state) yet the lowest mean LLS of the Figure 4 models, because both modes
  are found at too-negative LLS values.

**Figure 4.** Bivariate histograms of net longwave radiation at the surface (positive
downward) against low-level stability over sea ice, during the winter months
(November–March). Histogram units are normalized as the total count of points varies
between subplots. Surface radiative flux was not available for the North Pole drifting
stations, so NP data are partitioned based on visual assessment of cloud coverage, with
coverage of >50% denoted "Cloudy." Data for all models are 6-hourly, except for
NorESM2-LM, IPSL-CM6A-LR, EC-Earth3-CC, and TaiESM1, which use daily mean outputs.
Vertical black dashed lines show the −25 Wm⁻² threshold. The values in brackets in each
title are the mean-state atmosphere mass content of cloud condensed water (grams m⁻²) for
each model over the same region and the time period; the models are shown in ascending
order in this quantity. Starred models are not unimodal in net longwave radiation,
according to a dip test at 95% significance (see Section 2.3 and Figure S4 in Supporting
Information S1).

### 3.4 Other Controls on Low-Level Stability

- The observed relationship between near-surface inversions and wind speed is nonlinear,
  with several studies finding transition wind speeds above which surface inversion
  strength sharply decreases to near zero (Baas et al. 2019; Vignon et al. 2017; Wiel et
  al. 2017). At the larger vertical scale of this analysis no such transition is apparent
  (Figures 5a–5c), so linear regression is used as a first-order approximation to the
  nonlinear underlying behavior.
- The three observational data sets show clear, highly statistically significant
  reductions in LLS with faster surface wind: slopes **−0.55, −0.67, −0.63 °C per
  m s⁻¹** for MOSAiC, SHEBA, NP respectively, with R² ≈ 0.1 in each case. For NP the
  reduction holds both across all stations and within every individual station.
- CMIP6 (12 models with wind variables at daily or higher resolution) shows a diverse set
  of wind speed–LLS relationships. Several models (e.g., IPSL-CM6A-LR) recreate the
  observed suppression closely, with slope ≈ −0.6 °C per m s⁻¹ and wind speed accounting
  for ~10% of the variance in LLS. However, BCC-CSM2-MR shows a strong, significant
  *increase* in LLS with wind speed, and MRI-ESM2-0 shows almost no relationship
  (R² < 0.01). Part of this variation is likely driven by differences in mean-state wind
  shear among models: stronger shear → stronger wind-driven turbulent heat fluxes
  (Chechin et al. 2023) → stronger suppression of LLS. This relationship is seen (not
  shown) in the NP station data — a positive correlation (significant at 90% confidence)
  between a station's mean wind shear and its stability reduction with wind. NP
  inter-station shear variation includes synoptic variability and local sea-ice
  conditions, whereas intermodel wind-shear variability (winter mean over the entire
  Arctic sea-ice domain, 20 model years each) is likely predominantly model uncertainty.
- Possible contributors to the missing cloudy state in some models: synoptic-scale
  meteorology (not enough moisture flux into the Arctic — out of scope here), column
  physics / surface-atmosphere coupling (bias in vertical turbulent heat fluxes at the
  surface), and cloud microphysics (early freezing of supercooled water droplets; Pithan
  et al. 2014). Figure 6a shows a positive relationship between cloud ice fraction and
  mean-state LLS — suggesting the CMIP5-era bias (freezing of supercooled droplets at
  excessively warm temperatures preventing high-emissivity mixed-phase clouds) may
  persist in the CMIP6 models lacking a cloudy state. However, only a correlation is
  established across the ensemble; the reverse relationship is possible — models with
  strong LLS and thus a cold boundary layer may see greater condensate freezing. Finally,
  across the CMIP6 ensemble there is a strong negative relationship between mean-state
  surface upward sensible heat flux and LLS over winter sea ice (Figure 6b) — explicable
  via the stronger downward fluxes expected given a steeper column temperature gradient;
  but, as suggested by Pithan et al. (2014), excessive upward heat fluxes from the warmer
  underlying ocean due to overestimated ice and snow conductivity may also contribute to
  reducing LLS in some models.

**Figure 5.** Relationship between low-level stability and surface wind speed during the
winter months (November–March) in each of the three sets of observations (a–c) and the 12
models for which wind data were available (d–o). Solid lines are linear regressions, and
colors are bivariate histograms with normalized density units (as the total count of
points varies between subplots). For the North Pole drifting stations (NP) (panel c),
gray solid lines show the linear regression as calculated for each individual station.
All regressions plotted have a p-value less than 0.001. Panel (p) shows the values of the
slopes of each linear regression. BCC-CSM2-MR, which has a strongly positive slope, is
excluded from (p) and from the CMIP6 distribution shown as a box. For NP, the
distribution of slopes across individual stations is shown as a box.

**Figure 6.** (a) Ratio of atmospheric column cloud ice to atmospheric column condensed
water across the multimodel ensemble in the mean state. (b) Relationship between
low-level stability (LLS) and surface sensible heat flux scaled by the surface wind
speed. In both panels, each point represents the mean of all monthly instances of LLS and
each variable for the first ensemble member over the winter months (November–March) over
the sea ice region in a given model over the final two decades of the historical
simulation (1995–2015).

### 3.5 Projected Decline in Low-Level Stability Under Warming

- The short-timescale negative LLS–temperature coupling (Figure 3; ~0.5 °C increase aloft
  at 850 hPa per 1 °C at the surface) also applies on climatic timescales in each
  individual CMIP6 model (Figure S5). Over the 250 years of the historical + SSP2-4.5
  runs, all 40 models assessed show a significant (p > 99%) negative linear relationship
  between winter near-surface air temperature over Arctic sea ice and LLS. Multimodel
  mean: LLS decreases by **−0.6 ± 0.1 °C per °C** of near-surface warming — equivalent to
  an increase in temperature aloft (850 hPa) of **+0.4 °C per °C** near-surface warming.
  Per-model trend sizes: Figure S6. The two trends are strongly linearly related,
  showing tight coupling of surface warming, warming aloft, and LLS across the ensemble.
  The multimodel-mean 0.4 °C warming aloft per °C surface warming (i.e., 2.5× faster
  warming at the surface than aloft) reasonably approximates the relationship between
  trends across the full ensemble (gray dotted line), though the best linear fit (black
  dashed line) has a nonzero y-intercept of 0.12 °C per decade and slope of 0.33 °C per
  °C.
- Every model tested shows faster surface warming than at 850 hPa over the 21st century,
  so winter LLS declines in each model with amplified Arctic warming under SSP2-4.5.
  Northward of 75°N, the multimodel mean LLS declines from **6.9 °C in the preindustrial
  period** to become negative before the end of the 21st century, with the 10-year
  rolling mean **crossing the zero line in 2083** (Figure 7). The rate of LLS decline
  across the observations, **−0.85 °C per decade**, is nearly twice as large as the
  **−0.45 °C per decade** trend in the CMIP6 multimodel mean over the same period;
  contributions to the difference could include internal variability, spatial variation
  in observation sites, and model limitations.

**Figure 7.** Time series of the CMIP6 multimodel ensemble projections for (a) high
Arctic (>75°N) winter near-surface air temperature change and (b) high Arctic (>75°N)
low-level stability. The black line is the multimodel mean of 10-year centered rolling
means, and the shaded region is the 10–90th percentile range. The colored dots show the
mean values in each observational campaign, with smaller crosses for individual North
Pole (NP) stations.

## 4. Discussion and Conclusions

- Radiosondes from the three data sets find mean wintertime LLS over sea ice of between
  5 and 10 °C, the large range likely arising at least in part from a decreasing LLS
  trend over the 70-year span between the campaigns. The CMIP6 multimodel mean LLS over
  winter sea ice sits within this range at 6.6 °C. However, individual models show a
  large range of mean states: several have negative LLS (thus failing to show a typically
  stable winter boundary layer); several others show mean stability several degrees above
  the observational-range maximum. **The intermodel spread in mean-state stability over
  winter sea ice for CMIP6 shows no reduction relative to CMIP5 and CMIP3.**
- Models with high LLS often lack a cloudy state. This lack — characterized by near-zero
  net surface longwave flux and weaker, elevated inversions, reported by Pithan et al.
  (2014) for CMIP5 — still applies to a majority of models in the newer CMIP6 generation.
  Improvements in mixed-phase cloud microphysics are still necessary for model
  development toward accurate simulation of the Arctic winter atmosphere.
- Despite this, CMIP6 models for the most part qualitatively capture the local processes
  driving variation in LLS. All models assessed reproduce the observed negative linear
  relationship between near-surface air temperature and LLS in Arctic winter over sea
  ice, with approximately a 0.5 °C decrease in LLS per °C warming at the surface.
  Suppression of stability with greater surface winds is also found, albeit less
  consistently. Both the NP drifting stations and CMIP6 show greater wind suppression
  with increased wind shear. In addition to the short-timescale (hours-to-days) coupling,
  a negative linear relationship between near-surface air temperature and LLS holds on
  centennial timescales in CMIP6, due to surface-dominant Arctic warming.
- Limitations: remote drivers of LLS variation (moisture and heat fluxes into the Arctic)
  are not considered — future studies might include them. Only free-running CMIP6
  simulations are used, restricting the study to a qualitative, process-orientated
  approach (e.g., Eyring et al. 2005); "nudged" model runs (e.g., Pithan et al. 2023),
  which constrain the large-scale circulation to a particular state, would allow more
  direct comparison against observations on a given day and location. The assessment is
  also necessarily limited by the extent of observations; higher spatial and temporal
  resolution of central-Arctic winter observations would allow more quantitative
  comparison of modeled and observed states.
- As the Arctic warms, the multimodel CMIP6 mean shows winter LLS decreasing to zero in
  the central Arctic before the end of the century under SSP2-4.5. Accurate
  representation of the less-stable cloudy state may therefore become increasingly
  important for near-term projections of Arctic climate change under increasing warming.
  This transition away from a typically stably stratified wintertime boundary layer marks
  yet another profound shift in Arctic climate projected to occur in the coming decades.

## Data Availability Statement

All data publicly available. CMIP6: Earth System Grid Federation CMIP6 archive
(https://esgf-index1.ceda.ac.uk/search/cmip6-ceda/). North Pole drifting stations: US
National Snow and Ice Data Centre (Colony & Thorndike, 1984). MOSAiC: Pangea (Maturilli
et al., 2021); MOSAiC tower radiation data (Reynolds & Riihimaki, 2019) from
https://www.arm.gov. SHEBA: https://atmos.uw.edu/~roode/SHEBA.html. Analysis and plotting
code: Zenodo, https://zenodo.org/records/13763472 (Duffey, 2024).

## Acknowledgments (condensed)

Initiated at the CLIVAR Arctic Processes in CMIP6 Bootcamp, October 2022; thanks to
organizer Ruth Mottram, all lecturers and mentors, and all involved in the MOSAiC, SHEBA,
and North Pole drifting-station field campaigns. AD: NERC Doctoral Training Partnership
Grant NE/S007229/1. RM: Canada 150 Research Chairs Program via Julienne Stroeve;
University of Manitoba. FP: EU Horizon 2020 Grant 101003826 (project CRiceS). VRD:
Research Development Fund studentship, Northumbria University, and the Northern Water
Futures project.

## References

Baas et al. (2019) *QJRMS* 145(720), 930–946 · Beesley et al. (2000) *JGR* 105(D10),
12337–12349 · Bintanja et al. (2011) *Nat. Geosci.* 4(11), 758–761 · Blackport & Screen
(2020) *Nat. Clim. Change* 10(12), 1065–1066 · Boeke et al. (2021) *GRL* 48(1),
e2020GL091109 · Bretherton et al. (1999) *JGR* (FIRE Arctic Clouds Experiment Special
Issue) · Cai et al. (2022) *Environ. Res. Lett.* 17(4), 044068 · Chechin et al. (2023)
*ACP* 23(8), 4685–4707 · Chechin et al. (2019) *JAS* 76(8), 2481–2503 · Chylek et al.
(2022) *GRL* 49(13), e2022GL099371 · Cohen et al. (2014) *Nat. Geosci.* 7(9), 627–637 ·
Cohen et al. (2020) *Nat. Clim. Change* 10(1), 20–29 · Colony & Thorndike (1984) NSIDC,
doi:10.7265/N5D798B1 · Comyn-Platt et al. (2018) *Nat. Geosci.* 11(8), 568–573 · Duffey
(2024) Zenodo, doi:10.5281/zenodo.13763472 · Duffey et al. (2023) *Earth Syst. Dyn.*
14(6), 1165–1169 · England et al. (2021) *GRL* 48(15), e2021GL094086 · Eyring et al.
(2016) *GMD* 9(5), 1937–1958 · Eyring et al. (2005) *BAMS* 86(8), 1117–1134 · Feldl et
al. (2020) *npj Clim. Atmos. Sci.* 3(1), 1–9 · Fetterer et al. (2017) Sea ice index v3,
NSIDC, doi:10.7265/N5K072F8 · Gettelman et al. (2019) *GRL* 46(14), 8329–8337 · Goosse
et al. (2018) *Nat. Commun.* 9(1), 1919 · Hahn et al. (2021) *Front. Earth Sci.* 9,
710036 · Hansen et al. (1997) *JGR* 102(D6), 6831–6864 · Hartigan, J. A., & Hartigan,
P. M. (1985) *Ann. Stat.* 13(1), 70–84 · Hartigan, P. M. (1985) *J. R. Stat. Soc. C*
34(3), 320–325 · Hausfather & Peters (2020) *PNAS* 117(45), 27791–27792 · Henry et al.
(2021) *J. Clim.* 34(6), 2355–2365 · Horton et al. (2015) *Nature* 522(7557), 465–469 ·
Inoue et al. (2021) *JGR Atmos.* 126(1), e2020JD033904 · Kahl et al. (1999) *BAMS*
80(10), 2019–2026 · Krumpen et al. (2021) *The Cryosphere* 15(8), 3897–3920 · Liu et al.
(2006) *J. Clim.* 19(19), 4902–4913 · Lu & Cai (2010) *Clim. Dyn.* 34(5), 669–687 ·
Maechler (2024) diptest: Hartigan's Dip test statistic for unimodality,
https://github.com/mmaechler/diptest · Manabe & Wetherald (1975) *JAS* 32(1), 3–15 ·
Maturilli et al. (2021) Initial radiosonde data from 2019-10 to 2020-09 during project
MOSAiC, PANGAEA, doi:10.1594/PANGAEA.928656 · Medeiros et al. (2011) *J. Clim.* 24(17),
4733–4740 · Pattyn et al. (2018) *Nat. Clim. Change* 8(12), 1053–1061 · Peng et al.
(2023) *ACP* 23(15), 8683–8703 · Perovich et al. (2003) *JGR* 108(C3), 8050 · Persson et
al. (2002) *JGR* 107(C10) · Pistone et al. (2014) *PNAS* 111(9), 3322–3326 · Pithan et
al. (2016) *JAMES* 8(3), 1345–1357 · Pithan et al. (2023) *GMD* 16(7), 1857–1873 ·
Pithan & Mauritsen (2014) *Nat. Geosci.* 7(3), 181–184 · Pithan, Medeiros, & Mauritsen
(2014) *Clim. Dyn.* 43(1), 289–303 · Previdi et al. (2021) *Environ. Res. Lett.* 16(9),
093003 · Rantanen et al. (2022) *Commun. Earth Environ.* 3(1), 1–10 · Reynolds &
Riihimaki (2019) ARM: Icerad, doi:10.5439/1608608 · Saavedra Garfias et al. (2023) *ACP*
23(22), 14521–14546 · Sedlar et al. (2020) *JGR Atmos.* 125(6), e2019JD031783 · Serreze
et al. (2009) *The Cryosphere* 3(1), 11–19 · Serreze & Francis (2006) *Clim. Change*
76(3), 241–264 · Shupe et al. (2022) *Elementa: Sci. Anthropocene* 10(1), 00060 ·
Solomon et al. (2023) *Elementa: Sci. Anthropocene* 11(1), 00104 · Stramler et al.
(2011) *J. Clim.* 24(6), 1747–1762 · Svensson & Karlsson (2011) *J. Clim.* 24(22),
5757–5771 · Taylor et al. (2022) *Front. Earth Sci.* 9, 758361 · Tjernström et al.
(2008) *J. Appl. Meteorol. Climatol.* 24(22), 5757–5771 · Uttal et al. (2002) *BAMS*
83(2), 255–276 · Vignon et al. (2017) *QJRMS* 143(704), 1241–1253 · Walsh & Stewart
(2019) Gridded monthly sea ice extent and concentration, 1850 onward, v2, NSIDC,
doi:10.7265/jj4s-tq79 · Wexler (1936) *MWR* 64(4), 122–136 · Wiel et al. (2017) *JAS*
74(4), 1057–1073 · Woods & Caballero (2016) *J. Clim.* 29(12), 4473–4485 · Woods et al.
(2013) *GRL* 40(17), 4717–4721 · Zhang & Screen (2021) *GRL* 48(13), e2021GL092726 ·
Zhang et al. (2022) *BAMS* 103(10), E2285–E2301
