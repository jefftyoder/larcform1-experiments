"""
Low-level stability T(850 hPa) - T(surface) following glaciation (days 0-10)
for the Larcform1 coupled sea-ice surfaces (calibrated vs uncalibrated), the
slab-ocean reference, and the Pithan 2016 ensemble.

Positive = 850 hPa warmer than surface = surface-based inversion (stable).

Outputs -> experiments/sea-ice/analysis/figures/
  stability_t850_minus_tsfc.png
  stability_metrics.txt
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

REPO = Path(__file__).resolve().parents[3]
ENS = REPO / "Pithan 2016 Intercomparison Data"
CONV = REPO / "experiments/sea-ice/analysis/converted"
SLAB = REPO / "experiments/20day run/output"
FIG = REPO / "experiments/sea-ice/analysis/figures"

SURF = [
    ("Slab ocean (SST~250K)", SLAB / "ClimaLarcform1.nc", SLAB / "ClimaLarcform1_WRONG_registered_CM.nc", "#9d64c4"),
    ("Slab ice (Holloway-Manabe)", CONV / "ClimaSlabIce_cal.nc", CONV / "ClimaSlabIce.nc", "#2a78d6"),
    ("ClimaSeaIce, bare", CONV / "ClimaSeaIceBare_cal.nc", CONV / "ClimaSeaIceBare.nc", "#e08a1e"),
    ("ClimaSeaIce + snow", CONV / "ClimaSeaIceSnow_cal.nc", CONV / "ClimaSeaIceSnow.nc", "#159a6b"),
]
C_ENS, C_EC = "#9a988f", "#c0392b"
SURFACE = "#fcfcfb"
plt.rcParams.update({
    "figure.facecolor": SURFACE, "axes.facecolor": SURFACE, "savefig.facecolor": SURFACE,
    "axes.edgecolor": "#c3c2b7", "axes.labelcolor": "#52514e", "axes.titlecolor": "#0b0b0b",
    "xtick.color": "#52514e", "ytick.color": "#52514e", "axes.grid": True,
    "grid.color": "#e6e5de", "grid.linewidth": 0.6, "axes.axisbelow": True,
    "axes.spines.top": False, "axes.spines.right": False,
    "font.family": "sans-serif", "font.size": 9, "legend.frameon": False,
})


def t_at(ds, plevel=850.0):
    """T interpolated to plevel (hPa) at every time; returns array over time."""
    pvar = "p" if "p" in ds else ("pf" if "pf" in ds else "ph")
    t = np.asarray(ds["t"])            # (time, lev)
    p = np.asarray(ds[pvar]) / 100.0   # hPa
    if t.ndim > 2:
        t = t.reshape(t.shape[0], -1)
    nt = t.shape[0]
    out = np.full(nt, np.nan)
    for k in range(nt):
        pk, tk = p[k], t[k]
        if pk.ndim > 1:
            pk = pk.squeeze()
        order = np.argsort(pk)
        out[k] = np.interp(plevel, pk[order], tk[order], left=np.nan, right=np.nan)
    return out


def ts_series(ds):
    ts = ds["ts"]
    ex = [d for d in ts.dims if d != "time" and ds.sizes[d] == 1]
    return np.asarray(ts.squeeze(ex) if ex else ts, dtype=float)


def clwvi_series(ds):
    c = ds["clwvi"]
    ex = [d for d in c.dims if d != "time" and ds.sizes[d] == 1]
    return np.asarray(c.squeeze(ex) if ex else c, dtype=float)


def glac_hour(ds):
    c = clwvi_series(ds)
    i = np.where(np.nan_to_num(c) > 1e-3)[0]
    return int(i[-1]) if i.size else -1


def stability(ds):
    return t_at(ds, 850.0) - ts_series(ds)


# ---- ensemble
ens = {os.path.basename(f)[:-3]: xr.open_dataset(f, decode_times=False)
       for f in sorted(glob.glob(str(ENS / "*.nc")))}

fig, axes = plt.subplots(1, 2, figsize=(13, 5.4), constrained_layout=True, sharey=True)

# ---------- panel A: calibrated surfaces vs ensemble
ax = axes[0]
for name, ds in ens.items():
    if name == "EC-Earth" or "t" not in ds:
        continue
    s = stability(ds)
    ax.plot(np.arange(len(s)) / 24, s, color=C_ENS, lw=0.7, alpha=0.35, zorder=1)
if "EC-Earth" in ens:
    s = stability(ens["EC-Earth"])
    ax.plot(np.arange(len(s)) / 24, s, color=C_EC, lw=1.4, zorder=2, label="EC-Earth")
for label, cal, _u, color in SURF:
    ds = xr.open_dataset(cal, decode_times=False)
    s = stability(ds)
    ax.plot(np.arange(len(s)) / 24, s, color=color, lw=2.0, zorder=3, label=label)
    gh = glac_hour(ds) / 24
    ax.axvline(gh, color=color, lw=0.8, ls=":", alpha=0.5)
ax.axhline(0, color="#888", lw=0.8)
ax.set_xlim(0, 10)
ax.set_xlabel("day")
ax.set_ylabel("T(850 hPa) - T(surface)  [K]   (+ = stable, surface inversion)")
ax.set_title("Calibrated surfaces vs Pithan ensemble", loc="left")
h, l = ax.get_legend_handles_labels()
h.append(Line2D([], [], color=C_ENS, lw=0.9, alpha=0.6)); l.append(f"ensemble (n={len(ens)-1})")
ax.legend(h, l, loc="upper left", fontsize=7.6)

# ---------- panel B: calibrated (solid) vs uncalibrated (dashed) per surface
ax = axes[1]
for label, cal, unc, color in SURF:
    dc = xr.open_dataset(cal, decode_times=False)
    sc = stability(dc)
    ax.plot(np.arange(len(sc)) / 24, sc, color=color, lw=2.0, zorder=3, label=label)
    if Path(unc).exists():
        du = xr.open_dataset(unc, decode_times=False)
        su = stability(du)
        ax.plot(np.arange(len(su)) / 24, su, color=color, lw=1.5, ls=(0, (4, 2)), alpha=0.75, zorder=2)
ax.axhline(0, color="#888", lw=0.8)
ax.set_xlim(0, 10)
ax.set_xlabel("day")
ax.set_title("Calibrated (solid) vs uncalibrated (dashed)", loc="left")
leg = [Line2D([], [], color="#444", lw=2.0, label="calibrated"),
       Line2D([], [], color="#444", lw=1.5, ls=(0, (4, 2)), label="uncalibrated")]
ax.legend(handles=leg, loc="upper left", fontsize=7.8)

fig.suptitle("Low-level stability following glaciation: T(850 hPa) - T(surface), Larcform1 20-day runs",
             fontsize=12.5)
FIG.mkdir(exist_ok=True)
out = FIG / "stability_t850_minus_tsfc.png"
fig.savefig(out, dpi=160)
plt.close(fig)
print("wrote", out)

# ---------- metrics: mean stability over post-glaciation window and days 3-10
lines = [f"{'run':30s} {'glac_d':>6s} {'stab_glac':>9s} {'stab_d3-10':>10s} {'stab_d10':>8s}",
         "-" * 68]
def row(label, ds):
    s = stability(ds); gh = glac_hour(ds)
    n = len(s)
    post = np.nanmean(s[gh:min(240, n)]) if 0 <= gh < n else np.nan
    d310 = np.nanmean(s[72:min(240, n)])
    d10 = s[min(240, n) - 1]
    return f"{label:30s} {gh/24:6.2f} {s[gh] if 0<=gh<n else np.nan:9.2f} {d310:10.2f} {d10:8.2f}", post
for label, cal, unc, _ in SURF:
    for tag, p in [("CAL", cal), ("UNCAL", unc)]:
        if Path(p).exists():
            r, _ = row(f"{label} [{tag}]", xr.open_dataset(p, decode_times=False))
            lines.append(r)
    lines.append("")
r, _ = row("EC-Earth", ens["EC-Earth"]); lines.append(r)
txt = "\n".join(lines)
print(txt)
(FIG / "stability_metrics.txt").write_text(txt + "\n")
print("wrote", FIG / "stability_metrics.txt")
