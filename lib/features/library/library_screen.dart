import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_error.dart';
import '../../core/api/download_api.dart';
import '../../core/api/library_api.dart';
import '../../core/api/reference_api.dart';
import '../../core/data/library_books.dart';
import '../../core/models/library_item.dart';
import '../../core/models/library_presentation.dart';
import '../../core/models/reference.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/pill_chip.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<LibraryItem> _items = [];
  List<LibraryPresentationItem> _presentations = [];
  List<GradeRef> _grades = [];
  List<SubjectRef> _subjects = [];
  String? _gradeFilter;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final results = await Future.wait([ReferenceApi.grades(), ReferenceApi.subjects()]);
      if (!mounted) return;
      setState(() {
        _grades = results[0] as List<GradeRef>;
        _subjects = results[1] as List<SubjectRef>;
      });
    } catch (_) {}
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        LibraryApi.list(gradeId: _gradeFilter),
        LibraryApi.presentations(gradeId: _gradeFilter),
      ]);
      if (!mounted) return;
      setState(() {
        _items = results[0] as List<LibraryItem>;
        _presentations = results[1] as List<LibraryPresentationItem>;
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

  Future<void> _openAdd() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MedhaColors.surface,
      builder: (_) => _AddLibraryItemSheet(grades: _grades, subjects: _subjects),
    );
    if (added == true) _load();
  }

  Future<void> _delete(LibraryItem item) async {
    try {
      await LibraryApi.delete(item.id);
      _load();
    } on ApiError catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('लिंक कॉपी हुआ: $url'), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _openPresentation(LibraryPresentationItem p) async {
    try {
      final detail = await LibraryApi.presentation(p.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _PresentationDetailScreen(detail: detail)),
      );
    } on ApiError catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = AppScope.of(context).teacher?.role;
    final canManage = role == 'teacher' || role == 'principal';

    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(
        title: const Text('ई-लाइब्रेरी'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: MedhaColors.primary,
          unselectedLabelColor: MedhaColors.muted,
          indicatorColor: MedhaColors.primary,
          tabs: const [
            Tab(text: 'प्रस्तुतियाँ'),
            Tab(text: 'पुस्तकें'),
            Tab(text: 'लिंक'),
          ],
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(backgroundColor: MedhaColors.primary, onPressed: _openAdd, child: const MedhaIcon('plus', size: 20, color: Colors.white))
          : null,
      body: Column(
        children: [
          if (_grades.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(bottom: BorderSide(color: MedhaColors.border))),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    PillChip(label: 'सभी कक्षाएं', dense: true, selected: _gradeFilter == null, onTap: () {
                      setState(() => _gradeFilter = null);
                      _load();
                    }),
                    const SizedBox(width: 6),
                    for (final g in _grades) ...[
                      PillChip(label: g.label, dense: true, selected: _gradeFilter == g.id, onTap: () {
                        setState(() => _gradeFilter = g.id);
                        _load();
                      }),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: MedhaColors.danger)))
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          RefreshIndicator(
                            onRefresh: _load,
                            child: _presentations.isEmpty
                                ? ListView(children: const [
                                    Padding(padding: EdgeInsets.only(top: 100), child: Center(child: Text('कोई प्रस्तुति नहीं', style: TextStyle(color: MedhaColors.muted)))),
                                  ])
                                : ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _presentations.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                                    itemBuilder: (context, i) {
                                      final p = _presentations[i];
                                      return MedhaCard(
                                        onTap: () => _openPresentation(p),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(color: MedhaColors.accentWash, borderRadius: BorderRadius.circular(10)),
                                              child: const Center(child: MedhaIcon('presentation', size: 18, color: MedhaColors.accentInk)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(p.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    [
                                                      if (p.gradeLabel != null) p.gradeLabel!,
                                                      if (p.subjectName != null) p.subjectName!,
                                                      if (p.slideCount != null) '${p.slideCount} स्लाइड',
                                                    ].join(' · '),
                                                    style: const TextStyle(fontSize: 11.5, color: MedhaColors.muted),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const MedhaIcon('chevron_right', size: 15, color: MedhaColors.muted),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: libraryBooks.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final b = libraryBooks[i];
                              return MedhaCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 3),
                                    Text('${b.author} · ${b.classLabel} · ${b.pages} पृष्ठ', style: const TextStyle(fontSize: 11.5, color: MedhaColors.muted)),
                                    const SizedBox(height: 6),
                                    Text(b.blurb, style: const TextStyle(fontSize: 12.5, height: 1.4, color: MedhaColors.inkSoft)),
                                    const SizedBox(height: 8),
                                    PillChip(label: b.category, dense: true),
                                  ],
                                ),
                              );
                            },
                          ),
                          RefreshIndicator(
                            onRefresh: _load,
                            child: _items.isEmpty
                                ? ListView(children: const [
                                    Padding(padding: EdgeInsets.only(top: 100), child: Center(child: Text('अभी कोई लिंक नहीं', style: TextStyle(color: MedhaColors.muted)))),
                                  ])
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                                    itemCount: _items.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                                    itemBuilder: (context, i) {
                                      final item = _items[i];
                                      return MedhaCard(
                                        onTap: () => _openUrl(item.url),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(color: MedhaColors.primaryWash, borderRadius: BorderRadius.circular(10)),
                                              child: const Center(child: MedhaIcon('book', size: 18, color: MedhaColors.primary)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(item.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                                                  if (item.description != null) ...[
                                                    const SizedBox(height: 3),
                                                    Text(item.description!, style: const TextStyle(fontSize: 12, color: MedhaColors.inkSoft)),
                                                  ],
                                                  const SizedBox(height: 6),
                                                  Wrap(spacing: 6, children: [
                                                    if (item.gradeLabel != null) PillChip(label: item.gradeLabel!, dense: true, background: MedhaColors.primaryWash, foreground: MedhaColors.primary),
                                                    if (item.subjectName != null) PillChip(label: item.subjectName!, dense: true, background: MedhaColors.surface2, foreground: MedhaColors.inkSoft),
                                                  ]),
                                                ],
                                              ),
                                            ),
                                            if (canManage)
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 18, color: MedhaColors.muted),
                                                onPressed: () => _delete(item),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _PresentationDetailScreen extends StatelessWidget {
  const _PresentationDetailScreen({required this.detail});
  final LibraryPresentationDetail detail;

  @override
  Widget build(BuildContext context) {
    final slides = (detail.spec?['slides'] as List?) ?? const [];
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(
        title: Text(detail.title),
        actions: [
          IconButton(
            tooltip: 'PPTX डाउनलोड',
            onPressed: () async {
              try {
                await DownloadApi.libraryPresentationPptx(detail.id);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('डाउनलोड नहीं हो सका')));
                }
              }
            },
            icon: const MedhaIcon('download', color: MedhaColors.primary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (detail.description != null) ...[
            Text(detail.description!, style: const TextStyle(fontSize: 13.5, color: MedhaColors.inkSoft, height: 1.45)),
            const SizedBox(height: 14),
          ],
          Text(
            [
              if (detail.gradeLabel != null) detail.gradeLabel!,
              if (detail.subjectName != null) detail.subjectName!,
              if (detail.slideCount != null) '${detail.slideCount} स्लाइड',
            ].join(' · '),
            style: const TextStyle(fontSize: 12, color: MedhaColors.muted),
          ),
          const SizedBox(height: 16),
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
          if (slides.isEmpty)
            const Text('इस प्रस्तुति का पूर्वावलोकन उपलब्ध नहीं', style: TextStyle(color: MedhaColors.muted)),
        ],
      ),
    );
  }
}

class _AddLibraryItemSheet extends StatefulWidget {
  const _AddLibraryItemSheet({required this.grades, required this.subjects});
  final List<GradeRef> grades;
  final List<SubjectRef> subjects;

  @override
  State<_AddLibraryItemSheet> createState() => _AddLibraryItemSheetState();
}

class _AddLibraryItemSheetState extends State<_AddLibraryItemSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _url = TextEditingController();
  GradeRef? _grade;
  SubjectRef? _subject;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _url.text.trim().isEmpty) {
      setState(() => _error = 'शीर्षक और लिंक दोनों भरें।');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await LibraryApi.add(
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        url: _url.text.trim(),
        gradeId: _grade?.id,
        subjectId: _subject?.id,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('सामग्री जोड़ें', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
              const SizedBox(height: 14),
              TextField(controller: _title, decoration: const InputDecoration(hintText: 'शीर्षक')),
              const SizedBox(height: 10),
              TextField(controller: _description, decoration: const InputDecoration(hintText: 'विवरण (वैकल्पिक)')),
              const SizedBox(height: 10),
              TextField(controller: _url, decoration: const InputDecoration(hintText: 'लिंक (URL)')),
              const SizedBox(height: 12),
              if (widget.grades.isNotEmpty) ...[
                Wrap(spacing: 8, children: widget.grades.map((g) => PillChip(label: g.label, dense: true, selected: g.id == _grade?.id, onTap: () => setState(() => _grade = _grade?.id == g.id ? null : g))).toList()),
                const SizedBox(height: 8),
              ],
              if (widget.subjects.isNotEmpty)
                Wrap(spacing: 8, children: widget.subjects.map((s) => PillChip(label: s.name, dense: true, selected: s.id == _subject?.id, onTap: () => setState(() => _subject = _subject?.id == s.id ? null : s))).toList()),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(fontSize: 12.5, color: MedhaColors.danger)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('जोड़ें'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
