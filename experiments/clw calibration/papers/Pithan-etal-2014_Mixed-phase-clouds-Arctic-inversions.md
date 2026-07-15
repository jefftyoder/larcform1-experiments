# Mixed-phase clouds cause climate model biases in Arctic wintertime temperature inversions

Pithan, F., B. Medeiros, and T. Mauritsen (2014), *Climate Dynamics*, 43, 289–303,
doi:10.1007/s00382-013-1964-9.
Received 28 Feb 2013; accepted 4 Oct 2013; published online 15 Oct 2013.
© Springer-Verlag Berlin Heidelberg 2013.

> **Note on this file:** re-transcribed 2026-07-14 from the source PDF
> (`~/Zotero/storage/Z7QBMB6W/`), replacing an earlier automated PDF text dump
> (recoverable in git history). Tables, equations, and figure captions are
> verbatim; running prose is a faithful condensed rendering, not a word-for-word
> copy — consult the PDF for exact wording.

**Keywords:** Arctic · Boundary layer · Turbulence · Temperature inversion

## Abstract (condensed)

Temperature inversions are a common feature of the Arctic wintertime boundary layer,
affecting radiative and turbulent heat fluxes and local climate-change feedbacks.
The formation of Arctic air masses leads to the emergence of a **cloudy** and a
**clear** state of the Arctic winter boundary layer: in the cloudy state, cloud
liquid water is present, there is little to no surface radiative cooling, and
inversions are elevated and relatively weak; in the clear state, surface radiative
cooling leads to strong surface-based inversions. Comparing model output to
observations, most climate models lack a realistic representation of the cloudy
state. An idealised SCM experiment of Arctic air formation shows this bias is
linked to inadequate mixed-phase cloud microphysics, whereas turbulent and
conductive heat fluxes control the strength of inversions within the clear state.

## 1. Introduction

- The Arctic climate system is changing rapidly (ACIA 2004); Arctic processes matter
  for global climate via deep-water formation (Jungclaus et al. 2005), mid-latitude
  connections (Honda et al. 2009; Francis & Vavrus 2012), and feedbacks.
- Aim: understand Arctic temperature inversions and their model representation by
  combining CMIP5 output, observations, and an idealised SCM experiment of Arctic
  air-mass formation. Low-level mixed-phase clouds play a key role in setting
  surface fluxes and inversion strength; many models struggle with these clouds at
  low temperatures.
- Inversions affect the amplitude/sign of radiative and turbulent surface heat
  fluxes (Bintanja et al. 2011) and surface–atmosphere mechanical coupling, hence
  sea-ice drift (Overland & Guest 1991). Under warming, stable stratification traps
  additional heat near the surface → stronger surface than upper-tropospheric
  warming → regionally positive lapse-rate feedback: less upper-tropospheric
  warming means a smaller increase in outgoing longwave radiation, so more surface
  warming is required to balance TOA fluxes (Manabe & Wetherald 1975; Held 1978;
  Fig. 1).
- Inversions are a long-known Arctic feature (Sverdrup 1933). Serreze et al. (1992):
  wintertime inversion frequency/depth/strength increase from the Norwegian Sea
  eastward, where cloud cover is reduced and anticyclonic conditions dominate.
  SHEBA: inversions present in almost all soundings over one year (Tjernström &
  Graversen 2009); more than half of observed winter (DJF) inversions were
  surface-based, while elevated inversions with a near-neutral mixed layer
  dominated in spring/summer. Satellite retrievals compare favourably with
  radiosondes and extend the picture (Gettelman et al. 2006; Pavelsky et al. 2011).
  Humidity inversions (specific humidity rising with altitude) are also common in
  Arctic boundary layers (Curry 1986; Devasthale et al. 2011).
- Radiation–condensate interactions matter for BL development and inversion
  strength (Sverdrup 1933). SHEBA revealed **two preferred states** of the Arctic
  wintertime boundary layer (Persson et al. 1999, 2002; Stramler et al. 2011): a
  radiatively **clear** state — strong longwave cooling under ice clouds or clear
  skies — and a **cloudy** state — low-level mixed-phase clouds and little to no
  longwave cooling at the surface. The states show distinct turbulent/conductive
  heat fluxes and temperature structures: stronger, surface-based inversions in the
  clear state; weaker, usually elevated inversions in the cloudy state (Fig. 2).
- Arctic stratiform mixed-phase clouds: one or several thin supercooled-liquid
  layers at cloud top, ice crystals within and below (Morrison et al. 2012). Liquid
  forms mostly in updrafts (minor part in the inversion layer); ice forms in-cloud,
  grows, is removed by sedimentation. Ice can rapidly deplete liquid via the
  Wegener–Bergeron–Findeisen process (Wegener 1911; Bergeron 1935; Findeisen 1938);
  low in-cloud ice-nuclei concentrations may limit ice formation and contribute to
  cloud persistence (Fridlind et al. 2012). Large-scale models cannot resolve
  turbulent updrafts and are typically too coarse vertically to resolve the
  supercooled liquid layers (one model layer represents the mean of liquid and ice
  layers) → representing mixed-phase thermodynamics/microphysics is challenging
  (Klein et al. 2009; Barrett 2012).
- Medeiros et al. (2011), CMIP3: defining inversion strength as 850 hPa minus
  surface air temperature and partitioning land/ocean, typical inversion strengths
  spread by ~10 K, with many models overestimating stability over land and sea ice.
  That bulk-stability definition (robust given coarse model resolution) is adopted
  here as a proxy for inversion strength throughout. Surface turbulent fluxes are
  closely linked to lower-tropospheric structure and also spread widely: medians of
  monthly-mean winter turbulent heat fluxes over Arctic sea ice range from −15 to
  +15 W m⁻² across CMIP3 models, with similar spread in net longwave (Svensson &
  Karlsson 2011).
- Approach: idealised single-column experiment building on Wexler (1936) and Curry
  (1983), who showed radiative cooling, its interaction with condensate, and warm
  air advection are crucial for inversions, the whole boundary layer, and the
  winter surface heat budget; both call the radiative cooling of warm maritime air
  masses the formation of continental polar air — here "formation of Arctic air
  masses". Outline: large-scale stability analysis (Sect. 3); air-mass formation
  and BL-state emergence (Sect. 4); sub-daily CMIP5 comparison (Sect. 5); SCM
  parameterisation sensitivity (Sects. 5.1, 5.2).

**Figure 1.** Stronger warming at the surface than in the middle and upper
troposphere leads to a positive lapse-rate feedback in the Arctic. *Source* Pithan
and Mauritsen (2013) ©American Meteorological Society

**Figure 2.** Median vertical structures of temperature and humidity in the clear
(*red*) and cloudy (*blue*) boundary layer observed NDJF during SHEBA. Redrawn
following Stramler et al. (2011) using a threshold of −10 W m⁻² of surface net
longwave radiation to separate the two states
— Panels: temperature (°C, −40…−10) and specific humidity (g kg⁻¹, 0…1) vs
pressure 600–1000 hPa.

## 2. Models and data

- Monthly mean atmospheric/near-surface air temperatures and sensible heat fluxes
  from historical runs of CMIP5 models (Table 1) and RCP8.5 runs of a subset are
  used for large-scale low-level stability and flux analysis (Taylor et al. 2012).
  Detailed analysis for models with sub-daily temperatures and surface net longwave
  radiation; those models and their mixed-phase microphysics are in Table 2.
- Observations: SHEBA (multiyear pack ice north of Alaska, Oct 1997–Oct 1998;
  Persson et al. 2002) — surface met and flux measurements on the ice floe, six- to
  twelve-hourly radiosonde launches. Also surface observations and radiosondes from
  the ARM site at Barrow, Alaska (71.3°N 156.6°W; Xie et al. 2010).
- Reanalyses: ERA-40 (Uppala et al. 2005) and ERA-Interim (Simmons et al. 2007),
  using different IFS versions and assimilation schemes. Reanalyses are less
  reliable in data-sparse regions like the Arctic (Sorteberg et al. 2007); over the
  Arctic ocean, vertical temperature profiles depend strongly on satellite
  retrievals and the underlying model. Tjernström & Graversen (2009): ERA-40
  near-surface warm bias of ~1 K vs SHEBA persisting despite assimilation of SHEBA
  observations; assimilating soundings reduced the bias by ~0.5 K. ERA-40 somewhat
  underestimates typical inversion strengths but captures climatological
  characteristics; model biases shown later are much larger than likely reanalysis
  error, justifying reanalyses as approximate observational "truth".

**Table 1. CMIP5 models used in this study**

| Model | Modelling centre |
|---|---|
| BCC-CSM1-1 | Beijing Climate Center |
| BNU-ESM | College of Global Change and Earth System Science, Beijing Normal University |
| CanCM4 | Canadian Centre for Climate Modelling and Analysis |
| CMCC-CM | Centro Euro-Mediterraneo per I Cambiamenti Climatici |
| CNRM-CM5 | Centre National de Recherches Météorologiques |
| CSIRO-Mk3-6-0 | Commonwealth Scientific and Industrial Research Organization |
| EC-EARTH | EC-EARTH consortium |
| FIO-ESM | The First Institute of Oceanography |
| FGOALS-s2 | LASG, Institute of Atmospheric Physics |
| GFDL-CM3 | NOAA Geophysical Fluid Dynamics Laboratory |
| GISS-E2-R | NASA Goddard Institute for Space Science |
| INMCM4 | Institute for Numerical Mathematics |
| IPSL-CM5A-LR | Institut Pierre-Simon Laplace |
| IPSL-CM5B-LR | Institut Pierre-Simon Laplace |
| MIROC-ESM | Japan Agency for Marine-Earth Science and Technology |
| HadCM3 | Met Office Hadley Centre |
| MPI-ESM-LR | Max Planck Institute for Meteorology |
| MRI-CGCM3 | Meteorological Research Institute |
| CCSM4 | National Center for Atmospheric Research |
| CESM1-CAM5 | Community Earth System Model Contributors |
| NorESM1-M | Norwegian climate centre |

**Table 2. Overview of CMIP5 models providing high-frequency data**

| CMIP model | Atmosphere | No. of layers | References | Computation of cloud ice fraction f |
|---|---|---|---|---|
| BCC-CM-1-1 | BCC-AGCM 2.0.1 | 26 | Wu et al. (2010) | Linear between −10 and −40 |
| CMCC-CM | ECHAM5 | 31 | Scoccimarro et al. (2011) | Explicit parameterisation of freezing processes between 0 and −35 |
| CCSM4 | CAM4 | 26 | Gent et al. (2011) | Linear between −10 and −40 |
| CNRM-CM5 | Arpege-Climat 5.1 | 31 | Météo France (2009) | No prognostic condensate, f = 1 − exp{ −1/(2(ΔT)²) · (T − Tₜ)² }ᵃ |
| GISS-E2-R | GISS ModelE | 40 | Schmidt et al. (2006) | T-dependent probability of freezing and Bergeron–Findeisen process, pᵢ = 1 − exp[ −((T₀ − T)/12)² ]ᵇ |
| GFDL-CM3 | GFDL-AM3 | 48 | Donner et al. (2011) | Explicit parameterisation of freezing processes between 0 and −30, almost no water at temperatures colder than −15 |
| INMCM4 | INMCM | 21 | Volodin et al. (2010) | f = 1 − (0.0059 + 0.9941·exp(−0.003102 T²)) |
| IPSL-CM5A | LMDZ5A | 39 | Hourdin et al. (2012) | Linear between 0 and −15 |
| MIROC-ESM | MIROC-AGCM | 80 | Watanabe et al. (2011) | f = 1 − exp[(−((268.91 K − T)/12 K)²)] above −38 °C |
| MPI-ESM-LR | ECHAM6 | 47 | Stevens et al. (2013) | Explicit parameterisation of freezing processes between 0 and −35 |
| MRI-CGCM3 | MRI-AGCM3 | 40 | Yukimoto et al. (2012) | Explicit parameterisation of freezing processes, Bergeron–Findeisen process triggers full and immediate glaciation if ice water content >0.5 mg kg⁻¹ |

ᵃ Tₜ: triple point, ΔT = 11.82 K
ᵇ T₀ = −4 °C over ocean and −10 °C over land

### 2.1 Single-column models, forcing and initialisation

- SCM framework models the cooling of an air mass advected from lower latitudes
  into the Arctic in winter (Wexler 1936; Curry 1983): Lagrangian perspective —
  follow the air-mass trajectory with the SCM, assume horizontal homogeneity — an
  idealised setup for the role of local processes. Large-scale advection of heat
  and moisture matters for mixed-phase cloud formation/resilience and is the basis
  of the Lagrangian setup; open leads (heat/moisture sources; Andreas et al. 2002)
  are neglected.
- Most experiments use the SCM version of ECHAM6, the atmosphere of MPI-ESM
  (Stevens et al. 2013), with 47 layers as in the MPI-ESM-LR CMIP5 runs (lowest
  level ≈30 m above ground; 10 levels within the lowest 3 km). Some experiments
  repeated with the SCM of CAM4 (Gent et al. 2011), the atmosphere of CCSM4.
- ECHAM6 microphysics: cloud water and cloud ice are separate prognostic variables;
  rain and snow diagnosed. Instantaneous homogeneous freezing of all cloud liquid
  below −35 °C; stochastic heterogeneous and contact freezing between 0 and −35 °C.
  Cloud ice can sediment to lower levels or the surface, be converted to snow by
  aggregation and accretion, and sublimate or melt (Lohmann & Roeckner 1996).
- Initial temperature profile — air mass in equilibrium with a near-freezing ocean
  surface: `T = T₀ (p/p₀)^(Rγg⁻¹)` below 300 hPa and constant above, where
  T₀ = 273 K and p₀ = 1,013 hPa are the surface temperature and pressure,
  γ = 8 × 10⁻³ K m⁻¹ is the assumed lapse rate, R = 287 J kg⁻¹ K⁻¹ the gas
  constant for air and g gravitational acceleration (Curry 1983).
- Relative humidity drops linearly with pressure from 80 % at the surface to 20 %
  at 600 hPa. A constant specific humidity of 3 × 10⁻⁶ is prescribed between
  300 hPa and the model top. Model location 70°N; initial sea-ice thickness 1 m;
  initial snow cover 0.1 m water equivalent. A geostrophic wind of 5 m s⁻¹ is
  prescribed up to 300 hPa to drive moderate turbulent mixing. Large-scale
  advection of heat, moisture and momentum set to zero. CO₂ concentration set to
  the preindustrial value of 280 ppm. Surface temperatures initialised at 250 K;
  the ocean underneath the ice assumed at the freezing point of sea water
  (−1.9 °C). Surface temperatures, sea ice and snow properties calculated
  interactively during the experiment. Model started 1 January, run for 20 days →
  zero insolation throughout.
- Qualitative results are robust to small changes in initial/boundary conditions
  (initial surface temperature, initial temperature profiles, prescribed
  geostrophic wind profile). Since cloud formation depends on the initial RH
  profile, RH drops off quickly with altitude to study low-level cloud processes
  over several days while avoiding high-level cloud formation.

## 3. Lower tropospheric temperature structure in CMIP5 models

- Area-weighted PDFs of monthly-mean low-level stability over land and ocean, CMIP5
  models and reanalyses (Fig. 3). Over the ocean: a bimodal distribution (as
  Medeiros et al. 2011 found for CMIP3) with a stable mode over sea ice and a
  near-neutral mode over open water. The mode distribution reflects models'
  differing sea-ice cover; models agree on the near-neutral mode's temperature
  structure (−12 to −8 K) within a few Kelvin. Focus over ocean is on the stable
  mode (sea-ice covered Arctic ocean), which holds the bulk of the inter-model
  spread.
- Mean modelled low-level stability in the stable mode: ~1.5 to 13 K (Fig. 4);
  reanalyses give 4.1 (ERA-int) and 4.9 K (ERA40). Only five models produce weaker
  stability than the reanalyses; 15 produce stronger. Over land the distribution is
  unimodal with somewhat smaller intermodel spread (Fig. 3b): mean modelled
  stability 4.5–11.5 K vs reanalysis values of 7.1 (ERA40) and 7.5 K (ERA-int);
  eight models smaller, ten larger. In the reanalyses, land stability is 2–3 K
  stronger than ocean; most models show <1 K difference, five show ≥2 K, and five
  show stronger stability over ocean than land.
- Models with strong stability are underrepresented in the high-frequency sample
  (Table 2; dashed vs solid lines in Fig. 3). Caveat: Arctic-ocean observations are
  limited to satellite irradiances and sporadic campaigns. If the ERA40 surface
  warm bias of up to 1.5 K vs SHEBA (Tjernström & Graversen 2009) were
  representative of the whole Arctic ocean and period, five models would fall
  within the realistic range while ten would still overestimate mean low-level
  stability. With more soundings over land, the land reanalysis bias could be
  smaller, so land–sea stability contrasts may be overestimated by the reanalysis.
- Within an individual model, mean Arctic low-level stability is closely tied to
  global mean temperature (Fig. 5): in a warming climate the Arctic surface warms
  faster than air aloft, weakening inversions and reducing low-level stability —
  the disappearance of inversions is a prerequisite for wintertime deep convection
  over the Arctic ocean, a suggested mechanism keeping the Arctic ocean free of
  winter sea ice in warm climates (Abbot & Tziperman 2008). Since global mean
  temperatures are cold-biased in most models (Mauritsen et al. 2012), this
  relationship could in principle explain part of the stability overestimate; but
  Fig. 5 shows that while the strongest-stability models tend to be cold-biased,
  the relationship cannot explain the bulk of the inter-model spread → investigate
  local processes.

**Figure 3.** PDFs of NDJF Arctic (north of 64 °N) monthly mean grid-point wise
low-level stability in the historical runs, 1990–1999. Inversion strength is
defined as 850 hPa temperature minus surface air temperature. The models' own
land-sea masks have been used to partition data into land and ocean domains,
considering any gridpoint with more than 20 % land fraction as land. Models from
Table 2 are displayed with *solid lines*

**Figure 4.** Mean low-level stability in the stable mode over the ocean (*light
gray*) and over land (*dark gray*). Models are sorted by mean low-level stability
in the stable mode over ocean. Modes are separated at the local minimum of the pdf
for each model. *Shaded areas* mark the range of the reanalyses

**Figure 5.** Mean low-level stability over land against global mean temperature in
models and reanalyses. *Lines* show regressions within the RCP8.5 runs of a subset
of models, *black circles* represent all CMIP5 model shown in Fig. 4. The *dotted
area* shows observed global mean temperatures and the associated uncertainty
according to Jones et al. (1999)

## 4. The formation of Arctic air masses

- Building on Wexler (1936) and Curry (1983): a relatively warm, moist air mass
  from lower latitudes is advected over cold Arctic sea ice; the transformation is
  modelled in the SCM experiment of Sect. 2.1.
- Sequence (Figs. 6, 7): initially an inversion forms (Fig. 7a) and the air mass
  cools to space and to the surface (Fig. 6a). Radiative cooling saturates the air,
  forming liquid or mixed-phase clouds. Their emissivity is close to unity, so
  radiative cooling now occurs in the cloud layer rather than at the surface,
  progressively eroding the inversion and reducing low-level stability (b). The
  cloud cools and is eventually transformed from mixed-phase to a low-emissivity
  ice cloud, allowing the surface to cool radiatively (c). When the condensate has
  fallen out, strong clear-sky surface cooling grows a new surface-based inversion
  (d). In the SCM experiment, (a) and (c) are unstable states in rapid transition
  to the quasi-stable state (b) or the stable state (d). Observations of both
  supercooled liquid and ice clouds in the same temperature range indicate the
  (b)→(c) transition is not a temperature-threshold behaviour but a regime shift in
  the dynamical interactions between cloud microphysics, cloud macrophysics and
  environmental conditions (Morrison et al. 2012).
- Arctic air formation produces a humidity inversion (Fig. 8), characteristic of
  the cloudy-state boundary layer (Fig. 2), because condensation begins near the
  surface and occurs at increasing altitudes as the boundary layer cools.
- The first quasi-stable state (b) — little/no surface cooling with mixed-phase
  clouds — corresponds to the SHEBA cloudy state; the second stable state (d) —
  strong longwave cooling without cloud liquid — to the clear state (Persson et al.
  1999, 2002; Stramler et al. 2011). Both states appear as a bimodal distribution
  of surface net longwave radiation in the SCM experiment (Fig. 9); despite the
  idealisation, the peak locations match SHEBA observations. Net surface longwave
  radiation in the two states is thus an emergent property of the coupled
  surface–atmosphere system, captured by the SCM, largely independent of actual
  temperatures and large-scale forcings. (Since the SCM remains in the clear state
  at the end of the run, the relative weight of each peak depends on run duration
  and should not be compared to observations.) The experiment also reproduces the
  observed link between cloud liquid presence and the cloudy state (Fig. 9;
  Tjernström 2012), and the mechanism is consistent with observations of Arctic
  air-mass formation in northwestern Canada (Turner & Gyakum 2011), where
  cloud-top radiative cooling preceded clear-sky surface cooling and surface-based
  inversion formation.

**Figure 6.** Sketch of the formation of Arctic air. *Dashed boxes* mark unstable
transition states

**Figure 7.** Trajectory of low-level stability against surface net longwave
radiation in idealised SCM experiment of Arctic air formation (Sect. 2.1), hourly
averages — axes: low-level stability −12…16 K, surface net LW +40…−80 W m⁻²;
labelled loop through states a → b → c → d.

**Figure 8.** Profiles of specific humidity during the SCM experiment — Initial,
Cloudy (day 3), Clear (day 10); specific humidity 0–3.0 g kg⁻¹ vs pressure
600–1000 hPa.

**Figure 9.** PDF of surface net longwave radiation during the formation of Arctic
air in the ECHAM6 SCM and observed NDJF at the SHEBA site. Both time series are
hourly averages, bins are 5 W m⁻² wide. *Grey circles* denote cloud liquid water
paths averaged for each bin

## 5. The two states of the boundary layer in observations and CMIP5 models

- ARM and SHEBA observations (Fig. 10): clear-state wintertime inversions are
  typically stronger than cloudy-state ones; within the clear state, stronger
  stability corresponds to weaker longwave cooling — consistent with the processes
  of Sect. 4 / Fig. 6.
- To determine how much of the mean-stability overestimate stems from shortcomings
  in one/both states and from the distribution between them, the distribution of
  low-level stability and surface radiative cooling is analysed in sub-daily CMIP5
  output. Arctic-wide model output cannot be expected to match point observations,
  but models should show the qualitative bimodal behaviour with different stability
  between modes. (High-frequency station output would allow closer comparison but
  was available for only a few models.)
- Three model categories (Figs. 11, 12):
  1. Three models (BCC-CSM-1-1, CMCC-CM and MPI-ESM-LR) reproduce the bimodal
     behaviour with distinct clear and cloudy states and stronger stability in the
     clear state. CMCC-CM has a less frequent cloudy state and stronger mean
     stability than BCC-CSM-1-1 and MPI-ESM-LR, which both have stability about
     1 K stronger than the reanalyses over the ocean and weaker than the
     reanalyses over land (Fig. 4).
  2. Three models (CCSM4, GFDL-CM3 and INMCM4) lack the cloudy state; of these,
     CCSM4 over both ocean and land, GFDL-CM3 over ocean and INMCM4 over land
     produce stronger mean stability than the reanalyses. GFDL-CM3 is one of very
     few models with stronger stability over ocean than land; INMCM4 agrees with
     the reanalyses over ocean and is much stronger over land.
  3. Five models lacking the cloudy state produce weak stability despite strong
     longwave cooling, and weaker monthly-mean stability than the reanalyses —
     caused (shown below) by excessive downward sensible heat fluxes from the
     atmosphere or excessive upward conductive heat fluxes from the liquid ocean
     to the surface.
- Some models lacking the cloudy state over ocean do represent it over land — most
  evident in INMCM4, but also GFDL-CM3, CNRM-CM5 and IPSL-CM5A, which all show a
  distinct but small cloudy-state representation over land.
- Relationships between BL state, stability and surface heat fluxes (Figs. 13, 14):
  MPI-ESM-LR and BCC-CSM1-1 typically produce small upward monthly-mean sensible
  heat fluxes over sea ice; most other models including CMCC-CM produce mean
  downward turbulent fluxes (Fig. 13). SHEBA shows upward turbulent fluxes indeed
  occur in the cloudy state, when the surface does not cool radiatively but is
  still warmed by conductive heat fluxes from the warmer ocean beneath the ice
  (Persson et al. 2002). Models lacking the cloudy state thus predominantly produce
  downward sensible heat fluxes in a stably stratified boundary layer associated
  with surface radiative cooling.
- IPSL-CM5A has the strongest downward sensible heat fluxes over both land and
  ocean, explaining its very weak stability despite strong longwave cooling. The
  new physics package in IPSL-CM5B substantially changed the inversion
  characteristics, reducing downward turbulent fluxes and producing one of the
  strongest mean stabilities in the ensemble (Fig. 4); no sub-daily IPSL-CM5B data
  was available for this study.
- Most models have smaller land–ocean stability contrasts than reanalyses and much
  stronger downward sensible heat fluxes over land than ocean. Unlike sea ice, the
  land surface is not warmed from below, which could explain stronger stability
  over land. The much stronger sensible heat fluxes toward the land surface may
  reflect models overestimating diffusivity under strongly stable stratification
  (Cuxart et al. 2006), weakening the land–ocean stability contrast. CNRM-CM5's
  land–ocean contrast exceeds the reanalyses (Fig. 4), likely because its sensible
  heat fluxes are virtually identical over both surfaces.
- GISS-E2-R stands out: monthly-mean turbulent fluxes similar to models that do
  represent the cloudy state (Fig. 13), but by far the weakest stability over sea
  ice (Fig. 4) while producing strong surface longwave cooling at all times
  (Fig. 11). Over land, it shows strong downward turbulent fluxes and stability at
  the low end but within the range of other models. Inference: its upward turbulent
  fluxes and very weak stability over the ocean are caused by strong conductive
  heat fluxes from the ocean that effectively prevent the boundary layer from
  becoming very stably stratified.
- Summary: eight of eleven analysed models lack a distinct cloudy-state
  representation over sea ice and therefore produce excessive surface longwave
  cooling. The few models with a distinct cloudy state also have monthly-mean
  low-level stability in better agreement with reanalyses. Models with excessive
  longwave cooling either produce strong stability or compensate the cooling with
  stronger turbulent or conductive heat fluxes toward the surface (weak low-level
  stability). Models lacking the cloudy state do not display a cloud-free Arctic
  ocean — they merely lack near-surface liquid or mixed-phase clouds with a large
  enough emissivity to inhibit surface longwave cooling. The issue is cloud
  *phase*, not cloud fraction. The too-little-liquid bias in Arctic winter clouds
  found by Cesana et al. (2012) for IPSL-CM5B occurs in a wide range of models.

**Figure 10.** Bivariate pdfs of NDJF low-level stability and surface net longwave
radiation from SHEBA observations (1997/1998) and the ARM site in Barrow
(2000–2009). Low-level stability is defined as the temperature difference between
the 850 hPa level and the near-surface air. Temperature measurements are for
individual soundings while surface radiation measurements are 6-hourly averages.
The pdf is constructed using 50 by 50 equally spaced bins ranging from −25 to 45 K
for low-level stability and from −120 to 40 W m⁻² for net longwave radiation. The
*white line* drawn across the plot serves as a visual reference and indicates a
relationship between surface cooling and low-level stability with a
Stefan-Boltzmann equation linearised around 240 K and assuming an effective
atmospheric emissivity of 0.6. Both values are chosen to visually match the
position and slope of the maximum density region in the pdfs

**Figure 11.** Bivariate pdfs of NDJF low-level stability and surface net longwave
radiation from CMIP5 models, 6-hourly values from the ocean area north of 64 °N
for 1990–1999 of the historical runs — panels: MPI-ESM-LR, CCSM4, MRI-CGCM3,
MIROC-ESM, BCC-CSM1-1, GFDL-CM3, IPSL-CM5A-LR, GISS-E2-R, CMCC-CM, INMCM4,
CNRM-CM5; PDF levels 0.02–0.5.

**Figure 12.** Bivariate pdfs of NDJF low-level stability and surface net longwave
radiation from CMIP5 models, 6-hourly values over land — same eleven models and
levels as Fig. 11.

**Figure 13.** PDF of Arctic NDJF monthly mean turbulent heat fluxes in CMIP5
models 1990–1999, positive downwards. Downward turbulent fluxes over sea ice in
the MRI-CGCM3 model are always very small over sea ice, which results in the
narrow peak at small positive values in (a) — (a) Ocean, (b) Land; surface
sensible heat flux −20…60 W m⁻².

**Figure 14.** Arctic NDJF monthly mean turbulent heat fluxes in CMIP5 models
1990–1999, positive downwards — stable mode over ocean (gray) vs land (black) per
model; surface sensible heat flux −10…30 W m⁻².

### 5.1 The role of mixed-phase cloud microphysics

- SCM sensitivity experiments link the process-based understanding of the models'
  mean state to individual parameterisations. Since cloud liquid water controls the
  surface longwave balance and thus the BL state, mixed-phase microphysics at low
  temperatures is likely a key process. Many CMIP5 models prescribe a
  temperature-dependent ratio of ice to total condensate (Fig. 15); ECHAM6
  (MPI-ESM-LR's atmosphere) instead computes temperature-dependent freezing rates —
  its ice/total-condensate ratios during the SCM experiment are plotted for
  comparison.
- Test: modify the parameterisation in MPI-ESM-LR to mimic each scheme in Fig. 15
  and re-run the SCM experiment. For all schemes except that used in CCSM4 and
  BCC-CSM-1-1 (which allows a substantial fraction of cloud liquid at cold
  temperatures), the cloudy state disappears (Fig. 16) — freezing of cloud liquid
  at too-warm temperatures can explain the lack of a cloudy state in the analysed
  models except CCSM4. CCSM4 and BCC-CSM-1-1 compute condensate phase the same way,
  yet BCC-CSM-1-1 represents the cloudy state (consistent with the SCM) and CCSM4
  does not — other parameterisations, implementation issues or different
  large-scale conditions may be responsible. In CCSM4 SCM runs, vertically
  integrated total cloudiness never exceeds 0.4, while it is unity during almost
  the entire ECHAM6 experiment (not shown); this cloud-cover difference contributes
  to continuous surface radiative cooling on the order of 40 W m⁻² in CCSM4,
  supporting the suggestion that mechanisms other than the mixed-phase cloud
  microphysics parameterisation cause its missing cloudy state.
- The more complicated GFDL-CM3, GISS-E2-R and MRI-CGCM3 parameterisations could
  not be tested this way, but: GFDL-CM3's freezing parameterisation leads to almost
  complete disappearance of cloud liquid below −15 °C (Rotstayn et al. 2000);
  MRI-CGCM3's Bergeron–Findeisen parameterisation freezes all condensate
  immediately once cloud ice exceeds a threshold of 0.5 mg kg⁻¹ (Yukimoto et al.
  2012) — exceeded immediately once freezing begins in ECHAM6 — so a rapid
  transition to ice clouds is likely; GISS-E2-R combines a temperature-dependent
  freezing probability at any timestep with a Bergeron–Findeisen representation,
  likewise making rapid glaciation very likely (Schmidt et al. 2006).
- Caveat: modifying one parameterisation of a single model to resemble others is no
  substitute for a full intercomparison (cf. CCSM4 vs the CCSM4-mimicking ECHAM6).
  But the experiments show that differences in cloud microphysics among CMIP5
  models can determine the presence or lack of a cloudy state during Arctic air
  formation, all other things being equal.

**Figure 15.** Temperature dependence of condensate phase in different CMIP5
models — solid fraction of condensate (0–1) vs temperature (−50…+10 °C); curves:
ECHAM6, MIROC-ESM, INMCM4, IPSL-CM5, CNRM-CM5, CCSM4/BCC; gray dots are ECHAM6
SCM-experiment ratios.

**Figure 16.** PDFs of surface net longwave radiation in SCM experiment with
perturbed microphysics — same six schemes; x: −60…+20 W m⁻².

### 5.2 Model sensitivity to turbulent diffusivity and heat conduction

- Among models lacking realistic mixed-phase clouds, typical monthly-mean low-level
  stability still varies between 1.5 and 10 K (Fig. 4). Under radiatively clear
  skies, surface temperatures (and thus potentially stability and inversion
  strength) depend on turbulent and conductive heat fluxes to the surface (Sterk
  et al. 2013). Stable boundary-layer diffusivity and snow conductivity are
  perturbed in the ECHAM6 SCM and the idealised experiment re-run (Fig. 17).
- Increased diffusivity under stable conditions: the cloud deepens faster during
  the first days and the transition to clear skies happens earlier (not shown) —
  attributed to stronger mixing between cloud and free-tropospheric air, a source
  of moisture to the Arctic boundary layer (Solomon et al. 2013), leading to faster
  condensation and hence drying of the atmospheric column. Under clear skies, the
  turbulent heat flux toward the surface is reduced by about 25 % in a run with
  reduced diffusivity (slightly stronger stability); downward turbulent heat fluxes
  almost double in the increased-diffusivity run, reducing low-level stability by
  several Kelvin.
- The ocean beneath the sea ice is typically 10–40 K warmer than the Arctic
  wintertime atmosphere — a potentially important heat source. Heat conduction to
  the atmosphere must be balanced by latent heat release from sea-ice formation;
  the conducted heat depends on the thickness, density and specific conductivities
  of ice and snow. Snow conductivity is varied (stars and triangles in Fig. 17) as
  a proxy for inter-model differences in any of those quantities or in model
  formulations influencing conductive heat fluxes. Clear-state inversion strength
  is almost doubled when snow conductivity is halved and reduced to less than half
  the standard value when conductivity is doubled; despite these stability impacts,
  turbulent heat fluxes toward the surface remain almost unchanged.
- Sterk et al. (2013) studied turbulent diffusivity and ice conductivity impacts on
  surface fluxes and near-surface temperatures in a clear-sky stable-BL SCM
  experiment: stronger sensitivity of fluxes and surface temperatures to turbulent
  diffusivity under strong winds (8 m s⁻¹); conductive heat flux and clear-sky
  radiative transfer more important at low wind speeds (2 m s⁻¹) — confirming both
  conductive and turbulent heat fluxes can affect low-level stability and
  inversions under radiatively clear skies, and showing different stable-BL regimes
  must be considered when attributing process roles in a specific model.
- Summary: overestimation of stable boundary-layer diffusivity in most large-scale
  models may contribute to the lack of mixed-phase clouds in CMIP5 models. Weak
  low-level stability under radiatively clear skies (third CMIP5 group) can be
  caused by excessive turbulent mixing or by excessive heat conduction through snow
  and ice.

**Figure 17.** Overview of parameterisation sensitivity experiments in SCM. The
clear state is defined as all timesteps with surface net longwave radiation below
−20 W m⁻² — panels: low-level stability in clear state (2.0–8.0 K) and sensible
heat flux in clear state (3.0–8.0 W m⁻²); symbols: ● standard model, ○ diffusivity
increased, ⊗ diffusivity reduced, ◇ conductivity halved, ☆ conductivity doubled.

## 6. Conclusions

- An idealised single-column experiment of Arctic air-mass formation driven by
  radiative cooling and cloud processes reproduces the observed occurrence of a
  cloudy and a clear state of the Arctic winter boundary layer. The cloudy state
  (little/no surface longwave cooling) occurs when a liquid or mixed-phase cloud
  forms via radiative cooling of a relatively warm, moist air mass advected into
  the Arctic from lower latitudes. As the cloud cools, it transforms into a
  lower-emissivity ice cloud permitting stronger surface cooling — the radiatively
  clear state. Once the ice cloud has precipitated out, the BL remains in the clear
  state until a new moist air mass is advected in. During Arctic air formation,
  inversions are formed by advection, eroded by cooling at cloud level, and formed
  again by surface cooling in the clear state → two typical quasi-stable states,
  with inversions stronger in the clear than the cloudy state.
- Changing individual SCM parameterisations shows the representation of mixed-phase
  cloud microphysics is key to modelling both BL states. Freezing of supercooled
  water at too-warm temperatures, occurring in many CMIP5 models, leads to a lack
  of high-emissivity mixed-phase clouds and thus of a cloudy state. Models lacking
  a cloudy state display excessive surface radiative cooling in Arctic winter,
  tending to produce strong low-level stability and inversions; however, weak
  inversions without high-emissivity clouds may be sustained by excessive downward
  turbulent heat fluxes from the atmosphere or excessive conductive heat fluxes
  from the ocean, both of which warm the surface.
- These processes control the two boundary-layer states and inversion strengths in
  CMIP5 models:
  1. Few models that allow for cloud liquid water at very low temperatures
     reproduce both the clear and cloudy state; among these, mean low-level
     stability depends mostly on the relative occurrence of the two states.
  2. A second group of models lacks the cloudy state and exhibits strong stability
     and strong longwave cooling.
  3. Other models also lack the cloudy state but generate weak stability despite
     strong longwave cooling — possibly caused by excessive sensible and/or
     conductive heat fluxes to the surface.
- The CMIP5 intermodel spread of typical monthly-mean low-level stability over
  winter sea ice is about 10 K, similar to CMIP3 (Medeiros et al. 2011). 15 out of
  21 CMIP5 models overestimate low-level stability over sea ice compared to
  reanalysis data — an overestimation substantially larger than reanalysis biases.
  This widespread bias is linked to shortcomings in mixed-phase cloud microphysics;
  models with a reasonably frequent cloudy state show mean low-level stability in
  good agreement with reanalyses. Understanding turbulent-flux/heat-conduction
  biases behind weak stability despite strong cooling requires closer analysis of
  the third model group; land vs sea-ice differences in cloud properties, energy
  fluxes and inversion strengths remain to be investigated.
- Suggested next steps: compare a wider range of single-column models for an
  idealised case of warm air advection into the Arctic; to better represent the
  Arctic winter boundary layer and surface energy budget in climate models, an
  important step would be to improve mixed-phase cloud microphysics and obtain an
  adequate representation of the cloudy state.

## Acknowledgments (condensed)

Thanks to Tiina Kippeläinen (inspiration for parts of the study), Anthony del
Genio (GISS model), Tongwen Wu (BCC-CSM-1-1), Suvarchal Kumar Cheedela (ECHAM6
SCM), Bjorn Stevens, Dirk Notz, and two anonymous reviewers. SHEBA and ARM
investigators; ERA40/ERA-Interim from the ECMWF data server; HadCRUT3v from the
Climatic Research Unit, Univ. of East Anglia; WCRP WGCM (CMIP5) and modelling
groups (Table 1). Plots generated with NCL (UCAR/NCAR/CISL/VETS 2012). B. Medeiros
acknowledges DOE Office of Science (BER) support; NCAR is sponsored by NSF.

## References

Abbot & Tziperman (2008) *QJRMS* 134(630), 165–185, doi:10.1002/qj.211 · ACIA
(2004) *Impacts of a Warming Arctic — Arctic Climate Impact Assessment*, Cambridge
Univ. Press · Andreas et al. (2002) *JGR Oceans* 107(C10), SHE 8-1–SHE 8-15 ·
Barrett (2012) PhD thesis, Univ. Reading · Bergeron (1935) Proc. 5th Assembly
UGGI, Lisbon, 156–178 · Bintanja, Graversen & Hazeleger (2011) *Nat. Geosci.* 4,
758–761 · Cesana, Kay, Chepfer, English & de Boer (2012) *GRL* 39(20), L20804 ·
Curry (1983) *JAS* 40, 2278–2292 · Curry (1986) *JAS* 43(1), 90–106 · Cuxart et al.
(2006) *Boundary-Layer Met.* 118(2), 273–303 · Devasthale, Sedlar & Tjernström
(2011) *ACP* 11, 9813–9823 · Donner et al. (2011) *J. Clim.* 24(13), 3484–3519 ·
Findeisen (1938) *Meteorol. Z.* 55, 121–133 · Francis & Vavrus (2012) *GRL* 39(6),
L06801 · Fridlind et al. (2012) *JAS* 69(1), 365–389 · Gent et al. (2011)
*J. Clim.* 24(19), 4973–4991 · Gettelman et al. (2006) *JGR* 111(D9), D09S13 ·
Held (1978) *JAS* 35, 2083–2098 · Honda, Inoue & Yamane (2009) *GRL* 36(8),
L08707 · Hourdin et al. (2012) *Clim. Dyn.*, doi:10.1007/s00382-012-1343-y ·
Jones, New, Parker, Martin & Rigor (1999) *Rev. Geophys.* 37(2), 173–199 ·
Jungclaus, Haak, Latif & Mikolajewicz (2005) *J. Clim.* 18(19), 4013–4031 · Klein
et al. (2009) *QJRMS* 135(641), 979–1002 · Lohmann & Roeckner (1996) *Clim. Dyn.*
12(8), 557–572 · Manabe & Wetherald (1975) *JAS* 32, 3–15 · Mauritsen et al.
(2012) *JAMES* 4, M00A01, doi:10.1029/2012MS000154 · Medeiros, Deser, Tomas & Kay
(2011) *J. Clim.* 24, 4733–4740 · Météo France (2009) ARPEGE-Climat V5.1
algorithmic documentation, Météo France/CNRM · Morrison et al. (2012) *Nat.
Geosci.* 4, 11–17, doi:10.1038/ngeo1332 · Overland & Guest (1991) *JGR* 96(C3),
4651–4662 · Pavelsky, Boé, Hall & Fetzer (2011) *Clim. Dyn.* 36(5), 945–955 ·
Persson et al. (1999) 3rd Symp. on Integrated Observing Systems, AMS, Dallas, TX ·
Persson, Fairall, Andreas, Guest & Perovich (2002) *JGR* 107,
doi:10.1029/2000JC000705 · Pithan & Mauritsen (2013) *J. Clim.*,
doi:10.1175/JCLI-D-12-00331.1 · Rotstayn, Ryan & Katzfey (2000) *MWR* 128(4),
1070–1088 · Schmidt et al. (2006) *J. Clim.* 19(2), 153–192 · Scoccimarro et al.
(2011) *J. Clim.* 24(16), 4368–4384 · Serreze, Schnell & Kahl (1992) *J. Clim.*
5(6), 615–629 · Simmons, Uppala, Dee & Kobayashi (2007) ECMWF Newsl. 110, 25–35 ·
Solomon et al. (2013) *JAS* (under review) · Sorteberg, Kattsov, Walsh & Pavlova
(2007) *Clim. Dyn.* 29(2), 131–156 · Sterk, Steeneveld & Holtslag (2013) *JGR
Atmos.* 118, 1199–1217 · Stevens et al. (2013) *JAMES*, doi:10.1002/jame.20015 ·
Stramler, Del Genio & Rossow (2011) *J. Clim.* 24(6), 1747–1762 · Svensson &
Karlsson (2011) *J. Clim.* 24(22), 5757–5771 · Sverdrup (1933) *Meteorology*, The
Norwegian North Polar expedition with the 'Maud' 1918–1925, Sci. Results vol II,
Geophysical Institute, Bergen · Taylor, Stouffer & Meehl (2012) *BAMS* 93(4),
485 · Tjernström (2012) ECMWF GABLS workshop, 7–10 Nov 2011 · Tjernström &
Graversen (2009) *QJRMS* 135(639), 431–443 · Turner & Gyakum (2011) *J. Clim.* 24,
4818–4633, doi:10.1175/2011JCLI3855.1 · UCAR/NCAR/CISL/VETS (2012) NCL v6.0.0
[Software], doi:10.5065/D6WD3XH5 · Uppala et al. (2005) *QJRMS* 131(612),
2961–3012 · Volodin, Dianskii & Gusev (2010) *Izv. Atmos. Ocean Phys.* 46(4),
414–431 · Watanabe et al. (2011) *Geosci. Model Dev.* 4, 845–872 · Wegener (1911)
*Thermodynamik der Atmosphäre*, JA Barth, Leipzig · Wexler (1936) *MWR* 64,
122–136 · Wu et al. (2010) *Clim. Dyn.* 34(1), 123–147 · Xie et al. (2010) *BAMS*
91(1), 13–20 · Yukimoto, Adachi & Hosaka (2012) *J. Meteorol. Soc. Jpn.* 90,
23–64 · Zhang, Seidel, Golaz, Deser & Tomas (2011) *J. Clim.* 24(19), 5167–5186
