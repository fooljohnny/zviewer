@echo off
REM ZViewer Server with Persistent Storage
REM This script starts the server with persistent media storage

echo 🚀 Starting ZViewer Server with Persistent Media Storage...

REM Check if Go is installed
go version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Go is not installed. Please install Go first.
    pause
    exit /b 1
)

REM Create uploads directory if it doesn't exist
if not exist "uploads\media" (
    echo 📁 Creating uploads directory...
    mkdir uploads\media
)

REM Set environment variables
set ZVIEWER_DB_HOST=localhost
set ZVIEWER_DB_PORT=5432
set ZVIEWER_DB_USER=zviewer
set ZVIEWER_DB_PASSWORD=zviewer123
set ZVIEWER_DB_NAME=zviewer
set ZVIEWER_DB_SSLMODE=disable
set ZVIEWER_JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
set ZVIEWER_JWT_EXPIRATION=24h
set ZVIEWER_SERVER_PORT=8080
set ZVIEWER_ENVIRONMENT=development

REM Media service environment variables
set MEDIA_SERVICE_PORT=8081
set MEDIA_SERVICE_DATABASE_URL=postgres://zviewer:zviewer123@localhost:5432/zviewer?sslmode=disable
set MEDIA_SERVICE_JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
set MEDIA_SERVICE_STORAGE_TYPE=local
set MEDIA_SERVICE_LOCAL_STORAGE_PATH=./uploads/media
set MEDIA_SERVICE_MAX_IMAGE_SIZE=104857600
set MEDIA_SERVICE_MAX_VIDEO_SIZE=524288000
set MEDIA_SERVICE_MAX_CONCURRENT_UPLOADS=10
set MEDIA_SERVICE_UPLOAD_TIMEOUT=30

echo 📊 Environment Configuration:
echo    Database: %ZVIEWER_DB_HOST%:%ZVIEWER_DB_PORT%/%ZVIEWER_DB_NAME%
echo    Server Port: %ZVIEWER_SERVER_PORT%
echo    Media Service Port: %MEDIA_SERVICE_PORT%
echo    Media Storage Path: %MEDIA_SERVICE_LOCAL_STORAGE_PATH%
echo    Environment: %ZVIEWER_ENVIRONMENT%

echo 🌐 Starting services...
echo    Main API: http://localhost:%ZVIEWER_SERVER_PORT%
echo    Media API: http://localhost:%MEDIA_SERVICE_PORT%
echo    Health Check: http://localhost:%ZVIEWER_SERVER_PORT%/health
echo.
echo 📝 Default admin credentials:
echo    Email: admin@zviewer.local
echo    Password: admin123
echo.
echo 📁 Media files will be stored in: %MEDIA_SERVICE_LOCAL_STORAGE_PATH%
echo.
echo Press Ctrl+C to stop the server
echo.

REM Start the main server in background
start "ZViewer Main API" cmd /k "go run cmd/api/main.go"

REM Wait a moment for the main server to start
timeout /t 3 /nobreak >nul

REM Start the media service
echo 🎬 Starting Media Service...
go run services/media/cmd/api/main.go
