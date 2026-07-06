"""Build the EC-Earth observation target for the clw calibration.

Reads the Pithan 2016 EC-Earth output, computes day-2 (hours 25-48) time-mean
clw/cli profiles, linearly interpolates them onto the fixed pressure levels
used by the observation map (1005..905 hPa, step 10), and writes them as CSV.

The log10 transform and noise are applied on the Julia side
(model_interface.jl) so that observations and forward-model output are
guaranteed to go through identical code.

Usage (from repo root):
    conda run -n clenv python "experiments/clw calibration/scripts/build_observations.py"
"""

from pathlib import Path

import numpy as np
import xarray as xr

REPO_ROOT = Path(__file__).resolve().parents[3]
EXPERIMENT_DIR = Path(__file__).resolve().parents[1]
ECEARTH = REPO_ROOT / "Pithan 2016 Intercomparison Data" / "EC-Earth.nc"
OUT_CSV = EXPERIMENT_DIR / "observations" / "ecearth_day2_profiles.csv"

# Must match P_LEVELS_HPA in model_interface.jl (995 top-of-window: the model's
# lowest cell center is ~1000 hPa, so 1005 would extrapolate)
P_LEVELS_HPA = np.arange(995.0, 904.9, -10.0)
DAY2 = slice(24, 48)  # 0-based hourly indices for day 2


def main():
    ds = xr.load_dataset(ECEARTH)
    clw = ds["clw"].isel(time=DAY2).mean("time").values
    cli = ds["cli"].isel(time=DAY2).mean("time").values
    p_hpa = ds["p"].isel(time=DAY2).mean("time").values / 100.0

    # np.interp needs ascending x
    order = np.argsort(p_hpa)
    clw_i = np.interp(P_LEVELS_HPA, p_hpa[order], clw[order])
    cli_i = np.interp(P_LEVELS_HPA, p_hpa[order], cli[order])

    OUT_CSV.parent.mkdir(exist_ok=True)
    with open(OUT_CSV, "w") as f:
        f.write("p_hPa,clw,cli\n")
        for p, w, i in zip(P_LEVELS_HPA, clw_i, cli_i):
            f.write(f"{p:.1f},{w:.6e},{i:.6e}\n")

    print(f"Wrote {OUT_CSV}")
    print(f"{'p (hPa)':>8s} {'clw':>12s} {'cli':>12s}")
    for p, w, i in zip(P_LEVELS_HPA, clw_i, cli_i):
        print(f"{p:8.1f} {w:12.4e} {i:12.4e}")


if __name__ == "__main__":
    main()
