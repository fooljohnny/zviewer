import 'package:flutter/foundation.dart';
import '../models/payment.dart';
import '../models/subscription.dart';
import '../models/payment_method.dart';
import '../services/payment_service.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  // State variables
  bool _isLoading = false;
  String? _error;
  List<Payment> _payments = [];
  List<PaymentMethod> _paymentMethods = [];
  List<Subscription> _subscriptions = [];
  List<SubscriptionPlan> _subscriptionPlans = [];
  Payment? _currentPayment;
  Subscription? _currentSubscription;
  bool _isPaymentGatewayAvailable = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Payment> get payments => _payments;
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  List<Subscription> get subscriptions => _subscriptions;
  List<SubscriptionPlan> get subscriptionPlans => _subscriptionPlans;
  Payment? get currentPayment => _currentPayment;
  Subscription? get currentSubscription => _currentSubscription;
  bool get isPaymentGatewayAvailable => _isPaymentGatewayAvailable;

  // Payment methods
  List<PaymentMethod> get defaultPaymentMethods => 
      _paymentMethods.where((method) => method.isDefault).toList();

  List<PaymentMethod> get cardPaymentMethods => 
      _paymentMethods.where((method) => method.type == PaymentMethodType.card).toList();

  List<PaymentMethod> get nonExpiredPaymentMethods => 
      _paymentMethods.where((method) => !method.isExpired).toList();

  // Subscriptions
  List<Subscription> get activeSubscriptions => 
      _subscriptions.where((sub) => sub.isActive).toList();

  List<Subscription> get expiredSubscriptions => 
      _subscriptions.where((sub) => sub.isExpired).toList();

  // Payments
  List<Payment> get completedPayments => 
      _payments.where((payment) => payment.status == PaymentStatus.completed).toList();

  List<Payment> get failedPayments => 
      _payments.where((payment) => payment.status == PaymentStatus.failed).toList();

  double get totalSpent {
    return completedPayments.fold(0.0, (sum, payment) => sum + payment.amount);
  }

  // Error handling
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Initialize payment system
  Future<void> initialize() async {
    _setLoading(true);
    _setError(null);

    try {
      // Check payment gateway availability
      _isPaymentGatewayAvailable = await _paymentService.isPaymentGatewayAvailable();
      
      // Load initial data
      await Future.wait([
        loadPaymentHistory(),
        loadPaymentMethods(),
        loadSubscriptions(),
        loadSubscriptionPlans(),
      ]);
    } catch (e) {
      _setError('Failed to initialize payment system: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Payment methods
  Future<void> loadPaymentHistory({
    int page = 1,
    int limit = 20,
    PaymentStatus? status,
    PaymentType? type,
  }) async {
    try {
      _setError(null);
      final payments = await _paymentService.getPaymentHistory(
        page: page,
        limit: limit,
        status: status,
        type: type,
      );
      
      if (page == 1) {
        _payments = payments;
      } else {
        _payments.addAll(payments);
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to load payment history: $e');
    }
  }

  Future<void> refreshPaymentHistory() async {
    await loadPaymentHistory();
  }

  Future<Payment?> processPayment({
    required double amount,
    required String currency,
    required String paymentMethodId,
    String? description,
    PaymentType type = PaymentType.oneTime,
    String? subscriptionId,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final payment = await _paymentService.processPayment(
        amount: amount,
        currency: currency,
        paymentMethodId: paymentMethodId,
        description: description,
        type: type,
        subscriptionId: subscriptionId,
      );

      _currentPayment = payment;
      _payments.insert(0, payment); // Add to beginning of list
      notifyListeners();
      return payment;
    } catch (e) {
      _setError('Failed to process payment: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Payment?> getPayment(String paymentId) async {
    try {
      _setError(null);
      final payment = await _paymentService.getPayment(paymentId);
      _currentPayment = payment;
      notifyListeners();
      return payment;
    } catch (e) {
      _setError('Failed to fetch payment: $e');
      return null;
    }
  }

  // Payment methods management
  Future<void> loadPaymentMethods() async {
    try {
      _setError(null);
      final methods = await _paymentService.getPaymentMethods();
      _paymentMethods = methods;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load payment methods: $e');
    }
  }

  Future<PaymentMethod?> savePaymentMethod({
    required PaymentMethodType type,
    required String last4,
    String? brand,
    String? expiryMonth,
    String? expiryYear,
    String? holderName,
    bool isDefault = false,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final method = await _paymentService.savePaymentMethod(
        type: type,
        last4: last4,
        brand: brand,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        holderName: holderName,
        isDefault: isDefault,
      );

      _paymentMethods.add(method);
      notifyListeners();
      return method;
    } catch (e) {
      _setError('Failed to save payment method: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deletePaymentMethod(String paymentMethodId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _paymentService.deletePaymentMethod(paymentMethodId);
      _paymentMethods.removeWhere((method) => method.id == paymentMethodId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete payment method: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Subscription management
  Future<void> loadSubscriptionPlans() async {
    try {
      _setError(null);
      final plans = await _paymentService.getSubscriptionPlans();
      _subscriptionPlans = plans;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load subscription plans: $e');
    }
  }

  Future<void> loadSubscriptions() async {
    try {
      _setError(null);
      final subscriptions = await _paymentService.getSubscriptions();
      _subscriptions = subscriptions;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load subscriptions: $e');
    }
  }

  Future<Subscription?> createSubscription({
    required String planId,
    required String paymentMethodId,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final subscription = await _paymentService.createSubscription(
        planId: planId,
        paymentMethodId: paymentMethodId,
      );

      _currentSubscription = subscription;
      _subscriptions.add(subscription);
      notifyListeners();
      return subscription;
    } catch (e) {
      _setError('Failed to create subscription: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Subscription?> cancelSubscription({
    required String subscriptionId,
    String? reason,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final subscription = await _paymentService.cancelSubscription(
        subscriptionId: subscriptionId,
        reason: reason,
      );

      // Update the subscription in the list
      final index = _subscriptions.indexWhere((sub) => sub.id == subscriptionId);
      if (index != -1) {
        _subscriptions[index] = subscription;
      }
      _currentSubscription = subscription;
      notifyListeners();
      return subscription;
    } catch (e) {
      _setError('Failed to cancel subscription: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Utility methods
  Future<void> checkPaymentGatewayAvailability() async {
    try {
      _isPaymentGatewayAvailable = await _paymentService.isPaymentGatewayAvailable();
      notifyListeners();
    } catch (e) {
      _isPaymentGatewayAvailable = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getPaymentGatewayConfig() async {
    try {
      return await _paymentService.getPaymentGatewayConfig();
    } catch (e) {
      _setError('Failed to fetch payment gateway configuration: $e');
      return null;
    }
  }

  // Reset state
  void reset() {
    _isLoading = false;
    _error = null;
    _payments.clear();
    _paymentMethods.clear();
    _subscriptions.clear();
    _subscriptionPlans.clear();
    _currentPayment = null;
    _currentSubscription = null;
    _isPaymentGatewayAvailable = false;
    notifyListeners();
  }
}
