#!/usr/bin/env bash
# Launch the coupled 2D tau sweep in a detached tmux session on Stratus.
# Run ON stratus: bash "experiments/taudep sweep coupled 2d/launch_sweep.sh" [extra run_sweep args...]
set -euo pipefail
export PATH=/home/yoder/.juliaup/bin:$PATH
cd /home/yoder/clima/larcform1-experiments
mkdir -p output/lf1e-taudep-1-coupled-2d
tmux new-session -d -s lf1sweep2d \
  "julia +1.12 -t 1 --startup-file=no --project 'experiments/taudep sweep coupled 2d/run_sweep.jl' sweep --z_elem 60 $* 2>&1 | tee output/lf1e-taudep-1-coupled-2d/sweep_$(date +%Y%m%d_%H%M%S).log"
echo "launched tmux session lf1sweep2d (2D coupled sweep)"
