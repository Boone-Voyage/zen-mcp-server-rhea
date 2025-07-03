#!/bin/bash
set -euo pipefail

# ============================================================================
# Zen MCP Server Status Check Script
# 
# Checks the status of the Zen MCP server environment and processes
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

echo "🔍 Zen MCP Server Status Check"
echo "=============================="
echo ""

# Check version
if [ -f version.txt ]; then
    VERSION=$(cat version.txt)
    print_info "Version: $VERSION"
else
    print_warning "Version file not found"
fi
echo ""

# Check environment setup
echo "Environment Status:"
echo "-------------------"

# Check virtual environment
if [ -d ".zen_venv" ]; then
    print_success "Virtual environment exists"
    if [ -f ".zen_venv/bin/python" ]; then
        PYTHON_VERSION=$(.zen_venv/bin/python --version 2>&1)
        print_info "Python: $PYTHON_VERSION"
    fi
else
    print_error "Virtual environment not found - run ./run-server.sh to set up"
fi

# Check .env file
if [ -f ".env" ]; then
    print_success ".env file exists"
    # Count configured API keys
    KEY_COUNT=0
    for key in GEMINI_API_KEY OPENAI_API_KEY XAI_API_KEY DIAL_API_KEY OPENROUTER_API_KEY; do
        if grep -q "^$key=..*" .env 2>/dev/null; then
            ((KEY_COUNT++))
            print_success "$key configured"
        fi
    done
    if [ $KEY_COUNT -eq 0 ]; then
        print_error "No API keys configured in .env"
    fi
else
    print_error ".env file not found - run ./run-server.sh to create"
fi

echo ""

# Check server processes
echo "Server Process Status:"
echo "---------------------"

# Look for python processes running server.py from our directory
PIDS=$(ps aux | grep -E "python.*${SCRIPT_DIR}/server.py" | grep -v grep | awk '{print $2}' || true)

if [ -z "$PIDS" ]; then
    print_warning "No Zen MCP server processes running"
else
    COUNT=$(echo "$PIDS" | wc -l | tr -d ' ')
    if [ "$COUNT" -eq 1 ]; then
        print_success "1 server process running"
    else
        print_warning "$COUNT server processes running (expected 1)"
    fi
    
    for PID in $PIDS; do
        PROCESS_INFO=$(ps -p "$PID" -o pid,etime,command 2>/dev/null | grep -v PID || true)
        if [ -n "$PROCESS_INFO" ]; then
            ETIME=$(echo "$PROCESS_INFO" | awk '{print $2}')
            print_info "  PID $PID - Running for $ETIME"
        fi
    done
fi

echo ""

# Check logs
echo "Log Status:"
echo "-----------"

if [ -d "logs" ]; then
    print_success "Logs directory exists"
    
    # Check main server log
    if [ -f "logs/mcp_server.log" ]; then
        LOG_SIZE=$(ls -lh logs/mcp_server.log | awk '{print $5}')
        LOG_LINES=$(wc -l < logs/mcp_server.log | tr -d ' ')
        print_info "Server log: $LOG_SIZE ($LOG_LINES lines)"
        
        # Check for recent errors
        RECENT_ERRORS=$(tail -n 100 logs/mcp_server.log | grep -c "ERROR" || true)
        if [ "$RECENT_ERRORS" -gt 0 ]; then
            print_warning "Found $RECENT_ERRORS errors in last 100 log lines"
        else
            print_success "No recent errors in server log"
        fi
    else
        print_warning "Server log not found"
    fi
    
    # Check activity log
    if [ -f "logs/mcp_activity.log" ]; then
        ACT_SIZE=$(ls -lh logs/mcp_activity.log | awk '{print $5}')
        ACT_LINES=$(wc -l < logs/mcp_activity.log | tr -d ' ')
        print_info "Activity log: $ACT_SIZE ($ACT_LINES lines)"
    fi
else
    print_error "Logs directory not found"
fi

echo ""

# Check dependencies
echo "Dependencies Status:"
echo "-------------------"

if [ -f "requirements.txt" ] && [ -d ".zen_venv" ]; then
    # Quick check for key packages
    for package in mcp httpx google-genai openai; do
        if .zen_venv/bin/pip show "$package" &>/dev/null; then
            print_success "$package installed"
        else
            print_error "$package not installed"
        fi
    done
else
    print_warning "Cannot check dependencies - environment not set up"
fi

echo ""

# Check Claude configuration
echo "Claude Configuration:"
echo "--------------------"

CONFIG_FILE="$HOME/.config/claude/claude_desktop_config.json"
if [ -f "$CONFIG_FILE" ]; then
    if grep -q "zen-server" "$CONFIG_FILE" 2>/dev/null; then
        print_success "Zen server configured in Claude"
    else
        print_warning "Zen server not found in Claude config"
        print_info "Run './run-server.sh -c' for configuration instructions"
    fi
else
    print_warning "Claude config file not found"
    print_info "Run './run-server.sh -c' for configuration instructions"
fi

echo ""
echo "Status check complete!"
echo ""
echo "Quick actions:"
echo "  ./run-server.sh      - Set up environment"
echo "  ./run-server.sh -f   - Follow server logs"
echo "  ./stop-server.sh     - Stop server processes"
echo "  ./test-server.sh     - Run comprehensive tests"