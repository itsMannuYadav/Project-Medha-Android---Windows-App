import 'package:flutter/material.dart';

import '../../core/api/generation_api.dart';
import '../../core/api/speech_api.dart';
import '../../core/models/generation.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/widgets/medha_card.dart';

class GenerationDetailScreen extends StatefulWidget {
  const GenerationDetailScreen({super.key, required this.initial});
  final GenerationDetail initial;

  @override
  State<GenerationDetailScreen> createState() => _GenerationDetailScreenState();
}

class _GenerationDetailScreenState extends State<GenerationDetailScreen> {
  late GenerationDetail _detail;
  bool _busy = false;
  Map<String, dynamic>? _answerKey;

  @override
  void initState() {
    super.initState();
    _detail = widget.initial;
  }

  Future<void> _toggleFavorite() async {
    setState(() => _busy = true);
    try {
      final updated = await GenerationApi.patch(_detail.id, isFavorite: !_detail.isFavorite);
      if (mounted) setState(() => _detail = updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('अपडेट नहीं हो सका।')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('हटाएं?'),
        content: const Text('यह सामग्री स्थायी रूप से हट जाएगी।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('रद्द')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('हटाएं')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await GenerationApi.delete(_detail.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('हटाया नहीं जा सका।')));
      }
    }
  }

  Future<void> _export(String fmt) async {
    setState(() => _busy = true);
    try {
      await GenerationApi.exportAndShare(_detail.id, fmt);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('एक्सपोर्ट नहीं हो सका।')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _regenerate() async {
    setState(() => _busy = true);
    String? newId;
    await GenerationApi.regenerate(
      id: _detail.id,
      onToken: (_) {},
      onDone: (data) => newId = data['generation_id'] as String?,
      onError: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          setState(() => _busy = false);
        }
      },
    );
    if (newId == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    try {
      final detail = await GenerationApi.get(newId!);
      if (mounted) setState(() {
        _detail = detail;
        _answerKey = null;
        _busy = false;
      });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadAnswerKey() async {
    setState(() => _busy = true);
    try {
      final key = await GenerationApi.answerKey(_detail.id, contentJson: _detail.contentJson);
      if (mounted) setState(() => _answerKey = key);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('उत्तर कुंजी नहीं बनी।')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _feedback(int rating) async {
    try {
      await GenerationApi.feedback(_detail.id, rating: rating);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('धन्यवाद!')));
    } catch (_) {}
  }

  Future<void> _speak() async {
    final text = _detail.title;
    final summary = _detail.contentJson?['summary'] as String?;
    await SpeechApi.speak([text, if (summary != null) summary].join('. '), language: 'hi-IN');
  }

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (_detail.gradeLabel != null) _detail.gradeLabel!,
      if (_detail.subjectName != null) _detail.subjectName!,
      if (_detail.chapterTitle != null) _detail.chapterTitle!,
    ].join(' · ');

    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(
        title: Text(generationTypeLabel(_detail.type)),
        actions: [
          IconButton(
            onPressed: _busy ? null : _toggleFavorite,
            icon: Icon(
              _detail.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _detail.isFavorite ? MedhaColors.accent : MedhaColors.inkSoft,
            ),
          ),
          IconButton(
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline_rounded, color: MedhaColors.danger),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_detail.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(meta, style: const TextStyle(fontSize: 12, color: MedhaColors.muted)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(onPressed: _busy ? null : () => _export('pdf'), icon: const Icon(Icons.picture_as_pdf, size: 16), label: const Text('PDF')),
              OutlinedButton.icon(onPressed: _busy ? null : () => _export('docx'), icon: const Icon(Icons.description_outlined, size: 16), label: const Text('Word')),
              if (_detail.type == 'presentation')
                OutlinedButton.icon(onPressed: _busy ? null : () => _export('pptx'), icon: const Icon(Icons.slideshow_outlined, size: 16), label: const Text('PPTX')),
              OutlinedButton.icon(onPressed: _busy ? null : _regenerate, icon: const Icon(Icons.refresh, size: 16), label: const Text('फिर बनाएं')),
              if (_detail.type == 'question_paper')
                OutlinedButton.icon(onPressed: _busy ? null : _loadAnswerKey, icon: const Icon(Icons.key_outlined, size: 16), label: const Text('उत्तर कुंजी')),
              OutlinedButton.icon(onPressed: _busy ? null : _speak, icon: const Icon(Icons.volume_up_outlined, size: 16), label: const Text('सुनें')),
              IconButton(onPressed: () => _feedback(1), icon: const Icon(Icons.thumb_up_alt_outlined, size: 18, color: MedhaColors.success)),
              IconButton(onPressed: () => _feedback(-1), icon: const Icon(Icons.thumb_down_alt_outlined, size: 18, color: MedhaColors.danger)),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(color: MedhaColors.primary),
          ],
          if (_detail.status == 'failed') ...[
            const SizedBox(height: 12),
            Text(_detail.errorMessage ?? 'जनरेशन विफल', style: const TextStyle(color: MedhaColors.danger)),
          ],
          const SizedBox(height: 16),
          ..._contentBlocks(),
          if (_answerKey != null) ...[
            const SizedBox(height: 16),
            const Text('उत्तर कुंजी', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ..._answerKeyBlocks(_answerKey!),
          ],
        ],
      ),
    );
  }

  List<Widget> _answerKeyBlocks(Map<String, dynamic> key) {
    final sections = (key['sections'] as List? ?? []).cast<dynamic>();
    return [
      for (final s in sections)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MedhaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${(s as Map)['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                for (final a in ((s['answers'] as List?) ?? []))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('${(a as Map)['number']}. ${(a)['answer'] ?? ''}\n${(a)['solution'] ?? ''}', style: const TextStyle(fontSize: 12.5, height: 1.4)),
                  ),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _contentBlocks() {
    final c = _detail.contentJson;
    if (c == null) {
      return [const Text('कोई सामग्री नहीं', style: TextStyle(color: MedhaColors.muted))];
    }

    switch (_detail.type) {
      case 'quiz':
        return _quizBlocks(c);
      case 'lesson_plan':
        return _lessonPlanBlocks(c);
      case 'notes':
        return _notesBlocks(c);
      case 'presentation':
        return _presentationBlocks(c);
      case 'question_paper':
        return _questionPaperBlocks(c);
      default:
        return [MedhaCard(child: Text(c.toString(), style: const TextStyle(fontSize: 13, height: 1.45)))];
    }
  }

  List<Widget> _quizBlocks(Map<String, dynamic> c) {
    final questions = (c['questions'] as List? ?? []).cast<dynamic>();
    return [
      for (var i = 0; i < questions.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MedhaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('प्रश्न ${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MedhaColors.primary)),
                const SizedBox(height: 6),
                Text('${(questions[i] as Map)['q'] ?? ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
                if ((questions[i] as Map)['options'] is List) ...[
                  const SizedBox(height: 8),
                  for (final o in ((questions[i] as Map)['options'] as List))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('• $o', style: const TextStyle(fontSize: 13, color: MedhaColors.inkSoft)),
                    ),
                ],
                const SizedBox(height: 8),
                Text('उत्तर: ${(questions[i] as Map)['answer'] ?? ''}', style: const TextStyle(fontSize: 12.5, color: MedhaColors.success, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _lessonPlanBlocks(Map<String, dynamic> c) {
    final periods = (c['periods_detail'] as List? ?? []).cast<dynamic>();
    return [
      if (c['topic'] != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('${c['topic']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      for (final p in periods)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MedhaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('पीरियड ${(p as Map)['period_no']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MedhaColors.primary)),
                const SizedBox(height: 6),
                Text('${p['concept'] ?? ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('${p['teacher_learning_process'] ?? ''}', style: const TextStyle(fontSize: 13, height: 1.45, color: MedhaColors.inkSoft)),
              ],
            ),
          ),
        ),
      if (c['homework'] != null)
        MedhaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('गृहकार्य', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MedhaColors.accentInk)),
              const SizedBox(height: 6),
              Text('${c['homework']}', style: const TextStyle(fontSize: 13, height: 1.45)),
            ],
          ),
        ),
    ];
  }

  List<Widget> _notesBlocks(Map<String, dynamic> c) {
    final sections = (c['sections'] as List? ?? []).cast<dynamic>();
    return [
      if (c['summary'] != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MedhaCard(
            child: Text('${c['summary']}', style: const TextStyle(fontSize: 13.5, height: 1.45)),
          ),
        ),
      for (final s in sections)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MedhaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${(s as Map)['heading'] ?? ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('${s['body_md'] ?? ''}', style: const TextStyle(fontSize: 13, height: 1.45)),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _presentationBlocks(Map<String, dynamic> c) {
    final slides = (c['slides'] as List? ?? []).cast<dynamic>();
    return [
      if (c['title'] != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('${c['title']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      for (var i = 0; i < slides.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MedhaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('स्लाइड ${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MedhaColors.primary)),
                const SizedBox(height: 6),
                Text('${(slides[i] as Map)['heading'] ?? ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                if ((slides[i] as Map)['bullets'] is List) ...[
                  const SizedBox(height: 8),
                  for (final b in ((slides[i] as Map)['bullets'] as List))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('• $b', style: const TextStyle(fontSize: 13, height: 1.4)),
                    ),
                ],
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _questionPaperBlocks(Map<String, dynamic> c) {
    final sections = (c['sections'] as List? ?? []).cast<dynamic>();
    return [
      Text(
        'कुल अंक: ${c['total_marks'] ?? '—'} · समय: ${c['duration_min'] ?? '—'} मिनट',
        style: const TextStyle(fontSize: 12.5, color: MedhaColors.muted),
      ),
      const SizedBox(height: 12),
      for (final s in sections)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MedhaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${(s as Map)['name'] ?? ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                if (s['instructions'] != null) ...[
                  const SizedBox(height: 4),
                  Text('${s['instructions']}', style: const TextStyle(fontSize: 12, color: MedhaColors.muted)),
                ],
                const SizedBox(height: 10),
                for (var i = 0; i < ((s['questions'] as List?) ?? []).length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${i + 1}. ${((s['questions'] as List)[i] as Map)['text'] ?? ''}  (${((s['questions'] as List)[i] as Map)['marks'] ?? ''} अंक)',
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
              ],
            ),
          ),
        ),
    ];
  }
}
