#!/usr/bin/env bash
set -euo pipefail

# Scripts/install.sh - Install or upgrade the plasmoid locally

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Running quality checks before installation..."
if [ -f "scripts/check.sh" ]; then
    ./scripts/check.sh
fi

echo "==> Installing/Upgrading plasmoid using kpackagetool6..."
if kpackagetool6 --type Plasma/Applet --list | grep -q "com.padelle.musik"; then
    kpackagetool6 --type Plasma/Applet --upgrade com.padelle.musik
    echo "✓ Plasmoid successfully upgraded."
else
    kpackagetool6 --type Plasma/Applet --install com.padelle.musik
    echo "✓ Plasmoid successfully installed."
fi

# Chiedi se riavviare plasmashell
read -p "Do you want to restart Plasma Shell to apply changes immediately? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "==> Restarting Plasma Shell..."
    kquitapp6 plasmashell 2>/dev/null || true
    plasmashell --replace &>/dev/null &
    echo "✓ Plasma Shell restarted."
fi

echo "==> Done!"
