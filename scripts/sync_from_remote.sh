#!/usr/bin/env bash
# Pull output/ from remote workstation (stratus) to local machine.
# Requires a 'stratus' Host entry in ~/.ssh/config.
set -e

REMOTE="stratus:~/clima/larcform1-experiments/output/"
LOCAL="/Users/jeff/clima/larcform1-experiments/output/"

echo "Syncing from remote: $REMOTE"
rsync -avz --progress \
  "$REMOTE" "$LOCAL"
echo "Done."
