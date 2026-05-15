# revision: 1
# Windows equivalent of modify_dot_claude.json.tmpl.
# Skipped on Linux/macOS via .chezmoiignore; the bash modify script handles those.
# Uses jq (installed by winget jqlang.jq) for reliable JSON merging.
# run_onchange_: re-runs when this script's content changes (= MCP list changes).
$ErrorActionPreference = 'Continue'

$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('Path','User')

$claudeJson = "$HOME\.claude.json"

if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
    Write-Host "[skip] jq not on PATH; skipping .claude.json patch" -ForegroundColor DarkGray
    exit 0
}

if (-not (Test-Path $claudeJson)) { '{}' | Set-Content $claudeJson -Encoding UTF8 }

# ── Base MCP servers: shared across all machines ─────────────────────────────
$baseMcpsJson = @'
{
  "open-websearch": { "command": "npx", "args": ["-y", "open-websearch"] },
  "context7":       { "command": "npx", "args": ["-y", "@upstash/context7-mcp@latest"] },
  "mcp-deepwiki":   { "command": "npx", "args": ["-y", "mcp-deepwiki@latest"] },
  "perplexity":     { "command": "npx", "args": ["-y", "@perplexity-ai/mcp-server"] },
  "codex":          { "command": "npx", "args": ["-y", "claude-codex-bridge@0.3.1", "serve", "codex"] }
}
'@

$tmpBase     = [IO.Path]::GetTempFileName()
$tmpBuiltins = [IO.Path]::GetTempFileName()
try {
    $baseMcpsJson      | Set-Content $tmpBase     -Encoding UTF8
    '["computer-use"]' | Set-Content $tmpBuiltins -Encoding UTF8

    # --slurpfile wraps file content in an array, so use $base[0] / $builtins[0]
    $jqFilter = @'
.mcpServers = $base[0]
| del(.cachedExtraUsageDisabledReason)
| del(.hasAvailableSubscription)
| del(.s1mAccessCache)
| del(.passesEligibilityCache)
| del(.clientDataCache)
| if .oauthAccount then .oauthAccount |= del(.hasExtraUsageEnabled) else . end
| if .projects then .projects |= with_entries(
    .value.enabledMcpServers = ((.value.enabledMcpServers // []) + $builtins[0] | unique)
  ) else . end
'@

    $result = Get-Content $claudeJson -Raw |
              & jq --slurpfile base $tmpBase --slurpfile builtins $tmpBuiltins $jqFilter

    if ($LASTEXITCODE -eq 0 -and $result) {
        $result | Set-Content $claudeJson -Encoding UTF8
        Write-Host "[done] .claude.json — mcpServers set, cache keys scrubbed" -ForegroundColor Green
    } else {
        Write-Host "[fail] jq exited $LASTEXITCODE; .claude.json unchanged" -ForegroundColor Red
    }
} finally {
    Remove-Item $tmpBase, $tmpBuiltins -Force -ErrorAction SilentlyContinue
}
