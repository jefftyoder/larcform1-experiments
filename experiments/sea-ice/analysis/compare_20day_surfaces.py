"""
Compare the 20-day coupled surface-model suite against the calibrated
slab-ocean reference run and the Pithan 2016 ensemble.

Models compared (all calibrated microphysics, identical atmosphere numerics):
  - slab ocean      — "experiments/20day run/output/ClimaLarcform1.nc"
                      (SlabOceanSST pinned near 250 K; lf1e-20day-1.md)
  - slab ice        — lf1_larcform1_ice_20d (Holloway–Manabe slab, Phase 1)
  - ClimaSeaIce     — lf1_clima_seaice_column_nosnow_20d (bare 1 m ice)
  - ClimaSeaIce+snow— lf1_clima_seaice_column_20d (1 m ice + 0.1 m w.e. snow)

Coupled runs are first converted with scripts/convert_to_pithan.py, e.g.:
    python scripts/convert_to_pithan.py \
        --nc-dir "output/<job>/<job>/output_0000/clima_atmos" \
        --suffix 1h_average --model-name <label> --out <experiment>/output/<label>.nc

Usage (from repo root):
    python "experiments/sea-ice/analysis/compare_20day_surfaces.py"

Missing model files are skipped with a warning, so this can run on partial
results. Figures go to experiments/sea-ice/analysis/figures/.
"""

import glob
import os
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import xarray as xr
from matplotlib.lines import Line2D

REPO_ROOT = Path(__file__).resolve().parents[3]
ENSEMBLE_DIR = REPO_ROOT / "Pithan 2016 Intercomparison Data"
ANALYSIS_DIR = Path(__file__).resolve().parents[0]
FIG_DIR = ANALYSIS_DIR / "figures"
OUT_DIR = ANALYSIS_DIR / "converted"

CLWVI_THRESHOLD = 1e-3  # kg/m^2; matches experiments/20day run/scripts/compare_ensemble.py

# Our runs: label -> (path, color). Blue family = coupled ice surfaces,
# violet = the slab-ocean reference, red = EC-Earth, gray = ensemble.
CLIMA_RUNS = {
    "Clima slab ocean": (
        REPO_ROOT / "experiments/20day run/output/ClimaLarcform1.nc",
        "#9d64c4",
    ),
    "Clima slab ice": (OUT_DIR / "ClimaSlabIce.nc", "#63b0f2"),
    "Clima ClimaSeaIce": (OUT_DIR / "ClimaSeaIceBare.nc", "#2a78d6"),
    "Clima ClimaSeaIce+snow": (OUT_DIR / "ClimaSeaIceSnow.nc", "#0b3f78"),
}
C_ECEARTH = "#e34948"
C_ENSEMBLE = "#898781"
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


def hours(ds):
    return np.arange(ds.sizes["time"], dtype=float)


def surface_series(ds, var):
    da = ds[var]
    extra = [d for d in da.dims if d != "time" and ds.sizes[d] == 1]
    if extra:
        da = da.squeeze(extra)
    return np.asarray(da, dtype=float)


def profile_at_hour(ds, var, hour):
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
    d2 = slice(24, min(49, n))
    d5p = slice(120, n)
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
    FIG_DIR.mkdir(exist_ok=True)

    clima = {}
    for label, (path, color) in CLIMA_RUNS.items():
        if Path(path).exists():
            clima[label] = (xr.open_dataset(path, decode_times=False), color)
        else:
            print(f"WARNING: {label} missing ({path}); skipping")

    ensemble = {}
    for f in sorted(glob.glob(str(ENSEMBLE_DIR / "*.nc"))):
        name = os.path.basename(f)[:-3]
        ensemble[name] = xr.open_dataset(f, decode_times=False)

    # ------------------------------------------------------------------ metrics
    rows = [(label, metrics(ds)) for label, (ds, _) in clima.items()]
    rows += [(name, metrics(ds)) for name, ds in ensemble.items()]
    hdr = (
        f"{'model':24s} {'n_h':>4s} {'lastliq_h':>9s} {'clwvi_d2':>9s} "
        f"{'clwvi_max':>9s} {'clivi_d5+':>9s} {'ts_end':>7s} {'ts_min':>7s} {'rlds':>6s}"
    )
    print(hdr)
    print("-" * len(hdr))
    for name, m in rows:
        print(
            f"{name:24s} {m['n_hours']:4d} {m['last_liquid_h']:9d} "
            f"{m['clwvi_day2']:9.4f} {m['clwvi_max']:9.4f} {m['clivi_day5plus']:9.4f} "
            f"{m['ts_final']:7.1f} {m['ts_min']:7.1f} {m['rlds_mean']:6.1f}"
        )
    with open(FIG_DIR / "metrics_table.txt", "w") as fh:
        fh.write(hdr + "\n" + "-" * len(hdr) + "\n")
        for name, m in rows:
            fh.write(
                f"{name:24s} {m['n_hours']:4d} {m['last_liquid_h']:9d} "
                f"{m['clwvi_day2']:9.4f} {m['clwvi_max']:9.4f} {m['clivi_day5plus']:9.4f} "
                f"{m['ts_final']:7.1f} {m['ts_min']:7.1f} {m['rlds_mean']:6.1f}\n"
            )

    # ------------------------------------------------------- fig 1: time series
    panels = [
        ("clwvi", "Liquid water path (kg m$^{-2}$)"),
        ("clivi", "Ice water path (kg m$^{-2}$)"),
        ("ts", "Surface temperature (K)"),
        ("rlds", "Downwelling longwave at surface (W m$^{-2}$)"),
    ]
    fig, axes = plt.subplots(2, 2, figsize=(10, 6.4), constrained_layout=True)
    for ax, (var, label) in zip(axes.flat, panels):
        for name, ds in ensemble.items():
            if name == "EC-Earth":
                continue
            ax.plot(hours(ds) / 24, surface_series(ds, var),
                    color=C_ENSEMBLE, lw=0.7, alpha=0.4, zorder=1)
        ec = ensemble["EC-Earth"]
        ax.plot(hours(ec) / 24, surface_series(ec, var),
                color=C_ECEARTH, lw=1.6, zorder=2, label="EC-Earth")
        for run_label, (ds, color) in clima.items():
            ax.plot(hours(ds) / 24, surface_series(ds, var),
                    color=color, lw=1.8, zorder=3, label=run_label)
        ax.set_title(label, fontsize=9.5, loc="left")
        ax.set_xlim(0, 20)
        ax.set_xlabel("day")
    handles, labels = axes.flat[0].get_legend_handles_labels()
    handles.append(Line2D([], [], color=C_ENSEMBLE, lw=0.7, alpha=0.6))
    labels.append(f"ensemble (n={len(ensemble) - 1})")
    axes.flat[2].legend(handles, labels, loc="upper right", fontsize=7.5)
    fig.suptitle(
        "Larcform1 20-day record: coupled surface models vs Pithan 2016 ensemble",
        color=C_TEXT, fontsize=11,
    )
    fig.savefig(FIG_DIR / "timeseries_vs_ensemble.png", dpi=160)
    plt.close(fig)

    # -------------------------------------------------- fig 2: glaciation timing
    glac = sorted([(n, m["last_liquid_h"]) for n, m in rows], key=lambda kv: kv[1])
    fig, ax = plt.subplots(figsize=(7, 5.4), constrained_layout=True)
    names = [n for n, _ in glac]
    vals = [max(v, 0) for _, v in glac]
    colors = []
    for n in names:
        if n in clima:
            colors.append(clima[n][1])
        elif n == "EC-Earth":
            colors.append(C_ECEARTH)
        else:
            colors.append(C_ENSEMBLE)
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
                    ax.plot(r[0], r[1], color=C_ENSEMBLE, lw=0.7, alpha=0.4, zorder=1)
            r = profile_at_hour(ensemble["EC-Earth"], var, h)
            if r is not None:
                ax.plot(r[0], r[1], color=C_ECEARTH, lw=1.6, zorder=2, label="EC-Earth")
            for run_label, (ds, color) in clima.items():
                r = profile_at_hour(ds, var, h)
                if r is not None:
                    ax.plot(r[0], r[1], color=color, lw=1.8, zorder=3, label=run_label)
            ax.set_ylim(1030, 700)
            if var == "t":
                ax.set_xlim(205, 265)
            if j == 0:
                ax.set_ylabel(f"hour {h}\npressure (hPa)")
            if i == len(prof_hours) - 1:
                ax.set_xlabel(label)
            if i == 0:
                ax.set_title(label, fontsize=9.5, loc="left")
    axes[0, 0].legend(loc="lower left", fontsize=7.5)
    fig.suptitle("Profiles vs ensemble (boundary layer, 1030-700 hPa)",
                 color=C_TEXT, fontsize=11)
    fig.savefig(FIG_DIR / "profiles_vs_ensemble.png", dpi=160)
    plt.close(fig)

    print(f"\nFigures written to {FIG_DIR}")


if __name__ == "__main__":
    main()
