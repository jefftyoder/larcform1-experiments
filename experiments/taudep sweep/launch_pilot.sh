#!/usr/bin/env bash
# Launch the grid pilot in a detached tmux session on Stratus.
# Run ON stratus: bash "experiments/taudep sweep/launch_pilot.sh"
set -euo pipefail
export PATH=/home/yoder/.juliaup/bin:$PATH
cd /home/yoder/clima/larcform1-experiments
mkdir -p output/lf1e-taudep-1
tmux new-session -d -s lf1pilot \
  "julia +1.12 -t 1 --startup-file=no --project=ClimaAtmos.jl/.buildkite 'experiments/taudep sweep/run_sweep.jl' pilot 2>&1 | tee output/lf1e-taudep-1/pilot_$(date +%Y%m%d_%H%M%S).log"
echo "launched tmux session lf1pilot"
