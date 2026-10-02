import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/status_constants.dart';
import 'package:mobile/models/payment_model.dart';
import 'package:mobile/models/quote_model.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/payment_service.dart';
import 'package:mobile/services/quote_service.dart';
import 'package:mocktail/mocktail.dart';

class MockQuoteService extends Mock implements QuoteService {}

class MockPaymentService extends Mock implements PaymentService {}

QuoteModel buildQuote({
  String id = 'q1',
  String status = 'PENDING',
  String amount = '5000',
}) {
  return QuoteModel(
    id: id,
    serviceRequestId: 'r1',
    serviceRequestItemId: 'i1',
    providerId: 'p1',
    amount: amount,
    currency: 'RWF',
    status: status,
  );
}

PaymentModel buildPayment({
  String id = 'pay1',
  String status = 'PENDING',
  String amount = '5000',
}) {
  return PaymentModel.fromJson({
    'id': id,
    'service_request_id': 'r1',
    'quote_id': 'q1',
    'customer_id': 'c1',
    'amount': amount,
    'currency': 'RWF',
    'payment_method': 'MOBILE_MONEY',
    'status': status,
    'transaction_reference': null,
  });
}

void main() {
  // mocktail needs a fallback value to match `any()` on a custom type.
  setUpAll(() {
    registerFallbackValue(
      PaymentCreateRequest(
        serviceRequestId: 'r1',
        quoteId: 'q1',
        amount: '0',
        paymentMethod: 'MOBILE_MONEY',
      ),
    );
  });

  group('QuoteViewModel request scoping', () {
    late MockQuoteService service;
    late QuoteViewModel vm;

    setUp(() {
      service = MockQuoteService();
      vm = QuoteViewModel(service);
    });

    test('records which request the quotes belong to', () async {
      when(
        () => service.getRequestQuotes('r1'),
      ).thenAnswer((_) async => [buildQuote()]);

      await vm.fetchRequestQuotes('r1');

      expect(vm.activeRequestId, 'r1');
      expect(vm.quotes.length, 1);
    });

    test(
      'clears the previous request quotes while loading a new one',
      () async {
        when(
          () => service.getRequestQuotes('r1'),
        ).thenAnswer((_) async => [buildQuote(id: 'old')]);
        await vm.fetchRequestQuotes('r1');
        expect(vm.quotes.length, 1);

        // A slow second request must not leave the first request's quotes up.
        when(() => service.getRequestQuotes('r2')).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return [buildQuote(id: 'new')];
        });
        final pending = vm.fetchRequestQuotes('r2');

        expect(vm.quotes, isEmpty);
        expect(vm.activeRequestId, 'r2');

        await pending;
        expect(vm.quotes.single.id, 'new');
      },
    );

    test('leaves no stale quotes when the new fetch fails', () async {
      when(
        () => service.getRequestQuotes('r1'),
      ).thenAnswer((_) async => [buildQuote()]);
      await vm.fetchRequestQuotes('r1');

      when(
        () => service.getRequestQuotes('r2'),
      ).thenThrow(ApiException(statusCode: 404, message: 'Not found'));
      await vm.fetchRequestQuotes('r2');

      expect(vm.quotes, isEmpty);
      expect(vm.activeRequestId, 'r2');
      expect(vm.errorMessage, 'Not found');
    });

    test('clearRequestQuotes resets the scope', () async {
      when(
        () => service.getRequestQuotes('r1'),
      ).thenAnswer((_) async => [buildQuote()]);
      await vm.fetchRequestQuotes('r1');

      vm.clearRequestQuotes();

      expect(vm.quotes, isEmpty);
      expect(vm.activeRequestId, isNull);
    });

    test('accept sends APPROVED and updates the local copy', () async {
      when(
        () => service.getRequestQuotes('r1'),
      ).thenAnswer((_) async => [buildQuote(id: 'q1', status: 'PENDING')]);
      await vm.fetchRequestQuotes('r1');

      when(
        () => service.updateStatus('q1', 'APPROVED'),
      ).thenAnswer((_) async => buildQuote(id: 'q1', status: 'APPROVED'));

      final ok = await vm.acceptQuote('q1');

      expect(ok, isTrue);
      verify(() => service.updateStatus('q1', 'APPROVED')).called(1);
      expect(vm.quotes.single.status, 'APPROVED');
    });

    test('reject sends REJECTED and updates the local copy', () async {
      when(
        () => service.getRequestQuotes('r1'),
      ).thenAnswer((_) async => [buildQuote(id: 'q1', status: 'PENDING')]);
      await vm.fetchRequestQuotes('r1');

      when(
        () => service.updateStatus('q1', 'REJECTED'),
      ).thenAnswer((_) async => buildQuote(id: 'q1', status: 'REJECTED'));

      final ok = await vm.rejectQuote('q1');

      expect(ok, isTrue);
      expect(vm.quotes.single.status, 'REJECTED');
    });

    test('a rejected API call does not change the quote status', () async {
      when(
        () => service.getRequestQuotes('r1'),
      ).thenAnswer((_) async => [buildQuote(id: 'q1', status: 'PENDING')]);
      await vm.fetchRequestQuotes('r1');

      when(
        () => service.updateStatus('q1', 'APPROVED'),
      ).thenThrow(ApiException(statusCode: 403, message: 'Not your quote'));

      final ok = await vm.acceptQuote('q1');

      expect(ok, isFalse);
      expect(vm.errorMessage, 'Not your quote');
      expect(vm.quotes.single.status, 'PENDING');
    });
  });

  group('PaymentViewModel status honesty', () {
    late MockPaymentService service;
    late PaymentViewModel vm;

    setUp(() {
      service = MockPaymentService();
      vm = PaymentViewModel(service);
    });

    test('a created payment keeps the status the API returned', () async {
      when(
        () => service.createPayment(any()),
      ).thenAnswer((_) async => buildPayment(status: 'PENDING'));

      final payment = await vm.createPayment(
        serviceRequestId: 'r1',
        quoteId: 'q1',
        amount: '5000',
        currency: 'RWF',
        paymentMethod: 'MOBILE_MONEY',
      );

      expect(payment?.status, 'PENDING');
      expect(payment!.status.toUpperCase(), PaymentStatus.pending);
    });

    test('never upgrades a pending payment on its own', () async {
      when(
        () => service.createPayment(any()),
      ).thenAnswer((_) async => buildPayment(status: 'PENDING'));

      final payment = await vm.createPayment(
        serviceRequestId: 'r1',
        quoteId: 'q1',
        amount: '5000',
        paymentMethod: 'MOBILE_MONEY',
      );

      // The status must be whatever the server said, never rewritten locally.
      expect(payment?.status, isNot('PAID'));
      expect(vm.payments.single.status, 'PENDING');
    });

    test('reports PAID only when the API reports it', () async {
      when(
        () => service.createPayment(any()),
      ).thenAnswer((_) async => buildPayment(status: 'PAID'));

      final payment = await vm.createPayment(
        serviceRequestId: 'r1',
        quoteId: 'q1',
        amount: '5000',
        paymentMethod: 'CARD',
      );

      expect(payment?.status.toUpperCase(), PaymentStatus.paid);
    });

    test(
      'records the error and returns null when the backend refuses',
      () async {
        when(() => service.createPayment(any())).thenThrow(
          ApiException(
            statusCode: 400,
            message: 'Quote must be approved before payment',
          ),
        );

        final payment = await vm.createPayment(
          serviceRequestId: 'r1',
          quoteId: 'q1',
          amount: '5000',
          paymentMethod: 'MOBILE_MONEY',
        );

        expect(payment, isNull);
        expect(vm.errorMessage, 'Quote must be approved before payment');
        expect(vm.payments, isEmpty);
      },
    );

    test('amount mismatch from the backend is surfaced, not hidden', () async {
      when(() => service.createPayment(any())).thenThrow(
        ApiException(
          statusCode: 400,
          message: 'Payment amount must match the approved quote',
        ),
      );

      final payment = await vm.createPayment(
        serviceRequestId: 'r1',
        quoteId: 'q1',
        amount: '1',
        paymentMethod: 'MOBILE_MONEY',
      );

      expect(payment, isNull);
      expect(vm.errorMessage, contains('must match'));
    });
  });
}
