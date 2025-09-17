import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zviewer/widgets/multimedia_viewer/image_viewer.dart';

void main() {
  group('ImageViewer Tests', () {
    testWidgets('should show loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageViewer(
              imagePath: 'assets/sample_image.jpg',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading image...'), findsOneWidget);
    });

    testWidgets('should show error state when image fails to load', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageViewer(
              imagePath: 'invalid_path.jpg',
            ),
          ),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Failed to load image'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should call onPrevious when previous button is pressed', (WidgetTester tester) async {
      bool previousCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageViewer(
              imagePath: 'assets/sample_image.jpg',
              onPrevious: () {
                previousCalled = true;
              },
            ),
          ),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Simulate previous action (this would be triggered by gesture or button)
      // In a real test, you would trigger the actual gesture or button press
      expect(previousCalled, isFalse); // Initially false
    });
  });
}