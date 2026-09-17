import 'package:flutter/material.dart';

class MedhaLogo extends StatelessWidget {
  final double height;
  final bool circular;

  const MedhaLogo({super.key, this.height = 80, this.circular = false});

  @override
  Widget build(BuildContext context) {
    // Decode at display size. Without cacheWidth Flutter decodes the full
    // source into memory regardless of how small it is drawn, which is real
    // pressure on the 1-2GB devices this app targets.
    final cacheWidth =
        (height * MediaQuery.devicePixelRatioOf(context)).round();

    if (circular) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Image.asset(
          'assets/images/logo.jpg',
          width: height,
          height: height,
          cacheWidth: cacheWidth,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      'assets/images/logo.jpg',
      height: height,
      cacheWidth: cacheWidth,
      fit: BoxFit.contain,
    );
  }
}
