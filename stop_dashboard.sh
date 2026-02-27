#!/bin/bash
# Stop SDS200 Scanner Dashboard
echo "Stopping SDS200 Scanner Dashboard..."

# Kill Python backend
if [ -f /tmp/sds200_python.pid ]; then
    PID=$(cat /tmp/sds200_python.pid)
    if ps -p $PID > /dev/null; then
        kill $PID
        echo "✓ Stopped Python backend (PID: $PID)"
    fi
    rm /tmp/sds200_python.pid
fi

# Kill web server
if [ -f /tmp/sds200_web.pid ]; then
    PID=$(cat /tmp/sds200_web.pid)
    if ps -p $PID > /dev/null; then
        kill $PID
        echo "✓ Stopped Web server (PID: $PID)"
    fi
    rm /tmp/sds200_web.pid
fi

echo "✓ Dashboard stopped"