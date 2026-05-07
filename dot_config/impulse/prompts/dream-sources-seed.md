Dream sources batch seed: identify and record dream-worthy material from this week.

Step 1 — Read context:
- Read the dream sources skill at ~/navi/skills/navi-dream-sources/SKILL.md for the entry format and dream-worthy bar
- Read ~/dev/lumiere/apps/ark/plugin/agents/navi.md for voice guidance

Step 2 — Compute this week's Monday:
- Run: python3 -c "from datetime import date, timedelta; today=date.today(); print((today - timedelta(days=today.weekday())).strftime('%Y-%m-%d'))"
- Sources file path: ~/dev/expedition/blog/sources/week-of-YYYY-MM-DD.md (substitute the Monday date)

Step 3 — Create or open the sources file:
- If missing, create with this exact header:
  ```
  # Dream Sources — week of YYYY-MM-DD
  
  These are reference materials the weekly journal should weave in, beyond the daily posts.
  Added during the week when something crossed the dream-worthy bar.
  
  ---
  
  <!-- entries will be appended here as the week unfolds -->
  ```
- If it exists, read it to avoid duplicating entries.

Step 4 — Gather this week's material:
- Glob daily blog posts under ~/dev/expedition/blog/
- Glob chronicler day files under ~/dev/lumiere/apps/chronicler/output/days/
- Glob Navi memory files under ~/navi/workspace/memory/
- Read files from Monday through today.

Step 5 — Identify dream-worthy material:
- Apply the bar from the skill: external texture, reframing insight, emotional weight, or Rai's explicit flag.
- Exclude: routine task completions, FYI-level work, things already in the daily posts.
- The bar: would a thoughtful diarist clip this for their week's retrospective?
- Dedup against existing entries.

Step 6 — Append entries in this exact format:
  ```
  - `/path/to/file.md` (or description if no file)
    Author/source: <who produced it> | Type: <type>
    Why dream-worthy: One to three sentences.
    How weekly Navi should use it: What lens this source serves.
  ```
- Name authors explicitly (Hermione, Shikamaru, Rick, Navi, Rai).
- For conversation excerpts, quote briefly inline with date/context.
- Only append. Never overwrite or delete.
