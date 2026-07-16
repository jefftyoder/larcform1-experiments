---
name: avoid-output-dir-collisions
description: "No simultaneous simulations on Jeff's Mac unless the parallel workload is deliberately planned — collisions corrupt output and halve throughput"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: fb5b1f8a-ea7c-4d19-92ec-3c9b2940ded8
---

Jeff's rule (2026-07-09, after Phase 0 sea-ice work): **do not run simultaneous simulations on this machine without being very intentional about the parallel workload.** Two concurrent CoupledSimulations (Claude's Kaimon session + Jeff's own REPL) with the same `job_id` corrupted `output_0002` — the coupler's `RemovePreexisting`/versioned-dir logic let one construction delete the other's live output — and memory-bandwidth contention roughly halved per-step speed (15 → 7 ms/step once solo).

**Why:** Jeff works interactively in his own REPL(s) alongside the Kaimon session ([[kaimon-julia-repl-available]]); ClimaAtmos/ClimaCoupler version output dirs by `job_id`.

**How to apply:** Before constructing or running any simulation, check `ps aux | grep julia` (or `lsof` on the output dir) for live runs and confirm with Jeff if one exists. If parallel runs are genuinely wanted, give each a unique `job_id` and plan the core/memory budget explicitly. Always tell Jeff which `output_NNNN` a given run owns. Also recorded in `experiments/sea-ice/PLAN.md` → Working practices.
