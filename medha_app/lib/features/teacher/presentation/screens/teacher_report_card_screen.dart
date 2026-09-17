import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';

class TeacherReportCardScreen extends ConsumerStatefulWidget {
  const TeacherReportCardScreen({super.key});

  @override
  ConsumerState<TeacherReportCardScreen> createState() => _TeacherReportCardScreenState();
}

class _TeacherReportCardScreenState extends ConsumerState<TeacherReportCardScreen> {
  List<Map<String, dynamic>> _students = [];
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
      final res = await ref.read(apiClientProvider).get('/teacher/students');
      final list = (res.data as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _students = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ScreenHeader(title: 'Report Card', subtitle: 'View student academic performance'),
        Expanded(
          child: _loading
              ? const LoadingBody()
              : _error != null
                  ? ErrorBody(message: _error!, onRetry: _load)
                  : _students.isEmpty
                      ? const EmptyState(message: 'No students in your class', icon: Icons.people_outline)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _students.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final s = _students[i];
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
                                      (s['full_name'] as String? ?? '?').substring(0, 1).toUpperCase(),
                                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppColors.ink),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s['full_name'] as String? ?? '',
                                            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
                                        if (s['roll_number'] != null)
                                          Text('Roll: ${s['roll_number']}',
                                              style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.mutedForeground),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
