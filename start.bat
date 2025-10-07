@echo off
chcp 65001 >nul
echo ========================================
echo ZViewer Startup Script
echo ========================================
echo.

echo [1/4] Cleaning up existing processes...
taskkill /F /IM main.exe >nul 2>&1
taskkill /F /IM dart.exe >nul 2>&1
echo Cleanup completed.
echo.

echo [2/4] Checking Docker...
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker not running - starting...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    echo Waiting 30 seconds...
    timeout /t 30 /nobreak >nul
)

echo Starting Docker services...
cd /d "%~dp0server"
docker-compose -f docker-compose.infrastructure.yml up -d
echo Docker services started.
echo.

echo [3/4] Waiting for services to be ready...
timeout /t 15 /nobreak >nul
echo.

echo [4/4] Starting Go microservices...
echo Starting Main API Service (Port 8080)...
cd /d "%~dp0server"
start "Main API" cmd /k "cd /d %~dp0server && set DATABASE_URL=postgres://zviewer:zviewer123@localhost:5432/zviewer?sslmode=disable&& go run cmd/api/main.go"

echo Starting Media Service (Port 8081)...
cd /d "%~dp0server\services\media"
start "Media Service" cmd /k "cd /d %~dp0server\services\media && set DATABASE_URL=postgres://zviewer:zviewer123@localhost:5432/zviewer?sslmode=disable&& go run cmd/api/main.go"

echo Waiting for Go services to start...
timeout /t 5 /nobreak >nul
echo.

echo [5/5] Starting Flutter application...
echo Starting Flutter app in new window...
cd /d "%~dp0application"
start "Flutter App" cmd /k "cd /d %~dp0application && flutter run -d windows"

echo.
echo ========================================
echo ZViewer Startup Completed!
echo ========================================
echo.
echo Services started:
echo   - Docker infrastructure (PostgreSQL, Redis, Kong, Consul)
echo   - Main API Service (Port 8080)
echo   - Media Service (Port 8081)
echo   - Flutter Application
echo.
echo Access URLs:
echo   - Kong Gateway: http://localhost:8002
echo   - Kong Admin: http://localhost:8003
echo   - Main API: http://localhost:8080
echo   - Media Service: http://localhost:8081
echo.
echo The Flutter application should open in a new window.
echo If you don't see it, check the Flutter console window.
echo.
pause
