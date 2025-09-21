// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_method.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentMethod _$PaymentMethodFromJson(Map<String, dynamic> json) =>
    PaymentMethod(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(_$PaymentMethodTypeEnumMap, json['type']),
      last4: json['last4'] as String,
      brand: json['brand'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      expiryMonth: json['expiryMonth'] as String?,
      expiryYear: json['expiryYear'] as String?,
      holderName: json['holderName'] as String?,
    );

Map<String, dynamic> _$PaymentMethodToJson(PaymentMethod instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': _$PaymentMethodTypeEnumMap[instance.type]!,
      'last4': instance.last4,
      'brand': instance.brand,
      'isDefault': instance.isDefault,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'expiryMonth': instance.expiryMonth,
      'expiryYear': instance.expiryYear,
      'holderName': instance.holderName,
    };

const _$PaymentMethodTypeEnumMap = {
  PaymentMethodType.card: 'card',
  PaymentMethodType.paypal: 'paypal',
  PaymentMethodType.applePay: 'apple_pay',
  PaymentMethodType.googlePay: 'google_pay',
  PaymentMethodType.bankTransfer: 'bank_transfer',
};
