# larcform1-experiments

For changes to ClimaAtmos.jl, load in `ClimaAtmos.jl/AGENTS.md`

Single-column model (SCM) experiments for the LARCFORM1 Arctic radiation study using ClimaAtmos.jl + ClimaCoupler.jl.

## Pithan 2016 Experiment Protocol

Reference: Pithan et al. (2016), *JGR Atmospheres* — SCM intercomparison for Arctic boundary layer.

### Section 2.2: Boundary and Initial Conditions

- **Location:** 80°N
- **Start date:** 1 January → insolation = 0 throughout
- **Initial surface temperature:** 250 K
- **Sea ice:** 1 m thick
- **Snow on ice:** 0.1 m water equivalent
- **Ocean beneath ice:** at the freezing point of sea water
- **Geostrophic wind:** 5 m s⁻¹ throughout the troposphere; meridional component = 0
- **Advective tendencies:** set to zero
- **Run length:** 20 days; analyses limited to first 10 days
- **Greenhouse gas concentrations:** prescribed as in Table 2 (see below)

### Table 2: Greenhouse Gas Concentrations

| GHG | Volume-mixing ratio |
|---|---|
| CO₂ | 360 × 10⁻⁶ |
| N₂O | 309.5 × 10⁻⁹ |
| CH₄ | 1693.6 × 10⁻⁹ |
| CFC-11 | 252.8 × 10⁻¹² |
| CFC-12 | 466.2 × 10⁻¹² |

### Table 1: Initial Profiles of Temperature, Humidity, and Geostrophic Zonal Wind

| Pressure (hPa) | Temperature (K) | Humidity | u_geo (m s⁻¹) |
|---|---|---|---|
| 1013 | T₀ = 273 | rh wrt water: 80% | 5 |
| 1013–600 | T = T₀ (p/p₀)^(Rγ/g) | Linear interpolation of rh | 5 |
| 600 | T = T₀ (p/p₀)^(Rγ/g) | rh wrt water: 20% | 5 |
| 600–300 | T = T₀ (p/p₀)^(Rγ/g) | rh wrt water: 20% | 5 |
| 300 – model top | T = T₃₀₀hPa | q = 3 × 10⁻⁶ kg kg⁻¹ | 0 |

Parameters: p₀ = 1013 hPa, lapse rate γ = 8 × 10⁻³ K m⁻¹, R = 287 J kg⁻¹ K⁻¹, g = 9.81 m s⁻². Temperature profile based on Curry [1983].

### Table 3: Participating Models

| Model | Phase of Condensate | Snow and Ice | z₀ₘ (m) |
|---|---|---|---|
| CAM 5.3 | Prognostic | Interactive | 5e-3 |
| CMC-GDPS | f(T) | Interactive | 1.6e-4 |
| CMC-HRDPS | Prognostic | Interactive | 1.6e-4 |
| CMC-RDPS | f(T) | Interactive | 1.6e-4 |
| EC-Earth V3 (IFS 36r4) | Prognostic | No snow, fixed ice | 1e-3 |
| ECHAM 6.2 | Prognostic | Interactive | 1e-3 |
| ECHAM6.1.0-HAM2.2 | Prognostic | Interactive | 1e-3 |
| ECMWF-IFS | Prognostic | No snow, fixed ice | 1e-3 (+ Charnock term) |
| GISS E2 | p(T) | Fixed ice | v_m/u_* + 0.018 u²_*/g |
| WRF 3.5.1 | Prognostic | Fixed ice | 1e-3 |
| WUR-D91 | Ice (all condensate = ice) | Fixed ice | 1e-1 |

**z₀ₘ summary:** Modal value is **1e-3 m** (used by 5 of 11 models); range is 1.6e-4 to 1e-1 m (WUR-D91 is an outlier).

**Condensate phase legend:**
- **Prognostic:** separate prognostic variables for cloud ice and liquid + parametrized freezing rates
- **f(T):** phase partitioning as a function of temperature
- **p(T):** temperature-dependent probability for total freezing at each time step
- **Ice:** all condensate assumed to be ice

**Snow and ice treatment summary:** 6 models interactive, 3 fixed ice, 2 no snow fixed ice.

### Implications for our configuration

- z₀ₘ = 1e-3 m is the most common value; our code defaults (1e-4 m prescribed, 5.8e-5 m ClimaSeaIce) are lower than most participants — **check whether to update**
- Fixed ice thickness (h = 1 m) is used by 5 of 11 models — defensible
- Most models use prognostic separate ice/liquid; all-ice (0M) is a simplification

### Open TODOs

- **ClimaAtmos fix that every coupled run depends on is committed but NOT PUSHED.** `ClimaAtmos.jl/src/config/model_getters.jl` is patched so `surface_setup: PrescribedSurface` overrides a setup-provided flux scheme — otherwise atmos *and* the coupler both compute surface fluxes and nothing errors. Committed as `e4651309d` on the submodule's `jy/coldslab` branch, and the parent repo now pins that SHA. **It exists only on this machine:** `jy/coldslab` has not been pushed to CliMA, so a fresh clone cannot resolve the submodule pointer. Two things still owed: (1) push `jy/coldslab`, (2) cherry-pick just the `model_getters.jl` hunk onto a clean branch off ClimaAtmos `main` and open an upstream PR — the fix changes behavior in exactly one case (PrescribedSurface + setup-supplied flux scheme) and no in-repo config sets `PrescribedSurface`, so it's safe to upstream.
- **Three upstream ClimaCoupler bugs found, none reported yet:** column-mode SIC callback (belongs on [#1860](https://github.com/CliMA/ClimaCoupler.jl/issues/1860)), the `coupler_toml` clobber (see section below), and `postprocess` failing on column output. All are worked around in `experiments/sea-ice/`.
- **`prognostic_tke` field in `Larcform1` struct is dead code.** `Larcform1.prognostic_tke::Bool` is accepted by the constructor but never used — TKE is always initialized to zero regardless. Either wire it up (non-zero TKE warm-start) or remove the field.
- ~~Coupler z₀ₘ defaults don't match standalone run.~~ **Resolved** for our own components: `larcform1_ice` and `clima_seaice_column` both set z₀ₘ = z₀ᵦ = 1e-3 m (Pithan modal). Still true of *upstream's* `PrescribedIceSimulation` (1e-4 m) and `ClimaSeaIceSimulation` (5.8e-5 m), so it applies to any run built on those.

## Architecture

### Larcform1 Profile (`AtmosphericProfilesLibrary.jl`)

Defined in `AtmosphericProfilesLibrary.jl/src/profiles/Larcform1.jl`. Provides:
- Temperature: linear lapse rate (8 K/km) up to 300 hPa, isothermal above
- RH: 80% at surface → 20% at 600 hPa
- Geostrophic wind: u=5 m/s below 600 hPa, 0 above; v=0

### ClimaCoupler SCM Coupling

The coupler orchestrates a sequential stepping loop:
1. Step atmosphere (`ClimaAtmos` integrator advances by `Δt_cpl`)
2. Update surface area fractions (ice concentration → ice/ocean fraction)
3. Exchange non-turbulent fluxes (radiation, precipitation) via `FieldExchanger.jl`
4. Compute turbulent fluxes (Monin-Obukhov) via `FluxCalculator.jl`
5. Compute ocean↔sea-ice fluxes
6. Write diagnostics

The `CoupledSimulation` struct holds all component sims in a `model_sims` NamedTuple.
SCM-specific handling is via `domain_type: column` and `scm_surface_type: sea_ice`.

### Field Exchange

- Coupler → Atmos: surface temperature, albedo, roughness lengths
- Atmos → Surface: precipitation, downwelling radiation
- Turbulent fluxes (sensible heat, latent heat, momentum) computed centrally in the coupler using area-weighted `SurfaceFluxes.jl` calls

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

Sync local changes and launch a run in a detached tmux session:

```bash
bash scripts/sync_to_remote.sh
ssh stratus 'export PATH=/home/yoder/.juliaup/bin:$PATH && cd ~/clima/larcform1-experiments && tmux new-session -d -s lf1run "julia +1.12 -t auto --project --startup-file=no experiments/larcform1_driver.jl 2>&1 | tee output/lf1_run_$(date +%Y%m%d_%H%M%S).log"'
```

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
  sea-ice/                # coupled sea-ice surfaces (PLAN.md = status + findings)
    components/           # custom Interfacer sims: larcform1_ice, clima_seaice_column
    run_*.jl              # per-phase drivers (--dry-run validates config only)
    analysis/converted/   # 20-day suite in Pithan NetCDF form (*_cal.nc = calibrated)
  pithan-reproduction/    # our runs analyzed in the paper's own framework (Figs 1/4/5/6, Table 5)
  clw calibration/        # UKI calibration of the microphysics (configs/toml/ = final means)
ClimaAtmos.jl/        # submodule (dev'd into the root env) — carries an uncommitted
                      #   surface-flux-ownership fix; see Open TODOs
CloudMicrophysics.jl/ # vendored (registered 0.36 + Frostenberg a/b wired in; dev'd into the root env)
output/               # simulation output (gitignored)
  larcform1_minimal/
    output_NNNN/      # versioned runs (ActiveLink style)
docs/                 # Project level docs for Larcform1 experiments
```

## Checkpoints and restarts

```yaml
# Save state periodically
dt_save_state_to_disk: "1days"

# Auto-detect latest restart in output dir
detect_restart_file: true

# Or point explicitly
restart_file: "output/larcform1_minimal/output_0004/clima_atmos/day10.hdf5"
```

- Restart files are HDF5 containing all prognostic variables
- Restarting with a different `AtmosModel` will log a warning but proceed
- `reproducible_restart: true` forces deterministic cloud fractions (not for production)
- Diagnostic accumulators reset on restart — align `checkpoint_dt` with diagnostic `period`

## Diagnostics

Configured in YAML under the `diagnostics:` key. Format:
```yaml
diagnostics:
  - short_name: [ta, thetaa, pfull]
    period: 1hours
    reduction_time: average   # or: min, max, last
```

Output goes to `output/<job_id>/output_NNNN/clima_atmos/` as NetCDF files.
`netcdf_output_at_levels: true` skips vertical interpolation (raw model levels).

To add a custom diagnostic variable, create a `DiagnosticVariable` with:
- `short_name`, `long_name`, `units`, `comments`
- `compute!(out, state, cache, time)` function

## Submodules and vendored packages

```bash
git submodule update --init --recursive
```

`ClimaAtmos.jl` is a pinned submodule; `CloudMicrophysics.jl` is vendored (both
`Pkg.develop`'d into the root env). `ClimaCoupler.jl` is NOT a submodule — it comes
from the registry (v0.2.2, pinned in Manifest.toml).
The `.buildkite/` environment inside `ClimaAtmos.jl/` is activated for postprocessing
plots. Caution: that env has *registered* CloudMicrophysics, so the Frostenberg patch
is inert there — never run physics in the buildkite env.

See ./ClimaAtmos.jl/AGENTS.md for ClimaAtmos.jl specific best practices from the developers.