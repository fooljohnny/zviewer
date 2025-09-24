@echo off
echo ZViewer 图标更新工具
echo ====================

echo.
echo 步骤 1: 安装依赖包...
pip install cairosvg pillow

echo.
echo 步骤 2: 生成PNG图标文件...
python generate_icon.py

echo.
echo 步骤 3: 安装Flutter依赖...
flutter pub get

echo.
echo 步骤 4: 生成应用图标...
flutter pub run flutter_launcher_icons:main

echo.
echo 步骤 5: 清理构建缓存...
flutter clean

echo.
echo 完成！现在可以重新构建应用：
echo flutter build windows
echo.
pause
