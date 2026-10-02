import 'package:mobile/models/service_request_model.dart';
import 'api_client.dart';

class ServiceRequestService {
  final ApiClient _apiClient;

  ServiceRequestService(this._apiClient);

  Future<ServiceRequestModel> createRequest({
    required String address,
    required double latitude,
    required double longitude,
    DateTime? preferredDate,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final body = <String, dynamic>{
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'items': items,
    };
    if (preferredDate != null) {
      body['preferred_date'] = preferredDate.toIso8601String();
    }
    if (notes != null) {
      body['notes'] = notes;
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/service-requests',
        body,
      );
      return ServiceRequestModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }

  Future<List<ServiceRequestModel>> getMyRequests() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/service-requests/me',
      );
      return response
          .map((e) => ServiceRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    }
  }

  Future<ServiceRequestModel?> getRequestById(String id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/service-requests/$id',
      );
      return ServiceRequestModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }

  Future<ServiceRequestModel> updateStatus(String id, String status) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/service-requests/$id/status',
        {'status': status},
      );
      return ServiceRequestModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }
}

class ServiceRequestItemCreate {
  final String serviceCategoryId;
  final String? notes;

  ServiceRequestItemCreate({required this.serviceCategoryId, this.notes});

  Map<String, dynamic> toJson() => {
    'service_category_id': serviceCategoryId,
    if (notes != null) 'notes': notes,
  };
}
