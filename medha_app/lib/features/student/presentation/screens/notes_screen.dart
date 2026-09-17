import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  List<Map<String, dynamic>> _notes = [];
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
      final res = await ref.read(apiClientProvider).get('/student/notes');
      final list = res.data as List? ?? [];
      if (mounted) {
        setState(() {
          _notes = list.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ScreenHeader(title: 'My Notes', subtitle: 'Notes shared by your teacher'),
        Expanded(
          child: _loading
              ? const LoadingBody()
              : _error != null
                  ? ErrorBody(message: _error!, onRetry: _load)
                  : _notes.isEmpty
                      ? const EmptyState(
                          message: 'No notes available yet',
                          icon: Icons.notes_outlined)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.terracotta,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _notes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final note = _notes[i];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.tintNotes,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.hairline),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note['title'] as String? ?? 'Note',
                                      style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.ink),
                                    ),
                                    if (note['content'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        note['content'] as String,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.manrope(
                                            fontSize: 13, color: AppColors.mutedForeground),
                                      ),
                                    ],
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
