import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:medha_app/core/network/api_client.dart';
import 'package:medha_app/core/theme/app_theme.dart';
import 'package:medha_app/features/student/presentation/screens/student_shell.dart';
import 'package:medha_app/features/teacher/presentation/screens/teacher_shell.dart';

import 'helpers/test_harness.dart';

/// The shells carry the mobile chrome — AppBar, Drawer, BottomNavigationBar.
/// They need a live GoRouter (they call `GoRouterState.of`), so they can't go
/// through the plain harness the content screens use.
Widget shellHarness(Widget Function(Widget) buildShell, String initial,
    {double textScale = 1.0}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
    ..httpClientAdapter = FakeAdapter();

  final router = GoRouter(
    initialLocation: initial,
    routes: [
      ShellRoute(
        builder: (ctx, state, child) => buildShell(child),
        routes: [
          GoRoute(path: initial, builder: (c, s) => const SizedBox.shrink()),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
      builder: (ctx, widget) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(textScale)),
        child: widget!,
      ),
    ),
  );
}

void main() {
  final shells = <String, (Widget Function(Widget), String)>{
    'Student shell': ((child) => StudentShell(child: child), '/learn'),
    'Teacher shell': ((child) => TeacherShell(child: child), '/dashboard'),
  };

  for (final phone in Phone.all) {
    shells.forEach((label, cfg) {
      testWidgets('$label — ${phone.name}', (tester) async {
        tester.view.physicalSize = phone.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        FlutterErrorDetails? captured;
        final prev = FlutterError.onError;
        FlutterError.onError = (d) => captured ??= d;
        addTearDown(() => FlutterError.onError = prev);

        await tester.pumpWidget(shellHarness(cfg.$1, cfg.$2));
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        if (captured != null && isOverflow(captured!)) {
          fail('$label OVERFLOWED at ${phone.name}:\n${captured!.exception}');
        }
      });
    });
  }

  // Drawer open, smallest phone, enlarged font — the 12-item student nav is the
  // densest list in the app.
  shells.forEach((label, cfg) {
    testWidgets('$label drawer — 320px @ 1.3x text', (tester) async {
      tester.view.physicalSize = Phone.iphoneSe.size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      FlutterErrorDetails? captured;
      final prev = FlutterError.onError;
      FlutterError.onError = (d) => captured ??= d;
      addTearDown(() => FlutterError.onError = prev);

      await tester.pumpWidget(shellHarness(cfg.$1, cfg.$2, textScale: 1.3));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      final scaffold = find.byType(Scaffold);
      if (scaffold.evaluate().isNotEmpty) {
        final state = tester.firstState<ScaffoldState>(scaffold);
        if (state.hasDrawer) {
          state.openDrawer();
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 250));
          }
        }
      }
      if (captured != null && isOverflow(captured!)) {
        fail('$label drawer OVERFLOWED:\n${captured!.exception}');
      }
    });
  });
}
