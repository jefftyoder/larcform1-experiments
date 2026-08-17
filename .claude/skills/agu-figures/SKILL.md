---
name: agu-figures
description: "AGU/JAMES figure guidelines: file format, resolution, sizing, fonts, panel labels, color accessibility. Load before writing any plotting code."
---

# AGU Figure Guidelines for JAMES

All figures in this project must be publication-ready for JAMES (AGU journal). Apply every requirement below when writing or modifying plotting code.

## File Format

- Save figures in **both PNG and PDF** (or EPS). Vector formats (PDF, EPS) are preferred for line art, graphs, and text.
- TIFF/JPEG acceptable for photographic content.

## Resolution

- **300 dpi minimum** for raster images (photographs, filled contours).
- **600 dpi** for line art (graphs, diagrams with thin lines and text).
- When saving PNG alongside PDF: `dpi=300` minimum.

## Figure Dimensions

- **One-column width:** 50--85 mm (2.0--3.35 in)
- **Two-column width:** 105--170 mm (4.13--6.69 in)
- **Maximum height:** 228 mm (8.98 in)
- Set `figsize` in inches to land within these ranges at final print size.

## Fonts

- **Allowed families:** Arial, Helvetica, Times, or Symbol only.
- **Minimum text size:** 8 pt at final printed size (subscripts/superscripts: 6 pt).
- Fonts must be embedded, outlined, or converted to curves.
- In matplotlib:
  ```python
  plt.rcParams.update({
      "font.family": "sans-serif",
      "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
      "font.size": 8,        # minimum baseline
  })
  ```
- In CairoMakie/Makie.jl: `set_theme!(fontsize=8, fonts=(regular="Arial",))`

## Panel Labeling

- Use **sequential lowercase letters**: (a), (b), (c) — not Arabic or Roman numerals.
- Place the label in the **top-left corner** of each panel.
- Multi-panel figures must be combined into **one figure file**.
- Example in matplotlib:
  ```python
  for i, ax in enumerate(axes.flat):
      ax.text(0.02, 0.95, f"({chr(97+i)})", transform=ax.transAxes,
              fontsize=8, fontweight="bold", va="top")
  ```

## Captions

- Captions and figure titles must **NOT** be included in figure files — they go in the manuscript text only.
- Avoid placing long descriptive titles inside the figure (suptitle). Brief axis labels and legend entries are fine.

## Color and Accessibility

- **Avoid** rainbow (jet) and red-green color palettes.
- Use **patterns, markers, or line styles in combination with color** so differentiation does not rely on color alone.
- Ensure **high contrast** between elements.
- Recommended colormaps: `viridis`, `cividis`, `plasma`, `inferno` (perceptually uniform, CVD-safe).
- For categorical series, use the project's validated palette (blue `#2a78d6`, orange `#eb6834`, gray `#898781`, ink `#0b0b0b`) with distinct line styles (solid, dashed, dotted, dash-dot) and/or markers.
- Test with a CVD simulator before finalizing.

## At Revision / Submission

- Figures must be uploaded as **individual files** (separate from manuscript).
- Number of figure files must equal number of figure captions.
- File names must match figure labels in the manuscript.

## Savefig Template (matplotlib)

```python
for ext in ("png", "pdf"):
    fig.savefig(
        outdir / f"figN_name.{ext}",
        dpi=300 if ext == "png" else None,
        bbox_inches="tight",
        facecolor="white",
    )
```

## Savefig Template (CairoMakie)

```julia
save(joinpath(outdir, "figN_name.png"), fig; px_per_unit=4)   # 4 * 72 ≈ 288 dpi
save(joinpath(outdir, "figN_name.pdf"), fig)
```

## Quick Checklist

- [ ] Format: PNG + PDF (or EPS)
- [ ] DPI: 300+ raster, 600 line art
- [ ] Width: 50--85 mm (1-col) or 105--170 mm (2-col)
- [ ] Height: under 228 mm
- [ ] Font: Arial/Helvetica/Times, 8 pt minimum
- [ ] Panels: lowercase (a), (b), (c) labels, top-left
- [ ] Colors: no rainbow/red-green; markers or line styles supplement color
- [ ] No caption or long title in figure file
- [ ] White background
- [ ] All text legible at final printed size

Sources:
- https://www.agu.org/publications/authors/journals/text-graphics-requirements
- https://www.agu.org/Publish-with-AGU/Publish/Author-Resources/Graphic-Requirements
- https://www.agu.org/-/media/files/publications/author_image_guidance_final.pdf
