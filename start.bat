@echo off
REM ZViewer Complete Startup Script for Windows
REM This script starts all microservices and the Flutter client

echo.
echo ========================================
echo    ZViewer Complete Startup
echo ========================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python 3.6+ and try again
    pause
    exit /b 1
)

REM Run the Python startup script with all services
echo Starting ZViewer with all microservices...
python start.py --all-services

pause
