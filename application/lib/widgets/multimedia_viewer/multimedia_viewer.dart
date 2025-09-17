import 'package:flutter/material.dart';
import 'image_viewer.dart';
import 'video_viewer.dart';

class MultimediaViewer extends StatelessWidget {
  final String mediaPath;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const MultimediaViewer({
    super.key,
    required this.mediaPath,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if the file is an image or video based on extension
    final extension = mediaPath.toLowerCase().split('.').last;
    final isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(extension);
    final isVideo = ['mp4', 'webm'].contains(extension);

    if (isImage) {
      return ImageViewer(
        imagePath: mediaPath,
        onPrevious: onPrevious,
        onNext: onNext,
      );
    } else if (isVideo) {
      return VideoViewer(
        videoPath: mediaPath,
        onPrevious: onPrevious,
        onNext: onNext,
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Unsupported media format',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Supported formats: JPG, PNG, WebP, MP4, WebM',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }
}
