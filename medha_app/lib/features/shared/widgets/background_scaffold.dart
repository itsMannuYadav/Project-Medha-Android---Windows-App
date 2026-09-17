import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Scaffold with the Nalanda watercolour backdrop — same as the Next.js app's
/// dashboard-background.png with the ivory gradient overlay.
class BackgroundScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const BackgroundScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: appBar,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          // Nalanda watercolour background
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.3),
            ),
          ),
          // Ivory wash overlay (matching from-ivory/90 via-ivory/78 to-ivory/90)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.ivory.withValues(alpha: 0.92),
                    AppColors.ivory.withValues(alpha: 0.80),
                    AppColors.ivory.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
