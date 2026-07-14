# Select strengths and biases of models in representing the Arctic winter boundary layer over sea ice: the Larcform 1 single column model intercomparison

Pithan, F., A. Ackerman, W. M. Angevine, K. Hartung, L. Ickes, M. Kelley, B. Medeiros,
I. Sandu, G.-J. Steeneveld, H. A. M. Sterk, G. Svensson, P. A. Vaillancourt, and A. Zadra (2016),
*J. Adv. Model. Earth Syst.*, 8, 1345–1357, doi:10.1002/2016MS000630.
Received 13 Jan 2016; accepted 29 Jul 2016; published 27 Aug 2016. Open access (CC BY-NC-ND).
Model results archive: https://doi.org/10.1594/PANGAEA.856770

> **Note on this file:** re-transcribed 2026-07-13 from the source PDF
> (`~/Zotero/storage/X3JQ637K/`), replacing an earlier column-scrambled OCR dump
> (recoverable at git 387fc42). Tables, equations, and figure captions are
> verbatim; running prose is a faithful condensed rendering, not a word-for-word
> copy — consult the PDF for exact wording.

**Key points**
- A Lagrangian-style single column model experiment can reproduce Arctic air mass formation
- Model deficiencies are caused by mixed-phase microphysics, process interaction, and surface representation
- Lagrangian (air mass-following) observations would allow for a tighter constraint on model behavior

## Abstract (condensed)

Models struggle with lower-tropospheric temperature/moisture profiles and surface fluxes
in Arctic winter. Observations reveal two preferred boundary-layer states: a **cloudy state**
(cloud liquid water limits surface radiative cooling; inversions weak and elevated) and a
**radiatively clear state** (strong surface radiative cooling builds surface-based inversions).
Many large-scale models lack the cloudy state; some substantially underestimate clear-state
inversion strength. Larcform 1 — the first Lagrangian Arctic air formation experiment,
organized within GEWEX GASS — models the moist→cold-dry air-mass transformation in an
idealized Lagrangian SCM framework spanning both states. The intercomparison reproduces
the typical biases: some models lack the cloudy state due to mixed-phase microphysics or
micro–macrophysics interaction; in others, high ice-cloud emissivities or a missing
insulating snow layer prevent surface-based inversions in the clear state. Models disagree
substantially on cloudy-state liquid water and clear-sky turbulent heat fluxes.

## 1. Introduction

- Arctic winter: no insolation, continued LW emission → surface radiative deficit balanced
  by sensible heat, latent heat of sea-ice formation, and heat advection from lower
  latitudes. Dominance of low-level/surface radiative cooling forms the Arctic temperature
  inversion → strongly stable stratification → positive lapse-rate feedback, a major
  contributor to Arctic amplification (Manabe & Wetherald 1975; Pithan & Mauritsen 2014).
- SHEBA (1997/98) revealed the two-state structure (Persson et al. 1999, 2002; Stramler
  et al. 2011): **cloudy state** — liquid-containing, often mixed-phase low clouds with
  emissivity near 1 inhibit surface cooling; cloud-top radiative cooling keeps the BL
  well-mixed or weakly stable; inversions elevated near cloud top (clouds often extend into
  the inversion, Sedlar et al. 2012); surface sensible heat fluxes weak, possibly upward.
  **Clear state** — surface radiative cooling ~40 W m⁻² (Stramler et al. 2011) builds
  surface-based inversions; strongly stable; sensible heat flux directed downward.
- Air-mass transformation = formation of continental polar air (Wexler 1936; Curry 1983),
  often originating near the downstream ends of the Atlantic/Pacific storm tracks
  (Woods et al. 2013).
- CMIP5 biases (Pithan et al. 2014; Cesana et al. 2012): many models lack the cloudy state;
  some lack strong clear-state stability (Figure 3 groups). CNRM-CM5 additionally shifts the
  clear state to weaker stability at stronger LW cooling than observed.
- Maintaining supercooled liquid is hard for models (WBF: Wegener 1911; Bergeron 1935;
  Findeisen 1938). Observed liquid often sits *above* the ice cloud (Morrison et al. 2012) —
  vertical structure GCMs do not resolve. LES intercomparisons show strong sensitivity to ice
  number and size distribution (Ovchinnikov et al. 2014); ice-nuclei consumption can limit
  ice formation (Fridlind et al. 2012).
- Aim: understand the two CMIP5 bias types via an idealized Lagrangian SCM experiment
  (setup after Wexler 1936; Curry 1983; Pithan et al. 2014).

## 2. Experimental Strategy, Setup, and Participating Models

### 2.1 Lagrangian vs Eulerian frameworks

Eulerian SCMs would be dominated by prescribed advective tendencies, leaving little freedom
to develop model-specific biases. Larcform 1 instead follows a homogeneous air mass advected
over a homogeneous Arctic sea-ice surface: advective tendencies are set to zero. Models
freely develop their own state/biases over several days. The approach was used successfully
in earlier intercomparisons (Bretherton et al. 1999; van der Dussen et al. 2013).

### 2.2 Boundary and initial conditions

- Analytical initial T/q profiles (Table 1) — a typical air mass entering the Arctic.
- Geostrophic wind 5 m s⁻¹ throughout the troposphere (drives turbulent mixing).
- Initial surface temperature 250 K; 1 m sea ice; 0.1 m w.e. snow on the ice; ocean beneath
  at the freezing point of sea water. Interactive surface temperature is used (justified:
  surface–atmosphere interaction timescale ≪ advection timescale, Persson et al. 1999).
- Run length 20 days; most analyses limited to the first 10 days (beyond typical air-mass
  residence over Arctic sea ice, Woods & Caballero 2016; later temperatures less
  representative).
- Location 80°N, start 1 January → insolation = 0 throughout. GHGs per Table 2.

**Table 1. Initial profiles of temperature, humidity, and geostrophic zonal wind**

| Pressure (hPa) | Temperature (K) | Humidity | u_geo (m s⁻¹) |
|---|---|---|---|
| 1013 | T₀ = 273 | rh wrt water: 80% | 5 |
| 1013–600 | T = T₀ (p/p₀)^(Rγ/g) | linear interpolation of rh | 5 |
| 600 | T = T₀ (p/p₀)^(Rγ/g) | rh wrt water: 20% | 5 |
| 600–300 | T = T₀ (p/p₀)^(Rγ/g) | rh wrt water: 20% | 5 |
| 300–model top | T = T₃₀₀ₕₚₐ | q = 3 × 10⁻⁶ kg kg⁻¹ | 0 |

Meridional geostrophic wind = 0. p₀ = 1013 hPa, lapse rate γ = 8 × 10⁻³ K m⁻¹,
R = 287 J kg⁻¹ K⁻¹, g = 9.81 m s⁻². Temperature profile based on Curry [1983].

**Table 2. Greenhouse gas concentrations (volume-mixing ratio)**

| CO₂ | N₂O | CH₄ | CFC-11 | CFC-12 |
|---|---|---|---|---|
| 360 × 10⁻⁶ | 309.5 × 10⁻⁹ | 1693.6 × 10⁻⁹ | 252.8 × 10⁻¹² | 466.2 × 10⁻¹² |

### 2.3 Participating models

WRF 3.5.1 SCM uses Mellor-Yamada-Janjic BL scheme, NOAH land surface, eta-similarity
surface layer, RRTMG radiation, WRF single-moment 5-class microphysics. CAM SCM constrains
winds to geostrophic values (sensitivity tests suggest wind differences do not qualitatively
alter either BL state). Standard runs denoted *std*; model-specific sensitivity runs are
introduced in context.

**Table 3. Models participating in the intercomparison**

| Model | Documentation | Phase of condensate | Snow and ice | z₀ₘ (m) | Contributor |
|---|---|---|---|---|---|
| CAM 5.3 | Neale et al. [2010] | Prognostic | Interactive | 5e-3 | FP and BM |
| CMC-GDPS | Bélair et al. [2009] | f(T) | Interactive | 1.6e-4 | AZ |
| CMC-HRDPS | Mailhot et al. [2006] | Prognostic | Interactive | 1.6e-4 | AZ |
| CMC-RDPS | Mailhot et al. [2006] | f(T) | Interactive | 1.6e-4 | AZ |
| EC-Earth V3 (IFS 36r4) | ECMWF [2010] | Prognostic | No snow, fixed ice | 1e-3 | KH |
| ECHAM 6.2 | Stevens et al. [2013] | Prognostic | Interactive | 1e-3 | FP |
| ECHAM6.1.0-HAM2.2 | Stevens et al. [2013]; Lohmann et al. [2007] | Prognostic | Interactive | 1e-3 | LI |
| ECMWF-IFS | ECMWF [2010] | Prognostic | No snow, fixed ice | 1e-3 | IS |
| GISS E2 | Schmidt et al. [2014] | p(T) | Fixed ice | νₘ/u∗ + 0.018 u∗²/g | AA |
| WRF 3.5.1 | Skamarock et al. [2008] | Prognostic | Fixed ice | 1e-3 | HAMS and WA |
| WUR-D91 | Duynkerke [1991] | Ice | Fixed ice | 1e-1 | GJS |

Legend: *Prognostic* — separate prognostic variables for cloud ice and liquid with
parametrized freezing rates; *f(T)* — phase partitioning as a function of temperature;
*p(T)* — temperature-dependent probability for total freezing of condensate at each time
step; *ice* — all condensate assumed ice; *fixed ice* — fixed ice thickness; *no snow* —
no snow on sea ice. z₀ₘ = momentum roughness length.

## 3. Results and Discussion

No observational or LES "truth" exists for this idealized case; evaluation is qualitative —
whether and why models reproduce the typical fluxes/profiles of both BL states, with SHEBA
as observational reference. Cloud lifetime, heat fluxes etc. are not interpreted
quantitatively.

Overview: most models generate a **bimodal distribution of surface net LW radiation**
(Figure 4; fluxes positive downward), i.e. both states are represented (Table 4). Models
tend to have slightly less surface radiative cooling than observed in the clear state and
slightly more in the cloudy state. **CAM 5.3 and GISS std lack the cloudy state**
(unimodal PDF). **WUR-D91 only displays the cloudy state** (weak surface cooling
throughout). At day 2 (Figure 5), elevated inversions dominate in models with a cloudy
state; CAM5.3/GISS std already show surface-based inversions; WRF std is transitioning
(its day-1 cloud vanished but the elevated inversion persists). By day 10 (Figure 6),
surface-based inversions dominate in ECHAM6.2, ECHAM-HAM, GISS std, WRF std, CAM5.3;
WUR-D91, CMC (all versions), EC-Earth, and ECMWF-IFS remain well-mixed/near-neutral near
the surface. (State transitions are deliberately not analyzed — Eulerian observations
confound them with air-mass changes.)

**Table 4. Groups of models according to their representation of BL states**

| | With cloudy state | Lacking a cloudy state |
|---|---|---|
| **Strong stability in clear state** | ECHAM6.2, ECHAM-HAM, WRF std, CAM5.3 (process split), GISS vmp, CMC-GDPS (modified microphysics) | WRF-200l, CAM5.3 (std), GISS std |
| **Weak stability in clear state** | ECMWF-IFS, EC-Earth, CMC-GDPS (standard) | |

### 3.1 Existence or lack of the cloudy state

- **CAM5.3**: lacks cloud liquid despite sophisticated microphysics. Cause: *time-split*
  coupling of macrophysics → microphysics → radiation (Williamson 2002). Macrophysics makes
  liquid; the following microphysics call converts it all to ice; radiation then sees no
  liquid → cooling at the surface, not cloud top, further suppressing liquid formation
  (cf. Caldwell 2012 "disappearing condensate"; English et al. 2014). Fix tested here:
  call micro- and macrophysics *process-split* (parallel, summed tendencies) → liquid
  persists for several days, radiative cooling reduced, surface inversion delayed; a second
  (cloudy) peak appears in the net-LW PDF (Figure 7).
- **GISS std**: condensate all-liquid or all-ice at a given time/place, with a
  temperature-dependent probability of instantaneous total freezing → no persistent
  mixed-phase cloud. With the *virtual mixed-phase* scheme (GISS vmp), liquid appears after
  ~1 day, surface cooling drops to observed cloudy-state levels, and an elevated inversion
  forms.
- **WRF resolution dependency**: WRF-90l produces the cloudy state; very-high-resolution
  WRF-200l does not. Its 1.2 m-thick lowest level dries to the surface via frost deposition
  before cloud formation; air saturates wrt ice but never wrt water → no liquid. Very high
  vertical resolution can violate implicit parametrization assumptions (would need faster
  interlayer coupling / shorter time step).

### 3.2 Build-up of surface-based inversions under radiatively clear skies

- ECHAM6.2, ECHAM-HAM, WRF-90l, CAM5.3 build the observed surface-based inversions under
  sustained clear-sky cooling.
- **CMC models** stay well-mixed even without liquid: exaggerated **ice-cloud emissivity**
  (too-small ice effective radius + overestimated IWP). With enhanced ice precipitation
  efficiency (Appendix A), CMC-GDPS removes nearly all cloud ice by day 10 (Figure 8a; std
  version has among the highest IWP), gets stronger clear-state cooling (Figure 8b), and
  develops a surface-based inversion (Figure 8c).
- **WUR-D91**: extreme ice-emissivity case — maintains a single well-mixed layer and
  cloudy-state fluxes throughout despite all-ice condensate.
- **EC-Earth & ECMWF-IFS**: no surface-based inversions despite substantial cooling —
  cause is the **missing snow layer**. An ECHAM6.2 no-snow sensitivity run reproduces their
  profiles/fluxes. Snow's low conductivity strongly reduces ocean→surface heat flux.
  Consistent with ERA-Interim lacking early-winter surface inversions at SHEBA
  (Tjernström & Graversen 2009).

### 3.3 Turbulent heat flux, cloud liquid water, and energy budget

- Observed clear-state downward sensible heat flux ~10 W m⁻² (Stramler et al. 2011).
  No-snow models produce much smaller clear-state fluxes; remaining models still vary by a
  factor of ~5 (Table 5). Larger SHEBA fluxes may reflect higher wind speeds there. Friction
  velocity varies more between models than between states within a model.
- Cloudy-state LWP varies by an order of magnitude across models — small amounts of liquid
  suffice to sustain the cloudy state. SHEBA median winter LWP is at the low end of model
  results; the model high end exceeds the observed 95th percentile (Shupe et al. 2006) —
  though a more realistic setup (e.g. subsidence-constrained cloud height) would be needed
  to call this an overestimate.
- Greatest accumulated 10-day surface energy deficit occurs in the no-snow models.
  Excluding WUR-D91, accumulated loss varies ~50% across models. GISS cloud+snow changes
  roughly halve it; making mixed-phase clouds appear in CAM5.3 reduces it ~20%. The loss is
  largely balanced by latent heat of sea-ice growth.

**Table 5. Turbulent heat fluxes (positive downward) in the clear state, cloud liquid
water in the cloudy state, and net surface energy loss over the first 10 days**

| Model | hs (clear) (W m⁻²) | clwvi (cloudy) (kg m⁻²) | Net sfc energy loss 10³ (kJ m⁻²) |
|---|---|---|---|
| EC-Earth | 0.23 | 0.037 | 27.3 |
| ECMWF-IFS | 1.65 | 0.029 | 24.1 |
| ECHAM6.2 | 5.12 | 0.16 | 17.5 |
| ECHAM-HAM | 8.02 | 0.39 | 15.5 |
| CMC-GDPS | 3.09 | 0.01 | 12.9 |
| GISS std | 5.79 | — | 18.3 |
| WRF-90l | 12.05 | 0.05 | 13.0 |
| WUR-D91 | — | 0 | 6.3 |
| CAM5.3 | 9.57 | — | 16.5 |
| GISS vmp | 3.97 | 0.04 | 8.2 |
| CAM5.3 (process split) | 9.70 | 0.02 | 13.0 |

Clear and cloudy state are partitioned at a surface net longwave radiation of −20 W m⁻².

## 4. Conclusions

Two bias types reproduced and diagnosed:

1. **Lack of mixed-phase clouds / cloudy state.** All schemes with separate prognostic
   ice+liquid variables and explicit freezing rates qualitatively reproduce the cloudy
   state (CMC also does with diagnostic f(T) partitioning). CAM5.3 fails despite
   sophisticated microphysics because of time-split micro/macro/radiation coupling; the
   same physics process-split reproduces mixed-phase clouds. GISS's p(T) total-freezing
   scheme cannot hold a persistent mixed-phase cloud; GISS vmp can.
2. **Weak low-level stability / missing surface-based inversions** occur in models without
   snow on sea ice or with high atmospheric (ice-cloud) emissivities that maintain
   downwelling LW without liquid. Ice-cloud precipitation efficiency can control inversion
   development (CMC). Turbulent-flux differences under stable stratification are confirmed
   but secondary for this case.

The idealized case cannot quantitatively constrain cloud occurrence, turbulent fluxes, or
LWP (all vary considerably). Next step: a more realistic observationally based setup;
Lagrangian observations (e.g. Year of Polar Prediction) would allow tighter constraints.

## Appendix A: Sensitivity experiment for CMC microphysics

CMC-GDPS uses Sundqvist [1978] microphysics: precipitation generation (Sundqvist eq. 3.1a)
depends on a conversion timescale (c₀f⁻¹) and a threshold cloud-water value (m_rf) above
which precipitation formation becomes more efficient, modulated by a freezing function
[Mailhot et al., 1998]:

```
            ⎧ min(1, 1.33·exp(−0.066(T−T₀)²))          for 250 K ≤ T ≤ T₀
f_mr(T) =   ⎨                                                              (A1)
            ⎩ max(0.03, 0.75·(1.07 + ε·y/(1+y)))        for T ≤ 250 K
```

where y = x(1 + x(1 + 1.333x)), x = |T − 232|/18, ε = sign(T − 232), T₀ = 273.15 K.
For the sensitivity test in section 3.1, precipitation formation is accelerated by reducing
both the conversion timescale and the threshold value; the modified freezing function reads

```
            ⎧ min(1, 1.33·exp(−0.066(T−T₀)²))   for 230 K ≤ T ≤ T₀
f_mr(T) =   ⎨                                                              (A2)
            ⎩ 0.001                              for T ≤ 230 K
```

## Figures (captions verbatim; content notes added)

- **Figure 1.** "Bivariate pdf of low-level stability (defined as 850 hPa minus surface
  temperatures) and surface net longwave radiation defined positive downward, NDJF
  1997/1998 for SHEBA and NDJF 1990–1999 for the ARM site. Low-level stability is computed
  from individual soundings and surface radiation from the corresponding 6 h average.
  Figure source: Pithan et al. [2014]." — Two panels (ARM Barrow, SHEBA); x: stability
  −20…40 K, y: net LW +30…−90 W m⁻²; cloudy-state blob near (0, 0), clear-state blob near
  (10–20, −30…−60); white diagonal reference line; PDF levels 0.02–0.5.
- **Figure 2.** "Sketch of Arctic air mass formation. Curved arrows represent radiative
  cooling, red lines are temperature profiles, which are driven toward the dashed lines by
  radiative cooling in the respective state. Full boxes mark quasi-steady states and dashed
  boxes unstable transition states. Source: Pithan et al. [2014]." — (a) initial moist
  profile, (b) cloudy state, (c) transition, (d) clear state w/ surface inversion.
- **Figure 3.** "Bivariate PDFs as in Figure 1 using CMIP5 model output from the ocean
  domain north of 64°N. The models shown serve as examples for the three groups of models
  determined in Pithan et al. [2014]. White lines are included as visual reference
  indicating the observed relationship between stronger inversions and weaker surface
  cooling within the clear state." — MPI-ESM-LR (both states, strong stability), CCSM4
  (clear only, strong stability), CNRM-CM5 (weak stability).
- **Figure 4.** "PDF of hourly means of surface net longwave radiation in participating
  models for days 1–10 and NDJF SHEBA observations. Each tickmark corresponds to the center
  of one bin." — x: −77.5…+2.5 W m⁻² (bin width 5); annotated groups: two BL states
  (WRF std, ECHAM-HAM, ECHAM6.2, EC-Earth, ECMWF-IFS, CMC-GDPS), lack of mixed-phase
  clouds (CAM5.3, GISS std), lack of radiatively clear sky (WUR-D91); SHEBA obs black.
- **Figure 5.** "Temperature profiles averaged over 1 h after 2 days." — p 800–1013 hPa,
  T 252–270 K; elevated inversions: EC-Earth, ECMWF-IFS, ECHAM6.2, ECHAM-HAM, WUR-D91,
  CMC-GDPS; surface-based: CAM5.3, GISS std; WRF std intermediate.
- **Figure 6.** "Temperature profiles averaged over 1 h after 10 days." — p 500–1013 hPa,
  T 220–255 K; surface-based inversion: CAM5.3, GISS std, ECHAM6.2, ECHAM-HAM, WRF std;
  no surface-based inversion: EC-Earth, ECMWF-IFS, CMC-GDPS; WUR-D91 well-mixed.
- **Figure 7.** "PDF of surface net longwave radiation in selected models (up to day 10)
  and NDJF SHEBA observations. Each tickmark corresponds to the center of one bin." —
  sensitivity runs: CAM5.3 (process split), GISS vmp, WRF std have two states; WRF-200l,
  CAM5.3 std (time split), GISS std lack mixed-phase clouds.
- **Figure 8.** "(a) Vertically integrated ice water paths for the CMC-GDPS standard and
  modified versions and other models (gray). (b) PDF of surface net longwave radiation for
  the CMC-GDPS standard and modified versions, and NDJF SHEBA observations. (c) Vertical
  profiles of temperature after 10 days, CMC-GDPS standard and modified versions and other
  models (gray)." — (a) IWP 0–0.08 kg m⁻² over hours 0–240.

## References

Barrett (2012) PhD thesis, Univ. Reading · Beare et al. (2006) *BLM* 118, 247–272 ·
Bélair et al. (2009) *Wea. Forecasting* 24, 690–708 · Bergeron (1935) UGGI Lisbon,
156–178 · Bretherton et al. (1999) *BLM* 93, 341–380 · Caldwell (2012) CESM Workshop ·
Cesana et al. (2012) *GRL* 39, L20804 · Curry (1983) *JAS* 40, 2278–2292 · Cuxart et al.
(2006) *BLM* 118, 273–303 · Duynkerke (1991) *MWR* 119, 324–341 · ECMWF (2010) IFS
cy36r1 Part IV · English et al. (2014) *J. Clim.* 27, 5174–5197 · Findeisen (1938)
*Meteorol. Z.* 55, 121–133 · Fridlind et al. (2012) *JAS* 69, 365–389 · Hong et al.
(2004) *MWR* 132, 103–120 · Iacono et al. (2008) *JGR* 113, D13103 · Janjic (1994) *MWR*
122, 927–945 · Jung et al. (2016) *BAMS* doi:10.1175/BAMS-D-14-00246.1 · Lohmann et al.
(2007) *ACP* 7, 3425–3446 · Mailhot et al. (1998) RPN Physics Library 3.6 · Mailhot
et al. (2006) *Atmos. Ocean* 44, 133–149 · Manabe & Wetherald (1975) *JAS* 32, 3–15 ·
Medeiros et al. (2011) *J. Clim.* 24, 4733–4740 · Morrison et al. (2012) *Nat. Geosci.*
5, 11–17 · Neale et al. (2010) NCAR TN-486+STR · Ovchinnikov et al. (2014) *JAMES* 6,
223–248 · Persson et al. (1999) 3rd Symp. Integrated Obs. Sys. · Persson et al. (2002)
*JGR* 107, doi:10.1029/2000JC000705 · Pithan & Mauritsen (2014) *Nat. Geosci.* 7,
181–184 · Pithan et al. (2014) *Clim. Dyn.* 43, 289–303 · Schmidt et al. (2014) *JAMES*
6, 141–184 · Sedlar et al. (2012) *J. Clim.* 25, 2374–2393 · Shupe et al. (2006) *JAS*
63, 697–711 · Skamarock et al. (2008) NCAR WRF v3 · Sterk et al. (2013) *JGR Atmos.*
118, 1199–1217 · Stevens et al. (2013) *JAMES* 5, 146–172 · Stramler et al. (2011)
*J. Clim.* 24, 1747–1762 · Sundqvist (1978) *QJRMS* 104, 677–690 · Svensson & Karlsson
(2011) *J. Clim.* 24, 5757–5771 · Sverdrup (1933) Maud expedition Sci. Results II ·
Tjernström (2012) ECMWF GABLS Workshop · Tjernström & Graversen (2009) *QJRMS* 135,
431–443 · van der Dussen et al. (2013) *JAMES* 5, 483–499 · Wegener (1911)
*Thermodynamik der Atmosphäre* · Wexler (1936) *MWR* 64, 122–136 · Williamson (2002)
*MWR* 130, 2024–2041 · Woods & Caballero (2016) *J. Clim.* 29, 4473–4485 · Woods et al.
(2013) *GRL* 40, 4717–4721 · WWRP (2014) YOPP Implementation Plan · Zhang et al. (2011)
*J. Clim.* 24, 5167–5186
