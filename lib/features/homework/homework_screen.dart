import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/homework_api.dart';
import '../../core/models/homework.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import 'create_homework_screen.dart';

/// Role-aware: a teacher sees what they've assigned (with completion
/// counts); a student sees their own list with a done/not-done toggle.
class HomeworkScreen extends StatelessWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = AppScope.of(context).teacher?.role;
    return role == 'student' ? const _StudentHomework() : const _TeacherHomework();
  }
}

class _TeacherHomework extends StatefulWidget {
  const _TeacherHomework();
  @override
  State<_TeacherHomework> createState() => _TeacherHomeworkState();
}

class _TeacherHomeworkState extends State<_TeacherHomework> {
  List<HomeworkListItem> _items = [];
  bool _loading = true;
  String? _error;

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
      final items = await HomeworkApi.listForTeacher();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('होमवर्क')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MedhaColors.primary,
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const CreateHomeworkScreen()));
          if (created == true) _load();
        },
        child: const MedhaIcon('plus', size: 20, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: MedhaColors.danger))))
                : _items.isEmpty
                    ? ListView(children: const [
                        Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: Center(child: Text('अभी कोई होमवर्क नहीं दिया — नीचे + दबाकर शुरू करें', textAlign: TextAlign.center, style: TextStyle(color: MedhaColors.muted))),
                        ),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final h = _items[i];
                          final allDone = h.totalCount > 0 && h.doneCount == h.totalCount;
                          return MedhaCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(h.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
                                      const SizedBox(height: 4),
                                      Text('${h.gradeLabel}${h.subjectName != null ? " · ${h.subjectName}" : ""}',
                                          style: const TextStyle(fontSize: 11.5, color: MedhaColors.muted)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: allDone ? MedhaColors.successWash : MedhaColors.surface2,
                                    borderRadius: BorderRadius.circular(MedhaRadii.pill),
                                  ),
                                  child: Text('${h.doneCount}/${h.totalCount}',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: allDone ? MedhaColors.successInk : MedhaColors.inkSoft)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _StudentHomework extends StatefulWidget {
  const _StudentHomework();
  @override
  State<_StudentHomework> createState() => _StudentHomeworkState();
}

class _StudentHomeworkState extends State<_StudentHomework> {
  List<HomeworkStudentItem> _items = [];
  bool _loading = true;
  String? _error;
  final _toggling = <String>{};

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
      final items = await HomeworkApi.listForStudent();
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

  Future<void> _toggle(HomeworkStudentItem item) async {
    setState(() => _toggling.add(item.id));
    try {
      final updated = await HomeworkApi.setDone(item.id, !item.done);
      if (!mounted) return;
      setState(() {
        final i = _items.indexWhere((h) => h.id == item.id);
        if (i != -1) _items[i] = updated;
      });
    } on ApiError catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _toggling.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('मेरा होमवर्क')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: MedhaColors.danger))))
                : _items.isEmpty
                    ? ListView(children: const [
                        Padding(padding: EdgeInsets.only(top: 100), child: Center(child: Text('अभी कोई होमवर्क नहीं है', style: TextStyle(color: MedhaColors.muted)))),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final h = _items[i];
                          final busy = _toggling.contains(h.id);
                          return MedhaCard(
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: busy ? null : () => _toggle(h),
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: h.done ? MedhaColors.success : Colors.transparent,
                                      border: Border.all(color: h.done ? MedhaColors.success : MedhaColors.borderStrong, width: 1.75),
                                    ),
                                    child: busy
                                        ? const Padding(padding: EdgeInsets.all(5), child: CircularProgressIndicator(strokeWidth: 2))
                                        : h.done
                                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(h.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: MedhaColors.ink,
                                            decoration: h.done ? TextDecoration.lineThrough : null,
                                          )),
                                      if (h.subjectName != null) Text(h.subjectName!, style: const TextStyle(fontSize: 11.5, color: MedhaColors.muted)),
                                      if (h.description != null && h.description!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(h.description!, style: const TextStyle(fontSize: 12.5, color: MedhaColors.inkSoft)),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
