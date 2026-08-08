---
name: feedback-skip-dense-sweeps
description: Skip Stage C (dense critical-window) sweep runs by default; only add after reviewing plots
metadata:
  type: feedback
---

Skip Stage C (dense uniform sampling across the critical window) in tau_dep sweeps unless we explicitly decide to add it after reviewing the transition plots.

**Why:** Dense runs are expensive and usually unnecessary; the coarse + adaptive stages capture the transition well enough for initial analysis. Better to review the plots first and add targeted dense sampling only where resolution is clearly insufficient.

**How to apply:** When launching sweeps, do not pass `--stageC`. Only propose dense runs after the user has seen the transition plots and asks for finer resolution.
