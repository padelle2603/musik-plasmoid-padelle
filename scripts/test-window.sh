#!/usr/bin/env bash
set -euo pipefail

# Scripts/test-window.sh - Run plasmoid in isolated plasmawindowed window

echo "==> Launching plasmoid in isolated test window..."
exec plasmawindowed com.padelle.musik
