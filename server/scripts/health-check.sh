#!/bin/bash

echo "🏥 运行健康检查..."

# 健康检查函数
check_service() {
    local service_name=$1
    local url=$2
    local max_attempts=10
    local attempt=1

    echo "检查 $service_name..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" > /dev/null 2>&1; then
            echo "✅ $service_name 健康检查通过"
            return 0
        else
            echo "⏳ $service_name 健康检查失败 (尝试 $attempt/$max_attempts)"
            sleep 5
            ((attempt++))
        fi
    done
    
    echo "❌ $service_name 健康检查失败"
    return 1
}

# 检查各个服务
services=(
    "API网关(Kong):http://localhost:8000/health"
    "Consul:http://localhost:8500/v1/status/leader"
    "主服务器:http://localhost:8080/health"
    "媒体服务:http://localhost:8081/api/health"
    "评论服务:http://localhost:8082/api/health"
    "支付服务:http://localhost:8083/api/health"
    "管理服务:http://localhost:8084/api/health"
    "Nginx:http://localhost/health"
    "Prometheus:http://localhost:9090/-/healthy"
    "Grafana:http://localhost:3000/api/health"
)

failed_services=()

for service in "${services[@]}"; do
    IFS=':' read -r name url <<< "$service"
    if ! check_service "$name" "$url"; then
        failed_services+=("$name")
    fi
done

# 输出结果
if [ ${#failed_services[@]} -eq 0 ]; then
    echo "🎉 所有服务健康检查通过！"
    exit 0
else
    echo "❌ 以下服务健康检查失败:"
    for service in "${failed_services[@]}"; do
        echo "  - $service"
    done
    exit 1
fi
