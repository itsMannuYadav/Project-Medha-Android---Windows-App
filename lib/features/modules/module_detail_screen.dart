import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/modules_api.dart';
import '../../core/models/module.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/pill_chip.dart';

/// Renders one saved module's artifacts. Shared by the Modules tab (tap a
/// saved kit) and Home (after a quiz/activity finishes generating) — one
/// rendering path for `content_json`, matching the exact QuizContent /
/// ActivityContent shapes the backend actually produces
/// (`shiksha_sathi/lib/api.ts`), not a guess.
class ModuleDetailScreen extends StatefulWidget {
  const ModuleDetailScreen({super.key, required this.moduleId});
  final String moduleId;

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  ModuleDetail? _module;
  bool _loading = true;
  String? _error;
  int? _givingFeedback;

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
      final m = await ModulesApi.detail(widget.moduleId);
      if (!mounted) return;
      setState(() {
        _module = m;
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

  Future<void> _giveFeedback(int rating) async {
    setState(() => _givingFeedback = rating);
    try {
      await ModulesApi.giveFeedback(widget.moduleId, rating: rating);
      await _load();
    } on ApiError catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _givingFeedback = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: Text(_module?.title ?? 'मॉड्यूल')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: MedhaColors.danger))))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        PillChip(label: _module!.gradeLabel, dense: true, background: MedhaColors.primaryWash, foreground: MedhaColors.primary),
                        const SizedBox(width: 6),
                        PillChip(label: _module!.subjectName, dense: true, background: MedhaColors.surface2, foreground: MedhaColors.inkSoft),
                      ],
                    ),
                    const SizedBox(height: 16),
                    for (final artifact in _module!.artifacts) ...[
                      _ArtifactCard(artifact: artifact),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('यह कैसा लगा?', style: TextStyle(fontSize: 13, color: MedhaColors.muted)),
                        const SizedBox(width: 12),
                        _FeedbackButton(
                          icon: Icons.thumb_up_outlined,
                          active: _module!.feedback?.rating == 1,
                          loading: _givingFeedback == 1,
                          onTap: () => _giveFeedback(1),
                        ),
                        const SizedBox(width: 8),
                        _FeedbackButton(
                          icon: Icons.thumb_down_outlined,
                          active: _module!.feedback?.rating == -1,
                          loading: _givingFeedback == -1,
                          onTap: () => _giveFeedback(-1),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({required this.icon, required this.active, required this.loading, required this.onTap});
  final IconData icon;
  final bool active;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: loading ? null : onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? MedhaColors.primaryWash : MedhaColors.surface2,
        ),
        child: loading
            ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, size: 17, color: active ? MedhaColors.primary : MedhaColors.inkSoft),
      ),
    );
  }
}

class _ArtifactCard extends StatelessWidget {
  const _ArtifactCard({required this.artifact});
  final ModuleArtifact artifact;

  @override
  Widget build(BuildContext context) {
    final content = artifact.contentJson;
    return MedhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MedhaIcon(_iconFor(artifact.artifactType), size: 16, color: MedhaColors.primary),
              const SizedBox(width: 8),
              Text(_titleFor(artifact.artifactType), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
            ],
          ),
          const SizedBox(height: 12),
          if (content == null)
            const Text('सामग्री उपलब्ध नहीं है।', style: TextStyle(color: MedhaColors.muted))
          else
            switch (artifact.artifactType) {
              'quiz' => _QuizBody(content: content),
              'activity' => _ActivityBody(content: content),
              _ => Text(content['text'] as String? ?? '', style: const TextStyle(fontSize: 13.5, color: MedhaColors.ink, height: 1.65)),
            },
        ],
      ),
    );
  }

  static String _iconFor(String type) => switch (type) { 'quiz' => 'help_circle', 'activity' => 'activity', _ => 'presentation' };
  static String _titleFor(String type) => switch (type) { 'quiz' => 'प्रश्नोत्तरी', 'activity' => 'कक्षा गतिविधि', _ => 'व्याख्या' };
}

class _QuizBody extends StatelessWidget {
  const _QuizBody({required this.content});
  final Map<String, dynamic> content;

  @override
  Widget build(BuildContext context) {
    final questions = (content['questions'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < questions.length; i++) ...[
          if (i > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
          _QuizQuestion(index: i + 1, data: questions[i] as Map<String, dynamic>),
        ],
      ],
    );
  }
}

class _QuizQuestion extends StatelessWidget {
  const _QuizQuestion({required this.index, required this.data});
  final int index;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final options = (data['options'] as List?)?.cast<String>() ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$index. ${data['q'] as String? ?? ''}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: MedhaColors.ink)),
        if (options.isNotEmpty) ...[
          const SizedBox(height: 6),
          for (final opt in options)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 2),
              child: Text('• $opt', style: const TextStyle(fontSize: 13, color: MedhaColors.inkSoft)),
            ),
        ],
        const SizedBox(height: 6),
        Text('उत्तर: ${data['answer'] as String? ?? ''}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.success)),
      ],
    );
  }
}

class _ActivityBody extends StatelessWidget {
  const _ActivityBody({required this.content});
  final Map<String, dynamic> content;

  @override
  Widget build(BuildContext context) {
    final materials = (content['materials'] as List?)?.cast<String>() ?? [];
    final steps = (content['steps'] as List?)?.cast<String>() ?? [];
    final groupSize = content['group_size'];
    final duration = content['duration_min'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content['title'] != null)
          Text(content['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            if (groupSize != null) PillChip(label: '$groupSize का समूह', dense: true),
            if (duration != null) PillChip(label: '$duration मिनट', dense: true),
          ],
        ),
        if (materials.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text('सामग्री', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: MedhaColors.muted)),
          const SizedBox(height: 4),
          Text(materials.join(', '), style: const TextStyle(fontSize: 13, color: MedhaColors.inkSoft)),
        ],
        if (steps.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text('चरण', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: MedhaColors.muted)),
          const SizedBox(height: 4),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${i + 1}. ${steps[i]}', style: const TextStyle(fontSize: 13, color: MedhaColors.ink, height: 1.5)),
            ),
        ],
        if (content['variation'] != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: MedhaColors.accentWash, borderRadius: BorderRadius.circular(MedhaRadii.sm)),
            child: Text('बदलाव: ${content['variation']}', style: const TextStyle(fontSize: 12.5, color: MedhaColors.accentInk)),
          ),
        ],
      ],
    );
  }
}
