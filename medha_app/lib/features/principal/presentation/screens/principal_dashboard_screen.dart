import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';

class PrincipalDashboardScreen extends ConsumerStatefulWidget {
  const PrincipalDashboardScreen({super.key});

  @override
  ConsumerState<PrincipalDashboardScreen> createState() => _PrincipalDashboardScreenState();
}

class _PrincipalDashboardScreenState extends ConsumerState<PrincipalDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    dynamic statsRes, teachersRes, pendingRes;
    // Endpoints per shiksha_sathi/lib/api.ts: getPrincipalStats/Teachers/PendingTeachers.
    try { statsRes = await ref.read(apiClientProvider).get('/principal/stats'); } catch (_) {}
    try { teachersRes = await ref.read(apiClientProvider).get('/principal/teachers'); } catch (_) {}
    try { pendingRes = await ref.read(apiClientProvider).get('/principal/teachers/pending'); } catch (_) {}
    if (mounted) {
      setState(() {
        _stats = statsRes?.data as Map<String, dynamic>?;
        _teachers = ((teachersRes?.data as List?) ?? []).cast<Map<String, dynamic>>();
        _pending = ((pendingRes?.data as List?) ?? []).cast<Map<String, dynamic>>();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.card,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.terracotta,
            unselectedLabelColor: AppColors.mutedForeground,
            indicatorColor: AppColors.terracotta,
            labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              const Tab(text: 'Overview'),
              Tab(text: 'Teachers (${_teachers.length})'),
              Tab(text: 'Pending (${_pending.length})'),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingBody()
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _OverviewTab(stats: _stats),
                    _TeachersTab(teachers: _teachers, onRefresh: _load),
                    _PendingTab(pending: _pending, onRefresh: _load, api: ref.read(apiClientProvider)),
                  ],
                ),
        ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic>? stats;
  const _OverviewTab({this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const EmptyState(message: 'Stats not available', icon: Icons.bar_chart_outlined);
    }
    // Fields match PrincipalStats in shiksha_sathi/lib/api.ts exactly — the
    // backend has no attendance-percentage field on this endpoint.
    final cards = [
      (label: 'Teachers', value: stats!['teachers']?.toString() ?? '—', icon: Icons.school_rounded, color: AppColors.sage),
      (label: 'Pending Teachers', value: stats!['pending_teachers']?.toString() ?? '—', icon: Icons.pending_actions_rounded, color: AppColors.violet),
      (label: 'Students', value: stats!['students']?.toString() ?? '—', icon: Icons.people_rounded, color: AppColors.terracotta),
      (label: 'Pending Students', value: stats!['pending_students']?.toString() ?? '—', icon: Icons.hourglass_top_rounded, color: AppColors.gold),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: cards.map((c) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.color.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(c.icon, color: c.color, size: 22),
                  Text(c.value,
                      style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  Text(c.label, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _TeachersTab extends StatelessWidget {
  final List<Map<String, dynamic>> teachers;
  final VoidCallback onRefresh;
  const _TeachersTab({required this.teachers, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (teachers.isEmpty) return const EmptyState(message: 'No teachers registered', icon: Icons.school_outlined);
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.terracotta,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: teachers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final t = teachers[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    (t['full_name'] as String? ?? '?').substring(0, 1).toUpperCase(),
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['full_name'] as String? ?? '',
                          style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink)),
                      Text(t['email'] as String? ?? '',
                          style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PendingTab extends StatelessWidget {
  final List<Map<String, dynamic>> pending;
  final VoidCallback onRefresh;
  final ApiClient api;
  const _PendingTab({required this.pending, required this.onRefresh, required this.api});

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty) return const EmptyState(message: 'No pending approvals', icon: Icons.check_circle_outline);
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.terracotta,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: pending.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final p = pending[i];
          final id = p['id'] as String?;
          final employeeCode = p['employee_code'] as String?;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['full_name'] as String? ?? '',
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
                Text(p['email'] as String? ?? '',
                    style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground)),
                if (employeeCode != null)
                  Text('Employee code: $employeeCode',
                      style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.destructive,
                            side: const BorderSide(color: AppColors.destructive)),
                        onPressed: () async {
                          if (id == null) return;
                          try {
                            await api.post('/principal/teachers/$id/reject',
                                data: {'reason': 'Not approved by principal'});
                          } catch (_) {}
                          onRefresh();
                        },
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.sage),
                        onPressed: () async {
                          if (id == null) return;
                          try { await api.post('/principal/teachers/$id/approve'); } catch (_) {}
                          onRefresh();
                        },
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
