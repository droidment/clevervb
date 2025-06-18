// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic widget test', (WidgetTester tester) async {
    // Build a simple widget to test the framework is working
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Sports Team Manager'))),
      ),
    );

    // Verify that our widget displays the expected text
    expect(find.text('Sports Team Manager'), findsOneWidget);
  });

  testWidgets('Loading screen displays correctly', (WidgetTester tester) async {
    // Test a simple loading widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify loading elements are present
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);
  });
}
