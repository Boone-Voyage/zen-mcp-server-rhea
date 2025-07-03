#!/bin/bash
set -euo pipefail

# ============================================================================
# Zen MCP Server Test Suite
# 
# Runs comprehensive tests on the Zen MCP server setup and functionality
# ============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Print colored output
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Test functions
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TESTS_RUN++))
    echo -n "Testing $test_name... "
    
    if eval "$test_command" &>/dev/null; then
        print_success "PASSED"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "FAILED"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "🧪 Zen MCP Server Test Suite"
echo "============================"
echo ""

# Test 1: Script directory detection
echo "1. Environment Tests"
echo "-------------------"

run_test "Script directory detection" "[ -d '$SCRIPT_DIR' ]"
run_test "Working directory change" "[ '$PWD' = '$SCRIPT_DIR' ]"

# Test 2: File existence
run_test "run-server.sh exists" "[ -f 'run-server.sh' ]"
run_test "stop-server.sh exists" "[ -f 'stop-server.sh' ]"
run_test "check-server.sh exists" "[ -f 'check-server.sh' ]"
run_test "server.py exists" "[ -f 'server.py' ]"
run_test "requirements.txt exists" "[ -f 'requirements.txt' ]"

echo ""
echo "2. Setup Script Tests"
echo "--------------------"

# Test run-server.sh functionality
run_test "run-server.sh is executable" "[ -x 'run-server.sh' ]"
run_test "run-server.sh help" "bash -c './run-server.sh --help 2>&1 | grep -q Usage'"
run_test "run-server.sh version" "bash -c './run-server.sh --version 2>&1 | grep -qE \"[0-9]+\\.[0-9]+\"'"

# Test virtual environment
if [ -d ".zen_venv" ]; then
    run_test "Virtual environment exists" "[ -d '.zen_venv' ]"
    run_test "Python executable exists" "[ -f '.zen_venv/bin/python' ]"
    run_test "pip exists" "[ -f '.zen_venv/bin/pip' ]"
else
    print_warning "Virtual environment not set up - run ./run-server.sh first"
fi

echo ""
echo "3. Configuration Tests"
echo "---------------------"

# Test .env file
if [ -f ".env" ]; then
    run_test ".env file exists" "[ -f '.env' ]"
    run_test ".env has content" "[ -s '.env' ]"
    
    # Check for at least one API key
    if grep -qE "^(GEMINI_API_KEY|OPENAI_API_KEY|XAI_API_KEY|DIAL_API_KEY|OPENROUTER_API_KEY)=.+" .env 2>/dev/null; then
        run_test "At least one API key configured" "true"
    else
        run_test "At least one API key configured" "false"
    fi
else
    run_test ".env file exists" "false"
fi

# Test logs directory
run_test "Logs directory exists" "[ -d 'logs' ]"
if [ -d "logs" ]; then
    run_test "Logs directory is writable" "[ -w 'logs' ]"
fi

echo ""
echo "4. Server Control Tests"
echo "----------------------"

# Test stop-server.sh
run_test "stop-server.sh is executable" "[ -x 'stop-server.sh' ]"
run_test "stop-server.sh runs without error" "./stop-server.sh"

# Test check-server.sh
run_test "check-server.sh is executable" "[ -x 'check-server.sh' ]"

echo ""
echo "5. Python Environment Tests"
echo "--------------------------"

if [ -f ".zen_venv/bin/python" ]; then
    # Test Python version
    PYTHON_VERSION=$(.zen_venv/bin/python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    run_test "Python 3.9+" "python -c \"import sys; exit(0 if sys.version_info >= (3, 9) else 1)\""
    
    # Test critical imports
    run_test "Can import mcp module" ".zen_venv/bin/python -c 'import mcp'"
    run_test "Can import httpx module" ".zen_venv/bin/python -c 'import httpx'"
    run_test "Can import asyncio module" ".zen_venv/bin/python -c 'import asyncio'"
    
    # Test server.py syntax
    run_test "server.py syntax check" ".zen_venv/bin/python -m py_compile server.py"
fi

echo ""
echo "6. Integration Tests"
echo "-------------------"

# Test that server can be imported
if [ -f ".zen_venv/bin/python" ] && [ -f "server.py" ]; then
    run_test "Server imports successfully" ".zen_venv/bin/python -c 'import server'"
fi

# Test code quality if tools are available
if [ -f ".zen_venv/bin/ruff" ]; then
    echo ""
    echo "7. Code Quality Tests"
    echo "--------------------"
    run_test "Ruff linting" ".zen_venv/bin/ruff check . --quiet"
fi

# Summary
echo ""
echo "========================================"
echo "Test Summary"
echo "========================================"
echo "Total tests run: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
else
    echo -e "${GREEN}Failed: 0${NC}"
fi
echo ""

# Calculate pass rate
if [ $TESTS_RUN -gt 0 ]; then
    PASS_RATE=$(( TESTS_PASSED * 100 / TESTS_RUN ))
    echo "Pass rate: $PASS_RATE%"
    echo ""
fi

# Exit code based on failures
if [ $TESTS_FAILED -eq 0 ]; then
    print_success "All tests passed! 🎉"
    
    # Run quick simulator test if all basic tests pass
    if [ -f "communication_simulator_test.py" ] && [ -f ".zen_venv/bin/python" ]; then
        echo ""
        print_info "Run './run_integration_tests.sh --quick' for quick integration tests"
        print_info "Run 'python communication_simulator_test.py --quick' for quick simulator tests"
    fi
    
    exit 0
else
    print_error "Some tests failed. Run './run-server.sh' to fix setup issues."
    exit 1
fi