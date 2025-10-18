#!/usr/bin/env bash
# Rollback script to restore original icony files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "⏮️  Icony Template Rollback"
echo "=========================="
echo

# Check for backups
if [[ ! -f "$SCRIPT_DIR/icony.sh.backup" ]]; then
    echo "❌ Error: No backup found (icony.sh.backup)"
    echo "Cannot rollback without backups"
    exit 1
fi

echo "📦 Restoring from backups..."

# Restore files
mv "$SCRIPT_DIR/icony.sh.backup" "$SCRIPT_DIR/icony.sh"
echo "✓ Restored icony.sh"

if [[ -f "$SCRIPT_DIR/generate_showcase_function.sh.backup" ]]; then
    mv "$SCRIPT_DIR/generate_showcase_function.sh.backup" "$SCRIPT_DIR/generate_showcase_function.sh"
    echo "✓ Restored generate_showcase_function.sh"
fi

# Ensure executable
chmod +x "$SCRIPT_DIR/icony.sh"
echo "✓ Made icony.sh executable"

echo
echo "✅ Rollback complete!"
echo
echo "Original files have been restored."
echo
