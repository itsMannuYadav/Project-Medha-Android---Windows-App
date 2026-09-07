import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/generation_api.dart';
import '../../core/api/profile_api.dart';
import '../../core/api/reference_api.dart';
import '../../core/models/generation.dart';
import '../../core/models/profile.dart';
import '../../core/models/reference.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/widgets/pill_chip.dart';
import 'generation_detail_screen.dart';

/// Create flow for one generation type (quiz / lesson_plan / …).
class CreateGenerationScreen extends StatefulWidget {
  const CreateGenerationScreen({super.key, required this.type});
  final String type;

  @override
  State<CreateGenerationScreen> createState() => _CreateGenerationScreenState();
}

class _CreateGenerationScreenState extends State<CreateGenerationScreen> {
  List<ProfileSubject> _subjects = [];
  ProfileSubject? _selected;
  List<ChapterRef> _chapters = [];
  ChapterRef? _chapter;
  late Map<String, dynamic> _params;
  final _focus = TextEditingController();

  bool _loading = true;
  bool _generating = false;
  String? _error;
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _params = Map<String, dynamic>.from(defaultParamsFor(widget.type));
    _load();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = await ProfileApi.get();
      if (!mounted) return;
      setState(() {
        _subjects = profile.subjects;
        _selected = profile.subjects.isEmpty ? null : profile.subjects.first;
        _loading = false;
      });
      await _loadChapters();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadChapters() async {
    final s = _selected;
    if (s == null) return;
    try {
      final chapters = await ReferenceApi.chapters(gradeId: s.gradeId, subjectId: s.subjectId);
      if (!mounted) return;
      setState(() {
        _chapters = chapters;
        _chapter = chapters.isEmpty ? null : chapters.first;
      });
    } on ApiError catch (_) {
      if (mounted) setState(() {
        _chapters = [];
        _chapter = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_selected == null) {
      setState(() => _error = 'कक्षा व विषय चुनें।');
      return;
    }
    if (_focus.text.trim().isNotEmpty) {
      _params['focus'] = _focus.text.trim();
    }
    setState(() {
      _generating = true;
      _error = null;
      _statusText = 'तैयार हो रहा है…';
    });

    String? generationId;
    await GenerationApi.generate(
      type: widget.type,
      gradeId: _selected!.gradeId,
      subjectId: _selected!.subjectId,
      chapterId: _chapter?.id,
      params: _params,
      onToken: (t) {
        if (!mounted) return;
        setState(() => _statusText = t.isEmpty ? 'लिख रहा है…' : 'लिख रहा है…');
      },
      onProgress: (stage, done, total) {
        if (!mounted) return;
        setState(() => _statusText = '$stage ($done/$total)');
      },
      onDone: (data) {
        generationId = data['generation_id'] as String?;
      },
      onError: (msg) {
        if (mounted) {
          setState(() {
            _error = msg;
            _generating = false;
          });
        }
      },
    );

    if (!mounted) return;
    if (generationId == null) {
      setState(() {
        _generating = false;
        _error ??= 'जनरेशन पूरा नहीं हुआ।';
      });
      return;
    }

    setState(() => _statusText = 'लोड हो रहा है…');
    try {
      final detail = await GenerationApi.get(generationId!);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GenerationDetailScreen(initial: detail)),
      );
    } on ApiError catch (e) {
      setState(() {
        _error = e.message;
        _generating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = generationTypeLabel(widget.type);
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : _generating
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: MedhaColors.primary),
                      const SizedBox(height: 16),
                      Text(_statusText, style: const TextStyle(color: MedhaColors.muted)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('कक्षा व विषय', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
                      const SizedBox(height: 8),
                      if (_subjects.isEmpty)
                        const Text('प्रोफ़ाइल में कोई विषय नहीं जुड़ा।', style: TextStyle(color: MedhaColors.muted))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _subjects
                              .map((s) => PillChip(
                                    label: '${s.subjectName} · ${s.gradeLabel}',
                                    selected: s.subjectId == _selected?.subjectId && s.gradeId == _selected?.gradeId,
                                    onTap: () async {
                                      setState(() => _selected = s);
                                      await _loadChapters();
                                    },
                                  ))
                              .toList(),
                        ),
                      if (_chapters.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const Text('अध्याय', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _chapters
                              .map((c) => PillChip(
                                    label: '${c.chapterNumber}. ${c.title}',
                                    selected: c.id == _chapter?.id,
                                    onTap: () => setState(() => _chapter = c),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 18),
                      ..._paramFields(),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(_error!, style: const TextStyle(fontSize: 12.5, color: MedhaColors.danger)),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: Text('$title बनाएं'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _paramFields() {
    final type = widget.type;
    final widgets = <Widget>[];

    if (type == 'quiz' || type == 'lesson_plan' || type == 'question_paper' || type == 'presentation') {
      widgets.addAll([
        const Text('फोकस (वैकल्पिक)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
        const SizedBox(height: 6),
        TextField(controller: _focus, decoration: const InputDecoration(hintText: 'जैसे मुख्य अवधारणाएँ')),
        const SizedBox(height: 14),
      ]);
    }

    if (type == 'quiz') {
      widgets.addAll([
        const Text('प्रश्नों की संख्या', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
        const SizedBox(height: 6),
        Slider(
          value: (_params['question_count'] as int).toDouble(),
          min: 5,
          max: 20,
          divisions: 15,
          label: '${_params['question_count']}',
          activeColor: MedhaColors.primary,
          onChanged: (v) => setState(() => _params['question_count'] = v.round()),
        ),
        const SizedBox(height: 8),
        const Text('कठिनाई', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['easy', 'medium', 'hard', 'mixed'].map((d) {
            final labels = {'easy': 'आसान', 'medium': 'मध्यम', 'hard': 'कठिन', 'mixed': 'मिश्रित'};
            return PillChip(
              label: labels[d]!,
              selected: _params['difficulty'] == d,
              onTap: () => setState(() => _params['difficulty'] = d),
            );
          }).toList(),
        ),
      ]);
    } else if (type == 'lesson_plan') {
      widgets.addAll([
        const Text('अवधि (पीरियड)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
        Slider(
          value: (_params['periods'] as int).toDouble(),
          min: 1,
          max: 6,
          divisions: 5,
          label: '${_params['periods']}',
          activeColor: MedhaColors.primary,
          onChanged: (v) => setState(() => _params['periods'] = v.round()),
        ),
      ]);
    } else if (type == 'notes') {
      widgets.addAll([
        const Text('गहराई', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['summary', 'standard', 'detailed'].map((d) {
            final labels = {'summary': 'सारांश', 'standard': 'मानक', 'detailed': 'विस्तृत'};
            return PillChip(
              label: labels[d]!,
              selected: _params['depth'] == d,
              onTap: () => setState(() => _params['depth'] = d),
            );
          }).toList(),
        ),
      ]);
    } else if (type == 'presentation') {
      widgets.addAll([
        const Text('स्लाइड संख्या', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
        Slider(
          value: (_params['slide_count'] as int).toDouble(),
          min: 4,
          max: 16,
          divisions: 12,
          label: '${_params['slide_count']}',
          activeColor: MedhaColors.primary,
          onChanged: (v) => setState(() => _params['slide_count'] = v.round()),
        ),
      ]);
    } else if (type == 'question_paper') {
      widgets.addAll([
        const Text('कठिनाई', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['easy', 'medium', 'hard', 'mixed'].map((d) {
            final labels = {'easy': 'आसान', 'medium': 'मध्यम', 'hard': 'कठिन', 'mixed': 'मिश्रित'};
            return PillChip(
              label: labels[d]!,
              selected: _params['difficulty'] == d,
              onTap: () => setState(() => _params['difficulty'] = d),
            );
          }).toList(),
        ),
      ]);
    }

    return widgets;
  }
}
