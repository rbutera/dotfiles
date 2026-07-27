# Display / KVM changes log

## 2026-07-27 — Fix post-reboot blanking on the glkvm-fed Dell (pin the mode at login)

### Motivation
The Dell fed through the GL.iNet KVM kept blanking for about a second and coming back,
repeatedly, after this morning's reboot. Rai's framing was important and correct: **not a
cable**, and it had been stopped before but returned after this reboot — i.e. whatever
fixed it was applied by hand and nothing re-applied it.

### Investigation
Ruled out, with evidence, in this order:

**Not the agent.** No display/resolution/colour calls were made, no computer-use ran, and
`WindowServer` was pid 467 up 02:12:21 — never restarted.

**Not macOS.** 30 minutes of `log show` contained no framebuffer power-state change, no
display attach/detach, no `CGDisplay` reconfiguration, and no graphics driver error. An
initial theory that `RTBuddy(DCPEXT0/1)` messages were display-coprocessor resets was
**wrong** — they arrive at an exact 10-minute cadence (10:17, 10:27, 10:37) and are
routine OSLog segment rotation. Retracted.

**It is the KVM**, confirmed by sshing in as Rai asked (`glkvm`, 100.78.184.67, GL-RM1
"Comet", Buildroot `rmq1-1.8.1-beta1`, a kvmd + ustreamer stack). Its kernel log names the
mechanism outright:

```
lt6911c    1-002b: 0xD211 is ff                     <- HDMI receiver loses lock
lt86102sxe 3-0038: Sending HDMI disconnect event    <- output chip drops HPD
lt86102sxe 3-0038: Sending HDMI connect event       <- ...and re-asserts it
```

`lt6911c` is the HDMI receiver; `lt86102sxe` is the output chip feeding the Dell (the
pipeline has a real VO path — `vpss grp[0] chn[2] init ok (for Vo)`). **Every
disconnect/connect pair is one blank-and-return on the physical monitor.**

Converting kernel timestamps to wall clock gave the whole story:

```
08:06–08:20   Mac shutting down / off -> no signal -> 0xD211 reads 0xff
08:21         Mac boots
08:21–08:42   mode flaps 1920x1080@60 <-> 3840x2160@30, one plainly corrupt read
              ("1920x1080@16 fps, htotal=131070"), four HPD disconnect/connect pairs
08:42:13      0xD211 reads 0 — lock acquired
08:42:17      settles at 3840x2160@30, stable for hours afterwards
```

So it is a **boot-time HDMI negotiation storm that self-resolves after ~20 minutes**, not
a persistent fault. Rai independently confirmed mid-investigation that he had not noticed
it in a while, which matches the 08:42 settle exactly.

Two red herrings worth recording so they are not re-investigated:
- **KVM load average ~10** looks alarming but is cosmetic: exactly 9 video-pipeline
  threads (`vlog valloc valloc vsys vrga_0 vvi_thread vpss vrgn venc`) sit permanently in
  D state, and loadavg counts them. CPU was only ~15% across 4 cores.
- **ustreamer restarts** — only one, at 10:28. Not a restart loop.

A differential `dmesg` watch (mark buffer, wait 100s, diff) produced **zero** new kernel
lines, confirming the KVM is quiet now rather than actively flapping.

30Hz on that panel is an **accepted limitation** (Rai, 2026-07-27), not a bug: the KVM's
EDID advertises nothing better at native 4K, and the only >30Hz mode displayplacer offers
for it is `1080x1920@60`. The goal was the blanking, not the refresh rate.

### Changes
**`bin/executable_pin-displays`** (new) — pins the three-display layout via
`displayplacer` so the KVM output never renegotiates. Two deliberate properties:
- **Self-gating.** Exits 0 quietly unless all three of kinto's persistent screen ids are
  present, so the agent is harmless on latios or nimbus. Waits up to 120s for displays to
  attach, since post-reboot they arrive over several seconds and applying a layout that
  references a missing id produces a wrong arrangement.
- **Idempotent.** Re-applying a layout itself forces a mode set, which blanks the screen —
  the exact thing being fixed. It reads the KVM panel's current mode and does nothing if
  it is already `2160x3840@30`.

**`Library/LaunchAgents/com.rai.pin-displays.plist.tmpl`** (new) — `RunAtLoad` at login,
`KeepAlive` false (one-shot, not a daemon; the wrapper does its own bounded wait).

### Verification
```
plutil -lint ...com.rai.pin-displays.plist   # OK
/bin/sh -n ~/bin/pin-displays                # OK
~/bin/pin-displays                           # "already 2160x3840@30 -- no change", rc=0
launchctl bootstrap gui/501 ...              # runs = 1, last exit code = 0
```
The login path was exercised end-to-end: bootstrapping fired `RunAtLoad`, the script ran
under launchd, correctly detected the pinned mode, logged, and exited 0. Safe to test live
precisely because it is a no-op when nothing has drifted — no screen blip.

### Honest limits
This is a **mitigation of the trigger, not a fix to the KVM's receiver**. The lt6911c
losing lock during negotiation is the underlying hardware behaviour; pinning the mode
removes the renegotiation that provokes it. The real proof is the next reboot — check
`~/Library/Logs/pin-displays.log` for a "pinning layout" line, and if blanking recurs,
re-read the KVM's `dmesg` for fresh `lt86102sxe` HPD pairs and correlate against the
detected-resolution lines. If it flaps *even with the mode pinned*, the next lever is the
KVM's own EDID rather than anything on the Mac.
