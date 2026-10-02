import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/app_config.dart';
import 'package:mobile/services/api_client.dart';

void main() {
  group('ApiConfig', () {
    test('baseUrl and bearerPrefix are defined', () {
      expect(ApiConfig.baseUrl, isNotEmpty);
      expect(ApiConfig.bearerPrefix, 'Bearer ');
    });
  });

  group('ApiException', () {
    test('toString returns formatted message with statusCode', () {
      final exception = ApiException(statusCode: 404, message: 'Not found');

      expect(exception.toString(), 'ApiException(404): Not found');
    });

    test('stores body correctly', () {
      final exception = ApiException(
        statusCode: 500,
        message: 'Server error',
        body: {'error': 'Internal'},
      );

      expect(exception.statusCode, 500);
      expect(exception.message, 'Server error');
      expect(exception.body, {'error': 'Internal'});
    });
  });

  group('ApiError', () {
    test('toString returns message', () {
      final error = ApiError(message: 'Something went wrong');
      expect(error.toString(), 'Something went wrong');
    });
  });
}
