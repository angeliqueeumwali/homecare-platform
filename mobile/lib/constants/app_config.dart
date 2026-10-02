import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Android emulators reach the host machine through 10.0.2.2, not localhost.
  /// Override for real devices with:
  /// flutter run --dart-define=API_BASE_URL=http://your-ip:8000
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Browsers and desktop builds talk to the host directly, so they need
  /// localhost. Only the Android emulator needs the 10.0.2.2 alias.
  static const String _emulatorBaseUrl = 'http://10.0.2.2:8000';
  static const String _localBaseUrl = 'http://localhost:8000';

  static bool get _usesAndroidEmulatorAlias {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    return _usesAndroidEmulatorAlias ? _emulatorBaseUrl : _localBaseUrl;
  }

  static const String bearerPrefix = 'Bearer ';
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;

  /// The backend stores image paths like `/static/services/laundry.png`.
  /// Absolute URLs are returned untouched so external images still work.
  static String resolveUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) path = path.substring(1);
    return '$baseUrl/$path';
  }
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String userRole = 'user_role';
  static const String onboardingComplete = 'onboarding_complete';
}

class AppStrings {
  static const String appName = 'Homecare Platform';
  static const String appTagline =
      'Quality home-care services at your doorstep';
}
