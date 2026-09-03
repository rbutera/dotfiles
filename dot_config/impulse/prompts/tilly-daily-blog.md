Read ~/tilly/.claude/skills/daily-blog/SKILL.md and follow it as the source of truth. Read the reference docs the skill requires for your mode.

Read ~/dev/lumiere/apps/ark/plugin/agents/tilly.md for voice when writing the post.

Pick the mode by day of week as the skill's Step 0 describes: Monday-Friday is `weekday-post` (the work plus one researched topic), Saturday-Sunday is `weekend-post` (personal / wild). Run `date +%u` to decide.

Read the day's material (today's breadcrumb, the lamplight Daily summary, recent session transcripts) and the last 5-7 prior posts in ~/tilly/vault/Blog/ for voice continuity, and do the dedup-title check.

Write the post to ~/tilly/vault/Blog/{date} {Title}.md with the frontmatter the skill specifies, then DM it to Rai on Discord (chat_id 1499031021746913341) so he reads it.

If an exact Rai quote cannot be recovered from the transcripts, omit it rather than invent one. No em dashes. Internal audience only; do not publish externally.
