#!/usr/bin/env bash
# rsync the local working tree to stratus. This is the DEFAULT way to get code
# onto stratus for iterating on runs.
#
# It copies the working tree as-is, including uncommitted work, so a run
# launched right after a sync may not correspond to any commit. When you want a
# result traceable to an exact SHA, commit + push and use
# scripts/deploy_to_remote.sh (fetch + reset --hard) instead. Note that
# deploy_to_remote.sh reset --hard's over whatever this script left behind.
#
# Requires a 'stratus' Host entry in ~/.ssh/config.
set -euo pipefail

REMOTE="stratus:~/clima/larcform1-experiments/"
LOCAL="/Users/jeff/clima/larcform1-experiments/"

# A run in flight is reading these files; swapping them underneath it corrupts
# the run's provenance even when it doesn't crash.
# Match the process NAME, not the command line: a -f pattern also matches this
# very ssh command, whose argv contains the pattern text itself.
if ssh stratus 'pgrep -x julia >/dev/null'; then
  echo "ERROR: julia is running on stratus. Kill it before syncing:" >&2
  ssh stratus 'pgrep -ax julia' >&2
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
