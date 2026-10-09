---
name: tft-meta
description: Current TFT meta from tftflow.com - which comps are Default/Meta/Other, their economy plan, and the CONDITIONS (items, artifacts, emblems, augments) that raise a comp's tier. Use for "what's meta", "is comp X good", "what makes X work", "should I go X with what I have".
---

# tft-meta (tftflow.com)

tftflow.com is server-rendered WordPress: plain `curl` works, no browser needed. It is a patch flowchart, not a stats site: tiers are hand-assessed by the author and every comp has a BASE tier plus CONDITIONS that move it up. Verified 2026-10-09 (patch 18.4, Set 18).

## Fast path (CLI, `~/.local/bin/tft-flow`)

```
tft-flow patch                    # patch + the author's patch insights
tft-flow comps                    # every comp: section, economy plan, go-signal conditions, when to play
tft-flow comp "elderwood veigar"  # base tier, tier-up condition ladder, tips, per-stage economy
tft-flow cond "dawncore"          # which comps this item/augment/emblem boosts, and to what tier
```
A snapshot refreshed daily is in `meta.md` next to this file (check its `patch:` and `refreshed:` lines against today and the live patch before relying on it; run `tft-refresh` or `tft-flow comps` for live).

## How to read the site

- **Home `https://tftflow.com/`**: three sections. **Default** = most consistent comps, one player per lobby, consider first every game. **Meta** = strong but opener/item/augment dependent, "play toward them when you have the spot". **Other** = situational, strong only with specific conditions. Each card shows the economy plan badge (Fast 8, Fast 9, or a number = that-cost reroll), a "when to play" line, and 3 icons = the headline GO-SIGNALS (artifact, augment or emblem that make the comp work).
- **Comp page `https://tftflow.com/composition/set18/<slug>`**: Base tier ("Primary / Tier / B") then "Strong Conditions" as a ladder: `+1 Tier: B -> A`, `+2: B -> S`, `+3: B -> S+`, `+4: B -> OP`, each followed by the items/augments that grant it. Example (Elderwood Veigar, base B): Radiant Adaptive Helm -> OP; Dawncore or Radiant Blue Buff -> S+; Eternal Pact, Flora Fatalis Emblem, Golden Gamble -> S; Luden's Tempest, Lich Bane, Radiant Gargoyle/Warmog, Missed Connections, Golden Gamble+ -> A. Below that: tips, per-stage economy plan, item builds.
- **Conditions index `https://tftflow.com/conditions/set18`**: the reverse view. Each item, artifact, radiant, emblem or augment lists the comps it boosts and to which tier. Use it for "I just got X, what do I play".
- Other pages: `/line-selection/set18` (which line to commit to), `/tables/set18` (new/changed things), `/patch-changes/set18`, `/tier-list`.

## Answering "should I go comp X with what I have?"

1. `tft-flow comp "<X>"`: note base tier and economy plan.
2. Match Rai's items/augments/emblems/artifacts against the condition ladder. Highest matching rung = effective tier. No match = base tier, and say so.
3. Check the opener / "when to play" line (the cards often require a specific unit opener or copies, e.g. "Play from high copies of Ornn / Veigar").
4. Check patch insights for nerfs/buffs hitting the comp's units (this patch: Juggernaut lines weaker, Ashe nerfed, Riftbeast buffed).
5. Answer in one line: "Yes, effective S+ with Dawncore, Fast 8 shape" or "Base B and you have no condition, stay flexible". For "what do I play with item X": `tft-flow cond "<X>"`, then filter by his units.

Tiers are the author's judgement, not placement data. If Rai wants numbers for a specific build, hand off to `tft-explorer`.

## Unverified

- The meaning of the "Required" overlay on comp cards (appears when a condition is mandatory; the CLI does not extract it). Open the comp page and look.
- Condition ladders for comps in the "Other" section were not each inspected; the page layout is the same.
