#!/usr/bin/env bash
# Poll the lf1pilot tmux session on Stratus; emit progress/error lines; exit when it ends.
# Used by the local monitoring loop; safe to delete after the experiment.
SESSION="${1:-lf1pilot}"
prev=""
while true; do
  if ! ssh -o ConnectTimeout=10 -o BatchMode=yes stratus "tmux has-session -t $SESSION 2>/dev/null"; then
    echo "$SESSION tmux session ended; final log tail:"
    ssh -o BatchMode=yes stratus "tail -60 \"\$(ls -t /home/yoder/clima/larcform1-experiments/output/lf1e-taudep-1/*.log | head -1)\"" 2>/dev/null \
      | grep -E "Finished member|ret_code|===|^z[0-9]+:|Adopt|Error|ERROR|FAIL|PASS|Refinement"
    exit 0
  fi
  cur=$(ssh -o BatchMode=yes stratus "tmux capture-pane -pt $SESSION -S -300 -p" 2>/dev/null \
    | grep -E "Starting member|Finished member|LoadError|ERROR:|=== Grid pilot|=== Discriminator|Adopt the coarsest|: PASS|: FAIL|RUN FAILED|Refinement converged|Final sweep summary" \
    | tail -40)
  if [ -n "$cur" ] && [ "$cur" != "$prev" ]; then
    comm -13 <(echo "$prev") <(echo "$cur") 2>/dev/null | head -12
    prev="$cur"
  fi
  sleep 60
done
