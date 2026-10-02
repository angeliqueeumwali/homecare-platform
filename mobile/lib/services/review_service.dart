import 'package:mobile/models/notification_model.dart';
import 'api_client.dart';

class ReviewService {
  final ApiClient _apiClient;

  ReviewService(this._apiClient);

  Future<ReviewModel> createReview({
    required String assignmentId,
    required int rating,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'assignment_id': assignmentId,
      'rating': rating,
    };
    if (comment != null) body['comment'] = comment;
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/reviews',
        body,
      );
      return ReviewModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }

  Future<List<ReviewModel>> getProviderReviews(String providerId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/reviews/provider/$providerId',
      );
      return response
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    }
  }

  Future<List<ReviewModel>> getMyProviderReviews() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/reviews/me/provider',
      );
      return response
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    }
  }
}

class IssueService {
  final ApiClient _apiClient;

  IssueService(this._apiClient);

  Future<IssueModel> createIssue({
    required String serviceRequestId,
    String? assignmentId,
    required String title,
    required String description,
  }) async {
    final body = <String, dynamic>{
      'service_request_id': serviceRequestId,
      'title': title,
      'description': description,
    };
    if (assignmentId != null) body['assignment_id'] = assignmentId;
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/issues',
        body,
      );
      return IssueModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }

  Future<List<IssueModel>> getMyIssues() async {
    try {
      final response = await _apiClient.get<List<dynamic>>('/issues/me');
      return response
          .map((e) => IssueModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    }
  }
}
