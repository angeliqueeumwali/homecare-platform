class NotificationModel {
  final String id;
  final String userId;
  final String notificationType;
  final String title;
  final String message;
  final String? referenceId;
  bool isRead;
  final String? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.message,
    this.referenceId,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      notificationType: json['notification_type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      referenceId: json['reference_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }
}

class ReviewModel {
  final String id;
  final String customerId;
  final String providerId;
  final String assignmentId;
  final int rating;
  final String? comment;
  final String? createdAt;

  ReviewModel({
    required this.id,
    required this.customerId,
    required this.providerId,
    required this.assignmentId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      providerId: json['provider_id'] as String,
      assignmentId: json['assignment_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class IssueModel {
  final String id;
  final String serviceRequestId;
  final String? assignmentId;
  final String reportedById;
  final String title;
  final String description;
  final String status;
  final String? resolution;
  final String? createdAt;
  final String? updatedAt;

  IssueModel({
    required this.id,
    required this.serviceRequestId,
    this.assignmentId,
    required this.reportedById,
    required this.title,
    required this.description,
    required this.status,
    this.resolution,
    this.createdAt,
    this.updatedAt,
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      id: json['id'] as String,
      serviceRequestId: json['service_request_id'] as String,
      assignmentId: json['assignment_id'] as String?,
      reportedById: json['reported_by_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      resolution: json['resolution'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
