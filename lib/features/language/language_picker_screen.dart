import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_icon.dart';

/// Lets a teacher choose English / Hindi / Hinglish — each option is shown
/// *as itself* (a sample sentence in that language) rather than just named,
/// so someone can recognize what's comfortable without needing to already
/// read a description in a language they're unsure of.
///
/// Used both as the first-run screen (pushed as the app's very first route)
/// and as a destination from Profile settings — [onDone] controls what
/// happens next in each case.
class LanguagePickerScreen extends StatefulWidget {
  const LanguagePickerScreen({super.key, required this.onDone, this.showBack = false});

  final ValueChanged<AppLanguage> onDone;
  final bool showBack;

  @override
  State<LanguagePickerScreen> createState() => _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends State<LanguagePickerScreen> {
  late AppLanguage _selected;

  static const _samples = {
    AppLanguage.english: 'Which topic are we teaching today?',
    AppLanguage.hindi: 'आज कौन सा विषय पढ़ाना है?',
    AppLanguage.hinglish: 'Aaj kaunsa topic padhayenge?',
  };

  @override
  void initState() {
    super.initState();
    _selected = AppScope.of(context, listen: false).language;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.showBack)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: IconButton(
                    icon: const MedhaIcon('chevron_left', color: MedhaColors.ink),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              )
            else
              const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    const MedhaIcon('globe', size: 46, color: MedhaColors.primary),
                    const SizedBox(height: 10),
                    const Text('भाषा चुनें', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
                    const SizedBox(height: 2),
                    const Text('Choose your language', style: TextStyle(fontSize: 14, color: MedhaColors.inkSoft)),
                    const SizedBox(height: 9),
                    const Text(
                      'जो भाषा आपको सबसे सहज लगे, वही चुनें — बाद में कभी भी बदल सकते हैं',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: MedhaColors.muted, height: 1.6),
                    ),
                    const SizedBox(height: 22),
                    for (final lang in AppLanguage.values) ...[
                      _LanguageCard(
                        language: lang,
                        sample: _samples[lang]!,
                        selected: _selected == lang,
                        onTap: () => setState(() => _selected = lang),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => widget.onDone(_selected),
                      child: const Text('जारी रखें'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'प्रोफ़ाइल से कभी भी बदल सकते हैं · change anytime from Profile',
                    style: TextStyle(fontSize: 11.5, color: MedhaColors.muted),
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

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.language, required this.sample, required this.selected, required this.onTap});

  final AppLanguage language;
  final String sample;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(MedhaRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(MedhaRadii.lg),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? MedhaColors.primaryWash : MedhaColors.surface,
            borderRadius: BorderRadius.circular(MedhaRadii.lg),
            border: Border.all(color: selected ? MedhaColors.primary : MedhaColors.borderStrong, width: 1.75),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? MedhaColors.primary : MedhaColors.borderStrong, width: 2),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: MedhaColors.primary),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(language.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
                    const SizedBox(height: 5),
                    Text('"$sample"', style: const TextStyle(fontSize: 13, color: MedhaColors.inkSoft, height: 1.5)),
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
