# Following moist intrusions into the Arctic using SHEBA observations in a Lagrangian perspective

Ali, S. M., and F. Pithan (2020), *Quarterly Journal of the Royal Meteorological Society*,
doi:10.1002/qj.3859. (Accepted-article version; this transcription is from the accepted
preprint, which had not yet undergone copyediting/typesetting — page furniture and
"Accepted Article" watermarks stripped.)
Affiliations: Alfred Wegener Institute, Helmholtz Centre for Polar and Marine Research,
Bremerhaven; Institute of Environmental Physics, University of Bremen; Institute of
Geography and Oeschger Centre for Climate Change Research, University of Bern.
Funding: Helmholtz Association (HGF), Grant PD-300.
Trajectory dataset: Ali & Pithan (2019), doi:10.1594/PANGAEA.899851.
Figure code: https://github.com/avatar101/project_SHEBA

> **Note on this file:** re-transcribed 2026-07-14 from the source PDF
> (`~/Zotero/storage/9Q2AVKE7/`), replacing an earlier automated PDF text dump
> (recoverable in git history). Tables, equations, and figure captions are
> verbatim; running prose is a faithful condensed rendering, not a word-for-word
> copy — consult the PDF for exact wording.

**Keywords:** air mass transformation, moist air intrusion, cloudy state, Arctic,
Polar atmosphere, SHEBA.
Abbreviations: MI — Moist Intrusions; SHEBA — Surface Heat Budget of the Arctic;
MOSAiC — The Multidisciplinary drifting Observatory for the Study of Arctic Climate.

## Abstract (condensed)

Warm, moist air masses are transported into the Arctic from lower latitudes
year-round; in winter these moist intrusions can trigger cloud formation and surface
warming. The typical cloudy state of the Arctic winter boundary layer has been linked
to advection of moist air masses, but direct observations of the transformation from
moist mid-latitude to dry Arctic air are lacking. Here, SHEBA observations are used to
compile Eulerian observations along the trajectories of warm and cold air masses in a
Lagrangian sense, showing the cooling and drying of air masses over sea ice and
moistening over the open ocean. Air masses originating mostly over open water generate
cloudy conditions at the observation site, whereas air masses originating over
continents or sea ice generate radiatively clear conditions. The authors recommend
using their case studies for modelling work and the method of linking expeditions to
station soundings via back-trajectories for future campaigns.

## 1. Introduction

- The Arctic has sparse observational coverage: hostile climate, drifting sea ice,
  limited satellite retrievals (geographical coverage, low surface contrasts, polar
  night, strong cloudiness). This hampers understanding of polar key processes and
  prediction of Arctic weather/climate amid amplified warming (Hansen et al. 2010).
  Improving Arctic forecasts could also yield more skilful medium-range/sub-seasonal
  NH mid-latitude forecasts (Jung et al. 2014); international efforts are underway
  (Jung et al. 2016; Dethloff et al. 2016).
- SHEBA (Persson et al. 2002) and N-ICE2015 (Granskog et al. 2016) show a **bi-modal
  wintertime Arctic boundary layer**: a radiatively clear and an opaquely cloudy state
  (Stramler et al. 2011; Morrison et al. 2012; Graham et al. 2017), also seen at the
  ARM Utqiaġvik (Barrow) site (Pithan et al. 2014, Fig. 10). Clear state:
  NetLW ~ −40 W m⁻² under clear skies or ice clouds; cloudy state: NetLW ~ 0 W m⁻²
  under low-level mixed-phase clouds. Clear state shows surface-based inversions and a
  dry profile; cloudy state shows elevated, weaker inversions and high moisture
  (Stramler et al. 2011; Cohen et al. 2017). State frequency is crucial for the winter
  surface energy budget and hence winter sea-ice thickness (Morrison et al. 2012).
- Once the ocean freezes, the wintertime Arctic has no major local moisture source
  (leads contribute little overall: Walter et al. 1995; Serreze et al. 2007). A large
  fraction of Arctic wintertime tropospheric water vapour is advected in **moist
  intrusions** — pulses of warm, moist air-mass transport (Doyle et al. 2011),
  increasingly originating in the N. Atlantic and N. Pacific in winter (Woods &
  Caballero 2016), typically triggered by an anticyclonic-blocking feature to the east
  and a low-pressure system to the west (Woods et al. 2013; Pithan et al. 2018), and
  linked to Rossby wave breaking (Liu & Barnes 2015).
- Moist intrusions cause strong downward longwave radiation (high local water vapour)
  and anomalous surface warming over land/sea ice (Kapsch et al. 2013; Pithan et al.
  2014; Park et al. 2015; Woods & Caballero 2016; Pithan et al. 2016; Johansson et al.
  2017). During 2003–2014, intrusions from the N. Atlantic and Pacific caused local
  surface temperature anomalies of up to 8 K and 10 K respectively; implications for
  winter sea-ice recovery and premature spring melt (Kapsch et al. 2013; Mortin et al.
  2016; Kapsch et al. 2016). Nearly half of the 1979–2011 sea-ice concentration
  decline over the Barents–Kara Seas and Baffin Bay has been attributed to enhanced
  downward IR from such intrusions (Park et al. 2015); also associated with July 2012
  Greenland ice-sheet melt (Bennartz et al. 2013).
- Idealised single-column studies of air-mass transformation (Wexler 1936; Curry 1983;
  Emanuel 2008; Pithan et al. 2014) show radiative cooling drives the transformation,
  very sensitively to moisture and cloud condensate. As warm air advects poleward,
  rapid cooling forms cloud droplets; once the liquid-water cloud is radiatively
  opaque, the strongest cooling moves to cloud top (Pithan et al. 2014), driving
  turbulent mixing (Shupe et al. 2013; Brooks et al. 2017), ice formation, and the
  characteristic mixed-phase clouds of the cloudy state — persistent despite the
  inherent instability of the ice–water mixture, due to interacting micro-physical and
  dynamical processes (Morrison et al. 2012; Solomon et al. 2015). Eventually all
  liquid is lost by phase change and precipitation; the remaining ice cloud is
  radiatively transparent, enabling surface cooling and the surface-based inversion
  characteristic of the clear state. Air-mass transformation during transport into the
  Arctic thus plays an important role in forming both states.
- Weather and climate models struggle to represent both states and their
  transformation in a Lagrangian framework (Pithan et al. 2016), producing substantial
  surface energy biases; mixed-phase microphysics (cloud phase partitioning,
  precipitation efficiency) and atmosphere–surface coupling are key weaknesses (Klein
  et al. 2009; Morrison et al. 2012; Pithan et al. 2018). Modelling air-mass
  transformations correctly is essential to capture transitions temporally and
  spatially; improvements would feed back to large-scale processes, ocean/sea-ice
  coupling, forecasts, and Arctic climate projections.
- The observational basis is Eulerian, but transformations occur along Lagrangian
  pathways (Wexler 1936; Curry 1983; Emanuel 2008; Brümmer 1999; Pithan et al. 2018),
  and Pithan et al. (2018) suggest following an advected air mass and observing along
  its path. Repeated observations of individual advected air masses are lacking. This
  study addresses the gap: starting from SHEBA soundings, computing air-mass back
  trajectories, and compiling observations from stations along the trajectory — using
  existing Eulerian observations in a Lagrangian sense to obtain snapshots of an air
  mass at different stages of its transformation. Focus on Arctic winter, when
  open-ocean/sea-ice temperature contrasts strongly force transformations.

## 2. Data and methods

### 2.1 Data

- SHEBA: an icebreaker frozen into Beaufort Gyre sea ice from fall 1997 to summer
  1998; surface station (heat fluxes, standard meteorology), regular radiosondes, and
  ground-based remote sensing for cloud characterisation (Uttal et al. 2002). Unlike
  MOSAiC's 2019/2020 transpolar drift in thin, largely first-year ice, the late-1990s
  SHEBA domain had thick multiyear sea ice, and gyre circulation led to a smaller
  displacement of the drifting station (Dethloff et al. 2016).
- Vaisala RS80-15GH radiosondes deployed daily around 00:00 and 12:00 UTC (actual
  launch times vary slightly); quality-controlled version 2.0 (Moritz 2017).
  Along-trajectory soundings from the Integrated Global Radiosonde Archive (IGRA)
  Version 2 (Durre et al. 2016) — temperature, humidity, and wind at stations in both
  hemispheres, quality-assured (Durre et al. 2006); Python retrieval code on GitHub
  (see Acknowledgements). A separate homogenized Ny-Ålesund sounding dataset was used
  for one case study (Maturilli & Kayser 2016), correcting instrumentation errors with
  higher vertical resolution than IGRA.
- Surface fluxes: flux-group tower at "Met City" in the SHEBA ice camp, processed into
  hourly time series (Edgar et al. 2007) — the Net LW data are used here. Cloud
  base/top from the ETL Radar-Lidar Cloud Properties dataset, combining radar and
  lidar cloud-boundary information (Shupe et al. 2007).

### 2.2 Generating trajectories

- Backward trajectories via the Hybrid Single-Particle Lagrangian Trajectory
  (HYSPLIT) model of NOAA's Air Resources Laboratory (Stein et al. 2015), started at
  actual radiosonde launch times with drifting-camp coordinates, at heights
  corresponding approximately to standard tropospheric pressure levels, extending
  5 days back — the typical time taken by an air mass across the Arctic (Woods &
  Caballero 2016). Trajectory dataset on PANGAEA (Ali & Pithan 2019).
- Driven by ERA-Interim (Berrisford et al. 2011) at 0.75° × 0.75°; winds extracted at
  100, 200, 300, 400, 500, 600, 700, 800, 850, 925 and 1000 hPa at 6-hourly time
  steps. ERA-I offers comparably high spatial resolution, performs better than other
  reanalyses in the Arctic (Jakobson et al. 2012), and assimilated the SHEBA
  soundings; ERA-5 was not yet available when the study was performed. Sea-ice
  concentration for plots: Climate Data Record of Passive Microwave Sea Ice
  Concentration, Version 3 (Meier et al. 2017).
- Consistency checks: (i) forward trajectories restarted from the end-points of the
  backward trajectories; (ii) sensitivity to met-data resolution (2.5° × 2.5° vs
  ERA-I grid); (iii) HYSPLIT's standard meteorological grid-offset ensemble — each
  member's met data offset by 1 grid point horizontally and 0.01 sigma units
  vertically at the starting point. Only cases with small ensemble spread — robust
  trajectories — were selected as case studies.

### 2.3 Compiling observations

- Trajectories sorted into clear/cloudy states at SHEBA using the Net LW criteria of
  Stramler et al. (2011): Net LW < −30 W m⁻² → clear state; Net LW > −10 W m⁻² →
  cloudy state. Transitions can occur within hours (Stramler et al. 2011); a 3-hourly
  running mean of Net LW is used to obtain more persistent boundary-layer states.
- Analysis focuses on individual events, since much of the moisture import into the
  Arctic Ocean occurs in a small number of moist intrusions (Woods et al. 2013; Liu &
  Barnes 2015). Trajectories corresponding to the lower troposphere at SHEBA —
  height above ground level (AGL) between 500–3000 m — are considered, to capture
  transformation processes in the lower atmosphere.
- Sparse Arctic stations with irregular daily time series: a **spatial threshold of
  100 km** is used — a sounding counts only if one of the trajectories passes within
  100 km of the observation station. In most cases the trajectories pass a station no
  more than six hours before/after a sounding. In one case (the station farthest from
  SHEBA, for the 30 December 1998 case study) a sounding was lacking; the two
  adjacent soundings, ~12 hours apart from the passage time, showed consistent
  air-mass properties, so temperature and humidities from both were interpolated to
  the passage time. Forward trajectories were generated from the SHEBA site for the
  cases where the backward trajectories captured observations.
- Rationale: capture transformation of air masses advected in a reasonably barotropic
  manner, as conceptualized in the idealised studies (Wexler 1936; Curry 1983;
  Emanuel 2008; Pithan et al. 2014) — trajectories at different vertical levels
  should stay closely aligned spatially and temporally. In several cases air masses
  converge into SHEBA from different spatial sources (back-trajectories in Figure 8);
  such strongly sheared cases cannot be depicted with Lagrangian observations alone.
  This constraint on air-mass advection, monitored with the ensemble trajectories,
  rules out most of the cloudy-state intrusions during December. Some aspects, such
  as vertical velocities, will differ in the presence of baroclinic disturbances; yet
  the remarkable consistency of cloudy-state observations at SHEBA suggests most
  transformations affect the temperature and humidity profiles similarly, so some
  generalisation of results from strictly barotropic cases is possible.

## 3. Results and discussion

Sorting the 5-day back-trajectories by the air-mass state retrieved over SHEBA shows a
clear distinction in origin: air masses occupying the cloudy state predominantly have
an origin over — or at least travelled over — open ocean outside the Arctic, whereas
clear-state air masses typically travelled over sea ice and continents in the five days
before arrival (Figure 2). Moist air masses are more frequently advected from the
Pacific than the Atlantic sector over SHEBA, owing to the expedition's Beaufort Gyre
location; over the entire Arctic basin, Atlantic moist intrusions play a more dominant
role (Woods & Caballero 2016).

**Figure 1.** "(a) back trajectory computations for ensemble mean vs single member for
4th Jan which are spatially confined (b) back trajectories for 5th Jan where upper
tropospheric levels (dotted lines) diverge from lower levels (solid lines)." — Panels:
(a) 4 Jan 1998 23 UTC; (b) 5 Jan 1998 23 UTC; trajectory height labels 1000, 1400,
1850, 2850, 3950, 5220 m.

**Figure 2.** "5-day back trajectories starting at 1400 m for the cloudy (left) and
clear (right) cases observed at the SHEBA site during DJF. Background colour shows the
mean sea ice concentration for SHEBA DJF (Meier et al., 2017)" — Sea-ice concentration
colour bar 10–90; red dots mark trajectory origins.

### 3.1 Cloudy states caused by moist intrusions

- **Case 1 — moist intrusion beginning 31 Dec 1997, evident at SHEBA in the
  4 Jan 1998 23 UTC sounding.** Best observational coverage of the cases. A strong
  meridional pressure gradient conducted warm, moist air into the Arctic, towards and
  around Greenland and to the SHEBA site, as documented by Woods et al. (2013, their
  Fig. 1) using reanalysis data. IR satellite images (Figure 4, reproduced from
  Persson et al. 2017) capture this warm, moist intrusion from Fram Strait, in
  agreement with the back trajectories (blue dotted lines, Figure 3). Using these
  trajectories the air mass is matched with soundings in the immediate vicinity of
  the ice edge and at Greenland's east coast (Figure 3).
- Profiles obtained over open ocean and at the ice edge (Figure 5A) show a moist,
  near-adiabatic lower-tropospheric structure similar to what is assumed in the
  idealized air-mass-transformation studies of moist intrusions (Wexler 1936; Curry
  1983; Pithan et al. 2014). Observations at the Greenland coast — after the air has
  travelled over sea ice for at least several hours — indicate substantial cooling
  and drying of the lower troposphere up to about 800 hPa. SHEBA cloud observations
  show a low-level cloud layer topping the boundary layer and reaching into the
  temperature/moisture inversion (red and blue triangles in Figure 5A mark cloud top
  and base).
- These observations support Wexler's (1936) conceptual view that clouds deplete the
  lower troposphere of moisture as initially moist air masses are advected into the
  Arctic. While near-surface air cooled by more than 20 K in about three days,
  surface radiative cooling is small or absent when the air mass passes SHEBA
  (NetLW ~ −5.5 W m⁻²). The temperature structure shows a well-mixed boundary layer
  capped by a strong elevated temperature inversion, typical of the cloudy state
  (Stramler et al. 2011). No matching observations were available for the forward
  trajectories in this case.
- On 5 Jan, Persson et al. (2017) show intrusion of drier, clear-sky air from the
  Canadian Archipelago bringing clear conditions at SHEBA — consistent with the back
  trajectories (Figure 3: lower-tropospheric levels intruding from Greenland, higher
  levels from the Canadian Arctic). The apparent contradiction — Persson et al.
  (2017) attributing the cloudy→clear change at SHEBA to changes in wind direction vs
  Pithan et al. (2014) emphasising air-mass transformation from cloudy to clear — is
  merely a difference in perspective: from the Eulerian view of a (nearly) fixed
  observatory such as SHEBA, the 4–5 Jan change is indeed caused by advection of a
  different air mass, as shown by Persson et al. (2017); the Lagrangian perspective
  adopted here and in Wexler (1936), Curry (1983), and Pithan et al. (2018) addresses
  what happens to an initially moist air mass both before and after it passes the
  SHEBA site.
- **Case 2 — air mass arriving at SHEBA on 10 January (Figure 5B).** Originated over
  the Siberian landmasses (brown trajectory lines, Figure 3) but crossed the open
  ocean near Svalbard on its way to SHEBA; the moisture intrusion is also shown in IR
  satellite imagery by Persson et al. (2017, their Fig. 4). A constant
  mid-tropospheric temperature offset suggests either or both sounding datasets may
  have a temperature bias, so discussion focuses on the shape of the profiles, which
  such a bias does not affect. The initial profiles over Russia show a strong
  near-surface temperature inversion, as expected for a continental polar air mass.
  Advected over open ocean, such air masses quickly pick up heat and moisture in a
  vigorously convective boundary layer (Pithan et al. 2018), giving a substantially
  moister lower troposphere as the air passes over Svalbard (blue line, Figure 5B).
  By SHEBA arrival, the near-surface layer has cooled and dried considerably.
- **Cases 3 & 4 — 28 January and 27 February (Figure 5C, D).** Air masses from the
  Pacific Ocean; though modified by uplift and descent when passing over the Alaskan
  Cordillera or Canadian Coast mountains, the profiles still show typical traces of
  the air-mass transformation expected from warm, moist air advected over sea ice —
  an elevated temperature and humidity inversion. Temperature change is not
  interpreted, as the constant offset with height between SHEBA and the other
  soundings might point to a sensor issue.

**Figure 3.** "Back trajectories for the cloudy case studies discussed in this paper at
780 m, 1000 m, 1400 m, 1850 m, 2850 m above ground level, along with sounding stations
depicted by yellow stars." — Legend: 04 Jan 23:00 UTC; 10 Jan 23:00 UTC; 28 Jan
11:00 UTC; 27 Feb 11:00 UTC; sea-ice concentration colour bar 0–100.

**Figure 4.** "IR Satellite images corresponding to Jan 4 1998 case showing the
intrusion of warm and moist air from Fram Strait captured by NOAA's polar orbiting
satellite, figure reproduced from Persson et al. (2017, Figure 1)" — Panels: (c)
2339 UTC Jan 2 '98; (d) 1613 UTC Jan 3 '98; annotations "warmer air", "warm air",
"deep clouds".

**Figure 5.** "Observed profiles of temperature and humidity for cloudy state cases at
the SHEBA site. Circles show observations from upstream sounding stations matching the
corresponding air-mass trajectory." — Four rows (A–D) of temperature (K) and specific
humidity (g kg⁻¹) vs pressure (hPa), with cloud-top (red) and cloud-base (blue)
triangles. Sounding times: (A) 31 Dec 23:00; 02 Jan 00:00; 02 Jan 11:00; 04 Jan 23:00
(SHEBA). (B) 06 Jan 12:00; 07 Jan 00:00; 07 Jan 12:00; 08 Jan 00:00; 10 Jan 23:00
(SHEBA). (C) 27 Jan 11:00; 28 Jan 00:00; 28 Jan 11:00 (SHEBA). (D) 24 Feb 12:00;
25 Feb 00:00; 26 Feb 00:00; 27 Feb 11:00 (SHEBA). Temperature axes ~230–280 K;
humidity axes up to ~4 g kg⁻¹ (A, C, D) and ~2.5 g kg⁻¹ (B).

### 3.2 Clear states at SHEBA following the advection of cold, dry air masses

- Cold, dry air masses with typical aspects of the clear boundary-layer state arrive
  at SHEBA on **30 December** and **12 January**. In both cases the air comes from
  the Siberian side, and at least the section of the back trajectories over the
  Arctic Ocean has anticyclonic curvature — in line with the observation that the
  clear state tends to be associated with anticyclonic conditions (Morrison et al.
  2012) (Figure 6).
- In both cases, the air masses are substantially colder and drier at SHEBA than the
  cloudy-state cases: near-surface temperatures at or below 240 K, and humidity less
  than 1 g kg⁻¹ throughout the troposphere. Upstream soundings are somewhat warmer
  and moister for the air mass reaching SHEBA on 30 December (Figure 7A), and
  substantially more moist for the air mass arriving on 12 January — likely because
  the first case's trajectories come from far inland, whereas the second's originate
  closer to (and for one height level, over) the open ocean.
- Besides confirming that air-mass origin plays a crucial role in determining the
  boundary-layer state in Arctic winter, these observations show that air masses
  continue to cool and dry after reaching the clear state, while qualitatively
  retaining the temperature and moisture profiles characteristic of this
  boundary-layer state.

**Figure 6.** "Back trajectories for selected clear boundary-layer states at SHEBA
levels 780 m, 1000 m, 1400 m, 1850 m, 2850 m above ground, along with sounding stations
depicted by yellow stars." — Legend: 30 Dec 23:00 UTC; 12 Jan, 11:00 UTC; sea-ice
concentration colour bar 0–100.

**Figure 7.** "Observed profiles of temperature and humidity for clear state cases at
the SHEBA site. Circles show observations from upstream sounding stations matching the
corresponding air-mass trajectory." — Two rows: (A) 26 Dec 00:00; 27 Dec 00:00;
27 Dec 12:00; 30 Dec 23:00 (SHEBA) — humidity axis 0–1.50 g kg⁻¹. (B) 8 Jan 12:00;
9 Jan 12:00; 12 Jan 11:00 (SHEBA), with cloud-top/base markers — humidity axis
0–2.5 g kg⁻¹. Temperature axes 220–270 K.

### 3.3 Downstream transformation to the clear state

- Forward (downstream) trajectories from SHEBA allowed matching observations of
  air-mass development after passage over the site in one additional case (Figure 8),
  starting **7 December**. Over SHEBA the air mass is already rather dry and cold,
  but still in the cloudy state (NetLW ~ −9.6 W m⁻²). The downstream sounding one day
  later shows similar air-mass properties — even slightly warmer and moister
  conditions around 800 hPa — while the sounding four days after the air mass passed
  SHEBA shows a substantially colder and drier air mass.
- While the cooling and drying after a moist intrusion is initially confined to the
  lower troposphere, with profiles largely unchanged above 750–800 hPa (Figure 5),
  this example shows the cooling and drying eventually extend further up throughout
  the troposphere. This likely involves processes other than the canonical
  development of Arctic stratus clouds capping the boundary layer; which processes
  control the mid-tropospheric drying and cooling remains to be investigated.
  Downstream observations for the other cloudy-state cases in Figure 3 could not be
  compiled, as their trajectories diverge downstream of SHEBA.

**Figure 8.** "Forward and backward trajectories starting 7th December over the SHEBA
site and matching soundings. No soundings were available for the upstream station shown
in the map." — Map: forward trajectories (blue), backward trajectories (red),
observation stations (stars). Profiles: 7 Dec 23:00 (SHEBA); 8 Dec 12:00; 11 Dec 12:00;
cloud-top/base markers; temperature 230–270 K; specific humidity 0–3 g kg⁻¹.

## 4. Summary and conclusions

- Backward trajectories for radiosondes launched during DJF of the SHEBA icebreaker
  campaign in the Beaufort Gyre show that the **cloudy boundary-layer state**
  (Stramler et al. 2011) is usually associated with a **marine air-mass origin**,
  whereas the **clear state is tied to a continental air-mass source**.
- Comparing SHEBA and upstream soundings for selected barotropic events shows how
  initially warm, moist air masses cool and dry once advected over sea ice. The
  boundary layer is most affected by the cooling and drying, which creates the
  temperature and humidity inversions often found over the Arctic throughout the
  year. In one case, an air mass originating over the continent passed over open
  ocean before reaching the ice edge, rapidly picking up moisture on the way.
- Compiling local observations into a Lagrangian, air-mass-following framework yields
  the **first direct observational evidence of air-mass transformations creating the
  cloudy and clear states** of the Arctic boundary layer (Pithan et al. 2018). The
  approach is recommended for other past, ongoing, and future campaigns.
- A set of case studies is provided where SHEBA soundings can be compared to upstream
  (and in one case downstream) soundings. These cases are recommended for future
  single-column model or Large-Eddy Simulation studies, to go beyond the highly
  idealized studies conducted in the past (Pithan et al. 2016).

### 4.0.1 Supporting information

Supporting information provides the link to the repository hosting the code for
generating the figures used in the study.

**Acknowledgements (condensed).** Helmholtz postdoc project "Understanding the role of
atmosphere surface coupling for large-scale dynamics"; the SHEBA data sets (Moritz
2017; Edgar et al. 2007; Shupe et al. 2007) and the HYSPLIT software tool (Stein et al.
2015); ERA-I (Berrisford et al. 2011); sea-ice concentration data (Meier et al. 2017);
open-source Python packages (McKinney et al. 2010; Hunter 2007; May et al. 2008–2020;
Hoyer & Hamman 2017). Thanks to Thomas Jung for constant support and to two anonymous
reviewers. Figure code: https://github.com/avatar101/project_SHEBA.

**Conflict of interest.** The authors declare no conflict of interest.

## References

Ali & Pithan (2019) Backwards and forward trajectory data for wintertime (DJF)
corresponding to SHEBA expedition, doi:10.1594/PANGAEA.899851 · Bennartz et al. (2013)
*Nature* 496, 83 · Berrisford et al. (2011) The ERA-Interim archive version 2.0, ERA
report series 1, ECMWF, Shinfield Park, Reading, UK · Brooks et al. (2017) *JGR
Atmos.* 122, 9685–9704 · Brümmer (1999) *JAS* 56, 2613–2636 · Cohen et al. (2017)
*JGR Atmos.* 122, 7235–7259 · Curry (1983) *JAS* 40, 2278–2292 · Dethloff, Rex & Shupe
(2016) MOSAiC, 18, 3064 · Doyle et al. (2011) *GRL* 38 · Durre, Vose & Wuertz (2006)
*J. Clim.* 19, 53–68 · Durre et al. (2016) IGRA Version 2, NOAA NCEI,
doi:10.7289/V5X63K0Q · Edgar et al. (2007) Tower, 5-level hourly measurements plus
radiometer and surface data at Met City (ASFG) v1.0, UCAR/NCAR EOL,
doi:10.5065/D65H7DNS · Emanuel (2008) Back to Norway: an essay, *Meteorol. Monogr.*,
87–96 · Graham et al. (2017) *JGR Atmos.* 122, 5716–5737 · Granskog et al. (2016)
*Eos Trans. AGU* 97, 22–26 · Hansen et al. (2010) *Rev. Geophys.* 48 · Hoyer & Hamman
(2017) xarray, *J. Open Res. Softw.* 5, doi:10.5334/jors.148 · Hunter (2007)
Matplotlib, *Comput. Sci. Eng.* 9, 90–95, doi:10.1109/MCSE.2007.55 · Jakobson et al.
(2012) *GRL* 39 · Johansson et al. (2017) *GRL* 44, 2527–2536 · Jung et al. (2016)
*BAMS* 97, 1631–1647 · Jung et al. (2014) *GRL* 41, 3676–3680 · Kapsch, Graversen &
Tjernström (2013) *Nat. Clim. Change* 3, 744 · Kapsch et al. (2016) *J. Clim.* 29,
1143–1159, doi:10.1175/JCLI-D-15-0238.1 · Klein et al. (2009) *QJRMS* 135, 979–1002 ·
Liu & Barnes (2015) *JGR Atmos.* 120, 3774–3788 · Maturilli & Kayser (2016)
Homogenized radiosonde record at station Ny-Ålesund, Spitsbergen in 1998, PANGAEA;
supplement to Maturilli & Kayser (2016) *Theor. Appl. Climatol.*, 17 pp,
doi:10.1007/s00704-016-1864-0 · May et al. (2008–2020) Metpy, doi:10.5065/D6WW7G29 ·
McKinney et al. (2010) *Proc. 9th Python in Science Conf.*, 51–56 · Meier et al.
(2017) NOAA/NSIDC Climate Data Record of Passive Microwave Sea Ice Concentration,
Version 3, NSIDC, doi:10.7265/N59P2ZTG · Moritz (2017) Soundings, Ice Camp NCAR/GLAS
raobs (ASCII) v2.0, UCAR/NCAR EOL, doi:10.5065/D6FQ9V0Z · Morrison et al. (2012)
*Nat. Geosci.* 5, 11 · Mortin et al. (2016) *GRL* 43, 6636–6642 · Park, Lee &
Feldstein (2015) *J. Clim.* 28, 4027–4033 · Persson et al. (2002) *JGR Oceans* 107,
SHE-21 · Persson et al. (2017) *Clim. Dyn.* 49, 1341–1364 · Pithan et al. (2016)
*JAMES* 8, 1345–1357 · Pithan, Medeiros & Mauritsen (2014) *Clim. Dyn.* 43, 289–303 ·
Pithan et al. (2018) *Nat. Geosci.* 11, 805 · Serreze et al. (2007) *JGR Atmos.* 112 ·
Shupe, Intrieri & Uttal (2007) ETL Radar-Lidar 10-min Cloud Physical Properties v1.0,
UCAR/NCAR EOL, doi:10.5065/d6ms3r4g · Shupe et al. (2013) *Atmos. Chem. Phys.* 13,
9379–9399 · Solomon, Feingold & Shupe (2015) *ACP* 15, 10631–10643,
doi:10.5194/acp-15-10631-2015 · Stein et al. (2015) *BAMS* 96, 2059–2077 · Stramler,
Del Genio & Rossow (2011) *J. Clim.* 24, 1747–1762 · Uttal et al. (2002) *BAMS* 83,
255–276 · Walter, Overland & Turet (1995) *JGR Oceans* 100, 4585–4591 · Wexler (1936)
*Mon. Wea. Rev.* 64, 122–136 · Woods & Caballero (2016) *J. Clim.* 29, 4473–4485 ·
Woods, Caballero & Svensson (2013) *GRL* 40, 4717–4721
