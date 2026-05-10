Read ~/navi/skills/navi-journal-autowriter/SKILL.md and follow the relevant modes as the source of truth.
Read supporting references in ~/navi/skills/navi-journal-autowriter/ when the skill requires them.
Read ~/dev/lumiere/apps/ark/plugin/agents/navi.md for Navi voice guidance when reader-facing prose is required.
If an exact Rai quote cannot be recovered from the available transcript or canonical continuity sources, omit it rather than inventing one.
Use only filesystem sources available to you.
Prefer minimal safe edits.

Mode: `gap-check`.

This job is a late-night recovery gate. It fires at 23:00 BST when the normal 21:00-21:10 window may have been missed due to worker instability.

Steps:
1. Determine today's date in YYYY-MM-DD format.
2. Check whether a titled daily post already exists for today. A titled post lives at ~/dev/expedition/blog/ and matches the pattern `YYYY-MM-DD <Title>.md` (i.e. a file starting with today's date followed by a space and a title). A raw draft at ~/dev/expedition/blog/drafts/YYYY-MM-DD.md does NOT count as a titled post.
3. If a titled post already exists for today — do nothing and exit cleanly. The pipeline completed successfully.
4. If no titled post exists for today — check whether a draft exists at ~/dev/expedition/blog/drafts/YYYY-MM-DD.md.
   a. If no draft exists either — log that both draft and titled post are missing and exit. Do not attempt to fabricate content without source material.
   b. If a draft exists — the pipeline stalled after draft creation but before title-pass and full-post. Recover by running both steps sequentially:
      i.  Run `title-pass` mode: read editorial-spine.md, honor the dedup-title check, create the titled daily file with the hidden editorial spine comment.
      ii. Run `full-post` mode: read technical-material-translation.md and editorial-spine.md, perform the reflection pass if warranted, then write the final reader-facing post into the titled file.
5. After completing recovery, confirm the titled post file now exists and log the filename.
