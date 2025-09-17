import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'gesture_handler.dart';

class ImageViewer extends StatefulWidget {
  final String imagePath;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const ImageViewer({
    super.key,
    required this.imagePath,
    this.onPrevious,
    this.onNext,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  final PhotoViewController _photoViewController = PhotoViewController();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Simulate loading time for demonstration
      await Future.delayed(const Duration(milliseconds: 500));
      
      // In a real implementation, you would load the actual image
      // For now, we'll assume the image loads successfully
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading image...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load image',
              style: TextStyle(fontSize: 18),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadImage,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return GestureHandler(
      onPrevious: widget.onPrevious,
      onNext: widget.onNext,
      child: PhotoView(
        controller: _photoViewController,
        imageProvider: AssetImage(widget.imagePath),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2.0,
        enableRotation: true,
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error loading image',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    super.dispose();
  }
}
