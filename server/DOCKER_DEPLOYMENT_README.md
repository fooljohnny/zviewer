# ZViewer Docker 微服务部署指南

## 概述

本指南介绍如何使用Docker和Docker Compose部署ZViewer的分布式微服务架构。该架构包括服务注册发现、API网关、负载均衡、监控和日志聚合等完整的云原生解决方案。

## 架构组件

### 微服务
- **main-server**: 主服务器，处理用户认证和用户管理
- **media-service**: 媒体服务，处理文件上传和媒体处理
- **comments-service**: 评论服务，处理用户评论
- **payments-service**: 支付服务，处理支付和订阅
- **admin-service**: 管理服务，提供管理功能

### 基础设施
- **PostgreSQL**: 主数据库
- **Redis**: 缓存和会话存储
- **Consul**: 服务注册与发现
- **Kong**: API网关和流量管理
- **Nginx**: 负载均衡和反向代理
- **Prometheus**: 指标收集
- **Grafana**: 监控仪表板
- **ELK Stack**: 日志聚合和分析

## 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- 至少 4GB 可用内存
- 至少 10GB 可用磁盘空间

### 开发环境部署

1. **克隆仓库并进入服务器目录**
   ```bash
   cd server
   ```

2. **启动开发环境**
   ```bash
   # Linux/Mac
   ./scripts/deploy-dev.sh
   
   # Windows
   scripts\deploy-dev.bat
   ```

3. **访问服务**
   - 主API: http://localhost:8000/api/
   - Kong管理界面: http://localhost:8002
   - Consul UI: http://localhost:8500
   - Grafana: http://localhost:3000 (admin/admin123)
   - Prometheus: http://localhost:9090
   - Kibana: http://localhost:5601

### 生产环境部署

1. **配置环境变量**
   ```bash
   cp env.prod.example env.prod
   # 编辑 env.prod 文件，设置生产环境配置
   ```

2. **启动生产环境**
   ```bash
   # Linux/Mac
   ./scripts/deploy-prod.sh
   
   # Windows
   scripts\deploy-prod.bat
   ```

## 详细配置

### 环境变量配置

#### 开发环境 (env.dev)
```env
# 数据库配置
DB_NAME=zviewer
DB_USER=zviewer
DB_PASSWORD=password

# 服务配置
ENVIRONMENT=development
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRATION=24h

# 存储配置
STORAGE_TYPE=local
LOCAL_STORAGE_PATH=./uploads/media

# 监控配置
GRAFANA_PASSWORD=admin123
```

#### 生产环境 (env.prod)
```env
# 数据库配置
DB_NAME=zviewer_prod
DB_USER=zviewer_prod
DB_PASSWORD=your-secure-password

# 服务配置
ENVIRONMENT=production
JWT_SECRET=your-very-secure-jwt-secret
JWT_EXPIRATION=24h

# 存储配置
STORAGE_TYPE=s3
S3_BUCKET=zviewer-media-prod
S3_REGION=us-east-1
S3_ACCESS_KEY=your-access-key
S3_SECRET_KEY=your-secret-key

# 监控配置
GRAFANA_PASSWORD=your-secure-grafana-password
```

### 服务发现配置

Consul服务注册配置位于 `consul/services/` 目录下，每个微服务都有对应的服务定义文件。

### API网关配置

Kong网关配置位于 `kong/kong.yml`，包含：
- 服务路由配置
- 限流策略
- CORS配置
- 监控插件

### 监控配置

#### Prometheus
- 配置文件: `monitoring/prometheus.yml`
- 监控所有微服务的指标
- 支持自定义告警规则

#### Grafana
- 仪表板: `monitoring/grafana/dashboards/`
- 数据源配置: `monitoring/grafana/provisioning/datasources/`
- 自动加载配置

## 运维管理

### 健康检查

运行健康检查脚本：
```bash
# Linux/Mac
./scripts/health-check.sh

# Windows
scripts\health-check.bat
```

### 日志查看

查看特定服务日志：
```bash
docker-compose -f docker-compose.dev.yml logs -f main-server
```

查看所有服务日志：
```bash
docker-compose -f docker-compose.dev.yml logs -f
```

### 服务扩缩容

扩展媒体服务实例：
```bash
docker-compose -f docker-compose.prod.yml up -d --scale media-service=5
```

### 滚动更新

更新服务：
```bash
docker-compose -f docker-compose.prod.yml up -d --no-deps main-server
```

## 故障排除

### 常见问题

1. **服务启动失败**
   - 检查端口是否被占用
   - 查看服务日志: `docker-compose logs service-name`
   - 确认环境变量配置正确

2. **数据库连接失败**
   - 检查PostgreSQL是否正常运行
   - 验证数据库连接字符串
   - 确认网络连接

3. **服务发现失败**
   - 检查Consul是否正常运行
   - 验证服务注册配置
   - 查看Consul日志

4. **API网关问题**
   - 检查Kong配置语法
   - 验证服务路由配置
   - 查看Kong日志

### 性能优化

1. **资源限制**
   - 在docker-compose.prod.yml中调整资源限制
   - 根据实际负载调整副本数量

2. **缓存优化**
   - 配置Redis缓存策略
   - 调整缓存过期时间

3. **数据库优化**
   - 调整PostgreSQL配置
   - 优化查询性能

## 安全考虑

### 生产环境安全

1. **环境变量**
   - 使用强密码
   - 定期轮换密钥
   - 保护敏感信息

2. **网络安全**
   - 配置防火墙规则
   - 使用HTTPS
   - 限制网络访问

3. **容器安全**
   - 使用非root用户运行
   - 定期更新基础镜像
   - 扫描安全漏洞

## 监控和告警

### 关键指标

- 服务可用性
- 响应时间
- 错误率
- 资源使用率
- 数据库性能

### 告警配置

在Grafana中配置告警规则：
- 服务不可用告警
- 响应时间过长告警
- 错误率过高告警
- 资源使用率过高告警

## 备份和恢复

### 数据备份

1. **数据库备份**
   ```bash
   docker exec postgres pg_dump -U zviewer zviewer > backup.sql
   ```

2. **媒体文件备份**
   ```bash
   docker cp media-service:/uploads/media ./backup/media
   ```

### 恢复数据

1. **恢复数据库**
   ```bash
   docker exec -i postgres psql -U zviewer zviewer < backup.sql
   ```

2. **恢复媒体文件**
   ```bash
   docker cp ./backup/media media-service:/uploads/media
   ```

## 扩展和定制

### 添加新服务

1. 创建服务Dockerfile
2. 添加服务定义到docker-compose文件
3. 配置Consul服务注册
4. 添加Kong路由配置
5. 配置监控指标

### 自定义监控

1. 添加Prometheus指标
2. 创建Grafana仪表板
3. 配置告警规则

## 支持和贡献

如有问题或建议，请：
1. 查看日志文件
2. 检查配置是否正确
3. 提交Issue或Pull Request

## 版本历史

- v1.0.0: 初始版本，支持基本微服务部署
- v1.1.0: 添加Kong API网关
- v1.2.0: 添加Consul服务发现
- v1.3.0: 完善监控和日志聚合
