import 'package:flutter/material.dart';
import 'eight_bit_style.dart';

/// 일반 테마는 [circular], 8비트 모드에서는 직각
BorderRadius reelyRadius(BuildContext context, double circular) {
  if (Theme.of(context).extension<EightBitStyle>() != null) {
    return BorderRadius.zero;
  }
  return BorderRadius.circular(circular);
}

bool isEightBitContext(BuildContext context) =>
    Theme.of(context).extension<EightBitStyle>() != null;
