import 'package:flutter/material.dart';

import '../theme/medha_colors.dart';

/// A round initials avatar — the fallback every screen uses instead of a
/// photo, since most teacher accounts won't have one.
class AvatarInitials extends StatelessWidget {
  const AvatarInitials({
    super.key,
    required this.initials,
    this.size = 30,
    this.background = MedhaColors.primary,
    this.foreground = Colors.white,
  });

  final String initials;
  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Hind',
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
