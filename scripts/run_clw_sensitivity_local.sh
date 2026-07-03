#!/usr/bin/env bash
# Run all 9 clw-sensitivity-experiment-1 variations sequentially, in one persistent Julia
# process, on this machine. See:
#   experiments/clw sensitivity experiments/lf1e-clw-sensitivity-experiment-1.md
#   ("Local sequential execution" under "Running the Simulations")
#
# Why sequential, one process: this machine (16 GB RAM) cannot safely run more than one
# ClimaAtmos process at a time (a second concurrent process pushed swap to 12+ GB in
# testing) — so "batch" here means one variation after another, not in parallel. Running
# all 9 through a single `run_batch.jl` invocation still amortizes the ~9-10 min
# package-load/JIT cost across the whole set instead of paying it 9 times.
#
# Usage (run from the larcform1-experiments repo root):
#   bash scripts/run_clw_sensitivity_local.sh
#
# To run unattended/detached instead of blocking this shell:
#   nohup bash scripts/run_clw_sensitivity_local.sh > /dev/null 2>&1 &
#
# Each variation's `t_end` is 2 days (unchanged from the base config) — this is a
# screening run, not the full 20-day Pithan protocol run. Expected total wall time:
# roughly 30-40 minutes (~9-10 min fixed cost, paid once, plus ~9 x a few minutes of
# solve + per-type recompile). `run_batch.jl` keeps going after a crashed variation
# (e.g. the expected instability in v3_2M) and prints a `=== Batch summary ===` at the end.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

EXPERIMENT_DIR="experiments/clw sensitivity experiments"
CONFIG_DIR="$EXPERIMENT_DIR/configs"
RUN_BATCH="$EXPERIMENT_DIR/run_batch.jl"
# Same lf1e-clw-1 tree each variation's own `output_dir:` writes into (see the config
# files) — kept together so the driver log sits next to the simulation output it describes.
OUTPUT_LOG_DIR="$EXPERIMENT_DIR/output/lf1e-clw-1"

CONFIGS=(
  "$CONFIG_DIR/v1_base.yml"
  "$CONFIG_DIR/v2_0M.yml"
  "$CONFIG_DIR/v3_2M.yml"
  "$CONFIG_DIR/v4_cloudonly.yml"
  "$CONFIG_DIR/v5_subltime10.yml"
  "$CONFIG_DIR/v6_subltime400.yml"
  "$CONFIG_DIR/v7_subltime1000.yml"
  "$CONFIG_DIR/v8_subltime10000.yml"
  "$CONFIG_DIR/v9_condtime10.yml"
)

# Fail fast and clearly if setup is missing, rather than letting Julia error out after
# paying the multi-minute package-load cost first.
if [[ ! -f "$RUN_BATCH" ]]; then
  echo "ERROR: driver not found: $RUN_BATCH" >&2
  exit 1
fi
for cfg in "${CONFIGS[@]}"; do
  if [[ ! -f "$cfg" ]]; then
    echo "ERROR: config not found: $cfg" >&2
    exit 1
  fi
done

mkdir -p "$OUTPUT_LOG_DIR"
LOG_FILE="$OUTPUT_LOG_DIR/local_run_$(date +%Y%m%d_%H%M%S).log"

echo "==> Running ${#CONFIGS[@]} variations sequentially (one Julia process, -t 1)"
echo "==> Log: $LOG_FILE"

# run_batch.jl already times each variation and the whole batch internally (see its
# "=== Batch summary ===" block); this `time` wraps the whole process from the shell's
# side too, as an independent cross-check that also captures any overhead outside Julia's
# own timers (e.g. process startup before Julia's first log line).
TIMEFORMAT=$'\n==> Shell-side total wall time: %lR (user %lU, sys %lS)'
{ time julia -t 1 --project=ClimaAtmos.jl/.buildkite "$RUN_BATCH" "${CONFIGS[@]}"; } 2>&1 | tee "$LOG_FILE"

echo "==> Done. Full log at: $LOG_FILE"
echo "==> Grep for the summary: grep -A 20 'Batch summary' \"$LOG_FILE\""
