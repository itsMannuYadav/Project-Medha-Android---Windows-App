import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../data/student_models.dart';
import '../../data/student_repository.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  List<LibraryResource> _items = [];
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
      final items = await ref.read(studentRepositoryProvider).getResources();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ScreenHeader(title: 'E-Library', subtitle: 'Digital resources for your class'),
        Expanded(
          child: _loading
              ? const LoadingBody()
              : _error != null
                  ? ErrorBody(message: _error!, onRetry: _load)
                  : _items.isEmpty
                      ? const EmptyState(message: 'No resources yet', icon: Icons.library_books_outlined)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.terracotta,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) => _ResourceCard(item: _items[i]),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final LibraryResource item;
  const _ResourceCard({required this.item});

  IconData get _icon {
    final t = item.type?.toLowerCase() ?? '';
    if (t.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (t.contains('video')) return Icons.play_circle_outline_rounded;
    return Icons.insert_drive_file_outlined;
  }

  Color get _color {
    final t = item.type?.toLowerCase() ?? '';
    if (t.contains('pdf')) return AppColors.destructive;
    if (t.contains('video')) return AppColors.violet;
    return AppColors.gold;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (item.url != null) {
          final uri = Uri.parse(item.url!);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
                  if (item.subjectName != null)
                    Text(item.subjectName!,
                        style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground)),
                ],
              ),
            ),
            if (item.url != null)
              const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
