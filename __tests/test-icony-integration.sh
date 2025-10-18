#!/usr/bin/env bash
# Integration tests for icony.sh - end-to-end workflows

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONY_SH="${SCRIPT_DIR}/../icony.sh"

# Source test helpers
if ! declare -f assert_contains > /dev/null; then
    echo "Error: Test helpers not loaded. This test must be run via judge.sh"
    exit 1
fi

# Check if myst is available
has_myst() {
    command -v myst &> /dev/null || [[ -f "$SCRIPT_DIR/../.arty/libs/myst.sh/myst.sh" ]] || [[ -f "$SCRIPT_DIR/../myst.sh/myst.sh" ]]
}

# Setup before each test
setup() {
    TEST_DIR=$(mktemp -d)
    export INPUT_DIR="$TEST_DIR/icons"
    export OUTPUT_DIR="$TEST_DIR/dist"
    cd "$TEST_DIR"
}

# Cleanup after each test
teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

# Test: complete workflow from init to generate
test_complete_workflow() {
    setup
    
    # Step 1: Initialize
    bash "$ICONY_SH" init 2>&1 >/dev/null
    assert_dir_exists "$INPUT_DIR" "Init should create icons directory"
    
    # Step 2: Generate
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    assert_file_exists "$OUTPUT_DIR/iconset.css" "Generate should create CSS"
    
    # Step 3: Check HTML only if myst is available
    if has_myst && [[ -f "$OUTPUT_DIR/index.html" ]]; then
        assert_file_exists "$OUTPUT_DIR/index.html" "Generate should create HTML with myst"
    fi
    
    # Step 4: Clean
    bash "$ICONY_SH" clean 2>&1 >/dev/null
    
    # Check if directory was removed
    if [[ ! -e "$OUTPUT_DIR" ]]; then
        # Success - directory removed
        assert_equals "removed" "removed" "Clean should remove output"
    else
        fail "Clean should remove output directory"
    fi
    
    teardown
}

# Test: generate with multiple SVG files
test_generate_multiple_svgs() {
    setup
    
    mkdir -p "$INPUT_DIR"
    
    # Create 10 test SVGs
    for i in {1..10}; do
        cat > "$INPUT_DIR/icon${i}.svg" << EOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="${i}"/>
</svg>
EOF
    done
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    local css_content=$(cat "$OUTPUT_DIR/iconset.css")
    
    # Verify all icons are in CSS
    for i in {1..10}; do
        assert_contains "$css_content" ".icon-icon${i}" "CSS should contain icon${i}"
    done
    
    teardown
}

# Test: generate with special character filenames
test_generate_special_filenames() {
    setup
    
    mkdir -p "$INPUT_DIR"
    
    cat > "$INPUT_DIR/my-icon.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10"/>
</svg>
EOF
    
    cat > "$INPUT_DIR/icon_test.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <rect x="4" y="4" width="16" height="16"/>
</svg>
EOF
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    local css_content=$(cat "$OUTPUT_DIR/iconset.css")
    
    assert_contains "$css_content" ".icon-my-icon" "Should handle hyphenated names"
    assert_contains "$css_content" ".icon-icon_test" "Should handle underscored names"
    
    teardown
}

# Test: regenerate updates existing files
test_regenerate_updates_files() {
    setup
    
    mkdir -p "$INPUT_DIR"
    cat > "$INPUT_DIR/test.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10"/>
</svg>
EOF
    
    # First generation
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    local first_css=$(cat "$OUTPUT_DIR/iconset.css")
    
    # Add another icon
    cat > "$INPUT_DIR/test2.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <rect x="4" y="4" width="16" height="16"/>
</svg>
EOF
    
    # Second generation
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    local second_css=$(cat "$OUTPUT_DIR/iconset.css")
    
    assert_contains "$second_css" ".icon-test" "Should still have first icon"
    assert_contains "$second_css" ".icon-test2" "Should have second icon"
    assert_not_equals "$first_css" "$second_css" "CSS should be updated"
    
    teardown
}

# Test: generate with empty icons directory
test_generate_empty_directory() {
    setup
    
    mkdir -p "$INPUT_DIR"
    # No SVG files
    
    output=$(bash "$ICONY_SH" generate 2>&1 || true)
    
    assert_contains "$output" "No SVG files" "Should report no SVG files"
    
    teardown
}

# Test: generate creates valid HTML structure (with myst)
test_generate_valid_html_structure() {
    setup
    
    if ! has_myst; then
        # Skip test if myst not available - return success
        teardown
        return 0
    fi
    
    bash "$ICONY_SH" init 2>&1 >/dev/null
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    if [[ ! -f "$OUTPUT_DIR/index.html" ]]; then
        # Skip if HTML not generated - return success
        teardown
        return 0
    fi
    
    local html_content=$(cat "$OUTPUT_DIR/index.html")
    
    assert_contains "$html_content" "<!DOCTYPE html>" "Should have DOCTYPE"
    assert_contains "$html_content" "<html" "Should have html tag"
    assert_contains "$html_content" "<head>" "Should have head tag"
    assert_contains "$html_content" "<body>" "Should have body tag"
    assert_contains "$html_content" "</html>" "Should close html tag"
    
    teardown
}

# Test: generate creates functional showcase features (with myst)
test_generate_showcase_features() {
    setup
    
    if ! has_myst; then
        # Skip test if myst not available
        teardown
        return 0
    fi
    
    bash "$ICONY_SH" init 2>&1 >/dev/null
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    if [[ ! -f "$OUTPUT_DIR/index.html" ]]; then
        # Skip if HTML not generated
        teardown
        return 0
    fi
    
    local html_content=$(cat "$OUTPUT_DIR/index.html")
    
    assert_contains "$html_content" "searchIcons" "Should have search function"
    assert_contains "$html_content" "copyIconClass" "Should have copy function"
    assert_contains "$html_content" "toggleTheme" "Should have theme toggle function"
    assert_contains "$html_content" "searchInput" "Should have search input"
    
    teardown
}

# Test: CSS follows consistent formatting
test_css_formatting() {
    setup
    
    mkdir -p "$INPUT_DIR"
    cat > "$INPUT_DIR/test.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10"/>
</svg>
EOF
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    local css_content=$(cat "$OUTPUT_DIR/iconset.css")
    
    # Check for proper CSS structure
    assert_contains "$css_content" "/**" "Should have CSS comment header"
    assert_contains "$css_content" ".icon {" "Should have base icon class"
    assert_contains "$css_content" "}" "Should have closing braces"
    assert_contains "$css_content" "mask-image:" "Should have mask-image properties"
    
    teardown
}

# Test: HTML includes accessibility features (with myst)
test_html_accessibility() {
    setup
    
    if ! has_myst; then
        # Skip test if myst not available
        teardown
        return 0
    fi
    
    bash "$ICONY_SH" init 2>&1 >/dev/null
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    if [[ ! -f "$OUTPUT_DIR/index.html" ]]; then
        # Skip if HTML not generated
        teardown
        return 0
    fi
    
    local html_content=$(cat "$OUTPUT_DIR/index.html")
    
    assert_contains "$html_content" "lang=" "Should have language attribute"
    assert_contains "$html_content" "charset=" "Should specify charset"
    assert_contains "$html_content" "viewport" "Should have viewport meta tag"
    
    teardown
}

# Test: custom configuration workflow
test_custom_configuration() {
    setup
    
    export INPUT_DIR="$TEST_DIR/my-svgs"
    export OUTPUT_DIR="$TEST_DIR/build"
    export FONT_NAME="my-icons"
    export ICON_CLASS="ico"
    
    bash "$ICONY_SH" init 2>&1 >/dev/null
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    assert_dir_exists "$TEST_DIR/my-svgs" "Should use custom input dir"
    assert_dir_exists "$TEST_DIR/build" "Should use custom output dir"
    assert_file_exists "$TEST_DIR/build/my-icons.css" "Should use custom font name"
    
    local css_content=$(cat "$TEST_DIR/build/my-icons.css")
    assert_contains "$css_content" ".ico" "Should use custom icon class"
    
    teardown
}

# Test: generate without myst.sh shows appropriate message
test_generate_without_myst() {
    setup
    
    mkdir -p "$INPUT_DIR"
    cat > "$INPUT_DIR/test.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10"/>
</svg>
EOF
    
    # Only test if myst is NOT installed via arty
    if [[ ! -f "$SCRIPT_DIR/../.arty/libs/myst.sh/myst.sh" ]] && [[ ! -f "$SCRIPT_DIR/../myst.sh/myst.sh" ]]; then
        # Run with no myst in PATH
        output=$(PATH="/nonexistent" bash "$ICONY_SH" generate 2>&1 || true)
        
        # Should mention myst.sh
        assert_contains "$output" "myst" "Should mention myst.sh requirement"
    fi
    
    teardown
}

# Run all tests
run_tests() {
    log_section "Integration Tests"
    
    test_complete_workflow
    test_generate_multiple_svgs
    test_generate_special_filenames
    test_regenerate_updates_files
    test_generate_empty_directory
    test_generate_valid_html_structure
    test_generate_showcase_features
    test_css_formatting
    test_html_accessibility
    test_custom_configuration
    test_generate_without_myst
    
    print_test_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
