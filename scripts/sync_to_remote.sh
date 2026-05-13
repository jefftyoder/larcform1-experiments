#!/usr/bin/env bash
# Push local larcform1-experiments repo to remote workstation (stratus),
# excluding output data and logs.
# Requires a 'stratus' Host entry in ~/.ssh/config.
set -e

REMOTE="stratus:~/clima/larcform1-experiments/"
LOCAL="/Users/jeff/clima/larcform1-experiments/"

# Ensure remote parent directory exists (idempotent).
ssh stratus 'mkdir -p ~/clima/larcform1-experiments'

echo "Syncing to remote: $REMOTE"
rsync -avz --progress \
  --exclude='output/' \
  --exclude='*.nc' \
  --exclude='*.log' \
  "$LOCAL" "$REMOTE"
echo "Done."
