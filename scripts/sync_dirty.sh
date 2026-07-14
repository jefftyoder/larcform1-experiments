#!/usr/bin/env bash
# ESCAPE HATCH: rsync a DIRTY working tree to stratus for scratch iteration.
#
# Use scripts/deploy_to_remote.sh instead for anything whose output you might
# keep. This script copies uncommitted work, so a run launched after it cannot
# be traced to a commit -- the code that produced the numbers exists only on
# this laptop. Fine for poking at a parameter; not fine for a result.
#
# Leaves stratus's git checkout dirty/divergent; deploy_to_remote.sh will
# reset --hard over it, which is the intended way back to a known state.
#
# Requires a 'stratus' Host entry in ~/.ssh/config.
set -euo pipefail

REMOTE="stratus:~/clima/larcform1-experiments/"
LOCAL="/Users/jeff/clima/larcform1-experiments/"

# A run in flight is reading these files; swapping them underneath it corrupts
# the run's provenance even when it doesn't crash.
if ssh stratus "pgrep -f '[j]ulia.*--project' >/dev/null"; then
  echo "ERROR: julia is running on stratus. Kill it before syncing:" >&2
  ssh stratus "pgrep -alf '[j]ulia.*--project'" >&2
  exit 1
fi

# Ensure remote parent directory exists (idempotent).
ssh stratus 'mkdir -p ~/clima/larcform1-experiments'

echo "Syncing to remote: $REMOTE"
rsync -avz --progress \
  --exclude='output/' \
  --exclude='*.nc' \
  --exclude='*.log' \
  "$LOCAL" "$REMOTE"
echo "Done."
