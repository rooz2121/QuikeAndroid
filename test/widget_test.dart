// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quike_ai/main.dart';
import 'package:quike_ai/config/app_config.dart';

void main() {
  // Skip tests in production build
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(appConfig: AppConfig()));
    
    // Basic existence check
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
