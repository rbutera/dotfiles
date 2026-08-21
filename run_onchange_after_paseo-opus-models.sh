#!/usr/bin/env bash
# Keep Paseo's model pickers on Opus 4.8 (1M context), NOT Opus 5.
#
# HISTORY: an earlier version of this script (run_onchange_after_paseo-opus5-
# models.sh) force-INJECTED claude-opus-5 into every host's picker via
# additionalModels, because Opus 5 was new and predated Paseo's bundled catalog.
# Rai decided on 2026-08-21 to run the fleet on Opus 4.8 with the 1M-context
# window instead, so this script now does the inverse: it REMOVES the injected
# opus-5 entries (chezmoi does not clean up what the old run_onchange wrote, so
# the removal has to be explicit) and ensures the Opus 4.8 (1M) variant is
# selectable in Paseo.
#
# WHY 4.8 NEEDS NOTHING for the omp provider but DOES for claude:
#   - omp already discovers `claude-opus-4-8` and reports contextWindow=1000000,
#     so Opus 4.8 (1M) is present in the omp provider without any injection.
#   - The `claude` provider (Claude Code) is bundled-catalog-driven the same way
#     Opus 5 was, so its 1M variant `claude-opus-4-8[1m]` is force-added here to
#     guarantee it shows in the picker. (`[1m]` is Claude Code's id syntax for the
#     1M-context beta; it is valid ONLY for the claude provider, never omp.)
#
# Idempotent and host-safe: only touches agents.providers.*.additionalModels and
# leaves each host's daemon / hostnames / feature settings alone. Managed by
# chezmoi so it self-applies across the fleet (kinto / nimbus / latios). A Paseo
# daemon restart (or next launch) is required for the change to show in the picker.
set -euo pipefail

CFG="$HOME/.paseo/config.json"
[ -f "$CFG" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

python3 - "$CFG" <<'PY'
import json, sys

path = sys.argv[1]
with open(path) as f:
    cfg = json.load(f)

providers = cfg.setdefault("agents", {}).setdefault("providers", {})
changed = False

def get_models(provider):
    block = providers.setdefault(provider, {})
    return block, block.setdefault("additionalModels", [])

def drop(provider, model_id):
    global changed
    block, models = get_models(provider)
    kept = [m for m in models if not (isinstance(m, dict) and m.get("id") == model_id)]
    if len(kept) != len(models):
        block["additionalModels"] = kept
        changed = True

def ensure(provider, model_id, label):
    global changed
    block, models = get_models(provider)
    if not any(isinstance(m, dict) and m.get("id") == model_id for m in models):
        models.append({"id": model_id, "label": label})
        changed = True

# 1. Undo the old opus-5 force-injection on both providers.
for p in ("claude", "omp"):
    drop(p, "claude-opus-5")

# 2. Make the 1M-context Opus 4.8 variant selectable in the claude provider.
#    (omp already surfaces claude-opus-4-8 at 1M via discovery, so no omp entry.)
ensure("claude", "claude-opus-4-8[1m]", "Claude Opus 4.8 (1M)")

# Prune now-empty additionalModels lists so the config stays tidy.
for block in providers.values():
    if isinstance(block, dict) and block.get("additionalModels") == []:
        del block["additionalModels"]

if changed:
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
    print(f"paseo: pinned pickers to Opus 4.8 (1M), removed opus-5, in {path}")
else:
    print(f"paseo: pickers already on Opus 4.8 (1M) in {path}")
PY
