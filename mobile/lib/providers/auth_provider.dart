import 'package:flutter/material.dart';

import 'package:mobile/models/user_model.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/token_storage.dart';
import 'package:mobile/services/user_service.dart';

enum AuthStatus { unauthenticated, authenticated, loading }

class AuthProvider with ChangeNotifier {
  final ApiClient apiClient;
  late final AuthService authService;
  late final UserService userService;

  AuthStatus _authStatus = AuthStatus.loading;
  UserModel? _user;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isDisposed = false;

  AuthStatus get authStatus => _authStatus;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;

  AuthProvider() : apiClient = ApiClient(getToken: TokenStorage.readToken) {
    authService = AuthService(apiClient);
    userService = UserService(apiClient);
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  Future<void> init() async {
    await _checkAuth();
    _safeNotify();
  }

  Future<void> _checkAuth() async {
    final token = await TokenStorage.readToken();
    if (token == null) {
      _authStatus = AuthStatus.unauthenticated;
      return;
    }
    final user = await userService.getMyProfile();
    _user = user;
    _authStatus = AuthStatus.authenticated;
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await authService.login(email, password);
      if (result.success && result.token != null) {
        await TokenStorage.saveToken(result.token!);
        _user = await userService.getMyProfile();
        _authStatus = AuthStatus.authenticated;
        return true;
      }
      _errorMessage = result.error ?? 'Login failed';
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );
      if (result.success && result.token != null) {
        await TokenStorage.saveToken(result.token!);
        _user = await userService.getMyProfile();
        _authStatus = AuthStatus.authenticated;
        return true;
      }
      _errorMessage = result.error ?? 'Registration failed';
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearAll();
    _user = null;
    _authStatus = AuthStatus.unauthenticated;
    _safeNotify();
  }

  void clearError() {
    _errorMessage = null;
    _safeNotify();
  }

  Future<void> refreshUser() async {
    if (_user != null) {
      _user = await userService.getMyProfile();
      _safeNotify();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _safeNotify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
