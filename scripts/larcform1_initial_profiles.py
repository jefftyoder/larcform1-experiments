"""
Larcform1 initial condition profiles (Python port of AtmosphericProfilesLibrary.jl).

Reference: Pithan et al. (2016), JGR Atmospheres — SCM intercomparison for Arctic BL.

Saturation vapor pressure uses the Alduchov & Eskridge (1996) formula over liquid,
matching the Clausius-Clapeyron-based implementation in Thermodynamics.jl.
"""

import numpy as np
import matplotlib.pyplot as plt

# ---------------------------------------------------------------------------
# Constants (matching Larcform1.jl)
# ---------------------------------------------------------------------------
γ = 8e-3          # K/m  lapse rate
T_0 = 273.0       # K    surface temperature
P_0 = 101300.0    # Pa   surface pressure
g = 9.81          # m/s²
R_d = 287.0       # J/kg/K  dry air gas constant
R_v = 461.5       # J/kg/K  water vapor gas constant
ε = R_d / R_v     # ≈ 0.622

α = R_d * γ / g   # ≈ 0.2340  (Rγ/g, exponent in hypsometric T(z))

z_300hpa = 8457.614   # m  height of 300 hPa level
T_300hpa = T_0 - γ * z_300hpa   # K  temperature at 300 hPa

# ---------------------------------------------------------------------------
# Profile functions  z → scalar/array
# ---------------------------------------------------------------------------

def T_of_z(z):
    """Temperature [K] as a function of height [m]."""
    z = np.asarray(z, dtype=float)
    return np.where(z <= z_300hpa, T_0 - γ * z, T_300hpa)


def p_of_z(z):
    """Pressure [Pa] as a function of height [m]."""
    z = np.asarray(z, dtype=float)
    p_trop = P_0 * (1.0 - γ / T_0 * z) ** (1.0 / α)
    p_strat = 30000.0 * np.exp(-g / (R_d * T_300hpa) * (z - z_300hpa))
    return np.where(z <= z_300hpa, p_trop, p_strat)


def z_of_p(p):
    """Height [m] as a function of pressure [Pa]."""
    p = np.asarray(p, dtype=float)
    z_trop = T_0 / γ * (1.0 - (p / P_0) ** α)
    z_strat = z_300hpa - R_d * T_300hpa / g * np.log(p / 30000.0)
    return np.where(p >= 30000.0, z_trop, z_strat)


def e_sat_of_T(T):
    """
    Saturation vapor pressure [Pa] over liquid water.
    Alduchov & Eskridge (1996) — close match to Thermodynamics.jl.
    """
    T = np.asarray(T, dtype=float)
    T_c = T - 273.15
    return 611.21 * np.exp(17.502 * T_c / (240.97 + T_c))


def RH_of_z(z):
    """
    Relative humidity [0–1] as a function of height [m].
    Linear interpolation in pressure: RH = 0.8 at surface (1013 hPa),
    0.2 at 600 hPa and above, following Pithan 2016 / Larcform1.jl.
    Above z_300hpa: RH = 0.2 (constant).
    """
    z = np.asarray(z, dtype=float)
    p = p_of_z(z)
    # Control points in Pa (ascending pressure = descending height)
    p_pts = np.array([0.0, 60000.0, 101300.0])
    RH_pts = np.array([0.2,   0.2,      0.8])
    RH_raw = np.interp(p, p_pts, RH_pts)
    return np.where(z <= z_300hpa, RH_raw, 0.2)


def q_tot_of_z(z):
    """
    Total specific humidity [kg/kg] as a function of height [m].
    Derived from RH over liquid via saturation vapor pressure.
    Above z_300hpa: q_tot = 3e-6 kg/kg (Larcform1.jl constant).
    """
    z = np.asarray(z, dtype=float)
    p = p_of_z(z)
    T = T_of_z(z)
    RH = RH_of_z(z)
    e_sat = e_sat_of_T(T)
    e = RH * e_sat
    # specific humidity from partial pressure
    q = ε * e / (p - (1 - ε) * e)
    return np.where(z <= z_300hpa, q, 3e-6)


def theta_of_z(z):
    """Potential temperature [K]."""
    return T_of_z(z) * (P_0 / p_of_z(z)) ** (R_d / 1004.0)


def u_geo_of_z(z):
    """Geostrophic zonal wind [m/s]: 5 m/s below 300 hPa, 0 above."""
    z = np.asarray(z, dtype=float)
    return np.where(z <= z_300hpa, 5.0, 0.0)


# ---------------------------------------------------------------------------
# Plotting
# ---------------------------------------------------------------------------

def plot_profiles(z_max=9000.0, n=500, save_path=None):
    z = np.linspace(0, z_max, n)
    z_km = z / 1e3

    T = T_of_z(z)
    θ = theta_of_z(z)
    RH = RH_of_z(z)
    q = q_tot_of_z(z) * 1e3  # g/kg for display
    u = u_geo_of_z(z)

    # Pressure levels for right-axis ticks
    p_ticks_hpa = np.array([1000, 850, 700, 500, 400, 300])
    z_at_p_ticks = z_of_p(p_ticks_hpa * 100.0) / 1e3  # km

    S = 1.3  # thickness scaling
    lw = 2 * S

    fig, axes = plt.subplots(1, 4, sharey=True, figsize=(14, 6))
    fig.subplots_adjust(wspace=0.15)

    def _style_ax(ax, xlabel, title):
        ax.set_xlabel(xlabel, fontsize=10 * S)
        ax.set_title(title, fontsize=10 * S, fontweight="bold")
        ax.set_ylim(0, z_max / 1e3)
        ax.grid(True, linestyle=":", alpha=0.5, linewidth=0.6 * S)
        ax.tick_params(which="both", direction="in", width=0.8 * S, length=4 * S,
                       labelsize=8 * S)
        for spine in ax.spines.values():
            spine.set_linewidth(0.8 * S)

    ax0, ax1, ax2, ax3 = axes

    _style_ax(ax0, "T, θ  (K)", "Temperature")
    ax0.set_ylabel("Height (km)", fontsize=10 * S)
    ax0.plot(T, z_km, color="tab:red",  lw=lw, label="T")
    ax0.plot(θ, z_km, color="tab:blue", lw=lw, label="θ", linestyle="--")
    ax0.legend(fontsize=8 * S)

    _style_ax(ax1, "RH  (–)", "Relative Humidity")
    ax1.plot(RH, z_km, color="tab:cyan", lw=lw)
    ax1.set_xlim(0, 1)

    _style_ax(ax2, "q  (g kg⁻¹)", "Specific Humidity")
    ax2.plot(q, z_km, color="tab:green", lw=lw)

    _style_ax(ax3, "u  (m s⁻¹)", "Geostrophic Wind")
    ax3.plot(u, z_km, color="tab:orange", lw=lw)
    ax3.set_xlim(-1, 7)

    # Pressure right axis — only on the rightmost panel
    ax3_r = ax3.twinx()
    ax3_r.set_ylim(ax3.get_ylim())
    ax3_r.set_yticks(z_at_p_ticks)
    ax3_r.set_yticklabels([f"{int(p)}" for p in p_ticks_hpa], fontsize=8 * S)
    ax3_r.set_ylabel("Pressure (hPa)", fontsize=10 * S)
    ax3_r.tick_params(which="both", direction="in", width=0.8 * S, length=4 * S)
    for spine in ax3_r.spines.values():
        spine.set_linewidth(0.8 * S)

    fig.suptitle("Larcform1 Initial Condition Profiles  (Pithan 2016)", y=1.01)

    if save_path:
        fig.savefig(save_path, bbox_inches="tight", dpi=150)
        print(f"Saved to {save_path}")
    else:
        plt.show()

    return fig


if __name__ == "__main__":
    import os
    out = os.path.join(os.path.dirname(__file__), "..", "figures", "larcform1_profiles_python.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    plot_profiles(save_path=out)
