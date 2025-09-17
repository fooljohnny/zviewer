import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zviewer/widgets/multimedia_viewer/gesture_handler.dart';
import 'package:flutter/services.dart';

void main() {
  group('GestureHandler Tests', () {
    testWidgets('should render child widget', (WidgetTester tester) async {
      const testText = 'Test Child Widget';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureHandler(
              child: const Text(testText),
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('should handle keyboard navigation', (WidgetTester tester) async {
      bool previousCalled = false;
      bool nextCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureHandler(
              child: const Text('Test'),
              onPrevious: () {
                previousCalled = true;
              },
              onNext: () {
                nextCalled = true;
              },
            ),
          ),
        ),
      );

      // Simulate left arrow key press
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(previousCalled, isTrue);

      // Reset and simulate right arrow key press
      previousCalled = false;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nextCalled, isTrue);
    });

    testWidgets('should handle pan gestures for navigation', (WidgetTester tester) async {
      bool previousCalled = false;
      bool nextCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureHandler(
              child: const Text('Test'),
              onPrevious: () {
                previousCalled = true;
              },
              onNext: () {
                nextCalled = true;
              },
            ),
          ),
        ),
      );

      // Simulate swipe right (should trigger previous)
      await tester.drag(find.text('Test'), const Offset(100, 0));
      await tester.pump();
      expect(previousCalled, isTrue);

      // Reset and simulate swipe left (should trigger next)
      previousCalled = false;
      await tester.drag(find.text('Test'), const Offset(-100, 0));
      await tester.pump();
      expect(nextCalled, isTrue);
    });
  });
}