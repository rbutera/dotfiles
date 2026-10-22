---
name: tft-data
description: Look up TFT facts on datatft.com - the /rate cheat sheet (shop odds by level, XP, gold interest, streak gold, augment and orb loot tables, one anchor per loot augment), unit/item/trait/emblem pages, tier lists, comps, explorer. Use when Rai names an augment/item/unit/trait or asks for odds, interest, economy or loot. Includes the tft-url CLI.
---

# tft-data (datatft.com)

datatft.com is a Vue single-page app. Every path returns HTTP 200 with the same empty shell to curl, so open URLs in a browser (Playwright MCP headless, or cua-driver for Rai's Chrome). Wait about 3 s after load, then read `document.body.innerText`. Deep links with `#N` work on a fresh load (verified). Page headers show the version (`Ver: 18.4b`), sample size and "Updated N mins ago": quote them.

## Start here: the cheat sheet `https://www.datatft.com/rate`

Rai's pointer (Discord 2026-10-09): `/rate` is the cheat sheet; "Expected Unexpectedness" is `/rate#14`. Anchors are NOT sequential. All rendered and read 2026-10-09 (S18, 18.4b); gaps (#7-#11, #15, #19-#21) are not in the S18 menu.

| Anchor | Section | Covers |
|---|---|---|
| `#1` | Basic Info | XP needed per level (Lv2 2, Lv3 6, Lv4 10, Lv5 20, Lv6 36, Lv7 56, Lv8 68, Lv9 68), round gold, interest, win/loss streak gold, player damage by stage |
| `#2` | Shop Pool | Shop odds by level and cost, pool sizes (1c 30, 2c 25, 3c 18, 4c 10, 5c 9) |
| `#3` | Augments | Augment refresh (reroll) tier odds: silver/gold/prismatic by choice |
| `#4` | Orbs | Silver/blue/etc orb loot tables by stage |
| `#5` | Coven | Augment loot table |
| `#6` | Trait Ladder | Augment loot by number of traits |
| `#12` | Warpath | Augment loot |
| `#13` | Magic Roll | Augment loot |
| `#14` | Expected Unexpectedness | Augment loot (Stage 2, Stage 3 tables) |
| `#16` | The Golden Egg | Augment loot |
| `#17` | Call To Chaos | Augment loot |
| `#18` | Loot Subscription | Augment loot |
| `#22` | Slightly Magic Roll | Augment loot by dice points |
| `#23` | Expedition | Augment loot |
| `#24` | Hard Commit | Emblem + unit choices |
| `#25` | Backline Blueprint | Unit + emblem pairs |
| `#26` | Frontline Foundation | Unit + emblem pairs |
| `#BoosterPack` | Booster Pack | Augment loot |

Facts straight from the page: shop odds (% for 1c..5c) Lv5 45/33/20/2/0; Lv6 30/40/25/5/0; Lv7 16/30/43/10/1; Lv8 15/20/32/30/3; Lv9 10/17/25/33/15; Lv10 5/10/20/40/25. Interest: 10-19g +1, 20-29 +2, 30-39 +3, 40-49 +4, 50+ +5. Streak gold rows 1..6: -, +1, +1, +1, +2, +3 (re-read the page for exact reading). Always re-read the section when quoting; the page is the source.

Loot-augment names resolve with `tft-url augment "<name>"` straight to the anchor. Other augments (Silver Destiny, Rolling For Days, ...) have NO per-augment page: the CLI falls back to `/database?q=<name>#augment` (lists all augments; `q` does not filter) and you read the text, plus the tier list below.

## CLI

`tft-url augment "expected unexpectedness"` -> `/rate#14`; `tft-url rate "shop odds"` -> `/rate#2`; `tft-url rate interest` -> `/rate#1`; `tft-url unit veigar`; `tft-url item "rabadons deathcap"`; `tft-url trait elderwood`; `tft-url emblem blossom`; `tft-url page odds`. Fuzzy name match; URL on stdout, matched name on stderr. IDs for units/items/traits are in `ids.json` beside this file (S18, 18.4b, scraped 2026-10-09).

## Other verified URL patterns (rendered 2026-10-09)

| What | URL |
|---|---|
| Unit page | `/detail?id=<heroId>&type=hero` (Veigar `918045`) |
| Item page | `/detail?id=<equipId>&type=equip` (Rabadon's `553`) |
| Emblem page | same, emblems are equip ids (Blossom `33019`, Elderwood `33024`) |
| Trait page | `/detail?id=DA_18_Elderwood&type=trait&traitLevelIdx=0` |
| Stat tables | `/units`, `/items`, `/traits` (play rate, place, top4, win; rows link to detail pages) |
| Augment database | `/database#augment` (all augments: tier colour, category, round, effect text) |
| Augment tier list | `/augment/tier` (tiers by 2-1, 3-2, 4-2) |
| Augment exclusion rules | `/augment-rules` |
| Comps | `/comps`, `/comp/rank`, `/comp/allinone` |
| Explorer | `/explorer` (see tft-explorer; MetaTFT is easier to drive) |
| Rolling odds calculator | `/calculator` (target cost, level, copies out, gold, XP) |
| Economy table | `/economy` (Chinese-labelled) |

## Not verified

- Per-augment effect pages other than the /rate loot augments.
- `/item/tier`, `/rolldown`, `/comp/rank` content (routes exist, not read).
- Whether the S17 toggle changes the /rate anchors (S18 is the default).

## Re-scraping ids

Open `/units`, `/items`, `/traits`; collect `a[href^="/detail?"]` hrefs with the row's name; rewrite `ids.json`. For /rate anchors, click each menu entry and read the hash.
