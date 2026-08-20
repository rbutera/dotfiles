#!/usr/bin/env bash
# Global npm packages required by tooling (e.g. impeccable's HTML/CSS parser deps).
# run_onchange: editing PACKAGES below re-runs this on every machine at next
# `chezmoi apply`. Idempotent — only installs what is missing.
set -euo pipefail

command -v npm >/dev/null 2>&1 || { echo "npm not found, skipping global npm packages" >&2; exit 0; }

PACKAGES=(
  htmlparser2
  css-select
  css-tree
  domutils
)

missing=()
for pkg in "${PACKAGES[@]}"; do
  npm ls -g --depth=0 "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done

if [ "${#missing[@]}" -gt 0 ]; then
  echo "Installing global npm packages: ${missing[*]}"
  npm install -g "${missing[@]}"
fi
