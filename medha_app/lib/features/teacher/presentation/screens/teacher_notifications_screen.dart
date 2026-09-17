import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';

class TeacherNotificationsScreen extends ConsumerStatefulWidget {
  const TeacherNotificationsScreen({super.key});

  @override
  ConsumerState<TeacherNotificationsScreen> createState() => _TeacherNotificationsScreenState();
}

class _TeacherNotificationsScreenState extends ConsumerState<TeacherNotificationsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ref.read(apiClientProvider).get('/notifications');
      final list = (res.data as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _items = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showAnnounceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AnnounceSheet(
        api: ref.read(apiClientProvider),
        onSent: () { Navigator.pop(ctx); _load(); },
      ),
    );
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    try { return DateFormat('d MMM, hh:mm a').format(DateTime.parse(iso).toLocal()); }
    catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Notifications',
          subtitle: 'School announcements',
          trailing: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.terracotta, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_rounded, color: AppColors.ivory, size: 18),
            ),
            onPressed: _showAnnounceSheet,
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingBody()
              : _error != null
                  ? ErrorBody(message: _error!, onRetry: _load)
                  : _items.isEmpty
                      ? const EmptyState(message: 'No notifications yet', icon: Icons.notifications_outlined)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.terracotta,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final n = _items[i];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.hairline),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 36, height: 36,
                                          decoration: BoxDecoration(
                                            color: AppColors.terracotta.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.campaign_rounded, color: AppColors.terracotta, size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(n['title'] as String? ?? '',
                                              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                                        ),
                                      ],
                                    ),
                                    if (n['body'] != null || n['message'] != null) ...[
                                      const SizedBox(height: 8),
                                      Text((n['body'] ?? n['message']) as String,
                                          style: GoogleFonts.manrope(fontSize: 13, color: AppColors.mutedForeground)),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(_fmtDate(n['created_at'] as String?),
                                        style: GoogleFonts.manrope(fontSize: 11, color: AppColors.mutedForeground)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

class _AnnounceSheet extends StatefulWidget {
  final ApiClient api;
  final VoidCallback onSent;
  const _AnnounceSheet({required this.api, required this.onSent});

  @override
  State<_AnnounceSheet> createState() => _AnnounceSheetState();
}

class _AnnounceSheetState extends State<_AnnounceSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _audience = 'students';
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.api.post('/notifications', data: {
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim().isEmpty ? null : _bodyCtrl.text.trim(),
        'audience': _audience,
      });
      widget.onSent();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.destructive));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Send Announcement', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 16),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Title'), autofocus: true),
          const SizedBox(height: 10),
          TextField(controller: _bodyCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Message (optional)')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _audience,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'students', child: Text('Students')),
              DropdownMenuItem(value: 'teachers', child: Text('Teachers')),
              DropdownMenuItem(value: 'all', child: Text('Everyone')),
            ],
            onChanged: (v) { if (v != null) setState(() => _audience = v); },
            decoration: const InputDecoration(labelText: 'Audience'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _sending ? null : _send,
            child: _sending
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ivory))
                : const Text('Send'),
          ),
        ],
      ),
    );
  }
}
