class AssignmentModel {
  final String id;
  final String serviceRequestId;
  final String serviceRequestItemId;
  final String providerId;
  final String status;
  final String? assignedAt;
  final String? acceptedAt;
  final String? completedAt;
  final ServiceRequestInfoModel? serviceRequest;
  final ProviderInfoModel? provider;
  final ServiceRequestItemInfoModel? serviceRequestItem;

  AssignmentModel({
    required this.id,
    required this.serviceRequestId,
    required this.serviceRequestItemId,
    required this.providerId,
    required this.status,
    this.assignedAt,
    this.acceptedAt,
    this.completedAt,
    this.serviceRequest,
    this.provider,
    this.serviceRequestItem,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String,
      serviceRequestId: json['service_request_id'] as String,
      serviceRequestItemId: json['service_request_item_id'] as String,
      providerId: json['provider_id'] as String,
      status: json['status'] as String,
      assignedAt: json['assigned_at'] as String?,
      acceptedAt: json['accepted_at'] as String?,
      completedAt: json['completed_at'] as String?,
      serviceRequest: json['service_request'] != null
          ? ServiceRequestInfoModel.fromJson(
              json['service_request'] as Map<String, dynamic>,
            )
          : null,
      provider: json['provider'] != null
          ? ProviderInfoModel.fromJson(json['provider'] as Map<String, dynamic>)
          : null,
      serviceRequestItem: json['service_request_item'] != null
          ? ServiceRequestItemInfoModel.fromJson(
              json['service_request_item'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ServiceRequestInfoModel {
  final String id;
  final String customerId;
  final String status;
  final String address;
  final double latitude;
  final double longitude;
  final String? notes;

  ServiceRequestInfoModel({
    required this.id,
    required this.customerId,
    required this.status,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.notes,
  });

  factory ServiceRequestInfoModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestInfoModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      status: json['status'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

class ProviderInfoModel {
  final String id;
  final String userId;
  final String? businessName;
  final String? bio;
  final String approvalStatus;
  final bool isAvailable;
  final double? averageRating;

  ProviderInfoModel({
    required this.id,
    required this.userId,
    this.businessName,
    this.bio,
    required this.approvalStatus,
    required this.isAvailable,
    this.averageRating,
  });

  factory ProviderInfoModel.fromJson(Map<String, dynamic> json) {
    return ProviderInfoModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessName: json['business_name'] as String?,
      bio: json['bio'] as String?,
      approvalStatus: json['approval_status'] as String,
      isAvailable: json['is_available'] as bool? ?? false,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
    );
  }
}

class ServiceRequestItemInfoModel {
  final String id;
  final String serviceCategoryId;
  final String status;
  final String? notes;

  ServiceRequestItemInfoModel({
    required this.id,
    required this.serviceCategoryId,
    required this.status,
    this.notes,
  });

  factory ServiceRequestItemInfoModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestItemInfoModel(
      id: json['id'] as String,
      serviceCategoryId: json['service_category_id'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
    );
  }
}
