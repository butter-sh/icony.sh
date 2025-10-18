# Generate showcase HTML using myst.sh if available, fallback to bash generation
generate_showcase() {
    local output_dir="$1"
    local font_name="$2"
    local html_file="$output_dir/index.html"
    
    log_step "Generating showcase HTML..."
    
    # Collect icon names
    local icons=()
    while IFS= read -r -d '' svg_file; do
        local filename=$(basename "$svg_file" .svg")
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
    
    # Check if myst.sh is available (installed via arty.sh dependencies)
    local use_myst=false
    if [[ -f "$SCRIPT_DIR/myst.sh/myst.sh" ]] && [[ -f "$SCRIPT_DIR/index.html.myst" ]]; then
        use_myst=true
        log_info "Using myst.sh templating engine"
    elif command -v myst >/dev/null 2>&1 && [[ -f "$SCRIPT_DIR/index.html.myst" ]]; then
        use_myst=true
        log_info "Using myst.sh templating engine (from PATH)"
    fi
    
    if [[ "$use_myst" == true ]]; then
        # Use myst.sh to render the template
        local myst_cmd
        if [[ -f "$SCRIPT_DIR/myst.sh/myst.sh" ]]; then
            myst_cmd="bash $SCRIPT_DIR/myst.sh/myst.sh"
        else
            myst_cmd="myst"
        fi
        
        # Create temporary file for icon grid HTML
        local temp_icons_html=$(mktemp)
        echo "$icons_html" > "$temp_icons_html"
        
        # Render with myst.sh
        $myst_cmd render "$SCRIPT_DIR/index.html.myst" \
            -v font_name="$font_name" \
            -v icon_class="$ICON_CLASS" \
            -v icon_count="${#icons[@]}" \
            -v icon_grid_html="$icons_html" \
            -v myst_enabled="true" \
            -o "$html_file" 2>/dev/null || {
            log_warn "myst.sh rendering failed, falling back to bash generation"
            use_myst=false
        }
        
        rm -f "$temp_icons_html"
    fi
    
    # Fallback to bash generation if myst.sh not available or failed
    if [[ "$use_myst" != true ]]; then
        # Original bash generation code
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
    fi
    
    log_success "Showcase generated: $html_file"
}
