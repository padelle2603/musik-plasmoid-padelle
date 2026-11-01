#!/usr/bin/env bash
set -euo pipefail

# Scripts/update.sh - Check for new version on GitHub, pull, install and restart

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Fetching latest changes from remote (origin/master)..."
git fetch origin master || git fetch origin main

# Determina il branch corrente (master o main)
CURRENT_BRANCH=$(git branch --show-current)
REMOTE_BRANCH="origin/${CURRENT_BRANCH}"

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "$REMOTE_BRANCH")

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "✓ You are already running the latest version."
    read -p "Do you want to force reinstall and restart anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
else
    echo "==> New updates found! Pulling changes..."
    git pull origin "$CURRENT_BRANCH"
fi

echo "==> Installing updated package..."
./scripts/install.sh

echo "==> Update complete!"
