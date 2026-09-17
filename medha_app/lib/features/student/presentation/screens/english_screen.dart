import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';

class EnglishScreen extends ConsumerStatefulWidget {
  const EnglishScreen({super.key});

  @override
  ConsumerState<EnglishScreen> createState() => _EnglishScreenState();
}

class _EnglishScreenState extends ConsumerState<EnglishScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

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
      final res = await ref.read(apiClientProvider).get('/student/english');
      if (mounted) setState(() { _data = res.data as Map<String, dynamic>?; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ScreenHeader(title: 'Learn English', subtitle: 'Vocabulary, phrases, and pronunciation'),
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
                Tab(text: 'Word of Day'),
                Tab(text: 'Phrases'),
                Tab(text: 'Practice'),
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
                        _WordTab(data: _data),
                        _PhrasesTab(data: _data),
                        _PracticeTab(data: _data),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _WordTab extends StatelessWidget {
  final Map<String, dynamic>? data;
  const _WordTab({this.data});

  @override
  Widget build(BuildContext context) {
    final word = data?['word_of_day'] as Map<String, dynamic>?;
    if (word == null) return const EmptyState(message: 'No word for today', icon: Icons.abc_rounded);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.violet.withValues(alpha: 0.08), AppColors.violet.withValues(alpha: 0.04)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.violet.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(word['word'] as String? ?? '',
                style: GoogleFonts.fraunces(fontSize: 32, color: AppColors.violet)),
            if (word['phonetic'] != null)
              Text(word['phonetic'] as String,
                  style: GoogleFonts.manrope(fontSize: 14, color: AppColors.mutedForeground)),
            const SizedBox(height: 12),
            if (word['meaning'] != null) ...[
              Text('Meaning:', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text(word['meaning'] as String, style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink)),
            ],
            if (word['example'] != null) ...[
              const SizedBox(height: 12),
              Text('Example:', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text('"${word['example']}"',
                  style: GoogleFonts.manrope(fontSize: 14, color: AppColors.mutedForeground, fontStyle: FontStyle.italic)),
            ],
            if (word['hindi'] != null) ...[
              const SizedBox(height: 12),
              Text('हिंदी:', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text(word['hindi'] as String, style: GoogleFonts.manrope(fontSize: 14, color: AppColors.terracotta)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhrasesTab extends StatelessWidget {
  final Map<String, dynamic>? data;
  const _PhrasesTab({this.data});

  @override
  Widget build(BuildContext context) {
    final phrases = (data?['phrases'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (phrases.isEmpty) return const EmptyState(message: 'No phrases today', icon: Icons.translate_rounded);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: phrases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final p = phrases[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.tintLessonPlan,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p['phrase'] as String? ?? '', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
              if (p['meaning'] != null)
                Text(p['meaning'] as String, style: GoogleFonts.manrope(fontSize: 13, color: AppColors.mutedForeground)),
            ],
          ),
        );
      },
    );
  }
}

class _PracticeTab extends StatelessWidget {
  final Map<String, dynamic>? data;
  const _PracticeTab({this.data});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(message: 'Pronunciation practice coming soon', icon: Icons.mic_outlined);
  }
}
