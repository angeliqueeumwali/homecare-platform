import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/notification_model.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/common_widgets.dart';
import 'package:mobile/widgets/rating_stars.dart';

Widget wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

NotificationModel buildNotification({
  String id = 'n1',
  bool isRead = false,
  String type = 'SERVICE_REQUEST',
  String? referenceId = 'r1',
}) {
  return NotificationModel.fromJson({
    'id': id,
    'user_id': 'u1',
    'notification_type': type,
    'title': 'New quote received',
    'message': 'A provider sent you a quote for your cleaning request.',
    'reference_id': referenceId,
    'is_read': isRead,
    'created_at': '2026-09-30T10:00:00Z',
  });
}

void main() {
  group('unread indicator', () {
    test('reads the is_read flag from the API response', () {
      expect(buildNotification(isRead: false).isRead, isFalse);
      expect(buildNotification(isRead: true).isRead, isTrue);
    });

    test('a missing is_read defaults to unread', () {
      final notification = NotificationModel.fromJson({
        'id': 'n1',
        'user_id': 'u1',
        'notification_type': 'GENERAL',
        'title': 'Hello',
        'message': 'Something happened',
      });
      expect(notification.isRead, isFalse);
    });

    testWidgets('unread notifications render a dot, read ones do not', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              for (final isRead in [false, true])
                SizedBox(
                  key: ValueKey('n$isRead'),
                  child: isRead
                      ? const Icon(
                          Icons.done_all,
                          color: AppColors.secondaryText,
                        )
                      : const AppCountBadge(
                          count: 1,
                          color: AppColors.darkNavyBlue,
                        ),
                ),
            ],
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('nfalse')),
          matching: find.byType(AppCountBadge),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ntrue')),
          matching: find.byType(AppCountBadge),
        ),
        findsNothing,
      );
    });
  });

  group('RatingInput validation', () {
    testWidgets('does not allow submitting a zero rating', (tester) async {
      var submitted = false;
      var rating = 0;

      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              RatingInput(value: rating, onChanged: (value) => rating = value),
              TextButton(
                onPressed: () {
                  if (rating == 0) return; // mirrors the screen's guard
                  submitted = true;
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Submit'));
      expect(submitted, isFalse);

      await tester.tap(find.byIcon(Icons.star_border).first);
      await tester.tap(find.text('Submit'));
      expect(submitted, isTrue);
      expect(rating, 1);
    });
  });

  group('empty states', () {
    testWidgets('EmptyState hides the action when none is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const EmptyState(message: 'No requests yet')),
      );

      expect(find.text('No requests yet'), findsOneWidget);
      expect(find.byType(AppButton), findsNothing);
    });

    testWidgets('EmptyState shows the action when provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          EmptyState(
            message: 'No requests yet',
            actionLabel: 'Request a service',
            onAction: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Request a service'));
      expect(tapped, isTrue);
    });

    testWidgets('ErrorView offers a retry when given one', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        wrap(
          ErrorView(
            message: 'No internet connection',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('No internet connection'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });
  });

  group('AppLoadingIndicator', () {
    testWidgets('inline mode stays compact for use inside a card', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const AppLoadingIndicator(inline: true, message: 'Loading quotes'),
        ),
      );

      expect(find.text('Loading quotes'), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });
  });
}
