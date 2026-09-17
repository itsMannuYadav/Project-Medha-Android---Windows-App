import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/widgets/language_toggle.dart';
import '../../../shared/widgets/medha_logo.dart';

class PrincipalShell extends ConsumerWidget {
  final Widget child;
  const PrincipalShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebar,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: const MedhaLogo(height: 36, circular: true),
        ),
        title: Text('Principal Dashboard',
            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
        actions: [
          const Padding(padding: EdgeInsets.only(right: 4), child: LanguageToggle()),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.destructive),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background.png',
                fit: BoxFit.cover, alignment: const Alignment(0, -0.3)),
          ),
          Positioned.fill(child: Container(color: AppColors.ivory.withValues(alpha: 0.88))),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
