import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/generation_api.dart';
import '../../core/models/generation.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/pill_chip.dart';
import 'create_generation_screen.dart';
import 'generation_detail_screen.dart';

class GenerationsListScreen extends StatefulWidget {
  const GenerationsListScreen({super.key, this.initialType});
  final String? initialType;

  @override
  State<GenerationsListScreen> createState() => _GenerationsListScreenState();
}

class _GenerationsListScreenState extends State<GenerationsListScreen> {
  String? _typeFilter;
  List<GenerationListItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.initialType;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await GenerationApi.list(type: _typeFilter);
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

  Future<void> _open(GenerationListItem item) async {
    try {
      final detail = await GenerationApi.get(item.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GenerationDetailScreen(initial: detail)),
      );
      _load();
    } on ApiError catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('जनरेशन इतिहास')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MedhaColors.primary,
        onPressed: () async {
          final type = await showModalBottomSheet<String>(
            context: context,
            backgroundColor: MedhaColors.surface,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final t in kGenerationTypes)
                    ListTile(
                      title: Text(generationTypeLabel(t)),
                      onTap: () => Navigator.pop(context, t),
                    ),
                ],
              ),
            ),
          );
          if (type == null || !mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CreateGenerationScreen(type: type)),
          );
          _load();
        },
        child: const MedhaIcon('plus', size: 20, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(bottom: BorderSide(color: MedhaColors.border))),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  PillChip(
                    label: 'सभी',
                    dense: true,
                    selected: _typeFilter == null,
                    onTap: () {
                      setState(() => _typeFilter = null);
                      _load();
                    },
                  ),
                  const SizedBox(width: 6),
                  for (final t in kGenerationTypes) ...[
                    PillChip(
                      label: generationTypeLabel(t),
                      dense: true,
                      selected: _typeFilter == t,
                      onTap: () {
                        setState(() => _typeFilter = t);
                        _load();
                      },
                    ),
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
                    : _items.isEmpty
                        ? const Center(child: Text('अभी कोई जनरेशन नहीं', style: TextStyle(color: MedhaColors.muted)))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _items.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final item = _items[i];
                                return MedhaCard(
                                  onTap: () => _open(item),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: MedhaColors.primaryWash,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Center(child: MedhaIcon('clipboard', size: 16, color: MedhaColors.primary)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Text(
                                              [
                                                generationTypeLabel(item.type),
                                                if (item.gradeLabel != null) item.gradeLabel!,
                                                if (item.subjectName != null) item.subjectName!,
                                              ].join(' · '),
                                              style: const TextStyle(fontSize: 11, color: MedhaColors.muted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (item.isFavorite)
                                        const Icon(Icons.star_rounded, size: 16, color: MedhaColors.accent),
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
