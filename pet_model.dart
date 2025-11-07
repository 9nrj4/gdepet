class PetModel {
  final String id;
  final String userId;
  final String ownerName;
  final String petName;
  final String description;
  final List<String> imageUrls;
  final PetType type;
  final PetStatus status; // lost or found
  final double? latitude;
  final double? longitude;
  final String? geohash; // GeoHash для быстрого поиска
  final String? address;
  final String? contactPhone;
  final String? contactTelegram;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final List<Map<String, dynamic>> sightings;

  PetModel({
    required this.id,
    required this.userId,
    required this.ownerName,
    required this.petName,
    required this.description,
    required this.imageUrls,
    required this.type,
    required this.status,
    this.latitude,
    this.longitude,
    this.geohash,
    this.address,
    this.contactPhone,
    this.contactTelegram,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.sightings = const [],
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'],
      userId: json['userId'],
      ownerName: json['ownerName'],
      petName: json['petName'],
      description: json['description'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      type: PetType.values.firstWhere(
        (e) => e.toString() == 'PetType.${json['type']}',
        orElse: () => PetType.other,
      ),
      status: PetStatus.values.firstWhere(
        (e) => e.toString() == 'PetStatus.${json['status']}',
        orElse: () => PetStatus.lost,
      ),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      geohash: json['geohash'],
      address: json['address'],
      contactPhone: json['contactPhone'],
      contactTelegram: json['contactTelegram'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isActive: json['isActive'] ?? true,
      sightings: List<Map<String, dynamic>>.from(json['sightings'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'ownerName': ownerName,
      'petName': petName,
      'description': description,
      'imageUrls': imageUrls,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
      'address': address,
      'contactPhone': contactPhone,
      'contactTelegram': contactTelegram,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'sightings': sightings,
    };
  }
}

enum PetType {
  dog,
  cat,
  bird,
  other,
}

enum PetStatus {
  lost,
  found,
}

extension PetTypeExtension on PetType {
  String get displayName {
    switch (this) {
      case PetType.dog:
        return 'Собака';
      case PetType.cat:
        return 'Кошка';
      case PetType.bird:
        return 'Птица';
      case PetType.other:
        return 'Другое';
    }
  }
}

extension PetStatusExtension on PetStatus {
  String get displayName {
    switch (this) {
      case PetStatus.lost:
        return 'Пропал';
      case PetStatus.found:
        return 'Найден';
    }
  }
}
