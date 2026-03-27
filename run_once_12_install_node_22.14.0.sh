#!/bin/bash
set -euo pipefail

NODE_VERSION="22.14.0"
GLOBAL_PACKAGES=(
  "@cometix/ccline@1.1.2"
  "@openai/codex@0.117.0"
  "@tobilu/qmd@2.0.1"
  "corepack@0.34.6"
  "humanizer@0.1.1"
  "mcporter@0.7.3"
  "obsidian-headless@0.0.7"
)
REPOS=(
  "$HOME/oclaw"
  "$HOME/dev/lumiere"
)

if ! command -v asdf &>/dev/null; then
  echo "asdf not found, skipping node $NODE_VERSION install"
  exit 0
fi

# Install node version if missing
if ! asdf list nodejs 2>/dev/null | grep -q "$NODE_VERSION"; then
  echo "Installing Node.js $NODE_VERSION via asdf..."
  asdf install nodejs "$NODE_VERSION"
else
  echo "Node.js $NODE_VERSION already installed"
fi

# Set as global default
asdf global nodejs "$NODE_VERSION"
echo "Global node set to $NODE_VERSION"

# Reinstall global packages
echo "Installing global npm packages..."
npm install -g "${GLOBAL_PACKAGES[@]}"

# Re-enable corepack for pnpm
corepack enable pnpm

# Reshim so asdf picks up new binaries
asdf reshim nodejs

echo "Node $(node --version), pnpm $(pnpm --version)"

# Reinstall project dependencies
for repo in "${REPOS[@]}"; do
  if [[ -d "$repo" ]] && [[ -f "$repo/pnpm-lock.yaml" ]]; then
    echo "Reinstalling node_modules in $repo..."
    (cd "$repo" && pnpm install)
  fi
done

echo "Done."
