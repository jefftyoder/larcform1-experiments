# Arctic amplification dominated by temperature feedbacks in contemporary climate models

Pithan, F., and T. Mauritsen (2014), *Nature Geoscience*, 7, 181–184, doi:10.1038/NGEO2071.
Received 25 November 2013; accepted 19 December 2013; published online 2 February 2014.
© 2014 Macmillan Publishers Limited.
Affiliation: Max Planck Institute for Meteorology, Bundesstrasse 53, Hamburg D-20146, Germany.
Corresponding author: felix.pithan@mpimet.mpg.de

> **Note on this file:** re-transcribed 2026-07-14 from the source PDF
> (`~/Zotero/storage/EQ9NDHN4/`), replacing an earlier automated PDF text dump
> (recoverable in git history). Tables, equations, and figure captions are
> verbatim; running prose is a faithful condensed rendering, not a word-for-word
> copy — consult the PDF for exact wording.

## Abstract (condensed)

Climate change is amplified in the Arctic — in past warm and glacial periods, in historical
observations, and in climate model experiments. Feedbacks involving temperature, water vapour and
clouds have all been proposed as contributors, but the **surface albedo feedback** (increased
absorption of solar radiation as snow and ice retreat) is most often cited as the main cause. Yet
Arctic amplification also occurs in models without changes in snow and ice cover. Analysing CMIP5
simulations to quantify each feedback's contribution, the authors find the largest contribution comes
from **temperature feedbacks**: as the surface warms, more energy is radiated back to space in low
latitudes than in the Arctic. This is attributable to (i) the different vertical structure of warming
in high versus low latitudes (lapse-rate feedback) and (ii) the smaller increase in emitted blackbody
radiation per unit warming at colder temperatures (Planck feedback). The surface albedo feedback is
the **second** main contributor; other contributions are substantially smaller or even oppose Arctic
amplification.

## 1. Motivation

- Quantifying the mechanisms behind Arctic amplification is key for constraining projections and for
  focusing research effort and model–data comparison on the most important processes.
- Arctic amplification is partly caused by the surface albedo feedback, but IPCC AR4 already stated it
  was not clear whether albedo was the main cause. Amplification occurs in models without surface
  albedo feedback, and amplification in coupled models has been shown to be driven primarily by
  feedbacks acting on terrestrial longwave radiation — implying the (shortwave-acting) surface albedo
  feedback can play only a secondary role.
- Other proposed contributors: water vapour feedback, cloud feedback, lapse-rate feedback, and changes
  in atmospheric and oceanic heat transport.

## 2. Temperature feedbacks

The direct impact of rising temperature on outgoing longwave radiation at the top of the atmosphere
(TOA) — the **temperature feedback** — decomposes into:

- **Planck feedback:** vertically uniform warming of surface and troposphere.
- **Lapse-rate feedback:** tropospheric warming that deviates from the vertically uniform profile.

**Lapse rate.** In the tropics, deep convection tightly couples surface and upper troposphere; in a
warmer climate rising parcels release more latent heat, steepening the moist adiabat, so the upper
troposphere warms more than the surface. This top-heavy warming profile radiates efficiently, so a
smaller surface warming suffices to offset a given TOA imbalance. In the Arctic, cold dense air near
the surface is hardly mixed with lighter air aloft, leaving radiation as the primary coupling
mechanism; radiative coupling does not impose a fixed lapse rate, so surface-based warming stays
confined to the lowermost atmosphere. Under this bottom-heavy profile a **larger** surface warming is
required to offset the same TOA imbalance. The lapse-rate feedback is therefore **negative in the
tropics and positive in the Arctic**.

**Planck.** Longwave radiation *R* emitted by the surface rises with temperature *T* following
`R = ε σ T⁴`, with ε the surface emissivity (close to unity) and σ the Stefan–Boltzmann constant. A
given increase in emitted radiation thus requires a larger temperature increase at colder background
temperatures. Example given in the paper: at 30 °C, an external forcing of 1 W m⁻² is balanced by a
0.16 °C warming, whereas at −30 °C a 0.31 °C warming is required to balance the same forcing. Because
the Arctic is colder than the tropics, the Planck feedback in itself causes Arctic amplification —
a contribution generally overlooked despite the underlying physics being well established.

The local temperature change required to offset the radiative imbalance caused by a given forcing or
feedback corresponds to that mechanism's warming contribution. Individual contributions to Arctic
amplification are assessed as the difference between contributions to Arctic and to tropical warming
(Figure 2). Radiative kernels give the flux change at surface and TOA associated with a known surface
temperature change; here the kernel method is **inverted** to compute the local warming contributions
of the feedbacks. The Planck feedback's spatial structure is estimated as the difference between the
warming response for a globally averaged and for the local Planck feedback (Methods).

## 3. CMIP5 results

**Figure 1 | Arctic amplification in CMIP5 models. a**, Zonal mean surface temperature change for the
last 30 years of the CMIP5 4 × CO₂ experiment compared with the last 30 years of the control run. Box
and whisker plots show the median, 25th to 75th percentiles (boxes) and full spread (whiskers) of
temperature change averaged over the tropics (30° S–30° N) and the Arctic (60° N–90° N). **b**, Bars
show the intermodel mean warming for different seasons. Intermodel mean warming is 11.2 K in the
Arctic and 4.3 K in the tropics. Arctic warming is strongest in winter (15.9 K) and weakest in summer
(6.5 K). March–May, MAM; September–November, SON.

- **Conventional TOA decomposition (Figure 2a):** the largest contributor to Arctic amplification is
  the **lapse-rate feedback**, followed by the **surface albedo** and **Planck** feedbacks. In absolute
  terms the surface albedo feedback contributes slightly more to Arctic warming, but the lapse-rate
  feedback additionally *reduces* tropical warming and therefore makes the greater contribution to
  Arctic amplification (inferable from the distance to the 1:1 line). The water vapour feedback and
  CO₂ radiative forcing both lead to greater warming in the tropics, **opposing** Arctic amplification.
- **Fixed-relative-humidity framework:** treating warming and moistening as one feedback at constant
  relative humidity, plus a small feedback for relative-humidity changes, assigns only a slightly
  larger contribution to Arctic amplification to the alternative lapse-rate feedback
  (Arctic **+3.8 K**, tropics **−2.2 K**) than to the surface albedo feedback (Arctic **+5.7 K**),
  whereas the effect of the alternative Planck feedback on Arctic amplification is close to zero. In
  this framework the temperature–moisture and the surface albedo contributions are of roughly equal
  importance.
- **Seasonality (Figures 1b, 2b):** Arctic warming is stronger in winter (DJF) than summer (JJA). From
  a TOA perspective, surface albedo and water vapour feedbacks contribute to stronger summer warming
  but are outweighed by seasonal heat storage in the ocean and by the lapse-rate feedback. Seasonal
  ocean heat storage, including latent heat of melting sea ice, mitigates about **two-thirds** of the
  summertime effect of surface albedo change. Heat released from the ocean in winter, combined with the
  positive lapse-rate feedback, produces the well-known winter-amplified warming pattern. In summer,
  when atmospheric stability is much weaker, the Arctic lapse-rate feedback is actually slightly
  negative.
- **Surface perspective (Figure 2c):** The TOA decomposition is internally consistent but physically
  unsatisfying, since the Arctic lapse-rate feedback reflects the breakdown of an assumption of
  vertical coupling rather than a specific physical mechanism. At the surface the temperature feedback
  decomposes into a negative **surface warming feedback** (longwave emitted from the surface) and a
  positive **atmospheric warming feedback** (downwelling longwave received by the surface). The largest
  contribution to Arctic amplification arises from the surface temperature feedback, due to the smaller
  increase in longwave emission per unit warming at colder temperatures. This nonlinear blackbody
  dependence matters more from a surface than a TOA perspective because the meridional temperature
  gradient at the surface is larger than in the troposphere. The atmospheric temperature feedback
  contributes to Arctic amplification because the near-surface atmosphere warms more in the Arctic than
  in the tropics. Previous surface-perspective decompositions used a methodology that implicitly
  includes the spatial structure of the temperature feedback and therefore did not identify the key
  role of the surface temperature feedback's structure.

**Figure 2 | Warming contributions of individual feedback mechanisms. a**, Arctic versus tropical
warming from a TOA perspective. **b**, Arctic winter versus summer warming. **c**, Arctic versus
tropical warming from a surface perspective. For **a**,**c**, feedbacks above the 1:1 line contribute
to Arctic amplification, whereas feedbacks below the line oppose Arctic amplification. Grey is the
residual error of the decomposition. 'Ocean' includes the effect of ocean transport changes and ocean
heat uptake.

## 4. Clouds

In the annual mean, cloud feedback **opposes** Arctic amplification from a TOA perspective, but makes a
small **positive** contribution from a surface perspective. Within the lowest 1–2 km of the Arctic
atmosphere, cloud-top temperatures are often similar to surface temperatures; low-level clouds then
radiate upwards at roughly the same temperature as the surface, so they hardly affect TOA longwave
fluxes, but they increase downward longwave radiation and thus warm the surface at the expense of the
atmosphere. An increase or thickening of such clouds in a warming climate, as models predict, hardly
affects TOA cloud feedback but causes a positive cloud feedback at the surface. Likewise, the water
vapour feedback contributes more to summer than winter warming from a TOA perspective, but has a
stronger contribution to surface warming in winter than in summer.

## 5. Intermodel spread

**Figure 3 | Intermodel spread of Arctic warming contributions of feedbacks versus total Arctic
warming in individual models.** Lines are linear regressions of feedback contributions against total
Arctic warming. Filled circles on the black vertical line represent the ensemble mean. The right-hand
side shows the spread of Arctic warming contributions in the analysed models. Boxes show the median,
25th and 75th percentiles, and whiskers show the full ensemble spread.

- Intermodel spread in Arctic warming is dominated by the spread in **local feedback mechanisms**, not
  in meridional transport changes (Figure 3).
- Changes in atmospheric heat transport **dampen** intermodel spread, because they are more positive in
  models with little Arctic warming — consistent with energy-balance-model reconstructions of CMIP3.
- In the ensemble mean, atmospheric heat transport does contribute to Arctic amplification by enhancing
  Arctic and reducing tropical warming (Figure 2a).
- Contrary to physical intuition, poleward atmospheric energy transport does not scale with the
  meridional temperature gradient within individual models, but increases in most models despite a
  reduction of the Equator-to-pole temperature contrast; increasing latent energy transports
  overcompensating the decrease of dry static energy transport have been shown to cause such behaviour.
- Changes in ocean transport and ocean heat uptake are **not correlated** with total Arctic warming
  across models.

Models labelled in Figure 3 (ordered by total Arctic warming): INMCM4, GISS-E2-R, CCSM4, IPSL-CM5B-LR,
IPSL-CM5A-LR, MRI-CGCM3, BCC-CSM-1-1, NORESM1-M, FGOALS-s2, MPI-ESM-LR, CNRM-CM5, MIROC5, CanESM2,
MIROC-ESM, ACCESS1-0, GFDL-CM3, HadGEM2-ES.

## 6. Conclusion

Contrary to a widespread assumption, **temperature feedbacks are the most important contributors to
Arctic amplification in contemporary climate models**. The surface albedo feedback is the second main
contributor, whereas other suggested drivers of Arctic amplification either play minor roles or even
oppose it in the ensemble mean.

## Methods

Previous studies have often diagnosed feedbacks from TOA and surface fluxes routinely archived in
climate model output. Those methods give a precise assessment of longwave and shortwave flux changes,
but cannot quantify the temperature changes associated with individual feedback mechanisms. Here the
**radiative kernel technique** is used and extended to overcome this limitation.

A radiative kernel `kᵢ` is the change in TOA radiation `ΔR` caused by a small change in the climate
variable `xᵢ` — for example a one per cent change in surface albedo (`dxᵢ`): `kᵢ = dR/dxᵢ`. The TOA
flux change caused by one feedback in a climate change experiment can be estimated as
`ΔRᵢ = kᵢ · Δxᵢ`, where `Δxᵢ` is, for instance, the surface albedo change between the control and
perturbed runs. This established technique is used to compute the flux change caused by each feedback,
and is extended to convert those flux changes into temperature responses associated with each feedback.

The warming response to a TOA flux imbalance is decomposed into three components: a global mean Planck
feedback, the local deviation from the global mean Planck feedback, and the effect of the lapse-rate
feedback (that is, deviations from vertically uniform warming), on surface temperature change:

```
ΔT = Σᵢ ( ΔRᵢ ( dT̄/dR + dT′/dR + dT^LR/dR ) )
```

The warming contribution, for example of the surface albedo feedback, is:

```
ΔT = ΔR_a ( dT̄/dR )
```

and the contribution of the Planck feedback's deviation from its global mean is:

```
ΔT_P = Σᵢ ( ΔRᵢ dT′/dR )
```

The local warming contribution of the lapse-rate feedback is:

```
ΔT_LR = Σᵢ ( ΔRᵢ dT^LR/dR )
```

The warming response to a unit flux imbalance is the inverse of the vertically integrated temperature
kernel, `dT/dR = 1 / ∫ k_T dp`, obtained by summing over the surface temperature kernel and all levels
of the tropospheric temperature kernel. Averaging across latitudes and longitudes decomposes this into
the mean inverted kernel and a local deviation. To obtain the full warming response including the
effect of the lapse-rate feedback, each level is weighted by its warming relative to surface warming
when vertically integrating the temperature kernel:

```
∫ k_T,weighted = k̄_P + ∫ ( k_Tᵢ · (ΔTᵢ / ΔT_s) ) dp
```

In the surface-based feedback analysis, the inverted surface temperature kernel alone is used to
compute the warming response, whereas atmospheric temperature change is treated as a feedback
contributing to the surface flux imbalance. The surface temperature response is separated into a global
mean component and a local deviation, analogous to the Planck feedback:

```
ΔT = Σᵢ ( ΔR_s,ᵢ ( dT̄_s/dR_s + dT_s′/dR_s ) )
```

Atmospheric heat convergence is computed as the difference between TOA and surface fluxes, assuming no
storage of heat in the atmosphere on the timescale of the experiment. Changes in oceanic heat
convergence and ocean heat uptake, which are non-zero on the timescale considered, are computed as
changes in total surface fluxes. To separate tropospheric and stratospheric responses, a tropopause
height of 100 hPa in the tropics (30° S–30° N) is assumed, decreasing linearly with latitude to 300 hPa
at the poles. Surface downward and upward shortwave fluxes are used to compute the effective albedo.
Monthly mean data from the last 30 years of the CMIP5 pre-industrial control and 4 × CO₂ runs are
averaged into monthly climatologies for the feedback calculations. Radiative kernels were obtained from
the MPI-ESM-LR control climate. Using kernels from the 4 × CO₂ runs leads to a smaller role of the
albedo feedback, and using kernels from other models leads to larger residuals but does not
qualitatively change the conclusions.

## References

1. Barron, E. J. A warm, equable cretaceous: The nature of the problem. *Earth-Sci. Rev.* **19**, 305–338 (1983).
2. Dahl-Jensen, D. *et al.* Past temperatures directly from the greenland ice sheet. *Science* **282**, 268–271 (1998).
3. Chapman, W. L. & Walsh, J. E. Recent variations of sea ice and air temperature in high latitudes. *Bull. Am. Meteorol. Soc.* **74**, 33–47 (1993).
4. Bekryaev, R. V., Polyakov, I. V. & Alexeev, V. A. Role of polar amplification in long-term surface air temperature variations and modern arctic warming. *J. Clim.* **23**, 3888–3906 (2010).
5. Manabe, S. & Wetherald, R. The effects of doubling the CO₂ concentration on the climate of a general circulation model. *J. Atmos. Sci.* **32**, 3–15 (1975).
6. Holland, M. & Bitz, C. Polar amplification of climate change in coupled models. *Clim. Dynam.* **21**, 221–232 (2003).
7. Serreze, M. C. & Francis, J. A. The arctic amplification debate. *Climatic Change* **76**, 241–264 (2006).
8. Screen, J. A. & Simmonds, I. The central role of diminishing sea ice in recent arctic temperature amplification. *Nature* **464**, 1334–1337 (2010).
9. Crook, J. A., Forster, P. M. & Stuber, N. Spatial patterns of modeled climate feedback and contributions to temperature response and polar amplification. *J. Clim.* **24**, 3575–3592 (2011).
10. Taylor, P. C. *et al.* A decomposition of feedback contributions to polar warming amplification. *J. Clim.* **26**, 7023–7043 (2013).
11. Hall, A. The role of surface albedo feedback in climate. *J. Clim.* **17**, 1550–1568 (2004).
12. Graversen, R. G. & Wang, M. Polar amplification in a coupled climate model with locked albedo. *Clim. Dynam.* **33**, 629–643 (2009).
13. Arrhenius, S. On the influence of carbonic acid in the air upon the temperature of the ground. *London, Edinburgh, Dublin Phil. Mag. J. Sci.* **41**, 237–276 (1896).
14. IPCC. *Climate Change 2007: The Physical Science Basis* (Cambridge Univ. Press, 2007).
15. Winton, M. Amplified Arctic climate change: What does surface albedo feedback have to do with it? *Geophys. Res. Lett.* **33**, L03701 (2006).
16. Vavrus, S. The impact of cloud feedbacks on Arctic climate under greenhouse forcing. *J. Clim.* **17**, 603–615 (2004).
17. Bintanja, R., van der Linden, E. & Hazeleger, W. Boundary layer stability and Arctic climate change: A feedback study using EC-Earth. *Clim. Dynam.* **39**, 2659–2673 (2012).
18. Manabe, S. & Wetherald, R. T. On the distribution of climate change resulting from an increase in CO₂ content of the atmosphere. *J. Atmos. Sci.* **37**, 99–118 (1980).
19. Khodri, M. *et al.* Simulating the amplification of orbital forcing by ocean feedbacks in the last glaciation. *Nature* **410**, 570–574 (2001).
20. Spielhagen, R. F. *et al.* Enhanced modern heat transfer to the arctic by warm atlantic water. *Science* **331**, 450–453 (2011).
21. Planck, M. Ueber das gesetz der energieverteilung im normalspectrum. *Ann. Phys.* **309**, 553–563 (1901).
22. Soden, B. J. *et al.* Quantifying climate feedbacks using radiative kernels. *J. Clim.* **21**, 3504–3520 (2008).
23. Zhang, M., Hack, J., Kiehl, J. & Cess, R. Diagnostic study of climate feedback processes in atmospheric general circulation models. *J. Geophys. Res.* **99**, 5525–5537 (1994).
24. Hansen, J., Sato, M. & Ruedy, R. Radiative forcing and climate response. *J. Geophys. Res.: Atm.* **102**, 6831–6864 (1997).
25. Held, I. & Shell, K. Using relative humidity as a state variable in climate feedback analysis. *J. Clim.* **25**, 2578–2582 (2012).
26. Bintanja, R. & van der Linden, E. The changing seasonal climate in the arctic. *Sci. Rep.* **3**, 1556 (2013).
27. Serreze, M., Schnell, R. & Kahl, J. Low-level temperature inversions of the Eurasian Arctic and comparisons with Soviet drifting station data. *J. Clim.* **5**, 615–629 (1992).
28. Hwang, Y.-T., Frierson, D. M. W. & Kay, J. E. Coupling between arctic feedbacks and changes in poleward energy transport. *Geophys. Res. Lett.* **38**, L17704 (2011).
29. Held, I. M. & Soden, B. J. Robust responses of the hydrological cycle to global warming. *J. Clim.* **19**, 5686–5699 (2006).
30. Block, K. & Mauritsen, T. Forcing and feedback in the MPI-ESM-LR coupled model under abruptly quadrupled CO₂. *J. Adv. Model. Earth Syst.* **5**, 1–16 (2013).

## Acknowledgements / Author contributions / Competing interests

Radiative kernels provided by B. Block; discussions with B. Stevens; comments and feedback from
L. Tomassini.
T.M. developed the ideas that led to this paper. F.P. developed the inverted kernel method, analysed
the model data, and wrote the main paper with comments and input from T.M.
The authors declare no competing financial interests.
