---
name: physical-state-gpu-latent-issue
description: "Known latent GPU incompatibility in ClimaAtmos physical_state.jl (hydrostatic pressure integral) — left for upstream, do not fix here"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2e5ff578-d5fd-40e7-962c-9b0d8e7805de
---

`ClimaAtmos.jl/src/setups/common/physical_state.jl` has a latent GPU
incompatibility in `hydrostatic_pressure_profile` / `column_indefinite_integral`:
(1) the integration space is built from a bare `ClimaComms.SingletonCommsContext()`
(line ~176) which picks up `CLIMACOMMS_DEVICE=CUDA` and runs the setup-time column
integral as a GPU kernel; (2) the integrand closure captures a boxed local function
`ρ_from_profile` (`Core.Box`, not isbits) plus non-isbits profile objects, so the
kernel fails to compile (`KernelError: passing non-bitstype argument`). This is
shared code used by many setups.

**Why:** Decision (2026-07-15, jty53) is to NOT fix this in larcform1-experiments —
it belongs upstream in CliMA/ClimaAtmos.jl. The Larcform1 setup already sidesteps it
by using the analytic `APL.Larcform1_p` instead of the numerical integral (see
`Larcform1.jl:larcform1_profiles`).

**How to apply:** Don't spend effort patching `physical_state.jl` here. If another
setup needs GPU + the moist hydrostatic integral, flag it for upstream rather than
working around it in this repo. Related: [[larcform1-gpu-fix]].
