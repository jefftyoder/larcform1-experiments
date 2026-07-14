"""
Build a self-contained interactive HTML of lf1_slab_coupled vertical profiles.

Six panels (T/θ, RH, q, u, clw, cli) with a play/pause button and a time
slider that steps through all 480 hourly frames.  IC reference profiles are
shown as static gray dashed lines.  The right axis of the last panel shows
pressure in hPa.

Saves to figures/lf1_slab_profiles.html (~10 MB, fully offline).

Run from repo root:
    python scripts/lf1_slab_profiles_plotly.py
"""

import os
import sys

import numpy as np
import pandas as pd
import xarray as xr
import plotly.graph_objects as go
from plotly.subplots import make_subplots

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

PANEL_COLORS = {
    "T":   "#e15759",   # tab:red
    "th":  "#4e79a7",   # tab:blue
    "rh":  "#76b7b2",   # tab:cyan
    "q":   "#59a14f",   # tab:green
    "u":   "#f28e2b",   # tab:orange
    "clw": "#4e79a7",   # tab:blue
    "cli": "#b07aa1",   # tab:purple
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _compute_theta(T_K, p_Pa):
    return T_K * (P0 / p_Pa) ** (R_D / C_P)


def _pressure_ticks_km(p_mean_pa, lev_km):
    sort_idx = np.argsort(p_mean_pa)
    return np.interp(P_TICKS_HPA * 100.0, p_mean_pa[sort_idx], lev_km[sort_idx])


def _ic_trace(x, y_km, name="IC"):
    return go.Scatter(
        x=x.tolist(), y=y_km.tolist(),
        mode="lines",
        line=dict(color="gray", dash="dash", width=1),
        name=name, showlegend=False, hoverinfo="skip",
    )


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
    ylim       = [0.0, float(lev_km.max() * 1.02)]

    ic_z  = np.linspace(0, lev_m.max(), 500)
    ic_km = ic_z / 1e3

    def _time_label(i):
        elapsed = (i + 1) / 24.0
        ts = pd.to_datetime(time_vals[i]).strftime("%b %d  %H:%M")
        return f"lf1_slab_coupled  —  Day {elapsed:.2f}  ({ts})"

    # X-axis limits (fixed from full time range)
    xlim_T   = [float(min(T.min(), theta.min())) - 1,
                float(max(T.max(), theta.max())) + 1]
    xlim_rh  = [0.0, 1.0]
    xlim_q   = [0.0, float(q.max() * 1.05)]
    u_margin = float(max(abs(u.min()), abs(u.max()))) * 0.1 + 0.5
    xlim_u   = [float(u.min()) - u_margin, float(u.max()) + u_margin]
    xlim_clw = [0.0, max(float(clw.max() * 1.05), 1e-3)]
    xlim_cli = [0.0, max(float(cli.max() * 1.05), 1e-3)]

    # ---------------------------------------------------------------------------
    # Subplots: 1 row × 6 cols, shared y-axis
    # ---------------------------------------------------------------------------

    fig = make_subplots(
        rows=1, cols=6,
        shared_yaxes=True,
        subplot_titles=["Temperature", "Relative Humidity", "Specific Humidity",
                        "Eastward Wind", "Cloud Liquid", "Cloud Ice"],
        horizontal_spacing=0.04,
    )

    lev_list = lev_km.tolist()

    # ---- Static IC overlays ----
    fig.add_trace(_ic_trace(T_of_z(ic_z),        ic_km), row=1, col=1)
    fig.add_trace(_ic_trace(theta_of_z(ic_z),     ic_km, name="θ IC"), row=1, col=1)
    fig.add_trace(_ic_trace(RH_of_z(ic_z),        ic_km), row=1, col=2)
    fig.add_trace(_ic_trace(q_tot_of_z(ic_z)*1e3, ic_km), row=1, col=3)
    fig.add_trace(_ic_trace(u_geo_of_z(ic_z),     ic_km), row=1, col=4)
    n_static = 5   # number of static traces above

    # ---- Base (t=0) animated traces ----
    fig.add_trace(go.Scatter(
        x=T[0].tolist(), y=lev_list, mode="lines",
        line=dict(color=PANEL_COLORS["T"], width=2), name="T",
    ), row=1, col=1)
    T_idx = n_static + 0

    fig.add_trace(go.Scatter(
        x=theta[0].tolist(), y=lev_list, mode="lines",
        line=dict(color=PANEL_COLORS["th"], width=2, dash="dash"), name="θ",
    ), row=1, col=1)
    th_idx = n_static + 1

    fig.add_trace(go.Scatter(
        x=rh[0].tolist(), y=lev_list, mode="lines",
        line=dict(color=PANEL_COLORS["rh"], width=2), name="RH",
    ), row=1, col=2)
    rh_idx = n_static + 2

    fig.add_trace(go.Scatter(
        x=q[0].tolist(), y=lev_list, mode="lines",
        line=dict(color=PANEL_COLORS["q"], width=2), name="q",
    ), row=1, col=3)
    q_idx = n_static + 3

    fig.add_trace(go.Scatter(
        x=u[0].tolist(), y=lev_list, mode="lines",
        line=dict(color=PANEL_COLORS["u"], width=2), name="u",
    ), row=1, col=4)
    u_idx = n_static + 4

    fig.add_trace(go.Scatter(
        x=clw[0].tolist(), y=lev_list, mode="lines",
        line=dict(color=PANEL_COLORS["clw"], width=2), name="clw",
    ), row=1, col=5)
    clw_idx = n_static + 5

    fig.add_trace(go.Scatter(
        x=cli[0].tolist(), y=lev_list, mode="lines",
        line=dict(color=PANEL_COLORS["cli"], width=2), name="cli",
    ), row=1, col=6)
    cli_idx = n_static + 6

    animated_indices = [T_idx, th_idx, rh_idx, q_idx, u_idx, clw_idx, cli_idx]

    # ---------------------------------------------------------------------------
    # Frames — only x changes per frame; y (lev_km) is fixed in base traces
    # ---------------------------------------------------------------------------

    print("Building frames …")
    frames = []
    for i in range(480):
        frames.append(go.Frame(
            data=[
                go.Scatter(x=T[i].tolist()),
                go.Scatter(x=theta[i].tolist()),
                go.Scatter(x=rh[i].tolist()),
                go.Scatter(x=q[i].tolist()),
                go.Scatter(x=u[i].tolist()),
                go.Scatter(x=clw[i].tolist()),
                go.Scatter(x=cli[i].tolist()),
            ],
            traces=animated_indices,
            name=str(i),
            layout=go.Layout(title_text=_time_label(i)),
        ))
    fig.frames = frames

    # ---------------------------------------------------------------------------
    # Axis styling
    # ---------------------------------------------------------------------------

    # Shared y-axis (height in km)
    fig.update_yaxes(
        title_text="Height (km)", range=ylim,
        showgrid=True, gridcolor="rgba(0,0,0,0.12)",
        ticks="inside", tickfont_size=9,
        row=1, col=1,
    )
    fig.update_yaxes(
        range=ylim, showgrid=True, gridcolor="rgba(0,0,0,0.12)",
        ticks="inside", tickfont_size=9,
        row=1, col=2,
    )

    # X-axis labels and limits per panel
    for col, (label, xlim) in enumerate([
        ("T,  θ  (K)",    xlim_T),
        ("RH  (–)",        xlim_rh),
        ("q  (g kg⁻¹)",   xlim_q),
        ("u  (m s⁻¹)",    xlim_u),
        ("clw  (mg kg⁻¹)", xlim_clw),
        ("cli  (mg kg⁻¹)", xlim_cli),
    ], start=1):
        fig.update_xaxes(
            title_text=label, range=xlim, row=1, col=col,
            showgrid=True, gridcolor="rgba(0,0,0,0.12)",
            ticks="inside", tickfont_size=9,
        )

    # Zero-line for u panel
    fig.update_layout(xaxis4=dict(zeroline=True, zerolinecolor="gray",
                                  zerolinewidth=1))

    # Pressure right-axis on the last column (overlays the shared y-axis)
    fig.update_layout(
        yaxis2=dict(
            overlaying="y",
            side="right",
            anchor="x6",
            range=ylim,
            tickvals=z_ticks_km.tolist(),
            ticktext=[str(int(pv)) for pv in P_TICKS_HPA],
            title_text="Pressure (hPa)",
            showgrid=False,
            ticks="inside",
            tickfont_size=9,
        )
    )
    # Anchor the dummy trace for yaxis2 on the cli panel
    fig.data[cli_idx].update(yaxis="y2")

    # ---------------------------------------------------------------------------
    # Play / Pause buttons and time slider
    # ---------------------------------------------------------------------------

    slider_steps = []
    for i in range(480):
        elapsed = (i + 1) / 24.0
        label = f"Day {elapsed:.0f}" if (i + 1) % 24 == 0 else ""
        slider_steps.append(dict(
            method="animate",
            args=[[str(i)], {"frame": {"duration": 0}, "mode": "immediate",
                             "transition": {"duration": 0}}],
            label=label,
        ))

    fig.update_layout(
        title_text=_time_label(0),
        title_font_size=13,
        height=650,
        width=1600,
        showlegend=True,
        legend=dict(orientation="h", y=-0.18, x=0.5, xanchor="center"),
        plot_bgcolor="white",
        paper_bgcolor="white",
        updatemenus=[dict(
            type="buttons",
            showactive=False,
            y=-0.12,
            x=0.02,
            xanchor="left",
            buttons=[
                dict(
                    label="▶ Play",
                    method="animate",
                    args=[None, {"frame": {"duration": round(1000 / 48),
                                           "redraw": False},
                                 "fromcurrent": True,
                                 "transition": {"duration": 0}}],
                ),
                dict(
                    label="⏸ Pause",
                    method="animate",
                    args=[[None], {"frame": {"duration": 0},
                                   "mode": "immediate",
                                   "transition": {"duration": 0}}],
                ),
            ],
        )],
        sliders=[dict(
            active=0,
            currentvalue=dict(prefix="", font=dict(size=11), visible=True,
                               xanchor="center"),
            pad=dict(t=10, b=5),
            len=0.88,
            x=0.10,
            y=-0.08,
            steps=slider_steps,
        )],
    )

    # ---------------------------------------------------------------------------
    # Export
    # ---------------------------------------------------------------------------

    os.makedirs(FIGURES_DIR, exist_ok=True)
    out = os.path.join(FIGURES_DIR, "lf1_slab_profiles.html")
    print(f"Writing {out} …")
    fig.write_html(out, include_plotlyjs=True)
    size_mb = os.path.getsize(out) / 1e6
    print(f"Saved {out}  ({size_mb:.1f} MB)")


if __name__ == "__main__":
    main()
