import 'package:mobile/models/quote_model.dart';
import 'api_client.dart';

class QuoteService {
  final ApiClient _apiClient;

  QuoteService(this._apiClient);

  Future<QuoteModel> createQuote({
    required String serviceRequestId,
    required String serviceRequestItemId,
    required String amount,
    String currency = 'RWF',
    String? description,
  }) async {
    final body = <String, dynamic>{
      'service_request_id': serviceRequestId,
      'service_request_item_id': serviceRequestItemId,
      'amount': amount,
      'currency': currency,
    };
    if (description != null) body['description'] = description;
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/quotes',
        body,
      );
      return QuoteModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }

  Future<List<QuoteModel>> getRequestQuotes(String requestId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/quotes/request/$requestId',
      );
      return response
          .map((e) => QuoteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    }
  }

  Future<QuoteModel> updateStatus(String quoteId, String status) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/quotes/$quoteId/status',
        {'status': status},
      );
      return QuoteModel.fromJson(response);
    } on ApiException {
      rethrow;
    }
  }
}
