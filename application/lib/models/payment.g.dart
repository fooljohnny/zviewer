// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: $enumDecode(_$PaymentStatusEnumMap, json['status']),
      type: $enumDecode(_$PaymentTypeEnumMap, json['type']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
      subscriptionId: json['subscriptionId'] as String?,
      transactionId: json['transactionId'] as String?,
      paymentMethodId: json['paymentMethodId'] as String?,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'amount': instance.amount,
      'currency': instance.currency,
      'status': _$PaymentStatusEnumMap[instance.status]!,
      'type': _$PaymentTypeEnumMap[instance.type]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'description': instance.description,
      'subscriptionId': instance.subscriptionId,
      'transactionId': instance.transactionId,
      'paymentMethodId': instance.paymentMethodId,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.processing: 'processing',
  PaymentStatus.completed: 'completed',
  PaymentStatus.failed: 'failed',
  PaymentStatus.cancelled: 'cancelled',
  PaymentStatus.refunded: 'refunded',
};

const _$PaymentTypeEnumMap = {
  PaymentType.subscription: 'subscription',
  PaymentType.oneTime: 'one_time',
  PaymentType.refund: 'refund',
};
