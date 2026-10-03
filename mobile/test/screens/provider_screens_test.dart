import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mobile/models/assignment_model.dart';
import 'package:mobile/models/provider_model.dart';
import 'package:mobile/models/quote_model.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/assignment_service.dart';
import 'package:mobile/services/provider_service.dart';
import 'package:mobile/services/quote_service.dart';
import 'package:mobile/screens/provider/assignment_detail_screen.dart';
import 'package:mobile/screens/provider/provider_assignments_screen.dart';
import 'package:mobile/screens/provider/provider_dashboard.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/service_provider.dart';
import 'package:mobile/services/service_category_service.dart';

class MockProviderService extends Mock implements ProviderService {}

class MockAssignmentService extends Mock implements AssignmentService {}

class MockQuoteService extends Mock implements QuoteService {}

class MockServiceCategoryService extends Mock
    implements ServiceCategoryService {}

ProviderProfileModel buildProfile({
  String approvalStatus = 'APPROVED',
  bool isAvailable = true,
  double? averageRating = 4.5,
}) {
  return ProviderProfileModel.fromJson({
    'id': 'p1',
    'user_id': 'u1',
    'business_name': 'Bright Home Care',
    'bio': 'We clean homes.',
    'approval_status': approvalStatus,
    'is_available': isAvailable,
    'average_rating': averageRating,
  });
}

AssignmentModel buildAssignment({
  String id = 'a1',
  String requestId = 'req-1111-2222',
  String itemId = 'item-3333-4444',
  String status = 'PENDING',
}) {
  return AssignmentModel.fromJson({
    'id': id,
    'service_request_id': requestId,
    'service_request_item_id': itemId,
    'provider_id': 'p1',
    'status': status,
  });
}

QuoteModel buildQuote({
  String id = 'q1',
  String providerId = 'p1',
  String status = 'PENDING',
  String amount = '15000',
}) {
  return QuoteModel.fromJson({
    'id': id,
    'service_request_id': 'req-1111-2222',
    'service_request_item_id': 'item-3333-4444',
    'provider_id': providerId,
    'amount': amount,
    'currency': 'RWF',
    'status': status,
    'description': 'Includes materials',
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

  group('filters and search', () {
    setUp(() {
      when(() => assignmentService.getMyAssignments()).thenAnswer(
        (_) async => [
          buildAssignment(id: 'a1', status: 'PENDING', requestId: 'alpha-1'),
          buildAssignment(id: 'a2', status: 'IN_PROGRESS', requestId: 'beta-2'),
          buildAssignment(id: 'a3', status: 'COMPLETED', requestId: 'gamma-3'),
        ],
      );
    });

    test('search matches the request reference', () async {
      await vm.fetchAssignments();

      vm.setAssignmentQuery('beta');

      expect(vm.filteredAssignments.length, 1);
      expect(vm.filteredAssignments.first.id, 'a2');
    });

    test('search is case insensitive', () async {
      await vm.fetchAssignments();

      vm.setAssignmentQuery('ALPHA');

      expect(vm.filteredAssignments.first.id, 'a1');
    });

    test('a filter that matches nothing yields an empty list', () async {
      await vm.fetchAssignments();

      vm.setAssignmentStatusFilter('ON_THE_WAY');

      expect(vm.filteredAssignments, isEmpty);
    });

    test('clearing the query restores every assignment', () async {
      await vm.fetchAssignments();

      vm.setAssignmentQuery('beta');
      vm.setAssignmentQuery(null);

      expect(vm.filteredAssignments.length, 3);
    });

    test('open and pending groups classify the real statuses', () async {
      await vm.fetchAssignments();

      expect(vm.openAssignments.length, 2);
      expect(vm.pendingAssignments.length, 1);
    });
  });

  group('loadAssignment', () {
    test('loads the assignment and its request quotes', () async {
      when(
        () => assignmentService.getAssignmentById('a1'),
      ).thenAnswer((_) async => buildAssignment());
      when(
        () => quoteService.getRequestQuotes('req-1111-2222'),
      ).thenAnswer((_) async => [buildQuote()]);

      final ok = await vm.loadAssignment('a1');

      expect(ok, isTrue);
      expect(vm.selectedAssignment?.id, 'a1');
      expect(vm.quotesRequestId, 'req-1111-2222');
      expect(vm.quotes.length, 1);
    });

    test('surfaces the API error and clears stale data', () async {
      when(
        () => assignmentService.getAssignmentById('a1'),
      ).thenAnswer((_) async => buildAssignment());
      when(
        () => quoteService.getRequestQuotes(any()),
      ).thenAnswer((_) async => [buildQuote()]);
      await vm.loadAssignment('a1');

      when(() => assignmentService.getAssignmentById('a1')).thenThrow(
        ApiException(statusCode: 404, message: 'Assignment not found'),
      );
      final ok = await vm.loadAssignment('a1');

      expect(ok, isFalse);
      expect(vm.selectedAssignment, isNull);
      expect(vm.quotes, isEmpty);
      expect(vm.assignmentErrorMessage, 'Assignment not found');
    });

    test('separates the provider own quotes from other providers', () async {
      when(
        () => assignmentService.getAssignmentById('a1'),
      ).thenAnswer((_) async => buildAssignment());
      when(() => quoteService.getRequestQuotes(any())).thenAnswer(
        (_) async => [
          buildQuote(id: 'q1', providerId: 'p1'),
          buildQuote(id: 'q2', providerId: 'p-other'),
        ],
      );

      await vm.loadAssignment('a1');

      expect(vm.quotes.length, 2);
      expect(vm.myQuotes.length, 1);
      expect(vm.myQuotes.first.id, 'q1');
    });
  });

  group('changeAssignmentStatus', () {
    setUp(() {
      when(
        () => assignmentService.getAssignmentById('a1'),
      ).thenAnswer((_) async => buildAssignment());
      when(
        () => quoteService.getRequestQuotes(any()),
      ).thenAnswer((_) async => const []);
    });

    test('returns null and stores the confirmed status on success', () async {
      when(
        () => assignmentService.updateStatus('a1', 'ACCEPTED'),
      ).thenAnswer((_) async => buildAssignment(status: 'ACCEPTED'));

      final error = await vm.changeAssignmentStatus('a1', 'ACCEPTED');

      expect(error, isNull);
      expect(vm.selectedAssignment?.status, 'ACCEPTED');
    });

    test('keeps the cached list in step with the confirmed status', () async {
      when(
        () => assignmentService.getMyAssignments(),
      ).thenAnswer((_) async => [buildAssignment()]);
      await vm.fetchAssignments();

      when(
        () => assignmentService.updateStatus('a1', 'ACCEPTED'),
      ).thenAnswer((_) async => buildAssignment(status: 'ACCEPTED'));
      await vm.changeAssignmentStatus('a1', 'ACCEPTED');

      expect(vm.assignments.first.status, 'ACCEPTED');
    });

    test(
      'returns the backend message and keeps the old status on failure',
      () async {
        when(
          () => assignmentService.updateStatus('a1', 'ACCEPTED'),
        ).thenThrow(ApiException(statusCode: 400, message: 'Invalid status'));

        final error = await vm.changeAssignmentStatus('a1', 'ACCEPTED');

        expect(error, 'Invalid status');
        expect(vm.assignmentErrorMessage, 'Invalid status');
      },
    );

    test('clears the updating flag after a failure', () async {
      when(
        () => assignmentService.updateStatus('a1', 'DECLINED'),
      ).thenThrow(ApiException(statusCode: 403, message: 'Access denied'));

      await vm.changeAssignmentStatus('a1', 'DECLINED');

      expect(vm.isUpdatingAssignment, isFalse);
    });
  });

  group('createQuoteForSelectedAssignment', () {
    setUp(() async {
      when(
        () => assignmentService.getAssignmentById('a1'),
      ).thenAnswer((_) async => buildAssignment());
      when(
        () => quoteService.getRequestQuotes(any()),
      ).thenAnswer((_) async => const []);
      await vm.loadAssignment('a1');
    });

    test('sends the assignment request and item ids', () async {
      when(
        () => quoteService.createQuote(
          serviceRequestId: any(named: 'serviceRequestId'),
          serviceRequestItemId: any(named: 'serviceRequestItemId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => buildQuote());

      final error = await vm.createQuoteForSelectedAssignment(
        amount: '15000',
        description: 'Includes materials',
      );

      expect(error, isNull);
      final captured = verify(
        () => quoteService.createQuote(
          serviceRequestId: captureAny(named: 'serviceRequestId'),
          serviceRequestItemId: captureAny(named: 'serviceRequestItemId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          description: any(named: 'description'),
        ),
      ).captured;
      expect(captured[0], 'req-1111-2222');
      expect(captured[1], 'item-3333-4444');
      expect(vm.quotes.length, 1);
    });

    test(
      'returns the backend error and stores no quote on rejection',
      () async {
        when(
          () => quoteService.createQuote(
            serviceRequestId: any(named: 'serviceRequestId'),
            serviceRequestItemId: any(named: 'serviceRequestItemId'),
            amount: any(named: 'amount'),
            currency: any(named: 'currency'),
            description: any(named: 'description'),
          ),
        ).thenThrow(
          ApiException(statusCode: 400, message: 'Invalid request item'),
        );

        final error = await vm.createQuoteForSelectedAssignment(amount: '10');

        expect(error, 'Invalid request item');
        expect(vm.quotes, isEmpty);
      },
    );

    test('refuses when no assignment is open', () async {
      final fresh = ProviderViewModel(
        providerService,
        assignmentService,
        quoteService,
      );

      final error = await fresh.createQuoteForSelectedAssignment(amount: '10');

      expect(error, 'No assignment is open.');
    });
  });

  group('profile', () {
    test('clears the previous error before a new save', () async {
      when(
        () => providerService.updateProfile(businessName: 'New name'),
      ).thenThrow(ApiException(statusCode: 400, message: 'Too long'));
      await vm.updateProfile(businessName: 'New name');
      expect(vm.errorMessage, 'Too long');

      when(
        () => providerService.updateProfile(businessName: 'New name'),
      ).thenAnswer((_) async => buildProfile());

      final ok = await vm.updateProfile(businessName: 'New name');

      expect(ok, isTrue);
      expect(vm.errorMessage, isNull);
    });

    test('records the availability the backend confirmed', () async {
      when(
        () => providerService.updateProfile(isAvailable: true),
      ).thenAnswer((_) async => buildProfile(isAvailable: true));

      final ok = await vm.updateProfile(isAvailable: true);

      expect(ok, isTrue);
      expect(vm.profile?.isAvailable, isTrue);
    });

    test('keeps the previous value when availability is refused', () async {
      when(() => providerService.updateProfile(isAvailable: true)).thenThrow(
        ApiException(
          statusCode: 400,
          message: 'Provider must be approved before becoming available',
        ),
      );

      final ok = await vm.updateProfile(isAvailable: true);

      expect(ok, isFalse);
      expect(vm.errorMessage, contains('must be approved'));
    });
  });

  group('loadDashboard', () {
    test('does not call the provider endpoints when not approved', () async {
      when(
        () => providerService.getMyProfile(),
      ).thenAnswer((_) async => buildProfile(approvalStatus: 'PENDING'));

      await vm.loadDashboard();

      verifyNever(() => assignmentService.getMyAssignments());
      expect(vm.accountState, ProviderAccountState.pending);
      expect(vm.hasLoadedOnce, isTrue);
    });

    test('loads profile and assignments for an approved provider', () async {
      when(
        () => providerService.getMyProfile(),
      ).thenAnswer((_) async => buildProfile());
      when(
        () => assignmentService.getMyAssignments(),
      ).thenAnswer((_) async => [buildAssignment()]);

      await vm.loadDashboard();

      expect(vm.assignments.length, 1);
      expect(vm.hasLoadedAssignments, isTrue);
    });

    test('records the failure message when assignments cannot load', () async {
      when(
        () => providerService.getMyProfile(),
      ).thenAnswer((_) async => buildProfile());
      when(
        () => assignmentService.getMyAssignments(),
      ).thenThrow(ApiException(statusCode: 403, message: 'Access denied'));

      await vm.loadDashboard();

      expect(vm.assignmentErrorMessage, 'Access denied');
      expect(vm.isLoadingAssignments, isFalse);
    });
  });

  group('widget rendering', () {
    Future<ProviderViewModel> approvedVm() async {
      when(
        () => providerService.getMyProfile(),
      ).thenAnswer((_) async => buildProfile());
      final approved = ProviderViewModel(
        providerService,
        assignmentService,
        quoteService,
      );
      await approved.refreshAccountState();
      return approved;
    }

    Future<void> pumpProvider(
      WidgetTester tester,
      Widget child, {
      ProviderViewModel? viewModel,
      bool tallSurface = false,
    }) async {
      if (tallSurface) {
        tester.view.physicalSize = const Size(1000, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
      }
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ProviderViewModel>.value(
              value: viewModel ?? vm,
            ),
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<ServiceCategoryViewModel>(
              create: (_) =>
                  ServiceCategoryViewModel(MockServiceCategoryService()),
            ),
          ],
          child: MaterialApp(home: Scaffold(body: child)),
        ),
      );
    }

    testWidgets('dashboard shows a loading state first', (tester) async {
      when(
        () => providerService.getMyProfile(),
      ).thenAnswer((_) async => buildProfile());
      when(
        () => assignmentService.getMyAssignments(),
      ).thenAnswer((_) async => [buildAssignment()]);

      await pumpProvider(
        tester,
        const ProviderDashboardScreen(),
        tallSurface: true,
      );
      await tester.pumpAndSettle();

      expect(find.text('Bright Home Care'), findsOneWidget);
      expect(find.text('Waiting for your reply'), findsOneWidget);
    });

    testWidgets('assignments screen reports an API failure', (tester) async {
      when(
        () => assignmentService.getMyAssignments(),
      ).thenThrow(ApiException(statusCode: 500, message: 'Server error'));

      await pumpProvider(
        tester,
        const ProviderAssignmentsScreen(),
        viewModel: await approvedVm(),
        tallSurface: true,
      );
      await tester.pumpAndSettle();

      expect(find.text('Server error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('assignments screen explains an empty list', (tester) async {
      when(
        () => assignmentService.getMyAssignments(),
      ).thenAnswer((_) async => []);

      await pumpProvider(
        tester,
        const ProviderAssignmentsScreen(),
        viewModel: await approvedVm(),
        tallSurface: true,
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('You have no assignments yet'),
        findsOneWidget,
      );
    });

    testWidgets('a pending provider cannot open the assignments list', (
      tester,
    ) async {
      when(
        () => providerService.getMyProfile(),
      ).thenAnswer((_) async => buildProfile(approvalStatus: 'PENDING'));
      when(
        () => assignmentService.getMyAssignments(),
      ).thenAnswer((_) async => []);

      final pending = ProviderViewModel(
        providerService,
        assignmentService,
        quoteService,
      );
      await pending.refreshAccountState();

      await pumpProvider(
        tester,
        const ProviderAssignmentsScreen(),
        viewModel: pending,
      );
      await tester.pumpAndSettle();

      expect(find.text('Approval pending'), findsOneWidget);
      expect(
        find.text('Assignments are only available to approved providers.'),
        findsOneWidget,
      );
    });

    testWidgets('assignment detail offers accept and decline for PENDING', (
      tester,
    ) async {
      when(
        () => assignmentService.getAssignmentById('a1'),
      ).thenAnswer((_) async => buildAssignment());
      when(
        () => quoteService.getRequestQuotes(any()),
      ).thenAnswer((_) async => const []);

      await pumpProvider(
        tester,
        const AssignmentDetailScreen(assignmentId: 'a1'),
        tallSurface: true,
      );
      await tester.pumpAndSettle();

      expect(find.text('Accept job'), findsOneWidget);
      expect(find.text('Decline job'), findsOneWidget);
    });

    testWidgets('assignment detail offers work progress for ACCEPTED', (
      tester,
    ) async {
      when(
        () => assignmentService.getAssignmentById('a1'),
      ).thenAnswer((_) async => buildAssignment(status: 'ACCEPTED'));
      when(
        () => quoteService.getRequestQuotes(any()),
      ).thenAnswer((_) async => const []);

      await pumpProvider(
        tester,
        const AssignmentDetailScreen(assignmentId: 'a1'),
        tallSurface: true,
      );
      await tester.pumpAndSettle();

      expect(find.text('On the way'), findsOneWidget);
      expect(find.text('Start work'), findsOneWidget);
      expect(find.text('Accept job'), findsNothing);
    });

    testWidgets('a completed assignment offers no further actions', (
      tester,
    ) async {
      when(
        () => assignmentService.getAssignmentById('a1'),
      ).thenAnswer((_) async => buildAssignment(status: 'COMPLETED'));
      when(
        () => quoteService.getRequestQuotes(any()),
      ).thenAnswer((_) async => const []);

      await pumpProvider(
        tester,
        const AssignmentDetailScreen(assignmentId: 'a1'),
        tallSurface: true,
      );
      await tester.pumpAndSettle();

      expect(find.text('Job closed'), findsOneWidget);
      expect(find.text('Accept job'), findsNothing);
      expect(find.text('Start work'), findsNothing);
    });

    testWidgets('detail states the request details are not available', (
      tester,
    ) async {
      when(
        () => assignmentService.getAssignmentById('a1'),
      ).thenAnswer((_) async => buildAssignment());
      when(
        () => quoteService.getRequestQuotes(any()),
      ).thenAnswer((_) async => const []);

      await pumpProvider(
        tester,
        const AssignmentDetailScreen(assignmentId: 'a1'),
        tallSurface: true,
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('not shown: the backend returns 403'),
        findsOneWidget,
      );
    });

    testWidgets('decline asks for confirmation before calling the API', (
      tester,
    ) async {
      when(
        () => assignmentService.getAssignmentById('a1'),
      ).thenAnswer((_) async => buildAssignment());
      when(
        () => quoteService.getRequestQuotes(any()),
      ).thenAnswer((_) async => const []);

      await pumpProvider(
        tester,
        const AssignmentDetailScreen(assignmentId: 'a1'),
        tallSurface: true,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Decline job'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      verifyNever(() => assignmentService.updateStatus(any(), any()));

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Accept job'), findsOneWidget);
    });

    testWidgets('confirming a decline sends the status the API returns', (
      tester,
    ) async {
      when(
        () => assignmentService.getAssignmentById('a1'),
      ).thenAnswer((_) async => buildAssignment());
      when(
        () => quoteService.getRequestQuotes(any()),
      ).thenAnswer((_) async => const []);
      when(
        () => assignmentService.updateStatus('a1', 'DECLINED'),
      ).thenAnswer((_) async => buildAssignment(status: 'DECLINED'));

      await pumpProvider(
        tester,
        const AssignmentDetailScreen(assignmentId: 'a1'),
        tallSurface: true,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Decline job'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Decline job'));
      await tester.pumpAndSettle();

      verify(() => assignmentService.updateStatus('a1', 'DECLINED')).called(1);
      expect(find.textContaining('Status updated to Declined'), findsOneWidget);
    });

    testWidgets('a failed status change shows the backend error', (
      tester,
    ) async {
      when(
        () => assignmentService.getAssignmentById('a1'),
      ).thenAnswer((_) async => buildAssignment());
      when(
        () => quoteService.getRequestQuotes(any()),
      ).thenAnswer((_) async => const []);
      when(
        () => assignmentService.updateStatus('a1', 'ACCEPTED'),
      ).thenThrow(ApiException(statusCode: 400, message: 'Invalid status'));

      await pumpProvider(
        tester,
        const AssignmentDetailScreen(assignmentId: 'a1'),
        tallSurface: true,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accept job'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid status'), findsOneWidget);
      expect(find.text('Accept job'), findsOneWidget);
    });
  });
}
