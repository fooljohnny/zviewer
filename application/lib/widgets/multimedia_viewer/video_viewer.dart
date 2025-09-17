import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'gesture_handler.dart';

class VideoViewer extends StatefulWidget {
  final String videoPath;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const VideoViewer({
    super.key,
    required this.videoPath,
    this.onPrevious,
    this.onNext,
  });

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      _controller = VideoPlayerController.asset(widget.videoPath);
      await _controller!.initialize();
      
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
            Text('Loading video...'),
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
              'Failed to load video',
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
              onPressed: _initializeVideo,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: GestureHandler(
        onPrevious: widget.onPrevious,
        onNext: widget.onNext,
        child: Stack(
          children: [
            Center(
              child: _controller != null
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                  : const CircularProgressIndicator(),
            ),
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_controller != null)
                        VideoProgressIndicator(
                          _controller!,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.white,
                            bufferedColor: Colors.grey,
                            backgroundColor: Colors.black26,
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: _controller != null ? () {
                              setState(() {
                                if (_controller!.value.isPlaying) {
                                  _controller!.pause();
                                } else {
                                  _controller!.play();
                                }
                              });
                            } : null,
                            icon: Icon(
                              _controller?.value.isPlaying == true
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: _controller != null ? () {
                              final currentPosition = _controller!.value.position;
                              final newPosition = currentPosition - const Duration(seconds: 10);
                              _controller!.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
                            } : null,
                            icon: const Icon(Icons.replay_10, color: Colors.white),
                          ),
                          IconButton(
                            onPressed: _controller != null ? () {
                              final currentPosition = _controller!.value.position;
                              final duration = _controller!.value.duration;
                              final newPosition = currentPosition + const Duration(seconds: 10);
                              _controller!.seekTo(newPosition > duration ? duration : newPosition);
                            } : null,
                            icon: const Icon(Icons.forward_10, color: Colors.white),
                          ),
                          Text(
                            _controller != null 
                                ? '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}'
                                : '00:00 / 00:00',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
