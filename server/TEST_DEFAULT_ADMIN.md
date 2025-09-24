# 默认管理员账号测试说明

## 概述
系统已添加默认管理员账号，账号信息如下：
- **邮箱**: admin@zviewer.local
- **密码**: admin123
- **角色**: admin

## 实现方式
通过数据库迁移文件 `002_insert_default_admin.sql` 自动创建默认管理员账号。

## 测试步骤

### 1. 启动数据库
```bash
# 启动Docker Desktop，然后运行：
docker-compose up -d postgres
```

### 2. 启动服务器
```bash
# 在server目录下运行：
go run cmd/api/main.go
```

### 3. 测试登录
使用以下方式测试默认管理员登录：

#### 使用curl测试：
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@zviewer.local", "password": "admin123"}'
```

#### 使用PowerShell测试：
```powershell
$body = @{
    email = "admin@zviewer.local"
    password = "admin123"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method POST -Body $body -ContentType "application/json"
```

### 4. 验证管理员权限
登录成功后，可以使用返回的token访问需要管理员权限的接口。

## 迁移文件说明
- `001_create_users_table.sql`: 创建用户表
- `002_insert_default_admin.sql`: 插入默认管理员账号

迁移文件会在服务器启动时自动执行，确保默认管理员账号被创建。

## 安全注意事项
⚠️ **重要**: 在生产环境中，请务必：
1. 修改默认管理员密码
2. 删除或禁用默认管理员账号
3. 使用强密码策略

## 故障排除
如果默认管理员账号无法登录，请检查：
1. 数据库是否正确启动
2. 迁移文件是否正确执行
3. 服务器日志中是否有错误信息
