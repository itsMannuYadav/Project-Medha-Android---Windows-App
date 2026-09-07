import 'package:flutter/material.dart';

import '../core/widgets/bottom_nav.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/profile/profile_screen.dart';

const _adminNavItems = [
  MedhaNavItem('home', 'डैशबोर्ड'),
  MedhaNavItem('users_group', 'स्कूल'),
  MedhaNavItem('user', 'प्रोफ़ाइल'),
];

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          AdminDashboardScreen(),
          AdminSchoolsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: MedhaBottomNav(
        currentIndex: _index,
        items: _adminNavItems,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}
