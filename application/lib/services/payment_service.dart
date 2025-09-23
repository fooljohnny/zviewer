import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/payment.dart';
import '../models/subscription.dart';
import '../models/payment_method.dart';
import '../config/api_config.dart';

class PaymentService {
  static String get _baseUrl => ApiConfig.paymentsUrl;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  // Payment processing
  Future<Payment> processPayment({
    required double amount,
    required String currency,
    required String paymentMethodId,
    String? description,
    PaymentType type = PaymentType.oneTime,
    String? subscriptionId,
  }) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          'paymentMethodId': paymentMethodId,
          'description': description,
          'type': type.name,
          'subscriptionId': subscriptionId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Payment.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Payment processing failed');
      }
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  // Get payment history
  Future<List<Payment>> getPaymentHistory({
    int page = 1,
    int limit = 20,
    PaymentStatus? status,
    PaymentType? type,
  }) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) {
        queryParams['status'] = status.name;
      }
      if (type != null) {
        queryParams['type'] = type.name;
      }

      final uri = Uri.parse('$_baseUrl/api/payments').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> paymentsJson = data['payments'] ?? data;
        return paymentsJson.map((json) => Payment.fromJson(json)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch payment history');
      }
    } catch (e) {
      throw Exception('Failed to fetch payment history: $e');
    }
  }

  // Get payment by ID
  Future<Payment> getPayment(String paymentId) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/payments/$paymentId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Payment.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch payment');
      }
    } catch (e) {
      throw Exception('Failed to fetch payment: $e');
    }
  }

  // Payment methods management
  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/payments/methods'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> methodsJson = data['paymentMethods'] ?? data;
        return methodsJson.map((json) => PaymentMethod.fromJson(json)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch payment methods');
      }
    } catch (e) {
      throw Exception('Failed to fetch payment methods: $e');
    }
  }

  Future<PaymentMethod> savePaymentMethod({
    required PaymentMethodType type,
    required String last4,
    String? brand,
    String? expiryMonth,
    String? expiryYear,
    String? holderName,
    bool isDefault = false,
  }) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/payments/methods'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'type': type.name,
          'last4': last4,
          'brand': brand,
          'expiryMonth': expiryMonth,
          'expiryYear': expiryYear,
          'holderName': holderName,
          'isDefault': isDefault,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return PaymentMethod.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to save payment method');
      }
    } catch (e) {
      throw Exception('Failed to save payment method: $e');
    }
  }

  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/payments/methods/$paymentMethodId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete payment method');
      }
    } catch (e) {
      throw Exception('Failed to delete payment method: $e');
    }
  }

  // Subscription management
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/subscriptions/plans'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> plansJson = data['plans'] ?? data;
        return plansJson.map((json) => SubscriptionPlan.fromJson(json)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch subscription plans');
      }
    } catch (e) {
      throw Exception('Failed to fetch subscription plans: $e');
    }
  }

  Future<Subscription> createSubscription({
    required String planId,
    required String paymentMethodId,
  }) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/subscriptions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'planId': planId,
          'paymentMethodId': paymentMethodId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Subscription.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create subscription');
      }
    } catch (e) {
      throw Exception('Failed to create subscription: $e');
    }
  }

  Future<List<Subscription>> getSubscriptions() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/subscriptions'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> subscriptionsJson = data['subscriptions'] ?? data;
        return subscriptionsJson.map((json) => Subscription.fromJson(json)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch subscriptions');
      }
    } catch (e) {
      throw Exception('Failed to fetch subscriptions: $e');
    }
  }

  Future<Subscription> cancelSubscription({
    required String subscriptionId,
    String? reason,
  }) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/subscriptions/$subscriptionId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Subscription.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to cancel subscription');
      }
    } catch (e) {
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  // Utility methods
  Future<bool> isPaymentGatewayAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/payments/health'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getPaymentGatewayConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/payments/config'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch payment gateway configuration');
      }
    } catch (e) {
      throw Exception('Failed to fetch payment gateway configuration: $e');
    }
  }
}
