import 'package:flutter_test/flutter_test.dart';
import 'package:zviewer/models/payment.dart';
import 'package:zviewer/models/subscription.dart';
import 'package:zviewer/models/payment_method.dart';

void main() {
  group('Payment Models', () {
    group('Payment', () {
      test('should create payment with required fields', () {
        // Arrange
        final payment = Payment(
          id: 'payment_123',
          userId: 'user_123',
          amount: 99.99,
          currency: 'USD',
          status: PaymentStatus.completed,
          type: PaymentType.oneTime,
          createdAt: DateTime(2024, 1, 1),
        );

        // Assert
        expect(payment.id, equals('payment_123'));
        expect(payment.userId, equals('user_123'));
        expect(payment.amount, equals(99.99));
        expect(payment.currency, equals('USD'));
        expect(payment.status, equals(PaymentStatus.completed));
        expect(payment.type, equals(PaymentType.oneTime));
        expect(payment.createdAt, equals(DateTime(2024, 1, 1)));
      });

      test('should create payment with optional fields', () {
        // Arrange
        final payment = Payment(
          id: 'payment_123',
          userId: 'user_123',
          amount: 99.99,
          currency: 'USD',
          status: PaymentStatus.completed,
          type: PaymentType.oneTime,
          createdAt: DateTime(2024, 1, 1),
          description: 'Test payment',
          subscriptionId: 'sub_123',
          transactionId: 'txn_123',
          paymentMethodId: 'method_123',
          updatedAt: DateTime(2024, 1, 2),
        );

        // Assert
        expect(payment.description, equals('Test payment'));
        expect(payment.subscriptionId, equals('sub_123'));
        expect(payment.transactionId, equals('txn_123'));
        expect(payment.paymentMethodId, equals('method_123'));
        expect(payment.updatedAt, equals(DateTime(2024, 1, 2)));
      });

      test('should support copyWith method', () {
        // Arrange
        final originalPayment = Payment(
          id: 'payment_123',
          userId: 'user_123',
          amount: 99.99,
          currency: 'USD',
          status: PaymentStatus.pending,
          type: PaymentType.oneTime,
          createdAt: DateTime(2024, 1, 1),
        );

        // Act
        final updatedPayment = originalPayment.copyWith(
          status: PaymentStatus.completed,
          amount: 149.99,
        );

        // Assert
        expect(updatedPayment.id, equals(originalPayment.id));
        expect(updatedPayment.status, equals(PaymentStatus.completed));
        expect(updatedPayment.amount, equals(149.99));
        expect(updatedPayment.currency, equals(originalPayment.currency));
      });

      test('should support equality comparison', () {
        // Arrange
        final payment1 = Payment(
          id: 'payment_123',
          userId: 'user_123',
          amount: 99.99,
          currency: 'USD',
          status: PaymentStatus.completed,
          type: PaymentType.oneTime,
          createdAt: DateTime(2024, 1, 1),
        );

        final payment2 = Payment(
          id: 'payment_123',
          userId: 'user_456',
          amount: 199.99,
          currency: 'EUR',
          status: PaymentStatus.pending,
          type: PaymentType.subscription,
          createdAt: DateTime(2024, 2, 1),
        );

        // Assert
        expect(payment1, equals(payment2)); // Same ID
        expect(payment1.hashCode, equals(payment2.hashCode));
      });
    });

    group('Subscription', () {
      test('should create subscription with required fields', () {
        // Arrange
        final subscription = Subscription(
          id: 'sub_123',
          userId: 'user_123',
          planId: 'plan_123',
          status: SubscriptionStatus.active,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 2, 1),
          price: 29.99,
          currency: 'USD',
          createdAt: DateTime(2024, 1, 1),
        );

        // Assert
        expect(subscription.id, equals('sub_123'));
        expect(subscription.userId, equals('user_123'));
        expect(subscription.planId, equals('plan_123'));
        expect(subscription.status, equals(SubscriptionStatus.active));
        expect(subscription.price, equals(29.99));
        expect(subscription.currency, equals('USD'));
      });

      test('should identify active subscription', () {
        // Arrange
        final activeSubscription = Subscription(
          id: 'sub_123',
          userId: 'user_123',
          planId: 'plan_123',
          status: SubscriptionStatus.active,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
          price: 29.99,
          currency: 'USD',
          createdAt: DateTime(2024, 1, 1),
        );

        // Assert
        expect(activeSubscription.isActive, isTrue);
        expect(activeSubscription.isExpired, isFalse);
        expect(activeSubscription.isCancelled, isFalse);
      });

      test('should identify expired subscription', () {
        // Arrange
        final expiredSubscription = Subscription(
          id: 'sub_123',
          userId: 'user_123',
          planId: 'plan_123',
          status: SubscriptionStatus.expired,
          startDate: DateTime(2023, 1, 1),
          endDate: DateTime(2023, 12, 31),
          price: 29.99,
          currency: 'USD',
          createdAt: DateTime(2023, 1, 1),
        );

        // Assert
        expect(expiredSubscription.isActive, isFalse);
        expect(expiredSubscription.isExpired, isTrue);
        expect(expiredSubscription.isCancelled, isFalse);
      });

      test('should calculate remaining duration', () {
        // Arrange
        final futureDate = DateTime.now().add(const Duration(days: 30));
        final subscription = Subscription(
          id: 'sub_123',
          userId: 'user_123',
          planId: 'plan_123',
          status: SubscriptionStatus.active,
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: futureDate,
          price: 29.99,
          currency: 'USD',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        );

        // Act
        final remaining = subscription.remainingDuration;

        // Assert
        expect(remaining.inDays, greaterThan(25));
        expect(remaining.inDays, lessThan(35));
      });
    });

    group('SubscriptionPlan', () {
      test('should create subscription plan with required fields', () {
        // Arrange
        final plan = SubscriptionPlan(
          id: 'plan_123',
          name: 'Premium Plan',
          description: 'Premium features',
          price: 29.99,
          currency: 'USD',
          interval: 'monthly',
          features: ['Feature 1', 'Feature 2'],
          createdAt: DateTime(2024, 1, 1),
        );

        // Assert
        expect(plan.id, equals('plan_123'));
        expect(plan.name, equals('Premium Plan'));
        expect(plan.description, equals('Premium features'));
        expect(plan.price, equals(29.99));
        expect(plan.currency, equals('USD'));
        expect(plan.interval, equals('monthly'));
        expect(plan.features, equals(['Feature 1', 'Feature 2']));
        expect(plan.isPopular, isFalse);
      });

      test('should format price correctly for monthly plan', () {
        // Arrange
        final monthlyPlan = SubscriptionPlan(
          id: 'plan_123',
          name: 'Monthly Plan',
          description: 'Monthly subscription',
          price: 29.99,
          currency: 'USD',
          interval: 'monthly',
          features: [],
          createdAt: DateTime(2024, 1, 1),
        );

        // Assert
        expect(monthlyPlan.formattedPrice, equals('USD 29.99/monthly'));
      });

      test('should format price correctly for lifetime plan', () {
        // Arrange
        final lifetimePlan = SubscriptionPlan(
          id: 'plan_123',
          name: 'Lifetime Plan',
          description: 'One-time payment',
          price: 299.99,
          currency: 'USD',
          interval: 'lifetime',
          features: [],
          createdAt: DateTime(2024, 1, 1),
        );

        // Assert
        expect(lifetimePlan.formattedPrice, equals('USD 299.99'));
      });
    });

    group('PaymentMethod', () {
      test('should create payment method with required fields', () {
        // Arrange
        final paymentMethod = PaymentMethod(
          id: 'method_123',
          userId: 'user_123',
          type: PaymentMethodType.card,
          last4: '1234',
          createdAt: DateTime(2024, 1, 1),
        );

        // Assert
        expect(paymentMethod.id, equals('method_123'));
        expect(paymentMethod.userId, equals('user_123'));
        expect(paymentMethod.type, equals(PaymentMethodType.card));
        expect(paymentMethod.last4, equals('1234'));
        expect(paymentMethod.isDefault, isFalse);
      });

      test('should create payment method with optional fields', () {
        // Arrange
        final paymentMethod = PaymentMethod(
          id: 'method_123',
          userId: 'user_123',
          type: PaymentMethodType.card,
          last4: '1234',
          brand: 'Visa',
          isDefault: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
          expiryMonth: '12',
          expiryYear: '2025',
          holderName: 'John Doe',
        );

        // Assert
        expect(paymentMethod.brand, equals('Visa'));
        expect(paymentMethod.isDefault, isTrue);
        expect(paymentMethod.updatedAt, equals(DateTime(2024, 1, 2)));
        expect(paymentMethod.expiryMonth, equals('12'));
        expect(paymentMethod.expiryYear, equals('2025'));
        expect(paymentMethod.holderName, equals('John Doe'));
      });

      test('should generate display name for card', () {
        // Arrange
        final cardMethod = PaymentMethod(
          id: 'method_123',
          userId: 'user_123',
          type: PaymentMethodType.card,
          last4: '1234',
          brand: 'Visa',
          createdAt: DateTime(2024, 1, 1),
        );

        // Assert
        expect(cardMethod.displayName, equals('Visa •••• 1234'));
      });

      test('should generate display name for PayPal', () {
        // Arrange
        final paypalMethod = PaymentMethod(
          id: 'method_123',
          userId: 'user_123',
          type: PaymentMethodType.paypal,
          last4: '0000',
          createdAt: DateTime(2024, 1, 1),
        );

        // Assert
        expect(paypalMethod.displayName, equals('PayPal'));
      });

      test('should generate masked number for card', () {
        // Arrange
        final cardMethod = PaymentMethod(
          id: 'method_123',
          userId: 'user_123',
          type: PaymentMethodType.card,
          last4: '1234',
          createdAt: DateTime(2024, 1, 1),
        );

        // Assert
        expect(cardMethod.maskedNumber, equals('•••• •••• •••• 1234'));
      });

      test('should identify expired card', () {
        // Arrange
        final expiredCard = PaymentMethod(
          id: 'method_123',
          userId: 'user_123',
          type: PaymentMethodType.card,
          last4: '1234',
          expiryMonth: '01',
          expiryYear: '2020',
          createdAt: DateTime(2024, 1, 1),
        );

        // Assert
        expect(expiredCard.isExpired, isTrue);
      });

      test('should identify non-expired card', () {
        // Arrange
        final futureYear = DateTime.now().year + 1;
        final validCard = PaymentMethod(
          id: 'method_123',
          userId: 'user_123',
          type: PaymentMethodType.card,
          last4: '1234',
          expiryMonth: '12',
          expiryYear: futureYear.toString(),
          createdAt: DateTime(2024, 1, 1),
        );

        // Assert
        expect(validCard.isExpired, isFalse);
      });
    });
  });
}
