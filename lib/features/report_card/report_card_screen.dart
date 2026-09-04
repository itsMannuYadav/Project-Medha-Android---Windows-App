import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/profile_api.dart';
import '../../core/api/report_card_api.dart';
import '../../core/api/roster_api.dart';
import '../../core/models/attendance.dart';
import '../../core/models/profile.dart';
import '../../core/models/report_card.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/pill_chip.dart';
import 'enter_marks_screen.dart';

class ReportCardScreen extends StatefulWidget {
  const ReportCardScreen({super.key});

  @override
  State<ReportCardScreen> createState() => _ReportCardScreenState();
}

class _ReportCardScreenState extends State<ReportCardScreen> {
  bool get _isStudent => AppScope.of(context, listen: false).teacher?.role == 'student';
  bool get _isTeacher => AppScope.of(context, listen: false).teacher?.role == 'teacher';

  List<ProfileSubject> _gradeOptions = [];
  String? _gradeId;
  List<AttendanceStudent> _roster = [];
  AttendanceStudent? _selectedStudent;

  ReportCard? _card;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final self = AppScope.of(context, listen: false).teacher!;
    if (_isStudent) {
      await _loadCard(self.id);
      return;
    }
    try {
      final profile = await ProfileApi.get();
      final seen = <String>{};
      final grades = [for (final s in profile.subjects) if (seen.add(s.gradeId)) s];
      if (!mounted) return;
      setState(() => _gradeOptions = grades);
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
      _gradeId = gradeId;
      _selectedStudent = null;
      _card = null;
    });
    try {
      final roster = await RosterApi.forGrade(gradeId);
      if (!mounted) return;
      setState(() {
        _roster = roster;
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

  Future<void> _loadCard(String studentId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final card = await ReportCardApi.get(studentId);
      if (!mounted) return;
      setState(() {
        _card = card;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('रिपोर्ट कार्ड')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: MedhaColors.danger))))
              : _isStudent
                  ? _buildCard(_card)
                  : _buildTeacherFlow(),
    );
  }

  Widget _buildTeacherFlow() {
    return Column(
      children: [
        if (_gradeOptions.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(bottom: BorderSide(color: MedhaColors.border))),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _gradeOptions
                    .map((g) => Padding(padding: const EdgeInsets.only(right: 8), child: PillChip(label: g.gradeLabel, selected: g.gradeId == _gradeId, onTap: () => _selectGrade(g.gradeId))))
                    .toList(),
              ),
            ),
          ),
        Expanded(
          child: _selectedStudent == null
              ? (_roster.isEmpty
                  ? const Center(child: Text('इस कक्षा में स्वीकृत छात्र नहीं हैं।', style: TextStyle(color: MedhaColors.muted)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _roster.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final s = _roster[i];
                        return MedhaCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          onTap: () {
                            setState(() => _selectedStudent = s);
                            _loadCard(s.studentId);
                          },
                          child: Row(
                            children: [
                              Expanded(child: Text(s.fullName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
                              const MedhaIcon('chevron_right', size: 15, color: MedhaColors.muted),
                            ],
                          ),
                        );
                      },
                    ))
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(bottom: BorderSide(color: MedhaColors.border))),
                      child: Row(
                        children: [
                          IconButton(icon: const MedhaIcon('chevron_left', size: 18, color: MedhaColors.ink), onPressed: () => setState(() => _selectedStudent = null)),
                          Expanded(child: Text(_selectedStudent!.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                          if (_isTeacher)
                            TextButton.icon(
                              onPressed: () async {
                                final saved = await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(builder: (_) => EnterMarksScreen(studentId: _selectedStudent!.studentId, studentName: _selectedStudent!.fullName)),
                                );
                                if (saved == true) _loadCard(_selectedStudent!.studentId);
                              },
                              icon: const MedhaIcon('plus', size: 14, color: MedhaColors.primary),
                              label: const Text('अंक जोड़ें', style: TextStyle(color: MedhaColors.primary)),
                            ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildCard(_card)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCard(ReportCard? card) {
    if (card == null || card.marks.isEmpty) {
      return const Center(child: Text('अभी कोई अंक दर्ज नहीं हैं।', style: TextStyle(color: MedhaColors.muted)));
    }
    final byTerm = <String, List<ReportCardMark>>{};
    for (final m in card.marks) {
      byTerm.putIfAbsent(m.term, () => []).add(m);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final term in byTerm.keys) ...[
          Text(term, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MedhaColors.primary)),
          const SizedBox(height: 8),
          MedhaCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < byTerm[term]!.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        Expanded(child: Text(byTerm[term]![i].subjectName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
                        Text(
                          '${byTerm[term]![i].marksObtained.toStringAsFixed(0)} / ${byTerm[term]![i].maxMarks.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: MedhaColors.ink),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}
