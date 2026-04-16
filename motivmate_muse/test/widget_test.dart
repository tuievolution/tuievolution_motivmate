// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motivmate/app_state.dart';
import 'package:motivmate/models/app_settings.dart';
import 'package:motivmate/models/quote.dart';
import 'package:motivmate/screens/home_screen.dart';
import 'package:motivmate/services/notification_service.dart';
import 'package:motivmate/services/quote_service.dart';
import 'package:motivmate/services/storage_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Home screen builds', (WidgetTester tester) async {
    final appState = AppState(
      storageService: StorageService(),
      quoteService: QuoteService(),
      notificationService: NotificationService(),
      initialSettings: AppSettings.defaults(),
      initialQuote: const Quote(
        text: 'Test quote',
        author: 'Tester',
        imageAsset: 'placeholder.png',
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('MotivMate'), findsOneWidget);
  });
}
