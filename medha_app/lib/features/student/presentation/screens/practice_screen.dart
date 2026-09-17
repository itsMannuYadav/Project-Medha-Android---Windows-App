import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  List<Map<String, dynamic>> _quizzes = [];
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
      final res = await ref.read(apiClientProvider).get('/student/practice');
      final list = res.data as List? ?? [];
      if (mounted) {
        setState(() {
          _quizzes = list.cast<Map<String, dynamic>>();
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
        const ScreenHeader(title: 'Practice', subtitle: 'Test your knowledge with practice quizzes'),
        Expanded(
          child: _loading
              ? const LoadingBody()
              : _error != null
                  ? ErrorBody(message: _error!, onRetry: _load)
                  : _quizzes.isEmpty
                      ? const EmptyState(
                          message: 'No practice quizzes available',
                          icon: Icons.quiz_outlined)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.terracotta,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _quizzes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final q = _quizzes[i];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.tintQuiz,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.hairline),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.sage.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.quiz_rounded, color: AppColors.sage, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            q['title'] as String? ?? 'Quiz',
                                            style: GoogleFonts.manrope(
                                                fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                                          ),
                                          if (q['subject_name'] != null)
                                            Text(q['subject_name'] as String,
                                                style: GoogleFonts.manrope(fontSize: 12, color: AppColors.mutedForeground)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.mutedForeground),
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
