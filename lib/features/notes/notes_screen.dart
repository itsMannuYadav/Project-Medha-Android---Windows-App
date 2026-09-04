import 'package:flutter/material.dart';

import '../../core/api/notes_api.dart';
import '../../core/models/notes.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/pill_chip.dart';

/// One chapter's teacher-curated revision note. Read-only -- authoring
/// happens on the web console.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.chapterId, required this.chapterTitle});
  final String chapterId;
  final String chapterTitle;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  ChapterNote? _note;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final note = await NotesApi.get(widget.chapterId);
      if (!mounted) return;
      setState(() {
        _note = note;
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
        title: const Text('नोट्स'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : _note == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MedhaIcon('book', size: 28, color: MedhaColors.muted),
                        const SizedBox(height: 10),
                        Text('${widget.chapterTitle} के नोट्स अभी तैयार नहीं हैं', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: MedhaColors.ink)),
                        const SizedBox(height: 6),
                        const Text('आपके शिक्षक ने अभी इस अध्याय के लिए नोट्स नहीं जोड़े हैं।', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: MedhaColors.muted)),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(widget.chapterTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
                    const SizedBox(height: 6),
                    Text(_note!.summary, style: const TextStyle(fontSize: 13.5, color: MedhaColors.inkSoft, height: 1.6)),
                    if (_note!.keyPoints.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      MedhaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('मुख्य बिंदु', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MedhaColors.muted)),
                            const SizedBox(height: 10),
                            for (final point in _note!.keyPoints)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(padding: EdgeInsets.only(top: 6), child: SizedBox(width: 6, height: 6, child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: MedhaColors.primary)))),
                                    const SizedBox(width: 9),
                                    Expanded(child: Text(point, style: const TextStyle(fontSize: 13.5, color: MedhaColors.ink, height: 1.5))),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (_note!.importantTerms.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      MedhaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('महत्वपूर्ण शब्द', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MedhaColors.muted)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: _note!.importantTerms
                                  .map((t) => PillChip(label: t, dense: true, background: MedhaColors.accentWash, foreground: MedhaColors.accentInk))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
