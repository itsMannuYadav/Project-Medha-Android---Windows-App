import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/widgets/language_toggle.dart';
import '../../../shared/widgets/medha_logo.dart';

class _NavItem {
  final String path;
  final String label;
  final IconData icon;
  const _NavItem(this.path, this.label, this.icon);
}

const _teacherNav = [
  _NavItem('/dashboard', 'Dashboard', Icons.dashboard_rounded),
  _NavItem('/ask', 'Ask Medha', Icons.auto_awesome_rounded),
  _NavItem('/attendance', 'Attendance', Icons.how_to_reg_rounded),
  _NavItem('/students', 'Students', Icons.people_rounded),
  _NavItem('/homework', 'Homework', Icons.assignment_rounded),
  _NavItem('/timetable', 'Timetable', Icons.calendar_today_rounded),
  _NavItem('/report-card', 'Report Card', Icons.bar_chart_rounded),
  _NavItem('/notifications', 'Notifications', Icons.notifications_outlined),
  _NavItem('/profile', 'Profile', Icons.person_outline_rounded),
];

const _bottomNavTeacher = [
  _NavItem('/dashboard', 'Dashboard', Icons.dashboard_rounded),
  _NavItem('/attendance', 'Attendance', Icons.how_to_reg_rounded),
  _NavItem('/homework', 'Homework', Icons.assignment_rounded),
  _NavItem('/ask', 'Ask Medha', Icons.auto_awesome_rounded),
];

class TeacherShell extends ConsumerWidget {
  final Widget child;
  const TeacherShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    return isWide ? _wideLayout(context, ref) : _narrowLayout(context, ref);
  }

  Widget _wideLayout(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _TeacherDesktopSidebar(ref: ref),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset('assets/images/background.png',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.3)),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.ivory.withValues(alpha: 0.92),
                          AppColors.ivory.withValues(alpha: 0.78),
                          AppColors.ivory.withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _narrowLayout(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebar,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.ink),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const MedhaLogo(height: 36),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.ink, size: 22),
            onPressed: () => context.go('/notifications'),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: LanguageToggle(),
          ),
        ],
      ),
      drawer: _TeacherMobileDrawer(ref: ref),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.3)),
          ),
          Positioned.fill(child: Container(color: AppColors.ivory.withValues(alpha: 0.88))),
          child,
        ],
      ),
      bottomNavigationBar: _TeacherBottomNav(),
    );
  }
}

class _TeacherDesktopSidebar extends StatelessWidget {
  final WidgetRef ref;
  const _TeacherDesktopSidebar({required this.ref});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final user = ref.watch(authProvider).valueOrNull?.user;

    return Container(
      width: 240,
      color: AppColors.sidebar,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: const MedhaLogo(height: 80),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text('MAIN',
                      style: GoogleFonts.manrope(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: AppColors.mutedForeground, letterSpacing: 0.8)),
                ),
                ..._teacherNav.map((item) {
                  final active = location == item.path || location.startsWith('${item.path}/');
                  return GestureDetector(
                    onTap: () => context.go(item.path),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? AppColors.sidebarAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(item.icon, size: 16,
                              color: active ? AppColors.sidebarAccentForeground : AppColors.ink.withValues(alpha: 0.55)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item.label,
                                style: GoogleFonts.manrope(
                                    fontSize: 13.5,
                                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                    color: active ? AppColors.sidebarAccentForeground : AppColors.ink.withValues(alpha: 0.7))),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.sidebarBorder))),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    const LanguageToggle(),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: AppColors.ink, size: 20),
                      onPressed: () => context.go('/notifications'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _UserMenu(user: user, ref: ref),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  final dynamic user;
  final WidgetRef ref;
  const _UserMenu({this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? '';
    final initials = user?.initials() ?? '?';
    final role = user?.role ?? '';
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.destructive),
                title: Text('Log out', style: GoogleFonts.manrope(color: AppColors.destructive)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authProvider.notifier).logout();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent,
              child: Text(initials,
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? '—' : name,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(fontSize: 13, color: AppColors.ink)),
                  Text(role.isEmpty ? '' : role[0].toUpperCase() + role.substring(1),
                      style: GoogleFonts.manrope(fontSize: 11, color: AppColors.mutedForeground)),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_up_rounded, size: 16, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}

class _TeacherMobileDrawer extends StatelessWidget {
  final WidgetRef ref;
  const _TeacherMobileDrawer({required this.ref});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Drawer(
      backgroundColor: AppColors.sidebar,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const MedhaLogo(height: 70),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: _teacherNav.map((item) {
                  final active = location == item.path;
                  return ListTile(
                    onTap: () {
                      Navigator.pop(context);
                      context.go(item.path);
                    },
                    leading: Icon(item.icon, size: 18,
                        color: active ? AppColors.terracotta : AppColors.ink.withValues(alpha: 0.6)),
                    title: Text(item.label,
                        style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                            color: active ? AppColors.terracotta : AppColors.ink)),
                    tileColor: active ? AppColors.sidebarAccent : Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  );
                }).toList(),
              ),
            ),
            const Divider(color: AppColors.sidebarBorder),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.destructive),
              title: Text('Log out', style: GoogleFonts.manrope(color: AppColors.destructive)),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherBottomNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    int idx = 0;
    for (var i = 0; i < _bottomNavTeacher.length; i++) {
      if (location == _bottomNavTeacher[i].path || location.startsWith('${_bottomNavTeacher[i].path}/')) {
        idx = i;
        break;
      }
    }
    return BottomNavigationBar(
      backgroundColor: AppColors.sidebar,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.terracotta,
      unselectedItemColor: AppColors.mutedForeground,
      selectedLabelStyle: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.manrope(fontSize: 10),
      currentIndex: idx,
      onTap: (i) => context.go(_bottomNavTeacher[i].path),
      items: _bottomNavTeacher.map((item) => BottomNavigationBarItem(
        icon: Icon(item.icon, size: 22),
        label: item.label,
      )).toList(),
    );
  }
}
