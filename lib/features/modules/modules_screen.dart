import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/modules_api.dart';
import '../../core/models/module.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/pill_chip.dart';
import 'module_detail_screen.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  List<ModuleListItem> _modules = [];
  bool _loading = true;
  String? _error;
  String _filter = 'सभी';

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
      final modules = await ModulesApi.list();
      if (!mounted) return;
      setState(() {
        _modules = modules;
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

  static const _artifactIcon = {'explanation': 'presentation', 'quiz': 'help_circle', 'activity': 'activity'};

  @override
  Widget build(BuildContext context) {
    final subjects = ['सभी', ..._modules.map((m) => m.subjectName).toSet()];
    final visible = _filter == 'सभी' ? _modules : _modules.where((m) => m.subjectName == _filter).toList();

    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('मेरे मॉड्यूल')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: MedhaColors.danger))))
                : Column(
                    children: [
                      if (subjects.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(bottom: BorderSide(color: MedhaColors.border))),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: subjects
                                  .map((f) => Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: PillChip(label: f, selected: f == _filter, onTap: () => setState(() => _filter = f)),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      Expanded(
                        child: visible.isEmpty
                            ? ListView(
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.only(top: 80),
                                    child: Center(child: Text('अभी कोई मॉड्यूल नहीं है — Home से एक सवाल पूछकर शुरू करें।', textAlign: TextAlign.center, style: TextStyle(color: MedhaColors.muted))),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: visible.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  final m = visible[i];
                                  return MedhaCard(
                                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ModuleDetailScreen(moduleId: m.id))),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(m.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
                                                  const SizedBox(height: 7),
                                                  Row(
                                                    children: [
                                                      PillChip(label: m.gradeLabel, dense: true, background: MedhaColors.primaryWash, foreground: MedhaColors.primary),
                                                      const SizedBox(width: 6),
                                                      PillChip(label: m.subjectName, dense: true, background: MedhaColors.surface2, foreground: MedhaColors.inkSoft),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(_relativeTime(m.updatedAt), style: const TextStyle(fontSize: 11, color: MedhaColors.muted)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: m.artifactTypes
                                              .map((type) => Padding(
                                                    padding: const EdgeInsets.only(right: 7),
                                                    child: Container(
                                                      width: 24,
                                                      height: 24,
                                                      decoration: BoxDecoration(color: MedhaColors.primaryWash, borderRadius: BorderRadius.circular(7)),
                                                      child: Center(child: MedhaIcon(_artifactIcon[type] ?? 'presentation', size: 13, color: MedhaColors.primary)),
                                                    ),
                                                  ))
                                              .toList(),
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
    );
  }
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes} मिनट पहले';
  if (diff.inHours < 24) return '${diff.inHours} घंटे पहले';
  if (diff.inDays < 7) return '${diff.inDays} दिन पहले';
  return '${(diff.inDays / 7).floor()} सप्ताह पहले';
}
