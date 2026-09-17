import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';

class TeacherTimetableScreen extends ConsumerStatefulWidget {
  const TeacherTimetableScreen({super.key});

  @override
  ConsumerState<TeacherTimetableScreen> createState() => _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends ConsumerState<TeacherTimetableScreen> {
  List<Map<String, dynamic>> _slots = [];
  bool _loading = true;
  String? _error;
  String _selectedDay = _today();

  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  static String _today() {
    const map = {1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday', 5: 'Friday', 6: 'Saturday'};
    return map[DateTime.now().weekday] ?? 'Monday';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ref.read(apiClientProvider).get('/teacher/timetable');
      final list = (res.data as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _slots = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _todaySlots => _slots
      .where((s) => (s['day_of_week'] as String? ?? '').toLowerCase() == _selectedDay.toLowerCase())
      .toList()
    ..sort((a, b) => (a['start_time'] as String? ?? '').compareTo(b['start_time'] as String? ?? ''));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ScreenHeader(title: 'My Timetable', subtitle: 'Your teaching schedule'),
        Container(
          height: 44,
          color: AppColors.card,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _days.length,
            itemBuilder: (ctx, i) {
              final day = _days[i];
              final selected = day == _selectedDay;
              return GestureDetector(
                onTap: () => setState(() => _selectedDay = day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.terracotta : AppColors.parchment,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(day.substring(0, 3),
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600,
                            color: selected ? AppColors.ivory : AppColors.ink)),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingBody()
              : _error != null
                  ? ErrorBody(message: _error!, onRetry: _load)
                  : _todaySlots.isEmpty
                      ? EmptyState(message: 'No classes on $_selectedDay', icon: Icons.calendar_today_outlined)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.terracotta,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _todaySlots.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final s = _todaySlots[i];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.hairline),
                                ),
                                child: Row(
                                  children: [
                                    Container(width: 4, height: 52,
                                        decoration: BoxDecoration(color: AppColors.terracotta, borderRadius: BorderRadius.circular(4))),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s['subject_name'] as String? ?? '',
                                              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                                          Text('${s['start_time']} – ${s['end_time']}',
                                              style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground)),
                                          if (s['grade_label'] != null)
                                            Text('Class ${s['grade_label']}',
                                                style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground)),
                                        ],
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
