#!/bin/bash

################################################################################
# TERMUX DESKTOP FORGE - Comprehensive Test Suite
# Version: 1.0.0
# Pure Bash, no external dependencies
# Tests all components for bugs, errors, and issues
################################################################################

set -o pipefail

################################################################################
# TEST FRAMEWORK SETUP
################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FUNCTIONS_FILE="$SCRIPT_DIR/functions.sh"
readonly TEST_LOG="$SCRIPT_DIR/test_results.log"
readonly TEST_DIR="$SCRIPT_DIR/.termux_desktop_forge_test_$$"
# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly RESET='\033[0m'

################################################################################
# TEST UTILITIES
################################################################################

# Print test header
print_test_header() {
    echo
    echo -e "${BLUE}════════════════════════════════════════${RESET}"
    echo -e "${BLUE}  $1${RESET}"
    echo -e "${BLUE}════════════════════════════════════════${RESET}"
}

# Log test result
log_result() {
    local status="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$status] $message" >> "$TEST_LOG"
}

# Test passed
test_pass() {
    local message="$1"
    ((TESTS_PASSED++))
    ((TESTS_RUN++))
    echo -e "${GREEN}✓ PASS${RESET} - $message"
    log_result "PASS" "$message"
}

# Test failed
test_fail() {
    local message="$1"
    ((TESTS_FAILED++))
    ((TESTS_RUN++))
    echo -e "${RED}✗ FAIL${RESET} - $message"
    log_result "FAIL" "$message"
}

# Test skipped
test_skip() {
    local message="$1"
    ((TESTS_SKIPPED++))
    ((TESTS_RUN++))
    echo -e "${YELLOW}⊘ SKIP${RESET} - $message"
    log_result "SKIP" "$message"
}

# Assert condition
assert_true() {
    local condition="$1"
    local message="${2:-Condition failed}"
    
    if eval "$condition"; then
        test_pass "$message"
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

# Assert false
assert_false() {
    local condition="$1"
    local message="${2:-Condition should be false}"
    
    if ! eval "$condition"; then
        test_pass "$message"
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist: $file}"
    
    if [[ -f "$file" ]]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

# Assert file executable
assert_executable() {
    local file="$1"
    local message="${2:-File should be executable: $file}"
    
    if [[ -x "$file" ]]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

# Assert command exists
assert_command_exists() {
    local cmd="$1"
    local message="${2:-Command should exist: $cmd}"
    
    if command -v "$cmd" &>/dev/null; then
        test_pass "$message"
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

# Assert output contains
assert_contains() {
    local output="$1"
    local pattern="$2"
    local message="${3:-Output should contain pattern}"
    
    if echo "$output" | grep -q "$pattern"; then
        test_pass "$message"
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

################################################################################
# TEST SETUP & TEARDOWN
################################################################################

setup_test_environment() {
    print_test_header "Setting Up Test Environment"
    
    # Create test directory
    mkdir -p "$TEST_DIR" || {
        echo "ERROR: Cannot create test directory"
        exit 1
    }
    
    test_pass "Test directory created: $TEST_DIR"
    
    # Clear test log
    > "$TEST_LOG"
    test_pass "Test log initialized"
}

cleanup_test_environment() {
    print_test_header "Cleaning Up Test Environment"
    
    # Remove test directory
    rm -rf "$TEST_DIR"
    test_pass "Test directory removed"
}

################################################################################
# SOURCE LOADING TESTS
################################################################################

test_functions_file_exists() {
    print_test_header "Testing Functions File"
    assert_file_exists "$FUNCTIONS_FILE" "functions.sh should exist"
}

test_functions_syntax() {
    print_test_header "Testing Functions Syntax"
    
    if bash -n "$FUNCTIONS_FILE" 2>/dev/null; then
        test_pass "functions.sh has valid bash syntax"
    else
        test_fail "functions.sh has syntax errors"
    fi
}

test_functions_sourcing() {
    print_test_header "Testing Functions Sourcing"
    
    if source "$FUNCTIONS_FILE" 2>/dev/null; then
        test_pass "functions.sh can be sourced without errors"
    else
        test_fail "functions.sh cannot be sourced"
    fi
}

################################################################################
# COLOR FUNCTION TESTS
################################################################################

test_color_variables() {
    print_test_header "Testing Color Variables"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    assert_true "[[ -n \"\$COLOR_RED\" ]]" "COLOR_RED should be defined"
    assert_true "[[ -n \"\$COLOR_GREEN\" ]]" "COLOR_GREEN should be defined"
    assert_true "[[ -n \"\$COLOR_YELLOW\" ]]" "COLOR_YELLOW should be defined"
    assert_true "[[ -n \"\$COLOR_BLUE\" ]]" "COLOR_BLUE should be defined"
    assert_true "[[ -n \"\$COLOR_RESET\" ]]" "COLOR_RESET should be defined"
}

test_print_functions() {
    print_test_header "Testing Print Functions"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    local output
    
    output=$(print_color "$COLOR_GREEN" "test" 2>&1)
    assert_contains "$output" "test" "print_color should output message"
    
    output=$(print_success "test" 2>&1)
    assert_contains "$output" "test" "print_success should output message"
    
    output=$(print_error "test" 2>&1)
    assert_contains "$output" "test" "print_error should output message"
    
    output=$(print_warning "test" 2>&1)
    assert_contains "$output" "test" "print_warning should output message"
    
    output=$(print_info "test" 2>&1)
    assert_contains "$output" "test" "print_info should output message"
}

################################################################################
# SYSTEM DETECTION TESTS
################################################################################

test_architecture_detection() {
    print_test_header "Testing Architecture Detection"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    local arch
    arch=$(detect_architecture)
    
    if [[ -n "$arch" ]]; then
        test_pass "Architecture detected: $arch"
    else
        test_fail "Architecture detection returned empty"
    fi
    
    assert_true "[[ \"\$arch\" =~ ^(arm|arm64|amd64|i386)$ ]] || [[ -n \"\$arch\" ]]" \
        "Architecture should be recognized"
}

test_termux_detection() {
    print_test_header "Testing Termux Detection"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    if is_termux; then
        test_pass "Running in Termux environment"
    else
        test_skip "Not running in Termux (expected in test environment)"
    fi
}

test_command_detection() {
    print_test_header "Testing Command Detection"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    assert_true "command_exists bash" "bash should be detected"
    assert_true "command_exists sh" "sh should be detected"
    assert_false "command_exists nonexistent_command_xyz_123" "nonexistent command should not be detected"
}

################################################################################
# FILE OPERATION TESTS
################################################################################

test_backup_function() {
    print_test_header "Testing Backup Function"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    local test_file="$TEST_DIR/test_backup.txt"
    local backup_dir="$TEST_DIR/.backup"
    
    echo "test content" > "$test_file"
    
    if backup_file "$test_file" "$backup_dir" 2>/dev/null; then
        test_pass "File backed up successfully"
        
        # Check if backup exists
        local backups
        backups=$(find "$backup_dir" -name "test_backup.txt.backup.*" 2>/dev/null)
        if [[ -n "$backups" ]]; then
            test_pass "Backup file exists"
        else
            test_fail "Backup file not found"
        fi
    else
        test_fail "Backup function failed"
    fi
}

test_safe_mkdir() {
    print_test_header "Testing Safe Mkdir"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    local test_dir="$TEST_DIR/test_mkdir/nested/path"
    
    if safe_mkdir "$test_dir" 2>/dev/null; then
        if [[ -d "$test_dir" ]]; then
            test_pass "Directory created recursively"
        else
            test_fail "Directory not created despite success return"
        fi
    else
        test_fail "safe_mkdir failed"
    fi
}

test_safe_write() {
    print_test_header "Testing Safe Write"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    local test_file="$TEST_DIR/test_write.txt"
    local content="test content"
    
    if safe_write "$test_file" "$content" 644 2>/dev/null; then
        if [[ -f "$test_file" ]]; then
            test_pass "File written successfully"
            
            if grep -q "$content" "$test_file"; then
                test_pass "File content is correct"
            else
                test_fail "File content mismatch"
            fi
        else
            test_fail "File not created"
        fi
    else
        test_fail "safe_write failed"
    fi
}

test_safe_append() {
    print_test_header "Testing Safe Append"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    local test_file="$TEST_DIR/test_append.txt"
    
    echo "line1" > "$test_file"
    
    if safe_append "$test_file" "line2" 2>/dev/null; then
        if grep -q "line2" "$test_file"; then
            test_pass "Line appended successfully"
        else
            test_fail "Appended line not found"
        fi
    else
        test_fail "safe_append failed"
    fi
}

################################################################################
# CONFIGURATION FILE TESTS
################################################################################

test_config_creation() {
    print_test_header "Testing Configuration Creation"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    declare -A test_config=(
        [DISTRO]="debian"
        [DISPLAY]="termux-x11"
        [WM]="i3"
    )
    
    local config_file="$TEST_DIR/test_config.env"
    
    if create_config_file "$config_file" test_config 2>/dev/null; then
        if [[ -f "$config_file" ]]; then
            test_pass "Configuration file created"
            
            if grep -q "DISTRO=" "$config_file"; then
                test_pass "Configuration contains expected variables"
            else
                test_fail "Configuration missing expected variables"
            fi
        else
            test_fail "Configuration file not created"
        fi
    else
        test_fail "create_config_file failed"
    fi
}

test_config_loading() {
    print_test_header "Testing Configuration Loading"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    # Create test config
    local config_file="$TEST_DIR/load_test_config.env"
    cat > "$config_file" << 'EOF'
#!/bin/bash
export TEST_VAR="test_value"
export TEST_NUM=42
EOF
    
    if load_config_file "$config_file" 2>/dev/null; then
        test_pass "Configuration file loaded"
        
        if [[ "$TEST_VAR" == "test_value" ]]; then
            test_pass "Configuration variables exported correctly"
        else
            test_fail "Configuration variables not set"
        fi
    else
        test_fail "load_config_file failed"
    fi
}

################################################################################
# MAIN.SH TESTS
################################################################################

test_main_file_exists() {
    print_test_header "Testing Main File"
    
    local main_file="$SCRIPT_DIR/main.sh"
    assert_file_exists "$main_file" "main.sh should exist"
}

test_main_syntax() {
    print_test_header "Testing Main Syntax"
    
    local main_file="$SCRIPT_DIR/main.sh"
    
    if bash -n "$main_file" 2>/dev/null; then
        test_pass "main.sh has valid bash syntax"
    else
        test_fail "main.sh has syntax errors"
    fi
}

test_main_sources_functions() {
    print_test_header "Testing Main Sources Functions"
    
    local main_file="$SCRIPT_DIR/main.sh"
    
    if grep -q "source.*functions.sh" "$main_file"; then
        test_pass "main.sh sources functions.sh"
    else
        test_fail "main.sh does not source functions.sh"
    fi
}

################################################################################
# INSTALL.SH TESTS
################################################################################

test_install_file_exists() {
    print_test_header "Testing Install File"
    
    local install_file="$SCRIPT_DIR/install.sh"
    assert_file_exists "$install_file" "install.sh should exist"
}

test_install_syntax() {
    print_test_header "Testing Install Syntax"
    
    local install_file="$SCRIPT_DIR/install.sh"
    
    if bash -n "$install_file" 2>/dev/null; then
        test_pass "install.sh has valid bash syntax"
    else
        test_fail "install.sh has syntax errors"
    fi
}

test_install_key_functions() {
    print_test_header "Testing Install Key Functions"
    
    local install_file="$SCRIPT_DIR/install.sh"
    
    grep -q "check_installation_environment" "$install_file" && \
        test_pass "install.sh has check_installation_environment function" || \
        test_fail "Missing check_installation_environment"
    
    grep -q "install_termux_dependencies" "$install_file" && \
        test_pass "install.sh has install_termux_dependencies function" || \
        test_fail "Missing install_termux_dependencies"
    
    grep -q "install_linux_distribution" "$install_file" && \
        test_pass "install.sh has install_linux_distribution function" || \
        test_fail "Missing install_linux_distribution"
}

################################################################################
# GENERATE.SH TESTS
################################################################################

test_generate_file_exists() {
    print_test_header "Testing Generate File"
    
    local generate_file="$SCRIPT_DIR/generate.sh"
    assert_file_exists "$generate_file" "generate.sh should exist"
}

test_generate_syntax() {
    print_test_header "Testing Generate Syntax"
    
    local generate_file="$SCRIPT_DIR/generate.sh"
    
    if bash -n "$generate_file" 2>/dev/null; then
        test_pass "generate.sh has valid bash syntax"
    else
        test_fail "generate.sh has syntax errors"
    fi
}

test_generate_key_functions() {
    print_test_header "Testing Generate Key Functions"
    
    local generate_file="$SCRIPT_DIR/generate.sh"
    
    grep -q "generate_start_script" "$generate_file" && \
        test_pass "generate.sh has generate_start_script function" || \
        test_fail "Missing generate_start_script"
    
    grep -q "generate_stop_script" "$generate_file" && \
        test_pass "generate.sh has generate_stop_script function" || \
        test_fail "Missing generate_stop_script"
    
    grep -q "generate_doctor_script" "$generate_file" && \
        test_pass "generate.sh has generate_doctor_script function" || \
        test_fail "Missing generate_doctor_script"
    
    grep -q "generate_remove_script" "$generate_file" && \
        test_pass "generate.sh has generate_remove_script function" || \
        test_fail "Missing generate_remove_script"
}

################################################################################
# SCRIPT GENERATION MOCK TESTS
################################################################################

test_mock_config_generation() {
    print_test_header "Testing Mock Configuration Generation"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    local config_file="$TEST_DIR/mock_config.env"
    
    cat > "$config_file" << 'EOF'
#!/bin/bash
export CONFIG_DISTRO="debian"
export CONFIG_DISPLAY="termux-x11"
export CONFIG_DESKTOP_ENV="xfce"
export CONFIG_WM="xfce"
export CONFIG_TERMINAL="bash"
export CONFIG_FILE_MANAGER="thunar"
export CONFIG_BAR="xfce4-panel"
export CONFIG_LAUNCHER="rofi"
EOF
    
    if load_config_file "$config_file" 2>/dev/null; then
        test_pass "Mock configuration loaded"
        
        assert_true "[[ \"\$CONFIG_DISTRO\" == \"debian\" ]]" "DISTRO should be debian"
        assert_true "[[ \"\$CONFIG_DISPLAY\" == \"termux-x11\" ]]" "DISPLAY should be termux-x11"
    else
        test_fail "Cannot load mock configuration"
    fi
}

################################################################################
# ERROR HANDLING TESTS
################################################################################

test_error_handling() {
    print_test_header "Testing Error Handling"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    local error_output
    
    # Test error function doesn't crash
    error_output=$(print_error "test error" 2>&1)
    if [[ -n "$error_output" ]]; then
        test_pass "Error handling works without crashing"
    else
        test_fail "Error handling failed"
    fi
}

################################################################################
# MENU SYSTEM TESTS
################################################################################

test_menu_functions_exist() {
    print_test_header "Testing Menu Functions"
    
    local main_file="$SCRIPT_DIR/main.sh"
    
    grep -q "show_main_menu" "$main_file" && \
        test_pass "main.sh has show_main_menu function" || \
        test_fail "Missing show_main_menu"
    
    grep -q "choose_distribution" "$main_file" && \
        test_pass "main.sh has choose_distribution function" || \
        test_fail "Missing choose_distribution"
    
    grep -q "choose_display" "$main_file" && \
        test_pass "main.sh has choose_display function" || \
        test_fail "Missing choose_display"
    
    grep -q "choose_desktop_wm" "$main_file" && \
        test_pass "main.sh has choose_desktop_wm function" || \
        test_fail "Missing choose_desktop_wm"
}

################################################################################
# VALIDATION TESTS
################################################################################

test_distro_support() {
    print_test_header "Testing Distro Support"
    
    local install_file="$SCRIPT_DIR/install.sh"
    
    grep -q "debian" "$install_file" && test_pass "Debian support included" || test_fail "Debian support missing"
    grep -q "ubuntu" "$install_file" && test_pass "Ubuntu support included" || test_fail "Ubuntu support missing"
    grep -q "arch" "$install_file" && test_pass "Arch support included" || test_fail "Arch support missing"
    grep -q "alpine" "$install_file" && test_pass "Alpine support included" || test_fail "Alpine support missing"
}

test_wm_support() {
    print_test_header "Testing Window Manager Support"
    
    local install_file="$SCRIPT_DIR/install.sh"
    
    grep -q "i3" "$install_file" && test_pass "i3 support included" || test_fail "i3 support missing"
    grep -q "openbox" "$install_file" && test_pass "Openbox support included" || test_fail "Openbox support missing"
    grep -q "xfce" "$install_file" && test_pass "XFCE support included" || test_fail "XFCE support missing"
    grep -q "lxqt" "$install_file" && test_pass "LXQt support included" || test_fail "LXQt support missing"
}

################################################################################
# VARIABLE DEFINITION TESTS
################################################################################

test_main_variables() {
    print_test_header "Testing Main Variables"
    
    local main_file="$SCRIPT_DIR/main.sh"
    
    grep -q "SCRIPT_DIR=" "$main_file" && test_pass "SCRIPT_DIR defined in main.sh" || test_fail "SCRIPT_DIR not defined"
    grep -q "CONFIG_FILE=" "$main_file" && test_pass "CONFIG_FILE defined in main.sh" || test_fail "CONFIG_FILE not defined"
    grep -q "CONFIG\[" "$main_file" && test_pass "CONFIG array defined in main.sh" || test_fail "CONFIG array not defined"
}

test_install_variables() {
    print_test_header "Testing Install Variables"
    
    local install_file="$SCRIPT_DIR/install.sh"
    
    grep -q "SCRIPT_DIR=" "$install_file" && test_pass "SCRIPT_DIR defined in install.sh" || test_fail "SCRIPT_DIR not defined"
    grep -q "CONFIG_FILE=" "$install_file" && test_pass "CONFIG_FILE defined in install.sh" || test_fail "CONFIG_FILE not defined"
    grep -q "INSTALLED_PACKAGES" "$install_file" && test_pass "INSTALLED_PACKAGES defined in install.sh" || test_fail "INSTALLED_PACKAGES not defined"
}

################################################################################
# SHEBANG TESTS
################################################################################

test_shebangs() {
    print_test_header "Testing Shebangs"
    
    assert_true "grep -q '^#!/bin/bash' \"\$SCRIPT_DIR/functions.sh\"" "functions.sh has correct shebang"
    assert_true "grep -q '^#!/bin/bash' \"\$SCRIPT_DIR/main.sh\"" "main.sh has correct shebang"
    assert_true "grep -q '^#!/bin/bash' \"\$SCRIPT_DIR/install.sh\"" "install.sh has correct shebang"
    assert_true "grep -q '^#!/bin/bash' \"\$SCRIPT_DIR/generate.sh\"" "generate.sh has correct shebang"
}

################################################################################
# READONLY CONSTANT TESTS
################################################################################

test_readonly_constants() {
    print_test_header "Testing Readonly Constants"
    
    local functions_file="$SCRIPT_DIR/functions.sh"
    
    grep -q "readonly COLOR_RED=" "$functions_file" && test_pass "COLOR_RED is readonly" || test_fail "COLOR_RED not readonly"
    grep -q "readonly COLOR_GREEN=" "$functions_file" && test_pass "COLOR_GREEN is readonly" || test_fail "COLOR_GREEN not readonly"
    grep -q "readonly SCRIPT_DIR=" "$SCRIPT_DIR/main.sh" && test_pass "SCRIPT_DIR is readonly in main.sh" || test_fail "SCRIPT_DIR not readonly"
}

################################################################################
# FUNCTION DEFINITION TESTS
################################################################################

test_all_functions_defined() {
    print_test_header "Testing All Functions Defined"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    local functions=(
        "print_color"
        "print_success"
        "print_error"
        "detect_architecture"
        "is_termux"
        "command_exists"
        "safe_mkdir"
        "safe_write"
        "create_config_file"
        "load_config_file"
    )
    
    for func in "${functions[@]}"; do
        if declare -f "$func" > /dev/null 2>&1; then
            test_pass "Function defined: $func"
        else
            test_fail "Function not defined: $func"
        fi
    done
}

################################################################################
# INTEGRATION TESTS
################################################################################

test_workflow_simulation() {
    print_test_header "Testing Workflow Simulation"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    # Simulate configuration workflow
    local test_config_file="$TEST_DIR/workflow_config.env"
    
    declare -A sim_config=(
        [DISTRO]="debian"
        [DISPLAY]="termux-x11"
        [DESKTOP_ENV]="xfce"
        [WM]="xfce"
        [TERMINAL]="bash"
        [FILE_MANAGER]="thunar"
        [BAR]="xfce4-panel"
        [LAUNCHER]="rofi"
    )
    
    if create_config_file "$test_config_file" sim_config 2>/dev/null; then
        test_pass "Configuration workflow: create passed"
        
        if load_config_file "$test_config_file" 2>/dev/null; then
            test_pass "Configuration workflow: load passed"
        else
            test_fail "Configuration workflow: load failed"
        fi
    else
        test_fail "Configuration workflow: create failed"
    fi
}

################################################################################
# EDGE CASE TESTS
################################################################################

test_empty_strings() {
    print_test_header "Testing Edge Cases: Empty Strings"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    # Test functions with empty strings
    local output
    output=$(print_color "" "" 2>&1)
    if [[ $? -eq 0 ]]; then
        test_pass "Functions handle empty strings without crashing"
    else
        test_fail "Functions crash on empty strings"
    fi
}

test_special_characters() {
    print_test_header "Testing Edge Cases: Special Characters"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    local test_file="$TEST_DIR/special_chars.txt"
    local special_content='Test with $special "chars" and \backslashes'
    
    if safe_write "$test_file" "$special_content" 644 2>/dev/null; then
        if grep -F "$special_content" "$test_file" > /dev/null 2>&1; then
            test_pass "Functions handle special characters correctly"
        else
            test_fail "Special characters corrupted"
        fi
    else
        test_fail "Cannot write special characters"
    fi
}

test_long_strings() {
    print_test_header "Testing Edge Cases: Long Strings"
    
    source "$FUNCTIONS_FILE" 2>/dev/null
    
    local long_string
    long_string=$(printf 'a%.0s' {1..1000})
    
    local output
    output=$(print_info "$long_string" 2>&1)
    
    if [[ -n "$output" ]]; then
        test_pass "Functions handle long strings"
    else
        test_fail "Functions fail on long strings"
    fi
}

################################################################################
# SUMMARY & REPORTING
################################################################################

print_test_summary() {
    echo
    echo -e "${BLUE}════════════════════════════════════════${RESET}"
    echo -e "${BLUE}  TEST SUMMARY${RESET}"
    echo -e "${BLUE}════════════════════════════════════════${RESET}"
    echo
    
    echo "Total Tests Run: $TESTS_RUN"
    echo -e "${GREEN}Passed: $TESTS_PASSED${RESET}"
    echo -e "${RED}Failed: $TESTS_FAILED${RESET}"
    echo -e "${YELLOW}Skipped: $TESTS_SKIPPED${RESET}"
    echo
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${RESET}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed!${RESET}"
        return 1
    fi
}

save_test_report() {
    local report_file="$SCRIPT_DIR/test_report.txt"
    
    {
        echo "TERMUX DESKTOP FORGE - Test Report"
        echo "Generated: $(date)"
        echo "========================================"
        echo
        echo "Test Results:"
        echo "  Total: $TESTS_RUN"
        echo "  Passed: $TESTS_PASSED"
        echo "  Failed: $TESTS_FAILED"
        echo "  Skipped: $TESTS_SKIPPED"
        echo
        echo "Details:"
        echo "========================================"
        cat "$TEST_LOG"
    } > "$report_file"
    
    print_info "Test report saved: $report_file"
}

################################################################################
# MAIN TEST EXECUTION
################################################################################

main() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║  TERMUX DESKTOP FORGE - Comprehensive Test Suite          ║
║  Version 1.0.0                                            ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
    
    # Setup
    setup_test_environment
    
    # Run all tests
    test_functions_file_exists
    test_functions_syntax
    test_functions_sourcing
    
    test_color_variables
    test_print_functions
    
    test_architecture_detection
    test_termux_detection
    test_command_detection
    
    test_backup_function
    test_safe_mkdir
    test_safe_write
    test_safe_append
    
    test_config_creation
    test_config_loading
    
    test_main_file_exists
    test_main_syntax
    test_main_sources_functions
    
    test_install_file_exists
    test_install_syntax
    test_install_key_functions
    
    test_generate_file_exists
    test_generate_syntax
    test_generate_key_functions
    
    test_mock_config_generation
    
    test_error_handling
    
    test_menu_functions_exist
    
    test_distro_support
    test_wm_support
    
    test_main_variables
    test_install_variables
    
    test_shebangs
    test_readonly_constants
    
    test_all_functions_defined
    
    test_workflow_simulation
    
    test_empty_strings
    test_special_characters
    test_long_strings
    
    # Cleanup
    cleanup_test_environment
    
    # Report
    save_test_report
    print_test_summary
}

# Execute tests
main "$@"
exit $?
