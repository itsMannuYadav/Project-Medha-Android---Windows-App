import 'dart:async';

import 'package:flutter/material.dart';

import 'core/api/auth_api.dart';
import 'core/auth/destination.dart';
import 'core/push/push_service.dart';
import 'core/state/app_state.dart';
import 'core/theme/medha_colors.dart';
import 'core/theme/medha_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/language/language_picker_screen.dart';

class MedhaApp extends StatefulWidget {
  const MedhaApp({super.key});

  @override
  State<MedhaApp> createState() => _MedhaAppState();
}

class _MedhaAppState extends State<MedhaApp> {
  final _appState = AppState();

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _appState,
      child: MaterialApp(
        title: 'मेधा',
        debugShowCheckedModeBanner: false,
        theme: MedhaTheme.light(),
        home: _StartupGate(appState: _appState),
      ),
    );
  }
}

/// Every cold start tries a silent `/auth/refresh` first (the refresh-token
/// cookie may still be valid), exactly like the web client -- only once that
/// fails does a fresh install actually see the language picker + login.
class _StartupGate extends StatefulWidget {
  const _StartupGate({required this.appState});
  final AppState appState;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final restored = await AuthApi.trySilentRefresh();
    if (!mounted) return;
    if (!restored) {
      widget.appState.setSignedOut();
      return;
    }
    try {
      final me = await AuthApi.me();
      if (!mounted) return;
      widget.appState.setSignedIn(me);
      unawaited(PushService.registerDevice());
    } catch (_) {
      if (!mounted) return;
      widget.appState.setSignedOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        switch (widget.appState.authStatus) {
          case AuthStatus.unknown:
            return const _SplashScreen();
          case AuthStatus.signedIn:
            return destinationFor(widget.appState.teacher!);
          case AuthStatus.signedOut:
            return LanguagePickerScreen(
              onDone: (lang) {
                widget.appState.language = lang;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            );
        }
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MedhaColors.bg,
      body: Center(
        child: CircularProgressIndicator(color: MedhaColors.primary),
      ),
    );
  }
}
