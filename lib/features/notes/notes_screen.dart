import 'package:flutter/material.dart';

import '../../core/api/notes_api.dart';
import '../../core/models/notes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/pill_chip.dart';

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
  bool get _canEdit {
    final role = AppScope.of(context, listen: false).teacher?.role;
    return role == 'teacher' || role == 'principal';
  }

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

  Future<void> _edit() async {
    final summary = TextEditingController(text: _note?.summary ?? '');
    final points = TextEditingController(text: (_note?.keyPoints ?? const []).join('\n'));
    final terms = TextEditingController(text: (_note?.importantTerms ?? const []).join('\n'));
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MedhaColors.surface,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('नोट्स लिखें / संपादित करें', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(controller: summary, maxLines: 4, decoration: const InputDecoration(hintText: 'सारांश')),
              const SizedBox(height: 10),
              TextField(controller: points, maxLines: 4, decoration: const InputDecoration(hintText: 'मुख्य बिंदु (एक पंक्ति में एक)')),
              const SizedBox(height: 10),
              TextField(controller: terms, maxLines: 3, decoration: const InputDecoration(hintText: 'महत्वपूर्ण शब्द (एक पंक्ति में एक)')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('सेव करें'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await NotesApi.upsert(
        chapterId: widget.chapterId,
        summary: summary.text.trim(),
        keyPoints: points.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        importantTerms: terms.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      );
      await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('सेव नहीं हो सका')));
    }
  }

  Future<void> _delete() async {
    if (_note == null || _note!.id.isEmpty) return;
    await NotesApi.delete(_note!.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(
        leading: IconButton(icon: const MedhaIcon('chevron_left', color: MedhaColors.ink), onPressed: () => Navigator.of(context).pop()),
        title: const Text('नोट्स'),
        actions: [
          if (_canEdit) IconButton(onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
          if (_canEdit && _note != null) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline, color: MedhaColors.danger)),
        ],
      ),
      floatingActionButton: _canEdit && _note == null
          ? FloatingActionButton(backgroundColor: MedhaColors.primary, onPressed: _edit, child: const MedhaIcon('plus', color: Colors.white))
          : null,
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
                        Text('${widget.chapterTitle} के नोट्स अभी तैयार नहीं हैं', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        if (_canEdit) ...[
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _edit, child: const Text('नोट्स जोड़ें')),
                        ],
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(widget.chapterTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(_note!.summary, style: const TextStyle(fontSize: 13.5, color: MedhaColors.inkSoft, height: 1.6)),
                    if (_note!.keyPoints.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      MedhaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('मुख्य बिंदु', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MedhaColors.primary)),
                            const SizedBox(height: 8),
                            for (final p in _note!.keyPoints)
                              Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $p', style: const TextStyle(fontSize: 13, height: 1.4))),
                          ],
                        ),
                      ),
                    ],
                    if (_note!.importantTerms.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(spacing: 6, runSpacing: 6, children: _note!.importantTerms.map((t) => PillChip(label: t, dense: true)).toList()),
                    ],
                  ],
                ),
    );
  }
}
