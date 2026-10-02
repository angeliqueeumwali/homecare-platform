import 'package:mobile/constants/app_config.dart';

class ServiceCategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  ServiceCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.isActive = true,
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Absolute URL ready for `Image.network`, or empty when the category has
  /// no image so callers can show a placeholder instead.
  String get displayImageUrl => ApiConfig.resolveUrl(imageUrl);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'image_url': imageUrl,
    'is_active': isActive,
  };

  /// Categories are compared by id because the backend returns a new instance
  /// on every fetch. Dropdowns require value equality, not object identity.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceCategoryModel &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.imageUrl == imageUrl &&
          other.isActive == isActive;

  @override
  int get hashCode => Object.hash(id, name, description, imageUrl, isActive);
}

class ServiceCategoryItemModel {
  final String id;
  final String serviceCategoryId;
  final String? notes;
  final String status;

  ServiceCategoryItemModel({
    required this.id,
    required this.serviceCategoryId,
    this.notes,
    required this.status,
  });

  factory ServiceCategoryItemModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryItemModel(
      id: json['id'] as String,
      serviceCategoryId: json['service_category_id'] as String,
      notes: json['notes'] as String?,
      status: json['status'] as String,
    );
  }
}

class ServiceRequestModel {
  final String id;
  final String customerId;
  final String status;
  final String address;
  final double latitude;
  final double longitude;
  final String? preferredDate;
  final String? notes;
  final List<ServiceCategoryItemModel> items;
  final String? createdAt;
  final String? updatedAt;

  ServiceRequestModel({
    required this.id,
    required this.customerId,
    required this.status,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.preferredDate,
    this.notes,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return ServiceRequestModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      status: json['status'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      preferredDate: json['preferred_date'] as String?,
      notes: json['notes'] as String?,
      items: itemsList
          .map(
            (e) => ServiceCategoryItemModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'status': status,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'preferred_date': preferredDate,
    'notes': notes,
    'items': items
        .map(
          (e) => {
            'id': e.id,
            'service_category_id': e.serviceCategoryId,
            'notes': e.notes,
            'status': e.status,
          },
        )
        .toList(),
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
