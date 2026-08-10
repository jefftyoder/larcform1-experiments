"""2D transition diagrams for the tau_dep x tau_ce sweep (lf1e-taudep-1, subexp C).

Reads output/lf1e-taudep-1-coupled-2d/manifest.toml and produces AGU/JAMES-ready
figures in experiments/taudep sweep coupled 2d/figures/, plus CAPTIONS.md with
manuscript-ready captions and provenance.

  fig1_2d_regime_map:     cloud metrics as heatmaps (4 panels)
  fig2_2d_transition:     gradient magnitude + 1D slices (2 panels)
  fig3_2d_surface:        surface temperature and radiative response (2 panels)

Run from repo root:  python3 "experiments/taudep sweep coupled 2d/analysis.py"
"""

import datetime
import subprocess
import tomllib
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "output" / "lf1e-taudep-1-coupled-2d"
OUTDIR = Path(__file__).resolve().parent / "figures"
OUTDIR.mkdir(exist_ok=True)

BLUE, ORANGE, GRAY, INK = "#2a78d6", "#eb6834", "#898781", "#0b0b0b"

plt.rcParams.update({
    "font.family": "sans-serif",
    "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
    "font.size": 8,
    "axes.linewidth": 0.6,
})

# ------------------------------------------------------------------ data --
with open(DATA / "manifest.toml", "rb") as f:
    manifest = tomllib.load(f)

all_members = [
    (e["log10_tau_dep"], e["log10_tau_ce"], e["metrics"], jid, e.get("stage", "?"))
    for jid, e in manifest.items()
    if e.get("ret_code") == "success" and "metrics" in e
]

# Separate the anchor (off-grid validation point) from the regular grid.
# The anchor sits at non-integer log10 values (e.g. 1.82, 2.005) and creates
# near-zero-width cells in pcolormesh if included in the grid axes.
grid_members = [(d, c, m, j) for d, c, m, j, s in all_members if s != "anchor"]
anchor_members = [(d, c, m, j) for d, c, m, j, s in all_members if s == "anchor"]
members = grid_members

log10_dep_vals = sorted(set(m[0] for m in members))
log10_ce_vals = sorted(set(m[1] for m in members))
n_dep = len(log10_dep_vals)
n_ce = len(log10_ce_vals)
dep_idx = {v: i for i, v in enumerate(log10_dep_vals)}
ce_idx = {v: i for i, v in enumerate(log10_ce_vals)}

print(f"Loaded {len(members)} grid members on a {n_dep}x{n_ce} grid"
      f" + {len(anchor_members)} anchor(s)")


def build_grid(metric_key, unit=1.0):
    Z = np.full((n_dep, n_ce), np.nan)
    for xd, xc, m, _ in members:
        Z[dep_idx[xd], ce_idx[xc]] = m[metric_key] * unit
    return Z


def pcolormesh_edges(vals):
    """Cell edges for pcolormesh from cell centers."""
    vals = np.asarray(vals, dtype=float)
    dx = np.diff(vals)
    edges = np.empty(len(vals) + 1)
    edges[1:-1] = vals[:-1] + dx / 2
    edges[0] = vals[0] - dx[0] / 2
    edges[-1] = vals[-1] + dx[-1] / 2
    return edges


dep_edges = pcolormesh_edges(log10_dep_vals)
ce_edges = pcolormesh_edges(log10_ce_vals)
dep_grid, ce_grid = np.meshgrid(log10_dep_vals, log10_ce_vals, indexing="ij")

DEP_LABEL = r"log$_{10}$($\tau_{\mathrm{dep}}$ / s)"
CE_LABEL = r"log$_{10}$($\tau_{\mathrm{ce}}$ / s)"

# -------------------------------------------------------------- figure 1 --
cloud_hours = build_grid("cloud_hours")
max_clw = build_grid("max_clw", 1e3)            # g/kg
lwp_int = build_grid("lwp_int", 1e3)            # g/m2 day
clivi_end = build_grid("clivi_end", 1e3)         # g/m2

fig, axes = plt.subplots(2, 2, figsize=(6.69, 6.0))

panels = [
    (cloud_hours, f"cloud lifetime (h of {int(members[0][2]['n_hours'])})",
     "viridis", None, None),
    (max_clw, "max clw (g kg$^{-1}$)", "viridis", None, None),
    (lwp_int, "time-integrated LWP (g m$^{-2}$ day)", "plasma", None, None),
    (clivi_end, "final column ice (g m$^{-2}$)", "inferno", None, None),
]

for i, (ax, (Z, label, cmap, vmin, vmax)) in enumerate(zip(axes.flat, panels)):
    im = ax.pcolormesh(dep_edges, ce_edges, Z.T, cmap=cmap,
                       shading="flat", vmin=vmin, vmax=vmax)
    ax.scatter(dep_grid.ravel(), ce_grid.ravel(), s=4, c=INK, zorder=5)
    for ad, ac, _, _ in anchor_members:
        ax.scatter(ad, ac, s=30, marker="*", c=INK, zorder=6)
    cb = fig.colorbar(im, ax=ax, orientation="horizontal", pad=0.15,
                      shrink=0.9)
    cb.set_label(label, fontsize=7)
    cb.ax.tick_params(labelsize=6)
    if i >= 2:
        ax.set_xlabel(DEP_LABEL)
    if i % 2 == 0:
        ax.set_ylabel(CE_LABEL)
    ax.set_xticks(range(1, 8))
    ax.set_yticks(range(1, 8))
    ax.text(0.02, 0.97, f"({chr(97 + i)})", transform=ax.transAxes,
            fontsize=8, fontweight="bold", va="top", color="white")
    ax.spines[["top", "right"]].set_visible(False)

fig.tight_layout()
for ext in ("png", "pdf"):
    fig.savefig(OUTDIR / f"fig1_2d_regime_map.{ext}",
                dpi=300 if ext == "png" else None, bbox_inches="tight",
                facecolor="white")
plt.close(fig)

# -------------------------------------------------------------- figure 2 --
fig, axes = plt.subplots(1, 2, figsize=(6.69, 3.4))

# (a) Cloud hours heatmap with contour overlay marking the transition.
ax = axes[0]
n_hours = int(members[0][2]["n_hours"])
im = ax.pcolormesh(dep_edges, ce_edges, cloud_hours.T, cmap="viridis",
                   shading="flat")
ax.scatter(dep_grid.ravel(), ce_grid.ravel(), s=4, c=INK, zorder=5)
for ad, ac, _, _ in anchor_members:
    ax.scatter(ad, ac, s=30, marker="*", c=INK, zorder=6)
levels = [0.1 * n_hours, 0.25 * n_hours, 0.5 * n_hours,
          0.75 * n_hours, 0.9 * n_hours]
lws = [0.6, 0.8, 1.2, 0.8, 0.6]
if n_dep >= 3 and n_ce >= 3:
    cs = ax.contour(log10_dep_vals, log10_ce_vals, cloud_hours.T,
                    levels=levels, colors="white", linewidths=lws)
    ax.clabel(cs, [0.5 * n_hours], fmt=f"{int(0.5 * n_hours)}h",
              fontsize=6, inline=True, colors="white")
cb = fig.colorbar(im, ax=ax, pad=0.02)
cb.set_label(f"cloud lifetime (h of {n_hours})", fontsize=7)
cb.ax.tick_params(labelsize=6)
ax.set_xlabel(DEP_LABEL)
ax.set_ylabel(CE_LABEL)
ax.set_xticks(range(1, 8))
ax.set_yticks(range(1, 8))
ax.text(0.02, 0.97, "(a)", transform=ax.transAxes,
        fontsize=8, fontweight="bold", va="top", color="white")
ax.spines[["top", "right"]].set_visible(False)

# (b) 1D slices at fixed tau_ce, compared with subexperiment A.
ax = axes[1]
slice_ces = [1.0, 4.0, 7.0]
slice_colors = [BLUE, ORANGE, GRAY]
slice_markers = ["o", "^", "s"]
for ce_val, color, marker in zip(slice_ces, slice_colors, slice_markers):
    if ce_val not in ce_idx:
        continue
    j = ce_idx[ce_val]
    ys = cloud_hours[:, j]
    ax.plot(log10_dep_vals, ys, color=color, marker=marker, ms=4,
            lw=0.8, label=f"$\\tau_{{ce}}$ = 10$^{{{int(ce_val)}}}$ s",
            markeredgewidth=0)

# Overlay subexperiment A if manifest exists.
manifest_a = ROOT / "output" / "lf1e-taudep-1" / "manifest.toml"
if manifest_a.exists():
    with open(manifest_a, "rb") as f:
        man_a = tomllib.load(f)
    pts_a = sorted(
        (e["log10_tau"], e["metrics"]["cloud_hours"])
        for e in man_a.values()
        if e.get("ret_code") == "success" and "metrics" in e
        and e.get("stage") in ("anchor", "coarse", "adaptive", "dense")
    )
    if pts_a:
        ax.plot([p[0] for p in pts_a], [p[1] for p in pts_a],
                color=INK, ls="--", lw=0.8, label="subexp A (1D, stock)")

ax.set_xlabel(DEP_LABEL)
ax.set_ylabel(f"cloud lifetime (h of {n_hours})")
ax.set_xticks(range(1, 8))
ax.legend(frameon=False, fontsize=6.5, loc="best")
ax.text(0.02, 0.97, "(b)", transform=ax.transAxes,
        fontsize=8, fontweight="bold", va="top")
ax.spines[["top", "right"]].set_visible(False)

fig.tight_layout()
for ext in ("png", "pdf"):
    fig.savefig(OUTDIR / f"fig2_2d_transition.{ext}",
                dpi=300 if ext == "png" else None, bbox_inches="tight",
                facecolor="white")
plt.close(fig)

# -------------------------------------------------------------- figure 3 --
ts_end = build_grid("ts_end")
rlds_mean = build_grid("rlds_mean")

fig, axes = plt.subplots(1, 2, figsize=(6.69, 3.4))

# (a) ts_end heatmap.
ax = axes[0]
im = ax.pcolormesh(dep_edges, ce_edges, ts_end.T, cmap="plasma",
                   shading="flat")
ax.scatter(dep_grid.ravel(), ce_grid.ravel(), s=4, c=INK, zorder=5)
for ad, ac, _, _ in anchor_members:
    ax.scatter(ad, ac, s=30, marker="*", c=INK, zorder=6)
cb = fig.colorbar(im, ax=ax, pad=0.02)
cb.set_label("final surface T (K)", fontsize=7)
cb.ax.tick_params(labelsize=6)
ax.set_xlabel(DEP_LABEL)
ax.set_ylabel(CE_LABEL)
ax.set_xticks(range(1, 8))
ax.set_yticks(range(1, 8))
ax.text(0.02, 0.97, "(a)", transform=ax.transAxes,
        fontsize=8, fontweight="bold", va="top", color="white")
ax.spines[["top", "right"]].set_visible(False)

# (b) ts_end vs rlds_mean scatter, colored by cloud_hours.
ax = axes[1]
ch_flat = cloud_hours.ravel()
ts_flat = ts_end.ravel()
rlds_flat = rlds_mean.ravel()
mask = np.isfinite(ch_flat) & np.isfinite(ts_flat) & np.isfinite(rlds_flat)
sc = ax.scatter(rlds_flat[mask], ts_flat[mask], c=ch_flat[mask], s=20,
                cmap="viridis", edgecolors="none", zorder=3)
cb = fig.colorbar(sc, ax=ax, pad=0.02)
cb.set_label(f"cloud lifetime (h of {n_hours})", fontsize=7)
cb.ax.tick_params(labelsize=6)
ax.set_xlabel("mean downwelling LW (W m$^{-2}$)")
ax.set_ylabel("final surface T (K)")
ax.text(0.02, 0.97, "(b)", transform=ax.transAxes,
        fontsize=8, fontweight="bold", va="top")
ax.spines[["top", "right"]].set_visible(False)

fig.tight_layout()
for ext in ("png", "pdf"):
    fig.savefig(OUTDIR / f"fig3_2d_surface.{ext}",
                dpi=300 if ext == "png" else None, bbox_inches="tight",
                facecolor="white")
plt.close(fig)

# ------------------------------------------------------------- captions --
try:
    sha = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT,
                         capture_output=True, text=True).stdout.strip() or "unknown"
except OSError:
    sha = "unknown"

config_sentence = (
    "Each cell is one 20-day Larcform1 single-column simulation "
    "(ClimaAtmos.jl coupled to ClimaSeaIce via ClimaCoupler: 1M microphysics "
    "with ConstantTimescale ice formation, UKI-calibrated parameters, "
    "prognostic EDMFx, quadrature cloud fraction, interactive sea-ice surface "
    "initialized at 250 K with 1 m ice and 0.1 m snow, Monin-Obukhov fluxes "
    "with z0 = 1e-3 m, z_max 5 km with 60 stretched levels, dt 30 s, "
    "dt_rad 30 min), varying the vapor-to-cloud-ice deposition timescale "
    "tau_dep (sublimation_deposition_timescale) and the liquid "
    "condensation/evaporation timescale tau_ce "
    "(condensation_evaporation_timescale) on a regular grid over "
    "10 to 1e7 s (both axes)."
)

captions = f"""# Figure captions: 2D tau_dep x tau_ce sweep (lf1e-taudep-1, subexp C)

Generated by analysis.py on {datetime.date.today()} from
output/lf1e-taudep-1-coupled-2d/manifest.toml
({len(members)} sweep members on a {n_dep}x{n_ce} grid)
at repo commit {sha}. Experiment protocol and findings:
experiments/taudep sweep coupled 2d/lf1e-taudep-sweep-coupled-2d.md.

## fig1_2d_regime_map

Cloud regime map over the (tau_dep, tau_ce) plane. (a) Cloud lifetime: hours
(of {n_hours}) with column-maximum cloud liquid above 0.1 g/kg. (b) Peak cloud
liquid mixing ratio. (c) Time-integrated liquid water path. (d) Final column
ice at day 20. {config_sentence} Small dots mark the simulation grid points;
stars mark the calibrated anchor.

## fig2_2d_transition

Transition characterization. (a) Cloud lifetime heatmap with contour lines
marking the transition boundary (white; the 50% contour at {int(0.5 * n_hours)} h
is labeled). The transition from cloud-free to cloud-sustaining runs through
the high-tau_dep, low-tau_ce quadrant.
(b) Cloud lifetime versus log10(tau_dep) at three fixed tau_ce values (blue
circles: tau_ce = 10 s; orange triangles: tau_ce = 10^4 s; gray squares:
tau_ce = 10^7 s), with the 1D subexperiment A curve (stock microphysics,
slab ocean) overlaid as a dashed black line for comparison.

## fig3_2d_surface

Surface temperature and radiative response. (a) Final surface temperature
(day 20) over the (tau_dep, tau_ce) plane; warmer surfaces correspond to
longer-lived cloud cover providing downwelling longwave insulation.
(b) Final surface temperature versus mean downwelling longwave, with points
colored by cloud lifetime; this directly shows the cloud radiative effect on
the surface energy budget.
"""

(OUTDIR / "CAPTIONS.md").write_text(captions)
print(f"Saved figures and CAPTIONS.md to {OUTDIR}")
