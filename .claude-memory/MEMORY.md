# Memory index

- [Coupler config args silently ignored](coupler-config-args-silently-ignored.md) — verify every ClimaCoupler YAML key actually parses; old repo configs untrusted
- [Kaimon Julia REPL available](kaimon-julia-repl-available.md) — prefer Jeff's live Julia 1.12 REPL via mcp__kaimon__ tools; cold julia processes only when a fresh process is genuinely required
- [No simultaneous sims without intent](avoid-output-dir-collisions.md) — check for live julia processes before running; same-job_id collisions corrupt output, contention halves speed
- [Stratus VPN times out](stratus-vpn-times-out.md) — stratus unreachable ⇒ VPN dropped; tell Jeff to reconnect, run remote work detached in tmux
- [physical_state.jl GPU latent issue](physical-state-gpu-latent-issue.md) — hydrostatic pressure integral isn't GPU-safe; left for upstream, don't fix here
- [AGU 2026 abstract advisor feedback](agu2026-abstract-advisor-feedback.md) — Sally Zhang's 10 comments + 4 tracked changes; working through one by one
- [No dashes in writing](feedback-no-dashes.md) — never use em-dashes or substitutes; use commas, colons, semicolons, periods
