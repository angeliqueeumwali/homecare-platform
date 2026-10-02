import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/service_request_model.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/widgets/service_category_widgets.dart';

ServiceCategoryModel category(String id, String name) => ServiceCategoryModel(
  id: id,
  name: name,
  description: '$name description',
  imageUrl: '/static/services/$name.png',
);

Widget wrap(Widget child) => MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.darkNavyBlue,
      onPrimary: Colors.white,
    ),
  ),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  final categories = [
    category('1', 'Elderly Care'),
    category('2', 'Laundry Services'),
    category('3', 'Pet Care'),
  ];

  group('ServiceCategoryDropdown', () {
    testWidgets('lists every category name so none must be typed', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ServiceCategoryDropdown(categories: categories, onChanged: (_) {}),
        ),
      );

      await tester.tap(
        find.byType(DropdownButtonFormField<ServiceCategoryModel>),
      );
      await tester.pumpAndSettle();

      for (final c in categories) {
        expect(find.text(c.name), findsOneWidget);
      }
    });

    testWidgets('does not expose raw category ids', (tester) async {
      await tester.pumpWidget(
        wrap(
          ServiceCategoryDropdown(categories: categories, onChanged: (_) {}),
        ),
      );

      await tester.tap(
        find.byType(DropdownButtonFormField<ServiceCategoryModel>),
      );
      await tester.pumpAndSettle();

      expect(find.text('1'), findsNothing);
      expect(find.textContaining('Enter category'), findsNothing);
    });

    testWidgets('reports the selected category object', (tester) async {
      ServiceCategoryModel? picked;
      await tester.pumpWidget(
        wrap(
          ServiceCategoryDropdown(
            categories: categories,
            onChanged: (value) => picked = value,
          ),
        ),
      );

      await tester.tap(
        find.byType(DropdownButtonFormField<ServiceCategoryModel>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Laundry Services').last);
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.id, '2');
      expect(picked!.name, 'Laundry Services');
    });

    testWidgets('shows a message instead of an empty dropdown', (tester) async {
      await tester.pumpWidget(
        wrap(ServiceCategoryDropdown(categories: const [])),
      );

      expect(find.text('No services available'), findsOneWidget);
      expect(
        find.byType(DropdownButtonFormField<ServiceCategoryModel>),
        findsNothing,
      );
    });

    testWidgets('accepts a re-fetched copy of the selected category', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ServiceCategoryDropdown(
            categories: categories,
            selected: category('2', 'Laundry Services'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Laundry Services'), findsOneWidget);
    });

    testWidgets('ignores duplicate category ids from the backend', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ServiceCategoryDropdown(
            categories: [categories[0], category('1', 'Elderly Care')],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('ServiceCategoryImage', () {
    testWidgets('falls back to a placeholder when there is no image', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const ServiceCategoryImage(category: null, size: 40)),
      );

      expect(find.byIcon(Icons.home_repair_service_outlined), findsOneWidget);
    });

    testWidgets('falls back to a placeholder when image_url is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ServiceCategoryImage(
            category: ServiceCategoryModel(id: '1', name: 'No image'),
            size: 40,
          ),
        ),
      );

      expect(find.byIcon(Icons.home_repair_service_outlined), findsOneWidget);
    });
  });
}
