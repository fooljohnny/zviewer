@echo off
REM Kong微服务架构启动脚本
REM 这个脚本启动完整的分布式微服务架构，使用Kong作为API网关

echo 🚀 启动ZViewer Kong微服务架构...
echo.

REM 检查Docker是否运行
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker未运行。请先启动Docker Desktop。
    pause
    exit /b 1
)

echo 📋 架构组件:
echo    - Kong API网关 (端口 8000)
echo    - PostgreSQL数据库 (端口 5432)
echo    - Redis缓存
echo    - Consul服务发现 (端口 8500)
echo    - 主API服务 (内部端口 8080)
echo    - 媒体服务 (内部端口 8081)
echo    - 评论服务 (内部端口 8082)
echo    - 支付服务 (内部端口 8083)
echo    - 管理服务 (内部端口 8084)
echo    - Prometheus监控 (端口 9090)
echo    - Grafana仪表板 (端口 3000)
echo.

echo 🔧 启动微服务架构...
docker-compose -f docker-compose.kong.yml up -d

echo.
echo ⏳ 等待服务启动...
timeout /t 10 /nobreak >nul

echo.
echo 🌐 服务访问地址:
echo    Kong网关: http://localhost:8000
echo    Kong管理: http://localhost:8001
echo    Consul: http://localhost:8500
echo    Prometheus: http://localhost:9090
echo    Grafana: http://localhost:3000
echo.

echo 📊 检查服务状态...
docker-compose -f docker-compose.kong.yml ps

echo.
echo ✅ Kong微服务架构启动完成！
echo.
echo 💡 使用以下命令管理服务:
echo   停止: docker-compose -f docker-compose.kong.yml down
echo   日志: docker-compose -f docker-compose.kong.yml logs -f
echo   重启: docker-compose -f docker-compose.kong.yml restart
echo.

pause
