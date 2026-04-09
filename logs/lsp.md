# LSP / Language Server changes log

## 2026-04-06 — Audit and install missing language servers on nimbus (Mac Mini M4)

### Problem
After migrating to the new Mac Mini M4 (nimbus), the markdown language server was
noticed missing. Suspected other LSPs may not have made the migration either.

### Audit Results

**Mason (Neovim's LSP manager) already had:**
- vtsls (TypeScript/JavaScript)
- basedpyright (Python)
- docker-language-server (Dockerfile)
- terraform-ls (Terraform)
- gopls (Go)
- lua-language-server (Lua)
- bash-language-server (Bash)
- yaml-language-server (YAML)
- tailwindcss-language-server (Tailwind CSS)
- vscode-json/html/css-language-server (JSON, HTML, CSS)
- emmet-ls (Emmet)
- selene, stylua (Lua linting/formatting)
- shellcheck, shfmt (Shell linting/formatting)
- sqls, sqlfluff (SQL)
- taplo (TOML)
- hadolint (Dockerfile linting)
- tflint, tfsec (Terraform linting/security)

**Also installed globally (npm/brew):**
- typescript-language-server (npm)
- bash-language-server (npm)
- yaml-language-server (npm)
- vscode-langservers-extracted (npm)
- tailwindcss-language-server (npm)
- marksman (brew)
- lua-language-server (brew)
- gopls (brew)

### What was missing
- **marksman** — installed via brew but NOT in Mason. Neovim couldn't find it
  because Mason's bin dir is not on the system PATH (it's used internally by
  Neovim via Mason's own resolution).

### Solution
- Installed **marksman** into Mason via `:MasonInstall marksman`
  (`~/.local/share/nvim/mason/bin/marksman` now exists)

### Skipped
- **ESLint LSP / Prisma LSP** — not configured in Neovim config, skipped to
  avoid installing unused tools. Can be added later via `:MasonInstall` if needed.
- No npm global or brew duplicates installed — Mason handles everything Neovim
  needs internally.

### Notes
- Mason's `mason.lua` plugin file is disabled (line 1: `return {}`) so
  `ensure_installed` lists are not active. All Mason packages were installed
  manually or by AstroNvim community packs.
- Mason bin dir (`~/.local/share/nvim/mason/bin/`) is NOT on the system PATH.
  Neovim resolves Mason tools internally. Global installs (npm/brew) are
  separate and serve CLI usage.
