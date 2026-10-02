import 'package:mobile/models/provider_model.dart';
import 'api_client.dart';

class ProviderService {
  final ApiClient _apiClient;

  ProviderService(this._apiClient);

  Future<ProviderProfileModel> getMyProfile() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/providers/me',
      );
      return ProviderProfileModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }

  Future<ProviderProfileModel> createProfile({
    String? businessName,
    String? bio,
  }) async {
    final body = <String, dynamic>{};
    if (businessName != null) body['business_name'] = businessName;
    if (bio != null) body['bio'] = bio;
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/providers/profile',
        body,
      );
      return ProviderProfileModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }

  Future<ProviderProfileModel> updateProfile({
    String? businessName,
    String? bio,
    bool? isAvailable,
  }) async {
    final body = <String, dynamic>{};
    if (businessName != null) body['business_name'] = businessName;
    if (bio != null) body['bio'] = bio;
    if (isAvailable != null) body['is_available'] = isAvailable;
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/providers/me',
        body,
      );
      return ProviderProfileModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }

  Future<ProviderServiceModel> addService(String serviceCategoryId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/providers/me/services',
        {'service_category_id': serviceCategoryId},
      );
      return ProviderServiceModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }

  Future<List<ProviderServiceModel>> getServices() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/providers/me/services',
      );
      return response
          .map((e) => ProviderServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    }
  }

  Future<void> removeService(String serviceCategoryId) async {
    try {
      await _apiClient.delete('/providers/me/services/$serviceCategoryId');
    } on ApiException {
      rethrow;
    }
  }

  Future<ProviderLocationModel> setLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };
    if (address != null) body['address'] = address;
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/providers/me/location',
        body,
      );
      return ProviderLocationModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> findNearestProviders({
    required String serviceCategoryId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/providers/match',
        queryParameters: {
          'service_category_id': serviceCategoryId,
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        },
      );
      return response.map((e) => e as Map<String, dynamic>).toList();
    } on ApiException {
      rethrow;
    }
  }
}

class ProviderMatchResult {
  final String providerId;
  final double distanceKm;
  final String businessName;
  final double? averageRating;

  ProviderMatchResult({
    required this.providerId,
    required this.distanceKm,
    required this.businessName,
    this.averageRating,
  });

  factory ProviderMatchResult.fromJson(Map<String, dynamic> json) {
    return ProviderMatchResult(
      providerId: json['provider_id'] as String,
      distanceKm: (json['distance_km'] as num).toDouble(),
      businessName: json['business_name'] as String? ?? '',
      averageRating: (json['average_rating'] as num?)?.toDouble(),
    );
  }
}
