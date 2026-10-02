import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Placeholder test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Homecare Platform'))),
      ),
    );

    expect(find.text('Homecare Platform'), findsOneWidget);
  });
}
