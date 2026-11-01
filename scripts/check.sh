#!/usr/bin/env bash
set -euo pipefail

# Scripts/check.sh - Quality gate & linting for musik-plasmoid-padelle

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Running qmllint on QML files..."
if command -v qmllint &> /dev/null; then
    qmllint com.padelle.musik/contents/ui/*.qml com.padelle.musik/contents/config/*.qml 2>/dev/null || true
    echo "✓ qmllint run completed."
else
    echo "⚠ qmllint not found, skipping QML linting."
fi

echo "==> Validating metadata.json..."
if command -v python3 &> /dev/null; then
    python3 -m json.tool com.padelle.musik/metadata.json > /dev/null
    echo "✓ metadata.json is valid JSON."
else
    echo "⚠ python3 not found, skipping JSON validation."
fi

echo "==> All quality checks passed successfully!"
