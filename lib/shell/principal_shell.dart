import 'package:flutter/material.dart';

import '../core/widgets/bottom_nav.dart';
import '../features/fees/fees_screen.dart';
import '../features/principal/principal_dashboard_screen.dart';
import '../features/principal/student_roster_screen.dart';
import '../features/principal/teacher_roster_screen.dart';
import '../features/profile/profile_screen.dart';

const _principalNavItems = [
  MedhaNavItem('tools_grid', 'डैशबोर्ड'),
  MedhaNavItem('users_group', 'शिक्षक'),
  MedhaNavItem('users_group', 'छात्र'),
  MedhaNavItem('receipt', 'फीस'),
  MedhaNavItem('user', 'प्रोफ़ाइल'),
];

/// The signed-in shell for a principal/school office user: Dashboard,
/// Teachers, Students, Fees and Profile behind one bottom nav -- mirrors
/// [AppShell]'s pattern exactly. Teacher approvals and announcements are
/// reached from the Dashboard's quick links rather than being their own
/// tabs, matching the canvas mockups.
class PrincipalShell extends StatefulWidget {
  const PrincipalShell({super.key});

  @override
  State<PrincipalShell> createState() => _PrincipalShellState();
}

class _PrincipalShellState extends State<PrincipalShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          PrincipalDashboardScreen(),
          TeacherRosterScreen(),
          StudentRosterScreen(),
          FeesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: MedhaBottomNav(
        currentIndex: _index,
        items: _principalNavItems,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}
