#!/bin/bash

echo "🚀 ZViewer 微服务快速启动脚本"
echo "================================"

# 检查操作系统
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    echo "检测到Windows系统，使用批处理脚本..."
    if [ -f "scripts/deploy-dev.bat" ]; then
        scripts/deploy-dev.bat
    else
        echo "❌ 未找到Windows部署脚本"
        exit 1
    fi
else
    echo "检测到Linux/Mac系统，使用Shell脚本..."
    if [ -f "scripts/deploy-dev.sh" ]; then
        chmod +x scripts/deploy-dev.sh
        ./scripts/deploy-dev.sh
    else
        echo "❌ 未找到Linux/Mac部署脚本"
        exit 1
    fi
fi
