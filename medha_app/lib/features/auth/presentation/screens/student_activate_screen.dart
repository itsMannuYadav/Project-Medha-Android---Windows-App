import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/medha_logo.dart';

/// Mirrors shiksha_sathi/app/student/activate/page.tsx. A student registers
/// with no credentials (a teacher approves the roll-number record), then
/// "claims" that approved record here by re-supplying school+grade+roll+name
/// and setting an email/password — POST /student/activate
/// (backend: {school_id, grade_id, roll_number, full_name, email, password}).
/// Only after this can the student log in at all.
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
  _Grade({required this.id, required this.label});
  factory _Grade.fromJson(Map<String, dynamic> j) =>
      _Grade(id: j['id'] as String, label: j['label'] as String);
}

class StudentActivateScreen extends ConsumerStatefulWidget {
  const StudentActivateScreen({super.key});
  @override
  ConsumerState<StudentActivateScreen> createState() => _StudentActivateScreenState();
}

class _StudentActivateScreenState extends ConsumerState<StudentActivateScreen> {
  final _nameCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  _School? _selectedSchool;
  List<_School> _schoolResults = [];
  bool _schoolSearching = false;

  List<_Grade> _grades = [];
  _Grade? _selectedGrade;
  bool _gradesFailed = false;

  bool _showPass = false;
  bool _showConfirm = false;
  bool _submitting = false;
  bool _done = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _schoolCtrl, _rollCtrl, _emailCtrl, _passCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadGrades() async {
    // No setState before the first await: unlike register_screen.dart's
    // _loadGrades (only ever called from a post-build tap handler), this one
    // is invoked directly from initState — a synchronous setState there runs
    // before the widget's first build completes, which flutter_test's
    // stricter checking turns into a hang (the widget never settles) rather
    // than the harmless no-op it is in a real running app. _gradesFailed
    // already defaults to false, so resetting it here was redundant anyway.
    if (mounted && _gradesFailed) setState(() => _gradesFailed = false);
    try {
      final res = await ref.read(apiClientProvider).get('/reference/grades');
      final list = (res.data as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _grades = list.map(_Grade.fromJson).toList());
    } catch (_) {
      if (mounted) setState(() => _gradesFailed = true);
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

  String? get _formError {
    if (_nameCtrl.text.trim().length < 2) return 'Enter your full name.';
    if (_selectedSchool == null) return 'Pick your school.';
    if (_selectedGrade == null) return 'Select your class.';
    if (_rollCtrl.text.trim().isEmpty) return 'Enter your roll number.';
    if (!_emailCtrl.text.contains('@')) return 'Enter a valid email.';
    if (_passCtrl.text.length < 8) return 'Password must be at least 8 characters.';
    if (_passCtrl.text != _confirmCtrl.text) return "Passwords don't match.";
    return null;
  }

  Future<void> _submit() async {
    final err = _formError;
    if (err != null) { setState(() => _errorMsg = err); return; }
    setState(() { _submitting = true; _errorMsg = null; });
    try {
      await ref.read(apiClientProvider).post('/student/activate', data: {
        'school_id': _selectedSchool!.id,
        'grade_id': _selectedGrade!.id,
        'roll_number': _rollCtrl.text.trim(),
        'full_name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passCtrl.text,
      });
      if (mounted) setState(() { _done = true; _submitting = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMsg = extractApiError(e); _submitting = false; });
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
              child: _done ? _buildDone(context) : _buildForm(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const MedhaLogo(height: 70),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Activate Your Account',
                              style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Confirm the details a teacher already approved, then set your login.',
                        style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground)),
                    const SizedBox(height: 16),
                    TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name'),
                        textCapitalization: TextCapitalization.words),
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
                    const SizedBox(height: 12),
                    if (_grades.isNotEmpty) DropdownButtonFormField<_Grade>(
                      value: _selectedGrade,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Class / Grade'),
                      items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g.label))).toList(),
                      onChanged: (g) => setState(() => _selectedGrade = g),
                    ) else if (_gradesFailed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
                          color: AppColors.destructive.withValues(alpha: 0.05),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text("Couldn't load classes.",
                                style: GoogleFonts.manrope(fontSize: 13, color: AppColors.destructive))),
                            TextButton(onPressed: _loadGrades, child: const Text('Retry')),
                          ],
                        ),
                      )
                    else const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    const SizedBox(height: 12),
                    TextField(controller: _rollCtrl, decoration: const InputDecoration(labelText: 'Roll Number')),
                    const SizedBox(height: 12),
                    TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passCtrl,
                      decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(
                        icon: Icon(_showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                        onPressed: () => setState(() => _showPass = !_showPass),
                      )),
                      obscureText: !_showPass,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmCtrl,
                      decoration: InputDecoration(labelText: 'Confirm Password', suffixIcon: IconButton(
                        icon: Icon(_showConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                        onPressed: () => setState(() => _showConfirm = !_showConfirm),
                      )),
                      obscureText: !_showConfirm,
                    ),
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.destructive.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.destructive.withValues(alpha: 0.25)),
                        ),
                        child: Text(_errorMsg!, style: GoogleFonts.manrope(fontSize: 13, color: AppColors.destructive)),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Activate'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Text('Back to Sign In',
                    style: GoogleFonts.manrope(fontSize: 13, color: AppColors.terracotta, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDone(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.sage, size: 56),
              const SizedBox(height: 16),
              Text('Account Activated!',
                  style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 10),
              Text('You can log in now with your new email and password.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(fontSize: 14, color: AppColors.mutedForeground)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to Sign In'),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
