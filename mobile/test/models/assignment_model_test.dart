import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/assignment_model.dart';

void main() {
  group('AssignmentModel', () {
    test('fromJson parses basic fields correctly', () {
      final json = {
        'id': 'assign-1',
        'service_request_id': 'req-1',
        'service_request_item_id': 'item-1',
        'provider_id': 'prov-1',
        'status': 'ASSIGNED',
      };

      final assignment = AssignmentModel.fromJson(json);

      expect(assignment.id, 'assign-1');
      expect(assignment.serviceRequestId, 'req-1');
      expect(assignment.serviceRequestItemId, 'item-1');
      expect(assignment.providerId, 'prov-1');
      expect(assignment.status, 'ASSIGNED');
      expect(assignment.assignedAt, isNull);
      expect(assignment.acceptedAt, isNull);
      expect(assignment.completedAt, isNull);
    });

    test('fromJson parses nullable timestamp fields', () {
      final json = {
        'id': 'assign-1',
        'service_request_id': 'req-1',
        'service_request_item_id': 'item-1',
        'provider_id': 'prov-1',
        'status': 'COMPLETED',
        'assigned_at': '2024-01-01T00:00:00Z',
        'accepted_at': '2024-01-01T01:00:00Z',
        'completed_at': '2024-01-01T02:00:00Z',
      };

      final assignment = AssignmentModel.fromJson(json);

      expect(assignment.assignedAt, '2024-01-01T00:00:00Z');
      expect(assignment.acceptedAt, '2024-01-01T01:00:00Z');
      expect(assignment.completedAt, '2024-01-01T02:00:00Z');
    });

    test('fromJson parses nested service request', () {
      final json = {
        'id': 'assign-1',
        'service_request_id': 'req-1',
        'service_request_item_id': 'item-1',
        'provider_id': 'prov-1',
        'status': 'ASSIGNED',
        'service_request': {
          'id': 'req-1',
          'customer_id': 'cust-1',
          'status': 'OPEN',
          'address': '123 Main St',
          'latitude': 40.7128,
          'longitude': -74.0060,
          'notes': 'Near the park',
        },
      };

      final assignment = AssignmentModel.fromJson(json);

      expect(assignment.serviceRequest, isNotNull);
      expect(assignment.serviceRequest!.id, 'req-1');
      expect(assignment.serviceRequest!.customerId, 'cust-1');
      expect(assignment.serviceRequest!.status, 'OPEN');
      expect(assignment.serviceRequest!.address, '123 Main St');
      expect(assignment.serviceRequest!.latitude, 40.7128);
      expect(assignment.serviceRequest!.longitude, -74.0060);
      expect(assignment.serviceRequest!.notes, 'Near the park');
    });

    test('fromJson handles null nested fields', () {
      final json = {
        'id': 'assign-1',
        'service_request_id': 'req-1',
        'service_request_item_id': 'item-1',
        'provider_id': 'prov-1',
        'status': 'ASSIGNED',
      };

      final assignment = AssignmentModel.fromJson(json);

      expect(assignment.serviceRequest, isNull);
      expect(assignment.provider, isNull);
      expect(assignment.serviceRequestItem, isNull);
    });
  });

  group('ProviderInfoModel', () {
    test('fromJson parses provider info with optional fields', () {
      final json = {
        'id': 'prov-1',
        'user_id': 'user-1',
        'business_name': 'Best Care',
        'bio': 'Experienced provider',
        'approval_status': 'APPROVED',
        'is_available': true,
        'average_rating': 4.5,
      };

      final provider = ProviderInfoModel.fromJson(json);

      expect(provider.id, 'prov-1');
      expect(provider.userId, 'user-1');
      expect(provider.businessName, 'Best Care');
      expect(provider.bio, 'Experienced provider');
      expect(provider.approvalStatus, 'APPROVED');
      expect(provider.isAvailable, true);
      expect(provider.averageRating, 4.5);
    });

    test('fromJson uses defaults for missing optional fields', () {
      final json = {
        'id': 'prov-1',
        'user_id': 'user-1',
        'approval_status': 'PENDING',
        'is_available': false,
      };

      final provider = ProviderInfoModel.fromJson(json);

      expect(provider.businessName, isNull);
      expect(provider.bio, isNull);
      expect(provider.averageRating, isNull);
      expect(provider.isAvailable, false);
    });
  });
}
