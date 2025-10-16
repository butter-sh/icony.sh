# icony.sh

🎨 SVG to Icon Font Generator using native Linux/Unix tools

Generate beautiful icon fonts from SVG files using FontForge, Python, and Bash - no Node.js required!

## Features

- ✨ Generate web fonts from SVG files (TTF, WOFF, WOFF2, SVG)
- 🎯 Automatic SVG normalization (24x24, centered, currentColor)
- 💅 Beautiful interactive showcase with Tailwind 4
- 🔍 Real-time icon search with keyboard shortcuts
- 📋 One-click copy icon class names
- 🎨 Modern glassmorphism design with theme switching
- 🚀 Fast and lightweight - pure bash/Python/FontForge
- 🐧 Linux-native tooling (FontForge)

## Dependencies

### Required

- **Python 3** - For SVG processing
- **FontForge** - For font generation

### Optional (Recommended)

- **Inkscape** - Better SVG handling
- **Potrace** - Vector tracing
- **woff2** - WOFF2 compression

## Installation

### Install Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install python3 fontforge inkscape potrace woff2
```

**Fedora/RHEL/CentOS:**
```bash
sudo dnf install python3 fontforge inkscape potrace woff2
```

**Arch Linux:**
```bash
sudo pacman -S python fontforge inkscape potrace woff2
```

**macOS (Homebrew):**
```bash
brew install python fontforge inkscape potrace woff2
```

### Install via hammer.sh

```bash
hammer.sh icony my-icon-font
cd my-icon-font
chmod +x icony.sh
```

### Manual Installation

```bash
git clone https://github.com/YOUR_USERNAME/icony.sh.git
cd icony.sh
bash setup.sh
```

## Quick Start

1. **Add your SVG icons** to the `icons/` directory

2. **Generate the icon font:**
   ```bash
   bash icony.sh generate
   ```

3. **View the showcase:**
   ```bash
   bash icony.sh serve
   ```
   Then open http://localhost:8080 in your browser

## Usage

### Commands

```bash
# Initialize project with example icons
bash icony.sh init

# Generate icon font from SVG files
bash icony.sh generate

# Serve the showcase with HTTP server
bash icony.sh serve

# Clean generated files
bash icony.sh clean

# Show help
bash icony.sh help
```

### Environment Variables

Customize the generation process:

```bash
# Custom input directory
INPUT_DIR=./my-icons bash icony.sh generate

# Custom output directory
OUTPUT_DIR=./build bash icony.sh generate

# Custom font name
FONT_NAME=myicons bash icony.sh generate

# Custom font family
FONT_FAMILY=MyIconFont bash icony.sh generate

# Combine multiple variables
INPUT_DIR=./svg OUTPUT_DIR=./dist FONT_NAME=custom bash icony.sh generate
```

## SVG Requirements

Your SVG files will be automatically normalized to:
- **24x24px** viewBox
- **currentColor** fill (inherits text color)
- **Centered** alignment

No manual preparation needed! Just add your SVGs to the icons directory.

## Using the Generated Icons

### In HTML

```html
<!-- Include the CSS -->
<link rel="stylesheet" href="dist/iconset.css">

<!-- Use icons with classes -->
<i class="icon icon-heart"></i>
<span class="icon icon-star"></span>
<button>
  <i class="icon icon-home"></i>
  Home
</button>
```

### In CSS

```css
/* Icons inherit the current text color */
.my-button {
  color: #ff0000;
}

.my-button .icon {
  /* Icon will be red */
  font-size: 1.5rem;
}
```

### Icon Classes

Every icon gets a class based on its filename:
- `home.svg` → `.icon-home`
- `arrow-right.svg` → `.icon-arrow-right`
- `user-circle.svg` → `.icon-user-circle`

## Output Structure

After running `generate`, you'll have:

```
dist/
├── iconset.ttf          # TrueType font
├── iconset.woff         # WOFF font
├── iconset.woff2        # WOFF2 font (if woff2 installed)
├── iconset.svg          # SVG font
├── iconset.css          # CSS stylesheet
└── index.html           # Interactive showcase
```

## Showcase Features

The generated `index.html` includes:

- 🎨 **Beautiful Design**: Modern glassmorphism with gradient backgrounds
- 🔍 **Live Search**: Filter icons in real-time (Press `/` to focus search)
- 📋 **Copy to Clipboard**: Click copy button on any icon
- 🎭 **Hover Effects**: Smooth animations and interactions
- 🌈 **Theme Toggle**: Multiple color schemes
- 📱 **Responsive**: Works on all devices
- ⌨️ **Keyboard Shortcuts**: 
  - `/` - Focus search
  - `Esc` - Clear search and blur input

## How It Works

1. **SVG Normalization** (Python)
   - Parses SVG files
   - Sets viewBox to 24x24
   - Replaces colors with `currentColor`
   - Centers content

2. **Font Generation** (FontForge)
   - Creates font file
   - Maps each SVG to Unicode Private Use Area (U+E000+)
   - Scales and centers glyphs
   - Exports to multiple formats

3. **CSS Generation** (Bash)
   - Creates @font-face rules
   - Generates icon classes with Unicode mappings
   - Adds base icon styles

4. **Showcase Generation** (Bash)
   - Creates responsive HTML gallery
   - Adds search and copy functionality
   - Includes Tailwind 4 styling

## Examples

### Basic Usage

```bash
# Create project
mkdir my-icons && cd my-icons

# Initialize with examples
bash icony.sh init

# Add your SVGs to icons/ directory

# Generate
bash icony.sh generate

# View showcase
bash icony.sh serve
```

### Custom Configuration

```bash
# Generate with custom settings
INPUT_DIR=./svg-files \
OUTPUT_DIR=./public/fonts \
FONT_NAME=my-icon-set \
FONT_FAMILY=MyIcons \
bash icony.sh generate
```

### Integration Example

```html
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="dist/iconset.css">
  <style>
    .btn {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.5rem 1rem;
      background: #3b82f6;
      color: white;
      border: none;
      border-radius: 0.375rem;
      cursor: pointer;
    }
    .btn .icon {
      font-size: 1.25rem;
    }
  </style>
</head>
<body>
  <button class="btn">
    <i class="icon icon-heart"></i>
    Like
  </button>
  
  <button class="btn">
    <i class="icon icon-star"></i>
    Favorite
  </button>
  
  <button class="btn">
    <i class="icon icon-home"></i>
    Home
  </button>
</body>
</html>
```

## Best Practices

1. **Naming**: Use descriptive, kebab-case filenames (e.g., `arrow-right.svg`)
2. **Size**: Keep SVGs simple for smaller font files
3. **Colors**: Original SVG colors are replaced with `currentColor`
4. **Organization**: Group related icons in subdirectories (processed recursively)
5. **Testing**: Always view the showcase to verify icons look correct

## Troubleshooting

### Icons not showing?

- Verify CSS is properly loaded
- Check browser console for errors
- Ensure correct class names (based on filenames)
- Check that font files are accessible

### Font generation fails?

- Install FontForge: See installation instructions above
- Check SVG files are valid XML
- Try running `bash icony.sh clean` first
- Ensure Python 3 is installed

### Missing WOFF2 files?

- Install woff2 tools: `sudo apt-get install woff2`
- WOFF2 is optional but recommended for smaller file sizes

### Python errors?

- Ensure Python 3 is installed: `python3 --version`
- Check that python3 is in your PATH

## Why No Node.js?

This project uses native Linux/Unix tools for several reasons:

- ✅ **Lighter dependencies** - No npm packages to install
- ✅ **More stable** - FontForge is battle-tested font software
- ✅ **Better integration** - Works seamlessly with system tools
- ✅ **Educational** - Learn how font generation actually works
- ✅ **Server-friendly** - Easier to deploy on Linux servers

## Technical Details

### Font Metrics

- **Em size**: 1000 units
- **Ascent**: 800 units
- **Descent**: 200 units
- **Glyph size**: Auto-scaled to fit 800×800 box
- **Unicode range**: U+E000 to U+F8FF (Private Use Area)

### Supported Formats

- **TTF** - TrueType (universal support)
- **WOFF** - Web Open Font Format (good compression)
- **WOFF2** - WOFF2 (best compression, requires woff2 tools)
- **SVG** - SVG Font (legacy support)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

---

Generated by hammer.sh on 2025-10-16
