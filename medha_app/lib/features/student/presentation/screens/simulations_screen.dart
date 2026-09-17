import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';

class SimulationsScreen extends ConsumerStatefulWidget {
  const SimulationsScreen({super.key});

  @override
  ConsumerState<SimulationsScreen> createState() => _SimulationsScreenState();
}

class _SimulationsScreenState extends ConsumerState<SimulationsScreen> {
  List<Map<String, dynamic>> _sims = [];
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
      final res = await ref.read(apiClientProvider).get('/simulations');
      final list = res.data as List? ?? [];
      if (mounted) {
        setState(() {
          _sims = list.cast<Map<String, dynamic>>();
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
        const ScreenHeader(title: 'Simulations', subtitle: 'Interactive science labs'),
        Expanded(
          child: _loading
              ? const LoadingBody()
              : _error != null
                  ? ErrorBody(message: _error!, onRetry: _load)
                  : _sims.isEmpty
                      ? const EmptyState(message: 'No simulations available', icon: Icons.science_outlined)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.terracotta,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: _sims.length,
                            itemBuilder: (ctx, i) => _SimCard(sim: _sims[i]),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _SimCard extends StatelessWidget {
  final Map<String, dynamic> sim;
  const _SimCard({required this.sim});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final url = sim['url'] as String?;
        if (url != null) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.inAppWebView);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.tintQuestionPaper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.science_rounded, color: AppColors.violet, size: 22),
            ),
            const Spacer(),
            Text(
              sim['title'] as String? ?? 'Simulation',
              style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (sim['subject'] != null)
              Text(
                sim['subject'] as String,
                style: GoogleFonts.manrope(fontSize: 11, color: AppColors.mutedForeground),
              ),
          ],
        ),
      ),
    );
  }
}
