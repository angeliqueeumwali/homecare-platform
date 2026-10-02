import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': '123',
        'first_name': 'John',
        'last_name': 'Doe',
        'email': 'john@example.com',
        'phone_number': '+1234567890',
        'role': 'CUSTOMER',
        'is_active': true,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '123');
      expect(user.firstName, 'John');
      expect(user.lastName, 'Doe');
      expect(user.email, 'john@example.com');
      expect(user.phoneNumber, '+1234567890');
      expect(user.role, 'CUSTOMER');
      expect(user.isActive, true);
      expect(user.createdAt, '2024-01-01T00:00:00Z');
      expect(user.updatedAt, '2024-01-02T00:00:00Z');
    });

    test('fromJson uses defaults for missing optional fields', () {
      final json = {
        'id': '123',
        'first_name': 'Jane',
        'last_name': 'Smith',
        'email': 'jane@example.com',
        'phone_number': '+0987654321',
        'role': 'SERVICE_PROVIDER',
      };

      final user = UserModel.fromJson(json);

      expect(user.isActive, false);
      expect(user.createdAt, '');
      expect(user.updatedAt, '');
    });

    test('toJson returns correct map', () {
      final user = UserModel(
        id: '123',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phoneNumber: '+1234567890',
        role: 'CUSTOMER',
        isActive: true,
        createdAt: '2024-01-01T00:00:00Z',
        updatedAt: '2024-01-02T00:00:00Z',
      );

      final json = user.toJson();

      expect(json['id'], '123');
      expect(json['first_name'], 'John');
      expect(json['last_name'], 'Doe');
      expect(json['email'], 'john@example.com');
      expect(json['phone_number'], '+1234567890');
      expect(json['role'], 'CUSTOMER');
      expect(json['is_active'], true);
      expect(json['created_at'], '2024-01-01T00:00:00Z');
      expect(json['updated_at'], '2024-01-02T00:00:00Z');
    });

    test('fullName concatenates first and last', () {
      final user = UserModel(
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phoneNumber: '+123',
        role: 'CUSTOMER',
        isActive: true,
        createdAt: '',
        updatedAt: '',
      );

      expect(user.fullName, 'John Doe');
    });

    test('isCustomer returns true for CUSTOMER role', () {
      final user = UserModel(
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phoneNumber: '+123',
        role: 'CUSTOMER',
        isActive: true,
        createdAt: '',
        updatedAt: '',
      );

      expect(user.isCustomer, true);
      expect(user.isProvider, false);
    });

    test('isProvider returns true for SERVICE_PROVIDER role', () {
      final user = UserModel(
        id: '1',
        firstName: 'Provider',
        lastName: 'Person',
        email: 'provider@example.com',
        phoneNumber: '+123',
        role: 'SERVICE_PROVIDER',
        isActive: true,
        createdAt: '',
        updatedAt: '',
      );

      expect(user.isProvider, true);
      expect(user.isCustomer, false);
    });
  });

  group('TokenResponse', () {
    test('fromJson parses token correctly', () {
      final json = {'access_token': 'abc123token', 'token_type': 'bearer'};

      final token = TokenResponse.fromJson(json);

      expect(token.accessToken, 'abc123token');
      expect(token.tokenType, 'bearer');
    });

    test('fromJson uses default token_type', () {
      final json = {'access_token': 'abc123token'};

      final token = TokenResponse.fromJson(json);

      expect(token.accessToken, 'abc123token');
      expect(token.tokenType, 'bearer');
    });
  });
}
