"""
Nonlinear-dynamics view of the Larcform1 / Pithan (2016) Arctic single-column setup.

Framing note: each participating model -- and each ClimaAtmos configuration -- is its
OWN dynamical system (different governing physics / parameters). It is therefore not
meaningful to pool their trajectories into a single reconstructed vector field or a
single "potential well" (an earlier version did this; it has been removed). What IS
comparable across systems is each one's TRANSIENT: with insolation = 0 and advective
tendencies = 0 (Pithan sec. 2.2), the column has no shortwave input and no lateral
moisture/heat resupply, so its water budget is a ratchet -- it drifts one way, from a
cloudy / radiatively-coupled state toward a clear / decoupled state, and does not return.
The interesting quantity is how long each system lingers coupled before it drains.

Analyses:

  1. transience.png  -- per-run surface-net-LW trajectories (each its own system), and a
                        per-run "radiative coupling persistence time" (last hour with net
                        LW >= -20 W/m2, i.e. Pithan's clear/cloudy partition), compared
                        across three families: the Pithan ensemble, our microphysics
                        sweep, and our surface variants.
  2. bifurcation_subltime.png -- the one legitimately single-system view: settled state
                        vs the Wegener-Bergeron-Findeisen glaciation rate
                        (1 / sublimation_deposition_timescale) within one atmos config.
                        A saddle-node: the cloudy branch ceases to exist once deposition
                        is fast enough.
  nld_metrics.txt    -- per-run transience table + group summary + bifurcation table.

Run from repo root:
    python experiments/pithan-reproduction/scripts/nonlinear_dynamics.py
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

# --------------------------------------------------------------------------- paths
REPO  = Path(__file__).resolve().parents[3]
ENS   = REPO / "Pithan 2016 Intercomparison Data"
CONV  = REPO / "experiments/sea-ice/analysis/converted"
SLAB  = REPO / "experiments/20day run/output"
SWEEP = REPO / "experiments/clw sensitivity experiments/output/pithan_format"
FIG   = REPO / "experiments/pithan-reproduction/figures"

D1, D10 = 24, 240          # hourly indices for the days 1-10 window (Pithan analysis)
CLEAR_THR = -20.0          # W/m2, Pithan's clear/cloudy partition on surface net LW

# families and their plot colours
C_ENS, C_EC   = "#9a988f", "#c0392b"
C_MICRO, C_SURF = "#e08a1e", "#2a78d6"
SURFACE = "#fcfcfb"
plt.rcParams.update({
    "figure.facecolor": SURFACE, "axes.facecolor": SURFACE, "savefig.facecolor": SURFACE,
    "axes.edgecolor": "#c3c2b7", "axes.labelcolor": "#52514e", "axes.titlecolor": "#0b0b0b",
    "xtick.color": "#52514e", "ytick.color": "#52514e", "axes.grid": True,
    "grid.color": "#e6e5de", "grid.linewidth": 0.6, "axes.axisbelow": True,
    "axes.spines.top": False, "axes.spines.right": False,
    "font.family": "sans-serif", "font.size": 9, "legend.frameon": False,
})

# --------------------------------------------------------- reduced coordinates
def series(ds, v):
    da = ds[v]
    ex = [d for d in da.dims if d != "time" and ds.sizes[d] == 1]
    return np.asarray(da.squeeze(ex) if ex else da, dtype=float)

def netlw(ds):
    return series(ds, "rlds") + series(ds, "rlus")   # both Pithan positive-down

def lwp_gm2(ds):
    if "clwvi" in ds:
        return series(ds, "clwvi") * 1000.0
    return np.full(ds.sizes["time"], np.nan)

def _open(p):
    return xr.open_dataset(p, decode_times=False)

def load_systems():
    """Each run as its own system: (label, ds, family, colour). Excludes the known
    mis-registered-microphysics slab run (not a physically valid trajectory)."""
    systems = []
    for f in sorted(glob.glob(str(ENS / "*.nc"))):
        ds = _open(f)
        if "rlus" in ds and "rlds" in ds:
            name = os.path.basename(f)[:-3]
            systems.append((name, ds, "Pithan ensemble",
                            C_EC if "EC-Earth" in name else C_ENS))
    for f in sorted(glob.glob(str(CONV / "*.nc"))):
        systems.append((os.path.basename(f)[:-3], _open(f), "Clima surface", C_SURF))
    slab = SLAB / "ClimaLarcform1.nc"
    if slab.exists():
        systems.append(("ClimaLarcform1_slabocean", _open(slab), "Clima surface", C_SURF))
    for f in sorted(glob.glob(str(SWEEP / "v*.nc"))):
        systems.append((os.path.basename(f)[:-3], _open(f), "Clima microphysics", C_MICRO))
    return systems

# ============================================================================
# Analysis 1: per-run transience (net LW)
# ============================================================================
def _transience_metrics(nlw):
    """Given a net-LW time series (hourly), characterise the one-way transit.

    Returns dict with:
      n_init, n_final : mean net LW over first/last 24 h
      cloudy_frac     : fraction of the days 1-10 window coupled (net LW >= -20)
      persist_h       : last hour still radiatively coupled (net LW >= -20); the moment
                        the column finally drains. 0 => clear from the start.
      censored        : True if still coupled at the end of the run (persistently cloudy)
      cls             : 'persistently clear' | 'transient (drains)' | 'persistently cloudy'
    """
    n = len(nlw)
    coupled = nlw >= CLEAR_THR
    w = slice(D1, min(n, D10))
    cloudy_frac = float(np.nanmean(coupled[w])) if (w.stop > w.start) else np.nan
    idx = np.where(coupled)[0]
    if idx.size == 0:
        persist_h, censored, cls = 0.0, False, "persistently clear"
    else:
        persist_h = float(idx.max())          # last coupled hour
        censored = bool(idx.max() >= n - 24)  # still coupled in the final day
        cls = "persistently cloudy" if censored else "transient (drains)"
    return dict(n_init=float(np.nanmean(nlw[:24])), n_final=float(np.nanmean(nlw[-24:])),
                cloudy_frac=cloudy_frac, persist_h=persist_h, censored=censored, cls=cls,
                runlen_h=n)

def fig_transience(systems, log):
    fig, (axL, axR) = plt.subplots(1, 2, figsize=(13.2, 5.4), constrained_layout=True,
                                   gridspec_kw={"width_ratios": [1.7, 1.0]})
    families = ["Pithan ensemble", "Clima microphysics", "Clima surface"]
    fcol = {"Pithan ensemble": C_ENS, "Clima microphysics": C_MICRO, "Clima surface": C_SURF}
    rows = []
    # --- left: net LW(t) trajectories, each its own system
    for label, ds, fam, col in systems:
        nlw = netlw(ds)
        days = np.arange(len(nlw)) / 24.0
        hi = ("EC-Earth" in label)
        axL.plot(days, nlw, color=col, lw=(1.6 if hi else 0.8),
                 alpha=(0.95 if hi else 0.5), zorder=(3 if hi else 2))
        m = _transience_metrics(nlw)
        m["label"], m["fam"] = label, fam
        rows.append(m)
    axL.axhline(CLEAR_THR, color="#555", lw=0.9, ls=":")
    axL.axvline(10, color="#888", lw=0.7, ls="--")
    axL.text(10.1, axL.get_ylim()[1], "day 10", fontsize=7.5, color="#888", va="top")
    axL.text(0.3, CLEAR_THR + 1.5, "coupled / cloudy (net LW $\\geq$ -20)", fontsize=7.5, color="#555")
    axL.set_xlabel("time (days)"); axL.set_ylabel(r"surface net LW (W m$^{-2}$)")
    axL.set_title("Per-run transients: each model / config is its own system\n"
                  "(insolation=0, no advective resupply $\\Rightarrow$ one-way drift to clear)",
                  loc="left", fontsize=10)
    hL = [Line2D([], [], color=fcol[f], lw=2) for f in families] + \
         [Line2D([], [], color=C_EC, lw=2)]
    axL.legend(hL, families + ["EC-Earth (reference)"], fontsize=7.6, loc="lower left")

    # --- right: radiative-coupling persistence time per run, by family
    rng = np.random.default_rng(0)
    tmax_days = max(len(netlw(ds)) for _, ds, _, _ in systems) / 24.0
    famlen = {fam: max(r["runlen_h"] for r in rows if r["fam"] == fam) / 24.0
              for fam in families}
    for gi, fam in enumerate(families):
        grp = [r for r in rows if r["fam"] == fam]
        # runs are censored by their OWN length -- mark that length so a short (2-day)
        # sweep run is never mistaken for a long-lived cloud.
        rl = famlen[fam]
        if rl < tmax_days - 0.5:
            axR.plot([gi - 0.38, gi + 0.38], [rl, rl], color="#999", lw=1.0, ls=":", zorder=1)
            axR.text(gi + 0.4, rl, f"{rl:.0f}-day\nrun", fontsize=6.5, color="#999", va="center")
        xs = gi + (rng.random(len(grp)) - 0.5) * 0.5
        for x, r in zip(xs, grp):
            y = r["persist_h"] / 24.0
            if r["censored"]:
                axR.plot(x, y, marker="^", ms=9, color=fcol[fam],
                         mec="#0b0b0b", mew=0.6, zorder=4)   # still cloudy at run end
            else:
                axR.plot(x, y, "o", ms=7, color=fcol[fam], alpha=0.8, zorder=3)
        med = np.median([r["persist_h"] / 24.0 for r in grp]) if grp else np.nan
        axR.plot([gi - 0.32, gi + 0.32], [med, med], color="#0b0b0b", lw=2, zorder=5)
    axR.set_xticks(range(len(families)))
    axR.set_xticklabels(["Pithan\nensemble", "Clima\nmicrophysics", "Clima\nsurface"], fontsize=8)
    axR.set_ylabel("radiative-coupling persistence (days)\nlast day with net LW $\\geq$ -20")
    axR.set_ylim(-0.6, tmax_days + 0.6)
    axR.set_title("How long each system stays coupled\n"
                  "(bar = family median; $\\blacktriangle$ = still cloudy at run end / censored)",
                  loc="left", fontsize=10)
    out = FIG / "transience.png"
    fig.savefig(out, dpi=160); plt.close(fig)
    print("wrote", out)

    # --- log
    log.append("=" * 80)
    log.append("ANALYSIS 1 -- per-run transience (surface net LW; each run its own system)")
    log.append("=" * 80)
    log.append("CAVEAT: run lengths differ -- Pithan ensemble & Clima surface ~20 d, but the")
    log.append("Clima microphysics sweep is only 2 d. A '+' / triangle marks right-censoring")
    log.append("(still coupled at run end); censored persistence is a LOWER BOUND. Sweep runs")
    log.append("that drained within 2 d (persist < 2) are fully observed and directly comparable.")
    log.append("")
    log.append(f"{'run':30s} {'family':18s} {'init':>6s} {'final':>6s} {'cloudy%':>7s} "
               f"{'persist_d':>9s}  class")
    log.append("-" * 92)
    for r in sorted(rows, key=lambda r: (r["fam"], -r["persist_h"])):
        cf = "" if np.isnan(r["cloudy_frac"]) else f"{r['cloudy_frac']*100:6.0f}"
        pd = f"{r['persist_h']/24.0:8.2f}" + ("+" if r["censored"] else " ")
        log.append(f"{r['label'][:30]:30s} {r['fam']:18s} {r['n_init']:6.0f} {r['n_final']:6.0f} "
                   f"{cf:>7s} {pd:>9s}  {r['cls']}")
    log.append("")
    for fam in families:
        grp = [r for r in rows if r["fam"] == fam]
        if not grp:
            continue
        pers = np.array([r["persist_h"] / 24.0 for r in grp])
        ncl = sum(r["cls"] == "persistently clear" for r in grp)
        ntr = sum(r["cls"] == "transient (drains)" for r in grp)
        ncy = sum(r["cls"] == "persistently cloudy" for r in grp)
        log.append(f"{fam:18s} n={len(grp):2d}  persistence median={np.median(pers):.2f} d, "
                   f"range {pers.min():.2f}-{pers.max():.2f} d  "
                   f"[clear:{ncl} transient:{ntr} cloudy:{ncy}]")

# ============================================================================
# Analysis 2: saddle-node bifurcation (one atmos config, tau_subl varied)
# ============================================================================
TAU = {"v5_subltime10": 10.0, "v6_subltime400": 400.0, "v7_subltime1000": 1000.0,
       "v8_subltime10000": 1e4, "v12_subltime1e9": 1e9}
EXTRA = {"v1_base": ("base (default tau)", "#666666"),
         "v11_noicedep": ("deposition OFF (tau -> inf)", "#159a6b"),
         "v2_0M": ("0M microphysics", "#9d64c4"),
         "v10_tdepice": ("T-dependent INP (Frostenberg)", "#e08a1e"),
         "v4_cloudonly": ("precip processes OFF", "#c0392b")}

def _settled(ds):
    # sweep runs are only 48 h; average over the second half of whatever is available
    n = ds.sizes["time"]
    w = slice(min(D1, n // 2), min(n, D10))
    lwp = lwp_gm2(ds)[w]; nlw = netlw(ds)[w]
    return float(np.nanmean(lwp)), float(np.nanmean(nlw))

def fig_bifurcation(log):
    files = {os.path.basename(f)[:-3]: f for f in glob.glob(str(SWEEP / "v*.nc"))}
    fig, (axL, axR) = plt.subplots(1, 2, figsize=(12.5, 4.9), constrained_layout=True)
    taus, lwps, nlws = [], [], []
    for name, tau in sorted(TAU.items(), key=lambda kv: kv[1]):
        if name in files:
            lwp, nlw = _settled(_open(files[name]))
            taus.append(tau); lwps.append(lwp); nlws.append(nlw)
    taus, lwps, nlws = map(np.array, (taus, lwps, nlws))
    for ax, y, ylab in [(axL, lwps, "settled LWP (g m$^{-2}$), 2nd-half mean"),
                        (axR, nlws, "settled surface net LW (W m$^{-2}$)")]:
        ax.plot(taus, y, "-o", color="#2a78d6", lw=1.6, ms=7, zorder=3, label="tau_subl sweep")
        ax.set_xscale("log")
        ax.set_xlabel(r"sublimation/deposition timescale $\tau$ (s)  --  slow glaciation $\rightarrow$")
        ax.set_ylabel(ylab)
        for name, (lab, col) in EXTRA.items():
            if name in files:
                lwp, nlw = _settled(_open(files[name]))
                yv = lwp if ax is axL else nlw
                ax.plot(3e9 if "inf" in lab else 3.0, yv, "D", color=col, ms=8, zorder=4,
                        label=lab if ax is axL else None)
    axL.axvspan(1e4, 1e9, color="#c0392b", alpha=0.08, zorder=0)
    axL.annotate("cloudy branch\nceases to exist\n(saddle-node)", (10**6.5, np.nanmax(lwps) * 0.55),
                 ha="center", fontsize=8, color="#c0392b")
    axL.legend(fontsize=7.2, loc="center left")
    fig.suptitle("Single-system view: saddle-node bifurcation in one atmos config (48 h runs)\n"
                 "settled state vs the Wegener-Bergeron-Findeisen glaciation rate", fontsize=12)
    out = FIG / "bifurcation_subltime.png"
    fig.savefig(out, dpi=160); plt.close(fig)
    print("wrote", out)
    log.append("\n" + "=" * 80)
    log.append("ANALYSIS 2 -- saddle-node bifurcation vs sublimation/deposition timescale")
    log.append("=" * 80)
    for tau, lwp, nlw in zip(taus, lwps, nlws):
        log.append(f"  tau={tau:.0e} s   LWP={lwp:8.2f} g/m2   netLW={nlw:7.2f}   "
                   f"-> {'CLOUDY' if lwp > 10 else 'clear'}")
    ct, cy = taus[lwps <= 10], taus[lwps > 10]
    if ct.size and cy.size:
        log.append(f"\n  cloudy branch appears between tau = {ct.max():.0e} and {cy.min():.0e} s")
        log.append("  => the WBF deposition sink is the bifurcation parameter; faster than this")
        log.append("     threshold the cloudy fixed point is destroyed.")

def tier3_note(log):
    log.append("\n" + "=" * 80)
    log.append("FOLLOW-UP (needs new runs -- NOT computed here)")
    log.append("=" * 80)
    log.append("""
  A. Critical slowing down near the saddle-node. The transient framing predicts that a
     system's coupling-persistence time should DIVERGE as its glaciation rate approaches
     the bifurcation from the cloudy side (passage through a saddle-node 'ghost',
     persistence ~ (tau - tau_c)^(-1/2)). The current sweep only brackets tau_c between
     1e4 and 1e9 s. Add runs at tau in {3e4, 1e5, 3e5, 1e6} s to resolve the divergence
     and pin tau_c -- the per-run persistence metric here is exactly what to plot vs tau.

  B. Hysteresis loop: ramp tau_subl slowly up across tau_c and back down within one 20-day
     run; a gap between the up- and down-going cloud state = a subcritical transition.

  C. Basin-of-attraction map: at fixed (cloudy-capable) physics, sweep the INITIAL surface
     temperature and cloud loading to see which final state each initial condition reaches.
     Reuse AtmosphericProfilesLibrary.jl/src/profiles/Larcform1.jl.
""")

def main():
    FIG.mkdir(parents=True, exist_ok=True)
    systems = load_systems()
    n = {}
    for _, _, fam, _ in systems:
        n[fam] = n.get(fam, 0) + 1
    print("systems:", ", ".join(f"{k}={v}" for k, v in n.items()))
    log = []
    fig_transience(systems, log)
    fig_bifurcation(log)
    tier3_note(log)
    txt = "\n".join(log) + "\n"
    (FIG / "nld_metrics.txt").write_text(txt)
    print("wrote", FIG / "nld_metrics.txt")
    print("\n" + txt)

if __name__ == "__main__":
    main()
