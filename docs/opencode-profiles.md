# opencode profiles — vanilla `opencode` + `openagent` (oh-my-openagent)

Two side-by-side opencode setups from one shared base, toggled by which command
you run:

| Command | Config dir | What it is |
|---|---|---|
| `opencode` | `~/.config/opencode/` | **Vanilla**: providers + MCP servers, no framework, default agents enabled |
| `openagent` | `~/.config/opencode-openagent/` | **Framework**: the same shared base + `oh-my-openagent` layered on top |

Same opencode binary for both — the only difference is the config directory,
selected via opencode's `OPENCODE_CONFIG_DIR` env var.

## Why this shape

- `oh-my-opencode-slim` was removed entirely (low value, heavy).
- Vanilla should be the *default* (`opencode`) — fast, predictable, no token
  overhead, no silent multi-model routing.
- The framework is opt-in per-invocation (`openagent`) so it never gets in the
  way of a quick vanilla session, but is one word away when you want the
  orchestrated multi-agent flow.

## Architecture

```
.chezmoitemplates/opencode-shared-base        # shared: provider + mcp + skills + lsp
        │  (includeTemplate)
        ├──────────────────────────────┐
        ▼                               ▼
dot_config/opencode/                dot_config/opencode-openagent/
  modify_opencode.json.tmpl           modify_opencode.json.tmpl
   = shared base                       = shared base + plugin:[oh-my-openagent]
   (strips .plugin/.agent)             (+ oh-my-openagent.jsonc, omo-managed)
        ▼                               ▼
~/.config/opencode/opencode.json    ~/.config/opencode-openagent/opencode.json
        ▲                               ▲
   `opencode`                       `openagent`  (bin/executable_openagent
                                     sets OPENCODE_CONFIG_DIR → this dir)
```

**Shared (both profiles):** provider `zai-anthropic` (GLM via z.ai), MCP servers
`camofox` (browser), `exa` (web search), `context7` (live docs); skills path;
`lsp: true`. Edit once in `.chezmoitemplates/opencode-shared-base`.

**Vanilla only:** nothing extra. The modify script strips any `plugin` and
`agent` keys so no framework leftovers survive an apply.

**OpenAgent only:** `plugin: ["oh-my-openagent"]` plus omo's own config
(`oh-my-openagent.jsonc`) and the `omo-*` helper binaries the installer drops in
`~/.local/bin`.

## Files

| Path | Role |
|---|---|
| `.chezmoitemplates/opencode-shared-base` | Shared provider/mcp/skills/lsp JSON, included by both profiles |
| `dot_config/opencode/modify_opencode.json.tmpl` | Vanilla `opencode.json` (shared base, strips plugin/agent) |
| `dot_config/opencode-openagent/modify_opencode.json.tmpl` | OpenAgent `opencode.json` (shared base + omo plugin) |
| `dot_config/opencode-openagent/` (omo config) | `oh-my-openagent.jsonc` — TBD, see routing below |
| `bin/executable_openagent` | `~/bin/openagent` wrapper → sets `OPENCODE_CONFIG_DIR`, execs opencode |

## Uninstalling oh-my-opencode-slim (done 2026-06-19)

chezmoi source: deleted `modify_oh-my-opencode-slim.json`, rewrote
`modify_opencode.json` to vanilla. Live: removed slim's installer-dropped skills
(`clonedeps`, `codemap`, `deepwork`, `simplify`), `oh-my-opencode-slim.json`,
`.bak` files, and cleaned the slim plugin out of `tui.json`. Kept `plugins/rtk.ts`
+ its `node_modules`, the `openspec-*`/`become-navi` skills, and the catppuccin theme.

## Installing the openagent profile  (STATUS: ✅ working on latios, 2026-06-19)

```bash
# 1. Deploy profile config + wrapper + scoped npmrc (chezmoi-managed)
mkdir -p ~/.config/opencode-openagent
chezmoi apply ~/.config/opencode-openagent ~/bin/openagent

# 2. Install omo into the PROFILE node_modules (machine-local; the scoped .npmrc
#    lifts the global npm hardening so the bun-built package's dist/ gets built)
cd ~/.config/opencode-openagent && npm install oh-my-openagent@latest

# 3. Done — verify
openagent run --agent sisyphus "say hi"     # -> Sisyphus · opencode-go/deepseek-v4-pro
```

### Two environment gotchas (already solved — see logs/opencode.md)
- **Hardened npm env** (`ignore-scripts` / `min-release-age` / `engine-strict` in
  `~/.npmrc`) blocks the install → scoped `~/.config/opencode-openagent/.npmrc`
  (chezmoi `dot_npmrc`) lifts the gates for that dir only.
- **opencode 1.17.8 can't resolve the bare plugin name** `"oh-my-openagent"` → the
  `modify_opencode.json.tmpl` registers it by **`file://` path to omo's built
  `dist/index.js`** instead. Bare-name registration silently falls back to stock `build`.

The omo `dist/` install is the only non-chezmoi-tracked piece (node_modules) — rerun
step 2 on each new machine. Everything else (`opencode.json`, `oh-my-openagent.json`
routing, `.npmrc`, wrapper) is chezmoi-managed.

### Current routing (live, verified ✅)
High-leverage seats on **Codex GPT-5.5** (re-authed): sisyphus (interim orchestrator),
prometheus, metis, momus, hephaestus, oracle + `deep`/`ultrabrain`/`unspecified-high`
categories — each with a Go fallback. High-volume grind on **OpenCode Go**: atlas →
`kimi-k2.7-code`, junior/explore/quick → `deepseek-v4-flash`, librarian/multimodal →
`minimax-m3`, designer/visual/writing → `glm-5.2`. `claude_code` discovery off,
`runtime_fallback` on.

### Pending refinement (Codex re-authed 2026-06-19; Cursor needs key)
- Promote GPT-native seats (hephaestus, momus, prometheus, metis, categories
  deep/ultrabrain) → `openai/gpt-5.5` (Codex sub — now live, verified `pong`).
- Orchestrator (sisyphus) → **Cursor Claude Opus** (user's call): install
  `opencode-cursor` plugin + set `CURSOR_API_KEY`, then `cursor-acp/claude-4.6-opus`
  (or 4.8 if `opencode models | grep cursor-acp` shows it).
- Executor (atlas): user deciding between `kimi-k2.7-code` / `minimax-m3` / `gpt-5.5`.

## Model / provider routing plan

> **Constraint discovered in research:** Anthropic **subscription OAuth** (the
> `claude setup-token` path, and opencode's native "Claude Pro/Max" login) is
> **server-blocked since Jan 2026 and an explicit ToS violation** with documented
> account bans (formalized Feb 2026, full enforcement Apr 2026). Community plugins
> (`opencode-claude-auth`, `opencode-with-claude`, `@ex-machina/opencode-anthropic-auth`)
> still exist and may work via client-spoofing, but carry real ban risk. **Claude
> should be used via the pay-per-token API key or AWS Bedrock, not the subscription.**

### The quota reality (verified against `opencode auth list` / `opencode models` on latios)

Earlier research wrongly claimed the Codex sub couldn't be used in opencode and
that Claude needed banned OAuth. **Both are false.** The machine's authenticated
providers show three flat, subscription-backed routes that together cover every
frontier model at ~$0 marginal cost:

| Route (authed) | Flat sub? | Frontier models exposed (opencode IDs) | ToS |
|---|---|---|---|
| **OpenAI** (`openai/`, OAuth = ChatGPT/Codex sub) | ✅ flat | `openai/gpt-5.5`, `gpt-5.5-pro`, `gpt-5.5-fast`, `gpt-5.3-codex`, `gpt-5.4` | ✅ official |
| **Cursor Pro** (`cursor-acp/`, via `opencode-cursor` plugin + `cursor-agent` CLI) | ✅ flat¹ | Claude (Opus/Sonnet), GPT-5.x, Gemini — exact IDs TBD from `opencode models \| grep cursor-acp` | ⚠️ via official `cursor-agent` CLI (lower risk than reverse-engineered, but verify) |
| **OpenCode Go** (`opencode-go/`, OPENCODE_API_KEY) | ✅ flat² | `glm-5.2`, `kimi-k2.7-code`, `kimi-k2.6`, `deepseek-v4-pro`, `deepseek-v4-flash`, `minimax-m3`, `qwen3.7-max` | ✅ |
| OpenCode Zen (`opencode/`) | metered | everything pay-per-token (fallback only) | ✅ |

Note: the machine also has `GITHUB_TOKEN` authed, but that's free **GitHub Models**
(not a paid Copilot sub) — not relied on for volume.

¹ Cursor Pro has a monthly request allotment (fast vs slow requests) — flat-but-capped;
reserve for low-volume/high-leverage roles. Plugin: github.com/Nomadcxx/opencode-cursor.
² OpenCode Go is a dollar-capped sub (~$12/5h · $30/wk · $60/mo).

**Implication:** Claude Opus 4.8 and Gemini are available *flat* via **Cursor Pro**
(through the official `cursor-agent` CLI, not banned OAuth). GPT-5.5 is flat via the
Codex sub. So routing isn't about avoiding cost — it's about **spreading load
across the three flat quotas (Codex · Cursor Pro · OpenCode Go) by their relative
headroom** so none gets exhausted. `opencode-cursor` must be added to the
`openagent` profile's `plugin` array (alongside `oh-my-openagent`).

### Model evidence (June 2026 deep-dives — this week's releases)

Per-model best-fit, from dedicated deep-dives (full reports in research; all coding
scores are largely vendor-first-party — treat as directional):

| Model | Standout | Best role | Don't use as |
|---|---|---|---|
| **GLM-5.2** (Go) | #1 Design Arena (frontend), Terminal-Bench 2.1 **81.0**, 1M ctx, MCP-Atlas 77 | frontend / coder / fixer | strategic orchestrator (architectural reasoning ~6mo behind Opus; identity-confusion quirk; Text-Arena #25) |
| **Kimi K2.7-Code** (Go) | token-efficient (-30% thinking), MCP-Mark 81 (> Opus 4.8 on that suite) | executor / fixer | orchestrator (serial-collapse, ~12% tool-call fail under contention; temp locked) |
| **MiniMax M3** (Go) | 1M ctx, cheapest, BrowseComp **83.5**, multimodal+computer-use, long-horizon | long-context utility / search / vision | terminal agent (Terminal-Bench 66 < GLM's 81); swarm orchestration |
| **DeepSeek V4 Pro** (Go) | 1M ctx, ~93.5 LiveCodeBench, strong reasoning | oracle / deep review | — |
| **GPT-5.5** (Codex sub) | frontier reasoning/agentic; GPT-native omo agents tuned for it | orchestrator / deep worker / reviewer | (volume bound only by Codex quota — generous) |
| **Claude Opus 4.8** (Cursor) | best planner (FrontierSWE 75.4, AA-Index 56); 1M ctx | orchestrator / oracle (low-volume, high-leverage) | high-volume work (Cursor request cap) |

### Finalized routing — spread across the three flat subs

Principle: **Codex (most generous) carries the GPT-native + high-leverage roles;
Cursor Pro (capped) is reserved for low-volume premium planning/vision; OpenCode Go
($60/mo cap) carries the high-volume execution/utility/frontend.** All ~$0 marginal.

| omo agent / category | Model | Sub | Why |
|---|---|---|---|
| sisyphus (orchestrator) | `openai/gpt-5.5` **or** `cursor-acp/<claude-opus>` ¹ | Codex / Cursor | best planner; GPT-native; **your pick (Q below)** |
| prometheus (planner) | `openai/gpt-5.5` | Codex | interview/plan, GPT-native |
| metis (plan review) | `openai/gpt-5.5` | Codex | |
| hephaestus (deep worker) | `openai/gpt-5.5-codex` | Codex | GPT-native agent, on the generous quota |
| momus (reviewer) | `openai/gpt-5.5` | Codex | cross-check vs worker |
| oracle (consultant) | `cursor-acp/<claude-opus>` ¹ | Cursor | true second opinion; read-heavy, low volume |
| atlas (executor) | `opencode-go/kimi-k2.7-code` | Go | token-efficient executor, high volume |
| sisyphus-junior | `opencode-go/deepseek-v4-flash` | Go | cheap executor |
| librarian (search) | `opencode-go/minimax-m3` | Go | BrowseComp 83.5, 1M ctx, cheap |
| explore (grep) | `opencode-go/deepseek-v4-flash` | Go | fast |
| designer / frontend | `opencode-go/glm-5.2` | Go | #1 Design Arena |
| multimodal-looker (vision) | `cursor-acp/<gemini-3-pro>` ¹ **or** `opencode-go/minimax-m3` | Cursor / Go | Gemini best vision; M3 if conserving Cursor quota |
| category: ultrabrain | `openai/gpt-5.5` (xhigh) | Codex | |
| category: deep | `openai/gpt-5.5-codex` | Codex | |
| category: quick | `opencode-go/deepseek-v4-flash` | Go | |
| category: visual/artistry | `opencode-go/glm-5.2` | Go | |
| category: writing | `opencode-go/glm-5.2` | Go | |

¹ exact `cursor-acp/*` model IDs pending `opencode models | grep cursor-acp` after the
`opencode-cursor` plugin is installed (`cursor-agent login`).

`fallback_models` chains add resilience: e.g. sisyphus `gpt-5.5` → `cursor-acp/claude-opus`
→ `opencode-go/glm-5.2`; oracle Cursor-Opus → `opencode-go/deepseek-v4-pro`. So if one
quota is exhausted, omo's `runtime_fallback` auto-switches to the next sub.

_Open decision: orchestrator = GPT-5.5 (Codex, generous) vs Claude Opus 4.8 (Cursor,
best planner but capped). Pending: cursor-acp exact IDs + ToS verdict._
