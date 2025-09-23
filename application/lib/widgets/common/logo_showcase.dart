import 'package:flutter/material.dart';
import 'zviewer_logo.dart';

/// Logo展示页面
/// 用于展示不同尺寸和变体的ZViewer Logo
class LogoShowcase extends StatelessWidget {
  const LogoShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZViewer Logo Showcase'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1C1C1E),
              Color(0xFF2C2C2E),
              Color(0xFF3A3A3C),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                '标准尺寸 Logo',
                [
                  const ZViewerLogoSmall(),
                  const ZViewerLogoMedium(),
                  const ZViewerLogoLarge(),
                ],
              ),
              const SizedBox(height: 32),
              _buildSection(
                '不同变体',
                [
                  const ZViewerLogo(
                    size: 64,
                    variant: ZViewerLogoVariant.standard,
                  ),
                  const ZViewerLogo(
                    size: 64,
                    variant: ZViewerLogoVariant.dark,
                  ),
                  const ZViewerLogo(
                    size: 64,
                    variant: ZViewerLogoVariant.monochrome,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSection(
                '动画效果',
                [
                  const ZViewerLogoAnimated(size: 64),
                  const ZViewerLogoAnimated(
                    size: 64,
                    variant: ZViewerLogoVariant.dark,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSection(
                '自定义尺寸',
                [
                  const ZViewerLogo(size: 24),
                  const ZViewerLogo(size: 48),
                  const ZViewerLogo(size: 96),
                  const ZViewerLogo(size: 160),
                ],
              ),
              const SizedBox(height: 32),
              _buildUsageExample(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: children,
        ),
      ],
    );
  }

  Widget _buildUsageExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '使用示例',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Flutter代码示例:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '''// 标准logo
ZViewerLogo(size: 64.0)

// 小尺寸logo
ZViewerLogoSmall()

// 动画logo
ZViewerLogoAnimated(size: 64.0)

// 深色变体
ZViewerLogo(
  size: 64.0,
  variant: ZViewerLogoVariant.dark,
)''',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
