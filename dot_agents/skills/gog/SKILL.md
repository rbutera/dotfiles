---
name: gog
description: Access Rai's Google account (rai@rbutera.com) from the shell with the gog CLI — Gmail search/read/send, Calendar, Drive, Docs, Sheets, Contacts, Tasks. Use whenever a task needs Rai's email, calendar, or Drive files and no dedicated Google MCP tool is available or sufficient (MCP connectors cannot send mail).
---

# gog — Google from the shell

`gog` is an unofficial Google Workspace CLI (https://gogcli.sh). It is installed and authenticated as `rai@rbutera.com` on every chezmoi-managed Mac (nimbus, latios). Full scopes: gmail, calendar, drive, docs, sheets, slides, contacts, people, tasks, chat, forms, appscript.

## Before the first call

`gog` exits 0 and prints nothing when the keyring is locked. Silence is not "no results".

```bash
source ~/.config/zsh/tools.zsh 2>/dev/null   # exports GOG_KEYRING_PASSWORD (from 1Password via chezmoi)
gog auth doctor | tail -1                     # must print: status ok
```

Interactive shells already have the variable. Cron, launchd, Docker, and any subshell that did not load `tools.zsh` do not, so put the `source` line in front of gog in scripts and job commands. Never hardcode the password.

## Conventions

- Output for scripts: `--json` (add `--results-only` to drop the envelope). Humans: `--plain` for TSV.
- Account is implicit (only one authed). Add `--account rai@rbutera.com` when writing anything that might run where a second account exists.
- Read-only runs: add `--readonly`. Agent safety when only reading mail: `--gmail-no-send`.
- `gmail search --json` returns `{ "threads": [...] }`, not `messages`. Reading `.messages` gives a confident zero. `gmail messages search` is the per-message variant.
- Gmail search excludes spam and trash. Add `in:anywhere` to the query when absence matters.
- When a search returns 0, run it once without `--json` and look at the table before asserting absence.

## Gmail

```bash
gog gmail search 'from:foo@example.com newer_than:7d' --max 20 --json
gog gmail messages search 'subject:invoice' --include-body --json   # decoded bodies inline (returns messages, not threads)
gog gmail get <messageId>                                     # one message
gog gmail thread get <threadId>
gog gmail attachment <messageId> <attachmentId> --out ./file
gog gmail labels list
gog gmail archive <messageId>  |  mark-read  |  unread  |  trash

# sending (see approval gate below)
gog gmail send --to a@b.com --cc c@d.com --subject 'Subj' --body 'Text'
gog gmail reply <messageId> --body 'Text'          # reply-all: gog gmail reply-all
gog gmail forward <messageId> --to a@b.com
gog gmail drafts create --to a@b.com --subject 'Subj' --body 'Text'
gog gmail drafts send <draftId>
```

Query syntax is standard Gmail search (`from:`, `to:`, `subject:`, `newer_than:3d`, `after:2026/09/01`, `has:attachment`, `label:`, `is:unread`).

## Calendar

```bash
gog calendar calendars                                  # list calendars (ids, names)
gog calendar events --today --json
gog calendar events --days 7 --calendars primary --json
gog calendar events --from 2026-09-22 --to 2026-09-29 --json
gog calendar event primary <eventId>
gog calendar search 'dentist' --json
gog calendar freebusy primary --from 2026-09-22T09:00:00+01:00 --to 2026-09-22T18:00:00+01:00
gog calendar conflicts --days 7
gog calendar create primary --summary 'Title' --from 2026-09-22T10:00:00+01:00 --to 2026-09-22T11:00:00+01:00
gog calendar update primary <eventId> --summary 'New title'
gog calendar respond primary <eventId> --status accepted
gog calendar delete primary <eventId>
```

Times are RFC3339 with timezone, or a plain date. Rai is in Europe/London.

## Drive, Docs, Sheets

```bash
gog drive ls --json                       # root
gog drive search 'name contains "budget"' --json
gog drive get <fileId>  |  download <fileId> --out ./local  |  upload ./local --parent <folderId>
gog drive mkdir 'Name' --parent <folderId>  |  share <fileId> --email a@b.com --role reader
gog drive url <fileId>                    # web link

gog docs cat <docId>                      # plain text of a Google Doc
gog docs export <docId> --format pdf --out ./doc.pdf
gog docs create 'Title'  |  gog docs write <docId> --text 'Text' --append

gog sheets get <spreadsheetId> 'Sheet1!A1:D20' --json
gog sheets append <spreadsheetId> 'Sheet1!A:D' 'v1' 'v2' 'v3' 'v4'
gog sheets update <spreadsheetId> 'Sheet1!B2' 'value'
```

## Contacts and Tasks

```bash
gog contacts search 'Jane' --json  |  gog contacts list --json
gog tasks lists list  |  gog tasks list <tasklistId> --json  |  gog tasks add <tasklistId> --title 'Do X'
gog me                                    # profile sanity check
```

## Approval gate

Anything that leaves the account is external-facing: `gmail send`, `reply`, `reply-all`, `forward`, `drafts send`, `calendar create/update/respond` with attendees, `drive share`. Show Rai the exact recipients, subject, and body and get an explicit yes before running it. Prior approval of the exact text in the current conversation counts; a bare "yes" to something else does not. Destructive ops (`trash`, `delete`, `clear`) need the same.

## Setup / repair

Config: `~/Library/Application Support/gogcli/` (`config.json` with `keyring_backend: file`, `credentials.json` OAuth client, `keyring/` encrypted refresh tokens). All hosts share the same refresh token and keyring password, so a new Mac is `brew install gogcli` plus copying those three from an existing host. Re-auth from scratch: `gog auth add rai@rbutera.com`. Details in `~/.local/share/chezmoi/logs/gog.md`.
