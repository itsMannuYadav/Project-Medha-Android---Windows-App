import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../data/student_models.dart';
import '../../data/student_repository.dart';

class ReportCardScreen extends ConsumerStatefulWidget {
  const ReportCardScreen({super.key});

  @override
  ConsumerState<ReportCardScreen> createState() => _ReportCardScreenState();
}

class _ReportCardScreenState extends ConsumerState<ReportCardScreen> {
  List<ReportCardEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final e = await ref.read(studentRepositoryProvider).getMyReportCard();
      if (mounted) setState(() { _entries = e; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  double? get _percentage {
    final with_marks = _entries.where((e) =>
        e.marksObtained != null && e.totalMarks != null && e.totalMarks! > 0);
    if (with_marks.isEmpty) return null;
    final obtained = with_marks.fold<int>(0, (s, e) => s + e.marksObtained!);
    final total = with_marks.fold<int>(0, (s, e) => s + e.totalMarks!);
    return total > 0 ? (obtained / total) * 100 : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ScreenHeader(
          title: 'My Report Card',
          subtitle: 'Academic performance overview',
        ),
        Expanded(
          child: _loading
              ? const LoadingBody()
              : _error != null
                  ? ErrorBody(message: _error!, onRetry: _load)
                  : _entries.isEmpty
                      ? const EmptyState(
                          message: 'Report card not available yet',
                          icon: Icons.bar_chart_outlined)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.terracotta,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (_percentage != null)
                                _OverallCard(percentage: _percentage!),
                              const SizedBox(height: 16),
                              ..._entries.map(
                                  (e) => _EntryCard(entry: e)),
                            ],
                          ),
                        ),
        ),
      ],
    );
  }
}

class _OverallCard extends StatelessWidget {
  final double percentage;
  const _OverallCard({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 75
        ? AppColors.sage
        : percentage >= 50
            ? AppColors.gold
            : AppColors.destructive;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          Text('Overall Performance',
              style: GoogleFonts.manrope(
                  fontSize: 13, color: AppColors.mutedForeground)),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: AppColors.parchment,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final ReportCardEntry entry;
  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final pct = entry.totalMarks != null && entry.totalMarks! > 0
        ? ((entry.marksObtained ?? 0) / entry.totalMarks!) * 100
        : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.subjectName,
                    style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink)),
                if (entry.remarks != null)
                  Text(entry.remarks!,
                      style: GoogleFonts.manrope(
                          fontSize: 12, color: AppColors.mutedForeground)),
                if (pct != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 4,
                      backgroundColor: AppColors.parchment,
                      valueColor: AlwaysStoppedAnimation(
                        pct >= 75
                            ? AppColors.sage
                            : pct >= 50
                                ? AppColors.gold
                                : AppColors.destructive,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (entry.marksObtained != null && entry.totalMarks != null)
                Text(
                  '${entry.marksObtained}/${entry.totalMarks}',
                  style: GoogleFonts.manrope(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              if (entry.grade != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.parchment,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    entry.grade!,
                    style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.terracotta),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
