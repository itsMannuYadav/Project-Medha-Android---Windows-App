import 'package:flutter/material.dart';

import '../theme/medha_colors.dart';
import '../theme/medha_radii.dart';

/// The standard white, hairline-bordered, softly-shadowed surface used for
/// cards throughout the app (module cards, tool cards, settings rows...).
class MedhaCard extends StatelessWidget {
  const MedhaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: MedhaColors.surface,
        borderRadius: BorderRadius.circular(MedhaRadii.lg),
        border: Border.all(color: MedhaColors.border),
        boxShadow: const [
          BoxShadow(color: MedhaColors.shadow, blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(MedhaRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(MedhaRadii.lg),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
