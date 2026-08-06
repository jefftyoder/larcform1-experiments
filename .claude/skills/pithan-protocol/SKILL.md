---
name: pithan-protocol
description: "Pithan et al. (2016) SCM intercomparison protocol: boundary conditions, GHG concentrations, initial profiles, and participating model configurations"
---

# Pithan 2016 Experiment Protocol

Reference: Pithan et al. (2016), *JGR Atmospheres* — SCM intercomparison for Arctic boundary layer.

## Section 2.2: Boundary and Initial Conditions

- **Location:** 80°N
- **Start date:** 1 January → insolation = 0 throughout
- **Initial surface temperature:** 250 K
- **Sea ice:** 1 m thick
- **Snow on ice:** 0.1 m water equivalent
- **Ocean beneath ice:** at the freezing point of sea water
- **Geostrophic wind:** 5 m s⁻¹ throughout the troposphere; meridional component = 0
- **Advective tendencies:** set to zero
- **Run length:** 20 days; analyses limited to first 10 days
- **Greenhouse gas concentrations:** prescribed as in Table 2 (see below)

## Table 2: Greenhouse Gas Concentrations

| GHG | Volume-mixing ratio |
|---|---|
| CO₂ | 360 × 10⁻⁶ |
| N₂O | 309.5 × 10⁻⁹ |
| CH₄ | 1693.6 × 10⁻⁹ |
| CFC-11 | 252.8 × 10⁻¹² |
| CFC-12 | 466.2 × 10⁻¹² |

## Table 1: Initial Profiles of Temperature, Humidity, and Geostrophic Zonal Wind

| Pressure (hPa) | Temperature (K) | Humidity | u_geo (m s⁻¹) |
|---|---|---|---|
| 1013 | T₀ = 273 | rh wrt water: 80% | 5 |
| 1013–600 | T = T₀ (p/p₀)^(Rγ/g) | Linear interpolation of rh | 5 |
| 600 | T = T₀ (p/p₀)^(Rγ/g) | rh wrt water: 20% | 5 |
| 600–300 | T = T₀ (p/p₀)^(Rγ/g) | rh wrt water: 20% | 5 |
| 300 – model top | T = T₃₀₀hPa | q = 3 × 10⁻⁶ kg kg⁻¹ | 0 |

Parameters: p₀ = 1013 hPa, lapse rate γ = 8 × 10⁻³ K m⁻¹, R = 287 J kg⁻¹ K⁻¹, g = 9.81 m s⁻². Temperature profile based on Curry [1983].

## Table 3: Participating Models

| Model | Phase of Condensate | Snow and Ice | z₀ₘ (m) |
|---|---|---|---|
| CAM 5.3 | Prognostic | Interactive | 5e-3 |
| CMC-GDPS | f(T) | Interactive | 1.6e-4 |
| CMC-HRDPS | Prognostic | Interactive | 1.6e-4 |
| CMC-RDPS | f(T) | Interactive | 1.6e-4 |
| EC-Earth V3 (IFS 36r4) | Prognostic | No snow, fixed ice | 1e-3 |
| ECHAM 6.2 | Prognostic | Interactive | 1e-3 |
| ECHAM6.1.0-HAM2.2 | Prognostic | Interactive | 1e-3 |
| ECMWF-IFS | Prognostic | No snow, fixed ice | 1e-3 (+ Charnock term) |
| GISS E2 | p(T) | Fixed ice | v_m/u_* + 0.018 u²_*/g |
| WRF 3.5.1 | Prognostic | Fixed ice | 1e-3 |
| WUR-D91 | Ice (all condensate = ice) | Fixed ice | 1e-1 |

**z₀ₘ summary:** Modal value is **1e-3 m** (used by 5 of 11 models); range is 1.6e-4 to 1e-1 m (WUR-D91 is an outlier).

**Condensate phase legend:**
- **Prognostic:** separate prognostic variables for cloud ice and liquid + parametrized freezing rates
- **f(T):** phase partitioning as a function of temperature
- **p(T):** temperature-dependent probability for total freezing at each time step
- **Ice:** all condensate assumed to be ice

**Snow and ice treatment summary:** 6 models interactive, 3 fixed ice, 2 no snow fixed ice.
