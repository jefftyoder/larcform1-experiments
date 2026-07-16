---
name: coupler-config-args-silently-ignored
description: "ClimaCoupler YAML config args have been silently ignored before — always verify parsing; don't trust old larcform1 coupler configs"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: fb5b1f8a-ea7c-4d19-92ec-3c9b2940ded8
---

JY hit a bug where ClimaCoupler config arguments were quietly ignored, so the existing `coupled_configs/*.yml` examples in this repo must not be trusted as evidence that a key works.

**Why:** ClimaCoupler's `Input.validate_model_types_for_mode` warn-and-overrides model selections, and some keys (e.g. `FLOAT_TYPE`) are atmos-only spellings that the coupler never reads — runs proceed with defaults without erroring.

**How to apply:** For any new coupler config, parse it with `ClimaCoupler.Input.get_coupler_args` (in the [[kaimon-julia-repl-available]] REPL) and diff parsed values against the YAML; check the `Component models initialized:` log line every run.
