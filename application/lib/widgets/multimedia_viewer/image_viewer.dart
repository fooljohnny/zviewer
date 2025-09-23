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
      
      // Check if the asset exists by trying to load it
      // For demo purposes, we'll simulate a missing image scenario
      // In a real app, you would check if the file exists first
      setState(() {
        _isLoading = false;
        _hasError = true; // Simulate no image available
        _errorMessage = 'No image available';
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
      // Check if it's a "no image available" scenario
      final isNoImage = _errorMessage == 'No image available';
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNoImage ? Icons.image_not_supported : Icons.error,
              size: 64,
              color: isNoImage ? Colors.grey[400] : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              isNoImage ? 'No Image Available' : 'Failed to load image',
              style: TextStyle(
                fontSize: 18,
                color: isNoImage ? Colors.grey[600] : Colors.red[700],
              ),
            ),
            if (_errorMessage != null && !isNoImage) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            if (isNoImage) ...[
              const SizedBox(height: 8),
              Text(
                'This media item doesn\'t have an image to display',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (!isNoImage) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadImage,
                child: const Text('Retry'),
              ),
            ],
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
