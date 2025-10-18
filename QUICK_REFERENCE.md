# Icony Quick Reference Card

## 🚀 Quick Commands

```bash
# Help
icony.sh help

# Initialize with examples
icony.sh init

# Generate icon set
icony.sh generate

# Serve showcase
icony.sh serve

# Clean output
icony.sh clean
```

## 📦 Migration

```bash
# Migrate to cleaned version
bash migrate.sh

# Rollback if needed
bash rollback.sh
```

## 🧪 Testing

```bash
# Run all tests
arty exec judge run

# Verbose output
arty exec judge run -v

# Specific test file
arty exec judge run __tests/test-icony-generate.sh

# Update snapshots
arty exec judge run -u
```

## 🔧 Configuration

```bash
# Custom directories
INPUT_DIR=./my-icons OUTPUT_DIR=./build icony.sh generate

# Custom naming
FONT_NAME=myicons ICON_CLASS=ico icony.sh generate

# All together
INPUT_DIR=./icons OUTPUT_DIR=./dist \
FONT_NAME=custom ICON_CLASS=icon-custom \
icony.sh generate
```

## 📁 File Structure

```
icony/
├── icony.sh                              # Main script
├── generate_showcase_function.sh         # HTML generation
├── index.html.myst                       # Myst template
├── setup.sh                              # Setup hook
├── arty.yml                              # Dependencies
│
├── __tests/                              # Test suite
│   ├── test-icony-init.sh               # 5 tests
│   ├── test-icony-generate.sh           # 14 tests
│   ├── test-icony-helpers.sh            # 6 tests
│   ├── test-icony-cli.sh                # 15 tests
│   ├── test-icony-integration.sh        # 10 tests
│   └── test-icony-svg-processing.sh     # 10 tests
│
└── docs/
    ├── SUMMARY.md                        # Complete overview
    ├── STRUCTURE.md                      # Before/after
    └── QUICK_REFERENCE.md                # This file
```

## 🎨 Usage in HTML

```html
<!-- Link stylesheet -->
<link rel="stylesheet" href="dist/iconset.css">

<!-- Basic icon -->
<i class="icon icon-heart"></i>

<!-- Sized icons -->
<i class="icon icon-star icon-xs"></i>
<i class="icon icon-star icon-sm"></i>
<i class="icon icon-star icon-lg"></i>
<i class="icon icon-star icon-xl"></i>
<i class="icon icon-star icon-2xl"></i>
<i class="icon icon-star icon-3xl"></i>

<!-- Colored icons (uses currentColor) -->
<span style="color: red;">
  <i class="icon icon-heart"></i>
</span>

<!-- With CSS classes -->
<i class="icon icon-home text-blue-500"></i>
```

## 🔍 Troubleshooting

### Tests failing?

```bash
# Check python3
which python3

# Verbose test output
arty exec judge run -v

# Check specific test
bash __tests/test-icony-generate.sh
```

### Myst not working?

```bash
# Check if installed
arty list | grep myst

# Install myst
arty install https://github.com/butter-sh/myst.sh.git

# Verify detection
bash icony.sh generate 2>&1 | grep -i myst
```

### Generation fails?

```bash
# Check input directory
ls -la icons/

# Check for SVG files
find icons/ -name "*.svg"

# Try with example icons
bash icony.sh init
bash icony.sh generate
```

### Clean not working?

```bash
# Manual cleanup
rm -rf dist/

# Check environment variable
echo $OUTPUT_DIR
```

## 📊 Test Coverage

| Area | Tests | File |
|------|-------|------|
| Init | 5 | test-icony-init.sh |
| Generate | 14 | test-icony-generate.sh |
| Helpers | 6 | test-icony-helpers.sh |
| CLI | 15 | test-icony-cli.sh |
| Integration | 10 | test-icony-integration.sh |
| SVG Processing | 10 | test-icony-svg-processing.sh |
| **Total** | **60+** | |

## 🎯 Common Workflows

### Create New Icon Set

```bash
# 1. Create project
mkdir my-icons && cd my-icons

# 2. Initialize
bash /path/to/icony.sh init

# 3. Add your SVGs to icons/
cp ~/Downloads/*.svg icons/

# 4. Generate
bash /path/to/icony.sh generate

# 5. Preview
bash /path/to/icony.sh serve
# Open http://localhost:8080
```

### Update Existing Icon Set

```bash
# 1. Add new SVGs
cp new-icons/*.svg icons/

# 2. Regenerate
bash icony.sh generate

# 3. View changes
bash icony.sh serve
```

### Custom Configuration

```bash
# Create config script
cat > generate.sh << 'EOF'
#!/bin/bash
INPUT_DIR=./svg-source
OUTPUT_DIR=./public/icons
FONT_NAME=app-icons
ICON_CLASS=app-icon

bash icony.sh generate
EOF

chmod +x generate.sh
./generate.sh
```

## 🔗 Dependencies

### Required
- `bash` (4.0+)
- `python3` - For SVG normalization
- `base64` - For encoding (usually included)

### Optional
- `myst.sh` - For better templating
- `judge.sh` - For running tests

### Install Optional

```bash
# Install via arty
arty install https://github.com/butter-sh/myst.sh.git
arty install https://github.com/butter-sh/judge.sh.git
```

## 📝 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `INPUT_DIR` | `./icons` | SVG input directory |
| `OUTPUT_DIR` | `./dist` | Output directory |
| `FONT_NAME` | `iconset` | CSS filename |
| `ICON_CLASS` | `icon` | Base CSS class |

## 🎨 CSS Classes Generated

### Base Class
```css
.icon {
  display: inline-block;
  width: 1em;
  height: 1em;
  background-color: currentColor;
  mask-size: contain;
  /* ... */
}
```

### Size Variants
```css
.icon-xs   { width: 0.75em;  height: 0.75em; }
.icon-sm   { width: 0.875em; height: 0.875em; }
.icon-lg   { width: 1.25em;  height: 1.25em; }
.icon-xl   { width: 1.5em;   height: 1.5em; }
.icon-2xl  { width: 2em;     height: 2em; }
.icon-3xl  { width: 3em;     height: 3em; }
```

### Icon Classes
```css
.icon-heart {
  mask-image: url('data:image/svg+xml;base64,...');
  -webkit-mask-image: url('data:image/svg+xml;base64,...');
}
```

## 🚨 Common Errors

### "Python3 not found"
```bash
# Install python3
# Ubuntu/Debian
sudo apt-get install python3

# macOS
brew install python3

# Then retry
bash icony.sh generate
```

### "No SVG files found"
```bash
# Check directory
ls icons/

# Verify SVG format
file icons/*.svg

# Should show: SVG Scalable Vector Graphics image
```

### "Test framework not found"
```bash
# Install judge.sh
arty install https://github.com/butter-sh/judge.sh.git

# Verify
arty exec judge --version
```

### "Myst template not found"
```bash
# Check file exists
ls -la index.html.myst

# If missing, reinstall or use bash fallback
# (Script will automatically use bash generation)
```

## 💡 Tips & Tricks

### Batch Process Icons

```bash
# Process multiple icon sets
for dir in icons-*; do
  INPUT_DIR=$dir OUTPUT_DIR=dist/${dir#icons-} \
  bash icony.sh generate
done
```

### Auto-regenerate on Changes

```bash
# Install inotify-tools first
# Then:
while inotifywait -e modify,create,delete icons/; do
  bash icony.sh generate
done
```

### Verify Generated CSS

```bash
# Count icons
grep -c "^\.icon-" dist/iconset.css

# List all icons
grep "^\.icon-" dist/iconset.css | sed 's/ {.*//' | sort
```

### Check HTML Features

```bash
# Verify search function
grep -q "searchIcons" dist/index.html && echo "✓ Search"

# Verify copy function
grep -q "copyIconClass" dist/index.html && echo "✓ Copy"

# Verify theme toggle
grep -q "toggleTheme" dist/index.html && echo "✓ Theme"
```

## 📚 Documentation

- `SUMMARY.md` - Complete overview and migration guide
- `STRUCTURE.md` - Before/after visualization
- `CLEANUP_AND_TESTS.md` - Detailed cleanup explanation
- `__tests/README.md` - Test suite documentation
- `QUICK_REFERENCE.md` - This file

## 🆘 Getting Help

1. Check documentation files
2. Run tests to verify setup: `arty exec judge run -v`
3. Check troubleshooting section above
4. Review test files for examples

## ✨ Key Features

- ✅ **No web fonts needed** - Pure CSS + SVG
- ✅ **currentColor support** - Easy theming
- ✅ **Size variants** - xs to 3xl
- ✅ **Search functionality** - In showcase
- ✅ **Copy to clipboard** - One-click class copy
- ✅ **Theme toggle** - Multiple color schemes
- ✅ **Fully tested** - 60+ comprehensive tests
- ✅ **Myst.sh support** - Better templating
- ✅ **Responsive** - Mobile-friendly showcase

## 🎓 Learning Path

1. **Start Simple**
   ```bash
   bash icony.sh init
   bash icony.sh generate
   bash icony.sh serve
   ```

2. **Customize**
   ```bash
   FONT_NAME=myicons bash icony.sh generate
   ```

3. **Add Your Icons**
   ```bash
   cp ~/myicons/*.svg icons/
   bash icony.sh generate
   ```

4. **Run Tests**
   ```bash
   arty exec judge run
   ```

5. **Integrate in Project**
   ```html
   <link rel="stylesheet" href="path/to/iconset.css">
   <i class="icon icon-heart"></i>
   ```

---

**Quick Links:**
- 📖 [Complete Guide](SUMMARY.md)
- 🏗️ [Structure Comparison](STRUCTURE.md)
- 🧪 [Test Documentation](__tests/README.md)
- 🔄 [Migration Script](migrate.sh)
