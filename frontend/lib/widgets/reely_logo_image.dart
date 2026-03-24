import 'package:flutter/material.dart';
import '../theme/eight_bit_style.dart';

/// 라이트 모드에서는 어두운 글자 로고, 다크 모드에서는 기존 투명 배경 로고 사용
class ReelyLogoImage extends StatelessWidget {
  const ReelyLogoImage({
    super.key,
    this.size = 100,
    this.borderRadius = 24,
  });

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/app_icon_nonbackground.png'
        : 'assets/app_icon_light_mode.png';

    final pixel = Theme.of(context).extension<EightBitStyle>() != null;
    return ClipRRect(
      borderRadius:
          pixel ? BorderRadius.zero : BorderRadius.circular(borderRadius),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        semanticLabel: 'Reely',
      ),
    );
  }
}
