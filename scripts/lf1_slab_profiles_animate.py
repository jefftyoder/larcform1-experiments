"""
Render lf1_slab_coupled vertical profiles as a video animation.

480 hourly frames play over 10 seconds (48 fps).
Saves to figures/lf1_slab_profiles_anim.mp4 (via ffmpeg) or
falls back to figures/lf1_slab_profiles_anim.gif (via pillow).

Run from repo root:
    python scripts/lf1_slab_profiles_animate.py
"""

import os
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, FFMpegWriter

import numpy as np
import pandas as pd
import xarray as xr

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NC_FILE = os.path.join(
    REPO_ROOT,
    "output/lf1_slab_coupled/output_0002/clima_atmos/"
    "ClimaLarcform1_coupled_lf1_slab_coupled_0002.nc",
)
FIGURES_DIR = os.path.join(REPO_ROOT, "figures")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from larcform1_initial_profiles import (  # noqa: E402
    RH_of_z,
    T_of_z,
    q_tot_of_z,
    theta_of_z,
    u_geo_of_z,
)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

P0  = 101300.0
R_D = 287.0
C_P = 1004.0
P_TICKS_HPA = np.array([1000, 850, 700, 500, 400, 300])

# ---------------------------------------------------------------------------
# Helpers (identical to lf1_slab_vertical_profiles.py)
# ---------------------------------------------------------------------------


def _compute_theta(T_K, p_Pa):
    return T_K * (P0 / p_Pa) ** (R_D / C_P)


def _pressure_ticks_km(p_mean_pa, lev_km):
    sort_idx = np.argsort(p_mean_pa)
    return np.interp(P_TICKS_HPA * 100.0, p_mean_pa[sort_idx], lev_km[sort_idx])


def _style_panel(ax, title, xlabel, xlim, show_ylabel=False):
    ax.set_title(title, fontsize=10, fontweight="bold")
    ax.set_xlabel(xlabel, fontsize=9)
    ax.set_xlim(xlim)
    if show_ylabel:
        ax.set_ylabel("Height (km)", fontsize=10)
    ax.grid(True, linestyle=":", alpha=0.5, linewidth=0.7)
    ax.tick_params(which="both", direction="in", labelsize=8)
    for spine in ax.spines.values():
        spine.set_linewidth(0.8)


def _add_pressure_axis(ax, z_ticks_km):
    ax_r = ax.twinx()
    ax_r.set_ylim(ax.get_ylim())
    ax_r.set_yticks(z_ticks_km)
    ax_r.set_yticklabels([str(int(p)) for p in P_TICKS_HPA], fontsize=8)
    ax_r.set_ylabel("Pressure (hPa)", fontsize=10)
    ax_r.tick_params(which="both", direction="in", labelsize=8)
    for spine in ax_r.spines.values():
        spine.set_linewidth(0.8)
    return ax_r


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main():
    print(f"Loading {NC_FILE} …")
    ds = xr.open_dataset(NC_FILE)

    lev_m     = ds["lev"].values
    lev_km    = lev_m / 1e3
    time_vals = ds["time"].values

    T     = ds["t"].values
    p     = ds["p"].values
    rh    = ds["rh"].values
    q     = ds["q"].values * 1e3
    u     = ds["u"].values
    clw   = np.clip(ds["clw"].values * 1e6, 0.0, None)
    cli   = np.clip(ds["cli"].values * 1e6, 0.0, None)
    theta = _compute_theta(T, p)

    p_mean     = p.mean(axis=0)
    z_ticks_km = _pressure_ticks_km(p_mean, lev_km)
    ylim       = (0.0, lev_km.max() * 1.02)

    ic_z  = np.linspace(0, lev_m.max(), 500)
    ic_km = ic_z / 1e3

    def _time_label(i):
        elapsed = (i + 1) / 24.0
        ts = pd.to_datetime(time_vals[i]).strftime("%b %d  %H:%M")
        return f"lf1_slab_coupled  —  Day {elapsed:.2f}  ({ts})"

    # ---------------------------------------------------------------------------
    # Build figure (no slider strip)
    # ---------------------------------------------------------------------------

    fig, axes = plt.subplots(1, 6, sharey=True, figsize=(22, 8))
    fig.subplots_adjust(wspace=0.08, bottom=0.10, top=0.88, left=0.05, right=0.95)

    ax_T, ax_rh, ax_q, ax_u, ax_clw, ax_cli = axes

    xlim_T = (min(T.min(), theta.min()) - 1, max(T.max(), theta.max()) + 1)
    _style_panel(ax_T, "Temperature", "T,  θ  (K)", xlim_T, show_ylabel=True)
    ax_T.set_ylim(ylim)
    ax_T.plot(T_of_z(ic_z),     ic_km, color="gray", lw=1, ls="--", alpha=0.6)
    ax_T.plot(theta_of_z(ic_z), ic_km, color="gray", lw=1, ls=":",  alpha=0.6)
    line_T,  = ax_T.plot(T[0],     lev_km, color="tab:red",  lw=2, label="T")
    line_th, = ax_T.plot(theta[0], lev_km, color="tab:blue", lw=2, ls="--", label="θ")
    ax_T.legend(fontsize=7, loc="upper left")

    _style_panel(ax_rh, "Relative Humidity", "RH  (–)", (0.0, 1.0))
    ax_rh.plot(RH_of_z(ic_z), ic_km, color="gray", lw=1, ls="--", alpha=0.6)
    line_rh, = ax_rh.plot(rh[0], lev_km, color="tab:cyan", lw=2, label="RH")
    ax_rh.legend(fontsize=7, loc="upper left")

    _style_panel(ax_q, "Specific Humidity", "q  (g kg⁻¹)", (0.0, q.max() * 1.05))
    ax_q.plot(q_tot_of_z(ic_z) * 1e3, ic_km, color="gray", lw=1, ls="--", alpha=0.6)
    line_q, = ax_q.plot(q[0], lev_km, color="tab:green", lw=2, label="q")
    ax_q.legend(fontsize=7, loc="upper right")

    u_margin = max(abs(u.min()), abs(u.max())) * 0.1 + 0.5
    _style_panel(ax_u, "Eastward Wind", "u  (m s⁻¹)",
                 (u.min() - u_margin, u.max() + u_margin))
    ax_u.axvline(0, color="gray", lw=0.6, ls=":")
    ax_u.plot(u_geo_of_z(ic_z), ic_km, color="gray", lw=1, ls="--", alpha=0.6)
    line_u, = ax_u.plot(u[0], lev_km, color="tab:orange", lw=2, label="u")
    ax_u.legend(fontsize=7, loc="upper right")

    _style_panel(ax_clw, "Cloud Liquid", "clw  (mg kg⁻¹)",
                 (0.0, max(clw.max() * 1.05, 1e-3)))
    line_clw, = ax_clw.plot(clw[0], lev_km, color="tab:blue", lw=2, label="clw")
    ax_clw.legend(fontsize=7, loc="upper right")

    _style_panel(ax_cli, "Cloud Ice", "cli  (mg kg⁻¹)",
                 (0.0, max(cli.max() * 1.05, 1e-3)))
    line_cli, = ax_cli.plot(cli[0], lev_km, color="tab:purple", lw=2, label="cli")
    ax_cli.legend(fontsize=7, loc="upper right")
    _add_pressure_axis(ax_cli, z_ticks_km)

    title_obj = fig.suptitle(_time_label(0), fontsize=11)

    # ---------------------------------------------------------------------------
    # Animation
    # ---------------------------------------------------------------------------

    def animate(i: int):
        title_obj.set_text(_time_label(i))
        line_T.set_xdata(T[i])
        line_th.set_xdata(theta[i])
        line_rh.set_xdata(rh[i])
        line_q.set_xdata(q[i])
        line_u.set_xdata(u[i])
        line_clw.set_xdata(clw[i])
        line_cli.set_xdata(cli[i])
        return ()

    anim = FuncAnimation(fig, animate, frames=480, interval=1000 / 48, blit=False)

    os.makedirs(FIGURES_DIR, exist_ok=True)
    out_mp4 = os.path.join(FIGURES_DIR, "lf1_slab_profiles_anim.mp4")
    out_gif = os.path.join(FIGURES_DIR, "lf1_slab_profiles_anim.gif")

    try:
        writer = FFMpegWriter(
            fps=48, bitrate=2000,
            extra_args=["-vcodec", "libx264", "-pix_fmt", "yuv420p"],
        )
        print("Rendering 480 frames to MP4 …")
        anim.save(out_mp4, writer=writer, dpi=100)
        print(f"Saved {out_mp4}")
    except Exception as exc:
        print(f"ffmpeg failed ({exc}); falling back to GIF …")
        anim.save(out_gif, writer="pillow", fps=24, dpi=80)
        print(f"Saved {out_gif}")


if __name__ == "__main__":
    main()
