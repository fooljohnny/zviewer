# 图集管理API文档

## 概述

本文档描述了ZViewer图集管理功能的REST API接口。图集管理允许管理员创建、管理图集，添加/移除图片，设置封面等操作。

## 数据库结构

### 表结构

#### albums 表
- `id`: UUID主键
- `title`: 图集标题 (VARCHAR(255))
- `description`: 图集描述 (TEXT)
- `cover_image_id`: 封面图片ID (UUID)
- `cover_image_path`: 封面图片路径 (VARCHAR(500))
- `cover_thumbnail_path`: 封面缩略图路径 (VARCHAR(500))
- `status`: 图集状态 (draft/published/archived)
- `user_id`: 创建者ID (UUID, 外键)
- `created_at`: 创建时间
- `updated_at`: 更新时间
- `metadata`: 元数据 (JSONB)
- `is_public`: 是否公开 (BOOLEAN)
- `view_count`: 浏览次数 (INTEGER)
- `like_count`: 点赞次数 (INTEGER)
- `tags`: 标签数组 (TEXT[])

#### album_images 表
- `id`: UUID主键
- `album_id`: 图集ID (UUID, 外键)
- `image_id`: 图片ID (UUID)
- `image_path`: 图片路径 (VARCHAR(500))
- `thumbnail_path`: 缩略图路径 (VARCHAR(500))
- `mime_type`: MIME类型 (VARCHAR(100))
- `file_size`: 文件大小 (BIGINT)
- `width`: 图片宽度 (INTEGER)
- `height`: 图片高度 (INTEGER)
- `sort_order`: 排序顺序 (INTEGER)
- `added_at`: 添加时间
- `added_by`: 添加者ID (UUID, 外键)

## API端点

### 认证

所有管理员API都需要Bearer Token认证。

```bash
Authorization: Bearer <your-jwt-token>
```

### 1. 创建图集

**POST** `/api/admin/albums`

创建新的图集。

**请求体:**
```json
{
  "title": "我的图集",
  "description": "这是一个测试图集",
  "imageIds": ["image-1", "image-2", "image-3"],
  "tags": ["风景", "摄影"],
  "isPublic": true
}
```

**响应:**
```json
{
  "success": true,
  "message": "Album created successfully",
  "album": {
    "id": "album-uuid",
    "title": "我的图集",
    "description": "这是一个测试图集",
    "status": "draft",
    "user_id": "user-uuid",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z",
    "is_public": true,
    "view_count": 0,
    "like_count": 0,
    "tags": ["风景", "摄影"],
    "image_count": 3
  }
}
```

### 2. 获取图集详情

**GET** `/api/admin/albums/{id}`

获取指定图集的详细信息。

**响应:**
```json
{
  "success": true,
  "message": "Album retrieved successfully",
  "album": {
    "id": "album-uuid",
    "title": "我的图集",
    "description": "这是一个测试图集",
    "cover_image_id": "image-1",
    "cover_image_path": "/path/to/cover.jpg",
    "cover_thumbnail_path": "/path/to/cover_thumb.jpg",
    "status": "published",
    "user_id": "user-uuid",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z",
    "is_public": true,
    "view_count": 15,
    "like_count": 3,
    "tags": ["风景", "摄影"],
    "image_count": 3,
    "images": [
      {
        "id": "album-image-uuid",
        "album_id": "album-uuid",
        "image_id": "image-1",
        "image_path": "/path/to/image1.jpg",
        "thumbnail_path": "/path/to/image1_thumb.jpg",
        "mime_type": "image/jpeg",
        "file_size": 1024000,
        "width": 1920,
        "height": 1080,
        "sort_order": 0,
        "added_at": "2024-01-01T00:00:00Z",
        "added_by": "user-uuid"
      }
    ]
  }
}
```

### 3. 获取图集列表

**GET** `/api/admin/albums`

获取图集列表，支持分页和筛选。

**查询参数:**
- `page`: 页码 (默认: 1)
- `limit`: 每页数量 (默认: 20, 最大: 100)
- `user_id`: 筛选特定用户的图集
- `public`: 只获取公开图集 (true/false)

**响应:**
```json
{
  "albums": [
    {
      "id": "album-uuid-1",
      "title": "图集1",
      "description": "描述1",
      "status": "published",
      "user_id": "user-uuid",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z",
      "is_public": true,
      "view_count": 10,
      "like_count": 2,
      "tags": ["标签1"],
      "image_count": 5
    }
  ],
  "total": 25,
  "page": 1,
  "limit": 20,
  "total_pages": 2
}
```

### 4. 更新图集

**PUT** `/api/admin/albums/{id}`

更新图集信息。

**请求体:**
```json
{
  "title": "更新的图集标题",
  "description": "更新的描述",
  "imageIds": ["image-1", "image-2", "image-4"],
  "coverImageId": "image-1",
  "tags": ["新标签"],
  "isPublic": false,
  "status": "published"
}
```

**响应:**
```json
{
  "success": true,
  "message": "Album updated successfully",
  "album": {
    "id": "album-uuid",
    "title": "更新的图集标题",
    "description": "更新的描述",
    "status": "published",
    "updated_at": "2024-01-01T01:00:00Z",
    "is_public": false,
    "tags": ["新标签"],
    "image_count": 3
  }
}
```

### 5. 删除图集

**DELETE** `/api/admin/albums/{id}`

删除图集。

**响应:**
```json
{
  "success": true,
  "message": "Album deleted successfully"
}
```

### 6. 添加图片到图集

**POST** `/api/admin/albums/{id}/images`

向图集添加图片。

**请求体:**
```json
{
  "imageIds": ["image-5", "image-6"]
}
```

**响应:**
```json
{
  "success": true,
  "message": "Images added to album successfully"
}
```

### 7. 从图集移除图片

**DELETE** `/api/admin/albums/{id}/images`

从图集移除图片。

**请求体:**
```json
{
  "imageIds": ["image-5", "image-6"]
}
```

**响应:**
```json
{
  "success": true,
  "message": "Images removed from album successfully"
}
```

### 8. 设置图集封面

**PUT** `/api/admin/albums/{id}/cover`

设置图集封面图片。

**请求体:**
```json
{
  "imageId": "image-2"
}
```

**响应:**
```json
{
  "success": true,
  "message": "Album cover set successfully"
}
```

### 9. 搜索图集

**GET** `/api/admin/albums/search`

搜索图集。

**查询参数:**
- `q`: 搜索关键词 (必需)
- `page`: 页码 (默认: 1)
- `limit`: 每页数量 (默认: 20)

**响应:**
```json
{
  "albums": [
    {
      "id": "album-uuid",
      "title": "匹配的图集",
      "description": "包含搜索关键词的描述",
      "status": "published",
      "user_id": "user-uuid",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z",
      "is_public": true,
      "view_count": 5,
      "like_count": 1,
      "tags": ["匹配的标签"],
      "image_count": 3
    }
  ],
  "total": 1,
  "page": 1,
  "limit": 20,
  "total_pages": 1
}
```

## 公开API

### 获取公开图集

**GET** `/api/public/albums`

获取公开的图集列表。

**查询参数:**
- `page`: 页码 (默认: 1)
- `limit`: 每页数量 (默认: 20)

**响应:** 与管理员API的图集列表响应格式相同。

### 获取公开图集详情

**GET** `/api/public/albums/{id}`

获取公开图集的详细信息。

**响应:** 与管理员API的图集详情响应格式相同。

## 错误响应

所有API在出错时返回以下格式：

```json
{
  "message": "错误描述信息"
}
```

**常见HTTP状态码:**
- `200`: 成功
- `201`: 创建成功
- `400`: 请求参数错误
- `401`: 未认证
- `403`: 无权限
- `404`: 资源不存在
- `500`: 服务器内部错误

## 使用示例

### 使用curl测试API

```bash
# 1. 登录获取token
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@zviewer.local","password":"admin123"}' \
  | jq -r '.token')

# 2. 创建图集
curl -X POST http://localhost:8080/api/admin/albums \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "测试图集",
    "description": "这是一个测试图集",
    "imageIds": ["img1", "img2"],
    "tags": ["测试"],
    "isPublic": true
  }'

# 3. 获取图集列表
curl -X GET http://localhost:8080/api/admin/albums \
  -H "Authorization: Bearer $TOKEN"
```

### 使用测试脚本

运行提供的测试脚本：

```bash
cd server
go run test_album_api.go
```

## 注意事项

1. 所有管理员API都需要有效的JWT Token
2. 只有图集的所有者才能修改或删除图集
3. 图片ID必须是有效的媒体文件ID
4. 图集状态可以是：draft（草稿）、published（已发布）、archived（已归档）
5. 删除图集会级联删除所有关联的图片记录
6. 设置封面时，指定的图片必须已经存在于图集中
