import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/attendance_api.dart';
import '../../core/api/profile_api.dart';
import '../../core/models/attendance.dart';
import '../../core/models/profile.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_icon.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _loading = true;
  String? _error;
  List<ProfileSubject> _subjectPairs = []; // for the grade choices (deduped by grade)
  String? _selectedGradeId;
  String? _selectedGradeLabel;

  AttendanceDay? _day;
  final DateTime _date = DateTime.now();
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final profile = await ProfileApi.get();
      if (!mounted) return;
      final seenGrades = <String>{};
      final pairs = [
        for (final s in profile.subjects)
          if (seenGrades.add(s.gradeId)) s,
      ];
      if (pairs.isEmpty) {
        setState(() {
          _error = 'प्रोफ़ाइल में कोई कक्षा नहीं जुड़ी है।';
          _loading = false;
        });
        return;
      }
      setState(() {
        _subjectPairs = pairs;
        _selectedGradeId = pairs.first.gradeId;
        _selectedGradeLabel = pairs.first.gradeLabel;
      });
      await _loadDay();
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadDay() async {
    if (_selectedGradeId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final day = await AttendanceApi.get(gradeId: _selectedGradeId!, date: _date);
      if (!mounted) return;
      setState(() {
        _day = day;
        _loading = false;
        _dirty = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _pickGrade() async {
    if (_subjectPairs.length < 2) return;
    final choice = await showModalBottomSheet<ProfileSubject>(
      context: context,
      backgroundColor: MedhaColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in _subjectPairs)
              ListTile(title: Text(p.gradeLabel), onTap: () => Navigator.of(context).pop(p)),
          ],
        ),
      ),
    );
    if (choice == null || choice.gradeId == _selectedGradeId) return;
    setState(() {
      _selectedGradeId = choice.gradeId;
      _selectedGradeLabel = choice.gradeLabel;
    });
    await _loadDay();
  }

  void _setStatus(String studentId, String status) {
    final day = _day;
    if (day == null) return;
    setState(() {
      _day = AttendanceDay(
        gradeId: day.gradeId,
        gradeLabel: day.gradeLabel,
        date: day.date,
        students: [
          for (final s in day.students) s.studentId == studentId ? s.copyWith(status: status) : s,
        ],
      );
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final day = _day;
    if (day == null) return;
    final marked = {for (final s in day.students) if (s.status != null) s.studentId: s.status!};
    if (marked.isEmpty) return;
    setState(() => _saving = true);
    try {
      final updated = await AttendanceApi.mark(gradeId: day.gradeId, date: _date, statusByStudentId: marked);
      if (!mounted) return;
      setState(() {
        _day = updated;
        _dirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('उपस्थिति सहेजी गई'), duration: Duration(seconds: 2)));
    } on ApiError catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    final present = day?.students.where((s) => s.status == 'present').length ?? 0;
    final absent = day?.students.where((s) => s.status == 'absent').length ?? 0;
    final total = day?.students.length ?? 0;

    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('उपस्थिति'),
            const SizedBox(height: 3),
            InkWell(
              onTap: _subjectPairs.length > 1 ? _pickGrade : null,
              child: Row(
                children: [
                  Text(_selectedGradeLabel ?? '—', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: MedhaColors.inkSoft)),
                  if (_subjectPairs.length > 1) const Padding(padding: EdgeInsets.only(left: 4), child: MedhaIcon('chevron_down', size: 11, color: MedhaColors.muted)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(border: Border.all(color: MedhaColors.borderStrong, width: 1.5), borderRadius: BorderRadius.circular(MedhaRadii.pill)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MedhaIcon('calendar', size: 14, color: MedhaColors.inkSoft),
                  const SizedBox(width: 6),
                  Text('${_date.day}/${_date.month}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: MedhaColors.danger))))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(bottom: BorderSide(color: MedhaColors.border))),
                      child: Row(
                        children: [
                          Expanded(child: _StatTile(value: '$present', label: 'उपस्थित', bg: MedhaColors.successWash, fg: MedhaColors.successInk)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatTile(value: '$absent', label: 'अनुपस्थित', bg: MedhaColors.dangerWash, fg: MedhaColors.danger)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatTile(value: '$total', label: 'कुल', bg: MedhaColors.surface2, fg: MedhaColors.inkSoft)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: (day?.students.isEmpty ?? true)
                          ? const Center(child: Text('इस कक्षा में स्वीकृत छात्र नहीं हैं।', style: TextStyle(color: MedhaColors.muted)))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: day!.students.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 9),
                              itemBuilder: (context, i) {
                                final s = day.students[i];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(color: MedhaColors.surface, border: Border.all(color: MedhaColors.border), borderRadius: BorderRadius.circular(MedhaRadii.md)),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(shape: BoxShape.circle, color: MedhaColors.primaryWash),
                                        child: Text(s.fullName.substring(0, 1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MedhaColors.primary)),
                                      ),
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s.fullName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: MedhaColors.ink)),
                                            if (s.rollNumber != null) Text('रोल नं. ${s.rollNumber}', style: const TextStyle(fontSize: 11, color: MedhaColors.muted)),
                                          ],
                                        ),
                                      ),
                                      _PASegment(status: s.status, onChanged: (v) => _setStatus(s.studentId, v)),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(top: BorderSide(color: MedhaColors.border))),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (!_dirty || _saving) ? null : _save,
                          child: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(_dirty ? 'सहेजें' : 'सहेजा गया ✓'),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, required this.bg, required this.fg});
  final String value;
  final String label;
  final Color bg;
  final Color fg;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(MedhaRadii.md)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fg)),
          Text(label, style: TextStyle(fontSize: 10.5, color: fg)),
        ],
      ),
    );
  }
}

class _PASegment extends StatelessWidget {
  const _PASegment({required this.status, required this.onChanged});
  final String? status;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: MedhaColors.borderStrong, width: 1.5), borderRadius: BorderRadius.circular(MedhaRadii.pill)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg('P', status == 'present', MedhaColors.success, () => onChanged('present')),
          _seg('A', status == 'absent', MedhaColors.danger, () => onChanged('absent')),
        ],
      ),
    );
  }

  Widget _seg(String label, bool active, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 30,
        alignment: Alignment.center,
        color: active ? color : MedhaColors.surface,
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : MedhaColors.muted)),
      ),
    );
  }
}
