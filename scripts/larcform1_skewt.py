"""
Skew-T log-P diagram for the Larcform1 initial condition profiles.
Uses MetPy for thermodynamic calculations and the SkewT plot class.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.lines as mlines
import metpy.calc as mpcalc
from metpy.plots import SkewT
from metpy.units import units

from larcform1_initial_profiles import (
    z_of_p, T_of_z, RH_of_z, u_geo_of_z
)

# ---------------------------------------------------------------------------
# Build profile on a pressure grid
# ---------------------------------------------------------------------------
p_hpa = np.arange(1013, 299, -1, dtype=float)   # hPa, surface → 300 hPa
p_pa  = p_hpa * 100.0
z     = z_of_p(p_pa)                             # m

T_K   = T_of_z(z)
RH    = RH_of_z(z)
u_ms  = u_geo_of_z(z)

# Dewpoint from RH + temperature (MetPy)
T_q   = T_K * units.kelvin
RH_q  = RH * units.dimensionless
Td_q  = mpcalc.dewpoint_from_relative_humidity(T_q, RH_q)

# Wind: geostrophic u only, v = 0
p_q   = p_hpa * units.hPa
u_q   = u_ms  * units("m/s")
v_q   = np.zeros_like(u_ms) * units("m/s")

# ---------------------------------------------------------------------------
# Plot
# ---------------------------------------------------------------------------
fig = plt.figure(figsize=(9, 11))
skew = SkewT(fig, rotation=45)

skew.plot(p_q, T_q.to("degC"),  "tab:red",  lw=2, label="Temperature")
skew.plot(p_q, Td_q,            "tab:green", lw=2, label="Dewpoint")

# Wind barbs every ~50 hPa to avoid clutter
stride = 50
skew.plot_barbs(p_q[::stride], u_q[::stride], v_q[::stride])

# Reference lines
dry_lines   = skew.plot_dry_adiabats(lw=0.8, alpha=0.5)
moist_lines = skew.plot_moist_adiabats(lw=0.8, alpha=0.4)
skew.plot_mixing_lines(lw=0.6, alpha=0.4)

skew.ax.set_xlim(-55, 10)           # °C — fits Arctic T range
skew.ax.set_ylim(1013, 300)
skew.ax.set_xlabel("Temperature (°C)")
skew.ax.set_ylabel("Pressure (hPa)")
skew.ax.set_title(
    "Larcform1 Initial Condition — Skew-T log-P\n"
    "Pithan et al. (2016),  80°N,  1 January",
    fontsize=11, fontweight="bold"
)

# Proxy artists for adiabats (LineCollection has no single label)
dry_proxy   = mlines.Line2D([], [], color=dry_lines.get_colors()[0],
                             lw=0.8, alpha=0.5, label="Dry adiabat")
moist_proxy = mlines.Line2D([], [], color=moist_lines.get_colors()[0],
                             lw=0.8, alpha=0.4, linestyle="--",
                             label="Moist adiabat")
skew.ax.legend(handles=[*skew.ax.get_legend_handles_labels()[0],
                         dry_proxy, moist_proxy],
               loc="upper left", fontsize=9)

plt.tight_layout()

if __name__ == "__main__":
    out = os.path.join(os.path.dirname(__file__), "..", "figures", "larcform1_skewt.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    fig.savefig(out, bbox_inches="tight", dpi=150)
    print(f"Saved to {out}")
