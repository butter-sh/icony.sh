#!/usr/bin/env bash
# Test suite for SVG normalization and processing

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
    mkdir -p "$INPUT_DIR"
    cd "$TEST_DIR"
}

# Cleanup after each test
teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

# Test: normalize SVG with different viewBox
test_normalize_different_viewbox() {
    setup
    
    cat > "$INPUT_DIR/test.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">
  <circle cx="50" cy="50" r="40"/>
</svg>
EOF
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    assert_file_exists "$OUTPUT_DIR/iconset.css" "Should normalize and generate CSS"
    
    local css_content=$(cat "$OUTPUT_DIR/iconset.css")
    assert_contains "$css_content" ".icon-test" "Should include normalized icon"
    
    teardown
}

# Test: normalize SVG without width/height attributes
test_normalize_no_dimensions() {
    setup
    
    cat > "$INPUT_DIR/test.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path d="M256 8C119 8 8 119 8 256s111 248 248 248 248-111 248-248S393 8 256 8z"/>
</svg>
EOF
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    assert_file_exists "$OUTPUT_DIR/iconset.css" "Should normalize SVG without dimensions"
    
    teardown
}

# Test: handle SVG with complex paths
test_normalize_complex_paths() {
    setup
    
    cat > "$INPUT_DIR/complex.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
</svg>
EOF
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    local css_content=$(cat "$OUTPUT_DIR/iconset.css")
    assert_contains "$css_content" ".icon-complex" "Should handle complex paths"
    assert_contains "$css_content" "data:image/svg+xml;base64," "Should encode to data URL"
    
    teardown
}

# Test: handle SVG with multiple elements
test_normalize_multiple_elements() {
    setup
    
    cat > "$INPUT_DIR/multi.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10"/>
  <path d="M12 2L12 22"/>
  <rect x="10" y="10" width="4" height="4"/>
</svg>
EOF
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    local css_content=$(cat "$OUTPUT_DIR/iconset.css")
    assert_contains "$css_content" ".icon-multi" "Should handle multiple elements"
    
    teardown
}

# Test: handle SVG with namespaced attributes
test_normalize_namespaced_attributes() {
    setup
    
    cat > "$INPUT_DIR/namespaced.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10"/>
</svg>
EOF
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    local css_content=$(cat "$OUTPUT_DIR/iconset.css")
    assert_contains "$css_content" ".icon-namespaced" "Should handle namespaced attributes"
    
    teardown
}

# Test: handle SVG with embedded styles
test_normalize_embedded_styles() {
    setup
    
    cat > "$INPUT_DIR/styled.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <style>
    .st0{fill:#FF0000;}
  </style>
  <circle class="st0" cx="12" cy="12" r="10"/>
</svg>
EOF
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    local css_content=$(cat "$OUTPUT_DIR/iconset.css")
    assert_contains "$css_content" ".icon-styled" "Should handle embedded styles"
    
    teardown
}

# Test: handle SVG with groups
test_normalize_groups() {
    setup
    
    cat > "$INPUT_DIR/grouped.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <g>
    <circle cx="12" cy="12" r="10"/>
    <path d="M12 2L12 22"/>
  </g>
</svg>
EOF
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    local css_content=$(cat "$OUTPUT_DIR/iconset.css")
    assert_contains "$css_content" ".icon-grouped" "Should handle grouped elements"
    
    teardown
}

# Test: handle SVG with transforms
test_normalize_transforms() {
    setup
    
    cat > "$INPUT_DIR/transformed.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10" transform="rotate(45 12 12)"/>
</svg>
EOF
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    local css_content=$(cat "$OUTPUT_DIR/iconset.css")
    assert_contains "$css_content" ".icon-transformed" "Should handle transforms"
    
    teardown
}

# Test: handle malformed SVG gracefully
test_handle_malformed_svg() {
    setup
    
    # Create a valid SVG
    cat > "$INPUT_DIR/valid.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10"/>
</svg>
EOF
    
    # Create a malformed SVG
    cat > "$INPUT_DIR/malformed.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10"
</svg>
EOF
    
    output=$(bash "$ICONY_SH" generate 2>&1 || true)
    
    # Should warn about malformed but continue
    assert_contains "$output" "Failed to normalize" "Should report normalization failure"
    
    # Valid icon should still be processed
    local css_content=$(cat "$OUTPUT_DIR/iconset.css")
    assert_contains "$css_content" ".icon-valid" "Should still process valid icons"
    
    teardown
}

# Test: base64 encoding is valid
test_base64_encoding_valid() {
    setup
    
    cat > "$INPUT_DIR/test.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10"/>
</svg>
EOF
    
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    local css_content=$(cat "$OUTPUT_DIR/iconset.css")
    
    # Extract base64 data
    if [[ "$css_content" =~ data:image/svg\+xml\;base64,([A-Za-z0-9+/=]+) ]]; then
        local base64_data="${BASH_REMATCH[1]}"
        
        # Try to decode it (should not fail)
        decoded=$(echo "$base64_data" | base64 -d 2>/dev/null || echo "FAILED")
        
        assert_not_equals "$decoded" "FAILED" "Base64 should be valid"
        assert_contains "$decoded" "svg" "Decoded data should contain SVG"
    else
        fail "Should contain valid base64 data URL"
    fi
    
    teardown
}

# Run all tests
run_tests() {
    log_section "SVG Normalization Tests"
    
    test_normalize_different_viewbox
    test_normalize_no_dimensions
    test_normalize_complex_paths
    test_normalize_multiple_elements
    test_normalize_namespaced_attributes
    test_normalize_embedded_styles
    test_normalize_groups
    test_normalize_transforms
    test_handle_malformed_svg
    test_base64_encoding_valid
    
    print_test_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
