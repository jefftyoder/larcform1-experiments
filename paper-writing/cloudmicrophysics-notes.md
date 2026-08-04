# CloudMicrophysics.jl Architecture Notes
## Compiled 2026-07-31, corrected 2026-08-04

### Vapor-to-condensate formulation in MicrophysicsNonEq.jl

**There is ONE formulation, not two.** Both `ConstantTimescale` and
`TemperatureDependent` config options use the same Morrison & Milbrandt (2015)
/ Morrison & Grabowski (2008) supersaturation-driven equations. The docstrings
on `conv_q_vap_to_q_lcl` and `conv_q_vap_to_q_icl` both cite MG2008 and
MM2015. Verified from source: `CloudMicrophysics.jl/src/MicrophysicsNonEq.jl`.

**Liquid condensation** (`conv_q_vap_to_q_lcl`, `CloudLiquidFormation`):
- `dq_lcl/dt = (q_vap - q_sl) / (tau_l * Gamma_l)`
- Liquid forms whenever `q_vap > q_sl` (saturation wrt liquid)
- `tau_l` is constant (default 10 s from ClimaParams)
- Only one implementation — no config switch for liquid
- Gamma_l is the psychrometric correction: `1 + (L_v/c_p) * dq_sl/dT`

**Ice deposition** (`conv_q_vap_to_q_icl`):
- Same MM2015 equation: `dq_icl/dt = (q_vap - q_si) / (tau_i * Gamma_i)`
- Two config options control ONLY how tau_i is computed:

| Config | Deposition tau | Sublimation tau | Effect at -10C |
|---|---|---|---|
| `ConstantTimescale` | constant (default 100 s) | same constant | Fast: drains vapor below q_sl before liquid can form |
| `TemperatureDependent` | Frostenberg tau_dep(T, q_icl) | constant tau_sub | Slow initially (~1e9 s): vapor reaches q_sl, liquid forms |

### CORRECTION: the "simple" formulation in the docs

The CloudMicrophysics documentation describes a "simple" formulation that
relaxes toward temperature-partitioned equilibrium targets:
- `dq_lcl/dt = (q_eq_lcl - q_lcl) / tau_l`
- `dq_icl/dt = (q_eq_icl - q_icl) / tau_i`

**This is NOT implemented as a separate code path.** It appears to be a
pedagogical description of a conceptual approach, not something selectable
via config. Both `ConstantTimescale` and `TemperatureDependent` use the
MM2015 supersaturation equations in the actual source code. An earlier
version of these notes incorrectly stated that `ConstantTimescale` selected
the "simple" formulation — it does not.

### Why ConstantTimescale kills liquid despite using MM2015 equations

The mechanism is a vapor competition, not a temperature partition:
1. Below freezing: `q_sat_ice < q_sat_liq` always
2. With constant tau_i = 100 s, ice deposition is fast enough to pin
   vapor at `q_sat_ice` before it can reach `q_sat_liq`
3. The liquid gate (`q_vap > q_sat_liq`) never opens
4. Result: clw = 0 exactly, at all levels and timesteps

This BEHAVES LIKE a diagnostic partition (liquid is never created) but the
MECHANISM is kinetic (fast ice deposition wins the vapor competition). The
distinction matters for how we describe it in the abstract.

### Why TemperatureDependent recovers liquid

Frostenberg et al. (2023) replaces the constant tau_i with:
- `tau_dep = 1 / (4*pi * D_v * N_icl * r_safe)`
- N_icl diagnosed from Frostenberg INPC(T): `N_icl = exp(mean_ln_INPC(T))`
- At -10C, N_INP ~ 0.9, giving tau_dep ~ 1e9 s initially
- Ice deposition is ~1e7x slower than ConstantTimescale
- Vapor reaches q_sat_liq -> liquid condenses
- As ice mass grows, r grows, tau_dep shrinks -> deposition accelerates
  (bootstrap feedback builds the ice phase)

**Asymmetric timescales** (TemperatureDependent only):
- Deposition: tau_dep (Frostenberg, T-dependent, grows with ice mass)
- Sublimation: tau_sub (constant, default from ClimaParams)

### Frostenberg a/b coefficients — PR #758

- Bug: `INP_concentration_mean` ignored the a and b coefficients
- Fix: `mean_ln_INPC(T) = 9*log(-b*T_c/10) - log(a)`
- At defaults a=1, b=1: reduces to previous hardcoded curve
- Jeff's runs use the corrected implementation (vendored CM + upstream PR)

### 1M precipitation module (Microphysics1M.jl) — separate layer

- Covers downstream precipitation: autoconversion, accretion, evaporation,
  sublimation, sedimentation
- Based on Kessler (1995), Grabowski (1998), Kaul (2015)
- No reference to MM2015 — vapor-to-condensate is entirely in MicrophysicsNonEq.jl

### Correct model description for the paper

"Non-equilibrium cloud formation following Morrison and Grabowski (2008) and
Morrison and Milbrandt (2015), with ice deposition timescale parameterized
following Frostenberg et al. (2023), coupled to 1-moment precipitation
microphysics."

The distinction between the two configurations is NOT "diagnostic vs kinetic"
or "simple vs MM2015" — both use MM2015. The distinction is whether the ice
deposition timescale is constant (unphysically fast, suppresses liquid) or
INP-limited (Frostenberg, allows liquid).

### Key references

- Morrison, H. and Grabowski, W. W. (2008). J. Atmos. Sci. [MG2008]
- Morrison, H. and Milbrandt, J. A. (2015). J. Atmos. Sci., 72(1), 287-311. [MM2015]
- Frostenberg et al. (2023). ACP, 23, 10883-10900. [tau_dep parameterization]
- Kaul, C. M., Teixeira, J., and Suzuki, K. (2015). Mon. Wea. Rev., 143(11), 4393-4421. [1M Arctic mixed-phase]
- Yatunin et al. (2026). JAMES, 18, e2025MS005014. [dycore conservation — for paper, not abstract]
