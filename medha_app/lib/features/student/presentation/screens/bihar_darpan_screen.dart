import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../../core/network/api_client.dart';

class BiharDarpanScreen extends ConsumerStatefulWidget {
  const BiharDarpanScreen({super.key});

  @override
  ConsumerState<BiharDarpanScreen> createState() => _BiharDarpanScreenState();
}

class _BiharDarpanScreenState extends ConsumerState<BiharDarpanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  int? _selectedAnswer;
  bool _quizSubmitted = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ref.read(apiClientProvider).get('/student/bihar-darpan');
      if (mounted) setState(() { _data = res.data as Map<String, dynamic>?; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ScreenHeader(
          title: 'Bihar Darpan',
          subtitle: 'Daily learning — current affairs, GK & quiz',
        ),
        if (!_loading)
          Container(
            color: AppColors.card,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.terracotta,
              unselectedLabelColor: AppColors.mutedForeground,
              indicatorColor: AppColors.terracotta,
              labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Quote'),
                Tab(text: 'Current Affairs'),
                Tab(text: 'Quiz'),
              ],
            ),
          ),
        Expanded(
          child: _loading
              ? const LoadingBody()
              : _error != null
                  ? ErrorBody(message: _error!, onRetry: _load)
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _QuoteTab(data: _data),
                        _AffairsTab(data: _data),
                        _QuizTab(
                          data: _data,
                          selectedAnswer: _selectedAnswer,
                          submitted: _quizSubmitted,
                          onSelect: (i) => setState(() => _selectedAnswer = i),
                          onSubmit: () => setState(() => _quizSubmitted = true),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _QuoteTab extends StatelessWidget {
  final Map<String, dynamic>? data;
  const _QuoteTab({this.data});

  @override
  Widget build(BuildContext context) {
    final quote = data?['quote'] as String? ?? 'No quote for today';
    final author = data?['quote_author'] as String? ?? '— मेधा';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.terracotta.withValues(alpha: 0.08), AppColors.gold.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              children: [
                Text(
                  '"',
                  style: GoogleFonts.fraunces(
                      fontSize: 64, color: AppColors.terracotta.withValues(alpha: 0.4), height: 0.7),
                ),
                const SizedBox(height: 8),
                Text(
                  quote,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(
                      fontSize: 18, color: AppColors.ink, height: 1.6),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 3,
                  width: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.saffron, AppColors.tricolorWhite, AppColors.tricolorGreen],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  author,
                  style: GoogleFonts.manrope(
                      fontSize: 14, color: AppColors.mutedForeground, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AffairsTab extends StatelessWidget {
  final Map<String, dynamic>? data;
  const _AffairsTab({this.data});

  @override
  Widget build(BuildContext context) {
    final items = (data?['current_affairs'] as List?)
        ?.map((e) => e as Map<String, dynamic>)
        .toList() ?? [];

    if (items.isEmpty) {
      return const EmptyState(message: 'No current affairs today', icon: Icons.newspaper_outlined);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final item = items[i];
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
              if (item['headline'] != null)
                Text(
                  item['headline'] as String,
                  style: GoogleFonts.manrope(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
              if (item['summary'] != null) ...[
                const SizedBox(height: 6),
                Text(
                  item['summary'] as String,
                  style: GoogleFonts.manrope(fontSize: 13, color: AppColors.mutedForeground),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _QuizTab extends StatelessWidget {
  final Map<String, dynamic>? data;
  final int? selectedAnswer;
  final bool submitted;
  final void Function(int) onSelect;
  final VoidCallback onSubmit;

  const _QuizTab({
    this.data,
    this.selectedAnswer,
    required this.submitted,
    required this.onSelect,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final quiz = data?['quiz'] as Map<String, dynamic>?;
    if (quiz == null) {
      return const EmptyState(message: 'No quiz for today', icon: Icons.quiz_outlined);
    }
    final question = quiz['question'] as String? ?? '';
    final options = (quiz['options'] as List?)?.cast<String>() ?? [];
    final correctIndex = quiz['correct_index'] as int? ?? 0;
    final explanation = quiz['explanation'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.violetMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              question,
              style: GoogleFonts.manrope(
                  fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 16),
          ...options.asMap().entries.map((e) {
            final i = e.key;
            final opt = e.value;
            final isSelected = selectedAnswer == i;
            final isCorrect = submitted && i == correctIndex;
            final isWrong = submitted && isSelected && i != correctIndex;

            return GestureDetector(
              onTap: submitted ? null : () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.sage.withValues(alpha: 0.15)
                      : isWrong
                          ? AppColors.destructive.withValues(alpha: 0.1)
                          : isSelected
                              ? AppColors.terracotta.withValues(alpha: 0.1)
                              : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect
                        ? AppColors.sage
                        : isWrong
                            ? AppColors.destructive
                            : isSelected
                                ? AppColors.terracotta
                                : AppColors.hairline,
                    width: isSelected || isCorrect || isWrong ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${String.fromCharCode(65 + i)}. $opt',
                        style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink),
                      ),
                    ),
                    if (isCorrect)
                      const Icon(Icons.check_circle_rounded, color: AppColors.sage, size: 18),
                    if (isWrong)
                      const Icon(Icons.cancel_rounded, color: AppColors.destructive, size: 18),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          if (!submitted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedAnswer != null ? onSubmit : null,
                child: const Text('Submit Answer'),
              ),
            ),
          if (submitted && explanation != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.sage.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explanation',
                      style: GoogleFonts.manrope(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.sage)),
                  const SizedBox(height: 6),
                  Text(explanation,
                      style: GoogleFonts.manrope(fontSize: 13, color: AppColors.ink)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
