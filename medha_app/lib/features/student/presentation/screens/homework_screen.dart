import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../data/student_models.dart';
import '../../data/student_repository.dart';

class HomeworkScreen extends ConsumerStatefulWidget {
  const HomeworkScreen({super.key});

  @override
  ConsumerState<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends ConsumerState<HomeworkScreen> {
  List<HomeworkItem> _items = [];
  bool _loading = true;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await ref.read(studentRepositoryProvider).getMyHomework();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggle(HomeworkItem hw) async {
    setState(() => _busyId = hw.id);
    try {
      final repo = ref.read(studentRepositoryProvider);
      final updated = hw.done
          ? await repo.markHomeworkUndone(hw.id)
          : await repo.markHomeworkDone(hw.id);
      if (mounted) {
        setState(() {
          _items = _items.map((x) => x.id == hw.id ? updated : x).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      return DateFormat('d MMM').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ScreenHeader(
          title: 'My Homework',
          subtitle: 'Mark tasks as done when complete',
        ),
        Expanded(
          child: _loading
              ? const LoadingBody()
              : _error != null
                  ? ErrorBody(message: _error!, onRetry: _load)
                  : _items.isEmpty
                      ? const EmptyState(
                          message: 'No homework assigned yet',
                          icon: Icons.assignment_outlined)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.terracotta,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final hw = _items[i];
                              return _HomeworkCard(
                                item: hw,
                                busy: _busyId == hw.id,
                                onToggle: () => _toggle(hw),
                                fmtDate: _fmtDate,
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final HomeworkItem item;
  final bool busy;
  final VoidCallback onToggle;
  final String Function(String?) fmtDate;

  const _HomeworkCard({
    required this.item,
    required this.busy,
    required this.onToggle,
    required this.fmtDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.done
            ? AppColors.card.withValues(alpha: 0.6)
            : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.done
              ? AppColors.hairline.withValues(alpha: 0.5)
              : AppColors.hairline,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          GestureDetector(
            onTap: busy ? null : onToggle,
            child: busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.terracotta))
                : Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: item.done
                          ? AppColors.terracotta
                          : Colors.transparent,
                      border: Border.all(
                        color: item.done
                            ? AppColors.terracotta
                            : AppColors.hairline,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: item.done
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: AppColors.ivory)
                        : null,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: item.done
                        ? AppColors.mutedForeground
                        : AppColors.ink,
                    decoration: item.done
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.mutedForeground),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (item.subjectName != null)
                      _Badge(label: item.subjectName!),
                    if (item.dueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          'Due ${fmtDate(item.dueDate)}',
                          style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppColors.mutedForeground),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
            fontSize: 11, color: AppColors.mutedForeground),
      ),
    );
  }
}
