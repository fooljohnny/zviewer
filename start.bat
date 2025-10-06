@echo off
echo ========================================
echo ZViewer Startup Script (Final)
echo ========================================
echo.

REM Step 1: Clean up existing processes
echo [1/4] Cleaning up existing processes...
taskkill /F /IM main.exe >nul 2>&1
taskkill /F /IM dart.exe >nul 2>&1
echo Cleanup completed.
echo.

REM Step 2: Start Docker services
echo [2/4] Starting Docker infrastructure...
cd /d "%~dp0server"
docker-compose -f docker-compose.infrastructure.yml up -d
if errorlevel 1 (
    echo ERROR: Failed to start Docker services
    echo Please ensure Docker Desktop is running
    pause
    exit /b 1
)
echo Docker services started.
echo.

REM Step 3: Wait for Docker services to be ready
echo [3/4] Waiting for services to be ready...
timeout /t 10 /nobreak >nul
echo.

REM Step 4: Start Go services
echo [4/4] Starting Go microservices...
echo Starting Main API Service (Port 8080)...
cd /d "%~dp0server"
start "" cmd /k "cd /d %~dp0server & set DATABASE_URL=postgres://zviewer:zviewer123@localhost:5432/zviewer?sslmode=disable& go run cmd/api/main.go"

echo Starting Media Service (Port 8081)...
cd /d "%~dp0server\services\media"
start "" cmd /k "cd /d %~dp0server\services\media & set DATABASE_URL=postgres://zviewer:zviewer123@localhost:5432/zviewer?sslmode=disable& go run cmd/api/main.go"

echo Waiting for Go services to start...
timeout /t 5 /nobreak >nul
echo.

REM Step 5: Start Flutter application (simplified)
echo [5/5] Starting Flutter application...
echo Starting Flutter app in new window...
start "" cmd /k "cd /d %~dp0application & flutter run -d windows"

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
