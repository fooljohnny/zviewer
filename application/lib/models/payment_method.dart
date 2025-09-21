import 'package:json_annotation/json_annotation.dart';

part 'payment_method.g.dart';

enum PaymentMethodType {
  @JsonValue('card')
  card,
  @JsonValue('paypal')
  paypal,
  @JsonValue('apple_pay')
  applePay,
  @JsonValue('google_pay')
  googlePay,
  @JsonValue('bank_transfer')
  bankTransfer,
}

@JsonSerializable()
class PaymentMethod {
  final String id;
  final String userId;
  final PaymentMethodType type;
  final String last4; // Last 4 digits of card
  final String? brand; // Visa, Mastercard, etc.
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? expiryMonth;
  final String? expiryYear;
  final String? holderName;

  const PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.last4,
    this.brand,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
    this.expiryMonth,
    this.expiryYear,
    this.holderName,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => _$PaymentMethodFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentMethodToJson(this);

  String get displayName {
    switch (type) {
      case PaymentMethodType.card:
        return '${brand ?? 'Card'} •••• $last4';
      case PaymentMethodType.paypal:
        return 'PayPal';
      case PaymentMethodType.applePay:
        return 'Apple Pay';
      case PaymentMethodType.googlePay:
        return 'Google Pay';
      case PaymentMethodType.bankTransfer:
        return 'Bank Transfer';
    }
  }

  String get maskedNumber {
    if (type == PaymentMethodType.card) {
      return '•••• •••• •••• $last4';
    }
    return displayName;
  }

  bool get isExpired {
    if (type != PaymentMethodType.card || expiryYear == null || expiryMonth == null) {
      return false;
    }
    
    final now = DateTime.now();
    final expiryDate = DateTime(
      int.parse(expiryYear!),
      int.parse(expiryMonth!),
    );
    
    return now.isAfter(expiryDate);
  }

  PaymentMethod copyWith({
    String? id,
    String? userId,
    PaymentMethodType? type,
    String? last4,
    String? brand,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? expiryMonth,
    String? expiryYear,
    String? holderName,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      last4: last4 ?? this.last4,
      brand: brand ?? this.brand,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      holderName: holderName ?? this.holderName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentMethod && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PaymentMethod(id: $id, userId: $userId, type: $type, last4: $last4, brand: $brand)';
  }
}
