import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';

class TeacherHomeworkScreen extends ConsumerStatefulWidget {
  const TeacherHomeworkScreen({super.key});

  @override
  ConsumerState<TeacherHomeworkScreen> createState() => _TeacherHomeworkScreenState();
}

class _TeacherHomeworkScreenState extends ConsumerState<TeacherHomeworkScreen> {
  List<Map<String, dynamic>> _hw = [];
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
      final res = await ref.read(apiClientProvider).get('/teacher/homework');
      final list = (res.data as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _hw = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showAssignSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AssignHomeworkSheet(
        onSaved: () {
          Navigator.pop(ctx);
          _load();
        },
        api: ref.read(apiClientProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Homework',
          subtitle: 'Assign and track homework',
          trailing: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.terracotta,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.ivory, size: 18),
            ),
            onPressed: _showAssignSheet,
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingBody()
              : _error != null
                  ? ErrorBody(message: _error!, onRetry: _load)
                  : _hw.isEmpty
                      ? const EmptyState(message: 'No homework assigned yet', icon: Icons.assignment_outlined)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.terracotta,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _hw.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final hw = _hw[i];
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
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(hw['title'] as String? ?? '',
                                              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                                        ),
                                        if (hw['due_date'] != null)
                                          Text(_fmt(hw['due_date'] as String),
                                              style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground)),
                                      ],
                                    ),
                                    if (hw['description'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(hw['description'] as String,
                                          maxLines: 2, overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.manrope(fontSize: 13, color: AppColors.mutedForeground)),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (hw['subject_name'] != null)
                                          _Badge(hw['subject_name'] as String),
                                        const SizedBox(width: 6),
                                        _Badge('${hw['done_count'] ?? 0}/${hw['total_students'] ?? 0} done'),
                                      ],
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

  String _fmt(String iso) {
    try { return DateFormat('d MMM').format(DateTime.parse(iso)); } catch (_) { return iso; }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.parchment, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.manrope(fontSize: 11, color: AppColors.mutedForeground)),
    );
  }
}

class _AssignHomeworkSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final ApiClient api;
  const _AssignHomeworkSheet({required this.onSaved, required this.api});

  @override
  State<_AssignHomeworkSheet> createState() => _AssignHomeworkSheetState();
}

class _AssignHomeworkSheetState extends State<_AssignHomeworkSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.api.post('/teacher/homework', data: {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'due_date': _dueDate != null ? DateFormat('yyyy-MM-dd').format(_dueDate!) : null,
      });
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.destructive));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Assign Homework', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(hintText: 'Homework title'),
            autofocus: true,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Description (optional)'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_rounded, size: 16),
            label: Text(_dueDate == null ? 'Set due date' : DateFormat('d MMMM y').format(_dueDate!)),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (d != null) setState(() => _dueDate = d);
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ivory))
                : const Text('Assign'),
          ),
        ],
      ),
    );
  }
}
