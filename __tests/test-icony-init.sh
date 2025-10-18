#!/usr/bin/env bash
# Test suite for icony init functionality

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
    cd "$TEST_DIR"
}

# Cleanup after each test
teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

# Test: icony init creates icons directory
test_init_creates_icons_directory() {
    setup
    
    bash "$ICONY_SH" init 2>&1
    
    assert_dir_exists "$INPUT_DIR" "Should create icons directory"
    
    teardown
}

# Test: icony init creates example SVG files
test_init_creates_example_svgs() {
    setup
    
    bash "$ICONY_SH" init 2>&1
    
    assert_file_exists "$INPUT_DIR/heart.svg" "Should create heart.svg"
    assert_file_exists "$INPUT_DIR/star.svg" "Should create star.svg"
    assert_file_exists "$INPUT_DIR/home.svg" "Should create home.svg"
    assert_file_exists "$INPUT_DIR/settings.svg" "Should create settings.svg"
    assert_file_exists "$INPUT_DIR/check.svg" "Should create check.svg"
    
    teardown
}

# Test: icony init creates valid SVG files
test_init_creates_valid_svgs() {
    setup
    
    bash "$ICONY_SH" init 2>&1
    
    assert_contains "$(cat $INPUT_DIR/heart.svg)" "xmlns" "SVG should have xmlns attribute"
    assert_contains "$(cat $INPUT_DIR/heart.svg)" "viewBox" "SVG should have viewBox attribute"
    assert_contains "$(cat $INPUT_DIR/heart.svg)" "<path" "SVG should have path element"
    
    teardown
}

# Test: icony init with custom INPUT_DIR
test_init_custom_input_dir() {
    setup
    
    export INPUT_DIR="$TEST_DIR/custom-icons"
    bash "$ICONY_SH" init 2>&1
    
    assert_dir_exists "$TEST_DIR/custom-icons" "Should create custom icons directory"
    assert_file_exists "$TEST_DIR/custom-icons/heart.svg" "Should create heart.svg in custom dir"
    
    teardown
}

# Test: icony init is idempotent (doesn't fail if icons exist)
test_init_is_idempotent() {
    setup
    
    bash "$ICONY_SH" init 2>&1
    output=$(bash "$ICONY_SH" init 2>&1)
    
    # Should not produce errors
    assert_not_contains "$output" "Error" "Should not error on second init"
    
    teardown
}

# Run all tests
run_tests() {
    log_section "Init Functionality Tests"
    
    test_init_creates_icons_directory
    test_init_creates_example_svgs
    test_init_creates_valid_svgs
    test_init_custom_input_dir
    test_init_is_idempotent
    
    print_test_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
