#!/bin/bash
set -euo pipefail

# ============================================================================
# Zen MCP Server Stop Script
# 
# Finds and stops any running Zen MCP server processes
# ============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Colors for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
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

# Find server processes
echo "🛑 Zen MCP Server Shutdown"
echo "=========================="
echo ""

# Look for python processes running server.py from our directory
PIDS=$(ps aux | grep -E "python.*${SCRIPT_DIR}/server.py" | grep -v grep | awk '{print $2}' || true)

if [ -z "$PIDS" ]; then
    print_warning "No Zen MCP server processes found running"
    echo ""
    echo "To start the server, run: ./run-server.sh"
    exit 0
fi

# Count how many processes we found
COUNT=$(echo "$PIDS" | wc -l | tr -d ' ')

if [ "$COUNT" -eq 1 ]; then
    echo "Found 1 Zen MCP server process:"
else
    echo "Found $COUNT Zen MCP server processes:"
fi

# Show process details
for PID in $PIDS; do
    PROCESS_INFO=$(ps -p "$PID" -o pid,etime,command 2>/dev/null | grep -v PID || true)
    if [ -n "$PROCESS_INFO" ]; then
        echo "  PID $PID - Running for $(echo "$PROCESS_INFO" | awk '{print $2}')"
    fi
done

echo ""

# Kill the processes
echo "Stopping server processes..."
for PID in $PIDS; do
    if kill "$PID" 2>/dev/null; then
        print_success "Stopped process $PID"
    else
        print_error "Failed to stop process $PID (may have already exited)"
    fi
done

echo ""
print_success "Server shutdown complete"
echo ""
echo "To restart the server, run: ./run-server.sh"