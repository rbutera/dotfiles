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

manual:

```bash
# ARCH="<choose between 386/amd64/arm/arm64>" && \
ARCH="amd64" && \
wget "https://cache.agilebits.com/dist/1P/op2/pkg/v2.29.0/op_linux_${ARCH}_v2.29.0.zip" -O op.zip && \
unzip -d op op.zip && \
sudo mv op/op /usr/local/bin/ && \
rm -r op.zip op && \
sudo groupadd -f onepassword-cli && \
sudo chgrp onepassword-cli /usr/local/bin/op && \
sudo chmod g+s /usr/local/bin/op
```

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

yum:

```
sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'
sudo dnf check-update -y 1password-cli && sudo dnf install 1password-cli
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

