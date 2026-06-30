# ci_plots
ci_plots (continuous integration plots) are handled by 
```
ClimaAtmos.jl/post_processing/ci_plots.jl
```
(relative to `larcform1-experiments`).

## Note on jobs and job names:
`reference_job_id` can be used to pass simulations with different strings for `job_id` to 
the same plotting structure.
For example, if your `job_id=larcform1_seaicetest`, you can still set 
`reference_job_id=larcform1` for the purposes of plotting