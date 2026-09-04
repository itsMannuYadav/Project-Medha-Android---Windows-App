import 'package:flutter/material.dart';

import '../core/widgets/bottom_nav.dart';
import '../features/homework/homework_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/report_card/report_card_screen.dart';
import '../features/timetable/timetable_screen.dart';
import '../features/tutor/tutor_screen.dart';

const _studentNavItems = [
  MedhaNavItem('home', 'होम'),
  MedhaNavItem('clipboard', 'गृहकार्य'),
  MedhaNavItem('grid_calendar', 'समय सारिणी'),
  MedhaNavItem('report', 'रिपोर्ट'),
  MedhaNavItem('user', 'प्रोफ़ाइल'),
];

/// The signed-in shell for a student: doubt-chat (Tutor), Homework,
/// Timetable, Report Card and Profile behind one bottom nav -- mirrors
/// [AppShell]'s pattern exactly, just with the student's own 5 screens.
/// Notes/Practice/E-Library are reached from Tutor's quick actions;
/// Notifications from the bell in Tutor's top bar (see [NotificationBell]).
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          TutorScreen(),
          HomeworkScreen(),
          TimetableScreen(),
          ReportCardScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: MedhaBottomNav(
        currentIndex: _index,
        items: _studentNavItems,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}
