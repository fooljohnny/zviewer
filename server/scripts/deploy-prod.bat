@echo off
echo 🚀 部署ZViewer生产环境...

REM 检查Docker是否运行
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker未运行，请先启动Docker
    exit /b 1
)

REM 检查环境变量文件
if not exist "env.prod" (
    echo ❌ 未找到env.prod文件，请先创建生产环境配置
    exit /b 1
)

REM 构建生产镜像
echo 🔨 构建生产镜像...
docker-compose -f docker-compose.prod.yml build

REM 启动生产服务
echo 🚀 启动生产服务...
docker-compose -f docker-compose.prod.yml up -d

REM 等待服务启动
echo ⏳ 等待服务启动...
timeout /t 60 /nobreak >nul

REM 检查服务状态
echo 🔍 检查服务状态...
docker-compose -f docker-compose.prod.yml ps

REM 运行健康检查
echo 🏥 运行健康检查...
call health-check.bat

echo ✅ 生产环境部署完成！
echo.
echo 🌐 API网关 (Kong): http://localhost:8000
echo 🔧 Kong管理界面: http://localhost:8002
echo 🏛️ Consul UI: http://localhost:8500
echo.
echo 📊 监控面板:
echo   📈 Grafana: http://localhost:3000
echo   🔍 Prometheus: http://localhost:9090
echo   📋 Kibana: http://localhost:5601
echo.
echo 🔗 直接服务访问:
echo   🏠 主服务器: http://localhost:8080
echo   🎬 媒体服务: http://localhost:8081
echo   💬 评论服务: http://localhost:8082
echo   💳 支付服务: http://localhost:8083
echo   👑 管理服务: http://localhost:8084
