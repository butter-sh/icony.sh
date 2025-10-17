# icony.sh

🎭 SVG to Icon Set Generator using CSS mask-image

Generate beautiful icon sets from SVG files using modern CSS `mask-image` with embedded data URLs - no web fonts needed!

## Features

- ✨ **CSS mask-image** - No web fonts, just modern CSS
- 🎨 **Perfect currentColor** - Icons inherit text color naturally
- 📦 **Embedded data URLs** - SVGs embedded directly in CSS
- 💅 **Beautiful showcase** - Interactive gallery with Tailwind 4
- 🔍 **Real-time search** - Filter icons instantly
- 📋 **One-click copy** - Copy class names to clipboard
- 🎯 **Size variants** - From xs to 3xl
- 🚀 **Lightweight** - Only Python 3 required!
- 🌈 **Theme support** - Works perfectly with color schemes

## Technology

This generator uses **CSS `mask-image`** instead of traditional web fonts:

```css
.icon {
  mask-image: url('data:image/svg+xml,...');
  background-color: currentColor;
}
```

### Benefits

- ✅ **No font files** - No TTF, WOFF, WOFF2 needed
- ✅ **Perfect color** - Uses currentColor natively
- ✅ **Modern** - Clean, CSS-only approach
- ✅ **Flexible** - Easy to modify and customize
- ✅ **Lightweight** - Smaller than font files

### Browser Support

- Chrome 120+
- Firefox 53+
- Safari 15.4+
- Edge 120+

## Dependencies

### Required

- **Python 3** - For SVG processing (that's it!)

### Installation

**Ubuntu/Debian:**
```bash
sudo apt-get install python3
```

**macOS:**
```bash
brew install python3
```

**Fedora/RHEL:**
```bash
sudo dnf install python3
```

## Installation

### Via hammer.sh

```bash
hammer.sh icony my-icon-set
cd my-icon-set
chmod +x icony.sh
```

### Manual

```bash
git clone https://github.com/YOUR_USERNAME/icony.sh.git
cd icony.sh
bash setup.sh
```

## Quick Start

1. **Add your SVG icons** to the `icons/` directory

2. **Generate the icon set:**
   ```bash
   bash icony.sh generate
   ```

3. **View the showcase:**
   ```bash
   bash icony.sh serve
   ```
   Then open http://localhost:8080

## Usage

### Commands

```bash
# Initialize with example icons
bash icony.sh init

# Generate icon set from SVG files
bash icony.sh generate

# Serve the showcase
bash icony.sh serve

# Clean generated files
bash icony.sh clean

# Show help
bash icony.sh help
```

### Environment Variables

```bash
# Custom input directory
INPUT_DIR=./my-icons bash icony.sh generate

# Custom output directory
OUTPUT_DIR=./build bash icony.sh generate

# Custom CSS filename
FONT_NAME=myicons bash icony.sh generate

# Custom icon class name
ICON_CLASS=ico bash icony.sh generate

# Combine all
INPUT_DIR=./svg OUTPUT_DIR=./dist FONT_NAME=custom ICON_CLASS=i bash icony.sh generate
```

## SVG Requirements

Your SVG files will be automatically normalized:
- **24x24px** viewBox
- **Black fill** (for mask-image)
- **Centered** alignment

No manual preparation needed!

## Using the Generated Icons

### In HTML

```html
<!-- Include the CSS -->
<link rel="stylesheet" href="dist/iconset.css">

<!-- Basic usage -->
<i class="icon icon-heart"></i>
<i class="icon icon-star"></i>
<i class="icon icon-home"></i>

<!-- With size variants -->
<i class="icon icon-heart icon-xs"></i>
<i class="icon icon-heart icon-sm"></i>
<i class="icon icon-heart icon-lg"></i>
<i class="icon icon-heart icon-xl"></i>
<i class="icon icon-heart icon-2xl"></i>
<i class="icon icon-heart icon-3xl"></i>

<!-- With color (uses currentColor) -->
<i class="icon icon-heart" style="color: red;"></i>
<span class="icon icon-star" style="color: #fbbf24;"></span>
```

### Size Variants

| Class | Size |
|-------|------|
| `icon-xs` | 0.75em |
| `icon-sm` | 0.875em |
| (default) | 1em |
| `icon-lg` | 1.25em |
| `icon-xl` | 1.5em |
| `icon-2xl` | 2em |
| `icon-3xl` | 3em |

### Color Theming

Icons automatically use `currentColor`:

```html
<!-- Red icon -->
<div style="color: red;">
  <i class="icon icon-heart"></i>
</div>

<!-- Blue icon -->
<div class="text-blue-500">
  <i class="icon icon-star"></i>
</div>

<!-- Custom color -->
<i class="icon icon-home" style="color: #10b981;"></i>
```

### CSS Styling

```css
/* Change icon color */
.icon {
  color: #3b82f6;
}

/* Custom size */
.icon-custom {
  width: 2.5rem;
  height: 2.5rem;
}

/* With Tailwind */
.text-red-500 .icon {
  /* Icon will be red */
}
```

### Icon Classes

Filename → CSS Class:
- `home.svg` → `.icon-home`
- `arrow-right.svg` → `.icon-arrow-right`
- `user-circle.svg` → `.icon-user-circle`

## Output Structure

After running `generate`:

```
dist/
├── iconset.css       # Icon stylesheet with mask-image
└── index.html        # Interactive showcase
```

## Showcase Features

The generated `index.html` includes:

- 🎨 **Beautiful Design** - Modern glassmorphism
- 🔍 **Live Search** - Press `/` to search
- 📋 **Copy Classes** - One-click copy
- 🌈 **Theme Toggle** - Multiple color schemes
- 📱 **Responsive** - Works on all devices
- ⌨️ **Keyboard Shortcuts** - `/` to search, `Esc` to clear
- 📖 **Usage Examples** - Code samples included

## How It Works

1. **SVG Normalization** (Python)
   - Parses SVG files
   - Sets 24x24 viewBox
   - Converts to black fill (for mask)
   - Centers content

2. **Data URL Generation** (Bash + Python)
   - Converts SVG to data URL
   - URL-encodes for CSS
   - Embeds in stylesheet

3. **CSS Generation** (Bash)
   - Creates icon classes
   - Uses `mask-image` property
   - Applies `currentColor` via `background-color`

4. **Showcase** (Bash)
   - Interactive HTML gallery
   - Search and filter
   - Copy functionality
   - Tailwind 4 styling

## Examples

### Basic Integration

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
      color: white;
      background: #3b82f6;
      border: none;
      border-radius: 0.375rem;
      cursor: pointer;
    }
  </style>
</head>
<body>
  <button class="btn">
    <i class="icon icon-heart"></i>
    Like
  </button>
</body>
</html>
```

### With Tailwind CSS

```html
<div class="flex items-center gap-2 text-blue-600">
  <i class="icon icon-star icon-lg"></i>
  <span class="font-semibold">Featured</span>
</div>

<div class="flex items-center gap-2 text-red-500">
  <i class="icon icon-heart icon-xl"></i>
  <span>Favorites</span>
</div>
```

### Dark Mode

```css
/* Light mode */
.icon {
  color: #1f2937;
}

/* Dark mode */
@media (prefers-color-scheme: dark) {
  .icon {
    color: #f3f4f6;
  }
}
```

## Best Practices

1. **Naming** - Use kebab-case: `arrow-right.svg`
2. **Simplicity** - Keep SVGs simple for smaller CSS
3. **Colors** - Original colors are converted to black for mask
4. **Testing** - Check in modern browsers

## Advantages Over Web Fonts

| Feature | Web Fonts | CSS mask-image |
|---------|-----------|----------------|
| **File Size** | Separate font files | Embedded in CSS |
| **Color Control** | Limited | Perfect currentColor |
| **Loading** | Extra HTTP request | Inline in CSS |
| **Flexibility** | Font metrics | Pure CSS |
| **Modification** | Regenerate font | Edit CSS |
| **Dependencies** | FontForge | Just Python |

## Browser Compatibility

CSS `mask-image` is widely supported:

- ✅ Chrome 120+ (Dec 2023)
- ✅ Firefox 53+ (Apr 2017)
- ✅ Safari 15.4+ (Mar 2022)
- ✅ Edge 120+ (Dec 2023)

For older browsers, consider a fallback or use the web font version.

## Troubleshooting

### Icons not showing?

- Check browser supports `mask-image`
- Verify CSS is loaded
- Ensure correct class names

### Colors not working?

- Icons use `currentColor`
- Set color on parent or icon element
- Check CSS specificity

### Python errors?

```bash
python3 --version  # Should be 3.x
```

## Migration from Web Fonts

If you have existing icon font code:

**Before (web font):**
```html
<i class="icon icon-heart"></i>
```

**After (mask-image):**
```html
<i class="icon icon-heart"></i>
```

The HTML is the same! Just replace the CSS file.

## Why mask-image?

- 🚀 **Modern** - Uses cutting-edge CSS
- 🎨 **Better** - Perfect color control
- 📦 **Simpler** - No font files
- ⚡ **Faster** - Inline in CSS
- 🔧 **Flexible** - Easy to customize

## Contributing

Contributions welcome! Please submit a Pull Request.

## License

MIT License - see LICENSE file

---

Generated by hammer.sh on 2025-10-18
