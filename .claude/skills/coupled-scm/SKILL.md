---
name: coupled-scm
description: "Setting up coupled Clima single-column model (SCM) experiments with ClimaCoupler.jl: config wiring, surface models, overlay pattern, custom components, and pitfalls"
---

# Setting Up Coupled Clima SCM Experiments

Reference: [ClimaCoupler running docs](https://clima.github.io/ClimaCoupler.jl/stable/running/)

## Core SCM YAML keys

Three keys make a coupled run single-column:

```yaml
domain_type: "column"                # (required) switches from global to SCM
column_latlon: [80.0, 0.0]          # [lat, lon] degrees; sets radiation, albedo, Coriolis
scm_surface_type: "ocean"           # "ocean" | "sea_ice" | "land" (required for column)
```

`scm_surface_type` activates exactly one surface component; the others are disabled.
Which *variant* of that component (slab vs prescribed vs custom) is controlled by
`mode_name` and the component-specific keys below.

## Surface model selection matrix

| scm_surface_type | mode_name            | Component key        | Result                                      |
|------------------|----------------------|----------------------|---------------------------------------------|
| `"ocean"`        | `"slabplanet_aqua"`  | `ocean_model: "slab"` | Slab ocean (evolving SST)                  |
| `"ocean"`        | `"amip"`             | (default)            | Prescribed SST from HadISST                 |
| `"sea_ice"`      | `"amip"`             | `ice_model: "prescribed"` | PrescribedIceSimulation (1D slab energy eq.) |
| `"sea_ice"`      | `"amip"`             | `ice_model: "clima_seaice"` | ClimaSeaIce (upstream CMIP extension)    |
| `"sea_ice"`      | `"amip"`             | `ice_model: "clima_seaice_column"` | Custom ClimaSeaIce column component (this project) |
| `"sea_ice"`      | `"amip"`             | `ice_model: "larcform1_ice"` | Custom Holloway-Manabe slab ice (this project) |
| `"land"`         | `"slabplanet_terra"` | `land_model: "bucket"` | Bucket land model                         |

For sea ice, use `mode_name: "amip"` (AMIP provides the prescribed-ocean backdrop
that sea-ice configurations expect). For slab ocean, use `mode_name: "slabplanet_aqua"`.

## Surface flux ownership

```yaml
surface_setup: "PrescribedSurface"   # coupler owns turbulent fluxes (standard for coupled SCM)
```

The alternative, `"DefaultMoninObukhov"`, makes ClimaAtmos recompute fluxes internally,
double-counting. Always use `PrescribedSurface` for coupled runs unless you have a
specific reason.

## Minimal slab-ocean SCM config

```yaml
# --- Coupler wiring ---
domain_type: "column"
column_latlon: [80.0, 0.0]
scm_surface_type: "ocean"
mode_name: "slabplanet_aqua"
ocean_model: "slab"
land_model: "nothing"
surface_setup: "PrescribedSurface"
dt_cpl: "30secs"
coupler_output_dir: "output"

# --- Atmosphere ---
initial_condition: "Larcform1"
dt: "30secs"
dt_rad: "30secs"
t_end: "20days"
start_date: "20010101"

# Spatial
z_max: 9000.0
z_elem: 90
z_stretch: true
dz_bottom: 20.0

# Solver
ode_algo: "ARS343"
approximate_linear_solve_iters: 2

# Physics
rad: "allskywithclear"
insolation: "larcform1"
turbconv: edonly_edmfx
cloud_model: quadrature
microphysics_model: "1M"

# Output
netcdf_output_at_levels: true
output_default_diagnostics: false
diagnostics:
  - short_name: [ta, thetaa, pfull, hus, cl, clw, cli]
    period: 1hours
    reduction_time: average
```

## Minimal sea-ice SCM config (prescribed ice)

```yaml
domain_type: "column"
column_latlon: [80.0, 0.0]
scm_surface_type: "sea_ice"
mode_name: "amip"
surface_setup: "PrescribedSurface"
dt_cpl: "30secs"
# ... atmosphere keys same as slab-ocean example ...
```

The default `ice_model: "prescribed"` gives `PrescribedIceSimulation` (Holloway-Manabe
slab energy equation with HadISST concentration). For column mode at high latitudes
there is a known bug: the daily SIC callback re-reads HadISST without a column-mode
guard, clobbering the init-time full-cover fraction and crashing at the first day
boundary. Workaround: patch `read_sic_data!` at the top of the driver script (see
`experiments/sea-ice/run_prescribed_ice.jl` for the exact monkey-patch).

## The overlay config pattern (this project)

Production runs use a two-layer config: a base ClimaAtmos standalone config plus a
coupler overlay that adds/overrides coupler-specific keys. The driver merges them,
validates all keys, and writes the generated config.

```
ClimaAtmos.jl/config/model_configs/larcform1_1M_prognostic_edmfx.yml   (base)
  + experiments/sea-ice/configs/lf1_clima_seaice_column_20d_overlay.yml (overlay)
  = experiments/sea-ice/configs/generated_lf1_clima_seaice_column_20d.yml (merged)
```

Driver pattern (from `run_prescribed_ice.jl`, `run_clima_seaice_column.jl`):

```julia
import YAML
import ClimaAtmos
import ClimaCoupler
import ClimaCoupler: Input, CoupledSimulation, run!

# If using custom components, include() BEFORE CoupledSimulation()
include("components/clima_seaice_column.jl")

atmos_dict = YAML.load_file(ATMOS_CONFIG)
overlay_dict = YAML.load_file(OVERLAY_CONFIG)

# Config hygiene: fail on unrecognized keys
coupler_defaults = Input.parse_commandline(Input.argparse_settings())
atmos_defaults = Input.atmos_default_config_dict()
known_keys = union(keys(coupler_defaults), keys(atmos_defaults))
unknown = setdiff(union(keys(atmos_dict), keys(overlay_dict)), known_keys)
isempty(unknown) || error("Unrecognized config keys: $unknown")

merged = merge(atmos_dict, overlay_dict)  # overlay wins
YAML.write_file(generated_path, merged)

cs = CoupledSimulation(generated_path)
run!(cs)
```

## Custom component registration

Custom surface models are registered via Julia's Val-dispatch on the `ice_model` /
`ocean_model` string. Include the component file before constructing the simulation:

```julia
# In the component file (e.g. components/clima_seaice_column.jl):
function Interfacer.SeaIceSimulation(::Type{FT}, ::Val{:clima_seaice_column}; kwargs...) where {FT}
    return ClimaSeaIceColumnSimulation(FT; kwargs...)
end

# In the driver:
include("components/clima_seaice_column.jl")
cs = CoupledSimulation(config_path)  # coupler dispatches on ice_model: "clima_seaice_column"
```

The component struct must subtype the appropriate `Interfacer.Abstract*Simulation`
(`AbstractSeaIceSimulation`, `AbstractOceanSimulation`, `AbstractLandSimulation`) and
implement the required `Interfacer.get_field`, `Interfacer.update_field!`,
`Interfacer.step!`, and `FluxCalculator.update_turbulent_fluxes!` methods.

This project's custom components live in `experiments/sea-ice/components/`:
- `larcform1_ice.jl`: Holloway-Manabe slab ice (`ice_model: "larcform1_ice"`)
- `clima_seaice_column.jl`: ClimaSeaIce thermodynamic column (`ice_model: "clima_seaice_column"` or `"clima_seaice_column_nosnow"`)

## Parameter TOMLs: use `coupler_toml`, never atmos `toml`

**Critical pitfall (ClimaCoupler v0.2.2 bug):** parameters listed under the atmos
`toml:` key are silently reverted to ClimaParams defaults. The coupler builds its own
parameter dictionary from `coupler_toml:` and uses it as the override, clobbering
atmos-toml values. Always use:

```yaml
coupler_toml:
  - "path/to/params.toml"
```

Paths resolve relative to cwd first, then `pkgdir(ClimaCoupler)`.

**Constraint:** every `coupler_toml` entry must be used by the atmos model, or the
strict unused-parameter check aborts. Surface-only parameters (e.g. `seaice_column_*`)
cannot go through TOML; use component kwargs or the registered-name pattern instead
(e.g. `ice_model: "clima_seaice_column_nosnow"`).

Verify parameters actually landed by grepping `output/<job>/.../<job>_parameters.toml`.

## Running from the REPL (interactive / sensitivity sweeps)

```julia
using ClimaCoupler
import ClimaAtmos
import ClimaCoupler: Input, CoupledSimulation, run!

config_dict = Input.get_coupler_config_dict("coupled_configs/larcform1_slabocean_coupled.yml")
config_dict["t_end"] = "2days"
config_dict["job_id"] = "my_sensitivity_run"

cs = CoupledSimulation(config_dict)
run!(cs)
```

For step-by-step control:
```julia
cs = CoupledSimulation(config_dict)
step!(cs)                          # one coupling timestep
@info "t = $(cs.t[])"
while cs.t[] < cs.tspan[end]
    step!(cs)
end
```

## All coupler YAML options (SCM-relevant subset)

### Simulation identity
| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `config_file` | String | `amip_default.yml` | Main YAML config |
| `job_id` | String | config filename | Unique run identifier |
| `mode_name` | String | `"amip"` | `amip`, `slabplanet_aqua`, `slabplanet_terra`, `slabplanet`, `cmip`, `subseasonal` |
| `coupler_toml` | Vector{String} | `[]` | TOML parameter override files |

### SCM-specific
| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `domain_type` | String | `"global"` | `"column"` for SCM |
| `column_latlon` | Vector{Float64} | `[0.0, 0.0]` | `[lat, lon]` degrees |
| `scm_surface_type` | String | `nothing` | `"land"`, `"ocean"`, or `"sea_ice"` (required for column) |

### Time
| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `t_end` | String | `"800secs"` | `"Nsecs"`, `"Ndays"`, etc. |
| `dt` | String | `"400secs"` | Component model timestep |
| `dt_cpl` | String | `"400secs"` | Coupling timestep |
| `start_date` | String | `"20000101"` | `YYYYMMDD` |
| `checkpoint_dt` | String | `"90days"` | Checkpoint interval |

### Component models
| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `surface_setup` | String | `"PrescribedSurface"` | `PrescribedSurface` or `DefaultMoninObukhov` |
| `ice_model` | String | `"prescribed"` | `prescribed`, `clima_seaice`, or custom registered names |
| `ocean_model` | String | (from mode) | `"slab"` for evolving SST |
| `land_model` | String | `"bucket"` | `bucket` or `integrated` |
| `evolving_ocean` | Bool | `true` | Dynamic slab vs constant SST |
| `albedo_model` | String | `"CouplerAlbedo"` | `ConstantAlbedo`, `RegressionFunctionAlbedo`, `CouplerAlbedo` |

### Restart
| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `detect_restart_files` | Bool | `false` | Auto-detect restarts |
| `restart_dir` | String | `nothing` | Directory with restart files |

### Diagnostics
| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `use_coupler_diagnostics` | Bool | `true` | Coupler-level diagnostics |
| `coupler_output_dir` | String | `"output"` | Output directory |
| `coupler_diagnostics_period` | String | auto | `"Nhours"`, `"Ndays"`, etc. |

### Compute
| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `FLOAT_TYPE` | String | `"Float64"` | `Float64` or `Float32` |
| `device` | String | `"auto"` | `auto`, `CPUSingleThreaded`, `CPUMultiThreaded`, `CUDADevice` |

## Config precedence (lowest to highest)

1. ClimaAtmos defaults
2. ClimaCoupler defaults (`Input.argparse_settings()`)
3. Command-line arguments
4. ClimaAtmos config file (`atmos_config_file`)
5. ClimaCoupler config file (`config_file`)

In the overlay pattern, `merge(atmos_dict, overlay_dict)` means overlay wins.

## Existing configs in this project

| Config | Surface | Physics | Duration | Notes |
|--------|---------|---------|----------|-------|
| `coupled_configs/larcform1_ci.yml` | Slab ocean | 0M, gray rad | 3 days | Minimal CI smoke test |
| `coupled_configs/larcform1_full_slabocean.yml` | Slab ocean | 1M, prognostic EDMFX | 20 days | Full physics, prognostic updrafts |
| `coupled_configs/larcform1_slabocean_coupled.yml` | Slab ocean | 1M, edonly EDMFX | 20 days | Production edonly reference |
| `coupled_configs/larcform1_seaice_edonly_coupled.yml` | Prescribed ice | 1M, edonly EDMFX | 20 days | Sea-ice with edonly |
| `experiments/sea-ice/configs/*_overlay.yml` | Various ice models | Calibrated 1M | 10-20 days | Overlay pattern, merged at runtime |

## Checklist for a new coupled SCM experiment

1. **Pick surface type and mode:** set `scm_surface_type`, `mode_name`, and the component model key (`ice_model`/`ocean_model`/`land_model`)
2. **Set `surface_setup: "PrescribedSurface"`** unless you have a reason not to
3. **Use `coupler_toml` for parameter overrides**, never atmos `toml`
4. **Match `dt` and `dt_cpl`:** coupling timestep should be a multiple of the component timestep (often equal for SCM)
5. **Set `dt_rad`:** radiation can be less frequent than dynamics (e.g. `"30mins"`) but must divide `t_end`
6. **Custom components:** `include()` before `CoupledSimulation()`; register via Val-dispatch on the model name string
7. **Validate config keys:** check against `Input.argparse_settings()` + `Input.atmos_default_config_dict()` to catch silently ignored keys
8. **Give each run a unique `job_id`:** same `job_id` with same `coupler_output_dir` overwrites previous output
9. **Verify parameters landed:** grep `output/<job>/.../<job>_parameters.toml` after a short test run
