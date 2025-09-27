@echo off
REM Media Service Startup Script
REM This script starts the media service with proper storage configuration

echo 🎬 Starting ZViewer Media Service...

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
set PORT=8081
set DATABASE_URL=postgres://zviewer:zviewer123@localhost:5432/zviewer?sslmode=disable
set JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
set STORAGE_TYPE=local
set LOCAL_STORAGE_PATH=./uploads/media
set MAX_IMAGE_SIZE=104857600
set MAX_VIDEO_SIZE=524288000
set IMAGE_THUMBNAIL_SIZE=300
set VIDEO_THUMBNAIL_SIZE=320
set VIDEO_THUMBNAIL_TIME=10
set MAX_CONCURRENT_UPLOADS=10
set UPLOAD_TIMEOUT=30

echo 📊 Media Service Configuration:
echo    Port: %PORT%
echo    Database: %DATABASE_URL%
echo    Storage Type: %STORAGE_TYPE%
echo    Storage Path: %LOCAL_STORAGE_PATH%
echo    Max Image Size: %MAX_IMAGE_SIZE% bytes
echo    Max Video Size: %MAX_VIDEO_SIZE% bytes

echo 🌐 Starting Media Service on port %PORT%...
echo    Media API: http://localhost:%PORT%/api/media
echo    Health Check: http://localhost:%PORT%/health
echo.
echo 📁 Media files will be stored in: %LOCAL_STORAGE_PATH%
echo.
echo Press Ctrl+C to stop the service
echo.

REM Start the media service
go run cmd/api/main.go
