import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/profile_api.dart';
import '../../core/api/reference_api.dart';
import '../../core/models/profile.dart';
import '../../core/models/reference.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/pill_chip.dart';

/// A read-only browse of the curriculum already in the database
/// (`/curriculum/chapters` + `/curriculum/topics`) -- no new backend, this
/// is purely a frontend view surfacing data that already exists.
class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  List<ProfileSubject> _options = [];
  ProfileSubject? _selected;
  List<ChapterRef> _chapters = [];
  final _expanded = <String>{};
  final _topicsByChapter = <String, List<TopicRef>>{};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final profile = await ProfileApi.get();
      if (!mounted) return;
      if (profile.subjects.isEmpty) {
        setState(() {
          _error = 'प्रोफ़ाइल में कोई विषय नहीं जुड़ा।';
          _loading = false;
        });
        return;
      }
      setState(() {
        _options = profile.subjects;
        _selected = profile.subjects.first;
      });
      await _loadChapters();
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadChapters() async {
    if (_selected == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _expanded.clear();
      _topicsByChapter.clear();
    });
    try {
      final chapters = await ReferenceApi.chapters(gradeId: _selected!.gradeId, subjectId: _selected!.subjectId);
      if (!mounted) return;
      setState(() {
        _chapters = chapters;
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

  Future<void> _toggleChapter(ChapterRef chapter) async {
    if (_expanded.contains(chapter.id)) {
      setState(() => _expanded.remove(chapter.id));
      return;
    }
    setState(() => _expanded.add(chapter.id));
    if (_topicsByChapter.containsKey(chapter.id)) return;
    try {
      final topics = await ReferenceApi.topics(chapter.id);
      if (mounted) setState(() => _topicsByChapter[chapter.id] = topics);
    } catch (_) {
      if (mounted) setState(() => _topicsByChapter[chapter.id] = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('पाठ्यक्रम')),
      body: Column(
        children: [
          if (_options.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(bottom: BorderSide(color: MedhaColors.border))),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _options
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: PillChip(
                              label: '${s.subjectName} · ${s.gradeLabel}',
                              selected: s.subjectId == _selected?.subjectId && s.gradeId == _selected?.gradeId,
                              onTap: () {
                                setState(() => _selected = s);
                                _loadChapters();
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: MedhaColors.danger))))
                    : _chapters.isEmpty
                        ? const Center(child: Text('इस विषय के लिए अभी पाठ्यक्रम उपलब्ध नहीं है।', style: TextStyle(color: MedhaColors.muted)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _chapters.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final chapter = _chapters[i];
                              final open = _expanded.contains(chapter.id);
                              final topics = _topicsByChapter[chapter.id];
                              return MedhaCard(
                                padding: const EdgeInsets.all(0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      borderRadius: BorderRadius.circular(MedhaRadii.lg),
                                      onTap: () => _toggleChapter(chapter),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 26,
                                              height: 26,
                                              alignment: Alignment.center,
                                              decoration: const BoxDecoration(shape: BoxShape.circle, color: MedhaColors.primaryWash),
                                              child: Text('${chapter.chapterNumber}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: MedhaColors.primary)),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(child: Text(chapter.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
                                            MedhaIcon(open ? 'chevron_down' : 'chevron_right', size: 15, color: MedhaColors.muted),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (open)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                        child: topics == null
                                            ? const Padding(padding: EdgeInsets.only(left: 36), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                                            : topics.isEmpty
                                                ? const Padding(padding: EdgeInsets.only(left: 36), child: Text('कोई विषय-वस्तु नहीं मिली', style: TextStyle(fontSize: 12, color: MedhaColors.muted)))
                                                : Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: topics
                                                        .map((t) => Padding(
                                                              padding: const EdgeInsets.only(left: 36, top: 6),
                                                              child: Text('• ${t.title}', style: const TextStyle(fontSize: 12.5, color: MedhaColors.inkSoft)),
                                                            ))
                                                        .toList(),
                                                  ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
