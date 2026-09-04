import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders one of the hand-drawn stroke icons from `assets/icons/`.
///
/// The source SVGs are monochrome (stroke="#000000"); [color] recolors the
/// whole icon via a tint filter, matching the currentColor pattern used in
/// the design canvas.
class MedhaIcon extends StatelessWidget {
  const MedhaIcon(this.name, {super.key, this.size = 20, required this.color});

  final String name;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
