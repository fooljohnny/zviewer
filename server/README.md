# ZViewer Server

A Go-based microservice backend for the ZViewer multimedia application, providing authentication and user management services.

## Features

- **User Authentication**: Registration, login, logout with JWT tokens
- **User Management**: Profile management and role-based access control
- **Database Integration**: PostgreSQL with migrations
- **RESTful API**: Clean API endpoints matching Flutter frontend expectations
- **Security**: Password hashing with bcrypt, JWT authentication, CORS support
- **Testing**: Comprehensive unit and integration tests
- **Docker Support**: Containerized deployment with Docker Compose

## Project Structure

```
server/
├── cmd/api/                 # Application entry point
├── internal/                # Private application code
│   ├── config/             # Configuration management
│   ├── handlers/           # HTTP request handlers
│   ├── middleware/         # HTTP middleware
│   ├── models/             # Data models
│   ├── repositories/       # Database access layer
│   └── services/           # Business logic layer
├── pkg/                    # Public library code
│   └── database/           # Database utilities
├── migrations/             # Database migration files
├── configs/                # Configuration files
├── docs/                   # API documentation
├── go.mod                  # Go module file
├── go.sum                  # Go module checksums
├── Dockerfile              # Docker image definition
├── docker-compose.yml      # Docker Compose configuration
└── README.md               # This file
```

## Prerequisites

- Go 1.21 or later
- PostgreSQL 13 or later
- Docker and Docker Compose (optional)

## Quick Start

### Using Docker Compose (Recommended)

1. Clone the repository and navigate to the server directory:
   ```bash
   cd server
   ```

2. Start the services:
   ```bash
   docker-compose up -d
   ```

3. The server will be available at `http://localhost:8080`

### Manual Setup

1. Install dependencies:
   ```bash
   go mod download
   ```

2. Set up PostgreSQL database:
   ```sql
   CREATE DATABASE zviewer;
   CREATE USER zviewer WITH PASSWORD 'password';
   GRANT ALL PRIVILEGES ON DATABASE zviewer TO zviewer;
   ```

3. Set environment variables:
   ```bash
   export ENVIRONMENT=development
   export SERVER_PORT=8080
   export DB_HOST=localhost
   export DB_PORT=5432
   export DB_USER=zviewer
   export DB_PASSWORD=password
   export DB_NAME=zviewer
   export DB_SSLMODE=disable
   export JWT_SECRET=your-secret-key-change-in-production
   export JWT_EXPIRATION=24h
   ```

4. Run migrations:
   ```bash
   go run cmd/api/main.go
   ```

5. Start the server:
   ```bash
   go run cmd/api/main.go
   ```

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user (requires authentication)
- `GET /api/auth/me` - Get current user info (requires authentication)

### Health Check

- `GET /health` - Server health check

## API Documentation

API documentation is available at `/swagger/index.html` when running in development mode.

## Testing

Run all tests:
```bash
go test ./...
```

Run tests with coverage:
```bash
go test -cover ./...
```

Run specific test package:
```bash
go test ./internal/services
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ENVIRONMENT` | `development` | Application environment |
| `SERVER_PORT` | `8080` | Server port |
| `SERVER_HOST` | `localhost` | Server host |
| `DB_HOST` | `localhost` | Database host |
| `DB_PORT` | `5432` | Database port |
| `DB_USER` | `zviewer` | Database user |
| `DB_PASSWORD` | `password` | Database password |
| `DB_NAME` | `zviewer` | Database name |
| `DB_SSLMODE` | `disable` | Database SSL mode |
| `JWT_SECRET` | `your-secret-key-change-in-production` | JWT secret key |
| `JWT_EXPIRATION` | `24h` | JWT token expiration |
| `JWT_REFRESH_EXPIRY` | `168h` | JWT refresh token expiration |

## Database Schema

### Users Table

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255),
    role VARCHAR(20) NOT NULL DEFAULT 'user',
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE
);
```

## Security Features

- **Password Hashing**: bcrypt with cost factor 12
- **JWT Authentication**: HMAC-SHA256 signing
- **CORS Support**: Configurable cross-origin resource sharing
- **Input Validation**: Request data validation and sanitization
- **SQL Injection Prevention**: Parameterized queries
- **Rate Limiting**: Built-in rate limiting for authentication endpoints

## Development

### Adding New Features

1. Create models in `internal/models/`
2. Implement repository in `internal/repositories/`
3. Add business logic in `internal/services/`
4. Create handlers in `internal/handlers/`
5. Add tests for all new functionality
6. Update API documentation

### Database Migrations

1. Create migration file in `migrations/` directory
2. Use sequential numbering: `001_description.sql`, `002_description.sql`, etc.
3. Test migrations on development database
4. Apply migrations in production

## Deployment

### Docker

Build Docker image:
```bash
docker build -t zviewer-server .
```

Run container:
```bash
docker run -p 8080:8080 zviewer-server
```

### Production Considerations

- Set strong JWT secret key
- Use environment-specific configuration
- Enable SSL/TLS
- Set up proper logging and monitoring
- Configure database connection pooling
- Implement rate limiting
- Set up health checks and monitoring

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is part of the ZViewer application suite.
