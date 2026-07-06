# lf1e clw calibration — model interface for ClimaCalibrate
#
# Patterned on ClimaAtmos.jl/calibration/experiments/perfect_scm, but the
# observations come from EC-Earth (Pithan 2016) instead of a perfect-model run,
# so the observation map is custom: day-2 time-mean clw/cli profiles linearly
# interpolated onto fixed pressure levels, log10-transformed.

import ClimaAtmos as CA
import ClimaCalibrate
import EnsembleKalmanProcesses as EKP
import NCDatasets

import ClimaComms
ClimaComms.@import_required_backends

import JLD2
import LinearAlgebra
import Random
import Statistics

const EXPERIMENT_DIR = @__DIR__
const FORWARD_CONFIG = joinpath(EXPERIMENT_DIR, "configs", "forward_model.yml")
const BASE_TOML =
    joinpath(EXPERIMENT_DIR, "configs", "toml", "larcform1_calibration_base.toml")
const OBS_CSV = joinpath(EXPERIMENT_DIR, "observations", "ecearth_day2_profiles.csv")

# Observation space: log10(q + floor) of day-2 mean clw and cli on fixed
# pressure levels. Must match scripts/build_observations.py.
# 995 not 1005: the model's lowest cell center sits at ~1000 hPa (day-2 mean),
# so 1005 would extrapolate below the grid.
const P_LEVELS_HPA = collect(995.0:-10.0:905.0)  # 10 levels
const DAY2_HOURS = 25:48    # 1-based hourly-output indices for day 2
const CLOUD_FLOOR = 1e-7    # kg/kg; keeps log10 finite in clear sky
const OBS_NOISE_STD = 0.3   # diagonal σ in log10 space (≈ factor-2 tolerance)

log10_floor(q) = log10.(max.(q, 0.0) .+ CLOUD_FLOOR)

struct Larcform1CalibrationInterface <: ClimaCalibrate.AbstractModelInterface
    "Filepath to the forward-model configuration"
    config::String
    "Directory the calibration is saved to"
    output_dir::String
end

ClimaCalibrate.model_interface_filepath(::Larcform1CalibrationInterface) = @__FILE__

"""
    ClimaCalibrate.forward_model(interface, iter, member)

Run one ensemble member: the s11 forward config with the member's sampled
parameters. The base toml is the de-duplicated calibration copy (see
configs/toml/), so the sampled toml is the only source of the calibrated
parameters.
"""
function ClimaCalibrate.forward_model(
    interface::Larcform1CalibrationInterface,
    iter,
    member,
)
    Random.seed!(1234)
    config_dict = CA.load_yaml_file(interface.config)

    member_output_dir =
        ClimaCalibrate.path_to_ensemble_member(interface.output_dir, iter, member)
    config_dict["output_dir"] = member_output_dir
    config_dict["dt_save_state_to_disk"] = "Inf"

    sampled_parameter_file =
        ClimaCalibrate.parameter_path(interface.output_dir, iter, member)
    config_dict["toml"] = [BASE_TOML, sampled_parameter_file]

    atmos_config = CA.AtmosConfig(config_dict)
    simulation = CA.get_simulation(atmos_config)
    CA.solve_atmos!(simulation)
    return nothing
end

"""
    day2_mean(output_active_dir, short_name)

Day-2 (hours 25-48) time-mean profile of a 1h-average diagnostic, as a vector
over model levels.
"""
function day2_mean(output_active_dir, short_name)
    file = joinpath(output_active_dir, "$(short_name)_1h_average.nc")
    NCDatasets.NCDataset(file) do ds
        v = ds[short_name]
        dims = NCDatasets.dimnames(v)
        tdim = findfirst(==("time"), dims)
        tdim === nothing && error("no time dimension in $file (dims: $dims)")
        data = Array(v)
        n_time = size(data, tdim)
        n_time >= last(DAY2_HOURS) ||
            error("$file has $n_time hourly outputs; need ≥ $(last(DAY2_HOURS))")
        day2 = selectdim(data, tdim, DAY2_HOURS)
        return vec(Statistics.mean(day2, dims = tdim))
    end
end

"""
    interp_to_levels(p_hpa, vals, targets_hpa)

Linear interpolation of a model profile onto fixed pressure levels. Errors on
extrapolation — the level set was chosen inside both the model's and
EC-Earth's pressure range.
"""
function interp_to_levels(p_hpa, vals, targets_hpa)
    perm = sortperm(p_hpa)
    ps, vs = p_hpa[perm], vals[perm]
    return map(targets_hpa) do pt
        (pt < first(ps) || pt > last(ps)) &&
            error("target $pt hPa outside model range [$(first(ps)), $(last(ps))]")
        i = min(searchsortedlast(ps, pt), length(ps) - 1)
        w = (pt - ps[i]) / (ps[i + 1] - ps[i])
        vs[i] * (1 - w) + vs[i + 1] * w
    end
end

"""
    g_vector(output_active_dir)

Map one member's output to observation space:
[log10 clw(p₁..p₁₁); log10 cli(p₁..p₁₁)] of day-2 means. 22 entries.
"""
function g_vector(output_active_dir)
    p_hpa = day2_mean(output_active_dir, "pfull") ./ 100
    clw = interp_to_levels(p_hpa, day2_mean(output_active_dir, "clw"), P_LEVELS_HPA)
    cli = interp_to_levels(p_hpa, day2_mean(output_active_dir, "cli"), P_LEVELS_HPA)
    return vcat(log10_floor(clw), log10_floor(cli))
end

function ClimaCalibrate.observation_map(
    interface::Larcform1CalibrationInterface,
    iteration,
)
    ekp = JLD2.load_object(ClimaCalibrate.ekp_path(interface.output_dir, iteration))
    ensemble_size = EKP.get_N_ens(ekp)
    G = fill(NaN, 2 * length(P_LEVELS_HPA), ensemble_size)
    for m in 1:ensemble_size
        member_path =
            ClimaCalibrate.path_to_ensemble_member(interface.output_dir, iteration, m)
        try
            G[:, m] = g_vector(joinpath(member_path, "output_active"))
        catch e
            @error "Member $m failed; filling G column with NaN" exception = e
        end
    end
    return G
end

"""
    load_ecearth_observation()

EC-Earth day-2 profiles (built by scripts/build_observations.py) as an
`EKP.Observation`, transformed identically to `g_vector`.
"""
function load_ecearth_observation()
    isfile(OBS_CSV) ||
        error("$OBS_CSV missing — run scripts/build_observations.py first")
    rows = [parse.(Float64, split(l, ',')) for l in readlines(OBS_CSV)[2:end]]
    p = [r[1] for r in rows]
    all(isapprox.(p, P_LEVELS_HPA; atol = 1e-6)) ||
        error("observation pressure levels don't match P_LEVELS_HPA")
    y = vcat(log10_floor([r[2] for r in rows]), log10_floor([r[3] for r in rows]))
    covariance = LinearAlgebra.Diagonal(fill(OBS_NOISE_STD^2, length(y)))
    return EKP.Observation(
        Dict(
            "samples" => y,
            "covariances" => covariance,
            "names" => "ecearth_day2_log10_clw_cli",
        ),
    )
end

function ClimaCalibrate.analyze_iteration(
    ::Larcform1CalibrationInterface,
    ekp,
    g_ensemble,
    prior,
    output_dir,
    iteration,
)
    errors = EKP.get_error(ekp)
    @info "Iteration $iteration complete" misfit =
        (isempty(errors) ? NaN : last(errors)) constrained_param_means =
        EKP.get_ϕ_mean_final(prior, ekp)
    return nothing
end
