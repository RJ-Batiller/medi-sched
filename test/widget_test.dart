// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finals_ggroup6/main.dart';

void main() {
  testWidgets('MediSched basic UI smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MediSchedApp());

    // Verify that the header and input exist.
    expect(find.text('MediSched'), findsOneWidget);
    expect(find.text('Full Name:'), findsOneWidget);

    // Enter a name and set default date/time, then submit.
    await tester.enterText(find.byType(TextField), 'Alice');
    await tester.tap(find.text('Default Date'));
    await tester.tap(find.text('Default Time'));
    await tester.tap(find.textContaining('Submit'));
    await tester.pumpAndSettle();

    // The appointment should appear in the list.
    expect(find.text('Alice'), findsOneWidget);
  });
}
