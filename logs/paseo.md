# Paseo changes log

## 2026-07-27 — Let the desktop app own the daemon; wrap it for shell env

### Motivation
Paseo on the phone went unresponsive, and `sh.paseo.daemon` showed as down in
`launchctl list` with last exit code 1.

It was not down — it was **crash-looping**. `launchctl print` reported `runs = 101`
with `KeepAlive` re-arming it forever, and every run died the same way:

```
Another Paseo daemon is already running (PID 16427, started 2026-07-27T07:28:49.520Z)
```

Root cause: Paseo's desktop app spawns its **own** `Paseo Supervisor` → daemon pair
and binds `127.0.0.1:6767` the moment it launches. PID 16427 was parented to
`/Applications/Paseo.app/Contents/MacOS/Paseo`, not to our LaunchAgent. The headless
`paseo daemon start --foreground` agent could therefore never win the port — it lost
the race 101 times.

The phone symptom followed from that: each doomed attempt still touched the outbound
relay before exiting, flapping the relay route between a dying instance and the live
one. That is exactly the remote-control failure the LaunchAgent was written to
prevent, caused by the LaunchAgent itself.

Two daemons cannot coexist, so one design had to go. The desktop app wins by
construction (it will always spawn its daemon on launch, and Rai runs the app), so
the headless agent was retired. What it was genuinely good at — environment — moved
into a wrapper around the app instead.

### Why the env wrapper still matters
A GUI app launched by launchd/Dock/LaunchServices gets a minimal environment, and its
child daemon plus every agent CLI that daemon spawns inherits it. None of the ~82
secrets exported from `~/.config/zsh/*.zsh` exist there. Verified from a clean env:

```
$ env -i HOME="$HOME" /bin/sh -c '...source groups...'
clean-env before=3 after=85 gained=82
```

That silently **degrades** agents rather than failing them — same class as the
2026-07-23 `omp` finding in `logs/pi.md`, where only `anthropic` and `openai-codex`
showed up (the two with credentials in omp's own HOME-based vault) while
opencode-zen, opencode-go, groq and zai vanished because they are discovered purely
from env vars.

Note: Paseo.app *does* run its own login-shell env capture (`/bin/zsh -i -l -c`, 30s
timeout) when spawning a daemon — visible as `[login-shell-env] applied` in the
launch log. The wrapper is deliberately belt-and-braces: that capture is best-effort
and can time out under load, whereas sourcing the groups directly cannot.

### Changes
**`bin/executable_paseo-desktop`** (new) — sources `~/.config/zsh/*.zsh`, builds the
PATH that provider detection depends on, then `exec`s
`/Applications/Paseo.app/Contents/MacOS/Paseo`. The app, Supervisor, daemon and every
agent CLI below them inherit one correct environment by ordinary process inheritance.
- Deliberately **not** `open -a Paseo`: LaunchServices hands the launch to launchd,
  which discards the environment and defeats the point.
- Deliberately **not** patched inside the app bundle: `sh.paseo.desktop.ShipIt`
  self-updates the app and would replace it / break the code signature.
- Deliberately **not** `launchctl setenv`: that would expose all ~82 credentials to
  every GUI app in the session via `launchctl getenv`. Scoping them to the Paseo
  process tree is the entire reason this is a wrapper.
- Homebrew prefix resolved at runtime (`/opt/homebrew` vs `/usr/local`) so the script
  stays plain and hand-testable rather than templated.

**`Library/LaunchAgents/sh.paseo.desktop.launcher.plist.tmpl`** (new) — `RunAtLoad`
launches the wrapper at login. `KeepAlive` is **false**, unlike the old agent: this
starts a GUI app, and if Rai quits Paseo he means it.

**`Library/LaunchAgents/sh.paseo.daemon.plist.tmpl`** (removed) — replaced by the
above. Deployed copy removed from `~/Library/LaunchAgents/` and booted out.

**`bin/executable_paseo-daemon`** (kept, now unused by launchd) — still a valid way to
run a headless daemon by hand on a host with no desktop app, and its header documents
the env rationale. Not wired to anything.

**`~/Library/Logs/paseo-daemon.log`** (removed) — 29.2MB of the single repeated
"Another Paseo daemon is already running" line, orphaned once the job was deleted.
Paseo's own logs under `~/.paseo/` rotate at 10MB and were left alone.

### Verification
```
launchctl bootout gui/501/sh.paseo.daemon      # crash loop stopped
plutil -lint ...sh.paseo.desktop.launcher.plist  # OK
/bin/sh -n ~/bin/paseo-desktop                   # OK
```
Relaunched through the wrapper with a deliberately minimal env
(`env -i HOME USER LOGNAME TMPDIR`) to prove it builds its own environment rather
than borrowing an interactive shell's:
- `[login-shell-env] applied`, no errors in the launch log
- single listener on `127.0.0.1:6767` (pid 74598)
- `/api/health` → `{"status":"ok"}`
- only `sh.paseo.desktop.ShipIt` left under launchd

### Not yet exercised
The login path itself. The new LaunchAgent is on disk and lints clean, but was **not**
bootstrapped this session — doing so fires `RunAtLoad` and would have raced a second
app instance against the daemon Rai was about to start working on. It activates at the
next login/reboot. Worth confirming `launchctl list | grep paseo` shows the launcher
after the next reboot, since a silent failure here is only discovered by reaching for
the phone and finding nothing there.
