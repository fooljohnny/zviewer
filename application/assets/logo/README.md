# ZViewer Logo Assets

这个目录包含了ZViewer应用的所有logo资源文件。

## 文件结构

```
logo/
├── zviewer-logo.svg              # 标准SVG版本 (64x64)
├── zviewer-logo-32.svg           # 小尺寸SVG (32x32)
├── zviewer-logo-128.svg          # 大尺寸SVG (128x128)
├── zviewer-logo-dark.svg         # 深色背景版本
├── zviewer-logo-monochrome.svg   # 单色版本
├── app_icon_config.json          # 应用图标配置
└── README.md                     # 本文件
```

## 设计规范

### 毛玻璃效果
- **背景**: `rgba(255, 255, 255, 0.15)`
- **边框**: `rgba(255, 255, 255, 0.3)`
- **模糊**: `blur(20px)`
- **阴影**: `0 8px 32px rgba(0, 0, 0, 0.1)`

### 色彩方案
- **主色调**: iOS Blue (#007AFF)
- **次要色**: iOS Purple (#5856D6)  
- **强调色**: iOS Orange (#FF9500)
- **文字**: `rgba(255, 255, 255, 0.9)`

### 尺寸规格
- **小尺寸**: 32x32px (导航栏、小UI元素)
- **标准尺寸**: 64x64px (主要应用图标)
- **大尺寸**: 128x128px (启动画面、大UI元素)
- **超大尺寸**: 512x512px (应用商店、高分辨率显示)

## 使用方式

### Flutter组件
```dart
import 'package:zviewer/widgets/common/zviewer_logo.dart';

// 标准logo
ZViewerLogo(size: 64.0)

// 小尺寸logo
ZViewerLogoSmall()

// 大尺寸logo  
ZViewerLogoLarge()

// 动画logo
ZViewerLogoAnimated(size: 64.0)

// 不同变体
ZViewerLogo(
  size: 64.0,
  variant: ZViewerLogoVariant.dark, // 深色背景版本
)

ZViewerLogo(
  size: 64.0,
  variant: ZViewerLogoVariant.monochrome, // 单色版本
)
```

### 直接使用SVG
```dart
SvgPicture.asset(
  'assets/logo/zviewer-logo.svg',
  width: 64,
  height: 64,
)
```

## 变体说明

### 标准版本 (zviewer-logo.svg)
- 适用于深色背景
- 使用白色毛玻璃效果
- 适合应用内主要使用场景

### 深色版本 (zviewer-logo-dark.svg)
- 适用于浅色背景
- 使用深色毛玻璃效果
- 适合浅色主题或印刷材料

### 单色版本 (zviewer-logo-monochrome.svg)
- 纯色设计
- 适用于单色印刷
- 可自定义颜色

## 应用图标生成

### Android
使用 `flutter_launcher_icons` 包：
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  image_path: "assets/logo/zviewer-logo-512.png"
  adaptive_icon_background: "#007AFF"
  adaptive_icon_foreground: "assets/logo/zviewer-logo-512.png"
```

### iOS
将 `zviewer-logo-512.png` 放入 `ios/Runner/Assets.xcassets/AppIcon.appiconset/` 目录

### Windows
将 `zviewer-logo-256.png` 转换为 `.ico` 格式用于Windows应用图标

## 注意事项

1. **版权**: 所有logo文件均为ZViewer项目专有设计
2. **修改**: 如需修改设计，请保持毛玻璃美学风格的一致性
3. **尺寸**: 使用SVG格式确保在所有尺寸下都保持清晰
4. **性能**: 在Flutter中使用BackdropFilter时注意性能影响
5. **可访问性**: 确保logo在各种背景下都有足够的对比度

## 更新日志

- **v1.0.0** (2024-01-XX): 初始版本，包含毛玻璃风格设计
