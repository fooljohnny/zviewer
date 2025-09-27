@echo off
chcp 65001 >nul
echo Running health check...

REM Check API Gateway (Kong)
echo Checking API Gateway (Kong)...
curl -f -s http://localhost:8000/health >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] API Gateway (Kong) health check passed
) else (
    echo [FAIL] API Gateway (Kong) health check failed
)

REM Check Consul
echo Checking Consul...
curl -f -s http://localhost:8500/v1/status/leader >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Consul health check passed
) else (
    echo [FAIL] Consul health check failed
)

REM Check Main Server
echo Checking Main Server...
curl -f -s http://localhost:8080/health >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Main Server health check passed
) else (
    echo [FAIL] Main Server health check failed
)

REM Check Media Service
echo Checking Media Service...
curl -f -s http://localhost:8081/api/health >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Media Service health check passed
) else (
    echo [FAIL] Media Service health check failed
)

REM Check Comments Service
echo Checking Comments Service...
curl -f -s http://localhost:8082/api/health >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Comments Service health check passed
) else (
    echo [FAIL] Comments Service health check failed
)

REM Check Payments Service
echo Checking Payments Service...
curl -f -s http://localhost:8083/api/health >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Payments Service health check passed
) else (
    echo [FAIL] Payments Service health check failed
)

REM Check Admin Service
echo Checking Admin Service...
curl -f -s http://localhost:8084/api/health >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Admin Service health check passed
) else (
    echo [FAIL] Admin Service health check failed
)

REM Check Nginx
echo Checking Nginx...
curl -f -s http://localhost/health >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Nginx health check passed
) else (
    echo [FAIL] Nginx health check failed
)

REM Check Prometheus
echo Checking Prometheus...
curl -f -s http://localhost:9090/-/healthy >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Prometheus health check passed
) else (
    echo [FAIL] Prometheus health check failed
)

REM Check Grafana
echo Checking Grafana...
curl -f -s http://localhost:3000/api/health >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Grafana health check passed
) else (
    echo [FAIL] Grafana health check failed
)

echo Health check completed!
