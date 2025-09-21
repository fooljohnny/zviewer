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

### 方法 1: 使用启动脚本（推荐）

我们提供了便捷的启动脚本来同时启动客户端和服务器：

```bash
# 启动完整应用（客户端 + 服务器 + 数据库）
python start.py

# 仅启动客户端
python start.py --client-only

# 仅启动服务器
python start.py --server-only

# 启动服务器但不启动数据库（用于测试）
python start.py --server-only --no-db
```

### 方法 2: 使用平台特定脚本

**Windows:**
```cmd
start.bat
# 或使用 PowerShell
start.ps1
```

**Linux/macOS:**
```bash
./start.sh
```

## 系统要求

### 必需软件
- **Python 3.6+** - 用于运行启动脚本
- **Flutter SDK** - 用于客户端开发
- **Go 1.21+** - 用于服务器开发
- **Docker & Docker Compose** - 用于数据库

### 安装步骤

#### 1. 安装 Flutter SDK

**Windows:**
1. 下载 Flutter SDK: https://flutter.dev/docs/get-started/install/windows
2. 解压到 `C:\flutter`
3. 将 `C:\flutter\bin` 添加到系统 PATH

**Linux/macOS:**
```bash
# 使用 snap (Linux)
sudo snap install flutter --classic

# 或手动安装
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
```

#### 2. 安装 Go

**Windows:**
1. 下载 Go: https://golang.org/dl/
2. 运行安装程序
3. 确保 `go` 命令在 PATH 中

**Linux/macOS:**
```bash
# Ubuntu/Debian
sudo apt install golang-go

# macOS
brew install go
```

#### 3. 安装 Docker

**Windows:**
1. 下载 Docker Desktop: https://www.docker.com/products/docker-desktop
2. 安装并启动 Docker Desktop

**Linux:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

**macOS:**
```bash
brew install --cask docker
```

## 手动启动（如果脚本失败）

### 启动数据库
```bash
cd server
docker-compose up -d postgres
```

### 启动服务器
```bash
cd server
go run cmd/api/main.go
```

### 启动客户端
```bash
cd application
flutter pub get
flutter run
```

## 故障排除

### 常见问题

**1. "Flutter command not found"**
- 确保 Flutter SDK 已安装并添加到 PATH
- 重启终端/命令提示符

**2. "Go command not found"**
- 确保 Go 已安装并添加到 PATH
- 检查 `go version` 命令是否工作

**3. "Docker command not found"**
- 确保 Docker 已安装并运行
- 在 Windows 上，确保 Docker Desktop 正在运行

**4. 数据库连接失败**
- 确保 Docker 正在运行
- 检查端口 5432 是否被占用
- 尝试重启 Docker 服务

**5. Flutter 应用无法启动**
- 确保有可用的设备（模拟器或真机）
- 运行 `flutter devices` 检查可用设备
- 在 Windows 上，确保已安装 Visual Studio

### 日志查看

启动脚本会显示彩色日志输出：
- 🔍 检查要求
- 🐘 数据库操作
- 🚀 服务器操作
- 📱 客户端操作
- ✅ 成功消息
- ❌ 错误消息

## 开发模式

### 环境变量

服务器使用以下环境变量（可在 `server/.env` 文件中设置）：

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

### 热重载

- **Flutter 客户端**: 支持热重载，修改代码后按 `r` 键
- **Go 服务器**: 需要手动重启

### 停止服务

按 `Ctrl+C` 停止所有服务，脚本会优雅地关闭所有进程。

## Features

- **Cross-platform support**: Web, Android, iOS, Windows, Linux, macOS
- **Image viewing**: Support for JPEG, PNG, WebP formats
- **Video playback**: Support for MP4, WebM formats
- **User authentication**: Secure login/registration system
- **Content management**: Admin panel for content management
- **Comments system**: User comments and interactions
- **Payment integration**: Subscription and payment processing
- **Touch gestures**: Pinch to zoom, pan, swipe navigation
- **Keyboard navigation**: Arrow keys, escape key support
- **Error handling**: Graceful error recovery with retry functionality

## Development

This project follows best practices and includes:
- **Frontend**: Flutter with Provider state management
- **Backend**: Go with Gin web framework
- **Database**: PostgreSQL with migrations
- **Authentication**: JWT-based authentication
- **API**: RESTful API design
- **Testing**: Comprehensive unit and integration tests
- **Documentation**: Detailed technical documentation

## Documentation

See the `docs/` directory for detailed documentation including:
- Architecture specifications
- Product requirements
- User stories and development tasks
- API documentation
- Database schema