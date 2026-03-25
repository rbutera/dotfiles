# pipewire config changes log

## 2026-03-25 — Remove unused virtual sinks

### Problem
`00-virtual-sinks.conf` defined five virtual sinks (Router, Games, Media, Voice,
Master) and one virtual source (MicrophoneFX). Only Master (output) and
MicrophoneFX (input) are needed.

### Solution
Commented out the Router, Games, Media, and Voice sink blocks in
`dot_config/pipewire/pipewire.conf.d/00-virtual-sinks.conf`. Master and
MicrophoneFX are unchanged.

Requires `systemctl --user restart pipewire pipewire-pulse wireplumber` to
remove the now-unused sinks from the running session.
