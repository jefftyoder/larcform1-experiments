"""Pithan 2016 state-space analyses for the tau_dep sweep extended members.

Reads the 20-day extended ladder from output/lf1e-taudep-1/ and compares
selected mid-tau members against the EC-Earth trajectory from the Pithan 2016
intercomparison. Produces three AGU/JAMES-ready figures:

  fig4_taudep_netlw_pdf:     PDF of hourly net surface LW (days 1-10 vs full)
  fig5_taudep_lls_netlw:     2D density in LLS-vs-netLW phase plane (days 1-10 vs full)
  fig6_taudep_energy_budget: surface energy budget time series (full 20 days)

Run from repo root:  python3 "experiments/taudep sweep/analysis_pithan.py"
"""

import datetime
import subprocess
from pathlib import Path

import numpy as np
import xarray as xr
import matplotlib.pyplot as plt
from matplotlib import colormaps
from matplotlib.colors import Normalize
from matplotlib.lines import Line2D

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "output" / "lf1e-taudep-1"
OUTDIR = Path(__file__).resolve().parent / "figures"
OUTDIR.mkdir(exist_ok=True)

_PITHAN_DATA = Path("/Users/jeff/clima/Pithan2016_Data/intercomparison data")
EC_EARTH = _PITHAN_DATA / "EC-Earth.nc"
ENS_DIR = _PITHAN_DATA

KAPPA = 0.286
CLEAR_THR = -20.0  # W/m^2, Pithan's clear/cloudy partition

BLUE, ORANGE, GRAY, INK = "#2a78d6", "#eb6834", "#898781", "#0b0b0b"
C_EC = "#c0392b"
C_ENS = "#9a988f"

plt.rcParams.update({
    "font.family": "sans-serif",
    "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
    "font.size": 8,
    "axes.linewidth": 0.6,
})

SELECTED_LOG10 = [3.5, 4.0, 4.5, 5.0, 5.5, 6.0]
SELECTED_TAUS = {x: f"lf1e_taudep1_20days_x{str(x).replace('.', 'p')}"
                 for x in SELECTED_LOG10}

CMAP = colormaps["viridis"]
NORM = Normalize(vmin=min(SELECTED_LOG10), vmax=max(SELECTED_LOG10))

# Time windows (hourly index). Pithan analyses use days 1-10; our 20-day
# extended runs capture the post-day-10 cycling that motivates this analysis.
# Both our members and EC-Earth output at 1-hour cadence in seconds;
# EC-Earth has 481 steps (hours 0-480 inclusive), ours has 480 (hours 1-480).
D1 = 24     # hour 24 = start of day 1
D10 = 240   # hour 240 = end of day 10
WINDOWS = [
    ("days 1–10", D1, D10),
    ("full 20 days", None, None),
]


def tau_color(log10_tau):
    return CMAP(NORM(log10_tau))


def load_1d(outdir, short_name):
    path = outdir / f"{short_name}_1h_average.nc"
    ds = xr.load_dataset(path, decode_times=False).squeeze()
    return ds[short_name]


def load_3d(outdir, short_name):
    path = outdir / f"{short_name}_1h_average.nc"
    ds = xr.load_dataset(path, decode_times=False).squeeze()
    return ds[short_name]


def netlw_from_outdir(outdir):
    rlds = load_1d(outdir, "rlds").values
    rlus = load_1d(outdir, "rlus").values
    return rlds - rlus  # positive = warming surface


def stability_from_outdir(outdir):
    ta = load_3d(outdir, "ta")
    pf = load_3d(outdir, "pfull")
    zdim = next(d for d in ta.dims if d != "time")
    ta_tz = ta.transpose("time", zdim).values
    pf_tz = pf.transpose("time", zdim).values
    t850 = np.array([
        np.interp(85000.0, pf_tz[i, ::-1], ta_tz[i, ::-1])
        for i in range(ta_tz.shape[0])
    ])
    th850 = t850 * (1e5 / 85000.0) ** KAPPA
    p_sfc0 = pf_tz[0, 0]
    th_sfc = ta_tz[:, 0] * (1e5 / p_sfc0) ** KAPPA
    return th850 - th_sfc


def time_days(outdir):
    rlds = xr.load_dataset(outdir / "rlds_1h_average.nc", decode_times=False).squeeze()
    return rlds["time"].values / 86400.0


def load_ecearth():
    if not EC_EARTH.exists():
        print(f"EC-Earth data not found at {EC_EARTH}; skipping reference")
        return None
    return xr.open_dataset(EC_EARTH, decode_times=False)


def ecearth_netlw(ds):
    rlds = np.asarray(ds["rlds"]).squeeze()
    rlus = np.asarray(ds["rlus"]).squeeze()
    return rlds + rlus  # Pithan convention: rlus is negative (upward)


def ecearth_stability(ds):
    t = np.asarray(ds["t"])
    pvar = "p" if "p" in ds else ("pf" if "pf" in ds else "ph")
    p = np.asarray(ds[pvar]) / 100.0
    if t.ndim > 2:
        t = t.reshape(t.shape[0], -1)
    if p.ndim > 2:
        p = p.reshape(p.shape[0], -1)
    sfc_idx = np.argmax(p[0])
    t850 = np.full(t.shape[0], np.nan)
    for k in range(t.shape[0]):
        pk, tk = np.squeeze(p[k]), np.squeeze(t[k])
        o = np.argsort(pk)
        t850[k] = np.interp(850.0, pk[o], tk[o], left=np.nan, right=np.nan)
    th850 = t850 * (1000.0 / 850.0) ** KAPPA
    p_sfc = p[:, sfc_idx]
    th_sfc = t[:, sfc_idx] * (1000.0 / p_sfc) ** KAPPA
    return th850 - th_sfc


def ecearth_time_days(ds):
    return np.asarray(ds["time"]).squeeze() / 3600.0 / 24.0


def load_ensemble():
    if not ENS_DIR.exists():
        return {}
    ens = {}
    for f in sorted(ENS_DIR.glob("*.nc")):
        name = f.stem
        try:
            ens[name] = xr.open_dataset(f, decode_times=False)
        except Exception:
            pass
    return ens


def ens_netlw(ds):
    rlds = np.asarray(ds["rlds"]).squeeze()
    rlus = np.asarray(ds["rlus"]).squeeze()
    return rlds + rlus


# Preload data shared across figures
ec_ds = load_ecearth()
ens = load_ensemble()

# Precompute per-member arrays (avoid redundant I/O across figures)
member_data = {}
for log_tau, job_id in SELECTED_TAUS.items():
    outdir = DATA / job_id / "output_active"
    if not outdir.exists():
        continue
    member_data[log_tau] = {
        "nlw": netlw_from_outdir(outdir),
        "lls": stability_from_outdir(outdir),
        "t": time_days(outdir),
        "hfss": load_1d(outdir, "hfss").values,
        "hfls": load_1d(outdir, "hfls").values,
    }

ec_nlw = ecearth_netlw(ec_ds) if ec_ds is not None else None
ec_lls = ecearth_stability(ec_ds) if ec_ds is not None else None

# ---------------------------------------------------------------- figure 4 --
# PDF of hourly surface net LW: left column days 1-10 (Pithan standard
# window), right column full 20 days. Each row is one selected tau.

BINS = np.arange(-110, 20.1, 5.0)
CENT = 0.5 * (BINS[:-1] + BINS[1:])


def lwpdf(vals, d1=None, d10=None):
    v = vals[d1:d10]
    v = v[np.isfinite(v)]
    if len(v) == 0:
        return np.zeros_like(CENT)
    h, _ = np.histogram(np.clip(v, BINS[0], BINS[-1] - 1e-6), bins=BINS)
    return h / h.sum() if h.sum() > 0 else h.astype(float)


n_sel = len(SELECTED_LOG10)
fig, axes = plt.subplots(n_sel, 2, figsize=(6.69, 1.6 * n_sel), sharey=True,
                         sharex=True)

for col, (wlabel, wd1, wd10) in enumerate(WINDOWS):
    axes[0, col].set_title(wlabel, fontsize=8)
    for row, log_tau in enumerate(SELECTED_LOG10):
        ax = axes[row, col]

        # Pithan ensemble background
        for name, eds in ens.items():
            if "rlus" not in eds:
                continue
            ax.plot(CENT, lwpdf(ens_netlw(eds), wd1, wd10), color=C_ENS,
                    lw=0.5, alpha=0.2, zorder=1)

        # EC-Earth
        if ec_nlw is not None:
            ax.plot(CENT, lwpdf(ec_nlw, wd1, wd10), color=C_EC, lw=1.0,
                    zorder=2)

        # This tau member
        if log_tau in member_data:
            ax.plot(CENT, lwpdf(member_data[log_tau]["nlw"], wd1, wd10),
                    color=tau_color(log_tau), lw=1.6, zorder=3)

        ax.axvline(CLEAR_THR, color=GRAY, lw=0.5, ls=":")
        ax.spines[["top", "right"]].set_visible(False)

        panel_idx = row * 2 + col
        ax.text(0.02, 0.95, f"({chr(97 + panel_idx)})", transform=ax.transAxes,
                fontsize=7, fontweight="bold", va="top")

        if col == 1:
            ax.text(1.02, 0.5,
                    r"$\log_{10}\tau$" + f" = {log_tau}",
                    transform=ax.transAxes, fontsize=7, ha="left", va="center",
                    rotation=-90)

for ax in axes[-1, :]:
    ax.set_xlabel(r"net surface LW (W m$^{-2}$)")
for ax in axes[:, 0]:
    ax.set_ylabel("PDF")

handles = [
    Line2D([], [], color=tau_color(4.5), lw=1.6,
           label=r"$\tau_{\mathrm{dep}}$ member"),
    Line2D([], [], color=C_EC, lw=1.0, label="EC-Earth"),
    Line2D([], [], color=C_ENS, lw=0.6, alpha=0.4, label="Pithan ensemble"),
]
axes[0, 0].legend(handles=handles, fontsize=6, loc="upper left",
                  handletextpad=0.3, borderaxespad=0.3, frameon=False)

fig.tight_layout()
fig.subplots_adjust(hspace=0.15, wspace=0.08)
for ext in ("png", "pdf"):
    fig.savefig(OUTDIR / f"fig4_taudep_netlw_pdf.{ext}",
                dpi=300 if ext == "png" else None, bbox_inches="tight",
                facecolor="white")
plt.close(fig)
print("wrote fig4_taudep_netlw_pdf")

# ---------------------------------------------------------------- figure 5 --
# 2D density in LLS-vs-netLW phase plane: left column days 1-10, right
# column full 20 days.

SB = np.arange(-20, 45.1, 3.0)
LB = np.arange(-110, 25.1, 5.0)

fig, axes = plt.subplots(n_sel, 2, figsize=(6.69, 2.0 * n_sel),
                         sharex=True, sharey=True)

for col, (wlabel, wd1, wd10) in enumerate(WINDOWS):
    axes[0, col].set_title(wlabel, fontsize=8)
    for row, log_tau in enumerate(SELECTED_LOG10):
        ax = axes[row, col]

        # EC-Earth background scatter
        if ec_lls is not None and ec_nlw is not None:
            s = ec_lls[wd1:wd10]
            n = ec_nlw[wd1:wd10]
            m = np.isfinite(s) & np.isfinite(n)
            ax.scatter(s[m], n[m], s=0.8, color=C_EC, alpha=0.12,
                       linewidths=0, zorder=1)

        if log_tau in member_data:
            nlw = member_data[log_tau]["nlw"][wd1:wd10]
            lls = member_data[log_tau]["lls"][wd1:wd10]
            m = np.isfinite(lls) & np.isfinite(nlw)
            hh, xe, ye = np.histogram2d(lls[m], nlw[m], bins=[SB, LB],
                                        density=False)
            if hh.sum() > 0:
                hh = hh / hh.sum()
            ax.pcolormesh(xe, ye, hh.T, cmap="YlOrRd", vmin=0, vmax=0.15,
                          zorder=2)
            ax.scatter(lls[m], nlw[m], s=0.8, color=tau_color(log_tau),
                       alpha=0.25, linewidths=0, zorder=3)

        ax.axhline(CLEAR_THR, color=GRAY, lw=0.4, ls=":")
        ax.axhline(0, color=GRAY, lw=0.3)
        ax.axvline(0, color=GRAY, lw=0.3)
        ax.spines[["top", "right"]].set_visible(False)

        panel_idx = row * 2 + col
        ax.text(0.02, 0.97, f"({chr(97 + panel_idx)})", transform=ax.transAxes,
                fontsize=7, fontweight="bold", va="top")

        if col == 1:
            ax.text(1.02, 0.5,
                    r"$\log_{10}\tau$" + f" = {log_tau}",
                    transform=ax.transAxes, fontsize=7, ha="left", va="center",
                    rotation=-90)

for ax in axes[-1, :]:
    ax.set_xlabel(r"LLS, $\theta_{850} - \theta_{\mathrm{sfc}}$ (K)")
for ax in axes[:, 0]:
    ax.set_ylabel(r"net surface LW (W m$^{-2}$)")

handles = [
    Line2D([], [], marker="o", ms=3, color=tau_color(4.5), lw=0,
           label=r"$\tau_{\mathrm{dep}}$ member"),
    Line2D([], [], marker="o", ms=3, color=C_EC, alpha=0.3, lw=0,
           label="EC-Earth"),
]
axes[0, 0].legend(handles=handles, fontsize=6, loc="lower left",
                  handletextpad=0.3, frameon=False)

fig.tight_layout()
fig.subplots_adjust(hspace=0.12, wspace=0.08)
for ext in ("png", "pdf"):
    fig.savefig(OUTDIR / f"fig5_taudep_lls_netlw.{ext}",
                dpi=300 if ext == "png" else None, bbox_inches="tight",
                facecolor="white")
plt.close(fig)
print("wrote fig5_taudep_lls_netlw")

# ---------------------------------------------------------------- figure 6 --
# Surface energy budget time series (full 20 days).

fig, axes = plt.subplots(3, 1, figsize=(6.69, 7.0), sharex=True,
                         constrained_layout=True)
ax_lw, ax_sh, ax_lh = axes

for log_tau in SELECTED_LOG10:
    if log_tau not in member_data:
        continue
    md = member_data[log_tau]
    color = tau_color(log_tau)
    ax_lw.plot(md["t"], md["nlw"], lw=0.8, color=color, label=f"{log_tau}")
    ax_sh.plot(md["t"], md["hfss"], lw=0.8, color=color)
    ax_lh.plot(md["t"], md["hfls"], lw=0.8, color=color)

if ec_ds is not None:
    ec_t = ecearth_time_days(ec_ds)
    ax_lw.plot(ec_t, ec_nlw, lw=1.0, color=C_EC, ls="--", alpha=0.7,
               label="EC-Earth", zorder=1)

ax_lw.set_ylabel(r"net surface LW (W m$^{-2}$)")
ax_lw.axhline(CLEAR_THR, color=GRAY, lw=0.5, ls=":")
ax_sh.set_ylabel(r"sensible heat flux (W m$^{-2}$)")
ax_lh.set_ylabel(r"latent heat flux (W m$^{-2}$)")
ax_lh.set_xlabel("time (days)")

for i, ax in enumerate(axes):
    ax.text(0.02, 0.97, f"({chr(97 + i)})", transform=ax.transAxes,
            fontsize=8, fontweight="bold", va="top")
    ax.spines[["top", "right"]].set_visible(False)
    ax.set_xlim(0, 20)

sm = plt.cm.ScalarMappable(cmap=CMAP, norm=NORM)
cb = fig.colorbar(sm, ax=axes, pad=0.01, fraction=0.025)
cb.set_label(r"log$_{10}$($\tau_{\mathrm{dep}}$ / s)", fontsize=8)
cb.ax.tick_params(labelsize=7)

handles_extra = [Line2D([], [], color=C_EC, ls="--", lw=1.0, alpha=0.7,
                        label="EC-Earth")]
ax_lw.legend(handles=ax_lw.get_legend_handles_labels()[0] + handles_extra,
             fontsize=6, loc="lower left", ncol=4, frameon=False,
             handletextpad=0.3, columnspacing=0.8)

for ext in ("png", "pdf"):
    fig.savefig(OUTDIR / f"fig6_taudep_energy_budget.{ext}",
                dpi=300 if ext == "png" else None, bbox_inches="tight",
                facecolor="white")
plt.close(fig)
print("wrote fig6_taudep_energy_budget")

# ------------------------------------------------------------- captions --
try:
    sha = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT,
                         capture_output=True, text=True).stdout.strip() or "unknown"
except OSError:
    sha = "unknown"

config_sentence = (
    "Each member is a 20-day Larcform1 single-column simulation "
    "(ClimaAtmos.jl: 1M microphysics with ConstantTimescale ice formation, "
    "prognostic EDMFx, quadrature cloud fraction, slab ocean surface "
    "initialized at 250 K, Monin-Obukhov fluxes with z0 = 1e-3 m, "
    "z_max 5 km with 60 stretched levels, dt 30 s, dt_rad 30 min), varying "
    "only the vapor-to-cloud-ice deposition timescale tau_dep."
)

captions = f"""# Figure captions: Pithan state-space analyses (lf1e-taudep-1)

Generated by analysis_pithan.py on {datetime.date.today()} at repo commit {sha}.
{config_sentence}
EC-Earth reference: Pithan et al. (2016) intercomparison data.

Note on extreme net LW values: our clear-state net surface LW reaches
approximately -97 W/m^2, compared to -69 W/m^2 for EC-Earth. This is
physical, not a sign error: the slab ocean surface stays near 250 K
(rlus approximately 221 W/m^2 throughout) while the clear-sky atmosphere
emits only approximately 122 W/m^2 downward. EC-Earth's interactive surface
cools to 238 K by day 20, reducing its own upward emission and narrowing
the net deficit. The difference is the expected signature of the slab
surface (no ice/snow conductivity model).

## fig4_taudep_netlw_pdf

PDF of hourly net surface longwave radiation (rlds minus rlus, positive
warming the surface) for selected tau_dep members (colored lines) overlaid
on the Pithan et al. (2016) intercomparison ensemble (gray) and EC-Earth
(red). Left column: days 1 to 10 (Pithan standard analysis window). Right
column: full 20 days. Dotted vertical line marks the {CLEAR_THR:.0f} W/m^2
clear/cloudy partition of Pithan et al. (2016). Panels span log10 tau_dep
from {min(SELECTED_LOG10)} to {max(SELECTED_LOG10)}, covering the transition
from early glaciation collapse to persistent cloud. Bimodality in the PDF
indicates a member visiting both the cloudy (near 0 W/m^2) and clear
(strongly negative) radiative states; the right column captures post-day-10
cycling visible in mid-tau members.

## fig5_taudep_lls_netlw

Joint density of low-level stability (theta at 850 hPa minus surface theta)
and net surface longwave for the same selected tau_dep members, with EC-Earth
hourly states shown as background scatter. Left column: days 1 to 10. Right
column: full 20 days. Heat map (YlOrRd) shows the fraction of hours in
each bin; colored dots are individual hourly states. The cloudy cluster
(low LLS, near-zero net LW) and clear cluster (high LLS, strongly negative
net LW) of Pithan et al. (2016) appear as the two density concentrations;
mid-tau members that traverse between them are cycling through the Pithan
four-stage process within a single run.

## fig6_taudep_energy_budget

Surface energy budget time series (full 20 days) for the selected tau_dep
members: (a) net longwave (rlds minus rlus); (b) sensible heat flux (hfss,
positive upward in ClimaAtmos convention); (c) latent heat flux (hfls).
Dashed red line in (a) is EC-Earth net LW for reference. Each Pithan
stage has a distinct energy balance signature: radiative cooling dominant
(clear), turbulent warming onset (cloud formation), near-equilibrium
(opaque cloud), renewed cooling (cloud breakup). Members at intermediate
tau_dep values cycle through these signatures, with the timing and
number of cycles controlled by the deposition timescale.
"""

captions_path = OUTDIR / "CAPTIONS.md"
existing = captions_path.read_text() if captions_path.exists() else ""
marker = "# Figure captions: Pithan state-space analyses"
if marker in existing:
    existing = existing[:existing.index(marker)]
with open(captions_path, "w") as f:
    f.write(existing + captions)

print(f"saved figures 4-6 and updated CAPTIONS.md in {OUTDIR}")
