#!/usr/bin/env bash
# Launch the extended (20-day) tau ladder in a detached tmux session on Stratus.
# Run ON stratus: bash "experiments/taudep sweep/launch_extend.sh" [extra run_sweep args...]
set -euo pipefail
export PATH=/home/yoder/.juliaup/bin:$PATH
cd /home/yoder/clima/larcform1-experiments
mkdir -p output/lf1e-taudep-1
tmux new-session -d -s lf1ext \
  "julia +1.12 -t 1 --startup-file=no --project=ClimaAtmos.jl/.buildkite 'experiments/taudep sweep/run_sweep.jl' extend $* 2>&1 | tee output/lf1e-taudep-1/extend_$(date +%Y%m%d_%H%M%S).log"
echo "launched tmux session lf1ext"
