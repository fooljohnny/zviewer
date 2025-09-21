#!/bin/bash
# ZViewer Startup Script for Unix-like systems
# This script provides an easy way to start both the Flutter client and Go server

echo ""
echo "========================================"
echo "    ZViewer Startup Script"
echo "========================================"
echo ""

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    if ! command -v python &> /dev/null; then
        echo "Error: Python is not installed or not in PATH"
        echo "Please install Python 3.6+ and try again"
        exit 1
    else
        PYTHON_CMD="python"
    fi
else
    PYTHON_CMD="python3"
fi

# Make the script executable
chmod +x "$0"

# Run the Python startup script
$PYTHON_CMD start.py "$@"
