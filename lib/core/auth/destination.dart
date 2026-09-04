import 'package:flutter/widgets.dart';

import '../../features/onboarding/onboarding_screen.dart';
import '../../shell/app_shell.dart';
import '../../shell/principal_shell.dart';
import '../../shell/student_shell.dart';
import '../models/teacher.dart';

/// The one place that decides which top-level screen a signed-in user lands
/// on -- used both at cold start (`app.dart`) and right after a fresh
/// login (`complete_login.dart`), so the two can never drift apart.
///
/// Onboarding (picking subjects/grades taught) is a *teacher*-only step --
/// the backend only ever sets `onboarded_at` via `/onboarding/complete`,
/// which students and principals never call, so gating on `needsOnboarding`
/// for every role would strand them on a screen that asks a student "which
/// classes do you teach?" forever.
Widget destinationFor(TeacherMe me) {
  switch (me.role) {
    case 'student':
      return const StudentShell();
    case 'principal':
      return const PrincipalShell();
    case 'teacher':
      return me.needsOnboarding ? const OnboardingScreen() : const AppShell();
    default:
      // admin (and any future role): this app was built for teacher/student/
      // principal use in the district pilot -- admins manage the program
      // from the web console. Fall back to the teacher shell rather than a
      // blank screen; it's read-only-broken at worst, not a crash.
      return const AppShell();
  }
}
