import 'package:flutter/material.dart';

class KotobFMLogo extends StatelessWidget {
  static const String assetPath = 'assets/generated/kotob_fm_logo.png';
  static const double _aspectRatio = 816 / 317;

  final double height;
  final Color? kColor;
  final Color? otobColor;
  final Color? fmColor;
  final bool showTrademark;

  const KotobFMLogo({
    super.key,
    this.height = 80,
    this.kColor,
    this.otobColor,
    this.fmColor,
    this.showTrademark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: height,
      width: height * _aspectRatio,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      semanticLabel: 'Kotob FM',
    );
  }
}
