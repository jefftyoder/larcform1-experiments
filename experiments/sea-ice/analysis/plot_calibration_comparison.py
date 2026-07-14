"""
Calibrated vs uncalibrated microphysics across the three Larcform1 sea-ice
surfaces (20-day coupled runs).

- uncalibrated = the 2026-07-09 suite (ClimaParams defaults; the coupler_toml
  clobber bug meant the calibrated TOML never landed).  Files: <base>.nc
- calibrated   = the 2026-07-10 rerun with corrected coupler_toml (uki_1 means:
  Frostenberg a=0.2537, b=1.1944, snow-auto tau=831.9 s, ...).  Files: <base>_cal.nc

Pithan 2016 ensemble shown as light-gray context (EC-Earth highlighted).

Outputs -> experiments/sea-ice/analysis/figures/
  calibration_comparison_timeseries.png
  calibration_comparison_metrics.txt
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
CONV = REPO_ROOT / "experiments/sea-ice/analysis/converted"
FIG_DIR = REPO_ROOT / "experiments/sea-ice/analysis/figures"

MODELS = [
    ("Slab ice (Holloway-Manabe)", "ClimaSlabIce", "#2a78d6"),
    ("ClimaSeaIce, bare", "ClimaSeaIceBare", "#e08a1e"),
    ("ClimaSeaIce + snow", "ClimaSeaIceSnow", "#159a6b"),
]
VARS = [
    ("clwvi", "Liquid water path\n(kg m$^{-2}$)"),
    ("clivi", "Ice water path\n(kg m$^{-2}$)"),
    ("ts", "Surface temperature\n(K)"),
    ("rlds", "Downwelling LW at sfc\n(W m$^{-2}$)"),
]
C_ENS = "#9a988f"
C_EC = "#c0392b"
C_TEXT = "#0b0b0b"
C_TEXT2 = "#52514e"
SURFACE = "#fcfcfb"

plt.rcParams.update({
    "figure.facecolor": SURFACE, "axes.facecolor": SURFACE, "savefig.facecolor": SURFACE,
    "axes.edgecolor": "#c3c2b7", "axes.labelcolor": C_TEXT2, "axes.titlecolor": C_TEXT,
    "xtick.color": C_TEXT2, "ytick.color": C_TEXT2, "axes.grid": True,
    "grid.color": "#e6e5de", "grid.linewidth": 0.6, "axes.axisbelow": True,
    "axes.spines.top": False, "axes.spines.right": False,
    "font.family": "sans-serif", "font.size": 9, "legend.frameon": False,
})


def series(ds, v):
    da = ds[v]
    ex = [x for x in da.dims if x != "time" and ds.sizes[x] == 1]
    return np.asarray(da.squeeze(ex) if ex else da, dtype=float)


def days(ds):
    return np.arange(ds.sizes["time"], dtype=float) / 24.0


def lastliq(c, thr=1e-3):
    i = np.where(np.nan_to_num(c) > thr)[0]
    return int(i[-1]) if i.size else -1


# ---- load ensemble
ens = {}
for f in sorted(glob.glob(str(ENSEMBLE_DIR / "*.nc"))):
    ens[os.path.basename(f)[:-3]] = xr.open_dataset(f, decode_times=False)

# ---- load our runs
runs = {}
for _, base, _ in MODELS:
    for ver, suf in [("uncal", ""), ("cal", "_cal")]:
        p = CONV / f"{base}{suf}.nc"
        runs[(base, ver)] = xr.open_dataset(p, decode_times=False) if p.exists() else None

# ================================================================= figure
fig, axes = plt.subplots(len(VARS), len(MODELS), figsize=(11.5, 11),
                         constrained_layout=True, sharex=True)
for j, (mlabel, base, color) in enumerate(MODELS):
    for i, (var, vlabel) in enumerate(VARS):
        ax = axes[i, j]
        # ensemble context
        for name, ds in ens.items():
            if name == "EC-Earth" or var not in ds:
                continue
            ax.plot(days(ds), series(ds, var), color=C_ENS, lw=0.6, alpha=0.35, zorder=1)
        if "EC-Earth" in ens and var in ens["EC-Earth"]:
            ec = ens["EC-Earth"]
            ax.plot(days(ec), series(ec, var), color=C_EC, lw=1.3, alpha=0.9, zorder=2)
        # our runs: uncal dashed, cal solid
        du, dc = runs[(base, "uncal")], runs[(base, "cal")]
        if du is not None:
            ax.plot(days(du), series(du, var), color=color, lw=1.6, ls=(0, (4, 2)),
                    alpha=0.75, zorder=3)
        if dc is not None:
            ax.plot(days(dc), series(dc, var), color=color, lw=2.1, zorder=4)
        ax.set_xlim(0, 20)
        if i == 0:
            ax.set_title(mlabel, fontsize=10, loc="left", color=color)
        if j == 0:
            ax.set_ylabel(vlabel)
        if i == len(VARS) - 1:
            ax.set_xlabel("day")
    # shared y-limits per row for comparability
for i in range(len(VARS)):
    lo = min(ax.get_ylim()[0] for ax in axes[i, :])
    hi = max(ax.get_ylim()[1] for ax in axes[i, :])
    for ax in axes[i, :]:
        ax.set_ylim(lo, hi)

legend = [
    Line2D([], [], color="#444", lw=2.1, label="calibrated (uki_1)"),
    Line2D([], [], color="#444", lw=1.6, ls=(0, (4, 2)), label="uncalibrated (defaults)"),
    Line2D([], [], color=C_EC, lw=1.3, label="EC-Earth"),
    Line2D([], [], color=C_ENS, lw=1.0, alpha=0.6, label=f"Pithan ensemble (n={len(ens)-1})"),
]
axes[0, 0].legend(handles=legend, loc="upper right", fontsize=7.8)
fig.suptitle(
    "Larcform1 20-day coupled runs: calibrated vs uncalibrated microphysics, by sea-ice surface",
    color=C_TEXT, fontsize=12.5,
)
FIG_DIR.mkdir(exist_ok=True)
out = FIG_DIR / "calibration_comparison_timeseries.png"
fig.savefig(out, dpi=160)
plt.close(fig)
print("wrote", out)

# ================================================================= metrics
lines = []
hdr = (f"{'model':16s} {'ver':6s} {'lastliq_d':>9s} {'clwvi_d2':>9s} "
       f"{'clwvi_max':>9s} {'clivi_d5+':>9s} {'ts_end':>7s} {'ts_min':>7s} {'rlds':>6s}")
lines += [hdr, "-" * len(hdr)]
for mlabel, base, _ in MODELS:
    for ver in ("uncal", "cal"):
        ds = runs[(base, ver)]
        if ds is None:
            continue
        cw, ci, ts, rl = (series(ds, "clwvi"), series(ds, "clivi"),
                          series(ds, "ts"), series(ds, "rlds"))
        n = len(ts)
        lines.append(
            f"{base:16s} {ver:6s} {lastliq(cw)/24:9.2f} {np.nanmean(cw[24:49]):9.4f} "
            f"{np.nanmax(cw):9.4f} {np.nanmean(ci[120:n]):9.4f} "
            f"{ts[-1]:7.1f} {np.nanmin(ts):7.1f} {np.nanmean(rl):6.1f}")
    lines.append("")
txt = "\n".join(lines)
print(txt)
(FIG_DIR / "calibration_comparison_metrics.txt").write_text(txt + "\n")
print("wrote", FIG_DIR / "calibration_comparison_metrics.txt")
