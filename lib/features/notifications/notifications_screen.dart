import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/notifications_api.dart';
import '../../core/api/profile_api.dart';
import '../../core/models/notification.dart';
import '../../core/models/profile.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/pill_chip.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _items = [];
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
      final items = await NotificationsApi.list();
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

  Future<void> _open(NotificationItem item) async {
    if (item.isUnread) {
      setState(() {
        final i = _items.indexOf(item);
        _items[i] = NotificationItem(
          id: item.id,
          type: item.type,
          title: item.title,
          body: item.body,
          data: item.data,
          readAt: DateTime.now(),
          createdAt: item.createdAt,
        );
      });
      try {
        await NotificationsApi.markRead(item.id);
      } catch (_) {
        // best-effort -- the item still shows read locally
      }
    }
  }

  Future<void> _openAnnounceComposer() async {
    final role = AppScope.of(context, listen: false).teacher?.role;
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MedhaColors.surface,
      builder: (_) => _AnnounceComposer(isPrincipal: role == 'principal'),
    );
    if (sent == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final role = AppScope.of(context).teacher?.role;
    final canAnnounce = role == 'teacher' || role == 'principal';

    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('सूचनाएं')),
      floatingActionButton: canAnnounce
          ? FloatingActionButton.extended(
              onPressed: _openAnnounceComposer,
              backgroundColor: MedhaColors.primary,
              icon: const MedhaIcon('megaphone', size: 18, color: Colors.white),
              label: const Text('घोषणा भेजें', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: MedhaColors.danger))))
                : _items.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.only(top: 100),
                            child: Center(child: Text('अभी कोई सूचना नहीं है', style: TextStyle(color: MedhaColors.muted))),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final item = _items[i];
                          return InkWell(
                            borderRadius: BorderRadius.circular(MedhaRadii.md),
                            onTap: () => _open(item),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: item.isUnread ? MedhaColors.primaryWash : MedhaColors.surface,
                                border: Border.all(color: item.isUnread ? MedhaColors.primary.withValues(alpha: 0.25) : MedhaColors.border),
                                borderRadius: BorderRadius.circular(MedhaRadii.md),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.isUnread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 5, right: 10),
                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: MedhaColors.accent),
                                    )
                                  else
                                    const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.title,
                                            style: TextStyle(fontSize: 13.5, fontWeight: item.isUnread ? FontWeight.w700 : FontWeight.w600, color: MedhaColors.ink)),
                                        const SizedBox(height: 3),
                                        Text(item.body, style: const TextStyle(fontSize: 12.5, color: MedhaColors.inkSoft, height: 1.5)),
                                        const SizedBox(height: 6),
                                        Text(_relativeTime(item.createdAt), style: const TextStyle(fontSize: 10.5, color: MedhaColors.muted)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _AnnounceComposer extends StatefulWidget {
  const _AnnounceComposer({required this.isPrincipal});
  final bool isPrincipal;

  @override
  State<_AnnounceComposer> createState() => _AnnounceComposerState();
}

class _AnnounceComposerState extends State<_AnnounceComposer> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _audience = 'students';
  List<ProfileSubject> _grades = [];
  String? _gradeId;
  bool _loadingGrades = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!widget.isPrincipal) _loadGrades();
  }

  Future<void> _loadGrades() async {
    try {
      final profile = await ProfileApi.get();
      final seen = <String>{};
      final grades = [for (final s in profile.subjects) if (seen.add(s.gradeId)) s];
      if (!mounted) return;
      setState(() {
        _grades = grades;
        _gradeId = grades.isEmpty ? null : grades.first.gradeId;
        _loadingGrades = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingGrades = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      setState(() => _error = 'शीर्षक और संदेश दोनों भरें।');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await NotificationsApi.announce(
        title: _title.text.trim(),
        body: _body.text.trim(),
        audience: widget.isPrincipal ? _audience : null,
        gradeId: widget.isPrincipal ? null : _gradeId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('घोषणा भेजें', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
              const SizedBox(height: 14),
              if (widget.isPrincipal)
                Row(
                  children: [
                    PillChip(label: 'छात्रों को', selected: _audience == 'students', onTap: () => setState(() => _audience = 'students')),
                    const SizedBox(width: 8),
                    PillChip(label: 'शिक्षकों को', selected: _audience == 'teachers', onTap: () => setState(() => _audience = 'teachers')),
                  ],
                )
              else if (_loadingGrades)
                const SizedBox(height: 32, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              else if (_grades.isEmpty)
                const Text('कोई कक्षा नहीं मिली।', style: TextStyle(color: MedhaColors.muted))
              else
                Wrap(
                  spacing: 8,
                  children: _grades
                      .map((g) => PillChip(label: g.gradeLabel, selected: g.gradeId == _gradeId, onTap: () => setState(() => _gradeId = g.gradeId)))
                      .toList(),
                ),
              const SizedBox(height: 14),
              TextField(controller: _title, decoration: const InputDecoration(hintText: 'शीर्षक')),
              const SizedBox(height: 10),
              TextField(controller: _body, maxLines: 3, decoration: const InputDecoration(hintText: 'संदेश')),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(fontSize: 12.5, color: MedhaColors.danger)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sending ? null : _send,
                  child: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('भेजें'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'अभी';
  if (diff.inMinutes < 60) return '${diff.inMinutes} मिनट पहले';
  if (diff.inHours < 24) return '${diff.inHours} घंटे पहले';
  return '${diff.inDays} दिन पहले';
}
