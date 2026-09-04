import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/profile_api.dart';
import '../../core/api/reference_api.dart';
import '../../core/api/timetable_api.dart';
import '../../core/models/profile.dart';
import '../../core/models/reference.dart';
import '../../core/models/timetable.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/pill_chip.dart';

const _days = ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि'];
const _periods = [1, 2, 3, 4, 5, 6, 7, 8];

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<ProfileSubject> _gradeOptions = [];
  String? _gradeId;
  List<SubjectRef> _subjects = [];

  // "day-period" -> subjectId, local edit buffer.
  Map<String, String?> _grid = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _editing = false;

  bool get _canEdit {
    final role = AppScope.of(context, listen: false).teacher?.role;
    return role == 'teacher' || role == 'principal';
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final results = await Future.wait([ProfileApi.get(), ReferenceApi.subjects()]);
      final profile = results[0] as Profile;
      final subjects = results[1] as List<SubjectRef>;
      final seen = <String>{};
      final grades = [for (final s in profile.subjects) if (seen.add(s.gradeId)) s];
      if (!mounted) return;
      setState(() {
        _subjects = subjects;
        _gradeOptions = grades;
      });
      if (grades.isNotEmpty) {
        await _selectGrade(grades.first.gradeId);
      } else {
        setState(() => _loading = false);
      }
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _selectGrade(String gradeId) async {
    setState(() {
      _loading = true;
      _error = null;
      _gradeId = gradeId;
      _editing = false;
    });
    try {
      final tt = await TimetableApi.get(gradeId);
      if (!mounted) return;
      setState(() {
        _grid = {for (final s in tt.slots) '${s.dayOfWeek}-${s.periodNumber}': s.subjectId};
        _loading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_gradeId == null) return;
    setState(() => _saving = true);
    final slots = <TimetableSlot>[];
    _grid.forEach((key, subjectId) {
      if (subjectId == null) return;
      final parts = key.split('-');
      slots.add(TimetableSlot(
        dayOfWeek: int.parse(parts[0]),
        periodNumber: int.parse(parts[1]),
        subjectId: subjectId,
        subjectName: null,
        teacherId: null,
        teacherName: null,
      ));
    });
    try {
      await TimetableApi.save(_gradeId!, slots);
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('समय सारणी सहेजी गई'), duration: Duration(seconds: 2)));
      }
    } on ApiError catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editCell(int day, int period) async {
    if (!_editing) return;
    final key = '$day-$period';
    final choice = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: MedhaColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('खाली करें', style: TextStyle(color: MedhaColors.muted)), onTap: () => Navigator.of(context).pop('')),
            for (final s in _subjects) ListTile(title: Text(s.name), onTap: () => Navigator.of(context).pop(s.id)),
          ],
        ),
      ),
    );
    if (choice == null) return;
    setState(() => _grid[key] = choice.isEmpty ? null : choice);
  }

  String _subjectName(String? id) {
    if (id == null) return '';
    return _subjects.firstWhere((s) => s.id == id, orElse: () => SubjectRef(id: id, name: '?', board: '')).name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(
        title: const Text('समय सारणी'),
        actions: [
          if (_canEdit && !_loading && _gradeId != null)
            TextButton(
              onPressed: _saving ? null : () => _editing ? _save() : setState(() => _editing = true),
              child: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_editing ? 'सहेजें' : 'बदलें', style: const TextStyle(color: MedhaColors.primary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_gradeOptions.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(bottom: BorderSide(color: MedhaColors.border))),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _gradeOptions
                      .map((g) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: PillChip(label: g.gradeLabel, selected: g.gradeId == _gradeId, onTap: () => _selectGrade(g.gradeId)),
                          ))
                      .toList(),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: MedhaColors.danger))))
                    : _gradeId == null
                        ? const Center(child: Text('कोई कक्षा नहीं मिली', style: TextStyle(color: MedhaColors.muted)))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: Table(
                              border: TableBorder.all(color: MedhaColors.border, borderRadius: BorderRadius.circular(MedhaRadii.sm)),
                              columnWidths: const {0: FixedColumnWidth(36)},
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(color: MedhaColors.surface2),
                                  children: [
                                    const SizedBox(height: 34),
                                    for (final d in _days)
                                      Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(d, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)))),
                                  ],
                                ),
                                for (final p in _periods)
                                  TableRow(
                                    children: [
                                      Center(child: Text('$p', style: const TextStyle(fontSize: 11, color: MedhaColors.muted))),
                                      for (var d = 0; d < _days.length; d++)
                                        InkWell(
                                          onTap: () => _editCell(d, p),
                                          child: Container(
                                            height: 46,
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(horizontal: 2),
                                            child: Text(
                                              _subjectName(_grid['$d-$p']),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontSize: 10.5, color: MedhaColors.ink),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
