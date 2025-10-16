#!/usr/bin/env bash

# setup.sh - Setup hook for icony.sh
# This script runs automatically when the library is installed via arty

set -euo pipefail

echo "Setting up icony.sh..."
echo ""

# Check for required dependencies
missing_deps=()

if ! command -v python3 &> /dev/null; then
    missing_deps+=("python3")
fi

if ! command -v fontforge &> /dev/null; then
    missing_deps+=("fontforge")
fi

# Show installation instructions if dependencies are missing
if [ ${#missing_deps[@]} -gt 0 ]; then
    echo "⚠️  Missing required dependencies: ${missing_deps[*]}"
    echo ""
    echo "Installation instructions:"
    echo ""
    
    # Detect OS and show appropriate commands
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|linuxmint)
                echo "  Ubuntu/Debian:"
                echo "  sudo apt-get update"
                echo "  sudo apt-get install python3 fontforge"
                ;;
            fedora|rhel|centos)
                echo "  Fedora/RHEL/CentOS:"
                echo "  sudo dnf install python3 fontforge"
                ;;
            arch|manjaro)
                echo "  Arch Linux:"
                echo "  sudo pacman -S python fontforge"
                ;;
        esac
    fi
    
    echo ""
    echo "  macOS (Homebrew):"
    echo "  brew install python fontforge"
    echo ""
fi

# Check for optional dependencies
optional_deps=()

if ! command -v inkscape &> /dev/null; then
    optional_deps+=("inkscape")
fi

if ! command -v potrace &> /dev/null; then
    optional_deps+=("potrace")
fi

if ! command -v woff2_compress &> /dev/null; then
    optional_deps+=("woff2")
fi

if [ ${#optional_deps[@]} -gt 0 ]; then
    echo "ℹ️  Optional dependencies (recommended): ${optional_deps[*]}"
    echo "   Install for better results and WOFF2 support"
    echo ""
fi

# Create icons directory
mkdir -p icons

# Create example icons if directory is empty
if [ -z "$(ls -A icons 2>/dev/null)" ]; then
    echo "Creating example icons..."
    
    cat > icons/heart.svg << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
</svg>
SVGEOF

    cat > icons/star.svg << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
</svg>
SVGEOF

    cat > icons/home.svg << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>
</svg>
SVGEOF

    echo "✓ Created example icons"
fi

# Make icony.sh executable
chmod +x icony.sh

echo ""
echo "Setup complete!"
echo ""
echo "Quick start:"
echo "  1. Add SVG files to the 'icons' directory"
echo "  2. Run: bash icony.sh generate"
echo "  3. Run: bash icony.sh serve"
echo "  4. Open: http://localhost:8080"
echo ""
echo "For more information, run: bash icony.sh help"
