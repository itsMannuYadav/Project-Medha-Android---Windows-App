import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medha_app/features/student/presentation/screens/homework_screen.dart';
import 'package:medha_app/features/student/presentation/screens/timetable_screen.dart';
import 'package:medha_app/features/student/presentation/screens/fees_screen.dart';
import 'package:medha_app/features/student/presentation/screens/report_card_screen.dart';
import 'package:medha_app/features/student/presentation/screens/library_screen.dart';
import 'package:medha_app/features/student/presentation/screens/resources_screen.dart';
import 'package:medha_app/features/student/presentation/screens/notes_screen.dart';
import 'package:medha_app/features/student/presentation/screens/practice_screen.dart';
import 'package:medha_app/features/student/presentation/screens/simulations_screen.dart';
import 'package:medha_app/features/student/presentation/screens/english_screen.dart';
import 'package:medha_app/features/student/presentation/screens/bihar_darpan_screen.dart';
import 'package:medha_app/features/student/presentation/screens/learn_screen.dart';

import 'package:medha_app/features/teacher/presentation/screens/teacher_dashboard_screen.dart';
import 'package:medha_app/features/teacher/presentation/screens/teacher_students_screen.dart';
import 'package:medha_app/features/teacher/presentation/screens/teacher_attendance_screen.dart';
import 'package:medha_app/features/teacher/presentation/screens/teacher_homework_screen.dart';
import 'package:medha_app/features/teacher/presentation/screens/teacher_timetable_screen.dart';
import 'package:medha_app/features/teacher/presentation/screens/teacher_report_card_screen.dart';
import 'package:medha_app/features/teacher/presentation/screens/teacher_notifications_screen.dart';
import 'package:medha_app/features/teacher/presentation/screens/teacher_profile_screen.dart';
import 'package:medha_app/features/teacher/presentation/screens/teacher_onboarding_screen.dart';

import 'package:medha_app/features/principal/presentation/screens/principal_dashboard_screen.dart';

import 'package:medha_app/features/auth/presentation/screens/login_screen.dart';
import 'package:medha_app/features/auth/presentation/screens/register_screen.dart';
import 'package:medha_app/features/auth/presentation/screens/student_activate_screen.dart';

import 'helpers/test_harness.dart';

/// Every screen, at every phone size we support. A RenderFlex overflow throws
/// during layout, so these fail loudly rather than silently shipping a
/// yellow-and-black striped band to a real student's phone.
void main() {
  final screens = <String, Widget Function()>{
    // Auth — the first thing every user sees, and the densest forms in the app
    'Auth / Login': () => const LoginScreen(),
    'Auth / Register': () => const RegisterScreen(),
    'Auth / Student Activate': () => const StudentActivateScreen(),
    // Student
    'Student / Homework': () => const HomeworkScreen(),
    'Student / Timetable': () => const TimetableScreen(),
    'Student / Fees': () => const FeesScreen(),
    'Student / Report Card': () => const ReportCardScreen(),
    'Student / Library': () => const LibraryScreen(),
    'Student / Resources': () => const ResourcesScreen(),
    'Student / Notes': () => const NotesScreen(),
    'Student / Practice': () => const PracticeScreen(),
    'Student / Simulations': () => const SimulationsScreen(),
    'Student / English': () => const EnglishScreen(),
    'Student / Bihar Darpan': () => const BiharDarpanScreen(),
    'Student / Learn (AI tutor)': () => const LearnScreen(),
    // Teacher
    'Teacher / Onboarding': () => const TeacherOnboardingScreen(),
    'Teacher / Dashboard': () => const TeacherDashboardScreen(),
    'Teacher / Students': () => const TeacherStudentsScreen(),
    'Teacher / Attendance': () => const TeacherAttendanceScreen(),
    'Teacher / Homework': () => const TeacherHomeworkScreen(),
    'Teacher / Timetable': () => const TeacherTimetableScreen(),
    'Teacher / Report Card': () => const TeacherReportCardScreen(),
    'Teacher / Notifications': () => const TeacherNotificationsScreen(),
    'Teacher / Profile': () => const TeacherProfileScreen(),
    // Principal
    'Principal / Dashboard': () => const PrincipalDashboardScreen(),
  };

  for (final phone in Phone.all) {
    group(phone.name, () {
      screens.forEach((label, build) {
        testWidgets('$label lays out with no overflow', (tester) async {
          final err = await pumpAtPhone(tester, build(), phone);
          if (err != null && isOverflow(err)) {
            fail('$label OVERFLOWED at ${phone.name}:\n${err.exception}');
          }
        });
      });
    });
  }

  // Worst realistic case: smallest phone *and* an enlarged system font. Many
  // users bump font size in Android accessibility settings, and it is the
  // fastest way to break a layout that looks fine at the default scale.
  group('iPhone SE + 1.3x system font', () {
    screens.forEach((label, build) {
      testWidgets('$label survives large text', (tester) async {
        final err = await pumpAtPhone(tester, build(), Phone.iphoneSe, textScale: 1.3);
        if (err != null && isOverflow(err)) {
          fail('$label OVERFLOWED at 320px with 1.3x text:\n${err.exception}');
        }
      });
    });
  });
}
