import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/library_api.dart';
import '../../core/api/reference_api.dart';
import '../../core/models/library_item.dart';
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

class _LibraryScreenState extends State<LibraryScreen> {
  List<LibraryItem> _items = [];
  List<GradeRef> _grades = [];
  List<SubjectRef> _subjects = [];
  String? _gradeFilter;
  String? _subjectFilter;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final results = await Future.wait([ReferenceApi.grades(), ReferenceApi.subjects()]);
      if (!mounted) return;
      setState(() {
        _grades = results[0] as List<GradeRef>;
        _subjects = results[1] as List<SubjectRef>;
      });
    } catch (_) {
      // filters just won't populate; the list itself still loads
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await LibraryApi.list(gradeId: _gradeFilter, subjectId: _subjectFilter);
      if (!mounted) return;
      setState(() {
        _items = items;
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

  @override
  Widget build(BuildContext context) {
    final role = AppScope.of(context).teacher?.role;
    final canManage = role == 'teacher' || role == 'principal';

    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('ई-लाइब्रेरी')),
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
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
                  : _error != null
                      ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: MedhaColors.danger))))
                      : _items.isEmpty
                          ? ListView(children: const [
                              Padding(padding: EdgeInsets.only(top: 100), child: Center(child: Text('अभी कोई सामग्री नहीं है', style: TextStyle(color: MedhaColors.muted)))),
                            ])
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                              itemCount: _items.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final item = _items[i];
                                return MedhaCard(
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
          ),
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
