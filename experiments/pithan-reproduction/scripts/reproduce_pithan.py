"""
Reproduce the Pithan et al. (2016) Larcform1 analyses with our ClimaAtmos/ClimaCoupler
runs included (4 surfaces x calibrated/uncalibrated microphysics).

Paper figures reproduced (days 1-10 unless noted):
  fig4_netlw_pdf.png      - PDF of hourly surface net LW (5 W/m2 bins, positive down)
  fig5_6_profiles.png     - T profiles, 1h average at day 2 and day 10
  fig1_bivariate.png      - bivariate PDF: low-level stability (T850-Tsfc) vs net LW
  table5_metrics.txt      - hs(clear), clwvi(cloudy), 10-day net sfc energy loss
                            (clear/cloudy partition at net LW = -20 W/m2)

Data (not copied; referenced in place):
  experiments/sea-ice/analysis/converted/*.nc   (coupled sea-ice runs, Pithan format)
  experiments/20day run/output/*.nc             (slab-ocean runs)
  Pithan 2016 Intercomparison Data/*.nc         (published ensemble)
"""
import glob, os
from pathlib import Path
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import xarray as xr
from matplotlib.lines import Line2D

REPO = Path(__file__).resolve().parents[3]
ENS  = REPO / "Pithan 2016 Intercomparison Data"
CONV = REPO / "experiments/sea-ice/analysis/converted"
SLAB = REPO / "experiments/20day run/output"
FIG  = REPO / "experiments/pithan-reproduction/figures"
D1, D10 = 24, 240          # hourly indices, days 1-10 window
CLEAR_THR = -20.0          # W/m2, Pithan's clear/cloudy partition

RUNS = [  # (label, calibrated file, uncalibrated file, color)
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

def series(ds, v):
    da = ds[v]; ex = [d for d in da.dims if d != "time" and ds.sizes[d] == 1]
    return np.asarray(da.squeeze(ex) if ex else da, dtype=float)

def netlw(ds):
    return series(ds, "rlds") + series(ds, "rlus")   # both Pithan positive-down

def _pvar(ds):
    return "p" if "p" in ds else ("pf" if "pf" in ds else "ph")

def t850(ds):
    pv = _pvar(ds)
    t = np.asarray(ds["t"]); p = np.asarray(ds[pv]) / 100.0
    if t.ndim > 2: t = t.reshape(t.shape[0], -1)
    if p.ndim > 2: p = p.reshape(p.shape[0], -1)
    out = np.full(t.shape[0], np.nan)
    for k in range(t.shape[0]):
        pk, tk = np.squeeze(p[k]), np.squeeze(t[k])
        o = np.argsort(pk)
        out[k] = np.interp(850.0, pk[o], tk[o], left=np.nan, right=np.nan)
    return out

def stability(ds):
    return t850(ds) - series(ds, "ts")

def profile_at(ds, hour):
    pv = _pvar(ds)
    t = np.asarray(ds["t"]); p = np.asarray(ds[pv]) / 100.0
    if t.ndim > 2: t = t.reshape(t.shape[0], -1)
    if p.ndim > 2: p = p.reshape(p.shape[0], -1)
    k = min(hour, t.shape[0]-1)
    return np.squeeze(t[k]), np.squeeze(p[k])

ens = {os.path.basename(f)[:-3]: xr.open_dataset(f, decode_times=False)
       for f in sorted(glob.glob(str(ENS/"*.nc")))}
ours = []   # (label, tag, ds, color)
for label, cal, unc, color in RUNS:
    for tag, p in [("CAL", cal), ("UNCAL", unc)]:
        if Path(p).exists():
            ours.append((label, tag, xr.open_dataset(p, decode_times=False), color))
FIG.mkdir(exist_ok=True)

# ============================================================ Fig 4: net-LW PDF
BINS = np.arange(-80, 10.1, 5.0)          # Pithan bin centers -77.5 .. +7.5
CENT = 0.5 * (BINS[:-1] + BINS[1:])
def lwpdf(ds):
    h, _ = np.histogram(np.clip(netlw(ds)[D1:D10], BINS[0], BINS[-1]-1e-6), bins=BINS)
    return h / h.sum()

fig, axes = plt.subplots(1, 2, figsize=(12.5, 4.6), constrained_layout=True, sharey=True)
for ax, want in zip(axes, ["CAL", "UNCAL"]):
    for name, ds in ens.items():
        if "rlus" not in ds: continue
        ax.plot(CENT, lwpdf(ds), color=(C_EC if name == "EC-Earth" else C_ENS),
                lw=(1.4 if name == "EC-Earth" else 0.7),
                alpha=(0.9 if name == "EC-Earth" else 0.35),
                zorder=(2 if name == "EC-Earth" else 1))
    for label, tag, ds, color in ours:
        if tag != want: continue
        ax.plot(CENT, lwpdf(ds), color=color, lw=2.0, zorder=3, label=label)
    ax.axvline(CLEAR_THR, color="#888", lw=0.8, ls=":")
    ax.set_xlabel(r"surface net LW radiation (W m$^{-2}$)")
    ax.set_title(f"{'Calibrated' if want=='CAL' else 'Uncalibrated'} microphysics", loc="left")
axes[0].set_ylabel("PDF (fraction per 5 W m$^{-2}$ bin)")
h, l = axes[0].get_legend_handles_labels()
h += [Line2D([], [], color=C_EC, lw=1.4), Line2D([], [], color=C_ENS, lw=0.9, alpha=0.6)]
l += ["EC-Earth", "Pithan ensemble"]
axes[0].legend(h, l, fontsize=7.6, loc="upper left")
fig.suptitle("Pithan16 Fig. 4: PDF of hourly surface net LW, days 1-10 "
             f"(dotted line: clear/cloudy partition {CLEAR_THR:.0f} W m$^{{-2}}$)", fontsize=12)
fig.savefig(FIG/"fig4_netlw_pdf.png", dpi=160); plt.close(fig)
print("wrote", FIG/"fig4_netlw_pdf.png")

# ==================================================== Fig 5/6: T profiles d2, d10
fig, axes = plt.subplots(2, 2, figsize=(12.5, 10), constrained_layout=True, sharey="row")
for i, (day, hour, xlim) in enumerate([(2, 48, (248, 272)), (10, 240, (218, 257))]):
    for j, want in enumerate(["CAL", "UNCAL"]):
        ax = axes[i, j]
        for name, ds in ens.items():
            if "t" not in ds: continue
            t, p = profile_at(ds, hour)
            ax.plot(t, p, color=(C_EC if name == "EC-Earth" else C_ENS),
                    lw=(1.4 if name == "EC-Earth" else 0.7),
                    alpha=(0.9 if name == "EC-Earth" else 0.35),
                    zorder=(2 if name == "EC-Earth" else 1))
        for label, tag, ds, color in ours:
            if tag != want: continue
            t, p = profile_at(ds, hour)
            ax.plot(t, p, color=color, lw=2.0, zorder=3, label=label)
            ax.plot(series(ds, "ts")[hour], np.nanmax(p), marker="o", ms=4,
                    color=color, zorder=4)   # skin temperature
        ax.set_ylim(1013, 500 if day == 10 else 790)
        ax.set_xlim(*xlim)
        ax.set_title(f"day {day} - {'calibrated' if want=='CAL' else 'uncalibrated'}", loc="left")
        if j == 0: ax.set_ylabel("pressure (hPa)")
        ax.set_xlabel("temperature (K)")
axes[0, 0].legend(fontsize=7.6, loc="upper left")
fig.suptitle("Pithan16 Figs. 5-6: temperature profiles (1 h average) after 2 and 10 days\n"
             "(dots: skin temperature; gray: ensemble; red: EC-Earth)", fontsize=12)
fig.savefig(FIG/"fig5_6_profiles.png", dpi=160); plt.close(fig)
print("wrote", FIG/"fig5_6_profiles.png")

# ================================================= Fig 1/3-style: bivariate PDF
SB = np.arange(-20, 40.1, 4.0); LB = np.arange(-90, 30.1, 8.0)
panels = [(f"{lab} [{tag}]", ds) for lab, tag, ds, _ in ours] + [("EC-Earth", ens["EC-Earth"])]
ncol = 3; nrow = int(np.ceil(len(panels)/ncol))
fig, axes = plt.subplots(nrow, ncol, figsize=(11.5, 3.6*nrow), constrained_layout=True,
                         sharex=True, sharey=True)
for ax, (title, ds) in zip(axes.flat, panels):
    s, n = stability(ds)[D1:D10], netlw(ds)[D1:D10]
    m = np.isfinite(s) & np.isfinite(n)
    hh, xe, ye = np.histogram2d(s[m], n[m], bins=[SB, LB], density=False)
    hh = hh / hh.sum()
    pc = ax.pcolormesh(xe, ye, hh.T, cmap="YlOrRd", vmin=0, vmax=0.25)
    ax.plot(s[m], n[m], ".", ms=1.5, color="#00000030")
    ax.axhline(CLEAR_THR, color="#888", lw=0.7, ls=":")
    ax.axhline(0, color="#888", lw=0.7); ax.axvline(0, color="#888", lw=0.7)
    ax.set_title(title, loc="left", fontsize=9)
for ax in axes.flat[len(panels):]: ax.set_visible(False)
for ax in axes[-1, :]: ax.set_xlabel("low-level stability T(850)-T(sfc) (K)")
for ax in axes[:, 0]: ax.set_ylabel(r"surface net LW (W m$^{-2}$)")
fig.colorbar(pc, ax=axes, shrink=0.6, label="fraction of hours (days 1-10)")
fig.suptitle("Pithan16 Figs. 1/3-style: bivariate PDF of low-level stability vs surface net LW, days 1-10",
             fontsize=12)
fig.savefig(FIG/"fig1_bivariate.png", dpi=160); plt.close(fig)
print("wrote", FIG/"fig1_bivariate.png")

# ======================================================== Table 5 reproduction
lines = [f"{'run':38s} {'hs_clear':>8s} {'clwvi_cloudy':>12s} {'E_loss_MJm2':>11s} {'f_clear':>7s}",
         "-"*80,
         f"(clear/cloudy partition: net LW < {CLEAR_THR:.0f} W/m2; window days 1-10; fluxes +down)", ""]
def t5row(label, ds):
    n   = netlw(ds)[D1:D10]
    hs  = series(ds, "hs")[D1:D10] if "hs" in ds else np.full_like(n, np.nan)
    hl  = series(ds, "hl")[D1:D10] if "hl" in ds else np.zeros_like(n)
    cw  = series(ds, "clwvi")[D1:D10] if "clwvi" in ds else np.full_like(n, np.nan)
    clear = n < CLEAR_THR
    hs_clear = np.nanmean(hs[clear]) if clear.any() else np.nan
    cw_cloudy = np.nanmean(cw[~clear]) if (~clear).any() else np.nan
    eloss = -np.nansum(n + hs + hl) * 3600 / 1e6      # MJ/m2 lost over days 1-10
    return (f"{label:38s} {hs_clear:8.2f} {cw_cloudy:12.3f} {eloss:11.1f} "
            f"{clear.mean():7.2f}")
for label, tag, ds, _ in ours:
    lines.append(t5row(f"{label} [{tag}]", ds))
lines.append("")
for name in sorted(ens):
    ds = ens[name]
    if "rlus" in ds and "hs" in ds:
        lines.append(t5row(name, ds))
txt = "\n".join(lines); print(txt)
(FIG/"table5_metrics.txt").write_text(txt+"\n")
print("wrote", FIG/"table5_metrics.txt")
