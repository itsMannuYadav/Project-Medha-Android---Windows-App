import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Mirrors app/(protected)/(app)/dashboard/page.tsx exactly, verified against
/// the live site 2026-09-17. The real teacher dashboard's core purpose is AI
/// content generation (lesson plans, presentations, question papers, quizzes,
/// notes) with a "Recent" feed — NOT a stats/attendance summary, which is
/// what an earlier version of this screen incorrectly built. See
/// lib/generation-types.ts for the full type/param/content schema.
///
/// SCOPE NOTE: the five creation flows (two with dedicated 2-step wizards —
/// lesson_plan, quiz, question_paper — plus a generic form for presentation/
/// notes) are a large, separate undertaking (SSE-streamed generation, per-
/// type parameter forms, per-type content viewers/editors, PDF/PPTX export).
/// Deliberately NOT built here — this screen is the correctly-shaped entry
/// point (hero, Ask Medha launcher, Quick Action tiles, real Recent list via
/// GET /generations) with each Quick Action tile showing "Coming soon" until
/// its creation flow exists. Building fake/stub creation screens instead
/// would be worse than an honest placeholder.
class _GenType {
  final String id, label, desc;
  final IconData icon;
  final Color tint, fill;
  const _GenType(this.id, this.label, this.desc, this.icon, this.tint, this.fill);
}

const _genTypes = [
  _GenType('lesson_plan', 'Create Lesson Plan', 'Step-by-step teaching plan for your class',
      Icons.edit_note_rounded, AppColors.tintLessonPlan, AppColors.fillLessonPlan),
  _GenType('presentation', 'Create Presentation', 'Engaging slides for your class',
      Icons.slideshow_rounded, AppColors.tintPresentation, AppColors.fillPresentation),
  _GenType('question_paper', 'Create Question Paper', 'Generate questions with answers',
      Icons.quiz_outlined, AppColors.tintQuestionPaper, AppColors.fillQuestionPaper),
  _GenType('quiz', 'Create Quiz', 'Interactive quiz for students',
      Icons.help_outline_rounded, AppColors.tintQuiz, AppColors.fillQuiz),
  _GenType('notes', 'Create Notes', 'Simple and clear notes',
      Icons.description_outlined, AppColors.tintNotes, AppColors.fillNotes),
];

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends ConsumerState<TeacherDashboardScreen> {
  List<Map<String, dynamic>>? _recent;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    try {
      final res = await ref.read(apiClientProvider).get('/generations', queryParameters: {'limit': 6});
      final list = (res.data as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _recent = list);
    } catch (_) {
      if (mounted) setState(() => _recent = []);
    }
  }

  void _showComingSoon(BuildContext context, String label) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top_rounded, color: AppColors.gold, size: 40),
            const SizedBox(height: 12),
            Text('$label — coming soon',
                style: GoogleFonts.fraunces(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 8),
            Text('This content-generation flow isn\'t built yet in the app.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 13, color: AppColors.mutedForeground)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull?.user;
    final firstName = user?.firstName ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero header — avatar/notifications row, greeting, hero tagline + tricolor rule.
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => context.go('/notifications'),
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.mutedForeground),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.terracotta.withValues(alpha: 0.15),
                child: Text((user?.initials() ?? '?'),
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.terracotta)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Hello, $firstName 👋',
              style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text('What should we make today?',
              style: GoogleFonts.manrope(fontSize: 14, color: AppColors.mutedForeground)),
          const SizedBox(height: 16),
          Text('बड़े सपने शिक्षा के साथ',
              style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.earth)),
          const SizedBox(height: 4),
          Container(
            height: 3, width: 64,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.saffron, AppColors.tricolorWhite, AppColors.tricolorGreen]),
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          const SizedBox(height: 16),

          // Ask Medha launcher pill — links straight to /ask, matching the web
          // app's AskMedhaBar (a launcher, not an inline composer).
          GestureDetector(
            onTap: () => context.go('/ask'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.violetMuted,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.violet.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.violet, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Ask Medha anything…',
                        style: GoogleFonts.manrope(fontSize: 15, color: AppColors.mutedForeground)),
                  ),
                  const Icon(Icons.mic_none_rounded, color: AppColors.violet, size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text('QUICK ACTIONS',
              style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.mutedForeground)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.15,
            children: _genTypes.take(4).map((t) => _QuickActionTile(type: t, onTap: () => _showComingSoon(context, t.label))).toList(),
          ),
          const SizedBox(height: 10),
          _QuickActionTile(type: _genTypes.last, wide: true, onTap: () => _showComingSoon(context, _genTypes.last.label)),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RECENT',
                  style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.mutedForeground)),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text('View all',
                        style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.terracotta)),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.terracotta),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_recent == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.terracotta)),
            )
          else if (_recent!.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.hairline, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text('No generations yet — try a Quick Action above.',
                    style: GoogleFonts.manrope(fontSize: 13, color: AppColors.mutedForeground)),
              ),
            )
          else
            ..._recent!.map((g) => _GenerationRow(item: g)),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tintNotes.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: AppColors.gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.manrope(fontSize: 13, color: AppColors.ink),
                      children: [
                        TextSpan(text: 'हर बच्चे में सीखने की अनंत संभावना है। ',
                            style: GoogleFonts.manrope(fontStyle: FontStyle.italic)),
                        TextSpan(text: '– मेधा', style: TextStyle(color: AppColors.mutedForeground)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _QuickActionTile extends StatelessWidget {
  final _GenType type;
  final bool wide;
  final VoidCallback onTap;
  const _QuickActionTile({required this.type, required this.onTap, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.hairline.withValues(alpha: 0.6)),
        ),
        child: wide
            ? Row(
                children: [
                  _iconChip(),
                  const SizedBox(width: 12),
                  Expanded(child: _labelBlock()),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.mutedForeground),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconChip(),
                  const Spacer(),
                  _labelBlock(),
                ],
              ),
      ),
    );
  }

  Widget _iconChip() => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: type.tint, borderRadius: BorderRadius.circular(10)),
        child: Icon(type.icon, color: type.fill, size: 18),
      );

  Widget _labelBlock() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type.label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(type.desc, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(fontSize: 11, color: AppColors.mutedForeground)),
        ],
      );
}

class _GenerationRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _GenerationRow({required this.item});

  static final _typeById = { for (final t in _genTypes) t.id: t };

  @override
  Widget build(BuildContext context) {
    final typeId = item['type'] as String? ?? 'notes';
    final meta = _typeById[typeId] ?? _genTypes.last;
    final title = item['title'] as String? ?? '';
    final gradeLabel = item['grade_label'] as String?;
    final subjectName = item['subject_name'] as String?;
    final subtitle = [gradeLabel, subjectName].where((s) => s != null && s.isNotEmpty).join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: meta.tint, borderRadius: BorderRadius.circular(10)),
            child: Icon(meta.icon, color: meta.fill, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(fontSize: 13, color: AppColors.ink)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(fontSize: 11, color: AppColors.mutedForeground)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.mutedForeground),
        ],
      ),
    );
  }
}
