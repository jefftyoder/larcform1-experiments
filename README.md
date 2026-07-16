# Larcform1 Experiments

This repository brings together the various parts of the [CliMA](https://clima.caltech.edu/) software stack used to implement the [LARCFORM1 experiment](https://doi.org/10.1002/2016MS000630) — the Pithan et al. (2016) single-column model (SCM) intercomparison of the Arctic wintertime boundary layer — in [ClimaAtmos.jl](https://github.com/CliMA/ClimaAtmos.jl).

The experiment is an SCM run at 80°N starting 1 January (zero insolation), initialized from the Pithan et al. (2016) profiles: 250 K initial surface temperature over 1 m of sea ice with 0.1 m w.e. of snow, 5 m s⁻¹ geostrophic zonal wind below 600 hPa, and prescribed greenhouse-gas concentrations. Runs are 20 days, with analysis focused on the first 10 days. See `CLAUDE.md` for the full experiment protocol (boundary/initial conditions, GHG concentrations, initial profiles, and a summary of the participating models).

## Installation

Recommended Julia version: **v1.12** (older versions fail to precompile).

```bash
git clone https://github.com/jefftyoder/larcform1-experiments
cd larcform1-experiments
git submodule update --init --recursive
julia +1.12 --project -e 'using Pkg; Pkg.develop(path="ClimaAtmos.jl"); Pkg.instantiate()'
```

`ClimaAtmos.jl` is a pinned git submodule (branch `jy/coldslab`). Use it in the root environment via `Pkg.develop(path="ClimaAtmos.jl")` (included in the install command above). Note the submodule's `.buildkite/` environment is a separate Julia project used by the standalone run script below.

## Running the Larcform1 Case

The standard workflow runs the standalone ClimaAtmos SCM and converts its output to the Pithan (2016) intercomparison format (requires `conda` with an environment named `clenv` containing the Python deps used by `scripts/convert_to_pithan.py`, notably `numpy`, `xarray`, and `netcdf4`):

```bash
# From the repo root — runs the sim, then convert_to_pithan.py on the latest output
bash scripts/run_larcform1.sh

# Eisenman sea-ice variant, or reprocess existing output without re-running
bash scripts/run_larcform1.sh --job-id larcform1_eisenman_1M_prognostic_edmfx
bash scripts/run_larcform1.sh --skip-sim
```

The script drives `ClimaAtmos.jl/.buildkite/ci_driver.jl` in the submodule's `.buildkite` environment, with model configs from `ClimaAtmos.jl/config/model_configs/<job_id>.yml` (default `larcform1_1M_prognostic_edmfx`). Output lands in `ClimaAtmos.jl/output/<job_id>/output_NNNN/` (versioned per run), and Pithan-format NetCDF goes to `~/clima/Pithan2016_Data/my_analysis/data` by default.

### Coupled runs (ClimaCoupler)

`experiments/larcform1_driver.jl` runs the SCM coupled to sea-ice / slab-ocean surface models via [ClimaCoupler.jl](https://github.com/CliMA/ClimaCoupler.jl), with configs in `coupled_configs/`:

| Config | Description |
|---|---|
| `larcform1_slabocean_coupled.yml` | Slab-ocean coupled run (driver default) |
| `larcform1_seaice_edonly_coupled.yml` | Sea-ice run, ED-only turbulence |
| `larcform1_full_slabocean.yml` | Full-physics slab-ocean run |
| `larcform1_ci.yml` | Short CI/smoke-test config |

```bash
julia +1.12 -t auto --project experiments/larcform1_driver.jl \
  --config_file coupled_configs/larcform1_slabocean_coupled.yml
```

Note: ClimaCoupler is not currently a dependency of the root environment — add it (`Pkg.add("ClimaCoupler")`) before running the coupled driver. Sea-ice component setups live under `experiments/sea-ice/`. For sensitivity sweeps, prefer modifying the config dict programmatically (`ClimaCoupler.Input.get_coupler_config_dict`) over multiplying YAML files — see `CLAUDE.md` for the pattern and for an important caveat about parameter TOMLs in coupled runs (`coupler_toml` vs the atmos `toml` key).

### Running on Stratus

Remote runs go through the scripts in `scripts/`:

- `sync_to_remote.sh` — rsync the local working tree (including uncommitted work) up to Stratus; the default iteration workflow.
- `deploy_to_remote.sh` — commit-traceable deploys (fetch + hard reset + submodule update); aborts on a dirty tree or unpushed commits.
- `sync_from_remote.sh` — pull `output/` back down after a run.

See the "Running on Stratus" section of `CLAUDE.md` for the full workflow, including the tmux launch command and the `julia +1.12` channel pin (juliaup's default on Stratus is 1.11, which fails to precompile).

## Project Structure

```
scripts/
  run_larcform1.sh        # run standalone SCM + convert output to Pithan format
  convert_to_pithan.py    # ClimaAtmos NetCDF → Pithan2016 intercomparison format
  sync_to_remote.sh       # Stratus sync/deploy workflow (see above)
  deploy_to_remote.sh
  sync_from_remote.sh
  *.py                    # profile / skew-T / intercomparison plotting utilities
experiments/
  larcform1_driver.jl     # coupled entrypoint: CoupledSimulation → run! → postprocess
  larcform1_climaseaice.jl
  sea-ice/                # sea-ice component models, configs, and analysis
  pithan-reproduction/    # reproduction of the Pithan et al. (2016) cases
  ...                     # calibration, sensitivity, benchmark, and speed-test runs
coupled_configs/          # YAML configs for coupled (ClimaCoupler) runs
postprocessing/           # postprocess.jl, initial-profile plots (own Project.toml)
docs/                     # project-level notes (literature review, PLOTTING.md)
ClimaAtmos.jl/            # pinned submodule, branch jy/coldslab (dev'd into the root env)
figures/                  # generated figures
output/                   # simulation output (gitignored)
Pithan 2016 Intercomparison Data/  # reference data from the intercomparison
```

Further reading:

- `CLAUDE.md` — experiment protocol, architecture notes, coupler caveats, and remote-run workflow.
- `docs/PLOTTING.md` — plotting and postprocessing guide.
- `ClimaAtmos.jl/AGENTS.md` — ClimaAtmos-specific development practices.
