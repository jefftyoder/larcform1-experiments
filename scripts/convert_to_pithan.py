"""
Convert ClimaAtmos Larcform1 output to a Pithan2016-compatible NetCDF file.

The Pithan2016 intercomparison notebooks expect one NetCDF per model containing
all variables in a (time, lev) layout with time in hours. ClimaAtmos produces one
file per variable with shape (z, y=1, x=1, time) and time in seconds.

Usage (from repo root):
    python experiments/larcform1_coupler/convert_to_pithan.py
    python experiments/larcform1_coupler/convert_to_pithan.py --job-id larcform1_full
    python experiments/larcform1_coupler/convert_to_pithan.py --model-name ClimaLarcform1 --out /path/to/out.nc

    # Standalone run (nc files directly in output dir, no clima_atmos/ subdir):
    python experiments/larcform1_coupler/convert_to_pithan.py \\
        --nc-dir output/larcform1_1M_edonly_edmfx/output_0004 \\
        --suffix 6h_average
"""

import argparse
import os
import re
import sys
from pathlib import Path

import numpy as np
import xarray as xr


# ---------------------------------------------------------------------------
# Output directory discovery (mirrors Julia find_latest_nc_dir in make_plots.jl)
# ---------------------------------------------------------------------------

def find_latest_nc_dir(output_root: Path) -> Path:
    """Return the highest-numbered output_NNNN/clima_atmos/ directory that
    contains at least one .nc file.  Matches Julia's last(sort(candidates))."""
    candidates = []
    for dirpath, _dirs, files in os.walk(output_root):
        p = Path(dirpath)
        if (re.search(r"output_\d+[/\\]?clima_atmos$", str(p)) and
                any(f.endswith(".nc") for f in files)):
            candidates.append(p)
    if not candidates:
        sys.exit(f"ERROR: No clima_atmos directories with .nc files found under {output_root}")
    return sorted(candidates)[-1]


# ---------------------------------------------------------------------------
# Variable loading helpers
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parents[1]   # ClimaLarcform1Experiments/


_SUFFIX = "3h_average"


def load_var(nc_dir: Path, short_name: str) -> xr.DataArray | None:
    """Load a single ClimaAtmos diagnostic variable, or return None if absent."""
    path = nc_dir / f"{short_name}_{_SUFFIX}.nc"
    if not path.exists():
        return None
    ds = xr.open_dataset(path, decode_times=False)
    da = ds[short_name]
    return da


def to_profile(da: xr.DataArray) -> xr.DataArray:
    """Squeeze (z, y=1, x=1, time) → (time, lev) and rename z → lev."""
    return (da
            .squeeze(["x", "y"])          # drop singleton horizontal dims
            .transpose("time", "z")       # → (time, z)
            .rename({"z": "lev"}))


def to_surface(da: xr.DataArray) -> xr.DataArray:
    """Squeeze (y=1, x=1, time) → (time,)."""
    return da.squeeze(["x", "y"])


def time_in_seconds(da: xr.DataArray) -> np.ndarray:
    """Return the 'time' coordinate in seconds since simulation start.
    Matches the convention used by the Pithan2016 model files."""
    return da.coords["time"].values.astype(float)


# ---------------------------------------------------------------------------
# Main conversion
# ---------------------------------------------------------------------------

def convert(nc_dir: Path, model_name: str, out_path: Path) -> None:
    print(f"Reading from: {nc_dir}")

    vars_3d = {}   # (time, lev) arrays
    vars_1d = {}   # (time,) arrays

    # ------------------------------------------------------------------
    # 3D profile variables
    # ------------------------------------------------------------------
    profile_map = {
        "ta":    "t",
        "pfull": "p",
        "hus":   "q",
        "hur":   "rh",
        "ua":    "u",
        "va":    "v",
        "clw":   "clw",
        "cli":   "cli",
        "cl":    "cl",
    }
    for clima_name, pithan_name in profile_map.items():
        da = load_var(nc_dir, clima_name)
        if da is None:
            print(f"  SKIP  {clima_name} (not found)")
            continue
        arr = to_profile(da)

        # cl is stored as % in ClimaAtmos; Pithan2016 convention is 0–1
        if clima_name == "cl":
            arr = (arr / 100.0).assign_attrs(da.attrs)
            arr.attrs["units"] = "1"  # Changed from "%" to dimensionless

        vars_3d[pithan_name] = arr
        print(f"  3D    {clima_name} → {pithan_name}  shape={arr.shape}")

    # ------------------------------------------------------------------
    # 1D surface variables (direct renames)
    # ------------------------------------------------------------------
    # ClimaAtmos sign conventions differ from Pithan2016:
    #   rlut, rlus: CliMA upward-positive → Pithan upward-negative (negate)
    #   hfls, hfss: CliMA upward-positive → Pithan upward-positive, but
    #               CliMA stores downward as negative, so negate to match
    #   prsn, pr:   CliMA downward-negative → Pithan positive (negate)
    surface_map = {
        "ts":    ("ts",    1),
        "rlds":  ("rlds",  1),
        "rlus":  ("rlus", -1),
        "rlut":  ("rlut", -1),
        "hfls":  ("hl",   -1),
        "hfss":  ("hs",   -1),
        "clivi": ("clivi", 1),
        "lwp":   ("clwvi", 1),
        "prsn":  ("precs",-1),
    }
    for clima_name, (pithan_name, sign) in surface_map.items():
        da = load_var(nc_dir, clima_name)
        if da is None:
            print(f"  SKIP  {clima_name} (not found)")
            continue
        arr = (to_surface(da) * sign).assign_attrs(da.attrs)
        vars_1d[pithan_name] = arr
        sign_str = "" if sign == 1 else " (sign-flipped)"
        print(f"  1D    {clima_name} → {pithan_name}{sign_str}  shape={arr.shape}")

    # ------------------------------------------------------------------
    # Derived: precr = pr - prsn
    # ------------------------------------------------------------------
    da_pr   = load_var(nc_dir, "pr")
    da_prsn = load_var(nc_dir, "prsn")
    if da_pr is not None and da_prsn is not None:
        # Both pr and prsn are downward-negative in CliMA; negate to Pithan positive
        precr = (-to_surface(da_pr)) - (-to_surface(da_prsn))
        precr = precr.clip(min=0)   # numerical noise guard
        vars_1d["precr"] = precr
        vars_1d["precr"].attrs = {
            "units": "kg m-2 s-1",
            "long_name": "Precipitation rate (rain, from pr − prsn)",
            "comments": "Rain component = total precip − snow"
        }
        print(f"  1D    pr - prsn → precr (sign-flipped)  shape={precr.shape}")

    # ------------------------------------------------------------------
    # Derived: prw = precipitable water = Σ(rhoa · hus · Δz)
    # ------------------------------------------------------------------
    da_rhoa = load_var(nc_dir, "rhoa")
    da_hus  = load_var(nc_dir, "hus")
    if da_rhoa is not None and da_hus is not None:
        rhoa = to_profile(da_rhoa)   # (time, lev)
        hus  = to_profile(da_hus)    # (time, lev)
        z    = rhoa.coords["lev"].values  # height in metres
        dz   = np.gradient(z)             # Δz at each level (m)
        prw  = (rhoa * hus * xr.DataArray(dz, dims="lev")).sum(dim="lev")
        vars_1d["prw"] = prw
        vars_1d["prw"].attrs = {
            "units": "kg m-2",
            "long_name": "Precipitable water (column-integrated)",
            "comments": "Σ(ρ_air × q × Δz) over model levels"
        }
        print(f"  1D    rhoa·hus·dz → prw  shape={prw.shape}")

    # ------------------------------------------------------------------
    # Derived: clt = total cloud cover (max-random overlap)
    #   C_tot = 1 - Π(1 - cl_i)
    # ------------------------------------------------------------------
    if "cl" in vars_3d:
        cl = vars_3d["cl"]   # (time, lev), fraction 0–1
        clt = 1.0 - (1.0 - cl).prod(dim="lev")
        vars_1d["clt"] = clt
        vars_1d["clt"].attrs = {
            "units": "1",
            "long_name": "Total cloud cover (max-random overlap)",
            "comments": "Cloud fraction 0–1; combines all vertical levels"
        }
        print(f"  1D    cl → clt (max-random overlap)  shape={clt.shape}")

    # ------------------------------------------------------------------
    # Build time coordinate in hours
    # ------------------------------------------------------------------
    # Use the 'date' coord from any loaded variable (all share the same time axis)
    sample_da = next(iter(vars_3d.values()), next(iter(vars_1d.values()), None))
    if sample_da is None:
        sys.exit("ERROR: No variables were loaded — nothing to write.")

    time_secs = time_in_seconds(sample_da)
    time_coord = xr.Variable(
        "time",
        time_secs,
        attrs={
            "units": "seconds since 2001-01-01T00:00:00",
            "long_name": "Time",
            "axis": "T",
        },
    )

    # ------------------------------------------------------------------
    # Assemble dataset
    # ------------------------------------------------------------------
    data_vars = {}

    for name, arr in vars_3d.items():
        data_vars[name] = xr.Variable(
            ["time", "lev"],
            arr.values,
            attrs=arr.attrs,
        )

    for name, arr in vars_1d.items():
        data_vars[name] = xr.Variable(
            ["time"],
            arr.values,
            attrs=arr.attrs,
        )

    # lev coordinate: use the height-z values (for reference; pressure p is also
    # stored as a data variable for use as the plotting vertical axis)
    lev_coord = xr.Variable(
        "lev",
        sample_da.coords["lev"].values if "lev" in sample_da.coords else np.arange(60),
        attrs={"units": "m", "long_name": "Height above surface"},
    )

    ds_out = xr.Dataset(
        data_vars,
        coords={"time": time_coord, "lev": lev_coord},
        attrs={
            "title": f"Larcform1 — ClimaAtmos ({model_name})",
            "source": str(nc_dir),
            "model": model_name,
            "Conventions": "CF-1.8",
        },
    )

    out_path.parent.mkdir(parents=True, exist_ok=True)
    ds_out.to_netcdf(out_path)
    n_time = len(time_secs)
    n_lev  = len(lev_coord)
    print(f"\nWrote {out_path}  ({n_time} timesteps, {n_lev} levels)")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    global _SUFFIX

    default_out = REPO_ROOT.parent / "Pithan2016_Data" / "my_analysis" / "data"

    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--job-id",     default="larcform1_full",
                        help="Experiment name under output/ (default: larcform1_full). "
                             "Ignored when --nc-dir is set.")
    parser.add_argument("--nc-dir",     default=None,
                        help="Path to the directory containing per-variable .nc files. "
                             "When set, skips the output_NNNN/clima_atmos/ discovery walk.")
    parser.add_argument("--suffix",     default=None,
                        help="Filename suffix for per-variable files, e.g. '6h_average' or "
                             "'3h_average' (default: 3h_average).")
    parser.add_argument("--model-name", default="ClimaLarcform1",
                        help="Model name used for the output filename (default: ClimaLarcform1)")
    parser.add_argument("--out",        default=None,
                        help="Output path for the NetCDF file.  "
                             "Default: ../Pithan2016_Data/my_analysis/data/{model_name}.nc")
    args = parser.parse_args()

    if args.suffix is not None:
        _SUFFIX = args.suffix

    if args.nc_dir is not None:
        nc_dir = Path(args.nc_dir)
        if not nc_dir.is_absolute():
            nc_dir = REPO_ROOT / nc_dir
        if not nc_dir.exists():
            sys.exit(f"ERROR: --nc-dir not found: {nc_dir}")
    else:
        output_root = REPO_ROOT / "output" / args.job_id
        if not output_root.exists():
            sys.exit(f"ERROR: Output directory not found: {output_root}")
        nc_dir = find_latest_nc_dir(output_root)

    if args.out is not None:
        out_path = Path(args.out)
    else:
        out_path = default_out / f"{args.model_name}.nc"

    convert(nc_dir, args.model_name, out_path)


if __name__ == "__main__":
    main()
