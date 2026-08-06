---
name: run-config
description: "Checkpoint/restart configuration and diagnostic output setup for ClimaAtmos coupled runs"
---

# Run Configuration: Checkpoints and Diagnostics

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
