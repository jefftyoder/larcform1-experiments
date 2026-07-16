---
name: stratus-vpn-times-out
description: "Stratus (stratus.rd.unr.edu) is only reachable over Jeff's VPN, which times out on its own and needs manual reconnection"
metadata: 
  node_type: memory
  type: user
  originSessionId: fb5b1f8a-ea7c-4d19-92ec-3c9b2940ded8
---

Stratus (`ssh stratus` → stratus.rd.unr.edu, UNR campus) is reachable only while Jeff's VPN is up. The VPN **times out on its own** and Jeff must manually reconnect — he has asked (2026-07-09) to be told when it drops.

**How to apply:** When an ssh/rsync to stratus fails with "Could not resolve hostname" (while general internet works), it's the VPN — tell Jeff immediately and ask him to reconnect rather than silently retrying. Launch all long-running remote work detached in tmux so a drop never kills it; only monitoring pauses. A background probe loop (`until ssh -o BatchMode=yes stratus 'echo back'; do sleep 60; done`) works well for resuming after reconnection.
