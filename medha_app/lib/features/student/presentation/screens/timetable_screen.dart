import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../data/student_models.dart';
import '../../data/student_repository.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  List<TimetableSlot> _slots = [];
  bool _loading = true;
  String? _error;
  String _selectedDay = _today();

  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  static String _today() {
    const map = {
      1: 'Monday', 2: 'Tuesday', 3: 'Wednesday',
      4: 'Thursday', 5: 'Friday', 6: 'Saturday',
    };
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
      final slots = await ref.read(studentRepositoryProvider).getMyTimetable();
      if (mounted) setState(() { _slots = slots; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<TimetableSlot> get _todaySlots => _slots
      .where((s) => s.dayOfWeek.toLowerCase() == _selectedDay.toLowerCase())
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ScreenHeader(
          title: 'My Timetable',
          subtitle: 'Your daily class schedule',
        ),
        // Day picker
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
                    child: Text(
                      day.substring(0, 3),
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.ivory : AppColors.ink,
                      ),
                    ),
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
                      ? EmptyState(
                          message: 'No classes on $_selectedDay',
                          icon: Icons.calendar_today_outlined)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.terracotta,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _todaySlots.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (ctx, i) =>
                                _SlotCard(slot: _todaySlots[i]),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  final TimetableSlot slot;
  const _SlotCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.terracotta,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.subjectName,
                  style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${slot.startTime} – ${slot.endTime}',
                  style: GoogleFonts.manrope(
                      fontSize: 12, color: AppColors.mutedForeground),
                ),
                if (slot.teacherName != null)
                  Text(
                    slot.teacherName!,
                    style: GoogleFonts.manrope(
                        fontSize: 12, color: AppColors.mutedForeground),
                  ),
              ],
            ),
          ),
          if (slot.room != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.parchment,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                slot.room!,
                style: GoogleFonts.manrope(
                    fontSize: 12, color: AppColors.mutedForeground),
              ),
            ),
        ],
      ),
    );
  }
}
