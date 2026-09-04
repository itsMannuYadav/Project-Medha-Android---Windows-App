import 'package:flutter/material.dart';

import '../../core/api/practice_api.dart';
import '../../core/models/practice.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';

/// Practice questions for one chapter -- teacher/principal-curated, tap an
/// option to check it (mcq) or tap to reveal the answer (short/true-false).
/// Read-only -- authoring happens on the web console.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.chapterId, required this.chapterTitle});
  final String chapterId;
  final String chapterTitle;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  List<PracticeQuestion> _questions = [];
  bool _loading = true;
  // per-question: the picked option index (mcq) or `true` once revealed
  final Map<String, int> _picked = {};
  final Set<String> _revealed = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final questions = await PracticeApi.list(widget.chapterId);
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(
        leading: IconButton(icon: const MedhaIcon('chevron_left', color: MedhaColors.ink), onPressed: () => Navigator.of(context).pop()),
        title: const Text('अभ्यास प्रश्न'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : _questions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MedhaIcon('file_question', size: 28, color: MedhaColors.muted),
                        const SizedBox(height: 10),
                        Text('${widget.chapterTitle} के लिए अभ्यास प्रश्न अभी नहीं हैं', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: MedhaColors.ink)),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _questions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final q = _questions[i];
                    final hasOptions = q.options != null && q.options!.isNotEmpty;
                    final chosen = _picked[q.id];
                    final revealed = _revealed.contains(q.id);
                    final correctIndex = hasOptions ? q.options!.indexOf(q.answer) : -1;

                    return MedhaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${i + 1}. ${q.question}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: MedhaColors.ink, height: 1.5)),
                          const SizedBox(height: 11),
                          if (hasOptions)
                            for (var oi = 0; oi < q.options!.length; oi++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: _OptionRow(
                                  label: q.options![oi],
                                  chosen: chosen == oi,
                                  correct: chosen != null && oi == correctIndex,
                                  wrong: chosen != null && chosen == oi && oi != correctIndex,
                                  onTap: chosen == null ? () => setState(() => _picked[q.id] = oi) : null,
                                ),
                              )
                          else if (revealed)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(color: MedhaColors.surface2, borderRadius: BorderRadius.circular(MedhaRadii.md)),
                              child: Text(q.answer, style: const TextStyle(fontSize: 13, color: MedhaColors.inkSoft)),
                            )
                          else
                            OutlinedButton(
                              onPressed: () => setState(() => _revealed.add(q.id)),
                              child: const Text('उत्तर देखें'),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.label, required this.chosen, required this.correct, required this.wrong, this.onTap});
  final String label;
  final bool chosen;
  final bool correct;
  final bool wrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = correct ? MedhaColors.successWash : wrong ? MedhaColors.dangerWash : chosen ? MedhaColors.primaryWash : MedhaColors.surface;
    final border = correct ? MedhaColors.success : wrong ? MedhaColors.danger : MedhaColors.borderStrong;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MedhaRadii.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 1.5), borderRadius: BorderRadius.circular(MedhaRadii.md)),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: MedhaColors.ink))),
            if (correct) const MedhaIcon('shield_check', size: 15, color: MedhaColors.success),
          ],
        ),
      ),
    );
  }
}
