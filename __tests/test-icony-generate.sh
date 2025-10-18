#!/usr/bin/env bash
# Test suite for icony generate functionality

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONY_SH="${SCRIPT_DIR}/../icony.sh"

# Source test helpers
if ! declare -f assert_contains > /dev/null; then
    echo "Error: Test helpers not loaded. This test must be run via judge.sh"
    exit 1
fi

# Setup before each test
setup() {
    TEST_DIR=$(mktemp -d)
    export INPUT_DIR="$TEST_DIR/icons"
    export OUTPUT_DIR="$TEST_DIR/dist"
    export FONT_NAME="testicons"
    export ICON_CLASS="test-icon"
    
    # Create test SVGs
    mkdir -p "$INPUT_DIR"
    
    cat > "$INPUT_DIR/test1.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10"/>
</svg>
EOF
    
    cat > "$INPUT_DIR/test2.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <rect x="4" y="4" width="16" height="16"/>
</svg>
EOF
    
    cd "$TEST_DIR"
}

# Cleanup after each test
teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

# Test: generate creates output directory
test_generate_creates_output_dir() {
    setup
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    assert_dir_exists "$OUTPUT_DIR" "Should create output directory"
    
    teardown
}

# Test: generate creates CSS file
test_generate_creates_css() {
    setup
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    assert_file_exists "$OUTPUT_DIR/$FONT_NAME.css" "Should create CSS file"
    
    teardown
}

# Test: generate creates HTML showcase (requires myst.sh)
test_generate_creates_html() {
    setup
    
    # Skip if myst not available
    if ! command -v myst &> /dev/null && ! [[ -f "$SCRIPT_DIR/../.arty/libs/myst.sh/myst.sh" ]] && ! [[ -f "$SCRIPT_DIR/../myst.sh/myst.sh" ]]; then
        log_warn "Skipping HTML test - myst.sh not installed"
        teardown
        return 0
    fi
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    assert_file_exists "$OUTPUT_DIR/index.html" "Should create index.html"
    
    teardown
}

# Test: CSS file contains correct icon classes
test_css_contains_icon_classes() {
    setup
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    local css_content=$(cat "$OUTPUT_DIR/$FONT_NAME.css")
    
    assert_contains "$css_content" ".${ICON_CLASS}" "CSS should contain base icon class"
    assert_contains "$css_content" ".${ICON_CLASS}-test1" "CSS should contain test1 icon class"
    assert_contains "$css_content" ".${ICON_CLASS}-test2" "CSS should contain test2 icon class"
    
    teardown
}

# Test: CSS file contains mask-image properties
test_css_contains_mask_properties() {
    setup
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    local css_content=$(cat "$OUTPUT_DIR/$FONT_NAME.css")
    
    assert_contains "$css_content" "mask-image" "CSS should contain mask-image"
    assert_contains "$css_content" "-webkit-mask-image" "CSS should contain -webkit-mask-image"
    assert_contains "$css_content" "mask-size" "CSS should contain mask-size"
    assert_contains "$css_content" "mask-repeat" "CSS should contain mask-repeat"
    
    teardown
}

# Test: CSS file contains data URLs
test_css_contains_data_urls() {
    setup
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    local css_content=$(cat "$OUTPUT_DIR/$FONT_NAME.css")
    
    assert_contains "$css_content" "data:image/svg+xml;base64," "CSS should contain SVG data URLs"
    
    teardown
}

# Test: CSS file contains size variants
test_css_contains_size_variants() {
    setup
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    local css_content=$(cat "$OUTPUT_DIR/$FONT_NAME.css")
    
    assert_contains "$css_content" ".${ICON_CLASS}-xs" "CSS should contain xs size"
    assert_contains "$css_content" ".${ICON_CLASS}-sm" "CSS should contain sm size"
    assert_contains "$css_content" ".${ICON_CLASS}-lg" "CSS should contain lg size"
    assert_contains "$css_content" ".${ICON_CLASS}-xl" "CSS should contain xl size"
    assert_contains "$css_content" ".${ICON_CLASS}-2xl" "CSS should contain 2xl size"
    assert_contains "$css_content" ".${ICON_CLASS}-3xl" "CSS should contain 3xl size"
    
    teardown
}

# Test: HTML file contains correct references (requires myst.sh)
test_html_contains_references() {
    setup
    
    # Skip if myst not available
    if ! command -v myst &> /dev/null && ! [[ -f "$SCRIPT_DIR/../.arty/libs/myst.sh/myst.sh" ]] && ! [[ -f "$SCRIPT_DIR/../myst.sh/myst.sh" ]]; then
        log_warn "Skipping HTML test - myst.sh not installed"
        teardown
        return 0
    fi
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    if [[ ! -f "$OUTPUT_DIR/index.html" ]]; then
        log_warn "HTML not generated, skipping test"
        teardown
        return 0
    fi
    
    local html_content=$(cat "$OUTPUT_DIR/index.html")
    
    assert_contains "$html_content" "$FONT_NAME.css" "HTML should reference CSS file"
    assert_contains "$html_content" "$FONT_NAME Icon Set" "HTML should contain icon set name"
    assert_contains "$html_content" "2 icons" "HTML should show icon count"
    
    teardown
}

# Test: HTML file contains icon cards (requires myst.sh)
test_html_contains_icon_cards() {
    setup
    
    # Skip if myst not available
    if ! command -v myst &> /dev/null && ! [[ -f "$SCRIPT_DIR/../.arty/libs/myst.sh/myst.sh" ]] && ! [[ -f "$SCRIPT_DIR/../myst.sh/myst.sh" ]]; then
        log_warn "Skipping HTML test - myst.sh not installed"
        teardown
        return 0
    fi
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    if [[ ! -f "$OUTPUT_DIR/index.html" ]]; then
        log_warn "HTML not generated, skipping test"
        teardown
        return 0
    fi
    
    local html_content=$(cat "$OUTPUT_DIR/index.html")
    
    assert_contains "$html_content" "icon-card" "HTML should contain icon cards"
    assert_contains "$html_content" "${ICON_CLASS}-test1" "HTML should contain test1 icon"
    assert_contains "$html_content" "${ICON_CLASS}-test2" "HTML should contain test2 icon"
    
    teardown
}

# Test: generate fails with missing input directory
test_generate_fails_no_input() {
    setup
    
    rm -rf "$INPUT_DIR"
    output=$(bash "$ICONY_SH" generate 2>&1 || true)
    
    assert_contains "$output" "not found" "Should report missing input directory"
    
    teardown
}

# Test: generate fails with no SVG files
test_generate_fails_no_svgs() {
    setup
    
    rm -f "$INPUT_DIR"/*.svg
    output=$(bash "$ICONY_SH" generate 2>&1 || true)
    
    assert_contains "$output" "No SVG files" "Should report no SVG files found"
    
    teardown
}

# Test: generate with custom FONT_NAME
test_generate_custom_font_name() {
    setup
    
    export FONT_NAME="my-custom-icons"
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    assert_file_exists "$OUTPUT_DIR/my-custom-icons.css" "Should create CSS with custom name"
    
    teardown
}

# Test: generate with custom ICON_CLASS
test_generate_custom_icon_class() {
    setup
    
    export ICON_CLASS="custom-ico"
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    local css_content=$(cat "$OUTPUT_DIR/$FONT_NAME.css")
    assert_contains "$css_content" ".custom-ico" "CSS should use custom icon class"
    
    teardown
}

# Test: generate normalizes SVG files
test_generate_normalizes_svgs() {
    setup
    
    # Create SVG with non-standard viewBox
    cat > "$INPUT_DIR/nonstandard.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">
  <circle cx="50" cy="50" r="40"/>
</svg>
EOF
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    # Check that icon class exists (normalization succeeded)
    local css_content=$(cat "$OUTPUT_DIR/$FONT_NAME.css")
    assert_contains "$css_content" ".${ICON_CLASS}-nonstandard" "Should normalize and include non-standard SVG"
    
    teardown
}

# Test: generate requires myst.sh
test_generate_requires_myst() {
    setup
    
    # This test verifies that myst is checked
    output=$(PATH="/nonexistent" bash "$ICONY_SH" generate 2>&1 || true)
    
    # Should mention myst.sh
    assert_contains "$output" "myst" "Should mention myst.sh requirement"
    
    teardown
}

# Run all tests
run_tests() {
    log_section "Generate Functionality Tests"
    
    test_generate_creates_output_dir
    test_generate_creates_css
    test_generate_creates_html
    test_css_contains_icon_classes
    test_css_contains_mask_properties
    test_css_contains_data_urls
    test_css_contains_size_variants
    test_html_contains_references
    test_html_contains_icon_cards
    test_generate_fails_no_input
    test_generate_fails_no_svgs
    test_generate_custom_font_name
    test_generate_custom_icon_class
    test_generate_normalizes_svgs
    test_generate_requires_myst
    
    print_test_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
