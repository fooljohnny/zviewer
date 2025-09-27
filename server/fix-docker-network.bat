@echo off
chcp 65001 >nul
echo Docker Network Fix Script
echo =========================

echo This script will help fix Docker network issues
echo.

echo 1. Stopping all containers...
docker-compose -f docker-compose.dev.yml down

echo 2. Cleaning up Docker network...
docker network prune -f

echo 3. Pulling base images with different mirrors...
echo Trying to pull golang:1.21-alpine...
docker pull golang:1.21-alpine

echo Trying to pull alpine:latest...
docker pull alpine:latest

echo Trying to pull consul:1.16...
docker pull consul:1.16

echo 4. Building images...
docker-compose -f docker-compose.dev.yml build

echo.
echo If images still fail to pull, try these commands:
echo   docker pull registry.cn-hangzhou.aliyuncs.com/library/golang:1.21-alpine
echo   docker pull registry.cn-hangzhou.aliyuncs.com/library/alpine:latest
echo   docker pull registry.cn-hangzhou.aliyuncs.com/library/consul:1.16
echo.
echo Then tag them back:
echo   docker tag registry.cn-hangzhou.aliyuncs.com/library/golang:1.21-alpine golang:1.21-alpine
echo   docker tag registry.cn-hangzhou.aliyuncs.com/library/alpine:latest alpine:latest
echo   docker tag registry.cn-hangzhou.aliyuncs.com/library/consul:1.16 consul:1.16
echo.
pause
