import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/medha_logo.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

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

// ─── Screen ───────────────────────────────────────────────────────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  /// Mirrors app/register/page.tsx's `?role=` handling: /register?role=teacher
  /// (etc.) jumps straight to the role-specific form instead of showing the
  /// picker first. Login's three inline "Register as a principal, teacher or
  /// student" links each pass this.
  final String? initialRole;
  const RegisterScreen({super.key, this.initialRole});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late int _step;
  late String _role;

  static const _validRoles = {'student', 'teacher', 'principal'};

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _empCodeCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _qualCtrl = TextEditingController();

  bool _showPass = false;
  bool _showConfirm = false;
  bool _submitting = false;
  bool _done = false;
  String? _errorMsg;

  // School typeahead
  _School? _selectedSchool;
  List<_School> _schoolResults = [];
  final _schoolCtrl = TextEditingController();
  bool _schoolSearching = false;

  // Grade
  _Grade? _selectedGrade;
  List<_Grade> _grades = [];
  bool _gradesFailed = false;

  @override
  void initState() {
    super.initState();
    final role = widget.initialRole;
    if (role != null && _validRoles.contains(role)) {
      _role = role;
      _step = 2;
      if (role == 'student') _loadGrades();
    } else {
      _role = 'student';
      _step = 1;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _emailCtrl, _passCtrl, _confirmCtrl, _mobileCtrl,
      _rollCtrl, _empCodeCtrl, _expCtrl, _qualCtrl, _schoolCtrl,
    ]) { c.dispose(); }
    super.dispose();
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

  Future<void> _loadGrades() async {
    if (_grades.isNotEmpty) return;
    // Guarded like student_activate_screen.dart's _loadGrades: this can now
    // be called from initState (when initialRole == 'student'), and a bare
    // setState there — before the first build completes — hangs
    // flutter_test indefinitely instead of failing cleanly.
    if (mounted && _gradesFailed) setState(() => _gradesFailed = false);
    try {
      final res = await ref.read(apiClientProvider).get('/reference/grades');
      final list = (res.data as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _grades = list.map(_Grade.fromJson).toList());
    } catch (_) {
      if (mounted) setState(() => _gradesFailed = true);
    }
  }

  String? get _formError {
    if (_nameCtrl.text.trim().length < 2) return 'Enter your full name.';
    if (_selectedSchool == null) return 'Pick your school.';
    if (_role == 'student') {
      if (_selectedGrade == null) return 'Select your class.';
      if (_rollCtrl.text.trim().isEmpty) return 'Enter your roll number.';
      return null;
    }
    if (!_emailCtrl.text.contains('@')) return 'Enter a valid email.';
    if (_passCtrl.text.length < 8) return 'Password must be at least 8 characters.';
    if (_passCtrl.text != _confirmCtrl.text) return "Passwords don't match.";
    final digits = _mobileCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Enter a valid 10-digit mobile number.';
    if (_role == 'teacher' && _empCodeCtrl.text.trim().isEmpty) return 'Employee code is required.';
    return null;
  }

  Future<void> _submit() async {
    final err = _formError;
    if (err != null) { setState(() => _errorMsg = err); return; }
    setState(() { _submitting = true; _errorMsg = null; });
    try {
      final api = ref.read(apiClientProvider);
      if (_role == 'student') {
        await api.post('/student/register', data: {
          'full_name': _nameCtrl.text.trim(),
          'school_id': _selectedSchool!.id,
          'grade_id': _selectedGrade!.id,
          'roll_number': _rollCtrl.text.trim(),
        });
      } else {
        final digits = _mobileCtrl.text.replaceAll(RegExp(r'\D'), '');
        await api.post('/auth/register', data: {
          'role': _role,
          'full_name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'password': _passCtrl.text,
          'mobile_number': digits,
          'school_id': _selectedSchool!.id,
          if (_role == 'teacher' && _empCodeCtrl.text.isNotEmpty)
            'employee_code': _empCodeCtrl.text.trim(),
          if (_expCtrl.text.isNotEmpty) 'years_of_experience': int.tryParse(_expCtrl.text),
          if (_qualCtrl.text.isNotEmpty) 'qualification': _qualCtrl.text.trim(),
        });
      }
      if (mounted) setState(() { _done = true; _submitting = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMsg = e.toString(); _submitting = false; });
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
              child: _done ? _PendingView(role: _role) : _buildForm(context),
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
              if (_step == 1) _RolePicker(
                selectedRole: _role,
                onSelect: (r) {
                  setState(() { _role = r; _step = 2; });
                  if (r == 'student') _loadGrades();
                },
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06),
              if (_step == 2) _FormStep(
                role: _role,
                nameCtrl: _nameCtrl,
                emailCtrl: _emailCtrl,
                passCtrl: _passCtrl,
                confirmCtrl: _confirmCtrl,
                mobileCtrl: _mobileCtrl,
                rollCtrl: _rollCtrl,
                empCodeCtrl: _empCodeCtrl,
                expCtrl: _expCtrl,
                qualCtrl: _qualCtrl,
                showPass: _showPass,
                showConfirm: _showConfirm,
                onTogglePass: () => setState(() => _showPass = !_showPass),
                onToggleConfirm: () => setState(() => _showConfirm = !_showConfirm),
                selectedSchool: _selectedSchool,
                schoolCtrl: _schoolCtrl,
                schoolResults: _schoolResults,
                schoolSearching: _schoolSearching,
                onSchoolSearch: _searchSchools,
                onSchoolSelect: (s) => setState(() {
                  _selectedSchool = s;
                  _schoolCtrl.text = s.name;
                  _schoolResults = [];
                }),
                grades: _grades,
                selectedGrade: _selectedGrade,
                onGradeSelect: (g) => setState(() => _selectedGrade = g),
                gradesFailed: _gradesFailed,
                onRetryGrades: _loadGrades,
                errorMsg: _errorMsg,
                submitting: _submitting,
                onSubmit: _submit,
                onBack: () => setState(() { _step = 1; _errorMsg = null; }),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Text('Already have an account? Sign in',
                    style: GoogleFonts.manrope(
                        fontSize: 13, color: AppColors.terracotta, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Role Picker ─────────────────────────────────────────────────────────────

class _RolePicker extends StatelessWidget {
  final String selectedRole;
  final void Function(String) onSelect;
  const _RolePicker({required this.selectedRole, required this.onSelect});

  static const _cards = [
    (id: 'student', label: 'Student', emoji: '🎓', desc: 'Access textbooks, e-content and practice tests.'),
    (id: 'teacher', label: 'Teacher', emoji: '📚', desc: 'Build lessons, track classes and assignments.'),
    (id: 'principal', label: 'Principal', emoji: '🏫', desc: 'Oversee teacher approvals and school records.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Create your account',
            style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 4),
        Text("Choose how you'll use Medha",
            style: GoogleFonts.manrope(fontSize: 14, color: AppColors.mutedForeground)),
        const SizedBox(height: 20),
        ..._cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onSelect(c.id),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedRole == c.id ? AppColors.terracotta : AppColors.hairline,
                  width: selectedRole == c.id ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(c.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.label,
                            style: GoogleFonts.manrope(
                                fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
                        Text(c.desc,
                            style: GoogleFonts.manrope(
                                fontSize: 12, color: AppColors.mutedForeground)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.mutedForeground),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }
}

// ─── Form Step ───────────────────────────────────────────────────────────────

class _FormStep extends StatelessWidget {
  final String role;
  final TextEditingController nameCtrl, emailCtrl, passCtrl, confirmCtrl,
      mobileCtrl, rollCtrl, empCodeCtrl, expCtrl, qualCtrl, schoolCtrl;
  final bool showPass, showConfirm, submitting, schoolSearching;
  final VoidCallback onTogglePass, onToggleConfirm, onSubmit, onBack;
  final _School? selectedSchool;
  final List<_School> schoolResults;
  final void Function(String) onSchoolSearch;
  final void Function(_School) onSchoolSelect;
  final List<_Grade> grades;
  final _Grade? selectedGrade;
  final void Function(_Grade) onGradeSelect;
  final bool gradesFailed;
  final VoidCallback onRetryGrades;
  final String? errorMsg;

  const _FormStep({
    required this.role,
    required this.nameCtrl, required this.emailCtrl, required this.passCtrl,
    required this.confirmCtrl, required this.mobileCtrl, required this.rollCtrl,
    required this.empCodeCtrl, required this.expCtrl, required this.qualCtrl,
    required this.schoolCtrl,
    required this.showPass, required this.showConfirm, required this.submitting,
    required this.schoolSearching,
    required this.onTogglePass, required this.onToggleConfirm, required this.onSubmit,
    required this.onBack,
    required this.selectedSchool, required this.schoolResults, required this.onSchoolSearch,
    required this.onSchoolSelect,
    required this.grades, required this.selectedGrade, required this.onGradeSelect,
    required this.gradesFailed, required this.onRetryGrades,
    required this.errorMsg,
  });

  static const _roleMeta = {
    'student': (emoji: '🎓', label: 'Student'),
    'teacher': (emoji: '📚', label: 'Teacher'),
    'principal': (emoji: '🏫', label: 'Principal'),
  };

  @override
  Widget build(BuildContext context) {
    final isStudent = role == 'student';
    final isTeacher = role == 'teacher';
    final meta = _roleMeta[role]!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "← Change role" + role badge chip, mirroring the web app's header row.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onBack,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.mutedForeground),
                    const SizedBox(width: 4),
                    Text('Change role',
                        style: GoogleFonts.manrope(fontSize: 13, color: AppColors.mutedForeground)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(meta.emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(meta.label,
                        style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Create your ${meta.label} account',
            style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.authDeep),
          ),
          const SizedBox(height: 4),
          Text(
            isStudent
                ? 'A teacher at your school approves student accounts.'
                : isTeacher
                    ? 'Your principal approves teacher accounts.'
                    : 'An administrator approves principal accounts.',
            style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 18),

          // Field order mirrors app/register/page.tsx exactly: full name, then
          // (non-student) email/password+confirm/mobile, THEN school, then
          // role-specific fields last. School does not come right after name.
          _LabeledField('Full name', child: TextField(
            controller: nameCtrl, textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'e.g. Anita Kumari'),
          )),
          const SizedBox(height: 14),

          if (!isStudent) ...[
            _LabeledField('Email', child: TextField(
              controller: emailCtrl, keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'you@example.com'),
            )),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LabeledField('Password', child: TextField(
                    controller: passCtrl, obscureText: !showPass,
                    decoration: InputDecoration(
                      hintText: '8+ characters',
                      suffixIcon: IconButton(
                        icon: Icon(showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                        onPressed: onTogglePass,
                      ),
                    ),
                  )),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LabeledField('Confirm', child: TextField(
                    controller: confirmCtrl, obscureText: !showConfirm,
                    decoration: InputDecoration(
                      hintText: 'Repeat password',
                      suffixIcon: IconButton(
                        icon: Icon(showConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                        onPressed: onToggleConfirm,
                      ),
                    ),
                  )),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _LabeledField('Mobile number', child: TextField(
              controller: mobileCtrl, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '10-digit number'),
            )),
            const SizedBox(height: 14),
          ],

          _LabeledField('School', child: _SchoolField(
            ctrl: schoolCtrl,
            selected: selectedSchool,
            results: schoolResults,
            searching: schoolSearching,
            onSearch: onSchoolSearch,
            onSelect: onSchoolSelect,
          )),
          const SizedBox(height: 14),

          if (isStudent) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LabeledField('Class', child: grades.isNotEmpty
                      ? DropdownButtonFormField<_Grade>(
                          value: selectedGrade,
                          isExpanded: true,
                          decoration: const InputDecoration(hintText: 'Select'),
                          items: grades.map((g) => DropdownMenuItem(value: g, child: Text(g.label))).toList(),
                          onChanged: (g) { if (g != null) onGradeSelect(g); },
                        )
                      : _GradeLoadingTile(failed: gradesFailed, onRetry: onRetryGrades)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LabeledField('Roll number', child: TextField(
                    controller: rollCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. 23'),
                  )),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          if (isTeacher) ...[
            _LabeledField('Employee code (government teacher ID)', child: TextField(
              controller: empCodeCtrl,
              decoration: const InputDecoration(hintText: 'As on your service record'),
            )),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LabeledField('Years of experience', child: TextField(
                    controller: expCtrl, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'e.g. 7'),
                  )),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LabeledField('Qualification', child: TextField(
                    controller: qualCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. B.Ed'),
                  )),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ] else if (!isStudent) ...[
            _LabeledField('Qualification (optional)', child: TextField(
              controller: qualCtrl,
              decoration: const InputDecoration(hintText: 'e.g. M.Ed'),
            )),
            const SizedBox(height: 14),
          ],

          // Error
          if (errorMsg != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.destructive.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.destructive.withValues(alpha: 0.25)),
              ),
              child: Text(errorMsg!,
                  style: GoogleFonts.manrope(fontSize: 13, color: AppColors.destructive)),
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitting ? null : onSubmit,
              child: submitting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Register'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Label-above-input pattern matching the web app's shared `Field` component
/// (components/ui/label.tsx's shadcn Label + a `flex flex-col gap-2` wrapper)
/// — not Material's floating labelText-inside-border style used elsewhere
/// in this app's simpler forms.
class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField(this.label, {required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _GradeLoadingTile extends StatelessWidget {
  final bool failed;
  final VoidCallback onRetry;
  const _GradeLoadingTile({required this.failed, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (!failed) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
        color: AppColors.destructive.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text("Couldn't load classes.",
                style: GoogleFonts.manrope(fontSize: 13, color: AppColors.destructive)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ─── School Typeahead ─────────────────────────────────────────────────────────

class _SchoolField extends StatelessWidget {
  final TextEditingController ctrl;
  final _School? selected;
  final List<_School> results;
  final bool searching;
  final void Function(String) onSearch;
  final void Function(_School) onSelect;
  const _SchoolField({
    required this.ctrl, required this.selected, required this.results,
    required this.searching, required this.onSearch, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'Search by school name',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: searching
                ? const Padding(padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                : selected != null
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.sage)
                    : null,
          ),
          onChanged: onSearch,
        ),
        if (results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.hairline),
              boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 8)],
            ),
            // Material (not just a colored Container) so ListTile's ink
            // splashes and background paint on this ancestor instead of
            // being silently swallowed — Flutter throws exactly this
            // assertion in debug mode when it isn't.
            child: Material(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.length.clamp(0, 6),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final s = results[i];
                  return ListTile(
                    dense: true,
                    title: Text(s.name, style: GoogleFonts.manrope(fontSize: 13, color: AppColors.ink)),
                    subtitle: Text(s.districtName,
                        style: GoogleFonts.manrope(fontSize: 11, color: AppColors.mutedForeground)),
                    onTap: () => onSelect(s),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Pending confirmation screen ──────────────────────────────────────────────

class _PendingView extends StatelessWidget {
  final String role;
  const _PendingView({required this.role});

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.hourglass_top_rounded, color: AppColors.gold, size: 56),
              const SizedBox(height: 16),
              Text('Registration Submitted!',
                  style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 10),
              Text(
                switch (role) {
                  'student' => 'Your request has been submitted. A teacher will approve your account.',
                  'teacher' => 'Your account has been created and is pending approval from your principal. You\'ll be able to log in once it\'s approved.',
                  _ => 'Your account has been created and is pending approval from an administrator. You\'ll be able to log in once it\'s approved.',
                },
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 14, color: AppColors.mutedForeground),
              ),
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
