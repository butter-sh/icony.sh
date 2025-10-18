#!/usr/bin/env bash
# Migration script - removes generate_showcase_function.sh files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔧 Icony Template - Final Cleanup"
echo "==================================="
echo

# Remove generate_showcase_function files
if [[ -f "$SCRIPT_DIR/generate_showcase_function.sh" ]]; then
    echo "📦 Removing generate_showcase_function.sh..."
    rm "$SCRIPT_DIR/generate_showcase_function.sh"
    echo "✓ Removed"
fi

if [[ -f "$SCRIPT_DIR/generate_showcase_function.sh.backup" ]]; then
    echo "📦 Removing generate_showcase_function.sh.backup..."
    rm "$SCRIPT_DIR/generate_showcase_function.sh.backup"
    echo "✓ Removed"
fi

if [[ -f "$SCRIPT_DIR/generate_showcase_function_cleaned.sh" ]]; then
    echo "📦 Removing generate_showcase_function_cleaned.sh..."
    rm "$SCRIPT_DIR/generate_showcase_function_cleaned.sh"
    echo "✓ Removed"
fi

echo
echo "✅ Cleanup complete!"
echo
echo "The showcase generation is now integrated directly into icony.sh"
echo "using myst.sh for templating (no fallback needed)."
echo
echo "Myst.sh is now a required dependency."
echo "Install with: arty install https://github.com/butter-sh/myst.sh.git"
echo
