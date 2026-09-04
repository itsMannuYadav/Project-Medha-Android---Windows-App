import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/google_auth_api.dart';
import '../../core/auth/complete_login.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/google_logo.dart';
import '../../core/widgets/medha_icon.dart';
import '../language/language_picker_screen.dart';
import 'pending_approval_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _openLanguagePicker() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LanguagePickerScreen(
          showBack: true,
          onDone: (lang) {
            AppScope.of(context, listen: false).language = lang;
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'ईमेल और पासवर्ड दोनों भरें।');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthApi.login(email, password);
      if (!mounted) return;
      await completeLogin(context, AppScope.of(context, listen: false));
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.isPendingApproval || e.isRejected) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PendingApprovalScreen(email: email, password: password, initialRejection: e.isRejected ? e.rejectionReason : null),
          ),
        );
        return;
      }
      // Only a genuine 401 from /auth/login means "wrong credentials" --
      // anything else (no connection, timeout, 5xx...) has its own honest
      // message from ApiError and must not be relabelled as a bad password.
      setState(() => _error = e.statusCode == 401 ? 'गलत ईमेल या पासवर्ड।' : e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await GoogleAuthApi.signIn();
      if (!mounted) return;
      if (result.cancelled) return;
      if (result.notRegistered) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RegisterScreen(
              prefillFullName: result.fullName,
              prefillEmail: result.email,
              googleSub: result.googleSub,
            ),
          ),
        );
        return;
      }
      await completeLogin(context, AppScope.of(context, listen: false));
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);

    return Scaffold(
      backgroundColor: MedhaColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 18, 20, 0),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(MedhaRadii.pill),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(MedhaRadii.pill),
                    onTap: _openLanguagePicker,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
                      decoration: BoxDecoration(
                        color: MedhaColors.surface,
                        border: Border.all(color: MedhaColors.borderStrong),
                        borderRadius: BorderRadius.circular(MedhaRadii.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const MedhaIcon('globe', size: 14, color: MedhaColors.inkSoft),
                          const SizedBox(width: 6),
                          Text(appState.language.label,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
                          const SizedBox(width: 4),
                          const MedhaIcon('chevron_down', size: 11, color: MedhaColors.muted),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: MedhaColors.primaryWash),
                      child: CustomPaint(painter: _CrestPainter()),
                    ),
                    const SizedBox(height: 12),
                    const Text('बिहार सरकार · शिक्षा विभाग',
                        style: TextStyle(fontSize: 11, letterSpacing: 0.8, color: MedhaColors.muted)),
                    const SizedBox(height: 4),
                    const Text('मेधा', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
                    const SizedBox(height: 3),
                    const Text('पढ़ाने में आपकी साथी', style: TextStyle(fontSize: 13.5, color: MedhaColors.inkSoft)),
                    const SizedBox(height: 30),
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(color: MedhaColors.dangerWash, borderRadius: BorderRadius.circular(MedhaRadii.md)),
                        child: Text(_error!, style: const TextStyle(fontSize: 12.5, color: MedhaColors.danger)),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _Label('ईमेल'),
                    const SizedBox(height: 6),
                    TextField(controller: _email, keyboardType: TextInputType.emailAddress, enabled: !_busy),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Label('पासवर्ड'),
                        const Text('पासवर्ड भूल गए?', style: TextStyle(fontSize: 12, color: MedhaColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _password,
                      obscureText: _obscure,
                      enabled: !_busy,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: MedhaIcon(_obscure ? 'eye' : 'eye_off', size: 18, color: MedhaColors.muted),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('लॉग इन करें'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('या', style: TextStyle(fontSize: 12, color: MedhaColors.muted))),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _continueWithGoogle,
                        icon: const GoogleLogo(),
                        label: const Text('Google से जारी रखें'),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('खाता नहीं है? ', style: TextStyle(fontSize: 13.5, color: MedhaColors.inkSoft)),
                        GestureDetector(
                          onTap: _busy ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: const Text('रजिस्टर करें',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: MedhaColors.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              decoration: const BoxDecoration(
                color: MedhaColors.surface2,
                border: Border(top: BorderSide(color: MedhaColors.border)),
              ),
              child: const Row(
                children: [
                  MedhaIcon('shield_check', size: 16, color: MedhaColors.muted),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'बिहार सरकार, शिक्षा विभाग की एक आधिकारिक पहल · जिला-स्तरीय पायलट',
                      style: TextStyle(fontSize: 11, color: MedhaColors.muted, height: 1.5),
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

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
    );
  }
}

/// The placeholder institutional crest on the login screen — an abstract
/// open-book mark, not the real Bihar Govt./Education Dept. seal. Swap for
/// the approved emblem asset when the department provides one.
class _CrestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = MedhaColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final c = size.width / 2;

    final book = Path()
      ..moveTo(c - 11, c + 4)
      ..lineTo(c - 11, c - 7)
      ..lineTo(c, c - 12)
      ..lineTo(c + 11, c - 7)
      ..lineTo(c + 11, c + 4);
    canvas.drawPath(book, stroke);

    final pages = Path()
      ..moveTo(c - 6, c - 1.5)
      ..cubicTo(c - 6, c + 6.5, c - 3, c + 8, c, c + 8)
      ..cubicTo(c + 3, c + 8, c + 6, c + 6.5, c + 6, c - 1.5);
    canvas.drawPath(pages, stroke);

    canvas.drawCircle(Offset(c + 11, c - 11), 2.1, Paint()..color = MedhaColors.accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
