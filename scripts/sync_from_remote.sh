#!/usr/bin/env bash
# Pull output/ from remote workstation (stratus) to local machine.
# Also syncs ClimaAtmos.jl/output/ for standalone runs.
# Requires a 'stratus' Host entry in ~/.ssh/config.
set -e

REPO="stratus:~/clima/larcform1-experiments"
LOCAL="/Users/jeff/clima/larcform1-experiments"

rsync_opts="-avz --progress --links"

echo "Syncing coupled output..."
rsync $rsync_opts "$REPO/output/" "$LOCAL/output/"

echo "Syncing standalone ClimaAtmos output..."
rsync $rsync_opts "$REPO/ClimaAtmos.jl/output/" "$LOCAL/output/"

echo "Done."
