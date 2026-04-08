---
name: Add MCP Server
description: This skill should be used when the user asks to "add an MCP server", "install an MCP", "add a new MCP to all machines", "persist MCP config", "update MCP servers in chezmoi", "add MCP to codex", "add MCP to claude code", or discusses adding, removing, or managing global MCP server configurations across machines using chezmoi modify scripts.
---

# Add MCP Server to All Machines

This dotfiles repo manages MCP server configurations via chezmoi `modify_` scripts. These scripts merge managed base config into each tool's config file while preserving runtime state (per-project permissions, trusted projects, etc.).

## Architecture

Three modify scripts manage MCP configs across tools:

| File | Target | Format | Merge tool |
|---|---|---|---|
| `modify_dot_claude.json.tmpl` | `~/.claude.json` | JSON (chezmoi template) | `jq` |
| `dot_claude/modify_settings.json` | `~/.claude/settings.json` | JSON | `jq` |
| `dot_codex/modify_private_config.toml` | `~/.codex/config.toml` | TOML | Python `tomllib`/`tomli_w` |

`modify_dot_claude.json.tmpl` manages `mcpServers`. `modify_settings.json` manages `enabledPlugins`. The Codex script manages `mcp_servers`, `model_providers`, and `plugins`.

## Workflow: Adding a Global MCP Server

### Step 1: Determine server config format

MCP servers come in two formats:

**Command-based** (local process):
```json
{
  "server-name": {
    "command": "npx",
    "args": ["-y", "@package/name@latest"]
  }
}
```

**HTTP-based** (remote URL):
```json
{
  "server-name": {
    "url": "https://mcp.example.com",
    "bearer_token_env_var": "MY_TOKEN_ENV_VAR"
  }
}
```

### Step 2: Add to Claude Code

Edit `modify_dot_claude.json.tmpl` in the chezmoi source directory. Add the new server to the `base_mcps` JSON heredoc within the `MCPS` block. Maintain valid JSON — add a comma after the previous entry.

### Step 3: Add to Codex CLI

Edit `dot_codex/modify_private_config.toml` in the chezmoi source directory. Add the new server to the `BASE["mcp_servers"]` Python dict. For paths that need the home directory, use `f"{HOME}/path"` since `HOME = os.environ["HOME"]` is defined at the top.

### Step 4: Apply

```bash
chezmoi apply ~/.claude.json ~/.codex/config.toml
```

Verify idempotency:
```bash
chezmoi diff ~/.claude.json ~/.codex/config.toml
# Should produce no output
```

### Step 5: Add to other tools via add-mcp (optional)

To also add to Cursor, VS Code, Zed, OpenCode:
```bash
npx add-mcp <server> --global --agent cursor,zed,opencode
```

## OS-Conditional MCP Servers

For servers that only make sense on certain platforms (e.g., `arch-linux` on Arch systems), use OS conditionals:

**In `modify_dot_claude.json.tmpl`** (chezmoi template syntax):
```
{{- if or (eq .chezmoi.osRelease.id "arch") (and (hasKey .chezmoi.osRelease "idLike") (eq .chezmoi.osRelease.idLike "arch")) }}
  ,"arch-linux": {
    "command": "uvx",
    "args": ["arch-ops-server"]
  }
{{- end }}
```
Place this inside the `base_mcps` JSON heredoc, just before the closing `}`.

**In `dot_codex/modify_private_config.toml`** (Python runtime check):
```python
_is_arch = False
try:
    with open("/etc/os-release") as f:
        for line in f:
            if line.startswith(("ID=arch", "ID_LIKE=arch")):
                _is_arch = True
                break
except FileNotFoundError:
    pass

if _is_arch:
    BASE["mcp_servers"]["arch-linux"] = {
        "command": "uvx",
        "args": ["arch-ops-server"],
    }
```
Place this after the `BASE` dict definition and before the `deep_merge` function. The Codex script cannot use chezmoi templates (Python syntax conflicts with `{{ }}`), so it reads `/etc/os-release` at runtime instead.

Always use `hasKey` before accessing `.chezmoi.osRelease.idLike` in templates — it may be absent on minimal installs.

## Machine-Specific Environment Variables

For servers that need machine-specific credentials (e.g., local database connections), use chezmoi host groups in `dot_zshenv.tmpl` to set env vars conditionally:

```
{{- if has .chezmoi.hostname .host_groups.dev_infra }}
export DB_URL="postgresql://..."
{{- end }}
```

Host groups are defined in `.chezmoidata.toml`. The MCP server config itself stays global — only the env var it references is machine-specific.

## Environment Variables for MCP Servers

If a new MCP server needs an API key or token:

1. Store the secret in 1Password
2. Add an export to `dot_zshenv.tmpl`: `export TOKEN_NAME={{ onepasswordRead "op://Private/item/field" }}`
3. Reference the env var in the MCP config via `bearer_token_env_var` (Codex) or rely on the server reading it from the environment (Claude Code)

## Removing a Global MCP Server

Remove the entry from `base_mcps` in `modify_dot_claude.json.tmpl` and from `BASE["mcp_servers"]` in `modify_private_config.toml`. Then `chezmoi apply`. Note: locally-added servers on individual machines persist until manually removed.

## Additional Resources

### Reference Files

For the full guide including supported formats, dependencies, and cross-tool sync:
- **`references/mcp-guide.md`** — Complete MCP management documentation (symlinked from `docs/mcp.md`)

### Key Files to Edit

- **`modify_dot_claude.json.tmpl`** — Claude Code global MCP servers (JSON/jq)
- **`dot_codex/modify_private_config.toml`** — Codex CLI MCP servers (Python/TOML)
- **`dot_claude/modify_settings.json`** — Claude Code plugins (JSON/jq)
- **`dot_zshenv.tmpl`** — Environment variables / API keys
- **`.chezmoidata.toml`** — Host group definitions
