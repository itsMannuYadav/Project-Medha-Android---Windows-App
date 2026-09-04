import 'dart:async';

import 'package:flutter/material.dart';

import '../api/auth_api.dart';
import '../push/push_service.dart';
import '../state/app_state.dart';
import 'destination.dart';

/// After any successful sign-in (password login, Google, or a
/// PendingApproval "check status" call that turns out approved), fetch the
/// profile, update [AppState], and navigate to Onboarding or the signed-in
/// shell depending on whether onboarding is done. The one place this
/// routing decision is made, so it can't drift between entry points.
Future<void> completeLogin(BuildContext context, AppState appState) async {
  final me = await AuthApi.me();
  appState.setSignedIn(me);
  // Fire-and-forget: registers this device for push once we have a session,
  // but a slow/declined/unconfigured permission prompt should never delay
  // getting the signed-in teacher to their home screen.
  unawaited(PushService.registerDevice());
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => destinationFor(me)),
    (route) => false,
  );
}
