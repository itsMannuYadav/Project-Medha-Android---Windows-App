import 'package:flutter/material.dart';

import '../core/widgets/bottom_nav.dart';
import '../features/english/english_screen.dart';
import '../features/homework/homework_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/timetable/timetable_screen.dart';
import '../features/tutor/tutor_screen.dart';

const _studentNavItems = [
  MedhaNavItem('home', 'होम'),
  MedhaNavItem('translate', 'English'),
  MedhaNavItem('clipboard', 'गृहकार्य'),
  MedhaNavItem('grid_calendar', 'समय सारिणी'),
  MedhaNavItem('user', 'प्रोफ़ाइल'),
];

/// Student shell — Learn, English, Homework, Timetable, Profile.
/// Fees / Report Card / Notes / Practice / Library remain reachable from
/// Tutor quick actions (and Profile can deep-link later).
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
          EnglishScreen(),
          HomeworkScreen(),
          TimetableScreen(),
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
