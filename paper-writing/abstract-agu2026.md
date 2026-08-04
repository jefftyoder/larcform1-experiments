# AGU 2026 Abstract Draft

## Session choices

1. A025 — Aerosol, Cloud, Precipitation and Radiation Studies over High Latitudes
2. Processes of (Sub) Cloud Scales: Modeling, Observations and Parameterizations

## Title
Temperature-Dependent Ice Deposition Recovers the Missing Cloud Liquid in the Arctic Boundary Layer

Observations of the Arctic winter boundary layer reveal two preferred states: a cloudy state in which liquid water suppresses surface radiative cooling and inversions remain weak and elevated, and a radiatively clear state with strong surface-based inversions. Many atmospheric models fail to produce the cloudy state, biasing the Arctic surface energy budget and inversion strength. The Larcform 1 single-column intercomparison (Pithan et al., 2016), an idealized Lagrangian Arctic air formation experiment, attributed this failure largely to condensate representation, finding that most schemes with separate prognostic variables for cloud liquid and ice reproduced the cloudy state.

<!-- EDITORIAL: revisit whether to mention coupled sea-ice surface here or in results -->
<!-- TALK PREP: Pithan's full conclusion includes "explicitly computed freezing rates" — worth discussing at poster/talk level -->
<!-- NOTE: CloudMicrophysics.jl docs say "derived from [MG2008] and [MM2015], but without imposing exponential time integrators" — cite both in the paper -->
<!-- NOTE: Both ConstantTimescale and TemperatureDependent use MM2015 equations — the distinction is ONLY the ice deposition timescale. See paper-writing/cloudmicrophysics-notes.md -->

We implement Larcform 1 in ClimaAtmos.jl, the CliMA atmosphere model, using 1-moment non-equilibrium microphysics with prognostic cloud liquid and ice, and a prognostic eddy-diffusivity mass-flux scheme
<!-- EDITORIAL: cite Kaul et al. (2015) for 1M Arctic mixed-phase justification --> for turbulence and convection. Under a constant ice deposition timescale, vapor is consumed by ice before reaching liquid saturation, liquid water path remains identically zero throughout the air mass transformation, and the distribution of surface net longwave radiation is unimodal. Replacing the constant timescale with a temperature-dependent deposition rate recovers
<!-- EDITORIAL: cite Frostenberg et al. (2023) for the INP-based tau_dep(T) parameterization --> a persistent liquid-containing cloud, an elevated inversion, and a subsequent transition to the clear state. Sensitivity tests spanning two orders of magnitude in the constant deposition timescale leave liquid water path unchanged, indicating that liquid is never created rather than created and rapidly glaciated. Additional tests isolating individual microphysical processes confirm that ice deposition is the controlling pathway.
<!-- EDITORIAL: "Additional tests" = v4 (cloud-only isolation), v11 (deposition disabled), v12 (constant tau matched to INP-limited value). Detail in paper. -->
These results refine the Larcform 1 conclusion: separate prognostic condensate variables alone are not sufficient to sustain supercooled liquid water. Supercooled liquid persists only when ice deposition is constrained by a temperature-dependent timescale, here achieved within a 1-moment framework using a diagnosed ice-nucleating particle concentration, consistent with prior findings linking ice number concentration to liquid water persistence.
<!-- EDITORIAL: "prior findings" = Ovchinnikov et al. (2014), LES intercomparison showing Ni controls LWP. Cite here in the paper/poster. -->
<!-- EDITORIAL: future / ongoing work? -->
