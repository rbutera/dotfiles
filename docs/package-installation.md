# Package Installation Plan

## Goal

Refactor package installation so:

1. One core package list is maintained in a single template source.
2. macOS and WSL Linux continue to install from generated Homebrew Brewfiles.
3. Arch Linux installs from generated AUR/native package lists (via `paru`).

## Current State (Baseline)

- Installer script: `run_once_03_install-packages.sh.tmpl`
- Current package source: `raisbrewfile.tmpl`
- Current behavior:
  - Linux/macOS both use Homebrew + `brew bundle`
  - Linux dependencies are installed before Homebrew
  - WSL-specific `wl-clipboard` install has already been added

## Proposed Target Architecture

## Core package data source

Create a single canonical data file that is manager-agnostic, for example:

- `dot_config/packages/packages.toml.tmpl`

Use sections that separate intent from package-manager naming:

- `core`: packages expected on all platforms
- `macos_only`
- `wsl_only`
- `arch_only`
- `fonts_macos` (casks/fonts)
- `dev_optional` (future toggle)

Each package entry should support manager-specific names where needed:

- `brew`
- `pacman`
- `aur`

Example shape (conceptual):

- `ripgrep = { brew = "ripgrep", pacman = "ripgrep" }`
- `delta = { brew = "git-delta", pacman = "git-delta" }`
- `lazygit = { brew = "lazygit", pacman = "lazygit" }`
- `some_tool = { brew = "...", aur = "..." }`

This avoids hardcoding manager-specific naming inside install scripts.

## Generated outputs

Generate install manifests from the core data:

1. Brewfile for macOS
2. Brewfile for WSL Linux
3. Arch package list split into:
   - pacman packages
   - AUR packages

Suggested generated temp files:

- `/tmp/Brewfile.macos`
- `/tmp/Brewfile.wsl`
- `/tmp/packages.arch.pacman`
- `/tmp/packages.arch.aur`

## Installer orchestration

Update `run_once_03_install-packages.sh.tmpl` to choose install strategy by environment:

1. `darwin`:
   - install Homebrew
   - generate and apply Brewfile for macOS

2. `linux` + WSL:
   - install Linux build dependencies
   - install Homebrew
   - generate and apply Brewfile for WSL

3. `linux` + Arch (non-WSL):
   - ensure `paru` is available (install bootstrap if missing)
   - generate pacman list and install with `sudo pacman -S --needed`
   - generate AUR list and install with `paru -S --needed`

4. Other Linux distros (non-WSL):
   - keep current Homebrew path for now, or explicitly no-op with warning

## Implementation Plan

## Phase 1: Data model

1. Add canonical package data file (`packages.toml.tmpl`).
2. Encode current package inventory from `raisbrewfile.tmpl` into the new model.
3. Document naming mismatches and unresolved mappings.

## Phase 2: Generators

1. Add generation helper script (shell or small Lua/POSIX tool) to emit:
   - Brewfile (macOS)
   - Brewfile (WSL)
   - Arch pacman list
   - Arch AUR list
2. Keep `raisbrewfile.tmpl` temporarily as compatibility output until migration completes.

## Phase 3: Installer refactor

1. Refactor `run_once_03_install-packages.sh.tmpl` into strategy functions:
   - `install_packages_macos_brew`
   - `install_packages_wsl_brew`
   - `install_packages_arch_aur`
2. Wire runtime platform detection:
   - `is_macos`
   - `is_wsl`
   - `is_arch`
3. Add `paru` bootstrap/validation for Arch path.

## Phase 4: Validation

1. Dry-run generation in CI/local:
   - ensure generated files are non-empty and parse correctly.
2. Test on:
   - macOS machine
   - WSL Debian/Ubuntu
   - Arch Linux (native)
3. Compare installed package sets against baseline.

## Phase 5: Cleanup

1. Remove direct package duplication from `raisbrewfile.tmpl`.
2. Keep only generated/derived templates.
3. Update `README.md` with package strategy by platform.

## Design Decisions and Guardrails

- Keep one source of truth for package intent.
- Do not force Homebrew on native Arch.
- Prefer `pacman` first for Arch where package exists; use AUR only when needed.
- Keep manager-specific naming in mapping fields, not in install scripts.
- Keep install scripts deterministic and idempotent (`--needed`/no-op safe).

## Open Questions

1. Should `paru` be auto-installed if missing, or should script fail with instructions?
2. Should fonts remain macOS-only, or add Linux font package handling?
3. Should optional groups (`dev_optional`, GUI tools) be toggled by host profile?
4. Should we commit generated manifests or keep them ephemeral under `/tmp`?

## Suggested Rollout Order

1. Introduce canonical package data and generators without changing runtime behavior.
2. Switch macOS and WSL to generator-backed Brewfiles.
3. Add Arch strategy (`pacman` + `paru`).
4. Remove legacy direct Brewfile management once parity is verified.
