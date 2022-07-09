#!/bin/bash

backup_zsh_dotfiles() {
  echo "backing up zsh dotfiles..."
  mkdir -p ~/zsh_backup
  mv -v ~/.zlogin ~/zsh_backup/.zlogin
  mv -v ~/.zlogout ~/zsh_backup/.zlogout
  mv -v ~/.zpreztorc ~/zsh_backup/.zpreztorc
  mv -v ~/.zshrc ~/zsh_backup/.zshrc
  mv -v ~/.zprofile ~/zsh_backup/.zprofile
  mv -v ~/.zshenv ~/zsh_backup/.zshenv
  echo "finished backing up zsh dotfiles"
}

restore_zsh_dotfiles() {
  echo "restoring zsh dotfiles from backup..."
  mkdir -p ~/zsh_backup
  rm -rf ~/.zshrc ~/.zlogin ~/.zlogout ~/.zshenv ~/.zprofile ~/.zpreztorc
  mv -v ~/zsh_backup/.zlogin ~/.zlogin
  mv -v ~/zsh_backup/.zlogout ~/.zlogout
  mv -v ~/zsh_backup/.zpreztorc ~/.zpreztorc
  mv -v ~/zsh_backup/.zshrc ~/.zshrc
  mv -v ~/zsh_backup/.zprofile ~/.zprofile
  mv -v ~/zsh_backup/.zshenv ~/.zshenv
  rm -rf ~/zsh_backup
  echo "finished restoring zsh dotfiles from backup"
}
