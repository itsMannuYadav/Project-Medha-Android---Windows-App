import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/widgets/screen_header.dart';

class TeacherProfileScreen extends ConsumerWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull?.user;
    final name = user?.fullName ?? '—';
    final email = user?.email ?? '—';
    final role = user?.role ?? '';

    return Column(
      children: [
        const ScreenHeader(title: 'Profile', subtitle: 'Your account details'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Center(
                    child: Text(
                      user?.initials() ?? '?',
                      style: GoogleFonts.manrope(
                          fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name,
                    style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text(role.isEmpty ? '' : role[0].toUpperCase() + role.substring(1),
                    style: GoogleFonts.manrope(fontSize: 14, color: AppColors.terracotta)),

                const SizedBox(height: 24),
                _ProfileCard(items: [
                  (Icons.email_outlined, 'Email', email),
                  (Icons.badge_outlined, 'Role', role.isEmpty ? '—' : role[0].toUpperCase() + role.substring(1)),
                  (Icons.verified_user_outlined, 'Status', user?.approvalStatus ?? '—'),
                ]),

                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Log out'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final List<(IconData, String, String)> items;
  const _ProfileCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final (icon, label, value) = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: AppColors.mutedForeground),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: GoogleFonts.manrope(fontSize: 11, color: AppColors.mutedForeground)),
                          Text(value, style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(height: 1, color: AppColors.hairline, indent: 46),
            ],
          );
        }).toList(),
      ),
    );
  }
}
