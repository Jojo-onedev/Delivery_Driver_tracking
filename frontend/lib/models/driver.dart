// driver.dart
import 'package:logger/logger.dart';

final _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 50,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

class DriverDocument {
  final String type;
  final String url;
  final bool isValid;
  final DateTime? expiryDate;

  const DriverDocument({
    required this.type,
    required this.url,
    this.isValid = false,
    this.expiryDate,
  });

  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    return DriverDocument(
      type: json['type'] as String? ?? '',
      url: json['url'] as String? ?? '',
      isValid: json['isValid'] as bool? ?? false,
      expiryDate: json['expiryDate'] != null 
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'url': url,
        'isValid': isValid,
        'expiryDate': expiryDate?.toIso8601String(),
      };
}

class DeliverySummary {
  final String id;
  final String orderId;
  final String status;
  final DateTime? deliveredAt;
  final double? rating;

  const DeliverySummary({
    required this.id,
    required this.orderId,
    required this.status,
    this.deliveredAt,
    this.rating,
  });

  // Getter pour la rétrocompatibilité
  DateTime? get completedAt => deliveredAt;

  factory DeliverySummary.fromJson(Map<String, dynamic> json) {
    return DeliverySummary(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      deliveredAt: json['deliveredAt'] != null 
          ? DateTime.tryParse(json['deliveredAt'].toString())
          : json['completedAt'] != null  // Rétrocompatibilité
              ? DateTime.tryParse(json['completedAt'].toString())
              : null,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'status': status,
        'deliveredAt': deliveredAt?.toIso8601String(),
        'rating': rating,
      };
}

class Driver {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? vehiculeType;
  final String? vehiculeModel;
  final String? licensePlate;
  final String status;
  final double? rating;
  final int totalDeliveries;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final Map<String, dynamic>? location;
  final List<DriverDocument> documents;
  final List<DeliverySummary>? recentDeliveries;
  final String? photoUrl;

  const Driver({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.vehiculeType,
    this.vehiculeModel,
    this.licensePlate,
    this.status = 'offline',
    this.rating,
    this.totalDeliveries = 0,
    this.isActive = true,
    this.createdAt,
    this.lastActiveAt,
    this.location,
    this.documents = const [],
    this.recentDeliveries,
    this.photoUrl,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    try {
      // Créer une copie du JSON pour la manipulation
      final jsonCopy = Map<String, dynamic>.from(json);
      
      // Gérer l'alias de champ vehicule/vehiculeType
      if (jsonCopy['vehicule'] != null && jsonCopy['vehiculeType'] == null) {
        jsonCopy['vehiculeType'] = jsonCopy['vehicule'];
      }
      
      // Convertir les dates si nécessaire
      final createdAt = json['createdAt'] is DateTime 
          ? json['createdAt'] as DateTime
          : json['createdAt'] != null 
              ? DateTime.tryParse(json['createdAt'].toString())
              : null;
              
      final lastActiveAt = json['lastActiveAt'] is DateTime
          ? json['lastActiveAt'] as DateTime
          : json['lastActiveAt'] != null
              ? DateTime.tryParse(json['lastActiveAt'].toString())
              : null;

      // Convertir les documents
      final documents = (json['documents'] as List<dynamic>?)
          ?.map((e) => DriverDocument.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];

      // Convertir les livraisons récentes
      final recentDeliveries = (json['recentDeliveries'] as List<dynamic>?)
          ?.map((e) => DeliverySummary.fromJson(e as Map<String, dynamic>))
          .toList();

      return Driver(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        vehiculeType: json['vehiculeType'] as String? ?? json['vehicule'] as String?,
        vehiculeModel: json['vehiculeModel'] as String?,
        licensePlate: json['licensePlate'] as String?,
        status: (json['status'] as String?) ?? 'offline',
        rating: (json['rating'] as num?)?.toDouble(),
        totalDeliveries: (json['totalDeliveries'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: createdAt,
        lastActiveAt: lastActiveAt,
        location: json['location'] as Map<String, dynamic>?,
        documents: documents,
        recentDeliveries: recentDeliveries,
        photoUrl: json['photoUrl'] as String?,
      );
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Erreur lors de la désérialisation d\'un chauffeur',
        error: e,
        stackTrace: stackTrace,
      );
      _logger.e('Données problématiques: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (phone != null) 'phone': phone,
      if (vehiculeType != null) 'vehiculeType': vehiculeType,
      if (vehiculeModel != null) 'vehiculeModel': vehiculeModel,
      if (licensePlate != null) 'licensePlate': licensePlate,
      'status': status,
      if (rating != null) 'rating': rating,
      'totalDeliveries': totalDeliveries,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (lastActiveAt != null) 'lastActiveAt': lastActiveAt!.toIso8601String(),
      if (location != null) 'location': location,
      'documents': documents.map((doc) => doc.toJson()).toList(),
      if (recentDeliveries != null)
        'recentDeliveries': recentDeliveries!.map((d) => d.toJson()).toList(),
    };
  }

  Driver copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? vehiculeType,
    String? vehiculeModel,
    String? licensePlate,
    String? status,
    double? rating,
    int? totalDeliveries,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Map<String, dynamic>? location,
    List<DriverDocument>? documents,
    List<DeliverySummary>? recentDeliveries,
    String? photoUrl,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      vehiculeType: vehiculeType ?? this.vehiculeType,
      vehiculeModel: vehiculeModel ?? this.vehiculeModel,
      licensePlate: licensePlate ?? this.licensePlate,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      location: location ?? this.location,
      documents: documents ?? this.documents,
      recentDeliveries: recentDeliveries ?? this.recentDeliveries,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  bool get isOnline => status == 'available' || status == 'on_delivery';
  
  String get statusText {
    switch (status) {
      case 'available':
        return 'Disponible';
      case 'on_delivery':
        return 'En livraison';
      case 'offline':
      default:
        return 'Hors ligne';
    }
  }
}