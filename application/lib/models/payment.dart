import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

enum PaymentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('refunded')
  refunded,
}

enum PaymentType {
  @JsonValue('subscription')
  subscription,
  @JsonValue('one_time')
  oneTime,
  @JsonValue('refund')
  refund,
}

@JsonSerializable()
class Payment {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final PaymentType type;
  final DateTime createdAt;
  final String? description;
  final String? subscriptionId;
  final String? transactionId;
  final String? paymentMethodId;
  final DateTime? updatedAt;

  const Payment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.type,
    required this.createdAt,
    this.description,
    this.subscriptionId,
    this.transactionId,
    this.paymentMethodId,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentToJson(this);

  Payment copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    PaymentType? type,
    DateTime? createdAt,
    String? description,
    String? subscriptionId,
    String? transactionId,
    String? paymentMethodId,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      transactionId: transactionId ?? this.transactionId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Payment(id: $id, userId: $userId, amount: $amount, currency: $currency, status: $status, type: $type)';
  }
}
