#!/usr/bin/env bash
# Test suite for icony helper functions and utilities

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
    cd "$TEST_DIR"
}

# Cleanup after each test
teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

# Test: check_dependencies detects python3 and myst
test_check_dependencies_success() {
    setup
    
    # Test with python3 and myst available
    if command -v python3 &> /dev/null && (command -v myst &> /dev/null || [[ -f "$SCRIPT_DIR/../.arty/libs/myst.sh/myst.sh" ]]); then
        cat > "$TEST_DIR/test_deps.sh" << 'EOF'
#!/usr/bin/env bash
source "${1}"
if check_dependencies 2>&1; then
    echo "success"
fi
EOF
        output=$(bash "$TEST_DIR/test_deps.sh" "$ICONY_SH" 2>&1)
        assert_contains "$output" "success" "Should pass when dependencies are available"
    fi
    
    teardown
}

# Test: check_dependencies fails without python3
test_check_dependencies_no_python3() {
    setup
    
    cat > "$TEST_DIR/test_no_python.sh" << 'EOF'
#!/usr/bin/env bash
PATH="/nonexistent"
source "${1}"
check_dependencies 2>&1 || echo "failed"
EOF
    
    output=$(bash "$TEST_DIR/test_no_python.sh" "$ICONY_SH")
    
    assert_contains "$output" "python3" "Should report missing python3"
    assert_contains "$output" "failed" "Should fail without python3"
    
    teardown
}

# Test: check_dependencies fails without myst.sh
test_check_dependencies_no_myst() {
    setup
    
    cat > "$TEST_DIR/test_no_myst.sh" << 'EOF'
#!/usr/bin/env bash
# Remove myst from PATH but keep python3
if command -v python3 &> /dev/null; then
    PYTHON_PATH=$(command -v python3)
    PYTHON_DIR=$(dirname "$PYTHON_PATH")
    PATH="$PYTHON_DIR"
    source "${1}"
    check_dependencies 2>&1 || echo "failed"
else
    echo "python3 not available"
fi
EOF
    
    output=$(bash "$TEST_DIR/test_no_myst.sh" "$ICONY_SH")
    
    # Should mention myst unless it's installed via arty
    if ! [[ -f "$SCRIPT_DIR/../.arty/libs/myst.sh/myst.sh" ]] && ! [[ -f "$SCRIPT_DIR/../myst.sh/myst.sh" ]]; then
        assert_contains "$output" "myst" "Should report missing myst.sh"
    fi
    
    teardown
}

# Test: logging functions produce output
test_logging_functions() {
    setup
    
    cat > "$TEST_DIR/test_logging.sh" << 'EOF'
#!/usr/bin/env bash
source "${1}"

log_info "Info message"
log_success "Success message"
log_warn "Warning message"
log_error "Error message"
log_step "Step message"
EOF
    
    output=$(bash "$TEST_DIR/test_logging.sh" "$ICONY_SH" 2>&1)
    
    assert_contains "$output" "Info message" "Should log info message"
    assert_contains "$output" "Success message" "Should log success message"
    assert_contains "$output" "Warning message" "Should log warning message"
    assert_contains "$output" "Error message" "Should log error message"
    assert_contains "$output" "Step message" "Should log step message"
    
    teardown
}

# Test: normalize_svg creates valid output
test_normalize_svg() {
    setup
    
    # Create test SVG
    cat > "$TEST_DIR/input.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">
  <circle cx="50" cy="50" r="40"/>
</svg>
EOF
    
    cat > "$TEST_DIR/test_normalize.sh" << 'EOF'
#!/usr/bin/env bash
source "${1}"
if normalize_svg "${2}" "${3}"; then
    echo "success"
fi
EOF
    
    output=$(bash "$TEST_DIR/test_normalize.sh" "$ICONY_SH" "$TEST_DIR/input.svg" "$TEST_DIR/output.svg" 2>&1)
    
    assert_contains "$output" "success" "Should normalize SVG successfully"
    assert_file_exists "$TEST_DIR/output.svg" "Should create output file"
    
    # Check normalized content
    local normalized=$(cat "$TEST_DIR/output.svg")
    assert_contains "$normalized" "viewBox=\"0 0 24 24\"" "Should normalize viewBox to 24x24"
    assert_contains "$normalized" "width=\"24\"" "Should set width to 24"
    assert_contains "$normalized" "height=\"24\"" "Should set height to 24"
    
    teardown
}

# Test: svg_to_data_url creates base64 data URL
test_svg_to_data_url() {
    setup
    
    cat > "$TEST_DIR/test.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10"/>
</svg>
EOF
    
    cat > "$TEST_DIR/test_data_url.sh" << 'EOF'
#!/usr/bin/env bash
source "${1}"
svg_to_data_url "${2}"
EOF
    
    output=$(bash "$TEST_DIR/test_data_url.sh" "$ICONY_SH" "$TEST_DIR/test.svg")
    
    assert_contains "$output" "data:image/svg+xml;base64," "Should create data URL with base64 prefix"
    
    teardown
}

# Test: show_install_instructions shows OS-specific instructions
test_show_install_instructions() {
    setup
    
    cat > "$TEST_DIR/test_install.sh" << 'EOF'
#!/usr/bin/env bash
source "${1}"
show_install_instructions 2>&1
EOF
    
    output=$(bash "$TEST_DIR/test_install.sh" "$ICONY_SH")
    
    assert_contains "$output" "Installation instructions" "Should show installation header"
    assert_contains "$output" "python3" "Should mention python3"
    assert_contains "$output" "myst" "Should mention myst.sh"
    
    teardown
}

# Test: find_myst locates myst.sh
test_find_myst() {
    setup
    
    cat > "$TEST_DIR/test_find_myst.sh" << 'EOF'
#!/usr/bin/env bash
source "${1}"
if myst_cmd=$(find_myst); then
    echo "found: $myst_cmd"
else
    echo "not found"
fi
EOF
    
    output=$(bash "$TEST_DIR/test_find_myst.sh" "$ICONY_SH" 2>&1)
    
    # Should either find myst or report not found
    if command -v myst &> /dev/null || [[ -f "$SCRIPT_DIR/../.arty/libs/myst.sh/myst.sh" ]] || [[ -f "$SCRIPT_DIR/../myst.sh/myst.sh" ]]; then
        assert_contains "$output" "found" "Should find myst when available"
    else
        assert_contains "$output" "not found" "Should report when myst not available"
    fi
    
    teardown
}

# Run all tests
run_tests() {
    log_section "Helper Functions Tests"
    
    test_check_dependencies_success
    test_check_dependencies_no_python3
    test_check_dependencies_no_myst
    test_logging_functions
    test_normalize_svg
    test_svg_to_data_url
    test_show_install_instructions
    test_find_myst
    
    print_test_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
