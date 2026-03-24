import 'package:flutter/material.dart';

/// 8비트(레트로) 테마 활성 여부 마커 — [ThemeData.extensions]에만 등록
@immutable
class EightBitStyle extends ThemeExtension<EightBitStyle> {
  const EightBitStyle();

  @override
  EightBitStyle copyWith() => this;

  @override
  EightBitStyle lerp(ThemeExtension<EightBitStyle>? other, double t) => this;
}
