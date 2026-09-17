import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';

/// Endpoints per shiksha_sathi/lib/api.ts (getStudentRoster / getPendingStudents
/// / approveStudent / rejectStudent): the roster (`/teacher/students`) and the
/// approval queue (`/teacher/students/pending`) are two distinct lists with
/// different shapes — a roster item has no `approval_status` field at all
/// (`activated` instead), so pending students never show up on the roster.
class TeacherStudentsScreen extends ConsumerStatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  ConsumerState<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends ConsumerState<TeacherStudentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _roster = [];
  List<Map<String, dynamic>> _pending = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    dynamic rosterRes, pendingRes;
    try { rosterRes = await ref.read(apiClientProvider).get('/teacher/students'); } catch (_) {}
    try { pendingRes = await ref.read(apiClientProvider).get('/teacher/students/pending'); } catch (_) {}
    if (mounted) {
      setState(() {
        _roster = ((rosterRes?.data as List?) ?? []).cast<Map<String, dynamic>>();
        _pending = ((pendingRes?.data as List?) ?? []).cast<Map<String, dynamic>>();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredRoster => _query.isEmpty
      ? _roster
      : _roster.where((s) =>
          (s['full_name'] as String? ?? '').toLowerCase().contains(_query.toLowerCase()) ||
          (s['roll_number'] as String? ?? '').contains(_query)).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Students',
          subtitle: '${_roster.length} enrolled · ${_pending.length} pending',
        ),
        Container(
          color: AppColors.card,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.terracotta,
            unselectedLabelColor: AppColors.mutedForeground,
            indicatorColor: AppColors.terracotta,
            labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'Roster (${_roster.length})'),
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
                    _RosterTab(
                      students: _filteredRoster,
                      query: _query,
                      onQueryChanged: (v) => setState(() => _query = v),
                      onRefresh: _load,
                    ),
                    _PendingTab(
                      pending: _pending,
                      api: ref.read(apiClientProvider),
                      onRefresh: _load,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _RosterTab extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final Future<void> Function() onRefresh;
  const _RosterTab({required this.students, required this.query, required this.onQueryChanged, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            onChanged: onQueryChanged,
            decoration: const InputDecoration(
              hintText: 'Search by name or roll number…',
              prefixIcon: Icon(Icons.search_rounded, size: 18),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: students.isEmpty
              ? const EmptyState(message: 'No students found', icon: Icons.people_outline)
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  color: AppColors.terracotta,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: students.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final s = students[i];
                      final name = s['full_name'] as String? ?? '';
                      final activated = s['activated'] as bool? ?? false;
                      return Container(
                        padding: const EdgeInsets.all(12),
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
                                name.isEmpty ? '?' : name[0].toUpperCase(),
                                style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppColors.ink),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink)),
                                  Text(
                                    [
                                      if (s['grade_label'] != null) s['grade_label'] as String,
                                      if (s['roll_number'] != null) 'Roll ${s['roll_number']}',
                                    ].join(' · '),
                                    style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (activated ? AppColors.sage : AppColors.gold).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                activated ? 'ACTIVE' : 'NOT ACTIVATED',
                                style: GoogleFonts.manrope(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    color: activated ? AppColors.sage : AppColors.gold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _PendingTab extends StatelessWidget {
  final List<Map<String, dynamic>> pending;
  final ApiClient api;
  final Future<void> Function() onRefresh;
  const _PendingTab({required this.pending, required this.api, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty) return const EmptyState(message: 'No pending approvals', icon: Icons.check_circle_outline);
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.terracotta,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: pending.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final s = pending[i];
          final id = s['id'] as String?;
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
                Text(s['full_name'] as String? ?? '',
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
                Text(
                  [
                    if (s['grade_label'] != null) s['grade_label'] as String,
                    if (s['roll_number'] != null) 'Roll ${s['roll_number']}',
                  ].join(' · '),
                  style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground),
                ),
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
                            await api.post('/teacher/students/$id/reject',
                                data: {'reason': 'Not approved by teacher'});
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
                          try { await api.post('/teacher/students/$id/approve'); } catch (_) {}
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
