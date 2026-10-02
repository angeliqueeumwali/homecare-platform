import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/providers/auth_provider.dart';

void main() {
  group('AuthStatus', () {
    test('enum values are correct', () {
      expect(AuthStatus.values, [
        AuthStatus.unauthenticated,
        AuthStatus.authenticated,
        AuthStatus.loading,
      ]);
    });
  });

  group('AuthProvider', () {
    test('initial authStatus is loading', () {
      final provider = AuthProvider();
      expect(provider.authStatus, AuthStatus.loading);
      expect(provider.isAuthenticated, false);
    });

    test('initial user is null', () {
      final provider = AuthProvider();
      expect(provider.user, isNull);
    });

    test('initial isLoading is false', () {
      final provider = AuthProvider();
      expect(provider.isLoading, false);
    });

    test('initial errorMessage is null', () {
      final provider = AuthProvider();
      expect(provider.errorMessage, isNull);
    });
  });
}
