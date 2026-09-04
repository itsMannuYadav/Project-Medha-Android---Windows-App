import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/reference_api.dart';
import '../../core/models/reference.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_icon.dart';
import 'student_activate_screen.dart';

/// Phase 1 of student sign-up: name + school + class + roll number, no
/// password (the backend's `/student/register` creates a pending,
/// credential-less row -- a teacher approves it before phase 2 can run).
class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({super.key});

  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  final _fullName = TextEditingController();
  final _rollNumber = TextEditingController();
  final _schoolSearch = TextEditingController();

  Timer? _debounce;
  List<SchoolSearchResult> _schoolResults = [];
  SchoolSearchResult? _selectedSchool;
  bool _searching = false;

  List<GradeRef> _grades = [];
  GradeRef? _selectedGrade;
  bool _loadingGrades = true;

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    try {
      final grades = await ReferenceApi.grades();
      if (!mounted) return;
      setState(() {
        _grades = grades;
        _loadingGrades = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingGrades = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fullName.dispose();
    _rollNumber.dispose();
    _schoolSearch.dispose();
    super.dispose();
  }

  void _onSchoolQueryChanged(String query) {
    setState(() => _selectedSchool = null);
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _schoolResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _searching = true);
      try {
        final results = await ReferenceApi.searchSchools(query);
        if (mounted) setState(() => _schoolResults = results);
      } catch (_) {
        // silent -- the field just shows no suggestions
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  Future<void> _submit() async {
    final fullName = _fullName.text.trim();
    final roll = _rollNumber.text.trim();
    if (fullName.isEmpty || roll.isEmpty || _selectedSchool == null || _selectedGrade == null) {
      setState(() => _error = 'सभी फ़ील्ड भरें और सूची से विद्यालय चुनें।');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthApi.registerStudent(
        fullName: fullName,
        schoolId: _selectedSchool!.id,
        gradeId: _selectedGrade!.id,
        rollNumber: roll,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StudentActivateScreen(
            school: _selectedSchool!,
            grade: _selectedGrade!,
            rollNumber: roll,
            fullName: fullName,
            justRegistered: true,
          ),
        ),
      );
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(
        leading: IconButton(icon: const MedhaIcon('chevron_left', color: MedhaColors.ink), onPressed: () => Navigator.of(context).pop()),
        title: const Text('छात्र पंजीकरण'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(color: MedhaColors.dangerWash, borderRadius: BorderRadius.circular(MedhaRadii.md)),
                child: Text(_error!, style: const TextStyle(fontSize: 12.5, color: MedhaColors.danger)),
              ),
              const SizedBox(height: 14),
            ],
            const _FieldLabel('पूरा नाम'),
            const SizedBox(height: 6),
            TextField(controller: _fullName, enabled: !_busy, decoration: const InputDecoration(hintText: 'जैसा स्कूल रिकॉर्ड में दर्ज है')),
            const SizedBox(height: 14),
            const _FieldLabel('विद्यालय'),
            const SizedBox(height: 6),
            TextField(
              controller: _schoolSearch,
              enabled: !_busy,
              onChanged: _onSchoolQueryChanged,
              decoration: InputDecoration(
                hintText: 'नाम या ज़िला टाइप करें',
                prefixIcon: const Padding(padding: EdgeInsets.all(13), child: MedhaIcon('search', size: 17, color: MedhaColors.muted)),
                suffixIcon: _searching
                    ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                    : null,
              ),
            ),
            if (_selectedSchool != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: MedhaColors.primaryWash, borderRadius: BorderRadius.circular(MedhaRadii.md)),
                child: Row(
                  children: [
                    const MedhaIcon('shield_check', size: 14, color: MedhaColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${_selectedSchool!.name} — ${_selectedSchool!.districtName}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.primary)),
                    ),
                  ],
                ),
              ),
            ] else if (_schoolResults.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: MedhaColors.surface,
                  border: Border.all(color: MedhaColors.borderStrong, width: 1.5),
                  borderRadius: BorderRadius.circular(MedhaRadii.md),
                  boxShadow: const [BoxShadow(color: MedhaColors.shadow, blurRadius: 14, offset: Offset(0, 4))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < _schoolResults.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _Option(
                        '${_schoolResults[i].name} — ${_schoolResults[i].districtName}',
                        onTap: () {
                          final chosen = _schoolResults[i];
                          setState(() {
                            _selectedSchool = chosen;
                            _schoolResults = [];
                            _schoolSearch.text = chosen.name;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('कक्षा'),
                      const SizedBox(height: 6),
                      _loadingGrades
                          ? const SizedBox(height: 48, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))))
                          : DropdownButtonFormField<GradeRef>(
                              initialValue: _selectedGrade,
                              hint: const Text('चुनें', style: TextStyle(fontSize: 13.5)),
                              items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g.label))).toList(),
                              onChanged: _busy ? null : (g) => setState(() => _selectedGrade = g),
                            ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('रोल नंबर'),
                      const SizedBox(height: 6),
                      TextField(controller: _rollNumber, enabled: !_busy, decoration: const InputDecoration(hintText: 'जैसे 12')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('पंजीकरण जमा करें'),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: MedhaColors.accentWash, borderRadius: BorderRadius.circular(MedhaRadii.md)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: EdgeInsets.only(top: 1), child: MedhaIcon('info_circle', size: 16, color: MedhaColors.accentInk)),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'यहाँ कोई पासवर्ड नहीं चाहिए। पंजीकरण के बाद आपके शिक्षक इसकी पुष्टि करेंगे — स्वीकृति मिलते ही आप अपना खाता सक्रिय कर पाएंगे।',
                      style: TextStyle(fontSize: 12, color: MedhaColors.accentInk, height: 1.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft));
}

class _Option extends StatelessWidget {
  const _Option(this.label, {required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: MedhaColors.surface,
        child: Text(label, style: const TextStyle(fontSize: 13.5, color: MedhaColors.inkSoft)),
      ),
    );
  }
}
