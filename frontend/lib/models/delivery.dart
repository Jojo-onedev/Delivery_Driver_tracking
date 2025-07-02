import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'delivery.g.dart';

@JsonSerializable(explicitToJson: true, createFactory: false)
class Delivery {
  @JsonKey(name: '_id')
  final String id;
  
  @JsonKey(name: 'orderId')
  final String orderId;
  
  @JsonKey(name: 'customerName')
  final String customerName;
  
  @JsonKey(name: 'address')
  final String address;
  
  @JsonKey(name: 'status')
  final String status; // 'pending', 'assigned', 'picked', 'in_transit', 'delivered'
  
  @JsonKey(name: 'driverId')
  final String? driverId;
  
  @JsonKey(name: 'phone')
  final String? phone;
  
  @JsonKey(name: 'notes')
  final String? notes;
  
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;
  
  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;
  
  @JsonKey(name: 'pickedAt')
  final DateTime? pickedAt;
  
  @JsonKey(name: 'deliveredAt')
  final DateTime? deliveredAt;
  
  @JsonKey(name: 'assignedAt')
  final DateTime? assignedAt;
  
  // Champ version de MongoDB - ignoré dans la sérialisation
  @JsonKey(name: '__v', includeToJson: false)
  final int? version;

  Delivery({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.address,
    required this.status,
    this.driverId,
    this.phone,
    this.notes,
    DateTime? createdAt,
    this.updatedAt,
    this.pickedAt,
    this.deliveredAt,
    this.assignedAt,
    this.version,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Delivery.fromJson(Map<String, dynamic> json) {
    try {
      // Fonction utilitaire pour parser les dates
      DateTime? parseDate(dynamic value) {
        if (value == null) return null;
        if (value is DateTime) return value;
        if (value is String) return DateTime.parse(value);
        return null;
      }

      // Créer une copie des données pour éviter de modifier l'original
      final cleanJson = Map<String, dynamic>.from(json);
      
      // Afficher les données reçues pour le débogage
      debugPrint('📦 Données brutes reçues: $json');
      
      // Gérer le cas où _id est null (bien que ce ne devrait pas arriver)
      if (cleanJson['_id'] == null) {
        debugPrint('⚠️ Avertissement: _id est null dans la réponse de l\'API');
        cleanJson['_id'] = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      // S'assurer que les champs requis ont des valeurs
      cleanJson['orderId'] ??= '';
      cleanJson['customerName'] ??= 'Client inconnu';
      cleanJson['address'] ??= 'Adresse non spécifiée';
      cleanJson['status'] ??= 'pending';
      
      // Gérer les champs optionnels
      cleanJson['phone'] ??= '';
      cleanJson['notes'] ??= '';
      
      // Convertir les dates si nécessaire
      cleanJson['createdAt'] = parseDate(cleanJson['createdAt']) ?? DateTime.now();
      cleanJson['updatedAt'] = parseDate(cleanJson['updatedAt']);
      cleanJson['pickedAt'] = parseDate(cleanJson['pickedAt']);
      cleanJson['deliveredAt'] = parseDate(cleanJson['deliveredAt']);
      cleanJson['assignedAt'] = parseDate(cleanJson['assignedAt']);
      
      debugPrint('📦 Données nettoyées pour la désérialisation: $cleanJson');
      
      return Delivery(
        id: cleanJson['_id'] as String,
        orderId: cleanJson['orderId'] as String,
        customerName: cleanJson['customerName'] as String,
        address: cleanJson['address'] as String,
        status: cleanJson['status'] as String,
        driverId: cleanJson['driverId'] as String?,
        phone: cleanJson['phone'] as String?,
        notes: cleanJson['notes'] as String?,
        createdAt: cleanJson['createdAt'] as DateTime,
        updatedAt: cleanJson['updatedAt'] as DateTime?,
        pickedAt: cleanJson['pickedAt'] as DateTime?,
        deliveredAt: cleanJson['deliveredAt'] as DateTime?,
        assignedAt: cleanJson['assignedAt'] as DateTime?,
        version: (cleanJson['__v'] as num?)?.toInt(),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur dans Delivery.fromJson: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Données JSON problématiques: $json');
      rethrow;
    }
  }
  
  Map<String, dynamic> toJson() {
    final json = _$DeliveryToJson(this);
    // Renommer _id en id pour l'envoi au serveur si nécessaire
    if (json.containsKey('_id')) {
      json['id'] = json['_id'];
      json.remove('_id');
    }
    return json;
  }

  Delivery copyWith({
    String? id,
    String? orderId,
    String? customerName,
    String? address,
    String? status,
    String? driverId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? pickedAt,
    DateTime? deliveredAt,
    DateTime? assignedAt,
  }) {
    return Delivery(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pickedAt: pickedAt ?? this.pickedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      assignedAt: assignedAt ?? this.assignedAt,
    );
  }
}
