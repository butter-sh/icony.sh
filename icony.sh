#!/usr/bin/env bash

# icony.sh - SVG to Icon Font Generator
# Version: 1.0.0
# Generates icon fonts from SVG files using native Linux/Unix tools

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="${INPUT_DIR:-$SCRIPT_DIR/icons}"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/dist}"
FONT_NAME="${FONT_NAME:-iconset}"
FONT_FAMILY="${FONT_FAMILY:-IconFont}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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
    local deps_status=0
    
    # Required tools
    local required=(python3 fontforge)
    local missing_required=()
    
    for dep in "${required[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_required+=("$dep")
            deps_status=1
        fi
    done
    
    # Optional but recommended
    local recommended=(inkscape potrace woff2_compress)
    local missing_recommended=()
    
    for dep in "${recommended[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_recommended+=("$dep")
        fi
    done
    
    if [[ ${#missing_required[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_required[*]}"
        echo
        show_install_instructions "${missing_required[@]}"
        return 1
    fi
    
    if [[ ${#missing_recommended[@]} -gt 0 ]]; then
        log_warn "Missing recommended dependencies: ${missing_recommended[*]}"
        log_info "Some features may be limited. Install for best results:"
        show_install_instructions "${missing_recommended[@]}"
        echo
    fi
    
    return $deps_status
}

# Show installation instructions for dependencies
show_install_instructions() {
    echo -e "${CYAN}Installation instructions:${NC}"
    echo
    
    # Detect OS
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|linuxmint)
                echo "  ${GREEN}Ubuntu/Debian:${NC}"
                echo "  sudo apt-get update"
                echo "  sudo apt-get install python3 fontforge inkscape potrace woff2"
                ;;
            fedora|rhel|centos)
                echo "  ${GREEN}Fedora/RHEL/CentOS:${NC}"
                echo "  sudo dnf install python3 fontforge inkscape potrace woff2"
                ;;
            arch|manjaro)
                echo "  ${GREEN}Arch Linux:${NC}"
                echo "  sudo pacman -S python fontforge inkscape potrace woff2"
                ;;
            opensuse*)
                echo "  ${GREEN}openSUSE:${NC}"
                echo "  sudo zypper install python3 fontforge inkscape potrace woff2"
                ;;
        esac
    fi
    
    # macOS
    echo
    echo "  ${GREEN}macOS (Homebrew):${NC}"
    echo "  brew install python fontforge inkscape potrace woff2"
    
    echo
}

# Normalize SVG files (center, currentColor, 24x24)
normalize_svg() {
    local input_file="$1"
    local output_file="$2"
    
    python3 - "$input_file" "$output_file" << 'PYEOF'
import sys
import re
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
        
        # Get all elements
        ns = {'svg': 'http://www.w3.org/2000/svg'}
        
        # Remove any existing fill/stroke attributes and set currentColor
        for elem in root.iter():
            # Remove old color attributes
            for attr in ['fill', 'stroke', 'color', 'style']:
                if attr in elem.attrib:
                    if attr == 'style':
                        # Remove color-related styles
                        style = elem.attrib[attr]
                        style = re.sub(r'fill:[^;]+;?', '', style)
                        style = re.sub(r'stroke:[^;]+;?', '', style)
                        if style.strip():
                            elem.attrib[attr] = style
                        else:
                            del elem.attrib[attr]
                    else:
                        del elem.attrib[attr]
            
            # Set currentColor on path, circle, rect, polygon, polyline, ellipse elements
            tag = elem.tag.split('}')[-1] if '}' in elem.tag else elem.tag
            if tag in ['path', 'circle', 'rect', 'polygon', 'polyline', 'ellipse', 'line']:
                elem.set('fill', 'currentColor')
        
        # Write normalized SVG
        tree.write(output_path, encoding='utf-8', xml_declaration=True)
        return True
    except Exception as e:
        print(f"Error normalizing {input_path}: {e}", file=sys.stderr)
        return False

if __name__ == '__main__':
    normalize_svg(sys.argv[1], sys.argv[2])
PYEOF
}

# Normalize all SVG files
normalize_svgs() {
    local input_dir="$1"
    local temp_dir="$2"
    
    if [[ ! -d "$input_dir" ]]; then
        log_error "Input directory not found: $input_dir"
        return 1
    fi
    
    mkdir -p "$temp_dir"
    
    local count=0
    while IFS= read -r -d '' svg_file; do
        local filename=$(basename "$svg_file")
        log_step "Normalizing: $filename"
        
        if normalize_svg "$svg_file" "$temp_dir/$filename"; then
            ((count++))
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

# Generate font using FontForge Python scripting
generate_font() {
    local svg_dir="$1"
    local output_dir="$2"
    local font_name="$3"
    local font_family="$4"
    
    log_step "Generating font with FontForge..."
    
    python3 - "$svg_dir" "$output_dir" "$font_name" "$font_family" << 'PYEOF'
import sys
import os
import fontforge
from pathlib import Path

def generate_font(svg_dir, output_dir, font_name, font_family):
    try:
        # Create a new font
        font = fontforge.font()
        font.fontname = font_name
        font.familyname = font_family
        font.fullname = font_family
        font.encoding = "UnicodeFull"
        font.em = 1000
        font.ascent = 800
        font.descent = 200
        
        # Get all SVG files
        svg_files = sorted(Path(svg_dir).glob("*.svg"))
        
        if not svg_files:
            print("No SVG files found", file=sys.stderr)
            return False
        
        # Starting unicode point (Private Use Area)
        unicode_point = 0xE000
        
        # Import each SVG as a glyph
        for svg_file in svg_files:
            try:
                # Create glyph
                glyph = font.createChar(unicode_point)
                glyph.glyphname = svg_file.stem
                
                # Import SVG
                glyph.importOutlines(str(svg_file))
                
                # Center and scale glyph
                glyph.transform([1, 0, 0, 1, 0, 0])
                
                # Get bounding box
                bbox = glyph.boundingBox()
                if bbox[2] > bbox[0] and bbox[3] > bbox[1]:
                    width = bbox[2] - bbox[0]
                    height = bbox[3] - bbox[1]
                    
                    # Calculate scale to fit em square
                    scale = min(800 / width, 800 / height)
                    
                    # Scale glyph
                    glyph.transform([scale, 0, 0, scale, 0, 0])
                    
                    # Center horizontally
                    bbox = glyph.boundingBox()
                    x_offset = (1000 - (bbox[2] - bbox[0])) / 2 - bbox[0]
                    glyph.transform([1, 0, 0, 1, x_offset, 0])
                    
                    # Set width
                    glyph.width = 1000
                
                print(f"Added glyph: {svg_file.stem} (U+{unicode_point:04X})")
                unicode_point += 1
                
            except Exception as e:
                print(f"Error importing {svg_file}: {e}", file=sys.stderr)
                continue
        
        # Ensure output directory exists
        os.makedirs(output_dir, exist_ok=True)
        
        # Generate font files
        ttf_path = os.path.join(output_dir, f"{font_name}.ttf")
        woff_path = os.path.join(output_dir, f"{font_name}.woff")
        svg_path = os.path.join(output_dir, f"{font_name}.svg")
        
        print(f"Generating TTF: {ttf_path}")
        font.generate(ttf_path)
        
        print(f"Generating WOFF: {woff_path}")
        font.generate(woff_path)
        
        print(f"Generating SVG: {svg_path}")
        font.generate(svg_path)
        
        return True
        
    except Exception as e:
        print(f"Error generating font: {e}", file=sys.stderr)
        return False

if __name__ == '__main__':
    svg_dir = sys.argv[1]
    output_dir = sys.argv[2]
    font_name = sys.argv[3]
    font_family = sys.argv[4]
    
    success = generate_font(svg_dir, output_dir, font_name, font_family)
    sys.exit(0 if success else 1)
PYEOF

    local result=$?
    
    if [[ $result -eq 0 ]]; then
        log_success "Font files generated"
        
        # Generate WOFF2 if woff2_compress is available
        if command -v woff2_compress &> /dev/null; then
            log_step "Generating WOFF2..."
            local ttf_file="$output_dir/$font_name.ttf"
            local woff2_file="$output_dir/$font_name.woff2"
            
            if woff2_compress "$ttf_file" 2>/dev/null; then
                log_success "WOFF2 generated"
            else
                log_warn "WOFF2 generation failed (optional)"
            fi
        fi
        
        return 0
    else
        log_error "Font generation failed"
        return 1
    fi
}

# Generate CSS stylesheet with icon mappings
generate_css() {
    local output_dir="$1"
    local font_name="$2"
    local temp_dir="$(dirname "$output_dir")/temp"
    local css_file="$output_dir/$font_name.css"
    
    log_step "Generating CSS stylesheet..."
    
    # Generate @font-face
    cat > "$css_file" << CSSEOF
@font-face {
  font-family: '${FONT_FAMILY}';
  src: url('${font_name}.woff2') format('woff2'),
       url('${font_name}.woff') format('woff'),
       url('${font_name}.ttf') format('truetype'),
       url('${font_name}.svg#${FONT_FAMILY}') format('svg');
  font-weight: normal;
  font-style: normal;
  font-display: block;
}

.icon {
  font-family: '${FONT_FAMILY}' !important;
  font-style: normal;
  font-weight: normal;
  font-variant: normal;
  text-transform: none;
  line-height: 1;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  display: inline-block;
  vertical-align: middle;
}

CSSEOF

    # Add icon classes with proper unicode mapping
    local unicode_point=0xE000
    while IFS= read -r -d '' svg_file; do
        local filename=$(basename "$svg_file" .svg)
        local unicode_char=$(printf "\\%04x" $unicode_point)
        
        cat >> "$css_file" << CSSEOF
.icon-${filename}::before {
  content: '${unicode_char}';
}

CSSEOF
        ((unicode_point++))
    done < <(find "$temp_dir" -type f -name "*.svg" -print0 | sort -z)
    
    log_success "CSS generated: $css_file"
}

# Generate showcase HTML
generate_showcase() {
    local output_dir="$1"
    local font_name="$2"
    local html_file="$output_dir/index.html"
    local temp_dir="$(dirname "$output_dir")/temp"
    
    log_step "Generating showcase HTML..."
    
    # Collect icon names
    local icons=()
    while IFS= read -r -d '' svg_file; do
        local filename=$(basename "$svg_file" .svg)
        icons+=("$filename")
    done < <(find "$temp_dir" -type f -name "*.svg" -print0 | sort -z)
    
    # Generate icon grid HTML
    local icons_html=""
    for icon in "${icons[@]}"; do
        icons_html+="        <div class=\"icon-card group\">\n"
        icons_html+="          <i class=\"icon icon-$icon\"></i>\n"
        icons_html+="          <span class=\"icon-name\">$icon</span>\n"
        icons_html+="          <button class=\"copy-btn\" onclick=\"copyIconClass('icon-$icon')\" title=\"Copy class name\">\n"
        icons_html+="            <svg class=\"w-4 h-4\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">\n"
        icons_html+="              <path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z\" />\n"
        icons_html+="            </svg>\n"
        icons_html+="          </button>\n"
        icons_html+="        </div>\n"
    done
    
    cat > "$html_file" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FONT_FAMILY - Icon Font Showcase</title>
  <link rel="stylesheet" href="FONT_NAME.css">
  <script src="https://cdn.tailwindcss.com/4.0.0-alpha.27"></script>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
    
    * {
      font-family: 'Inter', system-ui, -apple-system, sans-serif;
    }
    
    body {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
    }
    
    .glass {
      background: rgba(255, 255, 255, 0.1);
      backdrop-filter: blur(10px);
      border: 1px solid rgba(255, 255, 255, 0.2);
    }
    
    .icon-card {
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      position: relative;
      overflow: hidden;
    }
    
    .icon-card::before {
      content: '';
      position: absolute;
      inset: 0;
      background: linear-gradient(135deg, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0.05) 100%);
      opacity: 0;
      transition: opacity 0.3s;
    }
    
    .icon-card:hover {
      transform: translateY(-4px) scale(1.02);
      box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3), 0 10px 10px -5px rgba(0, 0, 0, 0.2);
    }
    
    .icon-card:hover::before {
      opacity: 1;
    }
    
    .icon-card i {
      font-size: 2.5rem;
      transition: all 0.3s;
    }
    
    .icon-card:hover i {
      transform: scale(1.2) rotate(5deg);
      color: #fbbf24;
    }
    
    .copy-btn {
      opacity: 0;
      transition: all 0.2s;
      position: absolute;
      top: 0.5rem;
      right: 0.5rem;
    }
    
    .icon-card:hover .copy-btn {
      opacity: 1;
    }
    
    .copy-btn:hover {
      transform: scale(1.1);
    }
    
    @keyframes slideInUp {
      from {
        opacity: 0;
        transform: translateY(30px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }
    
    .icon-card {
      animation: slideInUp 0.5s ease-out backwards;
    }
    
    .toast {
      position: fixed;
      bottom: 2rem;
      right: 2rem;
      transform: translateY(200%);
      transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      z-index: 50;
    }
    
    .toast.show {
      transform: translateY(0);
    }
    
    .stat-badge {
      background: rgba(255, 255, 255, 0.2);
      backdrop-filter: blur(10px);
      border: 1px solid rgba(255, 255, 255, 0.3);
    }
  </style>
</head>
<body class="p-8">
  <div class="max-w-7xl mx-auto">
    <!-- Header -->
    <div class="glass rounded-3xl p-8 mb-8 text-white">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-5xl font-bold mb-2 bg-gradient-to-r from-white to-gray-200 bg-clip-text text-transparent">
            FONT_FAMILY
          </h1>
          <p class="text-gray-200 text-lg">
            Beautiful icon font with <span class="font-bold text-yellow-300">ICON_COUNT icons</span>
          </p>
          <p class="text-gray-300 text-sm mt-1">
            Generated by icony.sh using FontForge
          </p>
        </div>
        <div class="flex gap-4">
          <div class="stat-badge px-4 py-2 rounded-xl text-center">
            <div class="text-2xl font-bold">ICON_COUNT</div>
            <div class="text-xs text-gray-200">Icons</div>
          </div>
          <button onclick="toggleTheme()" class="glass px-6 py-3 rounded-xl hover:bg-white/20 transition-all" title="Toggle theme">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
            </svg>
          </button>
        </div>
      </div>
      
      <!-- Search -->
      <div class="relative">
        <input 
          type="text" 
          id="searchInput" 
          placeholder="Search icons..." 
          class="w-full px-6 py-4 rounded-xl bg-white/10 border border-white/20 text-white placeholder-gray-300 focus:outline-none focus:ring-2 focus:ring-white/50 transition-all"
          oninput="searchIcons(this.value)"
        />
        <svg class="absolute right-4 top-1/2 -translate-y-1/2 w-6 h-6 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      </div>
      
      <!-- Usage Example -->
      <div class="mt-6 p-4 bg-black/20 rounded-xl">
        <div class="text-sm font-mono text-gray-200">
          <div class="text-xs text-gray-400 mb-2">Usage:</div>
          <code class="text-green-300">&lt;i class="icon icon-example"&gt;&lt;/i&gt;</code>
        </div>
      </div>
    </div>

    <!-- Icon Grid -->
    <div id="iconGrid" class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8 gap-4">
ICON_GRID_HTML
    </div>

    <!-- Empty State -->
    <div id="emptyState" class="hidden glass rounded-3xl p-12 text-center text-white">
      <svg class="w-24 h-24 mx-auto mb-4 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <h3 class="text-2xl font-bold mb-2">No icons found</h3>
      <p class="text-gray-300">Try a different search term</p>
    </div>
    
    <!-- Footer -->
    <div class="mt-8 text-center text-white/60 text-sm">
      <p>Generated with ❤️ using icony.sh • FontForge • Python • Bash</p>
    </div>
  </div>

  <!-- Toast Notification -->
  <div id="toast" class="toast glass rounded-xl px-6 py-4 text-white flex items-center gap-3 shadow-2xl">
    <svg class="w-6 h-6 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
    </svg>
    <span class="font-medium">Copied to clipboard!</span>
  </div>

  <script>
    function searchIcons(query) {
      const cards = document.querySelectorAll('.icon-card');
      const emptyState = document.getElementById('emptyState');
      let visibleCount = 0;
      
      query = query.toLowerCase().trim();
      
      cards.forEach((card, index) => {
        const iconName = card.querySelector('.icon-name').textContent.toLowerCase();
        const matches = iconName.includes(query);
        
        if (matches) {
          card.style.display = 'flex';
          card.style.animationDelay = `${index * 0.02}s`;
          visibleCount++;
        } else {
          card.style.display = 'none';
        }
      });
      
      emptyState.classList.toggle('hidden', visibleCount > 0);
    }

    function copyIconClass(iconClass) {
      navigator.clipboard.writeText(iconClass).then(() => {
        showToast();
      });
    }

    function showToast() {
      const toast = document.getElementById('toast');
      toast.classList.add('show');
      setTimeout(() => {
        toast.classList.remove('show');
      }, 2000);
    }

    function toggleTheme() {
      const themes = [
        'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        'linear-gradient(135deg, #1e3a8a 0%, #1e40af 100%)',
        'linear-gradient(135deg, #065f46 0%, #047857 100%)',
        'linear-gradient(135deg, #9333ea 0%, #c026d3 100%)',
        'linear-gradient(135deg, #dc2626 0%, #ea580c 100%)'
      ];
      
      const currentBg = document.body.style.background;
      const currentIndex = themes.indexOf(currentBg);
      const nextIndex = (currentIndex + 1) % themes.length;
      
      document.body.style.background = themes[nextIndex];
    }

    // Add stagger animation
    document.querySelectorAll('.icon-card').forEach((card, index) => {
      card.style.animationDelay = `${index * 0.02}s`;
    });
    
    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => {
      if (e.key === '/' && e.target.tagName !== 'INPUT') {
        e.preventDefault();
        document.getElementById('searchInput').focus();
      }
      if (e.key === 'Escape') {
        document.getElementById('searchInput').value = '';
        searchIcons('');
        document.getElementById('searchInput').blur();
      }
    });
  </script>
</body>
</html>
HTMLEOF

    # Replace placeholders
    sed -i "s/FONT_NAME/$font_name/g" "$html_file"
    sed -i "s/FONT_FAMILY/$FONT_FAMILY/g" "$html_file"
    sed -i "s/ICON_COUNT/${#icons[@]}/g" "$html_file"
    
    # Use perl for multiline replacement (more reliable than sed for this)
    perl -i -pe "s|ICON_GRID_HTML|$(echo "$icons_html" | sed 's/[&/\]/\\&/g')|g" "$html_file" 2>/dev/null || {
        # Fallback: use a temp file
        echo "$icons_html" > /tmp/icons_temp.html
        sed -i "/ICON_GRID_HTML/r /tmp/icons_temp.html" "$html_file"
        sed -i "/ICON_GRID_HTML/d" "$html_file"
        rm -f /tmp/icons_temp.html
    }
    
    log_success "Showcase generated: $html_file"
}

# Generate everything
generate() {
    log_info "Starting icon font generation..."
    echo
    
    # Check dependencies
    if ! check_dependencies; then
        return 1
    fi
    
    # Create temp directory
    local temp_dir="$SCRIPT_DIR/temp"
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir"
    
    # Normalize SVGs
    log_step "Step 1: Normalizing SVG files"
    if ! normalize_svgs "$INPUT_DIR" "$temp_dir"; then
        return 1
    fi
    echo
    
    # Generate font
    log_step "Step 2: Generating icon font"
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
    
    if ! generate_font "$temp_dir" "$OUTPUT_DIR" "$FONT_NAME" "$FONT_FAMILY"; then
        log_error "Font generation failed"
        return 1
    fi
    echo
    
    # Generate CSS
    log_step "Step 3: Generating CSS stylesheet"
    generate_css "$OUTPUT_DIR" "$FONT_NAME"
    echo
    
    # Generate showcase
    log_step "Step 4: Generating showcase HTML"
    generate_showcase "$OUTPUT_DIR" "$FONT_NAME"
    echo
    
    # Cleanup
    rm -rf "$temp_dir"
    
    log_success "Icon font generation complete!"
    echo
    log_info "Output directory: $OUTPUT_DIR"
    log_info "Font formats: TTF, WOFF, WOFF2 (if available), SVG"
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
    
    log_success "Created example icons in $INPUT_DIR"
    echo
    log_info "Example icons: heart, star, home, settings"
    log_info "Add more SVG files to $INPUT_DIR and run: bash icony.sh generate"
}

# Show usage
show_usage() {
    cat << EOF
${GREEN}icony.sh${NC} - SVG to Icon Font Generator

${BLUE}USAGE:${NC}
    icony.sh <command> [options]

${BLUE}COMMANDS:${NC}
    ${GREEN}generate${NC}    Generate icon font from SVG files
    ${GREEN}serve${NC}       Serve the showcase with HTTP server (localhost:8080)
    ${GREEN}clean${NC}       Remove generated files
    ${GREEN}init${NC}        Initialize project with example icons
    ${GREEN}help${NC}        Show this help message

${BLUE}ENVIRONMENT VARIABLES:${NC}
    INPUT_DIR       SVG input directory (default: ./icons)
    OUTPUT_DIR      Output directory (default: ./dist)
    FONT_NAME       Font file name (default: iconset)
    FONT_FAMILY     Font family name (default: IconFont)

${BLUE}EXAMPLES:${NC}
    # Generate icon font
    bash icony.sh generate

    # Custom input/output directories
    INPUT_DIR=./my-icons OUTPUT_DIR=./build bash icony.sh generate

    # Custom font name and family
    FONT_NAME=myicons FONT_FAMILY=MyIcons bash icony.sh generate

    # Serve showcase
    bash icony.sh serve

    # Clean generated files
    bash icony.sh clean

${BLUE}REQUIREMENTS:${NC}
    Required:
    • python3        - For SVG processing
    • fontforge      - For font generation
    
    Optional (recommended):
    • inkscape       - Better SVG handling
    • potrace        - Vector tracing
    • woff2          - WOFF2 compression

${BLUE}SVG REQUIREMENTS:${NC}
    • SVG files will be automatically normalized to:
      - 24x24px viewBox
      - currentColor fill
      - Centered alignment
    • No manual preparation needed!

${BLUE}OUTPUT:${NC}
    • Font files (TTF, WOFF, WOFF2*, SVG)
    • CSS stylesheet with icon classes
    • Interactive HTML showcase with Tailwind 4
    
    * WOFF2 requires woff2_compress tool

${BLUE}INSTALLATION:${NC}
    Run ${GREEN}bash icony.sh generate${NC} and it will show
    installation instructions for missing dependencies.

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
