#!/usr/bin/env bash
# Export a Jupyter notebook to PDF via nbconvert -> tectonic.
#
# We use tectonic (a self-contained XeTeX engine installed in the clenv conda
# env) instead of the Jupyter UI's one-click PDF export, which needs a binary
# literally named `xelatex` and skips two patches this notebook requires:
#   1. longtable's \LTcaptype{none} -> {table}  (newer longtable.sty errors on
#      the "none" counter that pandoc emits for caption-less markdown tables)
#   2. DejaVu fonts  (Latin Modern lacks Greek/math glyphs, so tau/chi/sigma/
#      approx silently drop out of the text)
#
# Usage: ./export_pdf.sh [notebook.ipynb]
#   defaults to lf1e-progress-report-1.ipynb in this folder.

set -euo pipefail

NB="${1:-lf1e-progress-report-1.ipynb}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

if [[ ! -f "$NB" ]]; then
  echo "error: notebook not found: $DIR/$NB" >&2
  exit 1
fi

BASE="${NB%.ipynb}"
TEX="$BASE.tex"

# Make sure jupyter/tectonic from clenv are on PATH even if run outside the env.
if ! command -v tectonic >/dev/null 2>&1; then
  # shellcheck disable=SC1091
  source "$(conda info --base)/etc/profile.d/conda.sh"
  conda activate clenv
fi

echo ">> nbconvert: $NB -> $TEX"
jupyter nbconvert --to latex "$NB"

echo ">> patching $TEX (longtable counter + DejaVu fonts)"
# 1. longtable counter
sed -i 's/\\def\\LTcaptype{none}/\\def\\LTcaptype{table}/g' "$TEX"
# 2. Unicode-capable fonts, injected right after unicode-math loads
sed -i '/\\usepackage{unicode-math}/a\        \\setmainfont{DejaVu Serif}\n        \\setsansfont{DejaVu Sans}\n        \\setmonofont{DejaVu Sans Mono}' "$TEX"

echo ">> tectonic: $TEX -> $BASE.pdf"
tectonic "$TEX"

echo ">> done: $DIR/$BASE.pdf"
