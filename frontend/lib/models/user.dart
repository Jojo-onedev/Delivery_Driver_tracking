class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final Map<String, dynamic>? location;
  final String? vehicle;
  final String? licensePlate;
  final double rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.status = 'offline',
    this.location,
    this.vehicle,
    this.licensePlate,
    this.rating = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
  return User(
    id: json['_id'] ?? json['id'],
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone']?.toString(),
    role: json['role'] ?? 'driver',
    status: json['status'] ?? 'offline',
    location: json['location'] is Map ? Map<String, dynamic>.from(json['location']) : null,
    vehicle: json['vehicle']?.toString(),
    licensePlate: json['licensePlate']?.toString(),
    rating: (json['rating'] ?? 0).toDouble(),
    createdAt: (json['createdAt'] ?? json['created_at']) != null
        ? DateTime.parse(json['createdAt'] ?? json['created_at'])
        : DateTime.now(),
    updatedAt: (json['updatedAt'] ?? json['updated_at']) != null
        ? DateTime.parse(json['updatedAt'] ?? json['updated_at'])
        : DateTime.now(),
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      'role': role,
      'status': status,
      if (location != null) 'location': location,
      if (vehicle != null) 'vehicle': vehicle,
      if (licensePlate != null) 'licensePlate': licensePlate,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}