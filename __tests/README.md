# Icony Test Suite

Comprehensive test suite for icony.sh - SVG to Icon Set Generator

## Quick Start

```bash
# Run all tests
arty exec judge run

# Run with verbose output
arty exec judge run -v

# Update snapshots
arty exec judge run -u
```

## Test Files

### `test-icony-init.sh`
Tests for the `init` command functionality:
- Icons directory creation
- Example SVG generation
- Valid SVG file structure
- Custom INPUT_DIR support
- Idempotent behavior

**Test count:** 5

### `test-icony-generate.sh`
Tests for the `generate` command:
- Output directory and file creation
- CSS generation with correct classes
- Mask-image property inclusion
- Data URL generation
- Size variant classes
- HTML showcase generation
- Icon class naming
- Error handling for missing inputs
- Custom FONT_NAME and ICON_CLASS
- SVG normalization

**Test count:** 14

### `test-icony-helpers.sh`
Tests for helper functions:
- Python3 dependency checking
- Logging functions (info, success, warn, error, step)
- SVG normalization logic
- Data URL creation
- Installation instructions

**Test count:** 6

### `test-icony-cli.sh`
Tests for CLI interface:
- Help command and flags (--help, -h)
- Command short forms (gen, g, c, s, i)
- Unknown command handling
- Environment variable support
- Error messages

**Test count:** 15

### `test-icony-integration.sh`
End-to-end integration tests:
- Complete workflow (init → generate → clean)
- Multiple SVG file processing
- Special character filenames
- Regeneration and updates
- HTML structure validation
- Showcase features (search, copy, theme)
- CSS formatting consistency
- Accessibility features
- Custom configuration workflows

**Test count:** 10

### `test-icony-svg-processing.sh`
SVG processing and normalization:
- Different viewBox values
- Missing width/height attributes
- Complex SVG paths
- Multiple SVG elements
- Namespaced attributes
- Embedded styles
- Grouped elements
- Transform attributes
- Malformed SVG handling
- Base64 encoding validation

**Test count:** 10

## Total Coverage

- **Test Files:** 7 (including config)
- **Test Cases:** 60+
- **Lines of Test Code:** ~1,500+

## Test Structure

Each test file follows this pattern:

```bash
#!/usr/bin/env bash
# Test suite for [feature]

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

# Test cases...
test_something() {
    setup
    
    # Test logic
    bash "$ICONY_SH" command 2>&1 >/dev/null
    
    assert_file_exists "$OUTPUT_DIR/file.css" "Description"
    
    teardown
}

# Run all tests
run_tests() {
    log_section "Section Name"
    
    test_something
    test_another_thing
    
    print_test_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
```

## Available Assertions

From judge.sh test framework:

- `assert_equals <actual> <expected> <message>`
- `assert_not_equals <actual> <expected> <message>`
- `assert_contains <haystack> <needle> <message>`
- `assert_not_contains <haystack> <needle> <message>`
- `assert_file_exists <path> <message>`
- `assert_not_exists <path> <message>`
- `assert_dir_exists <path> <message>`
- `assert_empty <string> <message>`
- `assert_not_empty <string> <message>`

## Running Individual Tests

```bash
# Run specific test file
bash __tests/test-icony-generate.sh

# Run with judge.sh (recommended)
arty exec judge run __tests/test-icony-generate.sh
```

## Continuous Integration

Add to `.github/workflows/test.yml`:

```yaml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y python3
      
      - name: Install arty and judge
        run: |
          # Install arty
          git clone https://github.com/butter-sh/arty.sh.git
          cd arty.sh && bash arty.sh install && cd ..
          
          # Install judge via arty
          arty install https://github.com/butter-sh/judge.sh.git
      
      - name: Run tests
        run: arty exec judge run
```

## Adding New Tests

1. Create new test file: `__tests/test-icony-[feature].sh`
2. Follow the structure pattern above
3. Add setup/teardown for isolation
4. Write descriptive test names
5. Use appropriate assertions
6. Add to test suite via judge auto-discovery

## Test Best Practices

1. **Isolation:** Use temporary directories in setup
2. **Cleanup:** Always teardown after tests
3. **Independence:** Tests shouldn't depend on each other
4. **Clarity:** Descriptive names and messages
5. **Coverage:** Test happy paths AND error cases

## Debugging Tests

```bash
# Verbose output
arty exec judge run -v

# Run single test function
bash __tests/test-icony-generate.sh

# Keep test directory for inspection
# Modify teardown temporarily:
# teardown() {
#     echo "Test dir: $TEST_DIR"
#     # cd /
#     # rm -rf "$TEST_DIR"
# }
```

## Environment Variables

Tests respect these environment variables:

- `INPUT_DIR` - SVG input directory
- `OUTPUT_DIR` - Generated files output
- `FONT_NAME` - CSS file name
- `ICON_CLASS` - Base icon class name
- `UPDATE_SNAPSHOTS` - Update test snapshots
- `VERBOSE` - Verbose test output

## Dependencies

- `bash` (4.0+)
- `python3` - For SVG processing
- `judge.sh` - Test framework
- Standard Unix tools: `find`, `sed`, `base64`, `mktemp`

## Reporting Issues

If tests fail:

1. Run with verbose output: `arty exec judge run -v`
2. Check the error message and assertion
3. Inspect temporary directory if needed
4. Report with full output and environment details

## Contributing

When adding features to icony:

1. Write tests first (TDD)
2. Ensure all existing tests pass
3. Add tests for new functionality
4. Update this README if needed
5. Maintain >80% code coverage

## License

Same as icony.sh - MIT License
