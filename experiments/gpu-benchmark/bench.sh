#!/usr/bin/env bash
# Device benchmark driver for the calibrated Larcform1 SCM (sea ice + snow).
#
# Runs each device in its OWN julia process and wraps it in a wall clock, so the
# reported total is what a user actually waits for: process launch + package
# load + JIT/CUDA compilation + setup + time-stepping + I/O. Sharing one process
# across devices would amortise compilation away and flatter whichever device
# ran second — and compilation is precisely where CPU and CUDA differ most.
#
# Usage (from the repo root):
#   experiments/gpu-benchmark/bench.sh <t_end> <device-spec> [<device-spec> ...]
#
# A device-spec is LABEL:DEVICE:THREADS, e.g.
#   experiments/gpu-benchmark/bench.sh 20days \
#       stratus_cpu1:CPUSingleThreaded:1 \
#       stratus_cpu24:CPUMultiThreaded:24 \
#       stratus_a6000:CUDADevice:1
set -u

T_END="${1:?usage: bench.sh <t_end> <label:device:threads> ...}"
shift

if [[ ! -f Project.toml ]]; then
  echo "error: run from the repo root (no Project.toml here: $PWD)" >&2
  exit 1
fi

# On Stratus the Manifest requires the 1.12 channel (bare `julia` is 1.11.6 there
# and mass-fails precompile). Pass JULIA_CHANNEL=+1.12 on that host; leave it
# empty wherever the default julia already is 1.12.
JULIA="${JULIA:-julia}"
JULIA_CHANNEL="${JULIA_CHANNEL:-}"
LOGDIR="experiments/gpu-benchmark/results"
mkdir -p "$LOGDIR"
SUMMARY="$LOGDIR/summary_$(hostname -s)_${T_END}.txt"

echo "host=$(hostname -s)  t_end=$T_END  started=$(date -u +%FT%TZ)" | tee -a "$SUMMARY"

for spec in "$@"; do
  IFS=':' read -r LABEL DEVICE THREADS <<< "$spec"
  LOG="$LOGDIR/${LABEL}_${T_END}.log"

  echo "--- $LABEL  device=$DEVICE  threads=$THREADS ---" | tee -a "$SUMMARY"

  # Wall clock around the whole process = the honest "total run time".
  START=$(date +%s)
  set +e
  "$JULIA" ${JULIA_CHANNEL:+$JULIA_CHANNEL} -t "$THREADS" --project --startup-file=no \
    experiments/gpu-benchmark/run_device_benchmark.jl \
    --device "$DEVICE" --t-end "$T_END" --label "$LABEL" \
    >"$LOG" 2>&1
  RC=$?
  set -e
  END=$(date +%s)
  TOTAL=$((END - START))

  if [[ $RC -ne 0 ]]; then
    echo "  FAILED (rc=$RC) after ${TOTAL}s — see $LOG" | tee -a "$SUMMARY"
    echo "  $(grep -m1 -E 'ERROR|Error' "$LOG" | cut -c1-160)" | tee -a "$SUMMARY"
    continue
  fi

  # Pull the internal breakdown out of the julia log for context.
  SETUP=$(grep -o 't_setup_s = [0-9.]*' "$LOG" | tail -1 | awk '{print $3}')
  SOLVE=$(grep -o 't_solve_s = [0-9.]*' "$LOG" | tail -1 | awk '{print $3}')
  MSSTEP=$(grep -o 'ms_per_step = [0-9.]*' "$LOG" | tail -1 | awk '{print $3}')

  echo "  TOTAL(wall)=${TOTAL}s  setup(incl. JIT)=${SETUP}s  solve=${SOLVE}s  ${MSSTEP} ms/step" \
    | tee -a "$SUMMARY"
done

echo "finished=$(date -u +%FT%TZ)" | tee -a "$SUMMARY"
echo
echo "Summary written to $SUMMARY"
