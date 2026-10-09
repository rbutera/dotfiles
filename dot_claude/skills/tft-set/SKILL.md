---
name: tft-set
description: Reference for the CURRENT TFT set and patch - units by cost with traits, trait breakpoints, and the patch's character (fast 8/9 vs reroll mix, nerfs and buffs). Data lives in set.md and set.json next to this file with the patch and refresh date. Use for questions about traits, synergies, what a unit is, what the patch favours.
---

# tft-set

Read `set.md` (human-readable) or `set.json` (structured) in this directory. Header line has the **patch and refresh date**: compare it with the live patch (`tft-flow patch`) before quoting; if they differ run `tft-refresh --force`.

Currently generated: Set 18, tftflow patch 18.4 (datatft shows 18.4b), refreshed 2026-10-09.

## Contents

- `set.md`: patch character (economy-plan mix of Default+Meta comps on tftflow, plus the author's patch insights), units by cost with their traits, trait breakpoints.
- `set.json`: same data plus short trait descriptions and the source list.

## Sources

- Units, costs, traits, breakpoints: CommunityDragon `https://raw.communitydragon.org/latest/cdragon/tft/en_us.json`, set key `18` (Riot data export; it can briefly lag a live patch and mislabels the set name as "Set10", the champion/trait content is Set 18, cross-checked against datatft: Veigar 1-cost Blackthorn/Sprykin/Spellweaver, Blossom and Elderwood 3/5/7/9/11).
- Patch character and patch version: `https://tftflow.com/` (see tft-meta).
- Live per-unit/trait performance: datatft `/units`, `/traits` (tft-data) or the explorer (tft-explorer).

## Known gaps

- Unique/one-off traits show as breakpoint `1`; Eclipse has no breakpoints in the export ("see datatft": open `tft-url trait eclipse`).
- Neutral units (Elder Dragon, Krug, Murkwolf) have no trait in the export.
- Unit abilities and stats are not stored: use `tft-url unit <name>` (datatft database).
- Trait descriptions are truncated to 400 characters and have placeholder variables stripped.

## Refresh

`tft-refresh` (in `~/.local/bin`) rewrites `set.*` when the patch changes and `tft-meta/meta.md` every run. Scheduled daily, see `tft-coach` for status.
