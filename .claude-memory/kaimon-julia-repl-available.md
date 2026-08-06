---
name: kaimon-julia-repl-available
description: Jeff keeps a live Julia 1.12 REPL that Claude can drive via the Kaimon MCP tools
metadata: 
  node_type: memory
  type: feedback
  originSessionId: fb5b1f8a-ea7c-4d19-92ec-3c9b2940ded8
---

Jeff runs a live Julia 1.12 REPL accessible through the Kaimon.jl MCP server (`mcp__kaimon__*` tools, e.g. `ex`/`manage_repl`).

**Why:** Cold `julia --project` background processes pay full package-load/compile latency every time (minutes for Makie-class stacks), and Jeff has explicitly asked (2026-07-09) that the live REPL be preferred.

**How to apply:** Default to `mcp__kaimon__ex` for evaluation, package ops, config-parsing checks, and plotting tests. If multiple sessions are connected, pass `ses=`. Fall back to a cold `julia --project` process only when the test specifically requires a fresh process (e.g. validating driver scripts end-to-end) — and say so. Related: [[coupler-config-args-silently-ignored]].

**Caveat (2026-08-06):** Kaimon is not working on Stratus (Jeff's report); remote sweeps run via tmux + launcher scripts instead (see `experiments/taudep sweep/`). Kaimon is an HTTP MCP server on 127.0.0.1:2828; when it works again, a Stratus REPL can be driven through an SSH port-forward of 2828.
