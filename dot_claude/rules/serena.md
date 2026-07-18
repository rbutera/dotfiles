# Serena — symbolic code navigation

For any code work, prefer Serena's symbolic tools (`mcp__serena__*`) over native read/grep. They are LSP-backed and read at symbol granularity instead of pulling whole files into context.

- Discover structure with `get_symbols_overview`, then `find_symbol` — not a full-file Read.
- Trace usage with `find_referencing_symbols` before changing a shared symbol.
- Edit whole symbols with `replace_symbol_body` / `insert_before_symbol` / `insert_after_symbol`; rename with `rename_symbol` (updates references).
- Reserve native Grep/Glob for discovery and native Read for non-code files or a few known lines.

You do NOT need to call `initial_instructions` first — this rule is the instruction. Serena's own startup nudge to call it is a no-op; ignore it.

Applies wherever Serena is registered (the `~/focused` workspace via `.mcp.json`, and any repo you activate). If the `mcp__serena__*` tools are not present in a session, Serena is not registered for that project — skip this rule rather than trying to call absent tools.
