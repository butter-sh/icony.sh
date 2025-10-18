#!/usr/bin/env bash

# icony.sh - SVG to Icon Font Generator
# Version: 2.1.0
# Generates icon fonts using CSS mask-image with embedded SVG data URLs

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="${INPUT_DIR:-$PWD/icons}"
OUTPUT_DIR="${OUTPUT_DIR:-$PWD/dist}"
FONT_NAME="${FONT_NAME:-iconset}"
ICON_CLASS="${ICON_CLASS:-icon}"

# Colors for output - only use colors if output is to a terminal or if FORCE_COLOR is set
export FORCE_COLOR=${FORCE_COLOR:-}
if [[ -z "$FORCE_COLOR" ]]; then
		if [[ "$FORCE_COLOR" = "1" ]]; then
			export RED='\033[0;31m'
			export GREEN='\033[0;32m'
			export YELLOW='\033[1;33m'
			export BLUE='\033[0;34m'
			export CYAN='\033[0;36m'
			export MAGENTA='\033[0;35m'
			export BOLD='\033[1m'
			export NC='\033[0m'

		else
			export RED=''
			export GREEN=''
			export YELLOW=''
			export BLUE=''
			export CYAN=''
			export MAGENTA=''
			export BOLD=''
			export NC=''
		fi
elif [[ -t 1 ]] && [[ -t 2 ]]; then
		export RED='\033[0;31m'
		export GREEN='\033[0;32m'
		export YELLOW='\033[1;33m'
		export BLUE='\033[0;34m'
		export CYAN='\033[0;36m'
		export MAGENTA='\033[0;35m'
		export BOLD='\033[1m'
		export NC='\033[0m'
else
    export RED=''
    export GREEN=''
    export YELLOW=''
    export BLUE=''
    export CYAN=''
		export MAGENTA=''
		export BOLD=''
		export NC=''
fi

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_step() {
    echo -e "${CYAN}▸${NC} $1"
}

# Check dependencies
check_dependencies() {
    local missing=0
    
    # Python 3 is required
    if ! command -v python3 &> /dev/null; then
        log_error "Missing required dependency: python3"
        missing=1
    fi
    
    # base64 should be available on all Unix systems
    if ! command -v base64 &> /dev/null; then
        log_warn "base64 command not found (unusual)"
    fi
    
    # Check for myst.sh (required for showcase generation)
    local myst_cmd=""
    if [[ -f "$SCRIPT_DIR/.arty/libs/myst.sh/myst.sh" ]]; then
        myst_cmd="$SCRIPT_DIR/.arty/libs/myst.sh/myst.sh"
    elif [[ -f "$SCRIPT_DIR/myst.sh/myst.sh" ]]; then
        myst_cmd="$SCRIPT_DIR/myst.sh/myst.sh"
    elif command -v myst &> /dev/null; then
        myst_cmd="myst"
    else
        log_error "Missing required dependency: myst.sh"
        log_info "Install with: arty install https://github.com/butter-sh/myst.sh.git"
        missing=1
    fi
    
    if [[ $missing -eq 1 ]]; then
        echo
        show_install_instructions
        return 1
    fi
    
    return 0
}

# Show installation instructions for dependencies
show_install_instructions() {
    echo -e "${CYAN}Installation instructions:${NC}"
    echo
    
    # Python3
    echo "  ${GREEN}Python3:${NC}"
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|linuxmint)
                echo "  sudo apt-get update && sudo apt-get install python3"
                ;;
            fedora|rhel|centos)
                echo "  sudo dnf install python3"
                ;;
            arch|manjaro)
                echo "  sudo pacman -S python"
                ;;
            opensuse*)
                echo "  sudo zypper install python3"
                ;;
        esac
    fi
    
    # macOS
    echo
    echo "  ${GREEN}macOS:${NC}"
    echo "  brew install python3"
    
    # Myst.sh
    echo
    echo "  ${GREEN}Myst.sh (templating engine):${NC}"
    echo "  arty install https://github.com/butter-sh/myst.sh.git"
    
    echo
}

# Normalize SVG files (center, currentColor, 24x24)
normalize_svg() {
    local input_file="$1"
    local output_file="$2"
    
    python3 - "$input_file" "$output_file" << 'PYEOF'
import sys
import xml.etree.ElementTree as ET

def normalize_svg(input_path, output_path):
    try:
        # Register namespace to preserve xmlns
        ET.register_namespace('', 'http://www.w3.org/2000/svg')
        
        # Parse SVG
        tree = ET.parse(input_path)
        root = tree.getroot()
        
        # Set viewBox to 0 0 24 24
        root.set('viewBox', '0 0 24 24')
        root.set('width', '24')
        root.set('height', '24')
        
        # Write normalized SVG
        with open(output_path, 'wb') as f:
            tree.write(f, encoding='utf-8')
        return True
    except Exception as e:
        print(f"Error normalizing {input_path}: {e}", file=sys.stderr)
        return False

if __name__ == '__main__':
    normalize_svg(sys.argv[1], sys.argv[2])
PYEOF
}

# Convert SVG to base64 data URL
svg_to_data_url() {
    local svg_file="$1"
    local svg_content=$(cat "$svg_file" | base64 -w 0)
    echo "data:image/svg+xml;base64,${svg_content}"
}

# Normalize all SVG files
normalize_svgs() {
    local input_dir="$1"
    local temp_dir="$2"
    
    if [[ ! -d "$input_dir" ]]; then
        log_error "Input directory not found: $input_dir"
        return 1
    fi
    
    local count=0
    while IFS= read -r -d '' svg_file; do
        local filename=$(basename "$svg_file")
        log_step "Normalizing: $filename"
        
        if normalize_svg "$svg_file" "$temp_dir/$filename"; then
            count=$((count+1))
        else
            log_warn "Failed to normalize: $filename"
        fi
    done < <(find "$input_dir" -type f -name "*.svg" -print0)
    
    if [[ $count -eq 0 ]]; then
        log_error "No SVG files found in $input_dir"
        return 1
    fi
    
    log_success "Normalized $count SVG files"
    return 0
}

# Generate CSS stylesheet with mask-image and data URLs
generate_css() {
    local output_dir="$1"
    local font_name="$2"
    local css_file="$output_dir/$font_name.css"
    
    log_step "Generating CSS stylesheet with mask-image..."
    
    # Generate base CSS
    cat > "$css_file" << CSSEOF
/**
 * ${font_name} Icon Set
 * Generated by icony.sh using CSS mask-image
 * Icons use currentColor for easy theming
 */

.${ICON_CLASS} {
  display: inline-block;
  width: 1em;
  height: 1em;
  vertical-align: -0.125em;
  
  /* Mask properties */
  mask-size: contain;
  mask-repeat: no-repeat;
  mask-position: center;
  -webkit-mask-size: contain;
  -webkit-mask-repeat: no-repeat;
  -webkit-mask-position: center;
  
  /* Color from currentColor */
  background-color: currentColor;
  
  /* Allow sizing */
  font-size: inherit;
}

/* Icon size variants */
.${ICON_CLASS}-xs {
  width: 0.75em;
  height: 0.75em;
}

.${ICON_CLASS}-sm {
  width: 0.875em;
  height: 0.875em;
}

.${ICON_CLASS}-lg {
  width: 1.25em;
  height: 1.25em;
}

.${ICON_CLASS}-xl {
  width: 1.5em;
  height: 1.5em;
}

.${ICON_CLASS}-2xl {
  width: 2em;
  height: 2em;
}

.${ICON_CLASS}-3xl {
  width: 3em;
  height: 3em;
}

/* Individual icon classes with mask-image data URLs */

CSSEOF

    # Add icon classes with embedded SVG data URLs
    local icon_count=0
    while IFS= read -r -d '' svg_file; do
        local filename=$(basename "$svg_file" .svg)
        local data_url=$(svg_to_data_url "$svg_file")
        
        cat >> "$css_file" << CSSEOF
.${ICON_CLASS}-${filename} {
  mask-image: url('${data_url}');
  -webkit-mask-image: url('${data_url}');
}

CSSEOF
        icon_count=$((icon_count+1))
    done < <(find "$TEMP_DIR" -type f -name "*.svg" -print0 | sort -z)
    
    log_success "CSS generated: $css_file ($icon_count icons)"
}

# Find myst.sh command
find_myst() {
    if [[ -f "$SCRIPT_DIR/.arty/libs/myst.sh/myst.sh" ]]; then
        echo "bash $SCRIPT_DIR/.arty/libs/myst.sh/myst.sh"
    elif [[ -f "$SCRIPT_DIR/myst.sh/myst.sh" ]]; then
        echo "bash $SCRIPT_DIR/myst.sh/myst.sh"
    elif command -v myst &> /dev/null; then
        echo "myst"
    else
        return 1
    fi
}

# Generate showcase HTML using myst.sh
generate_showcase() {
    local output_dir="$1"
    local font_name="$2"
    local html_file="$output_dir/index.html"
    
    log_step "Generating showcase HTML with myst.sh..."
    
    # Check for myst.sh
    local myst_cmd=$(find_myst)
    if [[ -z "$myst_cmd" ]]; then
        log_error "myst.sh not found"
        log_info "Install with: arty install https://github.com/butter-sh/myst.sh.git"
        return 1
    fi
    
    # Check for template
    if [[ ! -f "$SCRIPT_DIR/index.html.myst" ]]; then
        log_error "Template not found: index.html.myst"
        return 1
    fi
    
    # Collect icon names and generate icon grid HTML
    local icons=()
    local icon_grid_html=""
    
    while IFS= read -r -d '' svg_file; do
        local filename=$(basename "$svg_file" .svg)
        icons+=("$filename")
        
        icon_grid_html+="      <div class=\"icon-card group\">"
        icon_grid_html+=$'\n'
        icon_grid_html+="        <i class=\"${ICON_CLASS} ${ICON_CLASS}-${filename}\"></i>"
        icon_grid_html+=$'\n'
        icon_grid_html+="        <span class=\"icon-name\">${filename}</span>"
        icon_grid_html+=$'\n'
        icon_grid_html+="        <button class=\"copy-btn\" onclick=\"copyIconClass('${ICON_CLASS}-${filename}')\" title=\"Copy class name\">"
        icon_grid_html+=$'\n'
        icon_grid_html+="          <svg class=\"w-4 h-4\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">"
        icon_grid_html+=$'\n'
        icon_grid_html+="            <path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z\" />"
        icon_grid_html+=$'\n'
        icon_grid_html+="          </svg>"
        icon_grid_html+=$'\n'
        icon_grid_html+="        </button>"
        icon_grid_html+=$'\n'
        icon_grid_html+="      </div>"
        icon_grid_html+=$'\n'
    done < <(find "$TEMP_DIR" -type f -name "*.svg" -print0 | sort -z)
    
    # Create temporary file for icon grid
    local temp_icon_grid=$(mktemp)
    echo "$icon_grid_html" > "$temp_icon_grid"
    
    # Render with myst.sh
    log_info "Using myst.sh: $myst_cmd"
    
    $myst_cmd render "$SCRIPT_DIR/index.html.myst" \
        -v font_name="$font_name" \
        -v icon_class="$ICON_CLASS" \
        -v icon_count="${#icons[@]}" \
        -v icon_grid_html="$(cat $temp_icon_grid)" \
        -o "$html_file" 2>&1 || {
        rm -f "$temp_icon_grid"
        log_error "myst.sh rendering failed"
        return 1
    }
    
    rm -f "$temp_icon_grid"
    
    log_success "Showcase generated: $html_file"
}

# Generate everything
generate() {
    log_info "Starting icon set generation with CSS mask-image..."
    echo
    
    # Check dependencies
    if ! check_dependencies; then
        return 1
    fi
    
    # Create temp directory
    TEMP_DIR="$(mktemp -d)"
    trap "rm -rf $TEMP_DIR" EXIT
    
    # Normalize SVGs
    log_step "Step 1: Normalizing SVG files"
    if ! normalize_svgs "$INPUT_DIR" "$TEMP_DIR"; then
        return 1
    fi
    echo
    
    # Create output directory
    log_step "Step 2: Preparing output directory"
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
    log_success "Output directory ready"
    echo
    
    # Generate CSS with embedded data URLs
    log_step "Step 3: Generating CSS with mask-image and data URLs"
    generate_css "$OUTPUT_DIR" "$FONT_NAME"
    echo
    
    # Generate showcase with myst.sh
    log_step "Step 4: Generating showcase HTML with myst.sh"
    if ! generate_showcase "$OUTPUT_DIR" "$FONT_NAME"; then
        log_warn "Showcase generation failed, but CSS is ready"
        echo
        log_info "You can still use the generated CSS: $OUTPUT_DIR/$FONT_NAME.css"
        return 0  # Don't fail completely if showcase fails
    fi
    echo
    
    log_success "Icon set generation complete!"
    echo
    log_info "Output directory: $OUTPUT_DIR"
    log_info "Technology: CSS mask-image with embedded SVG data URLs"
    log_info ""
    log_info "Files generated:"
    log_info "  • $FONT_NAME.css - Icon stylesheet"
    log_info "  • index.html - Interactive showcase"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Open $OUTPUT_DIR/index.html to view the showcase"
    log_info "  2. Or run: bash icony.sh serve"
}

# Serve the showcase with a simple HTTP server
serve() {
    if [[ ! -d "$OUTPUT_DIR" ]]; then
        log_error "Output directory not found. Run 'generate' first."
        return 1
    fi
    
    if [[ ! -f "$OUTPUT_DIR/index.html" ]]; then
        log_error "Showcase not found. Run 'generate' first."
        return 1
    fi
    
    log_info "Starting HTTP server..."
    log_success "Showcase: http://localhost:8080"
    log_info "Press Ctrl+C to stop"
    echo
    
    cd "$OUTPUT_DIR"
    
    if command -v python3 &> /dev/null; then
        python3 -m http.server 8080 2>/dev/null
    elif command -v python &> /dev/null; then
        python -m SimpleHTTPServer 8080 2>/dev/null
    else
        log_error "Python not found. Cannot start server."
        log_info "You can still open $OUTPUT_DIR/index.html in your browser"
        return 1
    fi
}

# Clean generated files
clean() {
    log_info "Cleaning generated files..."
    
    rm -rf "$OUTPUT_DIR"
    rm -rf "$SCRIPT_DIR/temp"
    
    log_success "Clean complete"
}

# Initialize project structure
init() {
    log_info "Initializing icony project..."
    
    mkdir -p "$INPUT_DIR"
    
    # Create multiple example SVGs
    cat > "$INPUT_DIR/heart.svg" << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
</svg>
SVGEOF

    cat > "$INPUT_DIR/star.svg" << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
</svg>
SVGEOF

    cat > "$INPUT_DIR/home.svg" << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>
</svg>
SVGEOF

    cat > "$INPUT_DIR/settings.svg" << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.07.62-.07.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z"/>
</svg>
SVGEOF

    cat > "$INPUT_DIR/check.svg" << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/>
</svg>
SVGEOF
    
    log_success "Created example icons in $INPUT_DIR"
    echo
    log_info "Example icons: heart, star, home, settings, check"
    log_info "Add more SVG files to $INPUT_DIR and run: bash icony.sh generate"
}

# Show usage
show_usage() {
    cat << EOF
${GREEN}icony.sh${NC} - SVG to Icon Set Generator (CSS mask-image)

${BLUE}USAGE:${NC}
    icony.sh <command> [options]

${BLUE}COMMANDS:${NC}
    ${GREEN}generate${NC}    Generate icon set from SVG files
    ${GREEN}serve${NC}       Serve the showcase with HTTP server (localhost:8080)
    ${GREEN}clean${NC}       Remove generated files
    ${GREEN}init${NC}        Initialize project with example icons
    ${GREEN}help${NC}        Show this help message

${BLUE}ENVIRONMENT VARIABLES:${NC}
    INPUT_DIR       SVG input directory (default: ./icons)
    OUTPUT_DIR      Output directory (default: ./dist)
    FONT_NAME       CSS file name (default: iconset)
    ICON_CLASS      Base icon class name (default: icon)

${BLUE}EXAMPLES:${NC}
    # Generate icon set
    bash icony.sh generate

    # Custom input/output directories
    INPUT_DIR=./my-icons OUTPUT_DIR=./build bash icony.sh generate

    # Custom CSS file and class names
    FONT_NAME=myicons ICON_CLASS=ico bash icony.sh generate

    # Serve showcase
    bash icony.sh serve

    # Clean generated files
    bash icony.sh clean

${BLUE}TECHNOLOGY:${NC}
    This generator uses CSS ${GREEN}mask-image${NC} with embedded SVG data URLs:
    
    • No web fonts needed - pure CSS + SVG
    • Perfect currentColor support
    • Lightweight and modern
    • Works in all modern browsers
    • Uses myst.sh for HTML templating

${BLUE}REQUIREMENTS:${NC}
    Required:
    • python3        - For SVG processing
    • myst.sh        - For HTML templating
    
    Install myst.sh:
    • arty install https://github.com/butter-sh/myst.sh.git

EOF
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        generate|gen|g)
            generate "$@"
            ;;
        serve|s)
            serve "$@"
            ;;
        clean|c)
            clean "$@"
            ;;
        init|i)
            init "$@"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
