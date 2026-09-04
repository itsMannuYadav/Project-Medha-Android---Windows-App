import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/reference_api.dart';
import '../../core/models/reference.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_icon.dart';
import 'login_screen.dart';

/// Phase 2 of student sign-up, reached once a teacher has approved the
/// phase-1 registration: re-confirm the same school/class/roll/name (the
/// backend matches the approved row by all four), then set email + password
/// for the first time. School/grade are pre-filled when reached right after
/// registering, but stay editable so this screen also works standalone
/// ("पहले से पंजीकृत? खाता सक्रिय करें" from the login screen, e.g. after
/// reinstalling or on a different device).
class StudentActivateScreen extends StatefulWidget {
  const StudentActivateScreen({
    super.key,
    this.school,
    this.grade,
    this.rollNumber,
    this.fullName,
    this.justRegistered = false,
  });

  final SchoolSearchResult? school;
  final GradeRef? grade;
  final String? rollNumber;
  final String? fullName;
  final bool justRegistered;

  @override
  State<StudentActivateScreen> createState() => _StudentActivateScreenState();
}

class _StudentActivateScreenState extends State<StudentActivateScreen> {
  late final _fullName = TextEditingController(text: widget.fullName ?? '');
  late final _rollNumber = TextEditingController(text: widget.rollNumber ?? '');
  final _schoolSearch = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  Timer? _debounce;
  List<SchoolSearchResult> _schoolResults = [];
  SchoolSearchResult? _selectedSchool;

  List<GradeRef> _grades = [];
  GradeRef? _selectedGrade;
  bool _loadingGrades = true;

  @override
  void initState() {
    super.initState();
    _selectedSchool = widget.school;
    _selectedGrade = widget.grade;
    _schoolSearch.text = widget.school?.name ?? '';
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    try {
      final grades = await ReferenceApi.grades();
      if (!mounted) return;
      setState(() {
        _grades = grades;
        _selectedGrade ??= widget.grade;
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
    _email.dispose();
    _password.dispose();
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
      try {
        final results = await ReferenceApi.searchSchools(query);
        if (mounted) setState(() => _schoolResults = results);
      } catch (_) {
        // silent -- the field just shows no suggestions
      }
    });
  }

  Future<void> _submit() async {
    final school = _selectedSchool;
    final grade = _selectedGrade;
    final fullName = _fullName.text.trim();
    final roll = _rollNumber.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if (school == null || grade == null || fullName.isEmpty || roll.isEmpty || email.isEmpty || password.length < 8) {
      setState(() => _error = 'सभी फ़ील्ड भरें, सूची से विद्यालय चुनें — पासवर्ड कम से कम 8 अक्षर का हो।');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthApi.activateStudent(
        schoolId: school.id,
        gradeId: grade.id,
        rollNumber: roll,
        fullName: fullName,
        email: email,
        password: password,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('खाता सक्रिय हो गया — अब लॉग इन करें।')),
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
        title: const Text('खाता सक्रिय करें'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: MedhaColors.successWash, borderRadius: BorderRadius.circular(MedhaRadii.md)),
              child: Text(
                widget.justRegistered
                    ? 'पंजीकरण जमा हो गया। जब आपके शिक्षक इसे स्वीकृत कर दें, तब नीचे अपनी जानकारी की पुष्टि करके लॉगिन विवरण बनाएँ।'
                    : 'अपनी जानकारी की पुष्टि करें, फिर लॉगिन विवरण बनाएँ।',
                style: const TextStyle(fontSize: 12.5, color: MedhaColors.successInk, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(color: MedhaColors.dangerWash, borderRadius: BorderRadius.circular(MedhaRadii.md)),
                child: Text(_error!, style: const TextStyle(fontSize: 12.5, color: MedhaColors.danger)),
              ),
              const SizedBox(height: 14),
            ],
            const _FieldLabel('विद्यालय'),
            const SizedBox(height: 6),
            TextField(
              controller: _schoolSearch,
              enabled: !_busy,
              onChanged: _onSchoolQueryChanged,
              decoration: const InputDecoration(hintText: 'नाम या ज़िला टाइप करें'),
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
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < _schoolResults.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      InkWell(
                        onTap: () {
                          final chosen = _schoolResults[i];
                          setState(() {
                            _selectedSchool = chosen;
                            _schoolResults = [];
                            _schoolSearch.text = chosen.name;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Text('${_schoolResults[i].name} — ${_schoolResults[i].districtName}', style: const TextStyle(fontSize: 13.5, color: MedhaColors.inkSoft)),
                        ),
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
                              initialValue: _grades.any((g) => g.id == _selectedGrade?.id) ? _selectedGrade : null,
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
                      TextField(controller: _rollNumber, enabled: !_busy),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _FieldLabel('पूरा नाम'),
            const SizedBox(height: 6),
            TextField(controller: _fullName, enabled: !_busy),
            const SizedBox(height: 18),
            const _FieldLabel('ईमेल'),
            const SizedBox(height: 6),
            TextField(controller: _email, enabled: !_busy, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'you@example.com')),
            const SizedBox(height: 14),
            const _FieldLabel('पासवर्ड'),
            const SizedBox(height: 6),
            TextField(
              controller: _password,
              enabled: !_busy,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'कम से कम 8 अक्षर',
                suffixIcon: IconButton(
                  icon: MedhaIcon(_obscure ? 'eye' : 'eye_off', size: 18, color: MedhaColors.muted),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('खाता सक्रिय करें'),
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
