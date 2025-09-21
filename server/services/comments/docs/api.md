# Comments Service API Documentation

## Overview

The Comments Service provides RESTful API endpoints for managing user comments on media content. It supports comment creation, retrieval, updating, deletion, threading (replies), and moderation capabilities.

## Base URL

```
http://localhost:8082/api/v1/comments
```

## Authentication

Most endpoints require JWT authentication. Include the JWT token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

## Endpoints

### 1. Create Comment

**POST** `/comments`

Creates a new comment on a media item.

**Headers:**
- `Authorization: Bearer <token>` (required)
- `Content-Type: application/json`

**Request Body:**
```json
{
  "mediaItemId": "uuid",
  "parentId": "uuid", // optional, for replies
  "content": "string" // max 1000 characters
}
```

**Response:**
```json
{
  "id": "uuid",
  "userId": "uuid",
  "mediaItemId": "uuid",
  "parentId": "uuid",
  "content": "string",
  "status": "active",
  "createdAt": "2024-01-21T10:00:00Z",
  "updatedAt": "2024-01-21T10:00:00Z",
  "isEdited": false,
  "repliesCount": 0
}
```

**Status Codes:**
- `201 Created` - Comment created successfully
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Authentication required
- `500 Internal Server Error` - Server error

### 2. Get Comment

**GET** `/comments/{id}`

Retrieves a specific comment by ID.

**Response:**
```json
{
  "id": "uuid",
  "userId": "uuid",
  "mediaItemId": "uuid",
  "parentId": "uuid",
  "content": "string",
  "status": "active",
  "createdAt": "2024-01-21T10:00:00Z",
  "updatedAt": "2024-01-21T10:00:00Z",
  "deletedAt": null,
  "isEdited": false,
  "repliesCount": 5,
  "userName": "john_doe"
}
```

**Status Codes:**
- `200 OK` - Comment retrieved successfully
- `404 Not Found` - Comment not found
- `500 Internal Server Error` - Server error

### 3. Update Comment

**PUT** `/comments/{id}`

Updates an existing comment. Only the comment owner can update their comments.

**Headers:**
- `Authorization: Bearer <token>` (required)
- `Content-Type: application/json`

**Request Body:**
```json
{
  "content": "string" // max 1000 characters
}
```

**Response:**
```json
{
  "id": "uuid",
  "userId": "uuid",
  "mediaItemId": "uuid",
  "parentId": "uuid",
  "content": "Updated content",
  "status": "active",
  "createdAt": "2024-01-21T10:00:00Z",
  "updatedAt": "2024-01-21T10:05:00Z",
  "isEdited": true,
  "repliesCount": 5
}
```

**Status Codes:**
- `200 OK` - Comment updated successfully
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Not authorized to update this comment
- `404 Not Found` - Comment not found
- `500 Internal Server Error` - Server error

### 4. Delete Comment

**DELETE** `/comments/{id}`

Soft deletes a comment. Comment owners and admins can delete comments.

**Headers:**
- `Authorization: Bearer <token>` (required)

**Response:**
```json
{
  "message": "Comment deleted successfully"
}
```

**Status Codes:**
- `200 OK` - Comment deleted successfully
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Not authorized to delete this comment
- `404 Not Found` - Comment not found
- `500 Internal Server Error` - Server error

### 5. List Comments

**GET** `/comments`

Lists comments with pagination and filtering.

**Query Parameters:**
- `page` (int, default: 1) - Page number
- `limit` (int, default: 20, max: 100) - Items per page
- `mediaId` (string) - Filter by media item ID
- `userId` (string) - Filter by user ID
- `status` (string) - Filter by status (active, deleted, moderated, pending)
- `parentId` (string) - Filter by parent comment ID (use "null" for top-level comments)
- `sortBy` (string, default: "created_at") - Sort field
- `sortOrder` (string, default: "desc") - Sort order (asc, desc)

**Response:**
```json
{
  "comments": [
    {
      "id": "uuid",
      "userId": "uuid",
      "mediaItemId": "uuid",
      "parentId": null,
      "content": "string",
      "status": "active",
      "createdAt": "2024-01-21T10:00:00Z",
      "updatedAt": "2024-01-21T10:00:00Z",
      "isEdited": false,
      "repliesCount": 5,
      "userName": "john_doe"
    }
  ],
  "total": 100,
  "page": 1,
  "limit": 20,
  "hasMore": true
}
```

**Status Codes:**
- `200 OK` - Comments retrieved successfully
- `400 Bad Request` - Invalid query parameters
- `500 Internal Server Error` - Server error

### 6. Get Comments by Media

**GET** `/comments/media/{mediaId}`

Gets all comments for a specific media item.

**Query Parameters:** Same as List Comments

**Response:** Same as List Comments

**Status Codes:**
- `200 OK` - Comments retrieved successfully
- `400 Bad Request` - Invalid query parameters
- `500 Internal Server Error` - Server error

### 7. Reply to Comment

**POST** `/comments/{id}/reply`

Creates a reply to an existing comment.

**Headers:**
- `Authorization: Bearer <token>` (required)
- `Content-Type: application/json`

**Request Body:**
```json
{
  "content": "string" // max 1000 characters
}
```

**Response:**
```json
{
  "id": "uuid",
  "userId": "uuid",
  "mediaItemId": "uuid",
  "parentId": "parent-comment-id",
  "content": "Reply content",
  "status": "active",
  "createdAt": "2024-01-21T10:00:00Z",
  "updatedAt": "2024-01-21T10:00:00Z",
  "isEdited": false,
  "repliesCount": 0
}
```

**Status Codes:**
- `201 Created` - Reply created successfully
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Authentication required
- `404 Not Found` - Parent comment not found
- `500 Internal Server Error` - Server error

### 8. Get Replies

**GET** `/comments/{id}/replies`

Gets all replies to a specific comment.

**Query Parameters:** Same as List Comments

**Response:** Same as List Comments

**Status Codes:**
- `200 OK` - Replies retrieved successfully
- `400 Bad Request` - Invalid query parameters
- `500 Internal Server Error` - Server error

### 9. Get Comment Statistics (Admin Only)

**GET** `/comments/stats`

Gets overall comment statistics. Requires admin role.

**Headers:**
- `Authorization: Bearer <admin-token>` (required)

**Response:**
```json
{
  "totalComments": 1000,
  "activeComments": 950,
  "deletedComments": 30,
  "moderatedComments": 15,
  "pendingComments": 5,
  "commentsToday": 25,
  "commentsThisWeek": 150,
  "commentsThisMonth": 600
}
```

**Status Codes:**
- `200 OK` - Statistics retrieved successfully
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Admin access required
- `500 Internal Server Error` - Server error

### 10. Get User Statistics

**GET** `/comments/stats/user/{userId}`

Gets comment statistics for a specific user.

**Response:**
```json
{
  "userId": "uuid",
  "userName": "john_doe",
  "totalComments": 50,
  "activeComments": 45,
  "lastCommentAt": "2024-01-21T10:00:00Z"
}
```

**Status Codes:**
- `200 OK` - Statistics retrieved successfully
- `500 Internal Server Error` - Server error

### 11. Get Media Statistics

**GET** `/comments/stats/media/{mediaId}`

Gets comment statistics for a specific media item.

**Response:**
```json
{
  "mediaId": "uuid",
  "totalComments": 25,
  "activeComments": 23,
  "lastCommentAt": "2024-01-21T10:00:00Z"
}
```

**Status Codes:**
- `200 OK` - Statistics retrieved successfully
- `500 Internal Server Error` - Server error

### 12. Moderate Comment (Admin Only)

**POST** `/comments/{id}/moderate`

Moderates a comment. Requires admin role.

**Headers:**
- `Authorization: Bearer <admin-token>` (required)
- `Content-Type: application/json`

**Request Body:**
```json
{
  "action": "approve", // "approve", "reject", "delete"
  "reason": "string" // optional
}
```

**Response:**
```json
{
  "message": "Comment moderated successfully"
}
```

**Status Codes:**
- `200 OK` - Comment moderated successfully
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Admin access required
- `404 Not Found` - Comment not found
- `500 Internal Server Error` - Server error

## Error Responses

All error responses follow this format:

```json
{
  "message": "Error description",
  "error": "Detailed error information" // optional
}
```

## Rate Limiting

Comment creation is rate-limited to prevent spam:
- Default: 10 comments per minute per user
- Configurable via environment variables

## Content Filtering

- Comments are automatically filtered for profanity (configurable)
- Comments with flagged content are marked as "pending" for moderation
- Content is sanitized to remove excessive whitespace

## Comment Status

- `active` - Comment is visible and can be interacted with
- `deleted` - Comment has been soft-deleted
- `moderated` - Comment has been moderated and hidden
- `pending` - Comment is awaiting moderation approval

## Threading

Comments support threading through the `parentId` field:
- Top-level comments have `parentId: null`
- Replies have `parentId` set to their parent comment's ID
- Maximum nesting depth: 1 level (no nested replies)

## Pagination

All list endpoints support pagination:
- `page` - Page number (1-based)
- `limit` - Items per page (max 100)
- `hasMore` - Boolean indicating if more pages exist

## Sorting

Comments can be sorted by:
- `created_at` (default)
- `updated_at`
- `content`

Sort order can be:
- `desc` (default)
- `asc`

## Health Check

**GET** `/health`

Returns service health status.

**Response:**
```json
{
  "status": "healthy"
}
```
