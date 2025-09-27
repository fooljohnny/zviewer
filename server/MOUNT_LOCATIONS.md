# 挂载位置详细说明

## 📍 当前实际挂载位置

### 1. **Docker Compose 方式（理想情况）**

```yaml
# docker-compose-full.yml
volumes:
  media_uploads:  # Docker卷名称

services:
  media-service:
    volumes:
      - media_uploads:/uploads/media  # 挂载映射
```

**挂载位置：**
- **Docker卷名称：** `media_uploads`
- **容器内路径：** `/uploads/media`
- **宿主机实际位置：** `C:\ProgramData\Docker\volumes\server_media_uploads\_data\`
- **访问方式：** 通过Docker卷管理

### 2. **当前本地运行方式（实际使用）**

```bash
# 环境变量设置
LOCAL_STORAGE_PATH="../../uploads/media"
```

**挂载位置：**
- **绝对路径：** `D:\ZengQ\Codes\zviewer\server\uploads\media\`
- **相对路径：** `server\uploads\media\`
- **访问方式：** 直接文件系统访问

## 📁 目录结构

```
D:\ZengQ\Codes\zviewer\
├── server\
│   ├── uploads\                    ← 媒体文件存储根目录
│   │   └── media\                  ← 实际挂载位置
│   │       ├── 2024\              ← 按年份组织
│   │       │   └── 12\            ← 按月份组织
│   │       │       └── 19\        ← 按日期组织
│   │       │           └── user_id\  ← 按用户ID组织
│   │       │               ├── original_file.jpg
│   │       │               └── thumbnails\
│   │       │                   └── thumbnail_300x300.jpg
│   ├── services\
│   │   └── media\                 ← 媒体服务代码
│   │       └── cmd\api\main.go    ← 媒体服务入口
│   └── cmd\api\main.go            ← 主API服务入口
```

## 🔄 数据流说明

### 文件上传流程：

```
用户上传图片
    ↓
媒体服务 (services/media/cmd/api/main.go)
    ↓
环境变量: LOCAL_STORAGE_PATH="../../uploads/media"
    ↓
保存到: D:\ZengQ\Codes\zviewer\server\uploads\media\
    ↓
按日期和用户ID组织存储
```

### 文件访问流程：

```
前端请求图片
    ↓
主API服务 (cmd/api/main.go)
    ↓
转发到媒体服务
    ↓
媒体服务从: D:\ZengQ\Codes\zviewer\server\uploads\media\
    ↓
返回图片数据
```

## 🎯 关键配置点

### 1. **媒体服务配置**

```bash
# 环境变量
PORT=8081
DATABASE_URL=postgres://zviewer:zviewer123@localhost:5432/zviewer?sslmode=disable
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
STORAGE_TYPE=local
LOCAL_STORAGE_PATH=../../uploads/media  ← 关键配置
```

### 2. **路径解析**

```bash
# 媒体服务运行位置
D:\ZengQ\Codes\zviewer\server\services\media\

# 相对路径解析
../../uploads/media
    ↓
D:\ZengQ\Codes\zviewer\server\uploads\media\
```

## ✅ 验证方法

### 1. **检查目录是否存在**

```bash
# PowerShell
ls D:\ZengQ\Codes\zviewer\server\uploads\media

# 或者
dir server\uploads\media
```

### 2. **上传测试文件**

```bash
# 创建测试文件
echo "test" > server\uploads\media\test.txt
```

### 3. **检查服务日志**

```bash
# 查看媒体服务日志
# 应该显示文件保存路径
```

## 🔧 故障排除

### 问题1：文件保存失败

**可能原因：**
- 目录权限不足
- 路径配置错误
- 磁盘空间不足

**解决方法：**
```bash
# 检查目录权限
icacls server\uploads\media

# 重新创建目录
mkdir server\uploads\media -Force
```

### 问题2：文件找不到

**可能原因：**
- 路径配置不一致
- 服务重启后路径变化
- 文件被意外删除

**解决方法：**
```bash
# 检查实际存储位置
Get-ChildItem -Recurse server\uploads\media

# 检查服务配置
echo $env:LOCAL_STORAGE_PATH
```

## 📊 性能考虑

### 1. **存储位置选择**

- **本地存储：** 快速访问，适合开发
- **网络存储：** 可扩展，适合生产
- **云存储：** 高可用，适合大规模部署

### 2. **目录组织**

- **按日期组织：** 便于管理和清理
- **按用户组织：** 便于权限控制
- **按类型组织：** 便于分类管理

## 🎉 总结

**当前挂载位置：** `D:\ZengQ\Codes\zviewer\server\uploads\media\`

**特点：**
- ✅ 持久化存储
- ✅ 重启后数据保留
- ✅ 直接文件系统访问
- ✅ 便于调试和管理

**验证：**
1. 上传一张图片
2. 检查 `server\uploads\media\` 目录
3. 重启服务
4. 确认图片仍然存在
