import 'package:mobile/models/service_request_model.dart';
import 'api_client.dart';

class ServiceCategoryService {
  final ApiClient _apiClient;

  ServiceCategoryService(this._apiClient);

  Future<List<ServiceCategoryModel>> getAllCategories() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/service-categories',
      );
      return response
          .map((e) => ServiceCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    }
  }

  Future<ServiceCategoryModel?> getCategoryById(String id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/service-categories/$id',
      );
      return ServiceCategoryModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }
}
