// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$DeliveryToJson(Delivery instance) => <String, dynamic>{
  '_id': instance.id,
  'orderId': instance.orderId,
  'customerName': instance.customerName,
  'address': instance.address,
  'status': instance.status,
  'driverId': instance.driverId,
  'phone': instance.phone,
  'notes': instance.notes,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'pickedAt': instance.pickedAt?.toIso8601String(),
  'deliveredAt': instance.deliveredAt?.toIso8601String(),
  'assignedAt': instance.assignedAt?.toIso8601String(),
};
