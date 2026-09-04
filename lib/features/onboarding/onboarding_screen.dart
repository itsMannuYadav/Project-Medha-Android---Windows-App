import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/onboarding_api.dart';
import '../../core/api/reference_api.dart';
import '../../core/models/reference.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../shell/app_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _selectedGradeIds = <String>{};
  final _selectedSubjectIds = <String>{};

  List<GradeRef> _grades = [];
  List<SubjectRef> _subjects = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([ReferenceApi.grades(), ReferenceApi.subjects()]);
      if (!mounted) return;
      setState(() {
        _grades = results[0] as List<GradeRef>;
        _subjects = results[1] as List<SubjectRef>;
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

  void _toggle(Set<String> set, String id) => setState(() => set.contains(id) ? set.remove(id) : set.add(id));

  /// The API wants explicit (subject, grade) pairs, not two independent
  /// sets -- the Cartesian product of the two multiselects is exactly that
  /// (picking Science+SocialScience for Class 8+9 means all four pairs).
  List<SubjectGradePair> get _pairs {
    final pairs = <SubjectGradePair>[];
    for (final subjectId in _selectedSubjectIds) {
      for (final gradeId in _selectedGradeIds) {
        pairs.add(SubjectGradePair(subjectId: subjectId, gradeId: gradeId, isPrimary: pairs.isEmpty));
      }
    }
    return pairs;
  }

  Future<void> _submit() async {
    final pairs = _pairs;
    if (pairs.isEmpty) {
      setState(() => _error = 'कम से कम एक कक्षा और एक विषय चुनें।');
      return;
    }
    final appState = AppScope.of(context, listen: false);
    final teacher = appState.teacher;
    if (teacher?.schoolId == null) {
      setState(() => _error = 'आपका खाता किसी विद्यालय से जुड़ा नहीं है।');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final updated = await OnboardingApi.complete(
        fullName: teacher!.fullName,
        schoolId: teacher.schoolId!,
        subjects: pairs,
      );
      appState.setSignedIn(updated);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AppShell()), (route) => false);
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Container(height: 4, decoration: BoxDecoration(color: MedhaColors.primary, borderRadius: BorderRadius.circular(2)))),
                            const SizedBox(width: 6),
                            Expanded(child: Container(height: 4, decoration: BoxDecoration(color: MedhaColors.primary, borderRadius: BorderRadius.circular(2)))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('लगभग हो गया', style: TextStyle(fontSize: 11.5, color: MedhaColors.muted)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('आप कौन सी कक्षाएं\nऔर विषय पढ़ाते हैं?',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: MedhaColors.ink, height: 1.4)),
                          const SizedBox(height: 6),
                          const Text('एक से अधिक चुन सकते हैं — इसी से मेधा आपके लिए सही सामग्री तैयार करेगी।',
                              style: TextStyle(fontSize: 13.5, color: MedhaColors.inkSoft)),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(color: MedhaColors.dangerWash, borderRadius: BorderRadius.circular(MedhaRadii.md)),
                              child: Text(_error!, style: const TextStyle(fontSize: 12.5, color: MedhaColors.danger)),
                            ),
                          ],
                          const SizedBox(height: 26),
                          const Text('कक्षा', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _grades
                                .map((g) => _Chip(
                                      label: g.label,
                                      selected: _selectedGradeIds.contains(g.id),
                                      selectedColor: MedhaColors.primary,
                                      onTap: () => _toggle(_selectedGradeIds, g.id),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 28),
                          const Text('विषय', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _subjects
                                .map((s) => _Chip(
                                      label: s.name,
                                      selected: _selectedSubjectIds.contains(s.id),
                                      selectedColor: MedhaColors.accent,
                                      selectedBg: MedhaColors.accentWash,
                                      selectedFg: MedhaColors.accentInk,
                                      onTap: () => _toggle(_selectedSubjectIds, s.id),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                            decoration: BoxDecoration(color: MedhaColors.primaryWash, borderRadius: BorderRadius.circular(MedhaRadii.md)),
                            child: Text.rich(
                              TextSpan(
                                style: const TextStyle(fontSize: 12.5, color: MedhaColors.primary, height: 1.55),
                                children: [
                                  const TextSpan(text: 'चुना गया: '),
                                  TextSpan(
                                    text: _selectedGradeIds.isEmpty
                                        ? '—'
                                        : _grades.where((g) => _selectedGradeIds.contains(g.id)).map((g) => g.label).join(', '),
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const TextSpan(text: ' · '),
                                  TextSpan(
                                    text: _selectedSubjectIds.isEmpty
                                        ? '—'
                                        : _subjects.where((s) => _selectedSubjectIds.contains(s.id)).map((s) => s.name).join(', '),
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const TextSpan(text: ' — प्रोफ़ाइल से कभी भी बदल सकते हैं।'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
                    decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(top: BorderSide(color: MedhaColors.border))),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('आगे बढ़ें'),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    this.selectedBg,
    this.selectedFg,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color? selectedBg;
  final Color? selectedFg;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? (selectedBg ?? selectedColor) : MedhaColors.surface,
          borderRadius: BorderRadius.circular(MedhaRadii.pill),
          border: Border.all(color: selected ? selectedColor : MedhaColors.borderStrong, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: selected ? (selectedFg ?? Colors.white) : MedhaColors.inkSoft,
          ),
        ),
      ),
    );
  }
}
