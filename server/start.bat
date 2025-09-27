@echo off
chcp 65001 >nul
echo ZViewer Microservices Quick Start Script
echo ========================================

echo Detected Windows system, starting development environment...
if exist "scripts\deploy-dev.bat" (
    call scripts\deploy-dev.bat
) else (
    echo Error: Windows deployment script not found
    exit /b 1
)
