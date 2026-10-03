import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/assignment_model.dart';
import 'package:mobile/models/provider_model.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/assignment_service.dart';
import 'package:mobile/services/provider_service.dart';
import 'package:mobile/services/quote_service.dart';
import 'package:mocktail/mocktail.dart';

class MockProviderService extends Mock implements ProviderService {}

class MockAssignmentService extends Mock implements AssignmentService {}

class MockQuoteService extends Mock implements QuoteService {}

ProviderProfileModel buildProfile({String approvalStatus = 'APPROVED'}) {
  return ProviderProfileModel.fromJson({
    'id': 'p1',
    'user_id': 'u1',
    'business_name': 'Bright Home Care',
    'bio': 'We clean homes.',
    'approval_status': approvalStatus,
    'is_available': true,
    'average_rating': 4.5,
  });
}

void main() {
  late MockProviderService providerService;
  late MockAssignmentService assignmentService;
  late MockQuoteService quoteService;
  late ProviderViewModel vm;

  setUp(() {
    providerService = MockProviderService();
    assignmentService = MockAssignmentService();
    quoteService = MockQuoteService();
    vm = ProviderViewModel(providerService, assignmentService, quoteService);
  });

  group('refreshAccountState', () {
    test('maps APPROVED to the approved state', () async {
      when(
        () => providerService.getMyProfile(),
      ).thenAnswer((_) async => buildProfile(approvalStatus: 'APPROVED'));

      await vm.refreshAccountState();

      expect(vm.accountState, ProviderAccountState.approved);
      expect(vm.isApprovedProvider, isTrue);
      expect(vm.profile?.businessName, 'Bright Home Care');
    });

    test('maps PENDING to the pending state', () async {
      when(
        () => providerService.getMyProfile(),
      ).thenAnswer((_) async => buildProfile(approvalStatus: 'PENDING'));

      await vm.refreshAccountState();

      expect(vm.accountState, ProviderAccountState.pending);
      expect(vm.isApprovedProvider, isFalse);
    });

    test('maps REJECTED to the rejected state', () async {
      when(
        () => providerService.getMyProfile(),
      ).thenAnswer((_) async => buildProfile(approvalStatus: 'REJECTED'));

      await vm.refreshAccountState();

      expect(vm.accountState, ProviderAccountState.rejected);
      expect(vm.isApprovedProvider, isFalse);
    });

    test('treats 404 as no provider profile, not an error', () async {
      when(() => providerService.getMyProfile()).thenThrow(
        ApiException(statusCode: 404, message: 'Provider profile not found'),
      );

      await vm.refreshAccountState();

      expect(vm.accountState, ProviderAccountState.none);
      expect(vm.profile, isNull);
    });

    test('treats 403 as blocked rather than none', () async {
      when(() => providerService.getMyProfile()).thenThrow(
        ApiException(
          statusCode: 403,
          message: 'You do not have permission to perform this action',
        ),
      );

      await vm.refreshAccountState();

      expect(vm.accountState, ProviderAccountState.blockedByBackend);
    });

    test('does not leave the checking flag set after an error', () async {
      when(
        () => providerService.getMyProfile(),
      ).thenThrow(ApiException(statusCode: 500, message: 'Server error'));

      await vm.refreshAccountState();

      expect(vm.isCheckingAccount, isFalse);
      expect(vm.accountState, ProviderAccountState.none);
    });
  });

  group('init', () {
    test('loads assignments only for an approved provider', () async {
      when(
        () => providerService.getMyProfile(),
      ).thenAnswer((_) async => buildProfile());
      when(
        () => assignmentService.getMyAssignments(),
      ).thenAnswer((_) async => []);

      await vm.init();

      verify(() => assignmentService.getMyAssignments()).called(1);
      expect(vm.assignments, isEmpty);
    });

    test(
      'does not call the provider-only endpoint when not approved',
      () async {
        when(() => providerService.getMyProfile()).thenThrow(
          ApiException(statusCode: 404, message: 'Provider profile not found'),
        );

        await vm.init();

        verifyNever(() => assignmentService.getMyAssignments());
      },
    );
  });

  group('services', () {
    setUp(() {
      when(() => providerService.getServices()).thenAnswer((_) async => []);
    });

    test('fetchServices populates the list', () async {
      await vm.fetchServices();

      verify(() => providerService.getServices()).called(1);
      expect(vm.services, isEmpty);
    });

    test(
      'addService ignores a duplicate category already in the list',
      () async {
        const categoryId = 'c1';
        when(() => providerService.addService(categoryId)).thenAnswer(
          (_) async => ProviderServiceModel.fromJson({
            'id': 's1',
            'provider_id': 'p1',
            'service_category_id': categoryId,
            'is_active': true,
          }),
        );
        vm.services.add(
          ProviderServiceModel.fromJson({
            'id': 's0',
            'provider_id': 'p1',
            'service_category_id': categoryId,
            'is_active': true,
          }),
        );

        final ok = await vm.addService(categoryId);

        expect(ok, isTrue);
        expect(vm.services.length, 1);
      },
    );

    test('addService reports failure on an ApiException', () async {
      when(
        () => providerService.addService('c2'),
      ).thenThrow(ApiException(statusCode: 400, message: 'Bad request'));

      final ok = await vm.addService('c2');

      expect(ok, isFalse);
      expect(vm.errorMessage, 'Bad request');
    });

    test('removeService drops the matching entry', () async {
      vm.services.add(
        ProviderServiceModel.fromJson({
          'id': 's1',
          'provider_id': 'p1',
          'service_category_id': 'c1',
          'is_active': true,
        }),
      );
      when(() => providerService.removeService('c1')).thenAnswer((_) async {});

      final ok = await vm.removeService('c1');

      expect(ok, isTrue);
      expect(vm.services, isEmpty);
    });
  });

  group('assignments', () {
    test('fetchAssignments loads the provider work list', () async {
      final assignment = AssignmentModel.fromJson({
        'id': 'a1',
        'service_request_id': 'sr1',
        'service_request_item_id': 'sri1',
        'provider_id': 'p1',
        'status': 'PENDING',
      });
      when(
        () => assignmentService.getMyAssignments(),
      ).thenAnswer((_) async => [assignment]);

      await vm.fetchAssignments();

      expect(vm.assignments.length, 1);
      expect(vm.assignments.first.status, 'PENDING');
    });
  });
}
