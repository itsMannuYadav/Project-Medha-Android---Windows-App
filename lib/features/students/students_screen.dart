import 'package:flutter/material.dart';

import '../../core/api/teacher_students_api.dart';
import '../../core/models/teacher_students.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';

/// Teacher Students page — approve pending registrations + view roster.
/// Mirrors web `/students`.
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  TeacherStudentStats? _stats;
  List<PendingStudent> _pending = [];
  List<TeacherStudentItem> _roster = [];
  bool _loading = true;
  String? _busyId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        TeacherStudentsApi.stats(),
        TeacherStudentsApi.pending(),
        TeacherStudentsApi.roster(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as TeacherStudentStats;
        _pending = results[1] as List<PendingStudent>;
        _roster = results[2] as List<TeacherStudentItem>;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'लोड नहीं हो सका।';
        _loading = false;
      });
    }
  }

  Future<void> _approve(String id) async {
    setState(() => _busyId = id);
    try {
      await TeacherStudentsApi.approve(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('छात्र स्वीकृत हुए।')));
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कुछ गड़बड़ हो गई।')));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _reject(String id) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ReasonDialog(),
    );
    if (reason == null || reason.trim().isEmpty) return;
    setState(() => _busyId = id);
    try {
      await TeacherStudentsApi.reject(id, reason.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('आवेदन अस्वीकृत हुआ।')));
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कुछ गड़बड़ हो गई।')));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(
        toolbarHeight: 66,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('छात्र'),
            SizedBox(height: 2),
            Text('आवेदन स्वीकृत करें, फिर वे संदेह पूछ सकते हैं', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: MedhaColors.inkSoft)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: MedhaColors.danger))
                  else if (_stats != null)
                    Row(
                      children: [
                        Expanded(child: _stat('${_stats!.students}', 'स्वीकृत')),
                        const SizedBox(width: 10),
                        Expanded(child: _stat('${_stats!.pendingStudents}', 'लंबित')),
                      ],
                    ),
                  const SizedBox(height: 22),
                  const Text('आवेदन', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  if (_pending.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('कोई लंबित आवेदन नहीं', style: TextStyle(color: MedhaColors.muted)),
                    )
                  else
                    ..._pending.map(_pendingCard),
                  const SizedBox(height: 22),
                  const Text('आपके छात्र', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  if (_roster.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('अभी कोई स्वीकृत छात्र नहीं', style: TextStyle(color: MedhaColors.muted)),
                    )
                  else
                    ..._roster.map(_rosterCard),
                ],
              ),
            ),
    );
  }

  Widget _stat(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MedhaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MedhaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: MedhaColors.muted)),
        ],
      ),
    );
  }

  Widget _pendingCard(PendingStudent s) {
    final busy = _busyId == s.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MedhaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: MedhaColors.primaryWash),
                  alignment: Alignment.center,
                  child: Text(
                    s.fullName.isEmpty ? '?' : s.fullName.substring(0, 1),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MedhaColors.primary),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(
                        [
                          s.gradeLabel,
                          if (s.rollNumber != null) 'रोल ${s.rollNumber}',
                        ].join(' · '),
                        style: const TextStyle(fontSize: 11.5, color: MedhaColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : () => _approve(s.id),
                    icon: const MedhaIcon('shield_check', size: 14, color: Colors.white),
                    label: const Text('स्वीकृत करें'),
                    style: ElevatedButton.styleFrom(backgroundColor: MedhaColors.success),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _reject(s.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MedhaColors.danger,
                      side: const BorderSide(color: MedhaColors.danger, width: 1.5),
                    ),
                    child: const Text('अस्वीकृत करें'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rosterCard(TeacherStudentItem s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MedhaCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.fullName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  Text(
                    [
                      s.gradeLabel,
                      if (s.rollNumber != null) 'रोल ${s.rollNumber}',
                      if (s.activated) 'सक्रिय' else 'सक्रिय नहीं',
                    ].join(' · '),
                    style: const TextStyle(fontSize: 11, color: MedhaColors.muted),
                  ),
                ],
              ),
            ),
            if (s.activated)
              const MedhaIcon('shield_check', size: 16, color: MedhaColors.success),
          ],
        ),
      ),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MedhaColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MedhaRadii.lg)),
      title: const Text('अस्वीकृति का कारण'),
      content: TextField(
        controller: _reason,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'संक्षेप में कारण लिखें'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('रद्द करें')),
        TextButton(onPressed: () => Navigator.of(context).pop(_reason.text), child: const Text('अस्वीकृत करें')),
      ],
    );
  }
}
