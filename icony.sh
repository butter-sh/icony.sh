#!/usr/bin/env bash

# icony.sh - SVG to Icon Font Generator
# Version: 2.0.0
# Generates icon fonts using CSS mask-image with embedded SVG data URLs

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="${INPUT_DIR:-$PWD/icons}"
OUTPUT_DIR="${OUTPUT_DIR:-$PWD/dist}"
FONT_NAME="${FONT_NAME:-iconset}"
ICON_CLASS="${ICON_CLASS:-icon}"

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
    
    # Only Python 3 is required
    if ! command -v python3 &> /dev/null; then
        log_error "Missing required dependency: python3"
        echo
        show_install_instructions
        return 1
    fi
    
    # base64 should be available on all Unix systems
    if ! command -v base64 &> /dev/null; then
        log_warn "base64 command not found (unusual)"
    fi
    
    return 0
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
                echo "  sudo apt-get install python3"
                ;;
            fedora|rhel|centos)
                echo "  ${GREEN}Fedora/RHEL/CentOS:${NC}"
                echo "  sudo dnf install python3"
                ;;
            arch|manjaro)
                echo "  ${GREEN}Arch Linux:${NC}"
                echo "  sudo pacman -S python"
                ;;
            opensuse*)
                echo "  ${GREEN}openSUSE:${NC}"
                echo "  sudo zypper install python3"
                ;;
        esac
    fi
    
    # macOS
    echo
    echo "  ${GREEN}macOS:${NC}"
    echo "  brew install python3"
    
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
        
        # Remove any existing fill/stroke attributes
        # for elem in root.iter():
        #     # Remove color attributes - we'll use currentColor via mask
        #     for attr in ['fill', 'stroke', 'color', 'style']:
        #         if attr in elem.attrib:
        #             if attr == 'style':
        #                 # Remove color-related styles
        #                 style = elem.attrib[attr]
        #                 style = re.sub(r'fill:[^;]+;?', '', style)
        #                 style = re.sub(r'stroke:[^;]+;?', '', style)
        #                 if style.strip():
        #                     elem.attrib[attr] = style
        #                 else:
        #                     del elem.attrib[attr]
        #             else:
        #                 del elem.attrib[attr]
            
        #     # Set fill to black for mask (mask uses alpha channel)
        #     # tag = elem.tag.split('}')[-1] if '}' in elem.tag else elem.tag
        #     if tag in ['path', 'circle', 'rect', 'polygon', 'polyline', 'ellipse', 'line']:
        #         elem.set('fill', 'black')
        
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
    
    # Read SVG content and encode to base64
    local svg_content=$(cat "$svg_file")
    
    # Remove XML declaration if present
    # svg_content=$(echo "$svg_content" | sed '/<\?xml/d')
    
    # To base64
   	svg_content=$(echo "$svg_content" | base64 -w 0)
    
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

# Generate showcase HTML
generate_showcase() {
    local output_dir="$1"
    local font_name="$2"
    local html_file="$output_dir/index.html"
    
    log_step "Generating showcase HTML..."
    
    # Collect icon names
    local icons=()
    while IFS= read -r -d '' svg_file; do
        local filename=$(basename "$svg_file" .svg)
        icons+=("$filename")
    done < <(find "$TEMP_DIR" -type f -name "*.svg" -print0 | sort -z)
    
    # Generate icon grid HTML
    local icons_html=""
    for icon in "${icons[@]}"; do
        icons_html+="        <div class=\"icon-card group\">"
        icons_html+="          <i class=\"${ICON_CLASS} ${ICON_CLASS}-${icon}\"></i>"
        icons_html+="          <span class=\"icon-name\">${icon}</span>"
        icons_html+="          <button class=\"copy-btn\" onclick=\"copyIconClass('${ICON_CLASS}-${icon}')\" title=\"Copy class name\">"
        icons_html+="            <svg class=\"w-4 h-4\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">"
        icons_html+="              <path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z\" />"
        icons_html+="            </svg>"
        icons_html+="          </button>"
        icons_html+="        </div>"
    done
    
    cat > "$html_file" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FONT_NAME - Icon Set Showcase</title>
  <link rel="stylesheet" href="FONT_NAME.css">
  <script src="https://cdn.tailwindcss.com/"></script>
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
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 0.75rem;
      padding: 1.5rem;
      min-height: 120px;
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
    
    .icon-card .ICON_CLASS {
      font-size: 2.5rem;
      transition: all 0.3s;
      color: white;
    }
    
    .icon-card:hover .ICON_CLASS {
      transform: scale(1.2) rotate(5deg);
      color: #fbbf24;
    }
    
    .icon-name {
      font-size: 0.75rem;
      color: rgba(255, 255, 255, 0.9);
      font-weight: 500;
      text-align: center;
      word-break: break-word;
    }
    
    .copy-btn {
      opacity: 0;
      transition: all 0.2s;
      position: absolute;
      top: 0.5rem;
      right: 0.5rem;
      padding: 0.375rem;
      background: rgba(255, 255, 255, 0.2);
      border: 1px solid rgba(255, 255, 255, 0.3);
      border-radius: 0.375rem;
      color: white;
      cursor: pointer;
    }
    
    .icon-card:hover .copy-btn {
      opacity: 1;
    }
    
    .copy-btn:hover {
      transform: scale(1.1);
      background: rgba(255, 255, 255, 0.3);
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
    
    .code-block {
      background: rgba(0, 0, 0, 0.3);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 0.5rem;
      padding: 1rem;
      font-family: 'Courier New', monospace;
      font-size: 0.875rem;
      color: #a5f3fc;
      overflow-x: auto;
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
            FONT_NAME Icon Set
          </h1>
          <p class="text-gray-200 text-lg">
            Beautiful icons using <span class="font-bold text-yellow-300">CSS mask-image</span> • <span class="font-bold">ICON_COUNT icons</span>
          </p>
          <p class="text-gray-300 text-sm mt-1">
            Generated by icony.sh • No web fonts, just CSS + SVG data URLs
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
      <div class="relative mb-6">
        <input 
          type="text" 
          id="searchInput" 
          placeholder="Search icons... (press '/' to focus)" 
          class="w-full px-6 py-4 rounded-xl bg-white/10 border border-white/20 text-white placeholder-gray-300 focus:outline-none focus:ring-2 focus:ring-white/50 transition-all"
          oninput="searchIcons(this.value)"
        />
        <svg class="absolute right-4 top-1/2 -translate-y-1/2 w-6 h-6 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      </div>
      
      <!-- Usage Example -->
      <div class="space-y-4">
        <div class="code-block">
          <div class="text-xs text-gray-400 mb-2">HTML Usage:</div>
          <code>&lt;i class="ICON_CLASS ICON_CLASS-example"&gt;&lt;/i&gt;</code>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="code-block">
            <div class="text-xs text-gray-400 mb-2">Size Variants:</div>
            <code>&lt;i class="ICON_CLASS ICON_CLASS-heart ICON_CLASS-xs"&gt;&lt;/i&gt;<br>
&lt;i class="ICON_CLASS ICON_CLASS-heart ICON_CLASS-sm"&gt;&lt;/i&gt;<br>
&lt;i class="ICON_CLASS ICON_CLASS-heart ICON_CLASS-lg"&gt;&lt;/i&gt;<br>
&lt;i class="ICON_CLASS ICON_CLASS-heart ICON_CLASS-xl"&gt;&lt;/i&gt;</code>
          </div>
          
          <div class="code-block">
            <div class="text-xs text-gray-400 mb-2">Color Theming:</div>
            <code>/* Icons use currentColor */<br>
.text-red-500 .ICON_CLASS { color: #ef4444; }<br>
.text-blue-500 .ICON_CLASS { color: #3b82f6; }</code>
          </div>
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
    <div class="mt-8 glass rounded-2xl p-6 text-center text-white">
      <h3 class="text-lg font-semibold mb-2">🎭 CSS Mask-Image Technology</h3>
      <p class="text-sm text-gray-200 mb-2">
        Icons use CSS <code class="px-2 py-1 bg-black/30 rounded">mask-image</code> with embedded SVG data URLs
      </p>
      <p class="text-xs text-gray-300">
        No web fonts needed • Perfect currentColor support • Lightweight • Modern browsers
      </p>
      <div class="mt-4 text-xs text-gray-400">
        Generated with ❤️ using icony.sh • Python • Bash
      </div>
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

    function unsecuredCopyToClipboard(text) {
      const textArea = document.createElement("textarea");
      textArea.value = text;
      document.body.appendChild(textArea);
      textArea.focus();
      textArea.select();
      try {
        document.execCommand('copy');
      } catch (err) {
        console.error('Unable to copy to clipboard', err);
      }
      document.body.removeChild(textArea);
    }

    function copyIconClass(iconClass) {
      if (window.isSecureContext && navigator.clipboard) {
        navigator.clipboard.writeText(iconClass).then(() => {
          showToast();
        });
      } else {
        unsecuredCopyToClipboard(iconClass);
        showToast();
      }
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
    sed -i "s/ICON_CLASS/$ICON_CLASS/g" "$html_file"
    sed -i "s/ICON_COUNT/${#icons[@]}/g" "$html_file"
    
    # Use perl for multiline replacement (more reliable)
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
    log_info "Starting icon set generation with CSS mask-image..."
    echo
    
    # Check dependencies
    if ! check_dependencies; then
        return 1
    fi
    
    # Create temp directory
    TEMP_DIR="$(dirname $OUTPUT_DIR)/temp"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
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
    
    # Generate showcase
    log_step "Step 4: Generating showcase HTML"
    generate_showcase "$OUTPUT_DIR" "$FONT_NAME"
    echo
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    
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
    
    ${YELLOW}Note:${NC} mask-image is supported in Chrome 120+, Firefox 53+, 
    Safari 15.4+, Edge 120+

${BLUE}REQUIREMENTS:${NC}
    Required:
    • python3        - For SVG processing
    
    That's it! No FontForge, no Node.js needed.

${BLUE}SVG REQUIREMENTS:${NC}
    • SVG files will be automatically normalized to:
      - 24x24px viewBox
      - Black fill (for mask)
      - Centered alignment
    • No manual preparation needed!

${BLUE}OUTPUT:${NC}
    • ${FONT_NAME}.css - Icon stylesheet with mask-image
    • index.html - Interactive showcase with Tailwind 4
    
${BLUE}USAGE IN HTML:${NC}
    <link rel="stylesheet" href="dist/iconset.css">
    
    <i class="icon icon-heart"></i>
    <i class="icon icon-star icon-lg"></i>
    <span class="icon icon-home icon-2xl" style="color: red;"></span>

${BLUE}SIZE VARIANTS:${NC}
    • icon-xs   (0.75em)
    • icon-sm   (0.875em)
    • icon      (1em - default)
    • icon-lg   (1.25em)
    • icon-xl   (1.5em)
    • icon-2xl  (2em)
    • icon-3xl  (3em)

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
