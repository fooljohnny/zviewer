import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zviewer/widgets/payments/payment_screen.dart';
import 'package:zviewer/providers/payment_provider.dart';
import 'package:zviewer/providers/auth_provider.dart';

import 'payment_screen_test.mocks.dart';

@GenerateMocks([PaymentProvider, AuthProvider])
void main() {
  group('PaymentScreen', () {
    late MockPaymentProvider mockPaymentProvider;
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockPaymentProvider = MockPaymentProvider();
      mockAuthProvider = MockAuthProvider();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<PaymentProvider>.value(value: mockPaymentProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ],
        child: const MaterialApp(
          home: PaymentScreen(),
        ),
      );
    }

    testWidgets('should show login prompt when user is not authenticated', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isAuthenticated).thenReturn(false);
      when(mockPaymentProvider.isLoading).thenReturn(false);
      when(mockPaymentProvider.subscriptionPlans).thenReturn([]);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Please log in to access payments'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('should show payment gateway unavailable message when gateway is not available', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockPaymentProvider.isPaymentGatewayAvailable).thenReturn(false);
      when(mockPaymentProvider.isLoading).thenReturn(false);
      when(mockPaymentProvider.subscriptionPlans).thenReturn([]);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Payment system is currently unavailable'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should show error message when there is an error', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockPaymentProvider.isPaymentGatewayAvailable).thenReturn(true);
      when(mockPaymentProvider.error).thenReturn('Test error message');
      when(mockPaymentProvider.isLoading).thenReturn(false);
      when(mockPaymentProvider.subscriptionPlans).thenReturn([]);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Error: Test error message'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should show tab bar when everything is working correctly', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockPaymentProvider.isPaymentGatewayAvailable).thenReturn(true);
      when(mockPaymentProvider.error).thenReturn(null);
      when(mockPaymentProvider.subscriptionPlans).thenReturn([]);
      when(mockPaymentProvider.isLoading).thenReturn(false);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Plans'), findsOneWidget);
      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.byIcon(Icons.subscriptions), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.payment), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.history), findsAtLeastNWidgets(1));
    });

    testWidgets('should call initialize when refresh button is pressed', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockPaymentProvider.isPaymentGatewayAvailable).thenReturn(true);
      when(mockPaymentProvider.error).thenReturn(null);
      when(mockPaymentProvider.isLoading).thenReturn(false);
      when(mockPaymentProvider.subscriptionPlans).thenReturn([]);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Assert
      verify(mockPaymentProvider.initialize()).called(2); // Once on init, once on refresh
    });

    testWidgets('should show loading indicator when loading', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockPaymentProvider.isPaymentGatewayAvailable).thenReturn(true);
      when(mockPaymentProvider.error).thenReturn(null);
      when(mockPaymentProvider.isLoading).thenReturn(true);
      when(mockPaymentProvider.subscriptionPlans).thenReturn([]);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });
  });
}
