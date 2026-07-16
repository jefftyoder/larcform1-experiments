---
name: stratus-julia-version-pin
description: "Stratus runs need `julia +1.12`; bare `julia` is juliaup default 1.11.6 and mass-fails precompile"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4a7c5515-660a-4c0e-bdea-4abf2c0f76b2
---

On Stratus, the project's Manifest.toml is resolved under **Julia 1.12.6**, but
juliaup's default channel is pinned to **1.11.6**. Launching with bare `julia`
(as the CLAUDE.md "Running on Stratus" tmux snippet does) picks 1.11.6 and every
package fails to precompile with a cascade rooted in
`UndefVarError: StaticData not defined in Base` (a `Base` internal that exists in
1.12 but not 1.11). It looks like an OOM/dependency disaster but is purely a
version mismatch — RAM was fine.

**Fix:** always launch Stratus runs with the channel selector: `julia +1.12 ...`.
Available juliaup channels: 1.10, 1.11, 1.11.6 (default), 1.12 (=1.12.6), release.

**How to apply:** use `julia +1.12 -t auto --project --startup-file=no <script>`
in the tmux launch. The CLAUDE.md snippet should be updated to pin this. Related:
[[stratus-vpn-times-out]].
