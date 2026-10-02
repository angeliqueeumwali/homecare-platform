import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/quote_model.dart';

void main() {
  group('QuoteModel', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'quote-1',
        'service_request_id': 'req-1',
        'service_request_item_id': 'item-1',
        'provider_id': 'prov-1',
        'amount': '50000',
        'currency': 'RWF',
        'status': 'PENDING',
        'description': 'Standard service',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };

      final quote = QuoteModel.fromJson(json);

      expect(quote.id, 'quote-1');
      expect(quote.serviceRequestId, 'req-1');
      expect(quote.serviceRequestItemId, 'item-1');
      expect(quote.providerId, 'prov-1');
      expect(quote.amount, '50000');
      expect(quote.currency, 'RWF');
      expect(quote.status, 'PENDING');
      expect(quote.description, 'Standard service');
      expect(quote.createdAt, '2024-01-01T00:00:00Z');
      expect(quote.updatedAt, '2024-01-02T00:00:00Z');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'quote-1',
        'service_request_id': 'req-1',
        'service_request_item_id': 'item-1',
        'provider_id': 'prov-1',
        'amount': '50000',
        'currency': 'RWF',
        'status': 'PENDING',
      };

      final quote = QuoteModel.fromJson(json);

      expect(quote.description, isNull);
      expect(quote.createdAt, isNull);
      expect(quote.updatedAt, isNull);
    });

    test('toJson returns correct map', () {
      final quote = QuoteModel(
        id: 'quote-1',
        serviceRequestId: 'req-1',
        serviceRequestItemId: 'item-1',
        providerId: 'prov-1',
        amount: '50000',
        currency: 'RWF',
        status: 'PENDING',
        description: 'Standard service',
        createdAt: '2024-01-01',
        updatedAt: '2024-01-02',
      );

      final json = quote.toJson();

      expect(json['id'], 'quote-1');
      expect(json['service_request_id'], 'req-1');
      expect(json['amount'], '50000');
      expect(json['currency'], 'RWF');
      expect(json['status'], 'PENDING');
      expect(json['description'], 'Standard service');
    });
  });

  group('QuoteCreateRequest', () {
    test('toJson includes all required fields', () {
      final request = QuoteCreateRequest(
        serviceRequestId: 'req-1',
        serviceRequestItemId: 'item-1',
        amount: '50000',
        description: 'Quote description',
      );

      final json = request.toJson();

      expect(json['service_request_id'], 'req-1');
      expect(json['service_request_item_id'], 'item-1');
      expect(json['amount'], '50000');
      expect(json['currency'], 'RWF');
      expect(json['description'], 'Quote description');
    });

    test('toJson omits description when null', () {
      final request = QuoteCreateRequest(
        serviceRequestId: 'req-1',
        serviceRequestItemId: 'item-1',
        amount: '50000',
      );

      final json = request.toJson();

      expect(json.containsKey('description'), false);
    });
  });
}
