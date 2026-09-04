// Smoke test: the app boots to the first-run language picker without
// throwing, and the primary call to action is present.

import 'package:flutter_test/flutter_test.dart';

import 'package:medha/main.dart';

void main() {
  testWidgets('boots to the language picker', (WidgetTester tester) async {
    await tester.pumpWidget(const MedhaApp());
    await tester.pump();

    expect(find.text('भाषा चुनें'), findsOneWidget);
    expect(find.text('जारी रखें'), findsOneWidget);
  });
}
