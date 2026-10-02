import 'package:mobile/models/assignment_model.dart';
import 'api_client.dart';

class AssignmentService {
  final ApiClient _apiClient;

  AssignmentService(this._apiClient);

  Future<List<AssignmentModel>> getMyAssignments() async {
    try {
      final response = await _apiClient.get<List<dynamic>>('/assignments/me');
      return response
          .map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    }
  }

  Future<AssignmentModel?> getAssignmentById(String id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/assignments/$id',
      );
      return AssignmentModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }

  Future<AssignmentModel> updateStatus(String id, String status) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/assignments/$id/status',
        {'status': status},
      );
      return AssignmentModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }
}
