import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/widgets/medha_logo.dart';

/// Mirrors shiksha_sathi/app/(protected)/onboarding/page.tsx exactly: a
/// 3-step wizard (profile -> subjects/grades -> confirm) gated in the router
/// for any teacher whose `onboarded_at` is null. Submits
/// POST /onboarding/complete with {full_name, school_id, subjects:
/// [{subject_id, grade_id, is_primary}]} — the backend requires at least one
/// pair and exactly one marked primary (backend/src/backend/onboarding/schemas.py).
class _School {
  final String id, name, districtName;
  _School({required this.id, required this.name, required this.districtName});
  factory _School.fromJson(Map<String, dynamic> j) => _School(
    id: j['id'] as String,
    name: j['name'] as String,
    districtName: j['district_name'] as String? ?? '',
  );
}

class _Grade {
  final String id, label;
  final int numericLevel;
  _Grade({required this.id, required this.label, required this.numericLevel});
  factory _Grade.fromJson(Map<String, dynamic> j) => _Grade(
    id: j['id'] as String,
    label: j['label'] as String,
    numericLevel: j['numeric_level'] as int? ?? 0,
  );
}

class _Subject {
  final String id, name;
  _Subject({required this.id, required this.name});
  factory _Subject.fromJson(Map<String, dynamic> j) =>
      _Subject(id: j['id'] as String, name: j['name'] as String);
}

class _Selection {
  final String subjectId, gradeId;
  bool isPrimary;
  _Selection({required this.subjectId, required this.gradeId, this.isPrimary = false});
}

class TeacherOnboardingScreen extends ConsumerStatefulWidget {
  const TeacherOnboardingScreen({super.key});
  @override
  ConsumerState<TeacherOnboardingScreen> createState() => _TeacherOnboardingScreenState();
}

class _TeacherOnboardingScreenState extends ConsumerState<TeacherOnboardingScreen> {
  int _step = 1;

  final _nameCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  _School? _selectedSchool;
  List<_School> _schoolResults = [];
  bool _schoolSearching = false;

  List<_Grade> _grades = [];
  List<_Subject> _subjects = [];
  bool _refLoading = true;
  final List<_Selection> _selections = [];

  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull?.user;
    if (user != null) _nameCtrl.text = user.fullName;
    _loadReference();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _schoolCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReference() async {
    dynamic gradesRes, subjectsRes;
    try { gradesRes = await ref.read(apiClientProvider).get('/reference/grades'); } catch (_) {}
    try { subjectsRes = await ref.read(apiClientProvider).get('/reference/subjects'); } catch (_) {}
    if (mounted) {
      setState(() {
        _grades = ((gradesRes?.data as List?) ?? []).map((e) => _Grade.fromJson(e as Map<String, dynamic>)).toList();
        _subjects = ((subjectsRes?.data as List?) ?? []).map((e) => _Subject.fromJson(e as Map<String, dynamic>)).toList();
        _refLoading = false;
      });
    }
  }

  Future<void> _searchSchools(String query) async {
    if (query.trim().length < 2) { setState(() => _schoolResults = []); return; }
    setState(() => _schoolSearching = true);
    try {
      final res = await ref.read(apiClientProvider).get('/schools/search', queryParameters: {'q': query});
      final list = (res.data as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _schoolResults = list.map(_School.fromJson).toList(); _schoolSearching = false; });
    } catch (_) {
      if (mounted) setState(() => _schoolSearching = false);
    }
  }

  void _toggleSelection(String subjectId, String gradeId) {
    setState(() {
      final idx = _selections.indexWhere((s) => s.subjectId == subjectId && s.gradeId == gradeId);
      if (idx != -1) {
        final wasPrimary = _selections[idx].isPrimary;
        _selections.removeAt(idx);
        if (wasPrimary && _selections.isNotEmpty) _selections.first.isPrimary = true;
      } else {
        _selections.add(_Selection(
          subjectId: subjectId, gradeId: gradeId, isPrimary: _selections.isEmpty));
      }
    });
  }

  void _setPrimary(String subjectId, String gradeId) {
    setState(() {
      for (final s in _selections) {
        s.isPrimary = s.subjectId == subjectId && s.gradeId == gradeId;
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedSchool == null || _selections.isEmpty) return;
    setState(() { _submitting = true; _submitError = null; });
    try {
      await ref.read(apiClientProvider).post('/onboarding/complete', data: {
        'full_name': _nameCtrl.text.trim(),
        'school_id': _selectedSchool!.id,
        'subjects': _selections.map((s) => {
          'subject_id': s.subjectId,
          'grade_id': s.gradeId,
          'is_primary': s.isPrimary,
        }).toList(),
      });
      // Onboarding changes onboarded_at on the server; refresh the cached
      // user so the router's redirect gate (isTeacher && onboardedAt==null)
      // stops firing and lets the teacher through to the dashboard.
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) setState(() { _submitError = extractApiError(e); _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background.png',
                fit: BoxFit.cover, alignment: const Alignment(0, -0.3)),
          ),
          Positioned.fill(child: Container(color: AppColors.ivory.withValues(alpha: 0.88))),
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const MedhaLogo(height: 64),
                        const SizedBox(height: 16),
                        Text(
                          switch (_step) { 1 => 'Your profile', 2 => 'What you teach', _ => 'Confirm' },
                          style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [1, 2, 3].map((s) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: s == _step ? 24 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: s <= _step ? AppColors.terracotta : AppColors.hairline,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: switch (_step) {
                            1 => _buildProfileStep(),
                            2 => _buildSubjectsStep(),
                            _ => _buildConfirmStep(),
                          },
                        ).animate(key: ValueKey(_step)).fadeIn(duration: 220.ms).slideX(begin: 0.06, end: 0),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => ref.read(authProvider.notifier).logout(),
                          child: Text('Not you? Log out',
                              style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground)),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
        const SizedBox(height: 12),
        TextField(
          controller: _schoolCtrl,
          decoration: InputDecoration(
            labelText: _selectedSchool != null ? 'School (selected)' : 'Search School',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _schoolSearching
                ? const Padding(padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                : _selectedSchool != null
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.sage)
                    : null,
          ),
          onChanged: (v) { setState(() => _selectedSchool = null); _searchSchools(v); },
        ),
        if (_schoolResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Material(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _schoolResults.length.clamp(0, 6),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final s = _schoolResults[i];
                  return ListTile(
                    dense: true,
                    title: Text(s.name, style: GoogleFonts.manrope(fontSize: 13, color: AppColors.ink)),
                    subtitle: Text(s.districtName, style: GoogleFonts.manrope(fontSize: 11, color: AppColors.mutedForeground)),
                    onTap: () => setState(() {
                      _selectedSchool = s;
                      _schoolCtrl.text = s.name;
                      _schoolResults = [];
                    }),
                  );
                },
              ),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nameCtrl.text.trim().isNotEmpty && _selectedSchool != null
                ? () => setState(() => _step = 2)
                : null,
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsStep() {
    if (_refLoading) {
      return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
    }
    final selectedKeys = _selections.map((s) => '${s.subjectId}:${s.gradeId}').toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tap every subject and grade combination that applies.',
            style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 90),
                  ..._grades.map((g) => SizedBox(
                    width: 42,
                    child: Text(g.numericLevel.toString(), textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(fontSize: 11, color: AppColors.mutedForeground)),
                  )),
                ],
              ),
              const SizedBox(height: 6),
              ..._subjects.map((subject) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(width: 90, child: Text(subject.name,
                        style: GoogleFonts.manrope(fontSize: 13, color: AppColors.ink))),
                    ..._grades.map((grade) {
                      final key = '${subject.id}:${grade.id}';
                      final selected = selectedKeys.contains(key);
                      return SizedBox(
                        width: 42,
                        child: Center(
                          child: GestureDetector(
                            onTap: () => _toggleSelection(subject.id, grade.id),
                            child: Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: selected ? AppColors.terracotta : Colors.transparent,
                                border: Border.all(color: selected ? AppColors.terracotta : AppColors.hairline),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: () => setState(() => _step = 1), child: const Text('Back')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _selections.isNotEmpty ? () => setState(() => _step = 3) : null,
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _gradeLabel(String id) => _grades.firstWhere((g) => g.id == id, orElse: () => _Grade(id: id, label: '?', numericLevel: 0)).label;
  String _subjectName(String id) => _subjects.firstWhere((s) => s.id == id, orElse: () => _Subject(id: id, name: '?')).name;

  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_nameCtrl.text.trim(), style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
        Text(_selectedSchool?.name ?? '', style: GoogleFonts.manrope(fontSize: 13, color: AppColors.mutedForeground)),
        const SizedBox(height: 12),
        ..._selections.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text('${_subjectName(s.subjectId)} — ${_gradeLabel(s.gradeId)}',
                    style: GoogleFonts.manrope(fontSize: 13, color: AppColors.ink)),
              ),
              GestureDetector(
                onTap: () => _setPrimary(s.subjectId, s.gradeId),
                child: Icon(s.isPrimary ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: s.isPrimary ? AppColors.gold : AppColors.mutedForeground, size: 20),
              ),
            ],
          ),
        )),
        if (_submitError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.destructive.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.destructive.withValues(alpha: 0.25)),
            ),
            child: Text(_submitError!, style: GoogleFonts.manrope(fontSize: 13, color: AppColors.destructive)),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting ? null : () => setState(() => _step = 2),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Finish'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
