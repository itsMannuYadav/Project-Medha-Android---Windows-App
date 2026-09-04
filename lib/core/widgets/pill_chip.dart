import 'package:flutter/material.dart';

import '../theme/medha_colors.dart';
import '../theme/medha_radii.dart';

/// A small rounded tag — used for subject/grade tags, filter chips, and
/// status badges. [selected] swaps to the filled/active look.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    this.selected = false,
    this.background,
    this.foreground,
    this.onTap,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final Color? background;
  final Color? foreground;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final bg = background ?? (selected ? MedhaColors.primary : MedhaColors.surface2);
    final fg = foreground ?? (selected ? Colors.white : MedhaColors.inkSoft);

    final chip = Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 14, vertical: dense ? 5 : 9),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(MedhaRadii.pill)),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Hind',
          fontSize: dense ? 11.5 : 13,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );

    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(MedhaRadii.pill),
      child: InkWell(borderRadius: BorderRadius.circular(MedhaRadii.pill), onTap: onTap, child: chip),
    );
  }
}
