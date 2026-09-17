import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends ConsumerState<TeacherDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ref.read(apiClientProvider).get('/teacher/dashboard');
      if (mounted) setState(() { _stats = res.data as Map<String, dynamic>?; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull?.user;
    final name = user?.firstName ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero greeting banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Hello!' : 'Hello, $name!',
                  style: GoogleFonts.fraunces(
                      fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'What are you teaching today?',
                  style: GoogleFonts.manrope(fontSize: 14, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),

          // Stats grid
          if (!_loading && _stats != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _StatsGrid(stats: _stats!),
            ),

          // Quick actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Actions',
                    style: GoogleFonts.manrope(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.0,
                  children: const [
                    _QuickAction(label: 'Take Attendance', icon: Icons.how_to_reg_rounded,
                        color: AppColors.sage, path: '/attendance'),
                    _QuickAction(label: 'Assign Homework', icon: Icons.assignment_rounded,
                        color: AppColors.gold, path: '/homework'),
                    _QuickAction(label: 'Ask Medha AI', icon: Icons.auto_awesome_rounded,
                        color: AppColors.violet, path: '/ask'),
                    _QuickAction(label: 'View Students', icon: Icons.people_rounded,
                        color: AppColors.terracotta, path: '/students'),
                  ],
                ),
              ],
            ),
          ),

          // Bihar quote
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Column(
                children: [
                  Text('"', style: GoogleFonts.fraunces(
                      fontSize: 32, color: AppColors.terracotta.withValues(alpha: 0.5))),
                  Text(
                    'हर बच्चे में सीखने की अनंत संभावना है।',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  Text('– मेधा',
                      style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground)),
                  const SizedBox(height: 12),
                  Container(
                    height: 3,
                    width: 80,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [AppColors.saffron, AppColors.tricolorWhite, AppColors.tricolorGreen]),
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      (label: 'Students', value: stats['total_students']?.toString() ?? '—', icon: Icons.people_rounded, color: AppColors.terracotta),
      (label: 'Present Today', value: stats['present_today']?.toString() ?? '—', icon: Icons.check_circle_rounded, color: AppColors.sage),
      (label: 'Pending HW', value: stats['pending_homework']?.toString() ?? '—', icon: Icons.assignment_rounded, color: AppColors.gold),
      (label: 'Notifications', value: stats['unread_notifications']?.toString() ?? '—', icon: Icons.notifications_rounded, color: AppColors.violet),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: cards.map((c) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(c.icon, size: 20, color: c.color),
            Text(c.value,
                style: GoogleFonts.manrope(
                    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
            Text(c.label,
                style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground)),
          ],
        ),
      )).toList(),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String path;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(path),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink),
                  maxLines: 2),
            ),
          ],
        ),
      ),
    );
  }
}
