import 'package:mobile/models/notification_model.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _apiClient.get<List<dynamic>>('/notifications');
      return response
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    }
  }

  Future<NotificationModel> markAsRead(String notificationId) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/notifications/$notificationId/read',
        {},
      );
      return NotificationModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }
}
