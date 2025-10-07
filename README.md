# ZViewer - Multimedia Viewer Application

A cross-platform multimedia viewer application built with Flutter for viewing images and videos, with a Go backend server for user authentication and content management.

## Project Structure

```
zviewer/
├── application/              # Flutter application (Frontend)
│   ├── lib/                 # Dart source code
│   │   ├── main.dart        # Application entry point
│   │   ├── models/          # Data models
│   │   ├── providers/       # State management
│   │   ├── services/        # API services
│   │   └── widgets/         # UI components
│   ├── test/                # Unit tests
│   ├── assets/              # Media assets
│   └── pubspec.yaml         # Flutter dependencies
├── server/                  # Go backend server
│   ├── cmd/api/            # Server entry point
│   ├── internal/           # Internal packages
│   ├── pkg/                # Public packages
│   ├── migrations/         # Database migrations
│   └── go.mod              # Go dependencies
├── docs/                    # Project documentation
│   ├── architecture/        # Technical architecture docs
│   ├── prd/                # Product requirements
│   └── stories/            # User stories and tasks
└── web-bundles/            # BMAD agent configurations
```

## 快速启动

### 方法 1: 使用 Python 启动脚本（推荐）

我们提供了功能完整的 Python 启动脚本来管理所有服务：

```bash
# 启动完整应用（客户端 + 主服务器 + 数据库）
python start.py

# 启动所有微服务（媒体、评论、支付、管理）
python start.py --all-services

# 仅启动客户端
python start.py --client-only

# 仅启动主服务器
python start.py --server-only

# 启动服务器但不启动数据库（用于测试）
python start.py --server-only --no-db

# 启动特定微服务
python start.py --media-only      # 仅媒体服务
python start.py --comments-only   # 仅评论服务
python start.py --payments-only   # 仅支付服务
python start.py --admin-only      # 仅管理服务
```

### 方法 2: 使用平台特定脚本

**Windows:**
```cmd
# 使用批处理脚本（启动基础设施 + 微服务）
start.bat

# 或使用 PowerShell 脚本
start.ps1
```

**Linux/macOS:**
```bash
# 使用 Shell 脚本
./start.sh
```

### 服务端口说明

启动后，以下服务将在指定端口运行：

- **主服务器**: http://localhost:8080
- **媒体服务**: http://localhost:8081
- **评论服务**: http://localhost:8082
- **支付服务**: http://localhost:8083
- **管理服务**: http://localhost:8084
- **PostgreSQL 数据库**: localhost:5432
- **Kong 网关**: http://localhost:8002
- **Kong 管理**: http://localhost:8003

## 系统要求

### 必需软件
- **Python 3.6+** - 用于运行启动脚本
- **Flutter SDK 3.0+** - 用于客户端开发（支持 Dart 3.0+）
- **Go 1.21+** - 用于服务器开发
- **Docker & Docker Compose** - 用于数据库和微服务
- **Visual Studio 2022** (Windows) - 用于 Flutter Windows 开发

### 详细依赖

#### Flutter 客户端依赖
- **Dart SDK**: >=3.0.0 <4.0.0
- **核心依赖**:
  - `photo_view: ^0.14.0` - 图片查看器
  - `video_player: ^2.8.1` - 视频播放器
  - `provider: ^6.1.1` - 状态管理
  - `http: ^1.1.0` - HTTP 客户端
  - `flutter_secure_storage: ^9.0.0` - 安全存储
  - `cached_network_image: ^3.3.0` - 网络图片缓存
  - `file_picker: ^8.0.0+1` - 文件选择器
  - `shared_preferences: ^2.2.2` - 本地存储
  - `webp: ^0.1.0` - WebP 图片支持
  - `flutter_svg: ^2.0.9` - SVG 支持

#### Go 服务器依赖
- **Go 版本**: 1.21+
- **核心依赖**:
  - `github.com/gin-gonic/gin v1.9.1` - Web 框架
  - `github.com/golang-jwt/jwt/v5 v5.2.0` - JWT 认证
  - `github.com/lib/pq v1.10.9` - PostgreSQL 驱动
  - `github.com/google/uuid v1.5.0` - UUID 生成
  - `github.com/sirupsen/logrus v1.9.3` - 日志库
  - `golang.org/x/crypto v0.17.0` - 加密库

#### 数据库和基础设施
- **PostgreSQL**: 15-alpine (Docker)
- **Redis**: 用于缓存和会话存储
- **Kong Gateway**: API 网关
- **Consul**: 服务发现

### 安装步骤

#### 1. 安装 Flutter SDK

**Windows:**
1. 下载 Flutter SDK: https://flutter.dev/docs/get-started/install/windows
2. 解压到 `C:\flutter`
3. 将 `C:\flutter\bin` 添加到系统 PATH
4. 安装 Visual Studio 2022 Community (包含 C++ 工具)
5. 运行 `flutter doctor` 检查环境

**Linux/macOS:**
```bash
# 使用 snap (Linux)
sudo snap install flutter --classic

# 或手动安装
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# 检查环境
flutter doctor
```

#### 2. 安装 Go

**Windows:**
1. 下载 Go: https://golang.org/dl/
2. 运行安装程序
3. 确保 `go` 命令在 PATH 中
4. 验证安装: `go version`

**Linux/macOS:**
```bash
# Ubuntu/Debian
sudo apt install golang-go

# macOS
brew install go

# 验证安装
go version
```

#### 3. 安装 Docker

**Windows:**
1. 下载 Docker Desktop: https://www.docker.com/products/docker-desktop
2. 安装并启动 Docker Desktop
3. 确保 Docker 服务正在运行

**Linux:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# 验证安装
docker --version
docker-compose --version
```

**macOS:**
```bash
brew install --cask docker
```

## 手动启动（如果脚本失败）

### 1. 启动数据库和基础设施
```bash
cd server
# 启动 PostgreSQL 数据库
docker-compose up -d postgres

# 或启动完整基础设施（包括 Redis、Kong、Consul）
docker-compose -f docker-compose.infrastructure.yml up -d
```

### 2. 启动主服务器
```bash
cd server
# 设置环境变量
export ENVIRONMENT=development
export SERVER_PORT=8080
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=zviewer
export DB_PASSWORD=password
export DB_NAME=zviewer
export DB_SSLMODE=disable
export JWT_SECRET=your-secret-key-change-in-production

# 启动主服务器
go run cmd/api/main.go
```

### 3. 启动微服务（可选）
```bash
# 媒体服务
cd server/services/media
export PORT=8081
export DATABASE_URL=postgres://zviewer:password@localhost:5432/zviewer?sslmode=disable
go run cmd/api/main.go

# 评论服务
cd server/services/comments
export PORT=8082
export DATABASE_URL=postgres://zviewer:password@localhost:5432/zviewer?sslmode=disable
go run cmd/api/main.go

# 支付服务
cd server/services/payments
export PORT=8083
export DATABASE_URL=postgres://zviewer:password@localhost:5432/zviewer?sslmode=disable
go run cmd/api/main.go

# 管理服务
cd server/services/admin
export ADMIN_PORT=8084
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=zviewer
export DB_PASSWORD=password
export DB_NAME=zviewer
export DB_SSLMODE=disable
go run cmd/api/main.go
```

### 4. 启动 Flutter 客户端
```bash
cd application
# 获取依赖
flutter pub get

# 运行应用
flutter run -d windows    # Windows
flutter run -d linux      # Linux
flutter run -d macos      # macOS
flutter run -d chrome     # Web
```

### 5. 数据库迁移（首次运行）
```bash
cd server
# 运行数据库迁移
go run cmd/migrate/main.go up
```

## 故障排除

### 常见问题

**1. "Flutter command not found"**
- 确保 Flutter SDK 已安装并添加到 PATH
- 重启终端/命令提示符
- 运行 `flutter doctor` 检查环境配置

**2. "Go command not found"**
- 确保 Go 1.21+ 已安装并添加到 PATH
- 检查 `go version` 命令是否工作
- 验证 GOPATH 和 GOROOT 环境变量

**3. "Docker command not found"**
- 确保 Docker 已安装并运行
- 在 Windows 上，确保 Docker Desktop 正在运行
- 运行 `docker info` 检查 Docker 状态

**4. 数据库连接失败**
- 确保 Docker 正在运行
- 检查端口 5432 是否被占用
- 尝试重启 Docker 服务
- 检查数据库容器状态: `docker ps`

**5. Flutter 应用无法启动**
- 确保有可用的设备（模拟器或真机）
- 运行 `flutter devices` 检查可用设备
- 在 Windows 上，确保已安装 Visual Studio 2022
- 运行 `flutter doctor` 检查环境问题

**6. Go 模块下载失败**
- 检查网络连接
- 设置 Go 代理: `go env -w GOPROXY=https://goproxy.cn,direct`
- 清理模块缓存: `go clean -modcache`

**7. Flutter 依赖获取失败**
- 检查网络连接
- 清理 Flutter 缓存: `flutter clean`
- 重新获取依赖: `flutter pub get`
- 检查 `pubspec.yaml` 语法

**8. 端口冲突**
- 检查端口占用: `netstat -ano | findstr :8080`
- 停止占用端口的进程
- 修改配置文件中的端口设置

**9. 权限问题（Linux/macOS）**
- 确保用户有 Docker 权限: `sudo usermod -aG docker $USER`
- 重启终端或重新登录
- 检查文件权限: `chmod +x start.sh`

**10. Windows 特定问题**
- 确保已安装 Windows SDK
- 检查 Visual Studio 2022 的 C++ 工具
- 运行 `flutter doctor` 查看具体问题

### 日志查看

启动脚本会显示彩色日志输出：
- 🔍 检查要求
- 🐘 数据库操作
- 🚀 服务器操作
- 📱 客户端操作
- ✅ 成功消息
- ❌ 错误消息

### 调试模式

**Flutter 调试:**
```bash
cd application
flutter run --verbose
```

**Go 服务器调试:**
```bash
cd server
go run cmd/api/main.go -debug
```

**Docker 日志:**
```bash
docker-compose logs -f
```

## 开发模式

### 环境变量

服务器使用以下环境变量（可在 `server/.env` 文件中设置）：

**主服务器环境变量:**
```env
ENVIRONMENT=development
SERVER_PORT=8080
SERVER_HOST=localhost
DB_HOST=localhost
DB_PORT=5432
DB_USER=zviewer
DB_PASSWORD=password
DB_NAME=zviewer
DB_SSLMODE=disable
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRATION=24h
```

**微服务环境变量:**
```env
# 媒体服务
PORT=8081
DATABASE_URL=postgres://zviewer:password@localhost:5432/zviewer?sslmode=disable
JWT_SECRET=your-secret-key-change-in-production
STORAGE_TYPE=local
LOCAL_STORAGE_PATH=./uploads/media
MAX_IMAGE_SIZE=104857600
MAX_VIDEO_SIZE=524288000

# 评论服务
PORT=8082
DATABASE_URL=postgres://zviewer:password@localhost:5432/zviewer?sslmode=disable
JWT_SECRET=your-secret-key-change-in-production

# 支付服务
PORT=8083
DATABASE_URL=postgres://zviewer:password@localhost:5432/zviewer?sslmode=disable
JWT_SECRET=your-secret-key-change-in-production

# 管理服务
ADMIN_PORT=8084
ADMIN_HOST=0.0.0.0
DB_HOST=localhost
DB_PORT=5432
DB_USER=zviewer
DB_PASSWORD=password
DB_NAME=zviewer
DB_SSLMODE=disable
JWT_SECRET=your-secret-key-change-in-production
```

### 热重载和开发工具

**Flutter 客户端:**
- 支持热重载，修改代码后按 `r` 键
- 支持热重启，按 `R` 键
- 支持调试模式，按 `d` 键
- 支持性能分析，按 `p` 键

**Go 服务器:**
- 需要手动重启
- 可以使用 `air` 工具实现热重载:
  ```bash
  # 安装 air
  go install github.com/cosmtrek/air@latest
  
  # 在服务器目录运行
  air
  ```

**数据库开发:**
- 使用 `migrate` 工具管理数据库迁移
- 支持回滚: `go run cmd/migrate/main.go down`
- 支持版本检查: `go run cmd/migrate/main.go version`

### 代码质量工具

**Flutter:**
```bash
# 代码格式化
dart format .

# 代码分析
dart analyze

# 运行测试
flutter test
```

**Go:**
```bash
# 代码格式化
go fmt ./...

# 代码检查
go vet ./...

# 运行测试
go test ./...

# 生成测试覆盖率
go test -cover ./...
```

### 停止服务

- **Python 脚本**: 按 `Ctrl+C` 停止所有服务
- **手动停止**: 使用 `Ctrl+C` 停止各个终端中的服务
- **Docker 服务**: `docker-compose down` 停止所有容器
- **清理数据**: `docker-compose down -v` 删除所有数据卷

## Features

### 核心功能
- **跨平台支持**: Web, Android, iOS, Windows, Linux, macOS
- **多媒体查看**: 支持 JPEG, PNG, WebP, GIF 图片格式
- **视频播放**: 支持 MP4, WebM, MOV 视频格式
- **用户认证**: 基于 JWT 的安全登录/注册系统
- **内容管理**: 完整的管理员面板和内容管理系统
- **图集管理**: 创建、编辑、删除图集，支持封面设置
- **图片管理**: 批量上传、预览、删除图片

### 高级功能
- **评论系统**: 用户评论和互动功能
- **支付集成**: 订阅和支付处理系统
- **触摸手势**: 捏合缩放、平移、滑动导航
- **键盘导航**: 方向键、ESC 键支持
- **错误处理**: 优雅的错误恢复和重试功能
- **响应式设计**: 适配移动端和桌面端
- **瀑布流布局**: 自适应的图片网格布局
- **图片缓存**: 智能的图片缓存和预加载
- **安全存储**: 本地安全存储用户数据

### 技术特性
- **微服务架构**: 模块化的后端服务设计
- **API 网关**: Kong 网关统一管理 API
- **服务发现**: Consul 服务注册和发现
- **数据库迁移**: 版本化的数据库结构管理
- **容器化部署**: Docker 容器化部署
- **状态管理**: Provider 模式的状态管理
- **热重载**: 开发时的热重载支持

## Development

### 技术栈

**前端 (Flutter):**
- **框架**: Flutter 3.0+ with Dart 3.0+
- **状态管理**: Provider 6.1.1
- **UI 组件**: Material Design 3
- **图片处理**: photo_view, cached_network_image
- **视频播放**: video_player
- **网络请求**: http
- **本地存储**: shared_preferences, flutter_secure_storage
- **文件处理**: file_picker, webp

**后端 (Go):**
- **框架**: Gin 1.9.1
- **数据库**: PostgreSQL 15 with lib/pq
- **认证**: JWT with golang-jwt/jwt
- **日志**: Logrus
- **UUID**: Google UUID
- **加密**: golang.org/x/crypto

**基础设施:**
- **容器化**: Docker & Docker Compose
- **数据库**: PostgreSQL 15-alpine
- **缓存**: Redis
- **API 网关**: Kong
- **服务发现**: Consul
- **反向代理**: Nginx

### 开发规范

**代码质量:**
- **Flutter**: 遵循 Dart 官方代码规范
- **Go**: 遵循 Go 官方代码规范
- **测试**: 单元测试和集成测试
- **文档**: 详细的 API 文档和代码注释

**项目结构:**
- **模块化设计**: 清晰的分层架构
- **微服务**: 独立的服务模块
- **配置管理**: 环境变量和配置文件
- **错误处理**: 统一的错误处理机制

**版本控制:**
- **Git**: 使用 Git 进行版本控制
- **分支策略**: 主分支 + 功能分支
- **提交规范**: 清晰的提交信息

## Documentation

See the `docs/` directory for detailed documentation including:
- Architecture specifications
- Product requirements
- User stories and development tasks
- API documentation
- Database schema