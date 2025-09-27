@echo off
chcp 65001 >nul
echo ZViewer Simple Start Script
echo ==========================

echo Checking Docker status...
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Docker is not running, please start Docker first
    pause
    exit /b 1
)

echo Starting only essential services...
echo This will start PostgreSQL and Redis only

REM Start only database services
docker-compose -f docker-compose.dev.yml up -d postgres redis

echo Waiting for database to start...
timeout /t 10 /nobreak >nul

echo Checking service status...
docker-compose -f docker-compose.dev.yml ps

echo.
echo Essential services started!
echo.
echo Database: localhost:5432
echo Redis: localhost:6379
echo.
echo To start all services, run: start.bat
echo To stop services, run: docker-compose -f docker-compose.dev.yml down
echo.
pause
