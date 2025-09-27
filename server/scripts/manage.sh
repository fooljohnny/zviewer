#!/bin/bash

# ZViewer 微服务管理脚本

show_help() {
    echo "ZViewer 微服务管理脚本"
    echo ""
    echo "用法: $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  start [dev|prod]     启动服务 (开发环境或生产环境)"
    echo "  stop [dev|prod]      停止服务"
    echo "  restart [dev|prod]   重启服务"
    echo "  status [dev|prod]    查看服务状态"
    echo "  logs [service]       查看服务日志"
    echo "  health               运行健康检查"
    echo "  clean                清理未使用的Docker资源"
    echo "  build [dev|prod]     构建镜像"
    echo ""
    echo "示例:"
    echo "  $0 start dev         启动开发环境"
    echo "  $0 logs main-server  查看主服务器日志"
    echo "  $0 health            运行健康检查"
}

start_services() {
    local env=$1
    if [ "$env" = "dev" ]; then
        echo "🚀 启动开发环境..."
        docker-compose -f docker-compose.dev.yml up -d
    elif [ "$env" = "prod" ]; then
        echo "🚀 启动生产环境..."
        docker-compose -f docker-compose.prod.yml up -d
    else
        echo "❌ 请指定环境: dev 或 prod"
        exit 1
    fi
}

stop_services() {
    local env=$1
    if [ "$env" = "dev" ]; then
        echo "🛑 停止开发环境..."
        docker-compose -f docker-compose.dev.yml down
    elif [ "$env" = "prod" ]; then
        echo "🛑 停止生产环境..."
        docker-compose -f docker-compose.prod.yml down
    else
        echo "❌ 请指定环境: dev 或 prod"
        exit 1
    fi
}

restart_services() {
    local env=$1
    echo "🔄 重启服务..."
    stop_services $env
    sleep 5
    start_services $env
}

show_status() {
    local env=$1
    if [ "$env" = "dev" ]; then
        echo "📊 开发环境状态:"
        docker-compose -f docker-compose.dev.yml ps
    elif [ "$env" = "prod" ]; then
        echo "📊 生产环境状态:"
        docker-compose -f docker-compose.prod.yml ps
    else
        echo "📊 所有服务状态:"
        docker-compose -f docker-compose.dev.yml ps
        echo ""
        docker-compose -f docker-compose.prod.yml ps
    fi
}

show_logs() {
    local service=$1
    if [ -z "$service" ]; then
        echo "❌ 请指定服务名称"
        echo "可用服务: main-server, media-service, comments-service, payments-service, admin-service, consul, kong, nginx, prometheus, grafana"
        exit 1
    fi
    
    echo "📋 查看 $service 日志..."
    docker-compose -f docker-compose.dev.yml logs -f $service
}

run_health_check() {
    echo "🏥 运行健康检查..."
    ./scripts/health-check.sh
}

clean_docker() {
    echo "🧹 清理Docker资源..."
    docker system prune -f
    docker volume prune -f
    echo "✅ 清理完成"
}

build_images() {
    local env=$1
    if [ "$env" = "dev" ]; then
        echo "🔨 构建开发环境镜像..."
        docker-compose -f docker-compose.dev.yml build
    elif [ "$env" = "prod" ]; then
        echo "🔨 构建生产环境镜像..."
        docker-compose -f docker-compose.prod.yml build
    else
        echo "🔨 构建所有镜像..."
        docker-compose -f docker-compose.dev.yml build
        docker-compose -f docker-compose.prod.yml build
    fi
}

# 主逻辑
case "$1" in
    start)
        start_services $2
        ;;
    stop)
        stop_services $2
        ;;
    restart)
        restart_services $2
        ;;
    status)
        show_status $2
        ;;
    logs)
        show_logs $2
        ;;
    health)
        run_health_check
        ;;
    clean)
        clean_docker
        ;;
    build)
        build_images $2
        ;;
    *)
        show_help
        ;;
esac
