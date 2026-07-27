# Display / KVM changes log

## 2026-07-27 (third pass) — KVM-side stabiliser + a validated instrument

### The actionable finding
`/etc/init.d/S23hdmi:159` gates the vendor's own HDMI repair on
`/etc/kvmd/user/edid_updated != "2"`:

```sh
if [ ! -f "$EDID_UPDATED_FLAG" -o "`cat $EDID_UPDATED_FLAG`" != "2" ]; then
    $TOOL -d /dev/i2c-1 -e $EDID_FILE && sleep 1 && echo 1 > $DEVICES_PATH/reset
    echo 2 > $EDID_UPDATED_FLAG
fi
```

Kinto's flag is `2` (custom 4K30 Dell EDID applied 2026-06-25 / 07-09), so **that reset has
never run on a normal boot since**. The receiver is left in whatever state the source's
power-on negotiation produced. That is precisely why a hand-run reset stopped this before
and why it returned after the next reboot — nothing re-applied it. The prior session's
truncated `echo 1 > /sys/bus/i2c/devices/$(cat /proc/gl-hw-info/hdmipatch)/…` command was
this same write.

### Changes
**`docs/glkvm/S99hdmi-stabilize`** (new, tracked here; deployed to the KVM at
`/etc/init.d/S99hdmi-stabilize`, persisted via the overlay at
`/userdata/overlay/upper/etc/init.d/`). `docs/` is in `.chezmoiignore`, so this is
version-controlled but never deployed into `$HOME`.

- Waits 90s for the source to finish negotiating, then issues the reset S23hdmi skips.
  Re-applies **only** the reset — never the EDID, since the custom 4K30 Dell EDID is
  deliberate.
- Then watchdogs: counts `0xD211 is ff` receiver read-failures in dmesg and watches for
  `no signal`, logging every degradation with a timestamp to `/userdata/hdmi-stabilize.log`
  (persistent, unlike /tmp). Remediates with a reset, rate-limited by a 180s cooldown and
  only on repeated evidence — a reset storm would be worse than the fault.

### Verified, not assumed
```
11:21:14 === stabiliser start (settle 90s) ===
11:22:44 RESET issued (boot re-init) [res=3840x2160@30]
11:22:54 RESET done, res=3840x2160@30
```
Deployed, `sh -n` clean, confirmed in the overlay upper dir, ran end-to-end.

**The 5Hz sysfs poller is now a validated instrument.** It captured both resets exactly:
```
11:16:38 res 3840x2160@30 -> no signal ;  11:16:43 -> 3840x2160@30   (manual reset)
11:22:46 res 3840x2160@30 -> no signal ;  11:22:51 -> 3840x2160@30   (stabiliser)
tx_state / tx_out unchanged throughout all four transitions
```
Two consequences: a ~4s event cannot slip past it, so a future "no change" reading is
genuine evidence; and resetting the receiver provably does **not** disturb the monitor
branch — the lt6911c hangs off the lt86102sxe splitter's second output, so the capture and
monitor branches are independent. Nothing on the KVM's streaming side can blank the Dell.

This also makes the remaining case decisive by construction: if a blank occurs with no
poller transition, the source and splitter are both innocent and it is monitor-side.

### Retractions from earlier passes (all on evidence)
- **`hotplug_status = error` is not a fault.** It survived a clean reset that produced a
  good `0xD211 is 0` read. Boot dmesg explains it: `lt6911c: Failed to get hotplug-gpios if
  lt86102sxe before is find` — with the splitter present the receiver gets no hotplug GPIO,
  so the attribute reads `error` by design.
- **HDMI audio renegotiation is not it.** The custom EDID does advertise audio and macOS
  does expose `DELL 4K` as an HDMI audio endpoint (2ch, 48kHz), which was a good lead — but
  `audio_present` has been `0` and unchanged at 5Hz throughout, with no resolution
  re-detects. Audio is not toggling.
- **"macOS logged nothing during the 08:21–08:42 storm" was invalid.** `log show` returns
  **zero lines total** for that window — unified log retention does not reach back that far.
  That was a broken instrument, not an absence of events. (The 10:58 check was inside
  retention and does stand.)
- Earlier retractions stand: the DCP reset loop (routine 10-minute OSLog rotation) and the
  cable.

### Honest state
The boot-time storm now has two independent mitigations (mode pinning on the Mac, receiver
re-init on the KVM). The sporadic ~1s blank has **never been observed inside a validated
window**, so it is not proven fixed — but every mechanism reachable from either side has
been tested and eliminated, the one repair the vendor's own code prescribes (and that
previously worked by hand) is now applied persistently, and any recurrence is logged and
self-healed rather than invisible. Next step on recurrence: read
`/userdata/hdmi-stabilize.log` and the poller output; no poller transition means
monitor-side.

---

## 2026-07-27 (later) — CORRECTION: there are TWO blanking phenomena, not one

The entry below is accurate about the **boot-time** storm and the mode-pinning fix, but it
was **wrong to present that as fixing the blanking generally**. Rai reported another blank
at ~10:58, well after the 08:42 settle. Re-checked both sides at the time:

- KVM `dmesg` frozen at 1121 lines, last entry uptime 907761s while the box was at
  909567s — **30 minutes with zero kernel messages**. No `lt86102sxe` HPD pair.
- macOS unified log: nothing.

So the 10:58 event was invisible to both the source and the KVM, which rules out the
`lt6911c`/`lt86102sxe` HPD mechanism that caused the morning storm. Two distinct
phenomena:

**(1) Boot-time negotiation storm** — real, logged, mechanism proven, mitigated by
`com.rai.pin-displays` (see below). Occurred 08:21–08:42 only.

**(2) Ongoing sporadic ~1s blanks** — mechanism NOT yet established. Neither side logs it.

### Leading candidate for (2), correlation only — NOT proven
A runaway `agent-browser` was found: `/Users/rai/.asdf/.../agent-browser-darwin-arm64`
driving **24** `Chrome for Testing` processes in a ~2Hz screen-capture loop, visible as
paired `powerd` assertions:

```
Process Google Chrome for Testing.9269 Created  NoDisplaySleepAssertion "Capturing"
Process Google Chrome for Testing.9269 Released NoDisplaySleepAssertion "Capturing"
```

Rate per minute: `11:03→16, 11:04→4, 11:05→12, 11:06→8, [killed 11:07:25] 11:07→0,
11:08→4`. It started ~10:31 and was **abandoned** — listening on 127.0.0.1:51913 with no
client connected. Both blanks Rai reported (~10:37, ~10:58) fall after 10:31.

Plausible mechanism: repeated screen-capture start/stop reconfigures the framebuffer,
which at a marginal 4K30 (297MHz, the Comet's ceiling) glitches the link briefly without
either side logging a state change. **This is a hypothesis with temporal correlation and
no proven causal link.** Recorded as a lead, not a conclusion — two earlier theories today
(DCP reset loop, cable) were already retracted on evidence.

Note `hotplug_status` on the receiver reads **`error`** while video flows normally, which
is consistent with the `0xD211` read failures and suggests the link sits marginal even
when stable.

### Instrumentation left running (2026-07-27 ~11:12, 3h)
Because the event is sporadic and unlogged, both sides are now instrumented so the next
occurrence is captured rather than reconstructed:
- **KVM**: `/tmp/hw2.sh` → `/tmp/hdmi-w2.log`. Polls `lt86102sxe/hdmi_state`,
  `hdmi_out`, and `lt6911c/hotplug_status|resolution|real_resolution|audio_present` 5x/sec
  and logs only transitions with ms timestamps. A 1s blank cannot slip between samples.
- **Mac**: `log stream` filtered to display/HDCP/assertion events.

How to read the next event:
| Poller shows | Capture burst same second | Conclusion |
|---|---|---|
| a transition | — | genuine KVM link event |
| no change | yes | capture-driven framebuffer churn |
| no change | no | monitor resyncing on a marginal link; nothing logs it |

### Related real bug found (separate from the blanking)
`~/focused/scripts/browser-memory-guard.sh` (untracked) exists precisely to reap runaway
automation browsers — its header records that on 2026-07-27 parallel subagents spawning
Playwright/Chrome exhausted 24GB and **forced a power cycle** (this morning's 08:21 boot).
It did not reap this runaway because its `free_mb()` counts inactive pages as available:

```
free_mb() reports:  5420 MB     (MIN_FREE_MB=2000, so "plenty of headroom")
reality:            60 MB truly free, 9167 MB compressor, 3.58M swapouts
kern.memorystatus_vm_pressure_level = 2   (WARN)
```

**Do not naively "fix" `free_mb()`.** The category-B pressure path reaps browsers *and*
test runners oldest-first until `free >= MIN_FREE_MB`; with an accurate metric that
condition can never clear on this box, so it would kill every vitest run every 60 seconds.
The safe surgical change is to reap *abandoned* automation-browser trees (no client on
their debug port) at any age under category A, which would have caught this one at minute
zero. Calibrating category B is a real aggressiveness tradeoff and is Rai's call.

---

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
