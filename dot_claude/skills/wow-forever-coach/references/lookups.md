# Data Lookups (Wowhead, Icy Veins, Blizzard)

Tested 2026-11-07. Wowhead's Forever data lives under the `forever` path; never use `/classic/` IDs for Forever, many items and quests are new (IDs in the 260000+ and 90000+ ranges).

## The `wowf` CLI (in `~/.local/bin`)

```
wowf find wolfsbane                      # Item  267369  Wolfsbane   (type, id, name)
wowf tip item 267369                     # stats, proc, binding, class, as plain text + URL
wowf tip quest 92422                     # quest level, objective, giver area
wowf tip zone 16591                      # "Riverglades Level 36-44"
wowf tip npc <id> / wowf tip spell <id>
wowf guide classes/paladin/retribution/dps-leveling-tips    # full guide text
wowf url item 267369                     # link to hand Rai
wowf url search hall of thanes           # search page link
```

Flow for "what does X do / is X good / where is X": `wowf find X`, pick the id, `wowf tip <type> <id>`, answer, then offer the `wowf url` link.

## What Works And What Does Not

| Endpoint | curl | Notes |
|---|---|---|
| `https://nether.wowhead.com/forever/tooltip/{item,quest,npc,spell,zone}/<id>` | yes, any UA | JSON with `tooltip` HTML. The dependable path. `?dataEnv=forever` on the plain tooltip URL 404s. |
| `https://www.wowhead.com/forever/search/suggestions-template?q=<term>` | only with a plain custom UA (`wowf/1.0`) | JSON `results[]`: `type`, `id`, `name`, `typeName`. curl's default UA and browser UAs get a CloudFront 403. |
| `https://www.wowhead.com/forever/search?q=<terms>` | custom UA | HTML with results in `new Listview({...})` JSON. |
| `https://www.wowhead.com/forever/guide/<slug>` | custom UA | Text is in `WH.markup.printHtml("...")`; `wowf guide` decodes it. Index of all guides: `/forever/guides`. |
| `https://www.wowhead.com/forever/item=<id>` (and quest=, npc=, zone=, `?xml`) | no, 403 | Needs a browser (Playwright MCP headless works). Use for drop sources and comments only. |
| Icy Veins `https://www.icy-veins.com/wow-forever/...` | no, 403 to curl and WebFetch | Use `mcp__exa__web_fetch_exa` or Playwright. Talent and zone sliders are JS: the readable text is in the page body, the per-level tables often are not. |

If the custom UA stops working, the block has moved: fall back to Playwright for search, keep using nether tooltips.

## Useful Starting URLs

- Wowhead guide index: https://www.wowhead.com/forever/guides
- Dungeons overview: https://www.wowhead.com/forever/guide/dungeons-overview-locations-details ; every dungeon quest: https://www.wowhead.com/forever/guide/dungeons/every-dungeon-quest-location
- Dungeon guides: `https://www.wowhead.com/forever/guide/<dungeon-slug>-dungeon-overview-location-rewards` (hall-of-thanes, ruins-of-lordaeron, city-of-dalaran, the-drowned-city, excavation-site-wetlands)
- Professions: https://www.wowhead.com/forever/guide/professions/overview ; gathering guides at `/forever/guide/professions/<name>/overview-leveling`
- Camping: https://www.wowhead.com/forever/guide/camping-overview-unlock-rewards
- Roadmap: https://www.wowhead.com/forever/guide/content-release-roadmap
- Icy Veins hub: https://www.icy-veins.com/wow-forever/ ; dungeons: https://www.icy-veins.com/wow-forever/dungeons-overview ; professions: https://www.icy-veins.com/wow-forever/professions-overview
- Class guides: see `classes.md`.

## Blizzard (Primary)

- Server status, Americas & Oceania: https://worldofwarcraft.blizzard.com/en-us/forever/us/server-status (JS page, use a browser)
- Hotfixes: search `news.blizzard.com` for "WoW Forever hotfixes <date>"; Wowhead mirrors them under `/news/`.
- Dev notes thread (Kaivax): https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-november-2/2360696
- Questie (quest addon) for Forever: https://github.com/Questie/Questie (ships `Questie_Forever.toc`).

## Freshness Rules

- Check a guide's "updated" date. Anything before 4 Nov 2026 predates the launch talent rework.
- Wowhead news at `/news/` is the fastest place to see hotfixes; quote the date.
- Advice past level 30 is theory until guides say otherwise (beta cap was 30).
