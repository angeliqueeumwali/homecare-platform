import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/app_config.dart';
import 'package:mobile/models/service_request_model.dart';

void main() {
  group('ApiConfig.resolveUrl', () {
    test('returns empty string for null or empty path', () {
      expect(ApiConfig.resolveUrl(null), '');
      expect(ApiConfig.resolveUrl(''), '');
    });

    test('leaves absolute http and https urls untouched', () {
      expect(
        ApiConfig.resolveUrl('https://cdn.example.com/laundry.png'),
        'https://cdn.example.com/laundry.png',
      );
      expect(
        ApiConfig.resolveUrl('http://cdn.example.com/laundry.png'),
        'http://cdn.example.com/laundry.png',
      );
    });

    test('prefixes a root-relative path with the api base url', () {
      expect(
        ApiConfig.resolveUrl('/static/services/laundry.png'),
        '${ApiConfig.baseUrl}/static/services/laundry.png',
      );
    });

    test('prefixes a relative path that has no leading slash', () {
      expect(
        ApiConfig.resolveUrl('static/services/laundry.png'),
        '${ApiConfig.baseUrl}/static/services/laundry.png',
      );
    });
  });

  group('ServiceCategoryModel', () {
    Map<String, dynamic> jsonWithImage() => {
      'id': '86461cfd-6062-4cba-9880-7964bd040c25',
      'name': 'Child Care',
      'description': 'Home-based childcare.',
      'image_url': '/static/services/child-care.png',
      'is_active': true,
    };

    test('fromJson parses image_url', () {
      final category = ServiceCategoryModel.fromJson(jsonWithImage());

      expect(category.name, 'Child Care');
      expect(category.imageUrl, '/static/services/child-care.png');
      expect(category.description, 'Home-based childcare.');
      expect(category.isActive, isTrue);
    });

    test('displayImageUrl resolves the relative backend path', () {
      final category = ServiceCategoryModel.fromJson(jsonWithImage());

      expect(
        category.displayImageUrl,
        '${ApiConfig.baseUrl}/static/services/child-care.png',
      );
    });

    test('handles a category with no image or description', () {
      final category = ServiceCategoryModel.fromJson({
        'id': 'abc',
        'name': 'Pet Care',
        'description': null,
        'image_url': null,
        'is_active': false,
      });

      expect(category.imageUrl, isNull);
      expect(category.description, isNull);
      expect(category.isActive, isFalse);
      expect(category.displayImageUrl, '');
    });

    test('tolerates a missing image_url and is_active key', () {
      final category = ServiceCategoryModel.fromJson({
        'id': 'abc',
        'name': 'Pet Care',
      });

      expect(category.imageUrl, isNull);
      expect(category.isActive, isTrue);
    });

    test('toJson round-trips through fromJson', () {
      final original = ServiceCategoryModel.fromJson(jsonWithImage());
      final restored = ServiceCategoryModel.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.isActive, original.isActive);
    });
  });
}
