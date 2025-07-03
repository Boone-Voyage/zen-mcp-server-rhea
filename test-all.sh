#!/bin/bash
set -euo pipefail

# ============================================================================
# Zen MCP Server Complete Test Suite
# 
# Runs all management scripts in sequence to verify everything is working
# ============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

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

print_header() {
    echo ""
    echo -e "${BOLD}$1${NC}"
    echo "$(echo "$1" | sed 's/./=/g')"
}

# Main test execution
echo -e "${BOLD}🚀 Zen MCP Server Complete Test Suite${NC}"
echo "====================================="
echo ""
print_info "This will run all management scripts in sequence"
print_info "Press Ctrl+C at any time to stop"
echo ""

# Track overall success
ALL_PASSED=true

# Function to run a script and check result
run_script() {
    local script="$1"
    local description="$2"
    
    print_header "Running $script - $description"
    
    if ./"$script"; then
        print_success "$script completed successfully"
    else
        print_error "$script failed with exit code $?"
        ALL_PASSED=false
        return 1
    fi
    
    # Brief pause between scripts for readability
    sleep 1
    return 0
}

# Store start time
START_TIME=$(date +%s)

# Run all scripts in sequence
echo -e "${BOLD}Starting test sequence...${NC}"
echo ""

# 1. Setup environment
if ! run_script "run-server.sh" "Environment Setup"; then
    print_error "Environment setup failed - stopping test sequence"
    exit 1
fi

# 2. Initial status check
run_script "check-server.sh" "Initial Status Check"

# 3. Run comprehensive tests
if ! run_script "test-server.sh" "Comprehensive Test Suite"; then
    print_warning "Some tests failed - continuing with sequence"
fi

# 4. Test shutdown functionality
run_script "stop-server.sh" "Server Shutdown Test"

# 5. Final status verification
run_script "check-server.sh" "Final Status Verification"

# Calculate elapsed time
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

# Final summary
echo ""
echo "========================================"
echo -e "${BOLD}Test Suite Summary${NC}"
echo "========================================"
echo "Total execution time: ${ELAPSED} seconds"
echo ""

if [ "$ALL_PASSED" = true ]; then
    print_success "All scripts executed successfully! 🎉"
    echo ""
    echo "Your Zen MCP Server environment is:"
    echo "  ✓ Properly configured"
    echo "  ✓ All dependencies installed"
    echo "  ✓ All tests passing"
    echo "  ✓ Ready to use"
    echo ""
    print_info "Start Claude and the Zen server will be available"
    exit 0
else
    print_error "Some scripts encountered errors"
    echo ""
    echo "Please check the output above for details and:"
    echo "  1. Fix any configuration issues"
    echo "  2. Run ./test-all.sh again"
    echo ""
    print_info "For help, check the README or run ./run-server.sh --help"
    exit 1
fi