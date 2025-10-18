#!/usr/bin/env bash
# Migration script to replace old icony files with cleaned versions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔧 Icony Template Migration"
echo "============================"
echo

# Check if we're in the right directory
if [[ ! -f "$SCRIPT_DIR/icony.sh" ]]; then
    echo "❌ Error: icony.sh not found in current directory"
    echo "Please run this script from the icony template directory"
    exit 1
fi

# Check if cleaned files exist
if [[ ! -f "$SCRIPT_DIR/icony_cleaned.sh" ]]; then
    echo "❌ Error: icony_cleaned.sh not found"
    echo "Please ensure cleaned files are in the same directory"
    exit 1
fi

if [[ ! -f "$SCRIPT_DIR/generate_showcase_function_cleaned.sh" ]]; then
    echo "❌ Error: generate_showcase_function_cleaned.sh not found"
    exit 1
fi

# Create backups
echo "📦 Creating backups..."
if [[ -f "$SCRIPT_DIR/icony.sh.backup" ]]; then
    echo "⚠️  Backup already exists: icony.sh.backup"
    read -p "Overwrite existing backup? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Migration cancelled"
        exit 1
    fi
fi

cp "$SCRIPT_DIR/icony.sh" "$SCRIPT_DIR/icony.sh.backup"
echo "✓ Backed up icony.sh → icony.sh.backup"

if [[ -f "$SCRIPT_DIR/generate_showcase_function.sh" ]]; then
    cp "$SCRIPT_DIR/generate_showcase_function.sh" "$SCRIPT_DIR/generate_showcase_function.sh.backup"
    echo "✓ Backed up generate_showcase_function.sh → generate_showcase_function.sh.backup"
fi

echo

# Replace files
echo "🔄 Replacing files with cleaned versions..."
mv "$SCRIPT_DIR/icony_cleaned.sh" "$SCRIPT_DIR/icony.sh"
echo "✓ Replaced icony.sh"

mv "$SCRIPT_DIR/generate_showcase_function_cleaned.sh" "$SCRIPT_DIR/generate_showcase_function.sh"
echo "✓ Replaced generate_showcase_function.sh"

# Ensure executable
chmod +x "$SCRIPT_DIR/icony.sh"
echo "✓ Made icony.sh executable"

echo

# Verify
echo "✅ Migration complete!"
echo
echo "Files updated:"
echo "  • icony.sh (cleaned version)"
echo "  • generate_showcase_function.sh (cleaned version)"
echo
echo "Backups created:"
echo "  • icony.sh.backup"
if [[ -f "$SCRIPT_DIR/generate_showcase_function.sh.backup" ]]; then
    echo "  • generate_showcase_function.sh.backup"
fi
echo
echo "📝 Test the new version:"
echo "  bash icony.sh help"
echo "  bash icony.sh init"
echo "  bash icony.sh generate"
echo
echo "🧪 Run tests (if judge.sh is installed):"
echo "  arty exec judge run"
echo
echo "♻️  To rollback:"
echo "  mv icony.sh.backup icony.sh"
if [[ -f "$SCRIPT_DIR/generate_showcase_function.sh.backup" ]]; then
    echo "  mv generate_showcase_function.sh.backup generate_showcase_function.sh"
fi
echo
