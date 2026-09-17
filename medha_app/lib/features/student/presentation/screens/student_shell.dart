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

const _navItems = [
  _NavItem('/learn', 'Ask Medha', Icons.chat_bubble_outline_rounded),
  _NavItem('/bihar-darpan', 'Bihar Darpan', Icons.auto_awesome_rounded),
  _NavItem('/english', 'Learn English', Icons.language_rounded),
  _NavItem('/my-practice', 'Practice', Icons.edit_rounded),
  _NavItem('/my-notes', 'Notes', Icons.notes_rounded),
  _NavItem('/library', 'Library', Icons.book_rounded),
  _NavItem('/learn-lab', 'Simulations', Icons.science_rounded),
  _NavItem('/my-homework', 'Homework', Icons.assignment_rounded),
  _NavItem('/my-timetable', 'Timetable', Icons.calendar_today_rounded),
  _NavItem('/my-report-card', 'Report Card', Icons.bar_chart_rounded),
  _NavItem('/my-resources', 'E-Library', Icons.library_books_rounded),
  _NavItem('/fees', 'Fees', Icons.currency_rupee_rounded),
];

// Bottom nav shows first 4 items on mobile
const _bottomNavItems = [
  _NavItem('/learn', 'Ask', Icons.chat_bubble_outline_rounded),
  _NavItem('/bihar-darpan', 'Darpan', Icons.auto_awesome_rounded),
  _NavItem('/my-homework', 'Homework', Icons.assignment_rounded),
  _NavItem('/my-timetable', 'Schedule', Icons.calendar_today_rounded),
];

class StudentShell extends ConsumerStatefulWidget {
  final Widget child;
  const StudentShell({super.key, required this.child});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    return isWide ? _wideLayout() : _narrowLayout();
  }

  Widget _wideLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _DesktopSidebar(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/background.png',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.3),
                  ),
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
                widget.child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _narrowLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _MobileAppBar(onMenuTap: () {}),
      drawer: _MobileDrawer(onClose: () {}),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.3),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: AppColors.ivory.withValues(alpha: 0.88),
            ),
          ),
          widget.child,
        ],
      ),
      bottomNavigationBar: _BottomNav(),
    );
  }
}

class _DesktopSidebar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final user = ref.watch(authProvider).valueOrNull?.user;

    return Container(
      width: 240,
      color: AppColors.sidebar,
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: const MedhaLogo(height: 80),
          ),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    'MAIN',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedForeground,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ..._navItems.map((item) {
                  final active = location == item.path ||
                      location.startsWith('${item.path}/');
                  return _SidebarNavItem(item: item, active: active);
                }),
                // Sidebar quote
                const SizedBox(height: 16),
                _SidebarQuote(),
              ],
            ),
          ),
          // Footer
          Container(
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: AppColors.sidebarBorder)),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    const LanguageToggle(),
                    const Spacer(),
                    // Notification bell placeholder
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: AppColors.ink, size: 20),
                      onPressed: () =>
                          context.go('/my-notifications'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _StudentFooterMenu(user: user),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final _NavItem item;
  final bool active;

  const _SidebarNavItem({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
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
            Icon(
              item.icon,
              size: 16,
              color: active
                  ? AppColors.sidebarAccentForeground
                  : AppColors.ink.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: GoogleFonts.manrope(
                  fontSize: 13.5,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                  color: active
                      ? AppColors.sidebarAccentForeground
                      : AppColors.ink.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarQuote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sidebarBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"',
            style: GoogleFonts.fraunces(
                fontSize: 28, color: AppColors.terracotta.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 4),
          Text(
            'शिक्षा से समृद्ध बिहार, समृद्ध भारत',
            style: GoogleFonts.manrope(
                fontSize: 12.5,
                color: AppColors.sidebarForeground.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 10),
          // Indian tricolour stripe
          Container(
            height: 3,
            width: 64,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              gradient: LinearGradient(
                colors: [
                  AppColors.saffron,
                  AppColors.tricolorWhite,
                  AppColors.tricolorGreen,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentFooterMenu extends ConsumerWidget {
  final dynamic user;
  const _StudentFooterMenu({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user?.fullName ?? '';
    final initials = user?.initials() ?? '?';
    return GestureDetector(
      onTap: () => _showLogoutMenu(context, ref),
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
              child: Text(
                initials,
                style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? '—' : name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                        fontSize: 13, color: AppColors.ink),
                  ),
                  Text(
                    'Student',
                    style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppColors.mutedForeground),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_up_rounded,
                size: 16, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }

  void _showLogoutMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: AppColors.destructive),
              title: Text('Log out',
                  style: GoogleFonts.manrope(color: AppColors.destructive)),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuTap;
  const _MobileAppBar({required this.onMenuTap});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.sidebar,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: AppColors.ink),
        onPressed: onMenuTap,
      ),
      title: const MedhaLogo(height: 36),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: AppColors.ink, size: 22),
          onPressed: () {},
        ),
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: LanguageToggle(),
        ),
      ],
    );
  }
}

class _MobileDrawer extends ConsumerWidget {
  final VoidCallback onClose;
  const _MobileDrawer({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                children: _navItems.map((item) {
                  final active = location == item.path;
                  return ListTile(
                    onTap: () {
                      onClose();
                      Navigator.pop(context);
                      context.go(item.path);
                    },
                    leading: Icon(item.icon,
                        size: 18,
                        color: active
                            ? AppColors.terracotta
                            : AppColors.ink.withValues(alpha: 0.6)),
                    title: Text(
                      item.label,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? AppColors.terracotta : AppColors.ink,
                      ),
                    ),
                    tileColor: active
                        ? AppColors.sidebarAccent
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  );
                }).toList(),
              ),
            ),
            const Divider(color: AppColors.sidebarBorder),
            ListTile(
              leading:
                  const Icon(Icons.logout_rounded, color: AppColors.destructive),
              title: Text('Log out',
                  style: GoogleFonts.manrope(color: AppColors.destructive)),
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

class _BottomNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    return BottomNavigationBar(
      backgroundColor: AppColors.sidebar,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.terracotta,
      unselectedItemColor: AppColors.mutedForeground,
      selectedLabelStyle:
          GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.manrope(fontSize: 10),
      currentIndex: _currentIndex(location),
      onTap: (i) => context.go(_bottomNavItems[i].path),
      items: _bottomNavItems
          .map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon, size: 22),
                label: item.label,
              ))
          .toList(),
    );
  }

  int _currentIndex(String location) {
    for (var i = 0; i < _bottomNavItems.length; i++) {
      if (location == _bottomNavItems[i].path ||
          location.startsWith('${_bottomNavItems[i].path}/')) {
        return i;
      }
    }
    return 0;
  }
}
