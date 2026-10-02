import 'package:mobile/models/user_model.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/token_storage.dart';

class AuthResult {
  final bool success;
  final String? token;
  final String? error;

  AuthResult({required this.success, this.token, this.error});
}

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/login',
        {'email': email, 'password': password},
        includeAuth: false,
      );
      final token = response['access_token'] as String;
      return AuthResult(success: true, token: token);
    } on ApiException catch (e) {
      return AuthResult(success: false, error: e.message);
    }
  }

  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      await _apiClient.post<Map<String, dynamic>>('/auth/register', {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': phoneNumber,
        'password': password,
      }, includeAuth: false);
      return await login(email, password);
    } on ApiException catch (e) {
      return AuthResult(success: false, error: e.message);
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final token = await TokenStorage.readToken();
    if (token == null) return null;
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/auth/me');
      return UserModel.fromJson(response);
    } on ApiException {
      return null;
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearAll();
  }
}
