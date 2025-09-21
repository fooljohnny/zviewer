import 'package:json_annotation/json_annotation.dart';

part 'subscription.g.dart';

enum SubscriptionStatus {
  @JsonValue('active')
  active,
  @JsonValue('inactive')
  inactive,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('expired')
  expired,
  @JsonValue('pending')
  pending,
}

@JsonSerializable()
class Subscription {
  final String id;
  final String userId;
  final String planId;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final String currency;
  final String? paymentMethodId;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.currency,
    this.paymentMethodId,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);

  bool get isActive => status == SubscriptionStatus.active;
  bool get isExpired => status == SubscriptionStatus.expired;
  bool get isCancelled => status == SubscriptionStatus.cancelled;

  Duration get remainingDuration {
    final now = DateTime.now();
    if (endDate.isBefore(now)) return Duration.zero;
    return endDate.difference(now);
  }

  Subscription copyWith({
    String? id,
    String? userId,
    String? planId,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? price,
    String? currency,
    String? paymentMethodId,
    DateTime? cancelledAt,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subscription && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Subscription(id: $id, userId: $userId, planId: $planId, status: $status, price: $price, currency: $currency)';
  }
}

@JsonSerializable()
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String interval; // 'monthly', 'yearly', 'lifetime'
  final List<String> features;
  final bool isPopular;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.interval,
    required this.features,
    this.isPopular = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => _$SubscriptionPlanFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionPlanToJson(this);

  String get formattedPrice {
    if (interval == 'lifetime') {
      return '${currency.toUpperCase()} ${price.toStringAsFixed(2)}';
    }
    return '${currency.toUpperCase()} ${price.toStringAsFixed(2)}/$interval';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionPlan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SubscriptionPlan(id: $id, name: $name, price: $price, currency: $currency, interval: $interval)';
  }
}
