import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/reference_api.dart';
import '../../core/models/reference.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_icon.dart';
import 'pending_approval_screen.dart';
import 'student_register_screen.dart';

enum _Role { teacher, principal, student }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.prefillFullName, this.prefillEmail, this.googleSub});

  /// Set when reached via "Continue with Google" on a brand-new identity --
  /// prefills name/email and, on submit, links the resulting pending row so
  /// a later Google login finds it directly.
  final String? prefillFullName;
  final String? prefillEmail;
  final String? googleSub;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  _Role _role = _Role.teacher;
  int _experience = 0;
  bool _busy = false;
  String? _error;

  late final _fullName = TextEditingController(text: widget.prefillFullName ?? '');
  late final _email = TextEditingController(text: widget.prefillEmail ?? '');
  final _password = TextEditingController();
  final _mobile = TextEditingController();
  final _employeeCode = TextEditingController();
  final _qualification = TextEditingController();
  final _schoolSearch = TextEditingController();

  Timer? _debounce;
  List<SchoolSearchResult> _schoolResults = [];
  SchoolSearchResult? _selectedSchool;
  bool _searching = false;

  static const _roleLabels = {_Role.teacher: 'शिक्षक', _Role.principal: 'प्रधानाध्यापक', _Role.student: 'छात्र'};

  @override
  void dispose() {
    _debounce?.cancel();
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _mobile.dispose();
    _employeeCode.dispose();
    _qualification.dispose();
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
    final email = _email.text.trim();
    final password = _password.text;
    final mobile = _mobile.text.trim();
    final employeeCode = _employeeCode.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.length < 8 || mobile.isEmpty || _selectedSchool == null) {
      setState(() => _error = 'सभी ज़रूरी फ़ील्ड भरें — पासवर्ड कम से कम 8 अक्षर का हो और विद्यालय सूची से चुनें।');
      return;
    }
    if (_role == _Role.teacher && employeeCode.isEmpty) {
      setState(() => _error = 'शिक्षक कोड ज़रूरी है।');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthApi.register(
        role: _role == _Role.teacher ? 'teacher' : 'principal',
        fullName: fullName,
        email: email,
        password: password,
        mobileNumber: mobile,
        schoolId: _selectedSchool!.id,
        employeeCode: _role == _Role.teacher ? employeeCode : null,
        yearsOfExperience: _role == _Role.teacher ? _experience : null,
        qualification: _qualification.text.trim().isEmpty ? null : _qualification.text.trim(),
        googleSub: widget.googleSub,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PendingApprovalScreen(
            email: email,
            password: password,
            fullName: fullName,
            schoolName: _selectedSchool!.name,
            employeeCode: _role == _Role.teacher ? employeeCode : null,
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
        title: const Text('रजिस्टर करें'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: MedhaColors.surface2, borderRadius: BorderRadius.circular(MedhaRadii.pill)),
              child: Row(
                children: _Role.values.map((role) {
                  final selected = role == _role;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (role == _Role.student) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const StudentRegisterScreen()),
                          );
                          return;
                        }
                        setState(() => _role = role);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? MedhaColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(MedhaRadii.pill),
                        ),
                        child: Text(
                          _roleLabels[role]!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : MedhaColors.muted,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(color: MedhaColors.dangerWash, borderRadius: BorderRadius.circular(MedhaRadii.md)),
                child: Text(_error!, style: const TextStyle(fontSize: 12.5, color: MedhaColors.danger)),
              ),
              const SizedBox(height: 14),
            ],
            _FieldLabel('पूरा नाम'),
            const SizedBox(height: 6),
            TextField(controller: _fullName, enabled: !_busy, decoration: const InputDecoration(hintText: 'जैसा प्रमाणपत्र पर दर्ज है')),
            const SizedBox(height: 14),
            _FieldLabel('ईमेल'),
            const SizedBox(height: 6),
            TextField(
              controller: _email,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'you@example.com'),
            ),
            const SizedBox(height: 14),
            _FieldLabel('पासवर्ड'),
            const SizedBox(height: 6),
            TextField(controller: _password, enabled: !_busy, obscureText: true, decoration: const InputDecoration(hintText: 'कम से कम 8 अक्षर')),
            const SizedBox(height: 14),
            _FieldLabel('मोबाइल नंबर'),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: MedhaColors.borderStrong, width: 1.5),
                    borderRadius: BorderRadius.circular(MedhaRadii.md),
                  ),
                  child: const Text('+91', style: TextStyle(fontSize: 14.5, color: MedhaColors.inkSoft)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _mobile,
                    enabled: !_busy,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: '98XXXXXXXX'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FieldLabel('विद्यालय'),
            const SizedBox(height: 6),
            TextField(
              controller: _schoolSearch,
              enabled: !_busy,
              onChanged: _onSchoolQueryChanged,
              decoration: InputDecoration(
                hintText: 'नाम या ज़िला टाइप करें',
                prefixIcon: const Padding(padding: EdgeInsets.all(13), child: MedhaIcon('search', size: 17, color: MedhaColors.muted)),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
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
                      _SchoolOption(
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
            if (_role == _Role.teacher) ...[
              const SizedBox(height: 14),
              _FieldLabel('शिक्षक कोड (Employee Code)'),
              const SizedBox(height: 6),
              TextField(controller: _employeeCode, enabled: !_busy, decoration: const InputDecoration(hintText: 'जैसे BR-GA-04521')),
              const SizedBox(height: 5),
              const Text(
                'यह आपके नियुक्ति पत्र पर दर्ज कोड है — इसी से प्रधानाध्यापक आपकी पुष्टि करेंगे।',
                style: TextStyle(fontSize: 11.5, color: MedhaColors.muted, height: 1.4),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_role == _Role.teacher)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('अनुभव (वर्ष)'),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(border: Border.all(color: MedhaColors.borderStrong, width: 1.5), borderRadius: BorderRadius.circular(MedhaRadii.md)),
                          child: Row(
                            children: [
                              _StepperButton(icon: 'minus', onTap: () => setState(() => _experience = (_experience - 1).clamp(0, 50))),
                              Expanded(child: Center(child: Text('$_experience', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)))),
                              _StepperButton(icon: 'plus', onTap: () => setState(() => _experience = (_experience + 1).clamp(0, 50))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_role == _Role.teacher) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('योग्यता'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _qualification,
                        enabled: !_busy,
                        decoration: const InputDecoration(hintText: 'जैसे B.Ed, स्नातक'),
                      ),
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
                    : const Text('रजिस्ट्रेशन जमा करें'),
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
                      'रजिस्ट्रेशन के बाद आपके विद्यालय के प्रधानाध्यापक की स्वीकृति आवश्यक होगी। स्वीकृति मिलते ही आपको सूचित किया जाएगा।',
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

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final String icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: SizedBox(width: 38, height: 46, child: Center(child: MedhaIcon(icon, size: 15, color: MedhaColors.inkSoft))));
  }
}

class _SchoolOption extends StatelessWidget {
  const _SchoolOption(this.label, {required this.onTap});
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
