---
name: tft-explorer
description: Explorer stats for SPECIFIC TFT combinations - "unit X holding items A+B, what is the best third item", "emblem A + emblem B placements", "unit + trait tier performance". Uses MetaTFT's explorer API through the tft-explore CLI (no browser). Use instead of generic tier lists whenever Rai names a combination.
---

# tft-explorer (MetaTFT explorer API)

## Choice and why

| Site | Filters in URL? | Agent-drivable? | Verdict |
|---|---|---|---|
| **metatft.com/explorer** | Yes: `?tab=games&unit_item=...&unit=...` and the page calls a plain JSON API that works with `curl` | Best | **Chosen** |
| tactics.tools/explorer | No query params seen; advanced filters are patron-only (page says so) | Click-driven only | Not used |
| datatft.com/explorer | Has Level/Emblem/Artifact/Radiant/3-Star filters, Save/Share; filter state not seen in the URL | Click-driven | Fallback / cross-check |

All checked 2026-10-09 (patch 18.4b). The MetaTFT API is unofficial and undocumented: if it changes, fall back to the UI URL form below.

## Use the CLI (`~/.local/bin/tft-explore`)

```
tft-explore third "Master Yi" "Guinsoo's Rageblade" "Edge of Night"        # best third item
tft-explore third "Master Yi" "Guinsoo's Rageblade" --artifacts             # include artifacts
tft-explore combo --item "Brawler Emblem" --item "Blossom Emblem"          # both emblems on the board
tft-explore combo --unit "Master Yi" --trait Blossom:3                      # trait tier index, see below
tft-explore combo --unititem "Sett=Warmog's Armor,Gargoyle Stoneplate"      # unit holding these items
flags: --days N (default 3)  --min N (min games, default 150)  --ranks A,B  --json
```

Worked outputs (live, 2026-10-09, Platinum+, last 3 days):
- `third "Master Yi" "Guinsoo's Rageblade" "Edge of Night"`: baseline avg 4.39, n=28,889. Best completed third items with n>=150: Giant Slayer 4.19 (n=405), Quicksilver 4.30 (n=1,206), Bloodthirster 4.31. Titan's Resolve is the most common (n=6,872) at 4.47. With `--artifacts` Hellfire Hatchet is 3.65 avg (n=667).
- `combo --item "Brawler Emblem" --item "Blossom Emblem"`: avg 4.07, top4 58.2%, win 15.8%, n=7,582.
- `combo --unit "Master Yi" --trait Blossom:3`: avg 4.83, top4 43.0%, n=32,017.

## Answering "best third item"

Report: top 3 by avg place with their n, the baseline, and the most-played option if it is not in the top 3. Ignore rows under ~150 games (noise). Say the sample is "games where the unit holds these items", which is correlational: strong boards also get strong items. Prefer items that are available to Rai right now (components held) over the raw leader.

## Raw API (if the CLI breaks)

Base `https://api-hc.metatft.com/tft-explorer-api/<endpoint>?formatnoarray=true&compact=true&queue=1100&patch=current&days=3&rank=CHALLENGER,DIAMOND,EMERALD,GRANDMASTER,MASTER,PLATINUM&permit_filter_adjustment=true&<filters>`
- Endpoints verified: `total` (returns `placement_count` = games finishing 1st..8th), `units_unique`, `items_unique`, `traits`, `unit_items`, `recent_matches`.
- Filters verified: `unit_unique=<UnitId>-<star>` (star 1..3, exact), `item_unique=<ItemId>-1` (repeat the param to AND several), `unit_item_unique=<UnitId>-1%26<ItemId>-1` (unit holding item; repeat the param for each extra item, a single value with three `%26` parts returns zero), `trait=<TraitId>_<tierIndex>` (tier index of the breakpoint, 1 = first breakpoint; Blossom_5 = the 11-Blossom tier).
- Ids: units `DA_18_MasterYi_AD`, items `DA_GuinsoosRageblade`, `DA_Artifact_HellfireHatchet`, emblems `DA_18_EmblemBrawler`, traits `DA_18_Blossom`. List them from `units_unique` / `items_unique` / `traits` with no filter.
- **Tell for a wrong filter name: `placement_count` is the same number in all 8 slots** (e.g. `[471749,471749,...]`). That is the unfiltered fallback, not a real result. Zeros mean the filter is valid but no games match.
- Avg place = sum((i+1) * count_i) / sum(count_i).

## UI URL form (to show Rai or use a browser)

`https://www.metatft.com/explorer?tab=items&unit_item=DA_18_MasterYi_AD-1%26DA_GuinsoosRageblade-1&unit=DA_18_MasterYi_AD-1` (tabs: `games`, `items`; verified). The UI's Items tab lists items on the whole board in those games; the API route above is more exact for "held by this unit".

## Browser notes

Playwright MCP (`mcp__plugin_playwright_playwright__*`) works headless for the UI pages (wait ~4 s). OpenTabs drives Rai's real Chrome. You rarely need either: the API is curl-able.
