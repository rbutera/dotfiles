# Rai's dotfiles

> Opinionated vi-mode friendly, productivity-oriented dotfiles for MacOS, Linux, Windows and WSL

Managed using chezmoi

# Pre-requisites

- 1Password

## 1Password CLI

### MacOS

```
brew install --cask 1password/tap/1password-cli
```

### Linux

apt:

```bash
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
 sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg;
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" |
sudo tee /etc/apt/sources.list.d/1password.list;
sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
 sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
 sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg;
sudo apt update && sudo apt install 1password-cli;
op --version;
```

arch:

```bash
pacman -S 1password
```


# Installation

To install:

```shell
chezmoi init --apply --verbose git@github.com:rbutera/dotfiles
```

if using http

```shell
chezmoi init --apply --verbose https://github.com/rbutera/dotfiles.git
```

