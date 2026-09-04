import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/profile_api.dart';
import '../../core/models/profile.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/widgets/avatar_initials.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/pill_chip.dart';
import '../auth/login_screen.dart';
import '../language/language_picker_screen.dart';

const _backendLanguageFor = {
  AppLanguage.english: 'en',
  AppLanguage.hindi: 'hi-BiharBoli',
  AppLanguage.hinglish: 'hinglish',
};

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
  bool _loading = true;
  String? _error;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await ProfileApi.get();
      if (!mounted) return;
      setState(() {
        _profile = profile;
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

  Future<void> _openLanguagePicker() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LanguagePickerScreen(
          showBack: true,
          onDone: (lang) async {
            AppScope.of(context, listen: false).language = lang;
            Navigator.of(context).pop();
            try {
              await ProfileApi.update(preferredLanguage: _backendLanguageFor[lang]);
              await _load();
            } on ApiError catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
            }
          },
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthApi.logout();
    if (!mounted) return;
    AppScope.of(context, listen: false).setSignedOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).language;
    final profile = _profile;
    final me = AppScope.of(context).teacher;
    final role = me?.role ?? 'teacher';
    const roleLabels = {'teacher': 'शिक्षक', 'principal': 'प्रधानाध्यापक', 'student': 'छात्र', 'admin': 'व्यवस्थापक'};

    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('प्रोफ़ाइल')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: MedhaColors.danger))))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    MedhaCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          AvatarInitials(initials: profile!.fullName.isEmpty ? '?' : profile.fullName.substring(0, 1), size: 64),
                          const SizedBox(height: 12),
                          Text(profile.fullName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PillChip(label: roleLabels[role] ?? role, dense: true, background: MedhaColors.primaryWash, foreground: MedhaColors.primary),
                              if (role == 'student' && me?.gradeId != null) ...[
                                const SizedBox(width: 6),
                                Text('रोल नं. ${me?.rollNumber ?? '—'}', style: const TextStyle(fontSize: 12, color: MedhaColors.muted)),
                              ],
                            ],
                          ),
                          if (profile.school != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              '${profile.school!.name}\n${profile.school!.districtName} ज़िला',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12.5, color: MedhaColors.inkSoft, height: 1.6),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (role == 'teacher') ...[
                      const SizedBox(height: 16),
                      MedhaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('पढ़ाई की जानकारी', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MedhaColors.muted)),
                            const SizedBox(height: 11),
                            if (profile.subjects.isEmpty)
                              const Text('कोई विषय नहीं जोड़ा गया', style: TextStyle(fontSize: 13, color: MedhaColors.muted))
                            else
                              Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: profile.subjects
                                    .map((s) => PillChip(
                                          label: '${s.subjectName} · ${s.gradeLabel}',
                                          dense: true,
                                          background: s.isPrimary ? MedhaColors.primaryWash : MedhaColors.accentWash,
                                          foreground: s.isPrimary ? MedhaColors.primary : MedhaColors.accentInk,
                                        ))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    MedhaCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          _InfoRow(icon: 'mail', text: profile.email),
                          if (profile.phoneNumber != null) ...[
                            const Divider(height: 1, indent: 14, endIndent: 14),
                            _InfoRow(icon: 'phone', text: profile.phoneNumber!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    MedhaCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _openLanguagePicker,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                              child: Row(
                                children: [
                                  const MedhaIcon('globe', size: 18, color: MedhaColors.inkSoft),
                                  const SizedBox(width: 12),
                                  const Expanded(child: Text('भाषा', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: MedhaColors.ink))),
                                  Text(language.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.primary)),
                                  const SizedBox(width: 6),
                                  const MedhaIcon('chevron_right', size: 15, color: MedhaColors.muted),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1, indent: 14, endIndent: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            child: Row(
                              children: [
                                const MedhaIcon('bell', size: 18, color: MedhaColors.inkSoft),
                                const SizedBox(width: 12),
                                const Expanded(child: Text('सूचनाएं', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: MedhaColors.ink))),
                                Switch(value: _notifications, activeThumbColor: MedhaColors.primary, onChanged: (v) => setState(() => _notifications = v)),
                              ],
                            ),
                          ),
                          const Divider(height: 1, indent: 14, endIndent: 14),
                          const _InfoRow(icon: 'help_circle', text: 'सहायता व समर्थन', trailingChevron: true),
                          const Divider(height: 1, indent: 14, endIndent: 14),
                          const _InfoRow(icon: 'info_circle', text: 'मेधा के बारे में', trailingChevron: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const MedhaIcon('logout', size: 16, color: MedhaColors.danger),
                        label: const Text('लॉग आउट'),
                        style: OutlinedButton.styleFrom(foregroundColor: MedhaColors.danger, side: const BorderSide(color: MedhaColors.danger, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.trailingChevron = false});
  final String icon;
  final String text;
  final bool trailingChevron;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          MedhaIcon(icon, size: 18, color: MedhaColors.inkSoft),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: MedhaColors.ink))),
          if (trailingChevron) const MedhaIcon('chevron_right', size: 15, color: MedhaColors.muted),
        ],
      ),
    );
  }
}
