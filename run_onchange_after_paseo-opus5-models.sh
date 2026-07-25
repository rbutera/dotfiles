#!/usr/bin/env bash
# Ensure Claude Opus 5 is selectable in Paseo's model pickers on every host.
#
# Paseo's bundled catalog + its cached provider snapshots predate Opus 5, so it
# does not appear in the picker until we add it via additionalModels (which
# merges with runtime-discovered models). OMP already resolves claude-opus-5 via
# models.dev discovery, and Claude Code >= 2.1.219 bundles it, so routing works
# once it is listed.
#
# This patch is idempotent and host-safe: it only touches
# agents.providers.*.additionalModels and leaves each host's daemon / hostnames
# / feature settings alone. It is managed by chezmoi so it self-applies across
# the fleet (kinto / nimbus / latios). A Paseo daemon restart (or next launch)
# is required for the change to show in the picker.
set -euo pipefail

CFG="$HOME/.paseo/config.json"
[ -f "$CFG" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

python3 - "$CFG" <<'PY'
import json, os, sys

path = sys.argv[1]
with open(path) as f:
    cfg = json.load(f)

providers = cfg.setdefault("agents", {}).setdefault("providers", {})

def ensure(provider):
    block = providers.setdefault(provider, {})
    models = block.setdefault("additionalModels", [])
    if not any(isinstance(m, dict) and m.get("id") == "claude-opus-5" for m in models):
        models.append({"id": "claude-opus-5", "label": "Claude Opus 5"})

# Claude Code is available on every host; only wire the omp provider where OMP
# is actually installed (or already declared) so we don't add a dead entry.
ensure("claude")
if os.path.exists(os.path.expanduser("~/.bun/bin/omp")) or "omp" in providers:
    ensure("omp")

with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")

print(f"paseo: ensured claude-opus-5 in {path}")
PY
