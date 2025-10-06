Write-Host "ZViewer Kong Microservices Architecture Startup Script" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Starting Kong Microservices Architecture (Default Mode)..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Checking Docker status..." -ForegroundColor Cyan
try {
    $dockerVersion = docker version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Docker is running normally" -ForegroundColor Green
    } else {
        Write-Host "Docker is not running, attempting to auto-start Docker Desktop..." -ForegroundColor Yellow
        Write-Host "Starting Docker Desktop..." -ForegroundColor Yellow
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -WindowStyle Hidden
        Write-Host "Waiting for Docker Desktop to start (this may take 30-60 seconds)..." -ForegroundColor Yellow
        Write-Host "Please wait while Docker Desktop starts up..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
        $dockerVersion = docker version 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Docker Desktop failed to start automatically." -ForegroundColor Red
            Write-Host "Please start Docker Desktop manually and run this script again." -ForegroundColor Red
            Read-Host "Press Enter to continue"
            exit 1
        }
        Write-Host "Docker Desktop started successfully!" -ForegroundColor Green
    }
} catch {
    Write-Host "Docker is not running, attempting to auto-start Docker Desktop..." -ForegroundColor Yellow
    Write-Host "Starting Docker Desktop..." -ForegroundColor Yellow
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -WindowStyle Hidden
    Write-Host "Waiting for Docker Desktop to start (this may take 30-60 seconds)..." -ForegroundColor Yellow
    Write-Host "Please wait while Docker Desktop starts up..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    try {
        $dockerVersion = docker version 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Docker Desktop failed to start automatically." -ForegroundColor Red
            Write-Host "Please start Docker Desktop manually and run this script again." -ForegroundColor Red
            Read-Host "Press Enter to continue"
            exit 1
        }
        Write-Host "Docker Desktop started successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Docker Desktop failed to start automatically." -ForegroundColor Red
        Write-Host "Please start Docker Desktop manually and run this script again." -ForegroundColor Red
        Read-Host "Press Enter to continue"
        exit 1
    }
}

Write-Host ""
Write-Host "Starting Architecture Components..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Starting Docker infrastructure services..." -ForegroundColor Cyan
Set-Location ".\server"
docker-compose -f docker-compose.infrastructure.yml up -d

Write-Host ""
Write-Host "Waiting for infrastructure services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "ZViewer Kong Microservices Architecture startup completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Service Access URLs:" -ForegroundColor Cyan
Write-Host "   Kong Gateway: http://localhost:8002" -ForegroundColor White
Write-Host "   Kong Admin: http://localhost:8003" -ForegroundColor White
Write-Host "   Consul: http://localhost:8500" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to continue"