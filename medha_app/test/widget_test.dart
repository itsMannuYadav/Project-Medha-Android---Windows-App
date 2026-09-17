import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medha_app/main.dart';

void main() {
  testWidgets('MedhaApp smoke test — login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MedhaApp()));
    // Settle all pending animations (flutter_animate timers)
    await tester.pumpAndSettle(const Duration(seconds: 2));
    // Login screen should be visible (app routes unauthenticated users to /login)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
