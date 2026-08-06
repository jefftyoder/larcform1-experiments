"""Abstract figure: LWP vs time — constant-timescale vs temperature-dependent ice deposition.

Data: 2-day Larcform1 sensitivity runs (lf1e-clw-1, converted to Pithan format)
vs EC-Earth from the Pithan 2016 intercomparison. Supports the AGU 2026 abstract's
central claim: constant tau_dep leaves LWP identically zero across three orders of
magnitude; only the INP-limited temperature-dependent timescale recovers the cloud.

Run from repo root:  python3 "paper-writing/figures/fig_lwp_const_vs_tdep.py"
"""

from pathlib import Path

import numpy as np
import xarray as xr
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve()
# Walk up until we find the repo root (works from paper-writing/figures/ or a tmp copy)
for parent in ROOT.parents:
    if (parent / "Pithan 2016 Intercomparison Data").exists():
        ROOT = parent
        break
else:
    ROOT = Path("/Users/jeff/clima/larcform1-experiments")

SENS = ROOT / "experiments/clw sensitivity experiments/output/pithan_format"
EC_PATH = ROOT / "Pithan 2016 Intercomparison Data" / "EC-Earth.nc"
OUTDIR = ROOT / "paper-writing" / "figures"
OUTDIR.mkdir(exist_ok=True)

# Colors: validated palette slots 1-2 on white + ink/chrome tokens (dataviz skill)
BLUE = "#2a78d6"     # temperature-dependent tau_dep (the fix)
ORANGE = "#eb6834"   # constant tau_dep, default and sweep <= 1e3 s (LWP == 0)
GRAY = "#898781"     # suppressed-pathway context runs (tau = 1e4, 1e9)
INK = "#0b0b0b"
INK2 = "#52514e"
GRID = "#e1e0d9"
ECBLACK = "#222222"

DAYS = 2.0


def lwp(name: str) -> tuple[np.ndarray, np.ndarray]:
    ds = xr.load_dataset(SENS / f"{name}.nc", decode_times=False).squeeze()
    t = ds["time"].values / 86400.0
    return t, ds["clwvi"].values


ec = xr.load_dataset(EC_PATH, decode_times=False).squeeze()
ec_t = np.arange(ec.sizes["time"]) / 24.0  # hourly record
sel = ec_t <= DAYS
ec_t, ec_lwp = ec_t[sel], ec["clwvi"].values[sel]

# AGU graphics requirements: Arial/Helvetica; >= 8 pt text at final size;
# two-column figure width 105-170 mm. Sized at the full 170 mm (6.69 in) with
# 10.5-13 pt bold labeling, so it is print-legal and scales up for a poster.
plt.rcParams.update({
    "font.family": "sans-serif",
    "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
    "font.size": 10.5,
    "mathtext.default": "bf",   # bold math to match bold labels
    "axes.edgecolor": GRID,
    "axes.linewidth": 0.8,
    "xtick.color": INK2,
    "ytick.color": INK2,
    "xtick.labelsize": 10.5,
    "ytick.labelsize": 10.5,
    "axes.labelcolor": INK,
    "text.color": INK,
})

fig, ax = plt.subplots(figsize=(6.69, 3.9))


# Context: constant tau with the pathway radically suppressed (gray, dashed)
t8, y8 = lwp("v8_subltime10000")
t12, y12 = lwp("v12_subltime1e9")
(l12,) = ax.plot(t12, y12, color=GRAY, lw=1.9, ls=(0, (5, 2)), zorder=2,
                 label=r"constant $\tau_{\mathrm{dep}}$ = $10^9$ s (negligible ice)")
(l8,) = ax.plot(t8, y8, color=GRAY, lw=1.9, ls=(0, (1.5, 1.5)), zorder=2,
                label=r"constant $\tau_{\mathrm{dep}}$ = $10^4$ s (transient only)")

# The two protagonists + reference
t1, y1 = lwp("v1_base")
t10, y10 = lwp("v10_tdepice")
(lec,) = ax.plot(ec_t, ec_lwp, color=ECBLACK, lw=2.8, zorder=4,
                 label="EC-Earth (reference)")
(l10,) = ax.plot(t10, y10, color=BLUE, lw=2.6, zorder=5,
                 label=r"temperature-dependent $\tau_{\mathrm{dep}}$ (INP-limited)")
(l1,) = ax.plot(t1, y1, color=ORANGE, lw=2.8, zorder=6,
                label=r"constant $\tau_{\mathrm{dep}}$ = 10–$10^3$ s (incl. 100 s default)")

ax.annotate("EC-Earth", xy=(1.55, 0.062), color=INK2, fontsize=11,
            fontweight="bold")
ax.annotate(r"LWP $\equiv$ 0 for constant $\tau_{\mathrm{dep}} \leq 10^3$ s",
            xy=(1.00, 0.009), color=INK2, fontsize=10.5, fontweight="bold")

ax.set_xlim(0, DAYS)
ax.set_ylim(-0.006, 0.32)
ax.set_xlabel("time (days)", fontsize=12.5, fontweight="bold")
ax.set_ylabel(r"liquid water path (kg m$^{-2}$)", fontsize=12.5,
              fontweight="bold")
ax.set_xticks([0, 0.5, 1, 1.5, 2])
ax.set_yticks([0, 0.1, 0.2, 0.3])
ax.tick_params(axis="both", labelsize=10.5, labelcolor=INK2)
for lbl in ax.get_xticklabels() + ax.get_yticklabels():
    lbl.set_fontweight("bold")
ax.legend(handles=[lec, l10, l1, l8, l12], loc="upper left",
          prop={"size": 10.5, "weight": "bold"}, frameon=False,
          handlelength=2.4, borderaxespad=0.4, labelspacing=0.55)
ax.spines[["top", "right"]].set_visible(False)

fig.tight_layout()
for ext in ("png", "pdf"):
    fig.savefig(OUTDIR / f"fig_lwp_const_vs_tdep.{ext}",
                dpi=300 if ext == "png" else None, bbox_inches="tight",
                facecolor="white")
print(f"saved to {OUTDIR}/fig_lwp_const_vs_tdep.[png,pdf]")
