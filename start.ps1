# ZViewer Startup Script for PowerShell
# This script provides an easy way to start both the Flutter client and Go server

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    ZViewer Startup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Python is available
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Python not found"
    }
    Write-Host "✅ Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: Python is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Python 3.6+ and try again" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Run the Python startup script with all arguments
Write-Host "🚀 Starting ZViewer..." -ForegroundColor Green
python start.py $args

Read-Host "Press Enter to exit"
