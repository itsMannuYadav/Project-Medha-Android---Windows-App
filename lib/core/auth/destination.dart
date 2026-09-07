import 'package:flutter/widgets.dart';

import '../../features/onboarding/onboarding_screen.dart';
import '../../shell/admin_shell.dart';
import '../../shell/app_shell.dart';
import '../../shell/principal_shell.dart';
import '../../shell/student_shell.dart';
import '../models/teacher.dart';

Widget destinationFor(TeacherMe me) {
  switch (me.role) {
    case 'student':
      return const StudentShell();
    case 'principal':
      return const PrincipalShell();
    case 'teacher':
      return me.needsOnboarding ? const OnboardingScreen() : const AppShell();
    case 'admin':
      return const AdminShell();
    default:
      return const AppShell();
  }
}
