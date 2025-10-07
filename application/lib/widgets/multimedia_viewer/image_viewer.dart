import 'dart:io';
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
      // Check if the file path is valid
      if (widget.imagePath.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'No image path provided';
        });
        return;
      }

      // For now, we'll assume the image can be loaded
      // In a real implementation, you might want to check if the file exists
      setState(() {
        _isLoading = false;
        _hasError = false;
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
        imageProvider: _getImageProvider(),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2.0,
        enableRotation: true,
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
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

  ImageProvider _getImageProvider() {
    // Check if the path is a network URL
    if (widget.imagePath.startsWith('http://') || widget.imagePath.startsWith('https://')) {
      return NetworkImage(widget.imagePath);
    }
    // Check if the path is an asset
    else if (widget.imagePath.startsWith('assets/')) {
      return AssetImage(widget.imagePath);
    }
    // Otherwise, treat as a file path
    else {
      return FileImage(File(widget.imagePath));
    }
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    super.dispose();
  }
}
