# 媒体文件存储问题解决方案

## 🔍 问题描述

上传的图片在重启服务后消失，这是因为媒体文件没有正确持久化存储。

## 🎯 问题原因

1. **存储路径配置问题** - 媒体服务使用相对路径 `./uploads/media`，重启后可能丢失
2. **没有持久化存储** - 直接运行Go程序时，文件存储在临时目录
3. **Docker容器数据丢失** - 没有正确的卷挂载配置

## 🛠️ 解决方案

### 方案1：使用Docker Compose（推荐）

```bash
# 启动所有服务，包括持久化存储
docker-compose -f docker-compose-full.yml up -d

# 查看服务状态
docker-compose -f docker-compose-full.yml ps

# 查看媒体文件存储
docker volume ls
```

**优点：**
- 完全持久化存储
- 服务隔离
- 易于管理

### 方案2：本地开发模式

```bash
# 1. 启动数据库
docker-compose up postgres -d

# 2. 启动主API服务
start_with_album_api.bat

# 3. 启动媒体服务（新窗口）
cd services/media
start_media_service.bat
```

**优点：**
- 开发调试方便
- 文件直接存储在本地

### 方案3：修改存储路径

修改 `server/services/media/config.env`：

```env
# 使用绝对路径
LOCAL_STORAGE_PATH=D:\ZengQ\Codes\zviewer\server\uploads\media
```

## 📁 文件存储位置

### Docker模式
- 卷名称：`media_uploads`
- 容器内路径：`/uploads/media`
- 宿主机路径：Docker管理的卷

### 本地模式
- 路径：`server/uploads/media/`
- 结构：
  ```
  uploads/
  └── media/
      ├── 2024/
      │   └── 12/
      │       └── 19/
      │           └── user_id/
      │               ├── original_file.jpg
      │               └── thumbnails/
      │                   └── thumbnail_300x300.jpg
  ```

## 🔧 配置说明

### 环境变量

```env
# 媒体服务配置
PORT=8081
DATABASE_URL=postgres://zviewer:zviewer123@localhost:5432/zviewer?sslmode=disable
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
STORAGE_TYPE=local
LOCAL_STORAGE_PATH=./uploads/media
MAX_IMAGE_SIZE=104857600
MAX_VIDEO_SIZE=524288000
```

### Docker Compose配置

```yaml
volumes:
  media_uploads:  # 持久化媒体文件存储

services:
  media-service:
    volumes:
      - media_uploads:/uploads/media  # 挂载到容器
```

## 🚀 快速启动

### 使用Docker（推荐）

```bash
# 1. 创建网络
docker network create zviewer-network

# 2. 启动所有服务
docker-compose -f docker-compose-full.yml up -d

# 3. 查看日志
docker-compose -f docker-compose-full.yml logs -f media-service
```

### 本地开发

```bash
# 1. 启动数据库
docker-compose up postgres -d

# 2. 启动主服务
start_with_album_api.bat

# 3. 启动媒体服务
cd services/media
start_media_service.bat
```

## 🔍 验证存储

### 检查文件是否存在

```bash
# Docker模式
docker exec -it <media-service-container> ls -la /uploads/media

# 本地模式
dir server\uploads\media
```

### 检查API响应

```bash
# 获取媒体列表
curl http://localhost:8081/api/media

# 获取特定媒体文件
curl http://localhost:8081/api/media/{media_id}
```

## ⚠️ 注意事项

1. **备份重要数据** - 定期备份 `uploads` 目录
2. **权限设置** - 确保应用有读写权限
3. **磁盘空间** - 监控存储空间使用情况
4. **安全考虑** - 生产环境建议使用S3等云存储

## 🆘 故障排除

### 文件仍然消失

1. 检查存储路径是否正确
2. 确认卷挂载配置
3. 查看服务日志
4. 验证文件权限

### 服务无法启动

1. 检查端口是否被占用
2. 确认数据库连接
3. 验证环境变量
4. 查看错误日志

## 📞 支持

如果问题仍然存在，请检查：
1. 服务日志：`docker-compose logs media-service`
2. 文件系统权限
3. 网络连接
4. 数据库状态
