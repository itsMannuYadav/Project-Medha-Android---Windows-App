import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/auth_api.dart';
import '../../core/auth/complete_login.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_icon.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({
    super.key,
    required this.email,
    required this.password,
    this.fullName,
    this.schoolName,
    this.employeeCode,
    this.initialRejection,
  });

  /// Kept in memory only (never persisted) so "check status" can retry a
  /// real login without asking the teacher to type their password again.
  final String email;
  final String password;
  final String? fullName;
  final String? schoolName;
  final String? employeeCode;
  final String? initialRejection;

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _checking = false;
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
    _rejectionReason = widget.initialRejection;
  }

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    try {
      await AuthApi.login(widget.email, widget.password);
      if (!mounted) return;
      await completeLogin(context, AppScope.of(context, listen: false));
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.isRejected) {
        setState(() => _rejectionReason = e.rejectionReason ?? 'कोई कारण नहीं दिया गया।');
      } else if (e.isPendingApproval) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('अभी भी स्वीकृति की प्रतीक्षा है।'), duration: Duration(seconds: 2)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), duration: const Duration(seconds: 2)));
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rejected = _rejectionReason != null;

    return Scaffold(
      backgroundColor: MedhaColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(shape: BoxShape.circle, color: rejected ? MedhaColors.dangerWash : MedhaColors.accentWash),
                child: Center(
                  child: MedhaIcon(rejected ? 'info_circle' : 'clock', size: 38, color: rejected ? MedhaColors.danger : MedhaColors.accentInk),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                rejected ? 'रजिस्ट्रेशन अस्वीकृत' : 'स्वीकृति की प्रतीक्षा है',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: MedhaColors.ink),
              ),
              const SizedBox(height: 10),
              Text(
                rejected
                    ? _rejectionReason!
                    : 'आपका रजिस्ट्रेशन ${widget.schoolName ?? "आपके विद्यालय"} के प्रधानाध्यापक के पास भेज दिया गया है। स्वीकृति मिलते ही आपको सूचित किया जाएगा।',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: MedhaColors.inkSoft, height: 1.7),
              ),
              const SizedBox(height: 26),
              if (widget.fullName != null || widget.schoolName != null || widget.employeeCode != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: MedhaColors.surface,
                    border: Border.all(color: MedhaColors.border),
                    borderRadius: BorderRadius.circular(MedhaRadii.lg),
                  ),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('जमा किया गया विवरण', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: MedhaColors.muted)),
                      ),
                      const SizedBox(height: 11),
                      if (widget.fullName != null) _DetailRow('नाम', widget.fullName!),
                      if (widget.schoolName != null) ...[const SizedBox(height: 9), _DetailRow('विद्यालय', widget.schoolName!)],
                      if (widget.employeeCode != null) ...[const SizedBox(height: 9), _DetailRow('शिक्षक कोड', widget.employeeCode!)],
                      const SizedBox(height: 9),
                      _DetailRow('ईमेल', widget.email),
                    ],
                  ),
                ),
              if (!rejected) ...[
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _checking ? null : _checkStatus,
                    icon: _checking
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MedhaColors.primary))
                        : const MedhaIcon('refresh', size: 16, color: MedhaColors.primary),
                    label: Text(_checking ? 'जांच रहे हैं...' : 'स्थिति जांचें', style: const TextStyle(color: MedhaColors.primary)),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text('लॉग इन स्क्रीन पर लौटें')),
                ),
              ],
              const SizedBox(height: 20),
              const Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 12, color: MedhaColors.muted),
                  children: [
                    TextSpan(text: 'सहायता चाहिए? '),
                    TextSpan(text: 'हेल्पलाइन [XXXX-XXX-XXX]', style: TextStyle(fontWeight: FontWeight.w600, color: MedhaColors.primary)),
                    TextSpan(text: ' पर संपर्क करें'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13.5, color: MedhaColors.muted)),
        Flexible(
          child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: MedhaColors.ink)),
        ),
      ],
    );
  }
}
