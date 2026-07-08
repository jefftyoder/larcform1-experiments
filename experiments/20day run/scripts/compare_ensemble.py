"""
Compare the 20-day ClimaAtmos Larcform1 run against the Pithan 2016 ensemble.

Reads the Pithan-format ClimaAtmos file (produced by scripts/convert_to_pithan.py
--suffix 1h_average) plus all 15 ensemble records, then writes comparison figures
to the experiment's figures/ dir and prints a per-model metrics table.

Usage (from repo root):
    python "experiments/20day run/scripts/compare_ensemble.py" \\
        [--clima-nc "experiments/20day run/output/ClimaLarcform1.nc"]
"""

import argparse
import glob
import os
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import xarray as xr

REPO_ROOT = Path(__file__).resolve().parents[3]
ENSEMBLE_DIR = REPO_ROOT / "Pithan 2016 Intercomparison Data"
EXPERIMENT_DIR = Path(__file__).resolve().parents[1]
FIG_DIR = EXPERIMENT_DIR / "figures"

# Liquid-presence threshold for "last liquid hour" (kg/m^2). 1e-3 reproduces
# the hour-51 EC-Earth glaciation used in lf1e-clw-calibration-1.md.
CLWVI_THRESHOLD = 1e-3

# --- dataviz reference palette (light mode) ---------------------------------
C_CLIMA = "#2a78d6"  # categorical slot 1 (blue) — our model
C_ECEARTH = "#e34948"  # categorical slot 6 (red) — calibration reference
C_ENSEMBLE = "#898781"  # muted ink — context members
C_GRID = "#e1e0d9"
C_AXIS = "#c3c2b7"
C_TEXT = "#0b0b0b"
C_TEXT2 = "#52514e"
SURFACE = "#fcfcfb"

plt.rcParams.update(
    {
        "figure.facecolor": SURFACE,
        "axes.facecolor": SURFACE,
        "savefig.facecolor": SURFACE,
        "axes.edgecolor": C_AXIS,
        "axes.labelcolor": C_TEXT2,
        "axes.titlecolor": C_TEXT,
        "xtick.color": C_TEXT2,
        "ytick.color": C_TEXT2,
        "axes.grid": True,
        "grid.color": C_GRID,
        "grid.linewidth": 0.6,
        "axes.axisbelow": True,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "font.family": "sans-serif",
        "font.size": 9,
        "legend.frameon": False,
    }
)


def load_model(path, decode_times=False):
    return xr.open_dataset(path, decode_times=decode_times)


def hours(ds):
    """Hourly record index — every record in the intercomparison is hourly."""
    n = ds.sizes["time"]
    return np.arange(n, dtype=float)


def surface_series(ds, var):
    """Return a (time,) float array for a surface variable, squeezing any
    singleton extra dims (some members carry ncl/x singletons)."""
    da = ds[var]
    extra = [d for d in da.dims if d != "time" and ds.sizes[d] == 1]
    if extra:
        da = da.squeeze(extra)
    return np.asarray(da, dtype=float)


def profile_at_hour(ds, var, hour):
    """Return (values, pressure_hPa) profiles at a given hour, or None."""
    if var not in ds:
        return None
    pvar = "p" if "p" in ds else ("pf" if "pf" in ds else None)
    if pvar is None:
        return None
    da, p = ds[var], ds[pvar]
    if "time" not in da.dims or hour >= ds.sizes["time"]:
        return None
    v = np.asarray(da.isel(time=hour), dtype=float).squeeze()
    parr = np.asarray(p.isel(time=hour) if "time" in p.dims else p, dtype=float).squeeze()
    if v.ndim != 1 or parr.shape != v.shape:
        return None
    return v, parr / 100.0


def last_liquid_hour(clwvi, threshold=CLWVI_THRESHOLD):
    idx = np.where(np.nan_to_num(clwvi) > threshold)[0]
    return int(idx[-1]) if idx.size else -1


def metrics(ds):
    clwvi = surface_series(ds, "clwvi")
    clivi = surface_series(ds, "clivi")
    ts = surface_series(ds, "ts")
    rlds = surface_series(ds, "rlds")
    n = len(ts)
    d2 = slice(24, min(49, n))  # day-2 window (h24-48)
    d5p = slice(120, n)  # days 5+ (ice phase)
    return {
        "n_hours": n,
        "last_liquid_h": last_liquid_hour(clwvi),
        "clwvi_day2": float(np.nanmean(clwvi[d2])),
        "clwvi_max": float(np.nanmax(clwvi)),
        "clivi_day5plus": float(np.nanmean(clivi[d5p])),
        "ts_final": float(ts[-1]),
        "ts_min": float(np.nanmin(ts)),
        "rlds_mean": float(np.nanmean(rlds)),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--clima-nc",
        default=str(EXPERIMENT_DIR / "output" / "ClimaLarcform1.nc"),
    )
    args = ap.parse_args()

    FIG_DIR.mkdir(exist_ok=True)

    clima = load_model(args.clima_nc)
    ensemble = {}
    for f in sorted(glob.glob(str(ENSEMBLE_DIR / "*.nc"))):
        name = os.path.basename(f)[:-3]
        ensemble[name] = load_model(f)

    # ------------------------------------------------------------------ metrics
    rows = [("ClimaAtmos", metrics(clima))]
    rows += [(name, metrics(ds)) for name, ds in ensemble.items()]
    hdr = (
        f"{'model':22s} {'n_h':>4s} {'lastliq_h':>9s} {'clwvi_d2':>9s} "
        f"{'clwvi_max':>9s} {'clivi_d5+':>9s} {'ts_end':>7s} {'ts_min':>7s} {'rlds':>6s}"
    )
    print(hdr)
    print("-" * len(hdr))
    for name, m in rows:
        print(
            f"{name:22s} {m['n_hours']:4d} {m['last_liquid_h']:9d} "
            f"{m['clwvi_day2']:9.4f} {m['clwvi_max']:9.4f} {m['clivi_day5plus']:9.4f} "
            f"{m['ts_final']:7.1f} {m['ts_min']:7.1f} {m['rlds_mean']:6.1f}"
        )

    # ------------------------------------------------------- fig 1: time series
    panels = [
        ("clwvi", "Liquid water path (kg m$^{-2}$)", 1),
        ("clivi", "Ice water path (kg m$^{-2}$)", 1),
        ("ts", "Surface temperature (K)", 1),
        ("rlds", "Downwelling longwave at surface (W m$^{-2}$)", 1),
    ]
    fig, axes = plt.subplots(2, 2, figsize=(10, 6.4), constrained_layout=True)
    for ax, (var, label, sign) in zip(axes.flat, panels):
        for name, ds in ensemble.items():
            if name == "EC-Earth":
                continue
            ax.plot(hours(ds) / 24, sign * surface_series(ds, var),
                    color=C_ENSEMBLE, lw=0.7, alpha=0.45, zorder=1)
        ec = ensemble["EC-Earth"]
        ax.plot(hours(ec) / 24, sign * surface_series(ec, var),
                color=C_ECEARTH, lw=1.8, zorder=2, label="EC-Earth")
        ax.plot(hours(clima) / 24, sign * surface_series(clima, var),
                color=C_CLIMA, lw=2.0, zorder=3, label="ClimaAtmos")
        ax.set_title(label, fontsize=9.5, loc="left")
        ax.set_xlim(0, 20)
        ax.set_xlabel("day")
    handles, labels = axes.flat[0].get_legend_handles_labels()
    handles.append(plt.Line2D([], [], color=C_ENSEMBLE, lw=0.7, alpha=0.6))
    labels.append(f"ensemble (n={len(ensemble) - 1})")
    axes.flat[0].legend(handles, labels, loc="upper right", fontsize=8)
    fig.suptitle("Larcform1 20-day record: ClimaAtmos vs Pithan 2016 ensemble",
                 color=C_TEXT, fontsize=11)
    fig.savefig(FIG_DIR / "timeseries_vs_ensemble.png", dpi=160)
    plt.close(fig)

    # -------------------------------------------------- fig 2: glaciation timing
    glac = sorted(
        [(n, m["last_liquid_h"]) for n, m in rows],
        key=lambda kv: kv[1],
    )
    fig, ax = plt.subplots(figsize=(7, 4.6), constrained_layout=True)
    names = [n for n, _ in glac]
    vals = [max(v, 0) for _, v in glac]
    colors = [
        C_CLIMA if n == "ClimaAtmos" else (C_ECEARTH if n == "EC-Earth" else C_ENSEMBLE)
        for n in names
    ]
    ax.barh(names, np.array(vals) / 24, color=colors, height=0.55)
    ax.set_xlabel(f"last hour with clwvi > {CLWVI_THRESHOLD:g} kg m$^{{-2}}$ (day)")
    ax.set_title("Supercooled-liquid persistence", loc="left", color=C_TEXT)
    ax.grid(axis="x")
    ax.grid(axis="y", visible=False)
    fig.savefig(FIG_DIR / "glaciation_timing.png", dpi=160)
    plt.close(fig)

    # ------------------------------------------------------- fig 3: profiles
    prof_hours = [48, 240]
    prof_vars = [("t", "Temperature (K)"), ("clw", "Cloud liquid (kg kg$^{-1}$)"),
                 ("cli", "Cloud ice (kg kg$^{-1}$)")]
    fig, axes = plt.subplots(len(prof_hours), len(prof_vars),
                             figsize=(10.5, 7.2), constrained_layout=True)
    for i, h in enumerate(prof_hours):
        for j, (var, label) in enumerate(prof_vars):
            ax = axes[i, j]
            for name, ds in ensemble.items():
                if name == "EC-Earth":
                    continue
                r = profile_at_hour(ds, var, h)
                if r is not None:
                    ax.plot(r[0], r[1], color=C_ENSEMBLE, lw=0.7, alpha=0.45, zorder=1)
            r = profile_at_hour(ensemble["EC-Earth"], var, h)
            if r is not None:
                ax.plot(r[0], r[1], color=C_ECEARTH, lw=1.8, zorder=2, label="EC-Earth")
            r = profile_at_hour(clima, var, h)
            if r is not None:
                ax.plot(r[0], r[1], color=C_CLIMA, lw=2.0, zorder=3, label="ClimaAtmos")
            ax.set_ylim(1030, 700)
            if var == "t":
                ax.set_xlim(215, 265)
            if j == 0:
                ax.set_ylabel(f"hour {h}\npressure (hPa)")
            if i == len(prof_hours) - 1:
                ax.set_xlabel(label)
            if i == 0:
                ax.set_title(label, fontsize=9.5, loc="left")
    axes[0, 0].legend(loc="lower left", fontsize=8)
    fig.suptitle("Profiles vs ensemble (boundary layer, 1030-700 hPa)",
                 color=C_TEXT, fontsize=11)
    fig.savefig(FIG_DIR / "profiles_vs_ensemble.png", dpi=160)
    plt.close(fig)

    print(f"\nFigures written to {FIG_DIR}")


if __name__ == "__main__":
    main()
