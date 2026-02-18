# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io). Vi-mode friendly, productivity-oriented configuration for macOS, Arch Linux, and WSL.

## Features

- **Shell**: zsh with prezto, starship prompt, vi-mode
- **Editor**: neovim (via bob)
- **Terminal**: kitty, tmux with catppuccin theme
- **Tools**: fzf, eza, delta, aichat, aider
- **Secrets**: 1Password CLI integration for API keys and credentials

## Prerequisites

### 1Password CLI

**macOS:**
```bash
brew install --cask 1password/tap/1password-cli
```

**Arch Linux:**
```bash
pacman -S 1password-cli
```

**Debian/Ubuntu:**
```bash
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
  sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
  sudo tee /etc/apt/sources.list.d/1password.list
sudo apt update && sudo apt install 1password-cli
```

## Installation

```bash
chezmoi init --apply git@github.com:rbutera/dotfiles.git
```

Or via HTTPS:
```bash
chezmoi init --apply https://github.com/rbutera/dotfiles.git
```

## Usage

```bash
chezmoi diff          # See pending changes
chezmoi apply         # Apply changes
chezmoi edit ~/.zshrc # Edit and apply a file
chezmoi update        # Pull and apply latest
```

## Structure

```
├── dot_aliases.tmpl      # Shell aliases
├── dot_zshrc.tmpl        # Zsh config
├── dot_zprofile.tmpl     # Login shell config
├── dot_gitconfig.tmpl    # Git config
├── dot_claude/           # Claude Code settings
├── dot_config/
│   ├── aichat/           # AI chat tool config
│   ├── kitty/            # Terminal config
│   ├── starship.toml     # Prompt config
│   └── ...
├── dot_ssh/              # SSH config
├── dot_tmux/             # Tmux config
└── bin/                  # Custom scripts
```

## License

MIT
