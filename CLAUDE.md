# larcform1-experiments

For changes to ClimaAtmos.jl, load in `ClimaAtmos.jl/AGENTS.md`

Single-column model (SCM) experiments for the LARCFORM1 Arctic radiation study using ClimaAtmos.jl + ClimaCoupler.jl.

## Pithan 2016 Experiment Protocol

Full protocol tables (boundary conditions, GHG concentrations, initial profiles, participating models) available via `/pithan-protocol`.

### Implications for our configuration

- z₀ₘ = 1e-3 m is the most common value; our code defaults (1e-4 m prescribed, 5.8e-5 m ClimaSeaIce) are lower than most participants — **check whether to update**
- Fixed ice thickness (h = 1 m) is used by 5 of 11 models — defensible
- Most models use prognostic separate ice/liquid; all-ice (0M) is a simplification

### Open TODOs

- **Coupler z₀ₘ defaults don't match standalone run.** `src/setups/Larcform1.jl:surface_condition` sets z₀ₘ = 1e-3 m correctly for the standalone ClimaAtmos path. But `PrescribedIceSimulation` defaults to z₀ₘ = 1e-4 m and `ClimaSeaIceSimulation` hardcodes 5.8e-5 m. When moving to coupled ClimaCoupler runs, update those defaults or override via config/TOML so z₀ₘ = 1e-3 m is consistent.
- **`prognostic_tke` field in `Larcform1` struct is dead code.** `Larcform1.prognostic_tke::Bool` is accepted by the constructor but never used — TKE is always initialized to zero regardless. Either wire it up (non-zero TKE warm-start) or remove the field.

## Running the simulation

```bash
# From repo root — interactive (REPL)
julia --project
julia> include("experiments/larcform1_driver.jl")

# Non-interactive
julia --project experiments/larcform1_driver.jl

# Custom config
julia --project experiments/larcform1_driver.jl --config_file configs/other.yml
```

### Running on Stratus

**Move code to Stratus with the sync scripts.** `scripts/sync_to_remote.sh` rsyncs the
local working tree (including uncommitted work) up to Stratus, and
`scripts/sync_from_remote.sh` pulls `output/` back down. This is the default workflow
for iterating on runs:

```bash
bash scripts/sync_to_remote.sh            # rsync working tree up (refuses while julia is live)
ssh stratus 'export PATH=/home/yoder/.juliaup/bin:$PATH && cd ~/clima/larcform1-experiments && tmux new-session -d -s lf1run "julia +1.12 -t auto --project --startup-file=no experiments/larcform1_driver.jl 2>&1 | tee output/lf1_run_$(date +%Y%m%d_%H%M%S).log"'
bash scripts/sync_from_remote.sh          # rsync output/ back down when the run finishes
```

`sync_to_remote.sh` refuses to run while julia is live on Stratus (it would swap files
underneath an in-flight run). It excludes `output/`, `*.nc`, and `*.log` from the upload.

**When you need a result traceable to a commit,** commit + push and use
`scripts/deploy_to_remote.sh` (fetch + reset --hard + submodule update) instead — it
prints the deployed lf1e and ClimaAtmos SHAs and aborts if the tree is dirty, commits
are unpushed, or julia is live. Note it `reset --hard`s over whatever `sync_to_remote.sh`
left behind, so switching from scratch iteration to a traceable run gets you a clean
checkout.

> **The Julia environment lives on Stratus, not in git.** `Manifest.toml` is gitignored
> and resolved remotely under 1.12 — `git reset --hard` does not touch it, since it is
> untracked. Same for `output/`. Deploying never re-resolves the environment; run
> `Pkg.instantiate()` yourself if `Project.toml` changed.

> **Claude Code memories are git-tracked via symlink.** Memory files live in the
> repo at `.claude-memory/` (tracked — `.gitignore` only excludes `.claude/`). On
> each machine, `~/.claude/projects/<encoded-path>/memory` is a symlink into that
> dir, so memories ride along with `sync_to_remote.sh` and share the code's
> provenance. The path encoding differs per machine (`-Users-jeff-…` on Mac,
> `-home-yoder-…` on Stratus) but both point at the one `.claude-memory/`. Caveat:
> a memory *written on Stratus* lives in the Stratus working tree and is overwritten
> by the next `sync_to_remote.sh` (Mac→Stratus) or `deploy_to_remote.sh`
> (`reset --hard`) unless it is first committed and pulled to Mac — same discipline
> as any other tracked file. To re-establish the symlink on a fresh machine: `mv`
> the real `memory` dir aside and `ln -s <repo>/.claude-memory <encoded-path>/memory`.

> **Pin `julia +1.12`.** The `Manifest.toml` is resolved under Julia 1.12.6, but
> juliaup's default channel on Stratus is 1.11.6. Launching with bare `julia`
> picks 1.11.6 and every package fails to precompile with a cascade rooted in
> `UndefVarError: StaticData not defined in Base` (a `Base` internal that exists
> in 1.12 but not 1.11) — it looks like a dependency/OOM disaster but is purely a
> version mismatch. Always use the `julia +1.12` channel selector.

Check run status — two options:

```bash
# Interactive (terminal only — requires a real TTY; do not use from Claude Code)
ssh -t stratus 'tmux attach -t lf1run'

# Non-interactive tail of recent output (works from Claude Code)
ssh stratus 'tmux capture-pane -pt lf1run -S -50'
```

## Parameter TOMLs in coupled runs: use `coupler_toml`, never atmos `toml`

In ClimaCoupler v0.2.2 coupled runs, parameter overrides listed under the atmos
`toml:` key are **silently reverted to ClimaParams defaults**: the coupler builds its
own param dict from `coupler_toml` (full defaults when that list is empty,
`SimCoordinator.jl:257`) and passes it as the *override* side of
`merge_override_default_values` (`ClimaCouplerClimaAtmosExt.jl:668`), clobbering every
atmos-toml value. The docs' promised fallback ("only if there is no coupler TOML will
the atmosphere-specific TOML be used") is broken — upstream bug, to be reported.

- Pass all parameter TOMLs via `coupler_toml:` (paths resolve cwd-first, then
  `pkgdir(ClimaCoupler)`).
- Constraint: every `coupler_toml` entry must be *used by atmos* or its strict
  unused-parameter check aborts the run — so surface-only parameters
  (e.g. `seaice_column_*`) cannot go through TOML at all; use component
  registration/kwargs instead (see `experiments/sea-ice/components/clima_seaice_column.jl`).
- Verify calibrated values actually landed by grepping the run's saved
  `output/<job>/.../clima_atmos/<job>_parameters.toml`.
- YAML keys (e.g. `cloud_ice_formation`) are unaffected; this applies only to TOML
  parameters.

## Interactive configuration (sensitivity tests)

Per [the ClimaCoupler running docs](https://clima.github.io/ClimaCoupler.jl/dev/running/#Modifying-configuration-interactively),
the config dict can be loaded and modified programmatically before constructing the
simulation — preferred for sensitivity sweeps (use the live Kaimon REPL):

```julia
import ClimaCoupler.Input
config_dict = Input.get_coupler_config_dict("experiments/sea-ice/configs/generated_<job>.yml")
config_dict["t_end"] = "2days"          # any documented Input option
config_dict["job_id"] = "my_sens_run"   # avoid output-dir collisions
cs = CoupledSimulation(config_dict)
run!(cs)
```

Note: `get_coupler_config_dict` resolves `coupler_toml` paths relative to the cwd, and
edits to the dict bypass the overlay files — record any sweep's final dict (or diff
from the generated yml) in the experiment report for provenance.

## Project layout

```
configs/              # YAML configuration files
  larcform1_minimal.yml   # main config: column, sea_ice, 10-day run
experiments/
  larcform1_driver.jl     # entrypoint: CoupledSimulation → run! → make_plots
ClimaAtmos.jl/        # submodule (dev'd into the root env)
output/               # simulation output (gitignored)
  larcform1_minimal/
    output_NNNN/      # versioned runs (ActiveLink style)
docs/                 # Project level docs for Larcform1 experiments
```

## Checkpoints, restarts, and diagnostics

See `/run-config` for checkpoint YAML options, restart behavior, and diagnostic output configuration.

## Submodules and package pins

```bash
git submodule update --init --recursive
```

`ClimaAtmos.jl` is a pinned submodule, `Pkg.develop`'d into the root env.
`CloudMicrophysics.jl` is **no longer vendored** — the patched local copy (registered
0.36 + Frostenberg a/b) was removed; the root env now uses registered
CloudMicrophysics v0.36.0, so the Frostenberg patch is not present anywhere.
`ClimaCoupler.jl` is NOT a submodule — it comes from the registry (v0.2.2, pinned in
Manifest.toml).
The `.buildkite/` environment inside `ClimaAtmos.jl/` is activated for postprocessing
plots only — never run physics in the buildkite env; its Manifest is resolved
independently of the root env.

### Known resolver conflict: do not `pkg> up` the root env

The dev'd ClimaAtmos submodule at v0.41.3+ requires `ClimaTimeSteppers = "0.10.4"`
and `CloudMicrophysics = "0.37"` (bumped in ClimaAtmos commit `75e2b22b7`), but every
registered ClimaCoupler release (≤ 0.2.2) caps `ClimaTimeSteppers = "0.8.11, 0.9"`.
The intersection is empty, so any full re-resolve (`pkg> up`, `pkg> add`, deleting
the Manifest) fails with `Unsatisfiable requirements detected for package
ClimaCoupler` — the resolver blames ClimaCoupler, but the root cause is the
transitive ClimaTimeSteppers conflict. The existing local Manifest (gitignored;
resolved when the
submodule was at ClimaAtmos v0.41.0, ClimaTimeSteppers 0.9.0) still instantiates and
runs; `pkg> st` reporting `ClimaAtmos v0.41.0` against a 0.41.3 checkout is this
staleness, not an error. The ⌅ pins on ClimaTimeSteppers 0.9.0 and CloudMicrophysics
0.36.0 are the same conflict viewed from `st`. Resolution options: roll the submodule
back before `75e2b22b7`, or wait for a ClimaCoupler release admitting
ClimaTimeSteppers 0.10.

See ./ClimaAtmos.jl/AGENTS.md for ClimaAtmos.jl specific best practices from the developers.