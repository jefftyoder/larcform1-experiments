# clw sensitivity test #1
## author: Jeffrey Yoder
## date: July 02, 2026

# Goal
The goal of this experiment is to investigate the missing cloud liquid and low cloud ice in
current Larcform1 model runs using ClimaAtmos.jl 

# Protocol

## Setup
This experiment is based on my implementation of the Larcform1 experiment in ClimaAtmos.jl.
The original Larcform1 protocol is outlined in @cite{Pithan 2016}.
This implementation uses a modified SlabOceanSST initialized to 250K as the surface boundary
condition to approximate the 250K sea ice // sea ice + snow models used in the original 
intercomparison.

## Variations
Only vary one .yml or .toml setting per run.
0) EC-Earth Data
1) Base (`ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml`)
2) 0M microphysics
3) 2M microphysics (expect will not be stable)
4) All microphys processes disabled except cloud formation (see default_config.yml)
5) `sublimation_deposition_timescale` = `10`
6) `sublimation_deposition_timescale` = `400`
7) `sublimation_deposition_timescale` = `1_000`
8) `sublimation_deposition_timescale` = `10_000`
9) `condensation_evaporation_timescale` = `10`

If none of these succceed, we may begin tweaking other fields in the settings. Focus on 
cloud and microphysics processes.


## Validation
Results will be compared against the EC-Earth model from the Pithan 2016 intercomparison 
dataset (see the netcdf files in `REPO_ROOT/Pithan 2016 Intercomparison Data/`). Comparisons
will be against EC-Earth data, as the EC-Earth model is the closest model to our 
implementation which does manage to produce significant clw (q_cl,l > .1g/kg = 1e-4kg/kg).
Note that EC-Earth does not follow the same data naming conventions as ClimaAtmos.jl. We 
must be careful in handling the conversion and comparison.

Steps:
1) Check if each variation for whether surpasses threshold of .1g/kg
if step (1) passes, stop running models and check the following:
2) Compare cloud ice (cli) to values
3) Compare total specific humidity
4) Compare relative humidity
5) Compare vertically integrated cloud water (clwvi)
6) Compare vertically integrated cloud ice (clivi)
7) Compare precipitation rate for rain (prra)
8) Compare precipitation rate for snow (prsn)

## Running the Simulations

### Driver
This experiment uses `SlabOceanSST` as the surface (see Setup), which is the standalone
ClimaAtmos path — not the coupled sea-ice driver (`experiments/larcform1_driver.jl`). Run
each variation through `.buildkite/ci_driver.jl`, layering the base config with a
variation-specific overlay (`--config_file` merges in order, later files win on conflicts):

```bash
julia --project=ClimaAtmos.jl/.buildkite ClimaAtmos.jl/.buildkite/ci_driver.jl \
  --config_file ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml \
  --config_file "experiments/clw sensitivity experiments/configs/v2_0M.yml"
```

### Variation config files
One overlay YAML per variation under `experiments/clw sensitivity experiments/configs/`,
setting only `job_id`, `output_dir`, and the single changed key — this makes the overlay
file itself the record of what changed, enforcing "only vary one setting per run".

Caveat: `toml:` is a list and config merging is a plain `Dict` merge — a later config file
does not append to it, it replaces it wholesale. So overlays for the timescale sweeps
(variations 5–9) must specify the *full* toml list, not just the new file:

```yaml
# v5_subltime10.yml
toml: [toml/larcform1_1M_prognostic_edmfx.toml, "experiments/clw sensitivity experiments/toml/subltime10.toml"]
```
```toml
# toml/subltime10.toml
[sublimation_deposition_timescale]
value = 10
```

### Output location
`default_config.yml` exposes `output_dir` and `output_dir_style` directly
([default_config.yml:138](ClimaAtmos.jl/config/default_configs/default_config.yml#L138)) —
set these explicitly per variation instead of relying on `job_id` to derive the path:

```yaml
output_dir: "experiments/clw sensitivity experiments/output/lf1e-clw-1/v2_0M"
output_dir_style: "ActiveLink"   # default; numbers subfolders output_0001, output_0002, ...
                                  # output_active always points at the latest
```

Each variation gets its own subfolder under `experiments/clw sensitivity experiments/output/lf1e-clw-1/`,
so reruns don't clobber earlier results and postprocessing can glob
`lf1e-clw-1/v*/output_active/` to pick up the latest run of every variation.

### Batch execution
With 9 variations, script the loop (`run_variations.sh` or a small Julia driver) rather than
invoking each by hand, to avoid a typo changing two settings instead of one. Redirect each
run's stdout to a per-variation log (e.g. `output/.../v3_2M/run.log`) — useful for the
Validation step, and especially for variation 3 (2M), which is expected to be unstable and
may need its failure mode documented rather than silently rerun.

## Postprocessing

### Data processing
Reuse `scripts/convert_to_pithan.py` — it already does more than reshape the data: it
renames ClimaAtmos variables into EC-Earth's own vocabulary (`hus`→`q`, `ta`→`t`,
`pfull`→`p`, `hur`→`rh`, `lwp`→`clwvi`, `cl`→`cl` as 0–1 fraction, derives `precr` from
`pr − prsn`), and fixes CliMA's sign conventions to match Pithan2016. After conversion, our
output and `EC-Earth.nc` share variable names directly — no separate renaming layer needed
in the notebook.

Two things the converter does *not* handle, which the notebook must:

1. **Diagnostic period mismatch.** The converter defaults to `--suffix 3h_average`, but
   `larcform1_1M_prognostic_edmfx.yml` diagnoses everything at `period: 1hours`
   ([larcform1_1M_prognostic_edmfx.yml:74-91](ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml#L74-L91)).
   Every call must pass `--suffix 1h_average` explicitly.
2. **Vertical grid mismatch.** The converter's `lev` coordinate is z-height (metres), not
   pressure — it's a per-model raw level index, and ClimaAtmos's stretched z-grid does not
   line up level-for-level with EC-Earth's `nlev`. Both files carry their own `p(time, lev)`
   though, so profile comparisons must interpolate onto a common pressure grid via `p`
   rather than comparing by level index. EC-Earth's `ps` is constant at 101300 Pa for the
   full run, so its `p(nlev)` is effectively time-invariant — interpolate ClimaAtmos's
   profiles onto EC-Earth's fixed pressure levels once, not per-timestep.

Conversion call, one per variation:
```bash
python scripts/convert_to_pithan.py \
  --nc-dir "experiments/clw sensitivity experiments/output/lf1e-clw-1/v2_0M/output_active" \
  --suffix 1h_average \
  --model-name v2_0M \
  --out "experiments/clw sensitivity experiments/output/pithan_format/v2_0M.nc"
```
Do this for all variations in a loop (matching the glob-per-variation pattern from Running
the Simulations) rather than one-off by hand.

Open question to verify in the notebook, not blocking: EC-Earth's `clw`/`cli` are labeled
unit `"1"` — confirm by magnitude that this is actually kg/kg matching ClimaAtmos, not some
other normalization, before trusting direct comparison.

### Build check tables
- **Threshold table** (Validation step 1): for each variation, load the converted file,
  compute `max(clw)` over `(time, lev)` restricted to the first 10 days, flag
  pass/fail against 1e-4 kg/kg (0.1 g/kg). Columns: variation, job_id, max_clw_kgkg,
  passes_threshold, notes (e.g. document variation 3's instability/failure mode from
  `run.log` here rather than silently excluding it).
- **Extended comparison table** (Validation steps 2–8), only for variations that pass step
  1: mean bias / RMSE of `cli`, `q`, `rh` profiles and `clwvi`, `clivi`, `precr`, `precs`
  time series against EC-Earth, computed on the pressure-regridded data, over the first 10
  days.

### Plotting
- **Profiles** (time-mean over first 10 days, plotted against pressure `p`, inverted axis):
  `t`, `q`, `rh`, `clw`, `cli` — one ClimaAtmos variation vs EC-Earth per panel.
- **Time series** (first 10 days): `clwvi`, `clivi`, `precr`, `precs` — variation vs
  EC-Earth, one plot per variable, variations overlaid or faceted.
- Follow the `dataviz` skill for palette/styling once chart code is written.

Implementation order in `analysis.ipynb`:
1. Imports, paths, glob `output/lf1e-clw-1/v*/output_active/`
2. Call `convert_to_pithan.convert()` per variation (import directly, not subprocess)
3. Load `EC-Earth.nc`
4. Pressure-regrid helper (ClimaAtmos `p(time,lev)` → EC-Earth's fixed `p(lev)`)
5. Threshold + comparison tables
6. Profile plots
7. Time-series plots