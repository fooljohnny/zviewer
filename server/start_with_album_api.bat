@echo off
REM ZViewer Server with Album API
REM This script starts the server with the new album management API

echo 🚀 Starting ZViewer Server with Album Management API...

REM Check if Go is installed
go version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Go is not installed. Please install Go first.
    pause
    exit /b 1
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

echo 📊 Environment Configuration:
echo    Database: %ZVIEWER_DB_HOST%:%ZVIEWER_DB_PORT%/%ZVIEWER_DB_NAME%
echo    Server Port: %ZVIEWER_SERVER_PORT%
echo    Environment: %ZVIEWER_ENVIRONMENT%

REM Start the server
echo 🌐 Starting server on port %ZVIEWER_SERVER_PORT%...
echo    Admin API: http://localhost:%ZVIEWER_SERVER_PORT%/api/admin/albums
echo    Public API: http://localhost:%ZVIEWER_SERVER_PORT%/api/public/albums
echo    Health Check: http://localhost:%ZVIEWER_SERVER_PORT%/health
echo.
echo 📝 Default admin credentials:
echo    Email: admin@zviewer.local
echo    Password: admin123
echo.
echo 🧪 To test the API, run: go run test_album_api.go
echo.
echo Press Ctrl+C to stop the server
echo.

REM Start the server
go run cmd/api/main.go
