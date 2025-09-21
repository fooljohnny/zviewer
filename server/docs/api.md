# ZViewer Server API Documentation

## Overview

The ZViewer Server provides a RESTful API for user authentication and management. All API endpoints return JSON responses and use standard HTTP status codes.

**Base URL**: `http://localhost:8080/api`

## Authentication

The API uses JWT (JSON Web Token) for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

## Endpoints

### Authentication Endpoints

#### Register User

**POST** `/auth/register`

Register a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "confirmPassword": "password123"
}
```

**Response (201 Created):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "displayName": null,
    "role": "user",
    "createdAt": "2024-01-21T10:00:00Z",
    "lastLoginAt": "2024-01-21T10:00:00Z"
  },
  "expiresAt": "2024-01-22T10:00:00Z"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid request data or passwords don't match
- `409 Conflict` - Email already exists

#### Login User

**POST** `/auth/login`

Authenticate a user and return a JWT token.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "displayName": null,
    "role": "user",
    "createdAt": "2024-01-21T10:00:00Z",
    "lastLoginAt": "2024-01-21T10:00:00Z"
  },
  "expiresAt": "2024-01-22T10:00:00Z"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Invalid credentials

#### Logout User

**POST** `/auth/logout`

Logout the current user (invalidate token).

**Headers:**
```
Authorization: Bearer <your-jwt-token>
```

**Response (200 OK):**
```json
{}
```

**Error Responses:**
- `401 Unauthorized` - Invalid or missing token

#### Get Current User

**GET** `/auth/me`

Get the current authenticated user's information.

**Headers:**
```
Authorization: Bearer <your-jwt-token>
```

**Response (200 OK):**
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "email": "user@example.com",
  "displayName": null,
  "role": "user",
  "createdAt": "2024-01-21T10:00:00Z",
  "lastLoginAt": "2024-01-21T10:00:00Z"
}
```

**Error Responses:**
- `401 Unauthorized` - Invalid or missing token
- `404 Not Found` - User not found

### Health Check

#### Server Health

**GET** `/health`

Check if the server is running and healthy.

**Response (200 OK):**
```json
{
  "status": "ok"
}
```

## Data Models

### User

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Unique user identifier |
| `email` | string | User's email address |
| `displayName` | string (nullable) | User's display name |
| `role` | string | User role (user, admin, moderator) |
| `createdAt` | string (ISO 8601) | Account creation timestamp |
| `lastLoginAt` | string (ISO 8601, nullable) | Last login timestamp |

### AuthResponse

| Field | Type | Description |
|-------|------|-------------|
| `token` | string | JWT authentication token |
| `user` | User | User information |
| `expiresAt` | string (ISO 8601) | Token expiration timestamp |

### ErrorResponse

| Field | Type | Description |
|-------|------|-------------|
| `message` | string | Error message |

## User Roles

- **user**: Regular user with basic permissions
- **admin**: Administrator with full system access
- **moderator**: Moderator with content management permissions

## Error Handling

All error responses follow this format:

```json
{
  "message": "Error description"
}
```

### Common HTTP Status Codes

- `200 OK` - Request successful
- `201 Created` - Resource created successfully
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Authentication required or invalid
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource already exists
- `500 Internal Server Error` - Server error

## Rate Limiting

Authentication endpoints are rate-limited to prevent abuse:
- Registration: 5 requests per minute per IP
- Login: 10 requests per minute per IP

## CORS

The API supports Cross-Origin Resource Sharing (CORS) for web applications. All origins are allowed in development mode.

## Examples

### Complete Authentication Flow

1. **Register a new user:**
   ```bash
   curl -X POST http://localhost:8080/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{
       "email": "user@example.com",
       "password": "password123",
       "confirmPassword": "password123"
     }'
   ```

2. **Login:**
   ```bash
   curl -X POST http://localhost:8080/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{
       "email": "user@example.com",
       "password": "password123"
     }'
   ```

3. **Get user info:**
   ```bash
   curl -X GET http://localhost:8080/api/auth/me \
     -H "Authorization: Bearer <your-jwt-token>"
   ```

4. **Logout:**
   ```bash
   curl -X POST http://localhost:8080/api/auth/logout \
     -H "Authorization: Bearer <your-jwt-token>"
   ```

## Flutter Integration

This API is designed to work seamlessly with the ZViewer Flutter frontend. The response formats match exactly what the Flutter `AuthService` expects.

### Flutter Service Integration

The Flutter app's `AuthService` class can directly consume these endpoints:

```dart
// Example Flutter integration
final response = await http.post(
  Uri.parse('http://localhost:8080/api/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': email,
    'password': password,
  }),
);

if (response.statusCode == 200) {
  final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
  // Handle successful login
}
```
