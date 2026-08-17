---
name: feedback-agu-figure-guidelines
description: All plots in this project must follow AGU/JAMES figure guidelines — invoke /agu-figures skill before writing any plotting code
metadata:
  type: feedback
---

All figures produced in this project must follow AGU journal guidelines (JAMES submission target).

**Why:** The paper targets JAMES (an AGU journal). Only the paper figure (fig_lwp_const_vs_tdep) currently meets spec; all exploratory/analysis figures fail on DPI, format, fonts, panel labeling, and/or color accessibility. Catching these early avoids rework at submission.

**How to apply:** Before writing or modifying any plotting code, invoke the `/agu-figures` skill to load the full spec. Key requirements: 300+ dpi raster / 600 dpi line art, vector PDF output alongside PNG, Arial/Helvetica/Times fonts at 8 pt minimum, lowercase (a)/(b)/(c) panel labels, colorblind-safe palettes with marker/linestyle differentiation.
