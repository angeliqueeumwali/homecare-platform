class ProviderProfileModel {
  final String id;
  final String userId;
  final String? businessName;
  final String? bio;
  final String approvalStatus;
  final bool isAvailable;
  final double? averageRating;
  final String? createdAt;
  final String? updatedAt;

  ProviderProfileModel({
    required this.id,
    required this.userId,
    this.businessName,
    this.bio,
    required this.approvalStatus,
    required this.isAvailable,
    this.averageRating,
    this.createdAt,
    this.updatedAt,
  });

  factory ProviderProfileModel.fromJson(Map<String, dynamic> json) {
    return ProviderProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessName: json['business_name'] as String?,
      bio: json['bio'] as String?,
      approvalStatus: json['approval_status'] as String,
      isAvailable: json['is_available'] as bool? ?? false,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'business_name': businessName,
    'bio': bio,
    'approval_status': approvalStatus,
    'is_available': isAvailable,
    'average_rating': averageRating,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  bool get isApproved => approvalStatus == 'APPROVED';
}

class ProviderServiceModel {
  final String id;
  final String providerId;
  final String serviceCategoryId;
  final bool isActive;

  ProviderServiceModel({
    required this.id,
    required this.providerId,
    required this.serviceCategoryId,
    required this.isActive,
  });

  factory ProviderServiceModel.fromJson(Map<String, dynamic> json) {
    return ProviderServiceModel(
      id: json['id'] as String,
      providerId: json['provider_id'] as String,
      serviceCategoryId: json['service_category_id'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class ProviderLocationModel {
  final String id;
  final String providerId;
  final double latitude;
  final double longitude;
  final String? address;

  ProviderLocationModel({
    required this.id,
    required this.providerId,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory ProviderLocationModel.fromJson(Map<String, dynamic> json) {
    return ProviderLocationModel(
      id: json['id'] as String,
      providerId: json['provider_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
    );
  }
}
