"""
Low-level stability in POTENTIAL temperature: theta(850 hPa) - theta(surface),
days 0-10, Larcform1 coupled sea-ice surfaces (calibrated vs uncalibrated),
slab-ocean reference, and Pithan 2016 ensemble.

theta = T (1000/p)^(R/cp), R/cp = 0.2857.  Surface theta uses skin temp ts and
surface pressure (ps if present, else lowest model level p).

Positive = 850 hPa potential temp warmer than surface = statically stable
(surface-based inversion beyond the dry-adiabatic reference).

Outputs -> experiments/sea-ice/analysis/figures/
  stability_theta850_minus_thetasfc.png
  stability_theta_metrics.txt
"""
import glob, os
from pathlib import Path
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import xarray as xr
from matplotlib.lines import Line2D

from pathlib import Path as _P
REPO = _P(__file__).resolve().parents[3]
ENS  = REPO / "Pithan 2016 Intercomparison Data"
CONV = REPO / "experiments/sea-ice/analysis/converted"
SLAB = REPO / "experiments/20day run/output"
FIG  = REPO / "experiments/sea-ice/analysis/figures"
KAPPA = 0.2857  # R/cp for dry air

SURF = [
    ("Slab ocean (SST~250K)", SLAB/"ClimaLarcform1.nc", SLAB/"ClimaLarcform1_WRONG_registered_CM.nc", "#9d64c4"),
    ("Slab ice (Holloway-Manabe)", CONV/"ClimaSlabIce_cal.nc", CONV/"ClimaSlabIce.nc", "#2a78d6"),
    ("ClimaSeaIce, bare", CONV/"ClimaSeaIceBare_cal.nc", CONV/"ClimaSeaIceBare.nc", "#e08a1e"),
    ("ClimaSeaIce + snow", CONV/"ClimaSeaIceSnow_cal.nc", CONV/"ClimaSeaIceSnow.nc", "#159a6b"),
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

def _pvar(ds):
    return "p" if "p" in ds else ("pf" if "pf" in ds else "ph")

def t_at(ds, plevel=850.0):
    pvar = _pvar(ds)
    t = np.asarray(ds["t"]); p = np.asarray(ds[pvar]) / 100.0
    if t.ndim > 2: t = t.reshape(t.shape[0], -1)
    if p.ndim > 2: p = p.reshape(p.shape[0], -1)
    nt = t.shape[0]; out = np.full(nt, np.nan)
    for k in range(nt):
        pk, tk = np.squeeze(p[k]), np.squeeze(t[k])
        o = np.argsort(pk)
        out[k] = np.interp(plevel, pk[o], tk[o], left=np.nan, right=np.nan)
    return out

def theta_at(ds, plevel=850.0):
    return t_at(ds, plevel) * (1000.0 / plevel) ** KAPPA

def ts_series(ds):
    ts = ds["ts"]; ex=[d for d in ts.dims if d!="time" and ds.sizes[d]==1]
    return np.asarray(ts.squeeze(ex) if ex else ts, dtype=float)

def psurf_series(ds):
    """surface pressure (hPa) per time: ps var if present, else max model-level p."""
    if "ps" in ds:
        v = ds["ps"]; ex=[d for d in v.dims if d!="time" and ds.sizes[d]==1]
        ps = np.asarray(v.squeeze(ex) if ex else v, dtype=float) / 100.0
        ps[ps <= 0] = np.nan
        return ps
    p = np.asarray(ds[_pvar(ds)]) / 100.0
    if p.ndim > 2: p = p.reshape(p.shape[0], -1)
    ps = np.nanmax(p.reshape(p.shape[0], -1), axis=1)
    ps[ps <= 0] = np.nan
    return ps

def theta_sfc(ds):
    return ts_series(ds) * (1000.0 / psurf_series(ds)) ** KAPPA

def clwvi_series(ds):
    c = ds["clwvi"]; ex=[d for d in c.dims if d!="time" and ds.sizes[d]==1]
    return np.asarray(c.squeeze(ex) if ex else c, dtype=float)

def glac_hour(ds):
    i = np.where(np.nan_to_num(clwvi_series(ds)) > 1e-3)[0]
    return int(i[-1]) if i.size else -1

def stab_theta(ds):
    return theta_at(ds, 850.0) - theta_sfc(ds)

ens = {os.path.basename(f)[:-3]: xr.open_dataset(f, decode_times=False)
       for f in sorted(glob.glob(str(ENS/"*.nc")))}

fig, axes = plt.subplots(1, 2, figsize=(13, 5.4), constrained_layout=True, sharey=True)
ax = axes[0]
for name, ds in ens.items():
    if name == "EC-Earth" or "t" not in ds: continue
    s = stab_theta(ds); ax.plot(np.arange(len(s))/24, s, color=C_ENS, lw=0.7, alpha=0.35, zorder=1)
if "EC-Earth" in ens:
    s = stab_theta(ens["EC-Earth"]); ax.plot(np.arange(len(s))/24, s, color=C_EC, lw=1.4, zorder=2, label="EC-Earth")
for label, cal, _u, color in SURF:
    ds = xr.open_dataset(cal, decode_times=False); s = stab_theta(ds)
    ax.plot(np.arange(len(s))/24, s, color=color, lw=2.0, zorder=3, label=label)
    ax.axvline(glac_hour(ds)/24, color=color, lw=0.8, ls=":", alpha=0.5)
ax.axhline(0, color="#888", lw=0.8)
ax.set_xlim(0,10); ax.set_xlabel("day")
ax.set_ylabel(r"$\theta$(850 hPa) - $\theta$(surface)  [K]   (+ = statically stable)")
ax.set_title("Calibrated surfaces vs Pithan ensemble", loc="left")
h,l = ax.get_legend_handles_labels()
h.append(Line2D([],[],color=C_ENS,lw=0.9,alpha=0.6)); l.append(f"ensemble (n={len(ens)-1})")
ax.legend(h,l, loc="upper left", fontsize=7.6)

ax = axes[1]
for label, cal, unc, color in SURF:
    dc = xr.open_dataset(cal, decode_times=False); sc = stab_theta(dc)
    ax.plot(np.arange(len(sc))/24, sc, color=color, lw=2.0, zorder=3, label=label)
    if Path(unc).exists():
        du = xr.open_dataset(unc, decode_times=False); su = stab_theta(du)
        ax.plot(np.arange(len(su))/24, su, color=color, lw=1.5, ls=(0,(4,2)), alpha=0.75, zorder=2)
ax.axhline(0, color="#888", lw=0.8)
ax.set_xlim(0,10); ax.set_xlabel("day")
ax.set_title("Calibrated (solid) vs uncalibrated (dashed)", loc="left")
ax.legend(handles=[Line2D([],[],color="#444",lw=2.0,label="calibrated"),
                   Line2D([],[],color="#444",lw=1.5,ls=(0,(4,2)),label="uncalibrated")],
          loc="upper left", fontsize=7.8)
fig.suptitle(r"Low-level static stability following glaciation: $\theta$(850 hPa) - $\theta$(surface), Larcform1 20-day runs", fontsize=12.5)
FIG.mkdir(exist_ok=True)
out = FIG/"stability_theta850_minus_thetasfc.png"
fig.savefig(out, dpi=160); plt.close(fig); print("wrote", out)

lines = [f"{'run':30s} {'glac_d':>6s} {'dtheta_glac':>11s} {'dtheta_d3-10':>12s} {'dtheta_d10':>10s}",
         "-"*74]
def row(label, ds):
    s = stab_theta(ds); gh = glac_hour(ds); n = len(s)
    g  = s[gh] if 0<=gh<n else np.nan
    d310 = np.nanmean(s[72:min(240,n)])
    d10  = s[min(240,n)-1]
    return f"{label:30s} {gh/24:6.2f} {g:11.2f} {d310:12.2f} {d10:10.2f}"
for label, cal, unc, _ in SURF:
    for tag,p in [("CAL",cal),("UNCAL",unc)]:
        if Path(p).exists():
            lines.append(row(f"{label} [{tag}]", xr.open_dataset(p, decode_times=False)))
    lines.append("")
lines.append(row("EC-Earth", ens["EC-Earth"]))
txt = "\n".join(lines); print(txt)
(FIG/"stability_theta_metrics.txt").write_text(txt+"\n")
print("wrote", FIG/"stability_theta_metrics.txt")
