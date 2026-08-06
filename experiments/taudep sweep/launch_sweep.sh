#!/usr/bin/env bash
# Launch the full sweep in a detached tmux session on Stratus.
# Run ON stratus: bash "experiments/taudep sweep/launch_sweep.sh" <z_elem> [extra run_sweep args...]
set -euo pipefail
Z_ELEM="${1:?usage: launch_sweep.sh <z_elem> [extra args]}"
shift || true
export PATH=/home/yoder/.juliaup/bin:$PATH
cd /home/yoder/clima/larcform1-experiments
mkdir -p output/lf1e-taudep-1
tmux new-session -d -s lf1sweep \
  "julia +1.12 -t 1 --project=ClimaAtmos.jl/.buildkite 'experiments/taudep sweep/run_sweep.jl' sweep --z_elem $Z_ELEM $* 2>&1 | tee output/lf1e-taudep-1/sweep_$(date +%Y%m%d_%H%M%S).log"
echo "launched tmux session lf1sweep (z_elem=$Z_ELEM)"
