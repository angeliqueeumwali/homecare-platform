import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/service_request_model.dart';
import 'package:mobile/providers/service_provider.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/service_category_service.dart';
import 'package:mobile/services/service_request_service.dart';
import 'package:mocktail/mocktail.dart';

class MockServiceRequestService extends Mock implements ServiceRequestService {}

class MockServiceCategoryService extends Mock
    implements ServiceCategoryService {}

ServiceRequestModel buildRequest({
  String id = 'r1',
  String status = 'PENDING',
  String address = '12 Test Road',
  String? notes,
}) {
  return ServiceRequestModel.fromJson({
    'id': id,
    'customer_id': 'c1',
    'address': address,
    'latitude': -1.286389,
    'longitude': 36.817223,
    'preferred_date': null,
    'status': status,
    'notes': notes,
    'items': [
      {
        'id': 'i1',
        'service_category_id': 'cat1',
        'notes': 'Kitchen',
        'status': 'PENDING',
      },
    ],
    'created_at': '2026-09-30T10:00:00Z',
    'updated_at': null,
  });
}

void main() {
  group('ServiceRequestViewModel filtering', () {
    late MockServiceRequestService service;
    late ServiceRequestViewModel vm;

    setUp(() {
      service = MockServiceRequestService();
      vm = ServiceRequestViewModel(service);
    });

    test('starts with no filter and reports not loaded yet', () {
      expect(vm.hasLoadedOnce, isFalse);
      expect(vm.requests, isEmpty);
      expect(vm.filteredRequests, isEmpty);
    });

    test('activeRequests excludes completed and cancelled', () async {
      when(() => service.getMyRequests()).thenAnswer(
        (_) async => [
          buildRequest(id: 'a', status: 'PENDING'),
          buildRequest(id: 'b', status: 'IN_PROGRESS'),
          buildRequest(id: 'c', status: 'COMPLETED'),
          buildRequest(id: 'd', status: 'CANCELLED'),
        ],
      );

      await vm.fetchMyRequests();

      expect(vm.activeRequests.map((r) => r.id), ['a', 'b']);
    });

    test('search matches the address, case insensitively', () async {
      when(() => service.getMyRequests()).thenAnswer(
        (_) async => [
          buildRequest(id: 'a', address: '12 Kenyatta Avenue'),
          buildRequest(id: 'b', address: '45 Moi Street'),
        ],
      );
      await vm.fetchMyRequests();

      vm.setQuery('moi');
      expect(vm.filteredRequests.map((r) => r.id), ['b']);

      vm.setQuery('KENYATTA');
      expect(vm.filteredRequests.map((r) => r.id), ['a']);
    });

    test('search also matches notes', () async {
      when(() => service.getMyRequests()).thenAnswer(
        (_) async => [
          buildRequest(id: 'a', notes: 'Needs the boiler checked'),
          buildRequest(id: 'b', notes: 'Garden tidy up'),
        ],
      );
      await vm.fetchMyRequests();

      vm.setQuery('boiler');
      expect(vm.filteredRequests.map((r) => r.id), ['a']);
    });

    test('status filter narrows the list', () async {
      when(() => service.getMyRequests()).thenAnswer(
        (_) async => [
          buildRequest(id: 'a', status: 'PENDING'),
          buildRequest(id: 'b', status: 'COMPLETED'),
        ],
      );
      await vm.fetchMyRequests();

      vm.setStatusFilter('COMPLETED');
      expect(vm.filteredRequests.map((r) => r.id), ['b']);
    });

    test('search and status filter combine', () async {
      when(() => service.getMyRequests()).thenAnswer(
        (_) async => [
          buildRequest(id: 'a', status: 'PENDING', address: 'Kenyatta Avenue'),
          buildRequest(id: 'b', status: 'PENDING', address: 'Moi Street'),
          buildRequest(
            id: 'c',
            status: 'COMPLETED',
            address: 'Kenyatta Avenue',
          ),
        ],
      );
      await vm.fetchMyRequests();

      vm.setStatusFilter('PENDING');
      vm.setQuery('kenyatta');
      expect(vm.filteredRequests.map((r) => r.id), ['a']);
    });

    test(
      'a search with no match returns an empty list, not everything',
      () async {
        when(
          () => service.getMyRequests(),
        ).thenAnswer((_) async => [buildRequest(address: 'Kenyatta Avenue')]);
        await vm.fetchMyRequests();

        vm.setQuery('zzzz');
        expect(vm.filteredRequests, isEmpty);
      },
    );

    test('an unfiltered query returns every request', () async {
      when(
        () => service.getMyRequests(),
      ).thenAnswer((_) async => [buildRequest(id: 'a'), buildRequest(id: 'b')]);
      await vm.fetchMyRequests();

      vm.setQuery('   ');
      expect(vm.filteredRequests.length, 2);
    });

    test(
      'surfaces the error and still records that loading finished',
      () async {
        when(() => service.getMyRequests()).thenThrow(
          ApiException(statusCode: 0, message: 'No internet connection'),
        );

        await vm.fetchMyRequests();

        expect(vm.errorMessage, 'No internet connection');
        expect(vm.hasLoadedOnce, isTrue);
        expect(vm.isLoading, isFalse);
      },
    );

    test('createRequest puts the new request at the top of the list', () async {
      when(() => service.getMyRequests()).thenAnswer((_) async => []);
      await vm.fetchMyRequests();

      when(
        () => service.createRequest(
          address: any(named: 'address'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          preferredDate: any(named: 'preferredDate'),
          notes: any(named: 'notes'),
          items: any(named: 'items'),
        ),
      ).thenAnswer((_) async => buildRequest(id: 'new'));

      final created = await vm.createRequest(
        address: '12 Test Road',
        latitude: -1.2,
        longitude: 36.8,
        items: [
          {'service_category_id': 'cat1'},
        ],
      );

      expect(created?.id, 'new');
      expect(vm.requests.first.id, 'new');
    });

    test(
      'createRequest returns null and records the error on failure',
      () async {
        when(
          () => service.createRequest(
            address: any(named: 'address'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            preferredDate: any(named: 'preferredDate'),
            notes: any(named: 'notes'),
            items: any(named: 'items'),
          ),
        ).thenThrow(ApiException(statusCode: 400, message: 'Invalid request'));

        final created = await vm.createRequest(
          address: 'x',
          latitude: 0,
          longitude: 0,
          items: [
            {'service_category_id': 'cat1'},
          ],
        );

        expect(created, isNull);
        expect(vm.errorMessage, 'Invalid request');
      },
    );
  });

  group('ServiceCategoryViewModel', () {
    late MockServiceCategoryService service;
    late ServiceCategoryViewModel vm;

    setUp(() {
      service = MockServiceCategoryService();
      vm = ServiceCategoryViewModel(service);
    });

    Future<void> load() async {
      when(() => service.getAllCategories()).thenAnswer(
        (_) async => [
          ServiceCategoryModel(
            id: 'a',
            name: 'General Housekeeping',
            description: 'Cleaning rooms and surfaces',
          ),
          ServiceCategoryModel(
            id: 'b',
            name: 'Pet Care',
            description: 'Feeding and walking',
          ),
          ServiceCategoryModel(
            id: 'c',
            name: 'Hidden Service',
            description: 'Not bookable',
            isActive: false,
          ),
        ],
      );
      await vm.fetchCategories();
    }

    test('inactive categories are excluded from the bookable list', () async {
      await load();

      expect(vm.activeCategories.length, 2);
      expect(vm.filteredCategories.map((c) => c.id), ['a', 'b']);
    });

    test('search matches name and description', () async {
      await load();

      vm.setQuery('pet');
      expect(vm.filteredCategories.map((c) => c.id), ['b']);

      vm.setQuery('cleaning');
      expect(vm.filteredCategories.map((c) => c.id), ['a']);
    });

    test('search never returns an inactive category', () async {
      await load();

      vm.setQuery('hidden');
      expect(vm.filteredCategories, isEmpty);
    });

    test('an empty query returns every active category', () async {
      await load();

      vm.setQuery('');
      expect(vm.filteredCategories.length, 2);
    });
  });
}
