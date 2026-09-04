import 'package:flutter/material.dart';

import '../core/widgets/bottom_nav.dart';
import '../features/attendance/attendance_screen.dart';
import '../features/home/home_screen.dart';
import '../features/modules/modules_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/tools/tools_screen.dart';

/// The signed-in shell: five tabs behind one bottom nav, matching the
/// Home / Modules / Tools / Attendance / Profile screens on the canvas.
/// [IndexedStack] keeps each tab's scroll position and state alive when
/// switching, rather than rebuilding it from scratch.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          ModulesScreen(),
          ToolsScreen(),
          AttendanceScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: MedhaBottomNav(currentIndex: _index, onChanged: (i) => setState(() => _index = i)),
    );
  }
}
