#!/usr/bin/env bash
# Test suite for icony CLI functionality

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

# Test: help command shows usage
test_help_command() {
    setup
    
    output=$(bash "$ICONY_SH" help 2>&1)
    
    assert_contains "$output" "icony.sh" "Should show script name"
    assert_contains "$output" "USAGE" "Should show usage section"
    assert_contains "$output" "COMMANDS" "Should show commands section"
    assert_contains "$output" "generate" "Should list generate command"
    assert_contains "$output" "serve" "Should list serve command"
    assert_contains "$output" "clean" "Should list clean command"
    assert_contains "$output" "init" "Should list init command"
    
    teardown
}

# Test: --help flag shows usage
test_help_flag() {
    setup
    
    output=$(bash "$ICONY_SH" --help 2>&1)
    
    assert_contains "$output" "USAGE" "Should show usage with --help flag"
    
    teardown
}

# Test: -h flag shows usage
test_h_flag() {
    setup
    
    output=$(bash "$ICONY_SH" -h 2>&1)
    
    assert_contains "$output" "USAGE" "Should show usage with -h flag"
    
    teardown
}

# Test: no arguments shows usage
test_no_args_shows_usage() {
    setup
    
    output=$(bash "$ICONY_SH" 2>&1)
    
    assert_contains "$output" "USAGE" "Should show usage when no arguments provided"
    
    teardown
}

# Test: unknown command shows error
test_unknown_command() {
    setup
    
    output=$(bash "$ICONY_SH" unknowncommand 2>&1 || true)
    
    assert_contains "$output" "Unknown command" "Should report unknown command"
    
    teardown
}

# Test: generate command short form
test_generate_short_form() {
    setup
    
    mkdir -p "$INPUT_DIR"
    cat > "$INPUT_DIR/test.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10"/>
</svg>
EOF
    
    bash "$ICONY_SH" gen 2>&1 >/dev/null
    
    assert_file_exists "$OUTPUT_DIR/iconset.css" "Short form 'gen' should work"
    
    teardown
}

# Test: generate command single letter form
test_generate_single_letter() {
    setup
    
    mkdir -p "$INPUT_DIR"
    cat > "$INPUT_DIR/test.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10"/>
</svg>
EOF
    
    bash "$ICONY_SH" g 2>&1 >/dev/null
    
    assert_file_exists "$OUTPUT_DIR/iconset.css" "Single letter 'g' should work"
    
    teardown
}

# Test: clean command removes output directory
test_clean_command() {
    setup
    
    mkdir -p "$OUTPUT_DIR"
    echo "test" > "$OUTPUT_DIR/test.txt"
    
    bash "$ICONY_SH" clean 2>&1 >/dev/null
    
    assert_not_exists "$OUTPUT_DIR" "Clean should remove output directory"
    
    teardown
}

# Test: clean command short form
test_clean_short_form() {
    setup
    
    mkdir -p "$OUTPUT_DIR"
    echo "test" > "$OUTPUT_DIR/test.txt"
    
    bash "$ICONY_SH" c 2>&1 >/dev/null
    
    assert_not_exists "$OUTPUT_DIR" "Short form 'c' should work for clean"
    
    teardown
}

# Test: serve command requires generated files
test_serve_requires_generated() {
    setup
    
    output=$(bash "$ICONY_SH" serve 2>&1 || true)
    
    assert_contains "$output" "not found" "Should report missing output directory"
    
    teardown
}

# Test: init command short form
test_init_short_form() {
    setup
    
    bash "$ICONY_SH" i 2>&1 >/dev/null
    
    assert_dir_exists "$INPUT_DIR" "Short form 'i' should work for init"
    
    teardown
}

# Test: environment variable INPUT_DIR is respected
test_env_var_input_dir() {
    setup
    
    export INPUT_DIR="$TEST_DIR/my-icons"
    bash "$ICONY_SH" init 2>&1 >/dev/null
    
    assert_dir_exists "$TEST_DIR/my-icons" "Should use INPUT_DIR environment variable"
    
    teardown
}

# Test: environment variable OUTPUT_DIR is respected
test_env_var_output_dir() {
    setup
    
    mkdir -p "$INPUT_DIR"
    cat > "$INPUT_DIR/test.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10"/>
</svg>
EOF
    
    export OUTPUT_DIR="$TEST_DIR/my-dist"
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    assert_dir_exists "$TEST_DIR/my-dist" "Should use OUTPUT_DIR environment variable"
    
    teardown
}

# Test: environment variable FONT_NAME is respected
test_env_var_font_name() {
    setup
    
    mkdir -p "$INPUT_DIR"
    cat > "$INPUT_DIR/test.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10"/>
</svg>
EOF
    
    export FONT_NAME="custom-icons"
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    assert_file_exists "$OUTPUT_DIR/custom-icons.css" "Should use FONT_NAME environment variable"
    
    teardown
}

# Test: environment variable ICON_CLASS is respected
test_env_var_icon_class() {
    setup
    
    mkdir -p "$INPUT_DIR"
    cat > "$INPUT_DIR/test.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10"/>
</svg>
EOF
    
    export ICON_CLASS="my-icon"
    bash "$ICONY_SH" generate 2>&1 >/dev/null
    
    local css_content=$(cat "$OUTPUT_DIR/iconset.css")
    assert_contains "$css_content" ".my-icon" "Should use ICON_CLASS environment variable"
    
    teardown
}

# Run all tests
run_tests() {
    log_section "CLI Functionality Tests"
    
    test_help_command
    test_help_flag
    test_h_flag
    test_no_args_shows_usage
    test_unknown_command
    test_generate_short_form
    test_generate_single_letter
    test_clean_command
    test_clean_short_form
    test_serve_requires_generated
    test_init_short_form
    test_env_var_input_dir
    test_env_var_output_dir
    test_env_var_font_name
    test_env_var_icon_class
    
    print_test_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
