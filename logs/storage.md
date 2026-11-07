# Storage / ExternalNVMe offload log

## 2026-10-01 — Free internal disk by moving cold dirs to ExternalNVMe

### Motivation
Internal disk was at 98% (4.3G free of 228G). Goal: free at least 20G durably,
meaning the freed space must not creep back, and nothing that a LaunchAgent
touches may depend on the external drive (known failure modes: a launchd
StandardOutPath on the NVMe dies EX_CONFIG(78); colima's launchd `open()` hung
on the volume after the macOS 26.4 update; ssh Include off the NVMe hit EINTR).

### Selection rule
A dir only moves if: no plist in `~/Library/LaunchAgents`, `~/bin`,
`~/.local/bin`, `~/navi/bin`, `~/navi/curator` references it; nothing has it
open (`lsof +D`); and it is not a worktree the worktree-janitor manages
(`~/dev/lumiere-*`). Hot paths stay internal: `~/dev/lumiere`, `~/navi`,
`~/.claude`, `~/.codex`, `~/.asdf`, `~/.perch`, `~/.bun` (Rai: both must stay internal), `~/Library/pnpm` (the pnpm store
must share a filesystem with projects or hardlinks become copies).

### Moved (copied with `ditto`, verified with `rsync -rlcn` checksum dry-run, then replaced by a symlink)
All targets under `/Volumes/ExternalNVMe/home/`:
- `~/dev/Perch-wt` (4.9G). Its 7 git worktrees were `git worktree lock`ed so a
  `git worktree prune` while the drive is unplugged cannot drop their metadata.
- `~/voice-goon` (2.8G)
- `~/perch-recovered` (1.3G)
- `~/.vscode-server` (2.6G). Regrows on every VS Code Remote connect, so it is
  linked rather than deleted. Verified sshd sessions can read the NVMe.
- `~/Library/Python/3.9` (929M) -> `home/Library/Python/3.9`
- `~/dev/pty-mcp` (402M), `~/dev/hurdle` (371M), `~/dev/opentabs-fork` (668M)
  -> `home/dev/...` (`opentabs` LaunchAgent runs the npm-installed CLI, not the fork)
- `~/.grok` (750M)

### Caches cleared (one-off relief, these regrow)
`npm cache clean --force`, `pnpm store prune`, `brew cleanup --prune=all -s`,
and `~/Library/Caches/{com.unity3d.unityhub.ShipIt,@getpaseodesktop-updater,t3code-updater,pnpm}`.

### System
`AutomountDisksWithoutUserLogin = true` in
`/Library/Preferences/SystemConfiguration/autodiskmount` so the NVMe mounts at
boot rather than at login.

### Result
Free space 4.3G -> 18G. Then deleted `/Applications/iMovie.app` (3.7G, Rai's call) -> 23G.

### Pending (needs Rai in the GUI)
- Backblaze: Settings -> "Temporary Data Drive" -> ExternalNVMe. Moves
  `/Library/Backblaze.bzpkg/bzdata/bzbackup/bzdatacenter` (12G staging) off internal.

### Not moved, and why
- `~/dev/lumiere-watson` (1.6G): worktree of lumiere matched by worktree-janitor, and in use.
- `~/Library/Caches/net.whatsapp.WhatsApp` (1.9G): WhatsApp had it open.
- `~/.claude/projects`, `~/.codex/sessions`: the real long-term growers, but
  read/written by launchd-spawned agents (cli-transcripts, paseo, orca, perch-orb).
