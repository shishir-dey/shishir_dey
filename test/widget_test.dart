// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shishir_dey/main.dart';

void main() {
  testWidgets('App initializes with Home tab selected', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts with the Home tab
    expect(find.text('Home'), findsWidgets);
    expect(find.byIcon(CupertinoIcons.home), findsOneWidget);

    // Verify that the "Coming soon" text is displayed
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('Can navigate between tabs', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const MyApp());

    // Tap on the Photography tab
    await tester.tap(find.byIcon(CupertinoIcons.photo));
    await tester.pumpAndSettle();

    // Verify that we're on the Photography tab
    expect(find.text('Photography'), findsWidgets);

    // Tap on the Diary tab
    await tester.tap(find.byIcon(CupertinoIcons.book));
    await tester.pumpAndSettle();

    // Verify that we're on the Diary tab
    expect(find.text('Diary'), findsWidgets);

    // Tap on the Contact tab
    await tester.tap(find.byIcon(CupertinoIcons.person));
    await tester.pumpAndSettle();

    // Verify that we're on the Contact tab
    expect(find.text('Contact'), findsWidgets);

    // Go back to Home tab
    await tester.tap(find.byIcon(CupertinoIcons.home));
    await tester.pumpAndSettle();

    // Verify that we're back on the Home tab
    expect(find.text('Home'), findsWidgets);
  });
}
