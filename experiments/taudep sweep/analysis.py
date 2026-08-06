"""Transition diagrams for the tau_dep sweep (lf1e-taudep-1).

Reads output/lf1e-taudep-1/manifest.toml (+ member NetCDF for time series) and
produces two AGU/JAMES-ready figures in experiments/taudep sweep/figures/:

  fig1_taudep_transition: order parameters vs log10 tau (4 panels)
  fig2_taudep_lwp_traces: lwp(t) traces colored by log10 tau

Run from repo root:  python3 "experiments/taudep sweep/analysis.py"
"""

import tomllib
from pathlib import Path

import xarray as xr
import matplotlib.pyplot as plt
from matplotlib import colormaps
from matplotlib.colors import Normalize

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "output" / "lf1e-taudep-1"
OUTDIR = Path(__file__).resolve().parent / "figures"
OUTDIR.mkdir(exist_ok=True)

# Validated categorical palette (project dataviz tokens) + stage markers.
BLUE, ORANGE, GRAY, INK = "#2a78d6", "#eb6834", "#898781", "#0b0b0b"
STAGES = {  # stage -> (color, marker, zorder)
    "anchor": (INK, "D", 5),
    "coarse": (BLUE, "o", 4),
    "adaptive": (ORANGE, "^", 3),
    "dense": (GRAY, "s", 3),
}
CLW_THRESHOLD = 1e-4

plt.rcParams.update({
    "font.family": "sans-serif",
    "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
    "font.size": 8,
    "axes.linewidth": 0.6,
})

with open(DATA / "manifest.toml", "rb") as f:
    manifest = tomllib.load(f)

members = [
    (e["log10_tau"], e["stage"], e["metrics"], jid)
    for jid, e in manifest.items()
    if e.get("ret_code") == "success"
    and "metrics" in e
    and e.get("stage") in STAGES
]
members.sort()
n_hours = members[0][2]["n_hours"]

# ---------------------------------------------------------------- figure 1 --
fig, axes = plt.subplots(2, 2, figsize=(6.69, 4.6), sharex=True)

panels = [
    ("cloud_hours", f"cloud lifetime (h of {n_hours})", None),
    ("max_clw", "max clw (kg kg$^{-1}$)", None),
    ("lwp_int", "time-integrated LWP (kg m$^{-2}$ day)", "symlog"),
    ("clivi_end", "final column ice (kg m$^{-2}$)", "log"),
]
for i, (ax, (key, ylabel, yscale)) in enumerate(zip(axes.flat, panels)):
    for stage, (color, marker, z) in STAGES.items():
        xs = [x for x, s, _, _ in members if s == stage]
        ys = [m[key] for _, s, m, _ in members if s == stage]
        ax.scatter(xs, ys, s=14, c=color, marker=marker, zorder=z,
                   linewidths=0, label=stage)
    if key == "max_clw":
        ax.axhline(CLW_THRESHOLD, color=GRAY, lw=0.8, ls=(0, (4, 2)), zorder=1)
        ax.annotate("0.1 g kg$^{-1}$ threshold", xy=(6.6, 1.2e-4),
                    fontsize=6.5, color=GRAY)
    if yscale == "symlog":
        ax.set_yscale("symlog", linthresh=1e-4)
    elif yscale:
        ax.set_yscale(yscale)
    ax.set_ylabel(ylabel)
    ax.text(0.02, 0.97, f"({chr(97 + i)})", transform=ax.transAxes,
            fontsize=8, fontweight="bold", va="top")
    ax.spines[["top", "right"]].set_visible(False)
for ax in axes[1]:
    ax.set_xlabel(r"log$_{10}$($\tau_{\mathrm{dep}}$ / s)")
    ax.set_xticks(range(1, 10))
axes[0, 0].legend(frameon=False, fontsize=7, loc="center left",
                  handletextpad=0.2, borderaxespad=0.3)

fig.tight_layout()
for ext in ("png", "pdf"):
    fig.savefig(OUTDIR / f"fig1_taudep_transition.{ext}",
                dpi=300 if ext == "png" else None, bbox_inches="tight",
                facecolor="white")
plt.close(fig)

# ---------------------------------------------------------------- figure 2 --
fig, ax = plt.subplots(figsize=(6.69, 3.4))
cmap = colormaps["viridis"]
xmin, xmax = members[0][0], members[-1][0]
for x, stage, m, jid in members:
    nc = DATA / jid / "output_active" / "lwp_1h_average.nc"
    if not nc.exists():
        continue
    ds = xr.load_dataset(nc, decode_times=False).squeeze()
    t = ds["time"].values / 86400.0
    ax.plot(t, ds["lwp"].values, lw=0.9,
            color=cmap((x - xmin) / (xmax - xmin)), zorder=2)
sm = plt.cm.ScalarMappable(cmap=cmap, norm=Normalize(vmin=xmin, vmax=xmax))
cb = fig.colorbar(sm, ax=ax, pad=0.01)
cb.set_label(r"log$_{10}$($\tau_{\mathrm{dep}}$ / s)", fontsize=8)
cb.ax.tick_params(labelsize=7)
ax.set_xlabel("time (days)")
ax.set_ylabel("liquid water path (kg m$^{-2}$)")
ax.set_xlim(0, 5)
ax.spines[["top", "right"]].set_visible(False)

fig.tight_layout()
for ext in ("png", "pdf"):
    fig.savefig(OUTDIR / f"fig2_taudep_lwp_traces.{ext}",
                dpi=300 if ext == "png" else None, bbox_inches="tight",
                facecolor="white")
print(f"saved figures to {OUTDIR}")
