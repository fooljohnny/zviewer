#!/bin/bash

# ZViewer Server with Album API
# This script starts the server with the new album management API

echo "🚀 Starting ZViewer Server with Album Management API..."

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go first."
    exit 1
fi

# Check if PostgreSQL is running
if ! pg_isready -q; then
    echo "❌ PostgreSQL is not running. Please start PostgreSQL first."
    echo "   On Ubuntu/Debian: sudo systemctl start postgresql"
    echo "   On macOS: brew services start postgresql"
    exit 1
fi

# Set environment variables
export ZVIEWER_DB_HOST=localhost
export ZVIEWER_DB_PORT=5432
export ZVIEWER_DB_USER=zviewer
export ZVIEWER_DB_PASSWORD=zviewer123
export ZVIEWER_DB_NAME=zviewer
export ZVIEWER_DB_SSLMODE=disable
export ZVIEWER_JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
export ZVIEWER_JWT_EXPIRATION=24h
export ZVIEWER_SERVER_PORT=8080
export ZVIEWER_ENVIRONMENT=development

echo "📊 Environment Configuration:"
echo "   Database: $ZVIEWER_DB_HOST:$ZVIEWER_DB_PORT/$ZVIEWER_DB_NAME"
echo "   Server Port: $ZVIEWER_SERVER_PORT"
echo "   Environment: $ZVIEWER_ENVIRONMENT"

# Create database if it doesn't exist
echo "🗄️  Checking database..."
createdb -h $ZVIEWER_DB_HOST -p $ZVIEWER_DB_PORT -U $ZVIEWER_DB_USER $ZVIEWER_DB_NAME 2>/dev/null || echo "   Database already exists"

# Run migrations
echo "🔄 Running database migrations..."
go run cmd/api/main.go --migrate-only 2>/dev/null || echo "   Migrations completed"

# Start the server
echo "🌐 Starting server on port $ZVIEWER_SERVER_PORT..."
echo "   Admin API: http://localhost:$ZVIEWER_SERVER_PORT/api/admin/albums"
echo "   Public API: http://localhost:$ZVIEWER_SERVER_PORT/api/public/albums"
echo "   Health Check: http://localhost:$ZVIEWER_SERVER_PORT/health"
echo ""
echo "📝 Default admin credentials:"
echo "   Email: admin@zviewer.local"
echo "   Password: admin123"
echo ""
echo "🧪 To test the API, run: go run test_album_api.go"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start the server
go run cmd/api/main.go
