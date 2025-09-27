#!/bin/bash

echo "🚀 启动ZViewer开发环境..."

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker"
    exit 1
fi

# 构建镜像
echo "🔨 构建Docker镜像..."
docker-compose -f docker-compose.dev.yml build

# 启动服务
echo "🚀 启动服务..."
docker-compose -f docker-compose.dev.yml up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose -f docker-compose.dev.yml ps

# 运行健康检查
echo "🏥 运行健康检查..."
./scripts/health-check.sh

echo "✅ 开发环境启动完成！"
echo ""
echo "🌐 API网关 (Kong): http://localhost:8000"
echo "🔧 Kong管理界面: http://localhost:8002"
echo "🏛️ Consul UI: http://localhost:8500"
echo ""
echo "📊 监控面板:"
echo "  📈 Grafana: http://localhost:3000 (admin/admin123)"
echo "  🔍 Prometheus: http://localhost:9090"
echo "  📋 Kibana: http://localhost:5601"
echo ""
echo "🔗 直接服务访问:"
echo "  🏠 主服务器: http://localhost:8080"
echo "  🎬 媒体服务: http://localhost:8081"
echo "  💬 评论服务: http://localhost:8082"
echo "  💳 支付服务: http://localhost:8083"
echo "  👑 管理服务: http://localhost:8084"
