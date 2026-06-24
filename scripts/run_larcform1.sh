#!/usr/bin/env bash
# Run a Larcform1 ClimaAtmos simulation and convert output to Pithan2016 format.
#
# Usage (run from ClimaAtmos.jl directory):
#   bash /path/to/run_larcform1.sh [OPTIONS]
#
# Options:
#   --job-id ID          Config base name (default: larcform1_1M_prognostic_edmfx)
#   --model-name NAME    Model name in the output NetCDF (default: derived from job-id)
#   --dest DIR           Destination for Pithan-format NetCDF (default: ~/clima/Pithan2016_Data/my_analysis/data)
#   --suffix SUFFIX      nc file averaging suffix (default: 1h_average)
#   --skip-sim           Skip the simulation; just convert the latest existing output
#
# Examples:
#   bash scripts/run_larcform1.sh
#   bash scripts/run_larcform1.sh --job-id larcform1_eisenman_1M_prognostic_edmfx --model-name ClimaEisenman
#   bash scripts/run_larcform1.sh --skip-sim --job-id larcform1_eisenman_1M_prognostic_edmfx

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONVERT_SCRIPT="$SCRIPT_DIR/convert_to_pithan.py"

# ---------- defaults ----------
JOB_ID="larcform1_1M_prognostic_edmfx"
MODEL_NAME=""
DEST="${HOME}/clima/Pithan2016_Data/my_analysis/data"
SUFFIX="1h_average"
SKIP_SIM=0

# ---------- parse args ----------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --job-id)       JOB_ID="$2";     shift 2 ;;
        --model-name)   MODEL_NAME="$2"; shift 2 ;;
        --dest)         DEST="$2";       shift 2 ;;
        --suffix)       SUFFIX="$2";     shift 2 ;;
        --skip-sim)     SKIP_SIM=1;      shift   ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Derive model name from job-id if not set:
#   larcform1_eisenman_1M_prognostic_edmfx  ->  ClimaEisenman
#   larcform1_1M_prognostic_edmfx           ->  ClimaLarcform1
if [[ -z "$MODEL_NAME" ]]; then
    if [[ "$JOB_ID" == *eisenman* ]]; then
        MODEL_NAME="ClimaEisenman"
    else
        MODEL_NAME="ClimaLarcform1"
    fi
fi

# ---------- run simulation ----------
if [[ "$SKIP_SIM" -eq 0 ]]; then
    CONFIG_PATH="config/model_configs"
    echo "==> Running simulation: $JOB_ID"
    julia --color=yes --project=.buildkite .buildkite/ci_driver.jl \
        --config_file "${CONFIG_PATH}/${JOB_ID}.yml" \
        --job_id "$JOB_ID"
fi

# ---------- find latest output ----------
OUTPUT_ROOT="output/${JOB_ID}"
if [[ ! -d "$OUTPUT_ROOT" ]]; then
    echo "ERROR: Output directory not found: $OUTPUT_ROOT" >&2
    exit 1
fi

OUT_DIR=$(ls -d "${OUTPUT_ROOT}"/output_* 2>/dev/null | sort | tail -1)
if [[ -z "$OUT_DIR" ]]; then
    echo "ERROR: No output_NNNN directories found under $OUTPUT_ROOT" >&2
    exit 1
fi
# Resolve symlinks so convert_to_pithan.py gets a real absolute path
OUT_DIR=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$OUT_DIR")
echo "==> Using output directory: $OUT_DIR"

# ---------- extract nc files ----------
if [[ ! -f "$OUT_DIR/ta_${SUFFIX}.nc" ]]; then
    if [[ -f "$OUT_DIR/nc_files.tar" ]]; then
        echo "==> Extracting nc_files.tar"
        tar xf "$OUT_DIR/nc_files.tar" -C "$OUT_DIR"
    else
        echo "ERROR: No .nc files and no nc_files.tar in $OUT_DIR" >&2
        exit 1
    fi
fi

# ---------- convert to Pithan format ----------
mkdir -p "$DEST"
OUT_NC="$DEST/${MODEL_NAME}.nc"
echo "==> Converting to Pithan format -> $OUT_NC"
conda run -n clenv python "$CONVERT_SCRIPT" \
    --nc-dir "$OUT_DIR" \
    --suffix "$SUFFIX" \
    --model-name "$MODEL_NAME" \
    --out "$OUT_NC"

echo "==> Done: $OUT_NC"
