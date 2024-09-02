#!/usr/bin/env bash

set -euo pipefail

create_fork() {
  # Get the remote URL
  remote_url=$(git config --get remote.origin.url)

  # Extract owner and repo name
  if [[ $remote_url =~ github.com[:/](.+)/(.+)\.git ]]; then
    owner=${BASH_REMATCH[1]}
    repo=${BASH_REMATCH[2]}
    original_repo="$owner/$repo"
    echo "Original repo: $original_repo"
  else
    echo "Error: Couldn't parse remote URL"
    exit 1
  fi

  # Check if gh is installed
  if ! command -v gh &>/dev/null; then
    echo "Error: GitHub CLI (gh) is not installed. Please install it first."
    exit 1
  fi

  # Check if already forked
  if gh repo view "rbutera/$repo" &>/dev/null; then
    echo "Repository $repo is already forked. Updating remotes..."
  else
    echo "Forking repository..."
    gh repo fork "$original_repo" --clone=false || {
      echo "Error: Forking failed"
      exit 1
    }
  fi

  # Update remotes
  git remote rename origin upstream || echo "Remote 'origin' already renamed or doesn't exist"
  git remote add origin "git@github.com:rbutera/$repo.git" || git remote set-url origin "git@github.com:rbutera/$repo.git"

  echo "Remote configuration:"
  git remote -v

  # Get the current branch name
  current_branch=$(git rev-parse --abbrev-ref HEAD)

  # Push to origin using the current branch name
  echo "Pushing current branch to fork..."
  git push -u origin "$current_branch" || {
    echo "Error: Push failed"
    exit 1
  }

  echo "Setting upstream branch..."
  git branch --set-upstream-to=origin/"$current_branch" "$current_branch" || echo "Upstream already set"

  echo "Forked repository created and configured successfully!"
}

create_fork
