# TFT coaching skills log

## 2026-10-09: global TFT coaching skill family (tft-coach, tft-data, tft-explorer, tft-meta, tft-set)

**Motivation.** Rai asked on voice (21:30) for agents that coach him at Teamfight Tactics with live, factual data (Master rank, mobile and PC). Needs: link a taken augment straight to its datatft page, explorer stats for specific combinations only, the tftflow meta with the conditions that make comps strong, and a current-set reference.

**Changed.**
- `dot_claude/skills/tft-{coach,data,explorer,meta,set}/` (SKILL.md; `tft-data/ids.json` scraped unit/item/trait ids). Deployed to `~/.claude/skills/`. Generated data (`tft-set/set.*`, `tft-meta/meta.md`) is deliberately NOT in the source: each machine builds it with `tft-refresh`.
- `dot_local/bin/executable_tft-{url,explore,flow,refresh}` -> `~/.local/bin/`. `tft-url` resolves datatft.com URLs (augment names to `/rate#N` cheat-sheet anchors), `tft-explore` queries MetaTFT's explorer JSON API (unit + items -> best third item; emblem/trait/unit combos), `tft-flow` reads tftflow.com (server-rendered), `tft-refresh` is the daily job.
- `dot_config/impulse/jobs.json.tmpl`, nimbus branch: new `tft-data-refresh` job, `trigger.kind: "cron"`, `20 4 * * *` Europe/London, runs `tft-refresh` (rewrites meta snapshot daily; set reference only when the tftflow patch changes). Applied with `chezmoi apply ~/.config/impulse/jobs.json` (no 1Password needed; diff showed only this job), `com.rai.impulse-worker` kickstarted, worker log shows `[sync-crons] synced ... (navi/tft-data-refresh) -> 20 3 * * * UTC`.

**Findings worth keeping.** datatft.com is a Vue SPA with no per-augment page; its `/rate` cheat sheet has anchors (Expected Unexpectedness = `/rate#14`, not sequential). MetaTFT's explorer API ignores unknown filter names and returns a uniform placement list (every slot equal) instead of an error. Repeating `unit_item_unique` ANDs items; one value with three `%26` parts returns zero.

**Not applied elsewhere.** Other machines need `chezmoi apply` and a first `tft-refresh`; the job exists only in the nimbus branch.
