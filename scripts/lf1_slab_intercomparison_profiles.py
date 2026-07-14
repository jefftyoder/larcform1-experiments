"""
Interactive vertical profile intercomparison: lf1_slab_coupled vs Pithan 2016 ensemble.

Six panels (T/θ, RH, q, u, clw, cli) share a single height (km) y-axis.
Pithan 2016 ensemble (15 models) shown as thin gray lines; Clima shown in color.
IC reference profiles shown as static gray dashed lines.

Y-axis: height (km).  Right axis on last panel: pressure (hPa) from Clima time-mean p.
Pithan model pressure levels are converted to approximate heights via the IC p↔z mapping.

Run from repo root:
    python scripts/lf1_slab_intercomparison_profiles.py
"""

import os
import sys

import matplotlib.pyplot as plt
import matplotlib.widgets as mwidgets
import mplcursors  # type: ignore[import-untyped]
import numpy as np
import pandas as pd
import xarray as xr

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NC_FILE_CLIMA = os.path.join(
    REPO_ROOT,
    "output/lf1_slab_coupled/output_0002/clima_atmos/"
    "ClimaLarcform1_coupled_lf1_slab_coupled_0002.nc",
)
INTERCOMPARISON_DIR = "/Users/jeff/clima/Pithan2016_Data/intercomparison data"

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from larcform1_initial_profiles import (  # noqa: E402
    RH_of_z, T_of_z, q_tot_of_z, theta_of_z, u_geo_of_z, z_of_p,
)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

P0          = 101300.0
R_D         = 287.0
C_P         = 1004.0
P_TICKS_HPA = np.array([1000, 850, 700, 500, 400, 300], dtype=float)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _compute_theta(T_K, p_Pa):
    return T_K * (P0 / p_Pa) ** (R_D / C_P)


def _pressure_ticks_km(p_mean_pa, lev_km):
    """Height (km) positions for standard pressure tick labels."""
    sort_idx = np.argsort(p_mean_pa)
    return np.interp(P_TICKS_HPA * 100.0, p_mean_pa[sort_idx], lev_km[sort_idx])


def _style_panel(ax, title, xlabel, xlim, ylim, show_ylabel=False):
    ax.set_title(title, fontsize=10, fontweight="bold")
    ax.set_xlabel(xlabel, fontsize=9)
    ax.set_xlim(xlim)
    ax.set_ylim(ylim)
    if show_ylabel:
        ax.set_ylabel("Height (km)", fontsize=10)
    ax.grid(True, linestyle=":", alpha=0.5, linewidth=0.7)
    ax.tick_params(which="both", direction="in", labelsize=8)
    for spine in ax.spines.values():
        spine.set_linewidth(0.8)


def _add_pressure_axis(ax, z_ticks_km):
    """Right-side pressure (hPa) twin axis using the Clima time-mean p↔z mapping."""
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
# Pithan model loading
# ---------------------------------------------------------------------------

_KNOWN_VERT_DIMS = {"lev", "levh", "mlev", "nlev", "plev"}
_SKIP_DIMS       = {"lat", "lon", "latitude", "longitude", "ncl1"}


def _vert_dim_of(da, time_dim):
    for d in da.dims:
        if d in _KNOWN_VERT_DIMS:
            return d
    for d in da.dims:
        if d not in _SKIP_DIMS and d != time_dim:
            return d
    return None


def _to_2d(da):
    """Squeeze and return a (n_time, n_lev) float64 array with auto dim detection.

    Returns None if the array cannot be reduced to 2-D.
    """
    da = da.squeeze()
    if da.ndim != 2:
        return None
    t_dim = "time" if "time" in da.dims else da.dims[0]
    v_dim = _vert_dim_of(da, t_dim)
    if v_dim is None:
        return None
    if da.dims != (t_dim, v_dim):
        da = da.transpose(t_dim, v_dim)
    return da.values.astype(float)


def load_pithan_models(intercomparison_dir):
    """Load all .nc files; return list of model dicts."""
    nc_files = sorted(f for f in os.listdir(intercomparison_dir) if f.endswith(".nc"))
    print(f"Found {len(nc_files)} files in intercomparison directory.")
    models = []
    for fname in nc_files:
        path = os.path.join(intercomparison_dir, fname)
        name = fname[:-3]
        try:
            ds = xr.open_dataset(path, decode_times=False)
        except Exception as exc:
            print(f"  [{name}] open failed: {exc}")
            continue

        if "t" not in ds:
            print(f"  [{name}] missing 't' — skipped")
            ds.close()
            continue

        # Try common pressure variable names
        p_var = next((v for v in ("p", "ph", "pf") if v in ds), None)
        if p_var is None:
            print(f"  [{name}] no pressure variable (p/ph/pf) — skipped")
            ds.close()
            continue

        T_raw = _to_2d(ds["t"])
        p_raw = _to_2d(ds[p_var])
        if T_raw is None or p_raw is None:
            print(f"  [{name}] cannot reduce 't'/'p' to 2-D (dims={ds['t'].dims}) — skipped")
            ds.close()
            continue

        n_time    = T_raw.shape[0]
        theta_raw = _compute_theta(T_raw, p_raw)
        p_hpa     = p_raw / 100.0
        # Convert pressure levels to approximate heights via IC p↔z mapping.
        # Pithan models use pressure as vertical coordinate; this gives a fixed
        # height axis anchored to the Larcform1 initial state.
        z_km = z_of_p(p_raw) / 1e3   # (n_time, n_lev)

        def _load(vname, scale=1.0, clip_zero=False):
            if vname not in ds:
                return None
            arr = _to_2d(ds[vname])
            if arr is None:
                return None
            arr = arr * scale
            return np.clip(arr, 0.0, None) if clip_zero else arr

        rh_raw = _load("rh")
        if rh_raw is not None and np.nanmedian(rh_raw) > 1.0:
            rh_raw = rh_raw / 100.0   # percent → fraction

        q_raw   = _load("q",   scale=1e3)
        u_raw   = _load("u")
        clw_raw = _load("clw", scale=1e6, clip_zero=True)
        cli_raw = _load("cli", scale=1e6, clip_zero=True)

        models.append(dict(
            name=name, n_time=n_time,
            T=T_raw, theta=theta_raw, p_hpa=p_hpa, z_km=z_km,
            rh=rh_raw, q=q_raw, u=u_raw,
            clw=clw_raw, cli=cli_raw,
        ))
        ds.close()
        print(f"  [{name}]  n_time={n_time}  n_lev={T_raw.shape[1]}")

    return models


# ---------------------------------------------------------------------------
# X-axis limit helpers
# ---------------------------------------------------------------------------


def _robust_lim_z(arr_z_pairs, pct_lo=1, pct_hi=99, pad=0.0,
                   lo_floor=None, hi_floor=None, z_max=None):
    """Robust xlim restricted to the visible height range (0–z_max km).

    arr_z_pairs: iterable of (data_array, z_km_array) 2-tuples; None entries skipped.
    """
    vals = []
    for arr, z_km in arr_z_pairs:
        if arr is None or z_km is None:
            continue
        mask = np.isfinite(arr)
        if z_max is not None:
            mask &= (z_km <= z_max)
        vals.append(arr[mask].ravel())
    if not vals:
        return (0.0, 1.0)
    all_v = np.concatenate(vals)
    if len(all_v) == 0:
        return (0.0, 1.0)
    lo = float(np.nanpercentile(all_v, pct_lo)) - pad
    hi = float(np.nanpercentile(all_v, pct_hi)) + pad
    if lo_floor is not None:
        lo = lo_floor
    if hi_floor is not None and hi < hi_floor:
        hi = hi_floor
    return (lo, hi)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main():
    # ---- Clima ---------------------------------------------------------------
    print(f"Loading Clima: {NC_FILE_CLIMA} …")
    ds_c      = xr.open_dataset(NC_FILE_CLIMA)
    lev_m     = ds_c["lev"].values          # (90,) fixed heights in metres
    lev_km    = lev_m / 1e3                 # fixed — never changes with time
    time_vals = ds_c["time"].values

    c_T     = ds_c["t"].values
    c_p     = ds_c["p"].values
    c_rh    = ds_c["rh"].values
    c_q     = ds_c["q"].values * 1e3
    c_u     = ds_c["u"].values
    c_clw   = np.clip(ds_c["clw"].values * 1e6, 0.0, None)
    c_cli   = np.clip(ds_c["cli"].values * 1e6, 0.0, None)
    c_theta = _compute_theta(c_T, c_p)
    ds_c.close()

    # ---- Pithan ensemble -----------------------------------------------------
    print(f"\nLoading Pithan models from:\n  {INTERCOMPARISON_DIR}")
    pithan = load_pithan_models(INTERCOMPARISON_DIR)
    print(f"\nLoaded {len(pithan)} Pithan models.")

    # ---- Shared y-axis range and pressure ticks ------------------------------
    ylim = (0.0, lev_km.max() * 1.02)
    z_max = lev_km.max()

    # Place pressure ticks at heights derived from Clima time-mean pressure profile
    p_mean     = c_p.mean(axis=0)
    z_ticks_km = _pressure_ticks_km(p_mean, lev_km)

    # ---- IC reference profiles (fine z grid) ---------------------------------
    ic_z  = np.linspace(0, lev_m.max(), 500)
    ic_km = ic_z / 1e3

    def _time_label(i):
        elapsed = (i + 1) / 24.0
        ts = pd.to_datetime(time_vals[i]).strftime("%b %d  %H:%M")
        return f"lf1_slab_coupled vs Pithan 2016  —  Day {elapsed:.2f}  ({ts})"

    # ---- X-axis limits (filtered to visible height range) --------------------
    def _pp_z(key, clima_arr):
        """(arr, z_km) pairs for Clima + Pithan, clipped to model top."""
        clima_z = np.broadcast_to(lev_km, clima_arr.shape)
        return ([(clima_arr, clima_z)]
                + [(m[key], m["z_km"]) for m in pithan if m[key] is not None])

    xlim_T   = _robust_lim_z(
        [(c_T,     np.broadcast_to(lev_km, c_T.shape)),
         (c_theta, np.broadcast_to(lev_km, c_theta.shape))]
        + [(m["T"],     m["z_km"]) for m in pithan]
        + [(m["theta"], m["z_km"]) for m in pithan],
        pad=1.0, z_max=z_max,
    )
    xlim_rh  = (0.0, 1.05)
    xlim_q   = _robust_lim_z(_pp_z("q",   c_q),   lo_floor=0.0, hi_floor=0.1, z_max=z_max)
    xlim_clw = _robust_lim_z(_pp_z("clw", c_clw), lo_floor=0.0, hi_floor=1e-3, z_max=z_max)
    xlim_cli = _robust_lim_z(_pp_z("cli", c_cli), lo_floor=0.0, hi_floor=1e-3, z_max=z_max)

    u_lo, u_hi = _robust_lim_z(_pp_z("u", c_u), z_max=z_max)
    u_margin   = max(abs(u_lo), abs(u_hi)) * 0.1 + 0.5
    xlim_u     = (u_lo - u_margin, u_hi + u_margin)

    # ---- Figure --------------------------------------------------------------
    fig, axes = plt.subplots(1, 6, sharey=True, figsize=(22, 8))
    fig.subplots_adjust(wspace=0.08, bottom=0.13, top=0.88, left=0.05, right=0.79)
    ax_T, ax_rh, ax_q, ax_u, ax_clw, ax_cli = axes

    _style_panel(ax_T,   "Temperature",       "T,  θ  (K)",      xlim_T,   ylim, show_ylabel=True)
    _style_panel(ax_rh,  "Relative Humidity",  "RH  (–)",         xlim_rh,  ylim)
    _style_panel(ax_q,   "Specific Humidity",  "q  (g kg⁻¹)",    xlim_q,   ylim)
    _style_panel(ax_u,   "Eastward Wind",      "u  (m s⁻¹)",     xlim_u,   ylim)
    _style_panel(ax_clw, "Cloud Liquid",       "clw  (mg kg⁻¹)", xlim_clw, ylim)
    _style_panel(ax_cli, "Cloud Ice",          "cli  (mg kg⁻¹)", xlim_cli, ylim)

    ax_u.axvline(0, color="gray", lw=0.6, ls=":")
    ax_cli_r = _add_pressure_axis(ax_cli, z_ticks_km)

    # ---- IC reference profiles (static) -------------------------------------
    ic_T_line,  = ax_T.plot(T_of_z(ic_z),     ic_km, color="gray", lw=1, ls="--", alpha=0.6)
    ic_th_line, = ax_T.plot(theta_of_z(ic_z), ic_km, color="gray", lw=1, ls=":",  alpha=0.6)
    ax_rh.plot(RH_of_z(ic_z),       ic_km, color="gray", lw=1, ls="--", alpha=0.6)
    ax_q.plot(q_tot_of_z(ic_z)*1e3, ic_km, color="gray", lw=1, ls="--", alpha=0.6)
    ax_u.plot(u_geo_of_z(ic_z),     ic_km, color="gray", lw=1, ls="--", alpha=0.6)

    # ---- Pithan ensemble lines (thin gray) ----------------------------------
    pit_T   = []
    pit_th  = []
    pit_rh  = []
    pit_q   = []
    pit_u   = []
    pit_clw = []
    pit_cli = []

    # model_lines: name → all Line2D objects (for CheckButtons toggle)
    # _line_info:  Line2D → (display_name, variable_label) (for mplcursors hover)
    model_lines: dict = {m["name"]: [] for m in pithan}
    _line_info:  dict = {}

    _gray = dict(color="gray", lw=0.8, alpha=0.5, zorder=1)

    for m in pithan:
        z0, name = m["z_km"][0], m["name"]

        line, = ax_T.plot(m["T"][0],     z0, **_gray)
        pit_T.append((m, line));  model_lines[name].append(line);  _line_info[line] = (name, "T (K)")
        line, = ax_T.plot(m["theta"][0], z0, **{**_gray, "ls": ":"})
        pit_th.append((m, line)); model_lines[name].append(line);  _line_info[line] = (name, "θ (K)")

        if m["rh"] is not None:
            line, = ax_rh.plot(m["rh"][0], z0, **_gray)
            pit_rh.append((m, line));  model_lines[name].append(line);  _line_info[line] = (name, "RH")
        if m["q"] is not None:
            line, = ax_q.plot(m["q"][0], z0, **_gray)
            pit_q.append((m, line));   model_lines[name].append(line);  _line_info[line] = (name, "q (g/kg)")
        if m["u"] is not None:
            line, = ax_u.plot(m["u"][0], z0, **_gray)
            pit_u.append((m, line));   model_lines[name].append(line);  _line_info[line] = (name, "u (m/s)")
        if m["clw"] is not None:
            line, = ax_clw.plot(m["clw"][0], z0, **_gray)
            pit_clw.append((m, line)); model_lines[name].append(line);  _line_info[line] = (name, "clw (mg/kg)")
        if m["cli"] is not None:
            line, = ax_cli.plot(m["cli"][0], z0, **_gray)
            pit_cli.append((m, line)); model_lines[name].append(line);  _line_info[line] = (name, "cli (mg/kg)")

    # ---- Clima lines (colored, bold) — y-axis is lev_km (fixed) -------------
    from matplotlib.lines import Line2D   # noqa: E402

    cline_T,   = ax_T.plot(c_T[0],     lev_km, color="tab:red",    lw=2.5, zorder=3, label="T (Clima)")
    cline_th,  = ax_T.plot(c_theta[0], lev_km, color="tab:blue",   lw=2.5, ls="--", zorder=3, label="θ (Clima)")
    cline_rh,  = ax_rh.plot(c_rh[0],   lev_km, color="tab:cyan",   lw=2.5, zorder=3, label="RH (Clima)")
    cline_q,   = ax_q.plot(c_q[0],     lev_km, color="tab:green",  lw=2.5, zorder=3, label="q (Clima)")
    cline_u,   = ax_u.plot(c_u[0],     lev_km, color="tab:orange", lw=2.5, zorder=3, label="u (Clima)")
    cline_clw, = ax_clw.plot(c_clw[0], lev_km, color="tab:blue",   lw=2.5, zorder=3, label="clw (Clima)")
    cline_cli, = ax_cli.plot(c_cli[0], lev_km, color="tab:purple", lw=2.5, zorder=3, label="cli (Clima)")

    for _cl, _vl in [(cline_T, "T (K)"), (cline_th, "θ (K)"), (cline_rh, "RH"),
                     (cline_q, "q (g/kg)"), (cline_u, "u (m/s)"),
                     (cline_clw, "clw (mg/kg)"), (cline_cli, "cli (mg/kg)")]:
        _line_info[_cl] = ("Clima", _vl)

    # ---- Legends -------------------------------------------------------------
    ens_handle = Line2D([0], [0], color="gray", lw=0.8, alpha=0.7,
                        label=f"Pithan 2016 ({len(pithan)} models)")
    ic_handle  = Line2D([0], [0], color="gray", lw=1, ls="--", alpha=0.6, label="IC")

    ax_T.legend(handles=[cline_T, cline_th, ens_handle, ic_handle],
                fontsize=7, loc="upper left")
    ax_rh.legend(handles=[cline_rh,  ens_handle], fontsize=7, loc="upper left")
    ax_q.legend(handles=[cline_q,    ens_handle], fontsize=7, loc="upper right")
    ax_u.legend(handles=[cline_u,    ens_handle], fontsize=7, loc="upper right")
    ax_clw.legend(handles=[cline_clw, ens_handle], fontsize=7, loc="upper right")
    ax_cli.legend(handles=[cline_cli, ens_handle], fontsize=7, loc="upper right")

    # ---- Title + slider ------------------------------------------------------
    title_obj = fig.suptitle(_time_label(0), fontsize=11)

    ax_slider = fig.add_axes((0.05, 0.04, 0.72, 0.025))
    slider = mwidgets.Slider(
        ax_slider, "Hour", 0, len(time_vals) - 1,
        valinit=0, valstep=1, color="steelblue",
    )
    slider.valtext.set_visible(False)

    def update(_val):
        i = int(slider.val)
        title_obj.set_text(_time_label(i))

        # Pithan lines: x = variable, y = height derived from pressure (time-varying)
        for m, line in pit_T:
            j = min(i, m["n_time"] - 1)
            line.set_xdata(m["T"][j]);     line.set_ydata(m["z_km"][j])
        for m, line in pit_th:
            j = min(i, m["n_time"] - 1)
            line.set_xdata(m["theta"][j]); line.set_ydata(m["z_km"][j])
        for m, line in pit_rh:
            j = min(i, m["n_time"] - 1)
            line.set_xdata(m["rh"][j]);    line.set_ydata(m["z_km"][j])
        for m, line in pit_q:
            j = min(i, m["n_time"] - 1)
            line.set_xdata(m["q"][j]);     line.set_ydata(m["z_km"][j])
        for m, line in pit_u:
            j = min(i, m["n_time"] - 1)
            line.set_xdata(m["u"][j]);     line.set_ydata(m["z_km"][j])
        for m, line in pit_clw:
            j = min(i, m["n_time"] - 1)
            line.set_xdata(m["clw"][j]);   line.set_ydata(m["z_km"][j])
        for m, line in pit_cli:
            j = min(i, m["n_time"] - 1)
            line.set_xdata(m["cli"][j]);   line.set_ydata(m["z_km"][j])

        # Clima lines: x = variable, y = lev_km (fixed — no set_ydata needed)
        cline_T.set_xdata(c_T[i])
        cline_th.set_xdata(c_theta[i])
        cline_rh.set_xdata(c_rh[i])
        cline_q.set_xdata(c_q[i])
        cline_u.set_xdata(c_u[i])
        cline_clw.set_xdata(c_clw[i])
        cline_cli.set_xdata(c_cli[i])

        fig.canvas.draw_idle()

    slider.on_changed(update)
    setattr(fig, "_slider_ref", slider)   # prevent GC

    # ---- CheckButtons: toggle individual Pithan models ----------------------
    ax_check = fig.add_axes((0.805, 0.32, 0.185, 0.56))
    ax_check.set_title("Pithan 2016", fontsize=8, pad=3)
    check_labels = [m["name"] for m in pithan]
    check = mwidgets.CheckButtons(
        ax_check, check_labels, actives=[True] * len(pithan),
    )
    for txt in check.labels:
        txt.set_fontsize(7)

    def toggle_model(label):
        for line in model_lines[label]:
            line.set_visible(not line.get_visible())
        fig.canvas.draw_idle()

    check.on_clicked(toggle_model)
    setattr(fig, "_check_ref", check)   # prevent GC

    # ---- RadioButtons: T / θ / both toggle ----------------------------------
    ax_tth = fig.add_axes((0.805, 0.21, 0.185, 0.10))
    ax_tth.set_title("Temperature panel", fontsize=8, pad=3)
    radio_tth = mwidgets.RadioButtons(ax_tth, ["T & θ", "T only", "θ only"], active=0)
    for lbl in radio_tth.labels:
        lbl.set_fontsize(7)

    _t_lines  = [cline_T,  ic_T_line]  + [l for _, l in pit_T]
    _th_lines = [cline_th, ic_th_line] + [l for _, l in pit_th]

    def set_tth(label):
        show_T  = label in ("T & θ", "T only")
        show_th = label in ("T & θ", "θ only")
        for ln in _t_lines:
            ln.set_visible(show_T)
        for ln in _th_lines:
            ln.set_visible(show_th)
        fig.canvas.draw_idle()

    radio_tth.on_clicked(set_tth)
    setattr(fig, "_radio_tth_ref", radio_tth)   # prevent GC

    # ---- RadioButtons: zoom y-axis to surface (0–1 km) ----------------------
    ylim_zoom = (0.0, 1.0)
    ax_radio = fig.add_axes((0.805, 0.06, 0.185, 0.13))
    ax_radio.set_title("Y-axis range", fontsize=8, pad=3)
    radio = mwidgets.RadioButtons(
        ax_radio, ["Full (0 – 9 km)", "0 – 1 km"], active=0,
    )
    for lbl in radio.labels:
        lbl.set_fontsize(7)

    def set_zoom(label):
        new_ylim = ylim_zoom if label == "0 – 1 km" else ylim
        ax_T.set_ylim(new_ylim)       # propagates to all panels via sharey
        ax_cli_r.set_ylim(new_ylim)   # twin pressure-axis updated separately
        fig.canvas.draw_idle()

    radio.on_clicked(set_zoom)
    setattr(fig, "_radio_ref", radio)   # prevent GC

    # ---- mplcursors hover ---------------------------------------------------
    cursor = mplcursors.cursor(list(_line_info.keys()), hover=2)

    @cursor.connect("add")
    def _on_hover(sel):
        display_name, var_label = _line_info.get(sel.artist, ("?", "?"))
        x_val, z_val = sel.target
        sel.annotation.set_text(
            f"{display_name}\n{var_label}: {x_val:.3g}\n{z_val:.2f} km"
        )
        sel.annotation.get_bbox_patch().set(
            fc="white", alpha=0.88, boxstyle="round,pad=0.3"
        )
        sel.annotation.set_fontsize(8)

    plt.show()


if __name__ == "__main__":
    main()
