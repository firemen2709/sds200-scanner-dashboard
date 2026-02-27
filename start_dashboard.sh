#!/bin/bash
# Start SDS200 Scanner Dashboard

# Set script directory
SCRIPT_DIR="$(cd ""$(dirname ""){BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/sds200_scanner.py"
WEB_DIR="$SCRIPT_DIR"
LOG_FILE="/tmp/sds200_dashboard.log"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting SDS200 Scanner Dashboard...${NC}"

# Make Python script executable
chmod +x "$PYTHON_SCRIPT"

# Start Python backend in background
echo -e "${BLUE}Starting Python backend...${NC}"
nohup python3 "$PYTHON_SCRIPT" > "$LOG_FILE" 2>&1 &
PYTHON_PID=$!
echo -e "${GREEN}Python backend PID: $PYTHON_PID${NC}"

# Start simple HTTP server
echo -e "${BLUE}Starting web server on http://localhost:8000${NC}"
cd "$WEB_DIR"
python3 -m http.server 8000 > /dev/null 2>&1 &
WEB_PID=$!
echo -e "${GREEN}Web server PID: $WEB_PID${NC}"

# Save PIDs to file for easy stopping
echo "$PYTHON_PID" > /tmp/sds200_python.pid
echo "$WEB_PID" > /tmp/sds200_web.pid

echo ""
echo -e "${GREEN}✓ Dashboard started successfully!${NC}" 
echo ""
echo "Access the dashboard at: http://localhost:8000"
echo ""
echo "Logs:"
echo "  Backend: $LOG_FILE"
echo "  Data: /tmp/sds200_data.json"
echo ""
echo "To stop the dashboard, run: ./stop_dashboard.sh"