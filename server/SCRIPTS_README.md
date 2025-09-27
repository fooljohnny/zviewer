# ZViewer 微服务脚本使用指南

## 概述

本目录包含了ZViewer微服务系统的各种管理脚本，支持开发和生产环境的部署、监控和管理。

## 脚本列表

### 快速启动脚本

#### `start.sh` / `start.bat`
一键启动开发环境，自动检测操作系统并使用相应的脚本。

**使用方法:**
```bash
# Linux/Mac
./start.sh

# Windows
start.bat
```

### 部署脚本

#### `scripts/deploy-dev.sh` / `scripts/deploy-dev.bat`
启动开发环境，包含所有微服务和监控组件。

**功能:**
- 构建Docker镜像
- 启动所有服务
- 运行健康检查
- 显示服务访问地址

**使用方法:**
```bash
# Linux/Mac
./scripts/deploy-dev.sh

# Windows
scripts\deploy-dev.bat
```

#### `scripts/deploy-prod.sh` / `scripts/deploy-prod.bat`
启动生产环境，包含完整的监控和日志系统。

**功能:**
- 加载生产环境变量
- 构建生产镜像
- 启动生产服务
- 运行健康检查

**使用方法:**
```bash
# Linux/Mac
./scripts/deploy-prod.sh

# Windows
scripts\deploy-prod.bat
```

### 健康检查脚本

#### `scripts/health-check.sh` / `scripts/health-check.bat`
检查所有服务的健康状态。

**检查的服务:**
- API网关 (Kong)
- Consul服务发现
- 所有微服务
- Nginx负载均衡
- Prometheus监控
- Grafana仪表板

**使用方法:**
```bash
# Linux/Mac
./scripts/health-check.sh

# Windows
scripts\health-check.bat
```

### 服务管理脚本

#### `scripts/manage.sh`
综合服务管理脚本，提供多种管理功能。

**使用方法:**
```bash
# 查看帮助
./scripts/manage.sh

# 启动开发环境
./scripts/manage.sh start dev

# 启动生产环境
./scripts/manage.sh start prod

# 停止服务
./scripts/manage.sh stop dev

# 重启服务
./scripts/manage.sh restart dev

# 查看服务状态
./scripts/manage.sh status dev

# 查看服务日志
./scripts/manage.sh logs main-server

# 运行健康检查
./scripts/manage.sh health

# 清理Docker资源
./scripts/manage.sh clean

# 构建镜像
./scripts/manage.sh build dev
```

## 服务访问地址

### 开发环境

#### API访问
- **API网关 (Kong)**: http://localhost:8000
- **Kong管理界面**: http://localhost:8002
- **Consul UI**: http://localhost:8500

#### 监控面板
- **Grafana**: http://localhost:3000 (admin/admin123)
- **Prometheus**: http://localhost:9090
- **Kibana**: http://localhost:5601

#### 直接服务访问
- **主服务器**: http://localhost:8080
- **媒体服务**: http://localhost:8081
- **评论服务**: http://localhost:8082
- **支付服务**: http://localhost:8083
- **管理服务**: http://localhost:8084

### 生产环境

生产环境的访问地址与开发环境相同，但需要配置相应的环境变量。

## 环境配置

### 开发环境
使用 `env.dev` 文件配置开发环境变量。

### 生产环境
使用 `env.prod` 文件配置生产环境变量。

**重要**: 生产环境部署前，请确保：
1. 修改 `env.prod` 中的密码和密钥
2. 配置正确的数据库连接信息
3. 设置适当的资源限制

## 故障排除

### 常见问题

1. **Docker未运行**
   ```
   ❌ Docker未运行，请先启动Docker
   ```
   解决: 启动Docker Desktop

2. **端口被占用**
   ```
   Error: Port 8080 is already in use
   ```
   解决: 停止占用端口的服务或修改端口配置

3. **服务启动失败**
   ```
   ❌ 主服务器 健康检查失败
   ```
   解决: 查看服务日志 `./scripts/manage.sh logs main-server`

4. **环境变量文件不存在**
   ```
   ❌ 未找到env.prod文件
   ```
   解决: 创建环境变量文件或使用开发环境

### 日志查看

查看特定服务日志：
```bash
# 查看主服务器日志
./scripts/manage.sh logs main-server

# 查看所有服务日志
docker-compose -f docker-compose.dev.yml logs -f
```

### 服务重启

重启特定服务：
```bash
# 重启主服务器
docker-compose -f docker-compose.dev.yml restart main-server

# 重启所有服务
./scripts/manage.sh restart dev
```

## 最佳实践

1. **开发环境**
   - 使用 `start.sh` 快速启动
   - 定期运行健康检查
   - 使用 `manage.sh` 管理服务

2. **生产环境**
   - 配置强密码和密钥
   - 设置资源限制
   - 定期备份数据
   - 监控服务状态

3. **维护**
   - 定期清理Docker资源
   - 更新镜像版本
   - 监控日志文件大小

## 支持

如有问题，请：
1. 查看服务日志
2. 运行健康检查
3. 检查Docker状态
4. 查看相关文档
