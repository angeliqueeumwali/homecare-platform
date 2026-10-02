import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:mobile/constants/app_config.dart';

class TokenStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: StorageKeys.accessToken, value: token);
  }

  static Future<String?> readToken() async {
    return await _storage.read(key: StorageKeys.accessToken);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: StorageKeys.accessToken);
  }

  static Future<void> saveUserRole(String role) async {
    await _storage.write(key: StorageKeys.userRole, value: role);
  }

  static Future<String?> readUserRole() async {
    return await _storage.read(key: StorageKeys.userRole);
  }

  static Future<void> deleteUserRole() async {
    await _storage.delete(key: StorageKeys.userRole);
  }

  static Future<void> setOnboardingComplete(bool value) async {
    await _storage.write(
      key: StorageKeys.onboardingComplete,
      value: value.toString(),
    );
  }

  static Future<bool> isOnboardingComplete() async {
    final value = await _storage.read(key: StorageKeys.onboardingComplete);
    return value == 'true';
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
