import 'package:mobile/models/payment_model.dart';
import 'api_client.dart';

class PaymentService {
  final ApiClient _apiClient;

  PaymentService(this._apiClient);

  Future<PaymentModel> createPayment(PaymentCreateRequest request) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/payments',
        request.toJson(),
      );
      return PaymentModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }

  Future<List<PaymentModel>> getMyPayments() async {
    try {
      final response = await _apiClient.get<List<dynamic>>('/payments/me');
      return response
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    }
  }
}
