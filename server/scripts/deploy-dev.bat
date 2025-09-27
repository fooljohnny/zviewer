@echo off
chcp 65001 >nul
echo Starting ZViewer Development Environment...

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Docker is not running, please start Docker first
    exit /b 1
)

REM Build images
echo Building Docker images...
docker-compose -f docker-compose.dev.yml build

REM Start services
echo Starting services...
docker-compose -f docker-compose.dev.yml up -d

REM Wait for services to start
echo Waiting for services to start...
timeout /t 30 /nobreak >nul

REM Check service status
echo Checking service status...
docker-compose -f docker-compose.dev.yml ps

REM Run health check
echo Running health check...
if exist "scripts\health-check.bat" (
    call scripts\health-check.bat
) else (
    echo Warning: Health check script not found
)

echo Development environment started successfully!
echo.
echo API Gateway (Kong): http://localhost:8000
echo Kong Admin UI: http://localhost:8002
echo Consul UI: http://localhost:8500
echo.
echo Monitoring Dashboard:
echo   Grafana: http://localhost:3000 (admin/admin123)
echo   Prometheus: http://localhost:9090
echo   Kibana: http://localhost:5601
echo.
echo Direct Service Access:
echo   Main Server: http://localhost:8080
echo   Media Service: http://localhost:8081
echo   Comments Service: http://localhost:8082
echo   Payments Service: http://localhost:8083
echo   Admin Service: http://localhost:8084
