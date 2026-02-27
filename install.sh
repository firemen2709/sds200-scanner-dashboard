#!/bin/bash
# SDS200 Scanner Dashboard - Complete Installation Script
# This script installs and configures everything needed to run the dashboard

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check Python version
check_python() {
    print_header "Checking Python Installation"
    
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is required but not installed"
        echo "Install Python 3 with:"
        echo "  Ubuntu/Debian: sudo apt-get install python3"
        echo "  RHEL/CentOS: sudo yum install python3"
        echo "  macOS: brew install python3"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    print_success "Python 3 found: $PYTHON_VERSION"
}

# Get script directory
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd
}

# Make scripts executable
make_executable() {
    print_header "Making Scripts Executable"
    
    SCRIPT_DIR=$(get_script_dir)
    
    chmod +x "$SCRIPT_DIR/sds200_scanner.py" 2>/dev/null && print_success "sds200_scanner.py is executable"
    chmod +x "$SCRIPT_DIR/start_dashboard.sh" 2>/dev/null && print_success "start_dashboard.sh is executable"
    chmod +x "$SCRIPT_DIR/stop_dashboard.sh" 2>/dev/null && print_success "stop_dashboard.sh is executable"
}

# Create systemd service
create_systemd_service() {
    print_header "Creating Systemd Service"
    
    SCRIPT_DIR=$(get_script_dir)
    SERVICE_FILE="$SCRIPT_DIR/sds200-scanner.service"
    
    cat > "$SERVICE_FILE" <<'EOFSERVICE'
[Unit]
Description=SDS200 Scanner Dashboard
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$SCRIPT_DIR
ExecStart=$SCRIPT_DIR/start_dashboard.sh
ExecStop=$SCRIPT_DIR/stop_dashboard.sh
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOFSERVICE
    
    chmod 644 "$SERVICE_FILE"
    print_success "Systemd service created: $SERVICE_FILE"
}

# Check for common issues
check_system() {
    print_header "System Configuration Check"
    
    # Check if port 8000 is available
    if command -v lsof &> /dev/null; then
        if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
            print_error "Port 8000 is already in use"
            print_info "You can use a different port when starting: python3 -m http.server 8080"
        else
            print_success "Port 8000 is available"
        fi
    else
        print_info "lsof not found - skipping port check"
    fi
    
    # Check if scanner is reachable
    SCANNER_IP="192.168.2.251"
    print_info "Checking scanner connectivity to $SCANNER_IP..."
    if ping -c 1 -W 1 "$SCANNER_IP" &> /dev/null; then
        print_success "Scanner at $SCANNER_IP is reachable"
    else
        print_error "Scanner at $SCANNER_IP is not reachable"
        echo "  - Verify scanner IP address in config.sh"
        echo "  - Ensure scanner is powered on and connected to network"
        echo "  - Check your network connection"
    fi
}

# Create configuration file
create_config() {
    print_header "Creating Configuration File"
    
    SCRIPT_DIR=$(get_script_dir)
    CONFIG_FILE="$SCRIPT_DIR/config.sh"
    
    cat > "$CONFIG_FILE" <<'EOFCONFIG'
#!/bin/bash
# SDS200 Scanner Dashboard Configuration
# Edit these values to customize the dashboard

# Scanner Network Settings
export SCANNER_IP="192.168.2.251"
export SCANNER_PORT="10001"
export SOCKET_TIMEOUT="5"

# Web Server Settings
export WEB_PORT="8000"
export WEB_HOST="0.0.0.0"

# Data Storage
export DATA_FILE="/tmp/sds200_data.json"
export LOG_FILE="/tmp/sds200_scanner.log"

# Update Interval (seconds)
export UPDATE_INTERVAL="1"
EOFCONFIG
    
    chmod 644 "$CONFIG_FILE"
    print_success "Configuration file created: $CONFIG_FILE"
}

# Display setup summary
show_summary() {
    print_header "Installation Complete!"
    
    SCRIPT_DIR=$(get_script_dir)
    
    echo "✓ SDS200 Scanner Dashboard is ready to use!"
    echo ""
    echo "Project Directory: $SCRIPT_DIR"
    echo ""
    echo "════════════════════════════════════════���══════════════════"
    echo "QUICK START:"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "1. (Optional) Configure scanner IP:"
    echo "   nano config.sh"
    echo ""
    echo "2. Start the dashboard:"
    echo "   ./start_dashboard.sh"
    echo ""
    echo "3. Open in browser:"
    echo "   http://localhost:8000"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "USEFUL COMMANDS:"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "View backend log:"
    echo "   tail -f /tmp/sds200_scanner.log"
    echo ""
    echo "View live data:"
    echo "   watch -n 1 cat /tmp/sds200_data.json"
    echo ""
    echo "Stop dashboard:"
    echo "   ./stop_dashboard.sh"
    echo ""
    echo "Check process:"
    echo "   ps aux | grep sds200"
    echo ""
}

# Main installation flow
main() {
    print_header "SDS200 Scanner Dashboard - Installation"
    
    echo "Setting up SDS200 Scanner Dashboard..."
    echo ""
    
    # Run checks and setup
    check_python
    make_executable
    create_systemd_service
    create_config
    check_system
    show_summary
}

# Run main function
main

exit 0