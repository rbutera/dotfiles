# zshenv changelog

## 2026-09-03 — ARK_WORKSPACE on work hosts: ~/focused -> ~/tilly

`ark` resolves its workspace from `ARK_WORKSPACE` before cwd, so with the old
export every `ark generate` / `ark install` run on latios silently targeted
`~/focused/ark.json` (and failed on its retired `FLORENCE_DISCORD_TOKEN`).
Work hosts now export `$HOME/tilly`.

## 2026-09-03 — Kill the Notion secrets group (Focused work tool)

Notion was a Focused Labs tool. `dot_config/zsh/notion.zsh.tmpl` (work-host gated,
read `op://focused/Notion API Key`) deleted; `.chezmoiremove` drops the deployed
`~/.config/zsh/notion.zsh`. `NOTION_TOKEN` / `NOTION_API_KEY` are no longer exported anywhere.

## 2026-09-03 — Kill the easyJet secrets group (left Focused)

### Motivation

No longer at Focused / easyJet. The `easyjet.zsh` group (Atlassian / JIRA /
Confluence / SonarQube / Databricks prod PAT, `AWS_PROFILE=ej-dev`) only ever
rendered on work hosts (kinto / latios) and has no reason to exist now.

### Change

- Deleted `dot_config/zsh/easyjet.zsh.tmpl`.
- Added `.chezmoiremove` with `.config/zsh/easyjet.zsh` so the deployed file is
  removed on every host at next `chezmoi apply` (the `.zshenv` loader globs
  `~/.config/zsh/*.zsh`, so a stale deployed copy would keep exporting).
- Removed the matching work-host Atlassian / JIRA / Confluence / SonarQube block
  from `Documents/PowerShell/Microsoft.PowerShell_profile.secrets.ps1.tmpl`.
- The 1Password items themselves (`op://focused/EasyJet JIRA API`, `SonarQube`,
  `easyjet databricks prod PAT`) still exist; nothing in the repo reads them now.

## 2026-09-03 — Drop the dead `_focused notion token` 1Password read

### Motivation

`chezmoi apply` failed rendering `dot_config/zsh/tools.zsh.tmpl`:

```
could not read secret 'op://Private/_focused notion token/credential': "_focused notion token" isn't an item in the "Private" vault
```

Rai left Focused and deleted the item from 1Password. Every other
`onepasswordRead` in the repo (86 unique refs) was checked against `op read`
and still resolves; the `focused` vault and its items (Flaude Discord, Hatchet
Kinto, claude code oauth token, etc.) are intact and stay referenced because
Florence depends on them.

### Change

- `dot_config/zsh/tools.zsh.tmpl`: removed the `NOTION_TOKEN` export. Work
  hosts still get `NOTION_TOKEN` from `notion.zsh.tmpl` (aliased to
  `NOTION_API_KEY` from `op://focused/Notion API Key`); non-work hosts no
  longer export it at all.
- `Documents/PowerShell/Microsoft.PowerShell_profile.secrets.ps1.tmpl`: removed
  the matching `$env:NOTION_TOKEN` line (same dead item).

## 2026-07-28 — Databricks prod PAT added to the work-only easyjet secrets group

### Motivation

Needed the easyJet **production** Databricks PAT available as an env var, on work
machines only (`latios`, `kinto`).

### Change

No new file was created. `dot_config/zsh/easyjet.zsh.tmpl` already *is* the
"work-machines-only easyjet zsh file imported by .zshenv" — it sits in the
`~/.config/zsh/*.zsh` secrets-group directory that `.zshenv`'s loader loops over,
and its entire body is wrapped in `{{ if has .chezmoi.hostname .host_groups.work }}`
(`work = ["latios", "kinto"]` in `.chezmoidata.toml`). On non-work hosts it
renders to just the header comment and performs zero `op` reads. A second file
would have duplicated that gating for no benefit, so the export was appended to
the existing group instead.

Added:

```
export DATABRICKS_PROD_TOKEN={{ onepasswordRead "op://focused/easyjet databricks prod PAT/credential" | quote }}
```

### Why `DATABRICKS_PROD_TOKEN` and not `DATABRICKS_TOKEN`

The databricks CLI and every SDK/dbx-aware tool auto-consume a bare
`DATABRICKS_TOKEN` from the environment. Exporting the **prod** PAT under that
name would silently point every ad-hoc `databricks ...` invocation at
production, with no opt-in step. The explicit name forces a deliberate
per-command opt-in:

```bash
DATABRICKS_TOKEN="$DATABRICKS_PROD_TOKEN" databricks ...
```

`DATABRICKS_HOST` was not set — the workspace URL wasn't specified and isn't
guessable; add it to the same block when known.

## 2026-07-13 — Export OP_ACCOUNT unconditionally, by user ID (not the `personal` shorthand)

### Problem

Every `onepasswordRead` in every template failed on this machine:

```
[ERROR] multiple accounts found. Use the --account flag or set the OP_ACCOUNT
        environment variable to select an account.
```

Two accounts are signed in — `my.1password.com` (rai@rbutera.com) and
`focusedlabs.1password.com` — so `op` refuses to guess. `OP_ACCOUNT=personal`
*was* set, but only inside the SSH-session block, so a local shell had nothing.

Worse, the `personal` value was wrong here anyway. That shorthand only exists on
machines where the account was added with `op account add --shorthand personal`.
On this machine the CLI is connected to the 1Password **app**, and in that mode
`op account add` is refused outright ("Add an account through the 1Password
app") — app-provided accounts carry no shorthand. `op account list` confirms:
URL/email/user ID only. So `--account personal` matched nothing.

Selector support, verified live: user ID ✅, account URL ✅, email ❌ (fails).

### What changed

- **`dot_zshenv.tmpl`**: Moved `OP_ACCOUNT` out of the SSH block and made it an
  unconditional export, set to the **user ID** `RTBK7UHJFNF7FB7ELCPJRRLDGM`
  (rai@rbutera.com). The user ID is the same identifier on every machine —
  it works whether the account came from the app integration (this machine) or
  from a CLI `op account add` (the machines with a `personal` shorthand), so one
  value is portable across the fleet where `personal` was not.
  The SSH block keeps `OP_BIOMETRIC_UNLOCK_ENABLED=false`.

No `op signin` is needed on this machine: the app integration serves reads
directly once the desktop app is unlocked.

## 2026-06-22 — Fix onepasswordDetailsFields section-field bug across group files

### Motivation
After dropping the Supermemory block (below), `chezmoi apply` still failed —
`chezmoi status` aborted rendering `dot_config/zsh/discord.zsh.tmpl` with
`map has no entry for key "hermione"`. Same root cause as Supermemory: the
2026-06-21 split rewrote several groups to fetch a whole item once via
`onepasswordDetailsFields` and index fields as `$item.<key>.value`. But
**`onepasswordDetailsFields` only returns an item's top-level fields**
(`credential`, `username`, `hostname`, `password`, …) — fields nested inside a
1Password **section** are absent from its map. Verified live by dumping the key
set for "Navi Discord tokens": only `credential`/`username`/`hostname`/… present,
none of the per-bot section labels. The old `op://Item/<label>` reads worked
because `op read` resolves section labels; the map lookup does not.

Three group files referenced section fields and so failed to render:
- `discord.zsh.tmpl` — 13 of 14 bot tokens are section fields
- `tools.zsh.tmpl` — `$expmail.app_password`, `one-time password` (google item)
- `voice-media.zsh.tmpl` — `$eleven.rai`/`.navi`, `$runpod.s3_access`/`.s3_secret`

Files that only referenced top-level fields render fine and were left as-is
(`claude-ai`, `easyjet`, `github`, `jobsearch`, and `tailscale`/`opencode` etc.
in `tools`) — `onepasswordDetailsFields` is correct there and still saves reads.

### What changed
- **`discord.zsh.tmpl`**: dropped the `$d := onepasswordDetailsFields` line;
  all 14 exports back to per-field `onepasswordRead "op://Private/Navi Discord
  tokens/<label>" | quote`.
- **`tools.zsh.tmpl`**: Expedition-email block back to two `onepasswordRead`
  calls (`app_password`, `one-time password`); removed `$expmail`.
- **`voice-media.zsh.tmpl`**: Elevenlabs (`rai`/`navi`) and RunPod
  (`s3_access`/`s3_secret`) blocks back to `onepasswordRead`; removed `$eleven`
  and `$runpod`. Kept `| quote`.
- Verified all three render and resolve to non-empty values; applied the 8
  previously-unapplied group files + `.zshenv`; `zsh -n` clean on all groups.

### Lesson
`onepasswordDetailsFields` is only safe for **top-level** item fields. For any
value stored in a 1Password section, use `onepasswordRead` with the field label.

## 2026-06-22 — Drop Supermemory block from ai-apis group (apply failure)

### Motivation
After the 2026-06-21 split, `chezmoi apply` failed rendering
`dot_config/zsh/ai-apis.zsh.tmpl:15` with
`map has no entry for key "claude"`. The refactor had collapsed the three
pre-existing `SUPERMEMORY_*` exports (originally three separate
`onepasswordRead "op://Private/supermemory api key/<field>"` calls) into one
cached `onepasswordDetailsFields "supermemory api key" "Private"` read, then
indexed it as `$supermem.claude` / `.opencode` / `.credential`. The
`onepasswordDetailsFields` map keys don't match those field references, so the
`.claude` lookup returned no entry and aborted the whole apply. Rai confirmed he
doesn't use supermemory, so the block is removed entirely rather than re-mapped.

### What changed
- **`dot_config/zsh/ai-apis.zsh.tmpl`**: Removed the Supermemory block
  (`$supermem` assignment + `SUPERMEMORY_CC_API_KEY`, `SUPERMEMORY_API_KEY`,
  `SUPERMEMORY_OPENCLAW_API_KEY` exports).

## 2026-06-21 — Split secrets into sourced group files (Dotfiles Phase 1, focused-nswr)

### Motivation
`dot_zshenv.tmpl` carried ~70 inline `onepasswordRead` calls in one block, so every
`chezmoi apply` did ~70 sequential `op read` round-trips — the real source of the
"applying the env takes forever" pain (profiling showed shell startup itself is
already ~0ms; see `vault/research/dotfiles/phase1-zshenv-profiling.md`). Two wins:
(1) per-file apply — `chezmoi apply ~/.config/zsh/<group>.zsh` renders only that
group, so editing one key re-reads only that group's items, not all 70; (2)
whole-item caching — multi-field / duplicate items now fetched ONCE via
`onepasswordDetailsFields` instead of once per field.

### What changed
- **`dot_zshenv.tmpl`**: removed the whole inline `# Secrets (1Password)` block
  and replaced it with a loader that sources every `~/.config/zsh/*.zsh` (zsh
  `(N)` null-glob so an empty dir is a no-op). The structural `.zshenv` now has
  ZERO `onepasswordRead` calls → `chezmoi apply ~/.zshenv` never invokes 1Password.
- **`dot_config/zsh/*.zsh.tmpl`** (8 new group files): secrets carved out by
  domain — `claude-ai`, `github`, `ai-apis`, `easyjet` (whole file work-host
  gated), `discord`, `voice-media`, `tools`, `jobsearch`, plus `host-infra`
  (DB_URL dev_infra / DATABASE_URL nimbus). Every env var name + `op://` ref
  preserved exactly (verified: zero vars added/dropped vs the old block).
  Caching collapses: Navi Discord 14→1, EasyJet JIRA 9→1, github PAT 3→1,
  Supermemory 3→1, Elevenlabs 3→1, RunPod 3→1, Tailscale 2→1, Adzuna 2→1,
  OpenCode Zen 2→1, Expedition email 2→1. `| quote` added to all secret values.

### Behaviour preserved
Host conditionals kept; `CONFLUENCE_URL` still gets `/wiki` (now via
`printf "%s/wiki"` inside the quote). On non-work hosts the easyjet group renders
to its header comment only (zero op reads).

### Verify on apply (needs an unlocked 1Password session)
1. `op signin` / biometric unlock FIRST (the group files call `op read`).
2. `chezmoi apply ~/.zshenv` (instant, no op), then `chezmoi apply ~/.config/zsh`.
3. New shell: spot-check collapsed items, e.g. `${GITHUB_TOKEN:+SET}`,
   `${ATLASSIAN_API_KEY:+SET}`, `${OPENCLAW_DISCORD_ORCA:+SET}`, must print `SET`.
4. Run on BOTH kinto (work) and nimbus (personal) — host-gated blocks differ.

### Caveat
`onepasswordDetailsFields` keys by 1Password FIELD ID. Field ids here were taken
verbatim from the old `op://item/<field>` refs Rai already used. If any field's id
differs from its label in 1Password, that one var renders empty — the `:+SET`
spot-check catches it. No live verification was possible (no op session at refactor).

## 2026-06-19 -- Remove OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS (omo flakiness)

### Change
Removed `export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=1` (a leftover from the
oh-my-opencode-slim era). oh-my-openagent's background/parallel subagent delegation
reports completion unreliably — `call_omo_agent` can time out after the subagent
already shows completed, and fast-finishing tasks hang in "running" forever
(oh-my-openagent issues #3774, #4570, #1517). Unsetting the flag forces
foreground/synchronous delegation, which avoids the completion-handshake race.
Requires `chezmoi apply ~/.zshenv` (1Password) + a fresh shell + restart of any
running `openagent` session.

## 2026-06-19 -- Add CURSOR_API_KEY for the opencode `openagent` profile

### Change
Added `export CURSOR_API_KEY={{ "{{" }} onepasswordRead "op://focused/cursor API key/credential" {{ "}}" }}`
under the OpenCode section. Used by the `opencode-cursor` plugin in the `openagent`
profile to route the Sisyphus orchestrator (and oracle/vision) through the user's
Cursor Pro subscription (`cursor-acp/*` models). Requires `chezmoi apply` with an
active 1Password session. See `logs/opencode.md` and `docs/opencode-profiles.md`.

## 2026-06-05 -- Use normal Claude Opus 4.8 context window

### Problem
Work-host `.zshenv` exported `ANTHROPIC_DEFAULT_OPUS_MODEL='claude-opus-4-8[1m]'`,
which made Claude Code default to the 1M context variant.

### Solution/Fix
Changed the work-host branch in `dot_zshenv.tmpl` to export
`ANTHROPIC_DEFAULT_OPUS_MODEL='claude-opus-4-8'`, matching the existing
non-work branch and using the normal context window. Rai will run `chezmoi apply`.

## 2026-06-04 -- Add OpenAI + Ideogram image-gen API keys

### Problem
The creative pipeline (fanart, campfire wallpaper pu5x, anime stills) silently
depended on the flaky ChatGPT-via-browser adapter (bead workspace-xho3). The
deterministic fix is the direct image-gen APIs (pod-factory + the new
`~/navi/bin/gen-image.mjs`), but OPENAI_API_KEY and IDEOGRAM_API_KEY were never
exported anywhere — absent from env and from chezmoi source.

### Solution/Fix
Added two `onepasswordRead` exports to `dot_zshenv.tmpl` under a new "Image
generation" block (right after the Cartesia key): OPENAI_API_KEY from
`op://Private/OpenAI API/credential` and IDEOGRAM_API_KEY from
`op://Private/Ideogram API/credential` (canonical paths per pod-factory setup
docs). After `chezmoi apply` with a 1Password session, both keys are live and
`gen-image.mjs` / pod-factory work browser-free.

## 2026-06-01 -- Add GELATO_API_KEY for Dopamade Etsy fulfilment

### Problem
Rai created a Gelato print-on-demand shop and linked it to his Etsy (Dopamade). The Gelato API credential needs to be available in the shell environment for the automated fulfilment pipeline (programmatic product creation / order handling).

### Solution/Fix
Added to `dot_zshenv.tmpl` after the Civitai key:
`export GELATO_API_KEY={{ onepasswordRead "op://Private/Gelato/credential" }}`
1Password item: op://Private/Gelato/credential (Rai created it). Requires a 1Password session for `chezmoi apply` (zshenv is full of onepasswordRead). Rai applies.

## 2026-06-03 -- add CARTESIA_API_KEY

- Added `export CARTESIA_API_KEY={{ onepasswordRead "op://Private/Cartesia/credential" }}` to the API-keys block, for the Discord voice plugin's Cartesia migration (ElevenLabs -> Cartesia).
- op reference only (resolved at apply-time); no raw key in git.
- Lands in the shell env on next `chezmoi apply`. (The voice daemon reads the key from its own plugin .env, not the shell -- this is for shell/general use.)

## 2026-06-04 -- Remove IDEOGRAM_API_KEY, demote OPENAI_API_KEY to billing-only

### Problem
Image generation was migrated to a first-party Codex/ChatGPT-subscription path (lumiere `openai-json` `generateImage` + pod-factory + `~/navi/bin/gen-image.mjs`), killing the paid Ideogram + OpenAI-paid-API image paths (bead workspace-0vuc). The `IDEOGRAM_API_KEY` export was now unused anywhere.

### Solution/Fix
Removed the `IDEOGRAM_API_KEY` export from `dot_zshenv.tmpl` (added earlier the same day, now dead). Kept `OPENAI_API_KEY` (still read by `~/navi/bin/cost-report.mjs` for billing checks) and updated its comment to note image-gen has moved to the free codex path. Removal takes effect on next `chezmoi apply`; the lingering deployed export is harmless until then.

## 2026-06-07 — Dedupe CARTESIA_API_KEY

### Problem
`CARTESIA_API_KEY` appeared twice in `dot_zshenv.tmpl` (line ~141 in the API-key cluster + line ~184 under the "voice migration 2026-06-03" comment), with inconsistent spacing before `}}`. Rai noticed the key seemed missing from his deployed `~/.zshenv` and asked about it.

### Root cause
The deployed `~/.zshenv` lacks the key because `chezmoi apply` hasn't run since it was added to the template on 2026-06-03 (apply needs an active 1Password session for the `onepasswordRead`, which agents can't provide). The key works at runtime anyway because it's also present in the gitignored runtime `.env` files (navi, discord-voice-plugin, narrate).

### Fix
Removed the duplicate, kept the single documented line (`export CARTESIA_API_KEY={{ onepasswordRead "op://Private/Cartesia/credential" }}`) under the voice-migration comment, normalized spacing. Source-only change; no apply run. Rai still needs to `chezmoi apply` (after `op signin`) to get the key into his live shell env.

## 2026-07-02 — Add Notion API key (work-gated group)

### Problem
Lloyd asked to publish the spec-driven-development blog series into Notion. The hosted Notion MCP (OAuth) cannot upload local files (charts/PDFs) to pages, so we need the Notion REST API, which needs an integration token in the shell env. It is a work tool and should not land on personal hosts.

### Solution/Fix
New per-domain group `dot_config/zsh/notion.zsh.tmpl` -> `~/.config/zsh/notion.zsh`, gated to `host_groups.work` (kinto/latios) exactly like `easyjet.zsh`. Exports `NOTION_API_KEY` (+ a `NOTION_TOKEN` alias) from `onepasswordRead "op://focused/Notion API Key/credential"`. On non-work hosts it renders to the header only (zero op reads). Requires the `Notion API Key` item in the `focused` vault (same vault easyjet.zsh already uses), then `chezmoi apply ~/.config/zsh/notion.zsh` with an active 1Password session. Source-only change; Rai applies.

## 2026-07-03 — Add Cloudflare R2 image-CDN credentials

### Problem
The new R2-backed image-hosting library (expedition-dashboard gallery + Florence/Navi skill uploads) needs Cloudflare R2 credentials in the shell env on all hosts. Rai generated a CF API token with R2+Images access plus S3-compatible R2 credentials, stored in `op://dev/Cloudflare R2 Images CDN`.

### Solution/Fix
Added five vars to `tools.zsh` (ungated — both Florence/kinto and Navi/nimbus need it): `CLOUDFLARE_R2_ACCOUNT_ID` (username), `CLOUDFLARE_R2_API_TOKEN` (credential; CF Bearer for R2/Images management), and `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` / `R2_S3_ENDPOINT` (S3-compatible object ops for aws-sdk / rclone). Deliberately `R2_`-prefixed, NOT `AWS_*`, so they never collide with `AWS_PROFILE=ej-dev`. Source-only change; requires `chezmoi apply ~/.config/zsh/tools.zsh` with an active 1Password session.
