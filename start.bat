@echo off
REM ZViewer Startup Script for Windows
REM This script provides an easy way to start both the Flutter client and Go server

echo.
echo ========================================
echo    ZViewer Startup Script
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

REM Run the Python startup script
python start.py %*

pause
