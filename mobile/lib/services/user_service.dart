import 'package:mobile/models/user_model.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _apiClient;

  UserService(this._apiClient);

  Future<UserModel> getMyProfile() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/users/me');
      return UserModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }

  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/users/me',
        body,
      );
      return UserModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }
}
