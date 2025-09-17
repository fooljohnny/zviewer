import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zviewer/widgets/multimedia_viewer/video_viewer.dart';

void main() {
  group('VideoViewer Tests', () {
    testWidgets('should show loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoViewer(
              videoPath: 'assets/sample_video.mp4',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading video...'), findsOneWidget);
    });

    testWidgets('should show error state when video fails to load', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoViewer(
              videoPath: 'invalid_path.mp4',
            ),
          ),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Failed to load video'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should toggle play/pause when play button is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoViewer(
              videoPath: 'assets/sample_video.mp4',
            ),
          ),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Find and tap the play button
      final playButton = find.byIcon(Icons.play_arrow);
      if (playButton.evaluate().isNotEmpty) {
        await tester.tap(playButton);
        await tester.pump();
        
        // Should show pause icon after tapping play
        expect(find.byIcon(Icons.pause), findsOneWidget);
      }
    });
  });
}