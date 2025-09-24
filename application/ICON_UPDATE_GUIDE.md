# ZViewer 应用图标更新指南

## 问题描述
当前应用使用的是默认的Flutter图标，需要更新为ZViewer的logo。

## 解决方案

### 1. 生成PNG图标文件
您需要将 `assets/logo/zviewer-logo.svg` 转换为以下尺寸的PNG文件：

- 16x16.png
- 32x32.png  
- 48x48.png
- 64x64.png
- 128x128.png
- 256x256.png
- 512x512.png

### 2. 使用在线工具转换
推荐使用以下在线工具：
- https://convertio.co/svg-png/
- https://cloudconvert.com/svg-to-png
- https://www.aconvert.com/cn/image/svg-to-png/

### 3. 更新Windows图标
1. 将生成的PNG文件放入 `assets/logo/` 目录
2. 使用在线ICO生成器（如 https://convertio.co/png-ico/）将PNG文件转换为ICO格式
3. 将生成的 `app_icon.ico` 文件替换 `windows/runner/resources/app_icon.ico`

### 4. 更新Android图标
1. 将PNG文件放入 `android/app/src/main/res/` 对应的drawable目录
2. 或者使用 `flutter_launcher_icons` 包自动生成

### 5. 更新iOS图标
1. 将PNG文件放入 `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
2. 或者使用 `flutter_launcher_icons` 包自动生成

## 快速解决方案（推荐）

### 使用 flutter_launcher_icons 包

1. 在 `pubspec.yaml` 中添加依赖：
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

2. 在 `pubspec.yaml` 中添加配置：
```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/logo/zviewer-logo-512.png"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/logo/zviewer-logo-512.png"
    background_color: "#hexcode"
    theme_color: "#hexcode"
  windows:
    generate: true
    image_path: "assets/logo/zviewer-logo-512.png"
    icon_size: 48
```

3. 运行命令：
```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

## 注意事项
- 确保PNG文件背景透明
- 图标应该在不同尺寸下都清晰可见
- 建议使用512x512作为源文件，然后缩放为其他尺寸
