# Zed config changes log

## 2026-04-09 — Initial Zed setup, ported from VSCode

### Motivation
Rai wants to try Zed as a VSCode replacement. Full config created from scratch,
porting all relevant settings from the existing VSCode configuration on nimbus.

### What was created

**`dot_config/zed/settings.json`** — main Zed settings:
- Vim mode enabled with system clipboard, smartcase find, relative line numbers,
  yank highlighting
- Catppuccin Mocha theme (dark) + Catppuccin Latte (light), matching the VSCode
  `workbench.colorTheme: "Catppuccin Mocha"` setting
- Catppuccin Mocha icon theme
- Font: Monaspace Neon at 13px/450 weight with all stylistic sets (ss01–ss09),
  ported from VSCode's `editor.fontFamily` and `editor.fontLigatures`
- UI font: Inter (matching VSCode's APC sidebar/titlebar font)
- Terminal font: JetBrainsMono Nerd Font at 12px (matching VSCode terminal font)
- Hard tabs, tab size 2 (matching VSCode `editor.insertSpaces: false`, `editor.tabSize: 2`)
- Format on save enabled (matching VSCode `editor.formatOnSave`)
- Trailing whitespace NOT removed (matching VSCode `files.trimTrailingWhitespace: false`)
- Minimap disabled (matching VSCode `editor.minimap.enabled: false`)
- Relative line numbers (matching VSCode `editor.lineNumbers: "relative"`)
- Sticky scroll enabled (matching VSCode `editor.stickyScroll.enabled`)
- Breadcrumbs disabled (matching VSCode `breadcrumbs.enabled: false`)
- Project panel on right (matching VSCode `workbench.sideBar.location: "right"`)
- Smartcase search enabled
- Semantic highlighting full (matching VSCode `editor.semanticHighlighting.enabled`)
- Inline blame with 500ms delay
- External agents: Claude Code (claude-acp) and Codex (codex-acp) configured
- Language-specific overrides for JS, TS, TSX, JSON, HTML, CSS, Markdown, Python,
  Go, Lua, Shell, SQL, Rust — matching VSCode formatter-per-language config

**`dot_config/zed/keymap.json`** — custom keybindings:
- All VSCode vim `normalModeKeyBindingsNonRecursive` ported where possible:
  - `<leader>ff` → file finder
  - `<leader>fw` → project search
  - `<leader>fb` → buffer/tab switcher
  - `<leader>fo` → open recent
  - `<leader>bb/bd/bc/bC` → buffer management
  - `<leader>c` → close editor
  - `<leader>\` / `<leader>|` → split right/down
  - `<leader>`` → toggle sidebar
  - `<leader>la/lr/lf/ld/lR` → LSP actions
  - `<leader>q/Q` → quick fix
  - `<leader>/` → toggle comment
  - `<leader>yj/yk` → duplicate line down/up
  - `<leader>p` → peek definition
  - `K` / `gl` → hover info
  - `gd/gr/gD/gI/gy` → go to definition/references/declaration/implementation/type
  - `]d/[d` → next/prev diagnostic
  - `]b/[b` → next/prev buffer
  - `<leader>T` → project symbols, `<leader>t` → file outline
  - `zC/zO` → fold/unfold all
  - `<leader>o/O` → new line below/above without insert mode
  - `<leader>ac` → Claude Code agent, `<leader>ax` → Codex agent
- Visual mode: comment toggle, block comment, duplicate selection
- Ctrl+w h/j/k/l for pane navigation (vim window movement)
- Global: ctrl+` for terminal, cmd+p for file finder

## 2026-04-15 — Fix 7 broken keymap actions + deprecation renames

### Problem
Zed was logging errors on startup for actions that don't exist (were renamed
or never existed). All 7 were in `dot_config/zed/keymap.json`.

### What was changed

| Binding | Broken action | Replacement | Rationale |
|---|---|---|---|
| `space f s` | `workspace::DeploySearch` | `buffer_search::Deploy` | In-file search (`space f w` already covers project search) |
| `space Q` | `editor::QuickFix` | `diagnostics::Deploy` | Opens diagnostics panel (closest equivalent) |
| `space space /` (normal) | `vim::ClearSearch` | `["workspace::SendKeystrokes", ": n o h enter"]` | Simulates `:noh` — Zed has no dedicated clear-highlight action |
| `space p` | `editor::PeekDefinition` | `editor::GoToDefinitionSplit` | Opens definition in a split pane (Zed has no peek window) |
| `space 5` | `workspace::TogglePanelPositions` | `workspace::ToggleZoom` | Zoom/restore current pane (no panel position toggle in Zed) |
| `space a c/x` | `{ "registry": ... }` | `{ "custom": ... }` | Zed agent API uses `custom` variant, not `registry` |
| `space space /` (visual) | `editor::ToggleBlockComment` | `editor::ToggleComments` | Zed has no separate block comment action |
| `space k h` | `pane::RevealInProjectPanel` | `project_panel::ToggleFocus` | Toggle + focus project panel (open/close sidebar) |
| `ctrl-w h/l/k/j` | `workspace::ActivatePaneInDirection` + arg | `workspace::ActivatePane{Left,Right,Up,Down}` | Deprecated parameterized action → dedicated actions (auto-migrated by Zed) |

### VSCode settings NOT ported (Zed equivalent doesn't exist or N/A)
- APC custom CSS/electron tweaks (VSCode-specific UI hacks)
- Peacock color per-workspace
- Extension-specific settings (Jest, Wallaby, TabNine, Supermaven, etc.)
- `editor.acceptSuggestionOnEnter: "off"` (Zed handles differently)
- `editor.definitionLinkOpensInPeek` (Zed uses different peek model)
- Custom tokenColorCustomizations (Zed uses theme system)
- Settings Sync gist (Zed has its own sync)
