# MCP Server Management

MCP (Model Context Protocol) servers are managed via chezmoi `modify_` scripts so that the same servers are available on all machines while allowing each tool to freely manage its own runtime state.

## How it works

Each AI tool's config file has a corresponding modify script in the chezmoi source:

| Tool | Modify script | Managed fields | Free fields |
|---|---|---|---|
| Claude Code (settings) | `dot_claude/modify_settings.json` | `cleanupPeriodDays`, `enabledPlugins` | `permissions`, `model`, `attribution`, etc. |
| Claude Code (global MCPs) | `modify_dot_claude.json` | `mcpServers` | `numStartups`, `tipsHistory`, `cachedGrowthBookFeatures`, etc. |
| Codex CLI | `dot_codex/modify_private_config.toml` | base settings, `mcp_servers`, `model_providers`, `plugins`, `sandbox` | `projects`, `notice` |

Modify scripts receive the current file on stdin, merge in the managed base config, and output the result. App-managed fields (per-project permissions, trusted projects, etc.) are preserved untouched.

## Adding an MCP server to all machines

### Codex CLI

Edit `dot_codex/modify_private_config.toml` and add to the `BASE["mcp_servers"]` dict:

```python
BASE = {
    ...
    "mcp_servers": {
        ...
        "my-new-server": {
            "command": "npx",
            "args": ["-y", "@example/mcp-server@latest"],
        },
        # or for HTTP-based servers:
        "my-remote-server": {
            "url": "https://mcp.example.com",
            "bearer_token_env_var": "MY_SERVER_TOKEN",
        },
    },
}
```

Then apply:

```bash
chezmoi apply ~/.codex/config.toml
```

### Claude Code

MCP servers live in `~/.claude.json` (not `settings.json`). Edit `modify_dot_claude.json` and add to the `base_mcps` JSON:

```json
{
  "my-new-server": {
    "command": "npx",
    "args": ["-y", "@example/mcp-server@latest"]
  }
}
```

Then apply:

```bash
chezmoi apply ~/.claude.json
```

For plugins (not MCP servers), edit `dot_claude/modify_settings.json` and add to `enabledPlugins`:

```json
{
  "enabledPlugins": {
    "my-plugin@my-org": true
  }
}
```

```bash
chezmoi apply ~/.claude/settings.json
```

## Adding an MCP server to one machine only

Just configure it directly in the tool's UI or config file. The modify scripts preserve any fields they don't manage, so your local additions survive `chezmoi apply`.

## Removing an MCP server from all machines

Remove the entry from the `BASE` dict (Codex) or `base` JSON (Claude Code) in the modify script. Then `chezmoi apply`. Note: if the server was also added locally on a machine, it will persist there until manually removed (the modify script won't delete keys it doesn't manage).

## Cross-tool sync with add-mcp

[add-mcp](https://github.com/neondatabase/add-mcp) can add MCP servers to multiple tools at once:

```bash
npx add-mcp <server> --global --agent claude,cursor,opencode,codex,zed
```

After using add-mcp, update the chezmoi modify scripts to match so the servers propagate to other machines.

## Dependencies

- `jq` — used by the Claude Code modify script
- `python-tomli-w` — system package used by the Codex modify script (`paru -S python-tomli-w`)

## Supported MCP server formats

**Command-based** (runs a local process):
```toml
[mcp_servers.name]
command = "npx"
args = ["-y", "@package/name@latest"]
```

**HTTP-based** (connects to a remote URL):
```toml
[mcp_servers.name]
url = "https://mcp.example.com"
bearer_token_env_var = "ENV_VAR_WITH_TOKEN"  # optional
```
