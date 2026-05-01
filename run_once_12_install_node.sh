#!/bin/bash
set -euo pipefail

NODE_VERSION="22.18.0"
NPM_GLOBAL_PACKAGES=(
  "@cometix/ccline"
  "@openai/codex"
  "@tobilu/qmd"
  "corepack"
  "humanizer"
  "mcporter"
  "obsidian-headless"
)
PNPM_GLOBAL_PACKAGES=(
  "@biomejs/biome"
  "@tailwindcss/language-server"
  "bash-language-server"
  "chronicler"
  "clawhub"
  "commander"
  "markdownlint-cli"
  "mcporter"
  "obsidian-headless"
  "opencode-ai"
  "semver"
  "typescript"
  "typescript-language-server"
  "vscode-langservers-extracted"
  "yaml-language-server"
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
asdf set --home nodejs "$NODE_VERSION"
echo "Global node set to $NODE_VERSION"

# Reinstall global npm packages
echo "Installing global npm packages..."
npm install -g "${NPM_GLOBAL_PACKAGES[@]}"

# Re-enable corepack for pnpm
corepack enable pnpm

# Reshim so asdf picks up new binaries
asdf reshim nodejs

echo "Node $(node --version), pnpm $(pnpm --version)"

# Reinstall global pnpm packages
echo "Installing global pnpm packages..."
pnpm add -g "${PNPM_GLOBAL_PACKAGES[@]}"

# Reinstall project dependencies
for repo in "${REPOS[@]}"; do
  if [[ -d "$repo" ]] && [[ -f "$repo/pnpm-lock.yaml" ]]; then
    echo "Reinstalling node_modules in $repo..."
    (cd "$repo" && pnpm install)
  fi
done

echo "Done."
