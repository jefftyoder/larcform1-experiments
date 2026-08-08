---
name: feedback-experiment-isolation
description: Never overwrite a prior experiment's code; each subexperiment gets its own directory for reproducibility
metadata:
  type: feedback
---

Never modify or overwrite files belonging to a completed experiment when creating a new one. Each subexperiment gets its own directory with its own code, even if the new experiment is an evolution of the old one.

**Why:** Experiments must be reproducible. If we overwrite subexperiment B's `sweep_tools.jl` to create subexperiment C, we lose the ability to re-run B or verify its results. The code that produced a result is part of that result's provenance.

**How to apply:** When creating a new subexperiment (e.g. C from B), create a new directory (e.g. `experiments/taudep sweep coupled 2d/`) with its own copies of the sweep infrastructure. The new code can import shared utilities from a common location, but the experiment-specific driver and config logic must live in the new directory. Never edit files in a prior experiment's directory to serve a new experiment's needs.
