#!/usr/bin/env python3
"""
ZViewer 图标生成脚本
将SVG logo转换为PNG格式的应用图标
"""

import os
import sys
from pathlib import Path

def check_dependencies():
    """检查必要的依赖"""
    try:
        import cairosvg
        import PIL
        return True
    except ImportError:
        print("缺少必要的依赖包，请安装：")
        print("pip install cairosvg pillow")
        return False

def generate_png_from_svg(svg_path, png_path, size):
    """将SVG转换为PNG"""
    try:
        import cairosvg
        from PIL import Image
        import io
        
        # 从SVG生成PNG
        png_data = cairosvg.svg2png(url=svg_path, output_width=size, output_height=size)
        
        # 使用PIL优化PNG
        img = Image.open(io.BytesIO(png_data))
        img.save(png_path, 'PNG', optimize=True)
        
        print(f"✓ 生成 {size}x{size} 图标: {png_path}")
        return True
    except Exception as e:
        print(f"✗ 生成 {size}x{size} 图标失败: {e}")
        return False

def main():
    """主函数"""
    print("ZViewer 图标生成器")
    print("=" * 30)
    
    # 检查依赖
    if not check_dependencies():
        return
    
    # 设置路径
    script_dir = Path(__file__).parent
    assets_dir = script_dir / "assets" / "logo"
    svg_file = assets_dir / "zviewer-logo.svg"
    
    # 检查SVG文件是否存在
    if not svg_file.exists():
        print(f"✗ 找不到SVG文件: {svg_file}")
        print("请确保 assets/logo/zviewer-logo.svg 文件存在")
        return
    
    # 需要生成的尺寸
    sizes = [16, 32, 48, 64, 128, 256, 512]
    
    print(f"从 {svg_file} 生成PNG图标...")
    print()
    
    success_count = 0
    for size in sizes:
        png_file = assets_dir / f"zviewer-logo-{size}.png"
        if generate_png_from_svg(svg_file, png_file, size):
            success_count += 1
    
    print()
    print(f"完成！成功生成 {success_count}/{len(sizes)} 个图标文件")
    
    if success_count == len(sizes):
        print()
        print("下一步：")
        print("1. 运行: flutter pub get")
        print("2. 运行: flutter pub run flutter_launcher_icons:main")
        print("3. 重新构建应用: flutter build windows")

if __name__ == "__main__":
    main()
