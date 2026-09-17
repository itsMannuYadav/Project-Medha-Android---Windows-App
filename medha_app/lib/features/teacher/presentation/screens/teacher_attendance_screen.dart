import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';

class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends ConsumerState<TeacherAttendanceScreen> {
  List<Map<String, dynamic>> _students = [];
  Map<String, bool> _attendance = {};
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  final _today = DateFormat('yyyy-MM-dd').format(DateTime.now());

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
      final att = <String, bool>{};
      for (final s in list) {
        att[s['id'] as String] = true; // default present
      }
      if (mounted) setState(() { _students = list; _attendance = att; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final records = _attendance.entries.map((e) => {
        'student_id': e.key,
        'date': _today,
        'status': e.value ? 'present' : 'absent',
      }).toList();
      await ref.read(apiClientProvider).post('/teacher/attendance', data: {'records': records});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance saved!'), backgroundColor: AppColors.sage));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.destructive));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _attendance.values.where((v) => v).length;
    return Column(
      children: [
        ScreenHeader(
          title: 'Attendance',
          subtitle: DateFormat('EEEE, d MMMM y').format(DateTime.now()),
          trailing: _loading ? null : Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.sage.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$presentCount/${_students.length} Present',
              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.sage),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingBody()
              : _error != null
                  ? ErrorBody(message: _error!, onRetry: _load)
                  : _students.isEmpty
                      ? const EmptyState(message: 'No students enrolled', icon: Icons.people_outline)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _students.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (ctx, i) {
                            final s = _students[i];
                            final id = s['id'] as String;
                            final present = _attendance[id] ?? true;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.hairline),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
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
                                            style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink)),
                                        if (s['roll_number'] != null)
                                          Text('Roll: ${s['roll_number']}',
                                              style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _AttendanceChip(
                                        label: 'P',
                                        active: present,
                                        color: AppColors.sage,
                                        onTap: () => setState(() => _attendance[id] = true),
                                      ),
                                      const SizedBox(width: 6),
                                      _AttendanceChip(
                                        label: 'A',
                                        active: !present,
                                        color: AppColors.destructive,
                                        onTap: () => setState(() => _attendance[id] = false),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
        if (!_loading && _students.isNotEmpty)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ivory))
                    : const Text('Save Attendance'),
              ),
            ),
          ),
      ],
    );
  }
}

class _AttendanceChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _AttendanceChip({required this.label, required this.active,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: active ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? color : color.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: active ? Colors.white : color)),
        ),
      ),
    );
  }
}
