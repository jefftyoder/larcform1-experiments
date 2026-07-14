#!/usr/bin/env bash
# Deploy larcform1-experiments to stratus by pulling from git.
#
# This is the DEFAULT way to get code onto stratus. Every run is then traceable
# to an exact commit SHA, which rsync cannot give you. Uncommitted work does not
# travel -- commit and push first, or use sync_dirty.sh for scratch iteration.
#
# Requires a 'stratus' Host entry in ~/.ssh/config.
set -euo pipefail

REMOTE_DIR="~/clima/larcform1-experiments"
BRANCH="${1:-main}"

# Refuse to deploy code that isn't on the remote yet: stratus pulls from origin,
# so anything uncommitted or unpushed would silently not arrive.
if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  echo "ERROR: working tree has uncommitted changes to tracked files." >&2
  echo "       Commit and push, or use scripts/sync_dirty.sh for scratch work." >&2
  git status --short --untracked-files=no >&2
  exit 1
fi
if [[ -n "$(git log --oneline "origin/${BRANCH}..${BRANCH}" 2>/dev/null)" ]]; then
  echo "ERROR: local ${BRANCH} has commits not pushed to origin:" >&2
  git log --oneline "origin/${BRANCH}..${BRANCH}" >&2
  exit 1
fi

echo "Deploying ${BRANCH} to stratus:${REMOTE_DIR}"

ssh stratus "
  set -euo pipefail
  cd ${REMOTE_DIR}

  # A run in flight is reading these files; swapping them underneath it
  # corrupts the run's provenance even when it doesn't crash.
  # Match the process NAME, not the command line: a -f pattern also matches
  # this very ssh command, whose argv contains the pattern text itself.
  if pgrep -x julia >/dev/null; then
    echo 'ERROR: julia is running on stratus. Kill it before deploying:' >&2
    pgrep -ax julia >&2
    exit 1
  fi

  git fetch origin --prune
  git checkout ${BRANCH}
  git reset --hard origin/${BRANCH}
  git submodule update --init --recursive

  echo '--- deployed ---'
  echo \"lf1e:       \$(git rev-parse --short HEAD)  \$(git log -1 --format=%s)\"
  cd ClimaAtmos.jl
  echo \"ClimaAtmos: \$(git rev-parse --short HEAD)  \$(git log -1 --format=%s)\"
"

echo "Done."
