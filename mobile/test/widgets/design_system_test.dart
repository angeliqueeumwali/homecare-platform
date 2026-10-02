import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/constants/status_constants.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/widgets/common_widgets.dart';
import 'package:mobile/widgets/promo_banner.dart';
import 'package:mobile/widgets/rating_stars.dart';
import 'package:mobile/widgets/status_timeline.dart';

Widget wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  group('timelineStepIndex', () {
    test('returns the position of a status on the happy path', () {
      expect(timelineStepIndex('PENDING', serviceRequestTimelineSteps), 0);
      expect(
        timelineStepIndex('PROVIDER_ASSIGNED', serviceRequestTimelineSteps),
        2,
      );
      expect(timelineStepIndex('COMPLETED', serviceRequestTimelineSteps), 4);
    });

    test('is case insensitive', () {
      expect(
        timelineStepIndex('in_progress', assignmentTimelineSteps),
        timelineStepIndex('IN_PROGRESS', assignmentTimelineSteps),
      );
    });

    test('returns -1 for a status that is off the happy path', () {
      expect(timelineStepIndex('CANCELLED', serviceRequestTimelineSteps), -1);
      expect(timelineStepIndex('DECLINED', assignmentTimelineSteps), -1);
      expect(timelineStepIndex('NOT_A_STATUS', assignmentTimelineSteps), -1);
    });
  });

  group('isTerminalFailureStatus', () {
    test('recognises the statuses that stop progress', () {
      expect(isTerminalFailureStatus('CANCELLED'), isTrue);
      expect(isTerminalFailureStatus('DECLINED'), isTrue);
      expect(isTerminalFailureStatus('REJECTED'), isTrue);
    });

    test('does not treat normal progress as a failure', () {
      expect(isTerminalFailureStatus('PENDING'), isFalse);
      expect(isTerminalFailureStatus('IN_PROGRESS'), isFalse);
      expect(isTerminalFailureStatus('COMPLETED'), isFalse);
      expect(isTerminalFailureStatus('APPROVED'), isFalse);
    });
  });

  group('StatusTimeline', () {
    testWidgets('marks every step up to the current status as done', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const StatusTimeline(
            currentStatus: 'PROVIDER_ASSIGNED',
            steps: serviceRequestTimelineSteps,
          ),
        ),
      );

      // Three steps before the current one are complete.
      expect(find.byIcon(Icons.check), findsNWidgets(2));
      expect(find.text('Current status'), findsOneWidget);
      expect(find.text('Provider Assigned'), findsOneWidget);
    });

    testWidgets('renders all steps for a fresh request', (tester) async {
      await tester.pumpWidget(
        wrap(
          const StatusTimeline(
            currentStatus: 'PENDING',
            steps: serviceRequestTimelineSteps,
          ),
        ),
      );

      for (final step in serviceRequestTimelineSteps) {
        expect(find.text(getStatusDisplayName(step)), findsOneWidget);
      }
    });

    testWidgets('shows a failure state instead of progress for CANCELLED', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const StatusTimeline(
            currentStatus: 'CANCELLED',
            steps: serviceRequestTimelineSteps,
          ),
        ),
      );

      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Current status'), findsNothing);
      expect(find.text('This was stopped before completion.'), findsOneWidget);
    });

    testWidgets('uses different copy for a declined assignment', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const StatusTimeline(
            currentStatus: 'DECLINED',
            steps: assignmentTimelineSteps,
          ),
        ),
      );

      expect(find.text('Declined'), findsOneWidget);
      expect(find.text('This did not go ahead.'), findsOneWidget);
    });
  });

  group('RatingStars', () {
    testWidgets('shows a new label when there is no rating yet', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const RatingStars(rating: 0)));
      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('renders a full set of filled stars for a rating of 5', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const RatingStars(rating: 5)));
      expect(find.byIcon(Icons.star), findsNWidgets(5));
      expect(find.text('5.0'), findsOneWidget);
    });

    testWidgets('renders half stars for a fractional rating', (tester) async {
      await tester.pumpWidget(wrap(const RatingStars(rating: 3.5)));
      expect(find.byIcon(Icons.star_half), findsNWidgets(1));
    });
  });

  group('RatingInput', () {
    testWidgets('reports the tapped star', (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        wrap(RatingInput(value: selected, onChanged: (v) => selected = v)),
      );

      await tester.tap(find.byIcon(Icons.star_border).at(2));
      expect(selected, 3);
    });
  });

  group('FilterChipRow', () {
    testWidgets('shows every option and reports the selected one', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        wrap(
          FilterChipRow(
            options: const ['PENDING', 'IN_PROGRESS', 'COMPLETED'],
            selected: 'PENDING',
            onSelected: (v) => picked = v,
          ),
        ),
      );

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      await tester.tap(find.text('Completed'));
      expect(picked, 'COMPLETED');
    });
  });

  group('AppSearchBar', () {
    testWidgets('reports typed text', (tester) async {
      String? query;
      await tester.pumpWidget(wrap(AppSearchBar(onChanged: (v) => query = v)));

      await tester.enterText(find.byType(TextField), 'plumbing');
      expect(query, 'plumbing');
    });

    testWidgets('shows a filter badge only when filters are active', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          AppSearchBar(
            onChanged: (_) {},
            onFilterTap: () {},
            activeFilterCount: 0,
          ),
        ),
      );
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.text('0'), findsNothing);

      await tester.pumpWidget(
        wrap(
          AppSearchBar(
            onChanged: (_) {},
            onFilterTap: () {},
            activeFilterCount: 2,
          ),
        ),
      );
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('PromoBanner', () {
    testWidgets('shows the title, subtitle and action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          PromoBanner(
            title: 'Book trusted care',
            subtitle: 'Verified providers near you',
            actionLabel: 'Browse',
            onAction: () => tapped = true,
            icon: Icons.local_offer_outlined,
          ),
        ),
      );

      expect(find.text('Book trusted care'), findsOneWidget);
      expect(find.text('Verified providers near you'), findsOneWidget);

      await tester.tap(find.text('Browse'));
      expect(tapped, isTrue);
    });
  });

  group('AppLoadingIndicator', () {
    testWidgets('shows a spinner and caption', (tester) async {
      await tester.pumpWidget(
        wrap(const AppLoadingIndicator(message: 'Loading services')),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading services'), findsOneWidget);
    });
  });

  group('InfoRow', () {
    testWidgets('falls back when a value is missing', (tester) async {
      await tester.pumpWidget(wrap(const InfoRow(label: 'Address')));
      expect(find.text('Not provided'), findsOneWidget);
    });

    testWidgets('shows the value when present', (tester) async {
      await tester.pumpWidget(
        wrap(const InfoRow(label: 'Address', value: '12 Test Road')),
      );
      expect(find.text('12 Test Road'), findsOneWidget);
      expect(find.text('Not provided'), findsNothing);
    });
  });

  group('SectionHeader', () {
    testWidgets('shows the action only when a callback is given', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const SectionHeader(title: 'Services')));
      expect(find.text('Services'), findsOneWidget);
      expect(find.text('See all'), findsNothing);

      var tapped = false;
      await tester.pumpWidget(
        wrap(
          SectionHeader(
            title: 'Services',
            actionLabel: 'See all',
            onAction: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.text('See all'));
      expect(tapped, isTrue);
    });
  });

  group('AppCountBadge', () {
    testWidgets('renders nothing when the count is zero', (tester) async {
      await tester.pumpWidget(wrap(const AppCountBadge(count: 0)));
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('caps the label at 99+', (tester) async {
      await tester.pumpWidget(wrap(const AppCountBadge(count: 250)));
      expect(find.text('99+'), findsOneWidget);
    });
  });

  group('theme', () {
    test('keeps the navy palette used by the design system', () {
      expect(AppColors.darkNavyBlue, const Color(0xFF142B4A));
      expect(AppColors.secondaryNavyBlue, const Color(0xFF203D63));
      expect(AppColors.deepNavyBlue, const Color(0xFF0B1F38));
      expect(AppColors.lightGrey, const Color(0xFFF5F7FA));
      expect(AppColors.borderGrey, const Color(0xFFE2E8F0));
    });
  });
}
