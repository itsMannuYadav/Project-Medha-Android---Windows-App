import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/language_toggle.dart';
import '../../../shared/widgets/medha_logo.dart';
import '../providers/auth_provider.dart';
import '../../data/auth_models.dart';

/// Mirrors app/login/page.tsx + the .mlogin-* rules in globals.css exactly,
/// verified 2026-09-17 against the live site (https://project-medha.vercel.app)
/// — colors sampled directly from its computed styles, not re-derived from
/// memory. Two things worth remembering if this drifts again:
///  - The tagline ("Your AI teaching companion") is `copy.login.subtitle`
///    (localized); "Sign in to your Medha account" right below it is a
///    hardcoded English literal in the JSX, always English regardless of
///    locale — that's the real product's behavior, not a bug to "fix" here.
///  - The active role tab / heading / submit button all use a bespoke
///    `oklch(0.360 0.089 40.0)` deep terracotta (AppColors.authDeep),
///    distinct from the shared `--terracotta` token used elsewhere in the
///    app (sidebars, CTAs) — do not conflate the two.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _activeRole = 'student';
  bool _showPass = false;
  bool _submitting = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _selectRole(String role) {
    setState(() {
      _activeRole = role;
      _emailCtrl.clear();
      _passCtrl.clear();
      _errorMsg = null;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return;

    setState(() {
      _submitting = true;
      _errorMsg = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .login(email, pass, _activeRole);
      // Navigation handled by router redirect
    } on AuthException catch (e) {
      setState(() {
        _errorMsg = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background image with overlay
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.3),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: AppColors.ivory.withValues(alpha: 0.88),
            ),
          ),
          // Content
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 420 : double.infinity,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MedhaLogo(height: 90),
                      const SizedBox(height: 24),
                      _LoginCard(
                        activeRole: _activeRole,
                        onSelectRole: _selectRole,
                        emailCtrl: _emailCtrl,
                        passCtrl: _passCtrl,
                        showPass: _showPass,
                        onTogglePass: () =>
                            setState(() => _showPass = !_showPass),
                        submitting: _submitting,
                        errorMsg: _errorMsg,
                        onSubmit: _submit,
                      ),
                      const SizedBox(height: 16),
                      // "New to Medha? Register as a principal, teacher or student"
                      // — three separate links, each pre-selecting that role on
                      // the register screen (matches /register?role=X on the web).
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text('New to Medha? Register as a ',
                              style: GoogleFonts.manrope(fontSize: 13, color: AppColors.mutedForeground)),
                          _RegisterLink(label: 'principal', onTap: () => context.go('/register?role=principal')),
                          Text(', ', style: GoogleFonts.manrope(fontSize: 13, color: AppColors.mutedForeground)),
                          _RegisterLink(label: 'teacher', onTap: () => context.go('/register?role=teacher')),
                          Text(' or ', style: GoogleFonts.manrope(fontSize: 13, color: AppColors.mutedForeground)),
                          _RegisterLink(label: 'student', onTap: () => context.go('/register?role=student')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            'Student approved? ',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          _RegisterLink(
                            label: 'Activate your account',
                            onTap: () => context.go('/student/activate'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 380.ms)
        .slideY(begin: 0.05, end: 0, duration: 380.ms);
  }
}

/// The `.mlogin-link` style: gold, bold, no underline until hover.
class _RegisterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _RegisterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 13,
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final String activeRole;
  final void Function(String) onSelectRole;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool showPass;
  final VoidCallback onTogglePass;
  final bool submitting;
  final String? errorMsg;
  final VoidCallback onSubmit;

  const _LoginCard({
    required this.activeRole,
    required this.onSelectRole,
    required this.emailCtrl,
    required this.passCtrl,
    required this.showPass,
    required this.onTogglePass,
    required this.submitting,
    required this.errorMsg,
    required this.onSubmit,
  });

  static const _roles = [
    (id: 'student', label: 'Student'),
    (id: 'teacher', label: 'Teacher'),
    (id: 'principal', label: 'Principal'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Role tabs — active tab is AppColors.authDeep (a bespoke deep
          // terracotta only used on login/register), not the shared ink/
          // terracotta tokens used everywhere else in the app.
          Container(
            decoration: BoxDecoration(
              color: AppColors.parchment,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: _roles.map((r) {
                final active = r.id == activeRole;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelectRole(r.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? AppColors.authDeep : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: AppColors.authDeep.withValues(alpha: 0.22),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        r.label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active ? AppColors.ivory : AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Tagline (h1) — Fraunces, authDeep, matches copy.login.subtitle
          Text(
            'Your AI teaching companion',
            textAlign: TextAlign.center,
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.authDeep,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          // Always English on the real site regardless of locale — a
          // hardcoded literal in the JSX, not a translation miss.
          Text(
            'Sign in to your Medha account',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          const Center(child: LanguageToggle()),
          const SizedBox(height: 20),

          // Email
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: '${_capitalise(activeRole)} email',
              prefixIcon: const Icon(Icons.email_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 14),

          // Password
          TextField(
            controller: passCtrl,
            obscureText: !showPass,
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.mutedForeground,
                ),
                onPressed: onTogglePass,
              ),
            ),
            onSubmitted: (_) => onSubmit(),
          ),

          if (errorMsg != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.destructive.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                errorMsg!,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.destructive,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Submit button — authDeep background, "Log in" (not "Sign in").
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.authDeep,
                foregroundColor: AppColors.ivory,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: submitting ? null : onSubmit,
              child: submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.ivory,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Log in',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
