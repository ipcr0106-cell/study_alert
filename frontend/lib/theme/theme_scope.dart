import 'package:flutter/material.dart';
import 'eight_bit_notifier.dart';
import 'theme_notifier.dart';

/// main·설정 등에서 [ThemeNotifier]·[EightBitNotifier]에 접근하기 위한 InheritedWidget
class ThemeScopeInherited extends InheritedWidget {
  final ThemeNotifier themeNotifier;
  final EightBitNotifier eightBitNotifier;

  const ThemeScopeInherited({
    super.key,
    required this.themeNotifier,
    required this.eightBitNotifier,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant ThemeScopeInherited oldWidget) =>
      themeNotifier != oldWidget.themeNotifier ||
      eightBitNotifier != oldWidget.eightBitNotifier;
}

/// 앱 루트에서 테마 노티파이어를 하위에 전달
class ThemeScope extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  final EightBitNotifier eightBitNotifier;
  final Widget child;

  const ThemeScope({
    super.key,
    required this.themeNotifier,
    required this.eightBitNotifier,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ThemeScopeInherited(
      themeNotifier: themeNotifier,
      eightBitNotifier: eightBitNotifier,
      child: child,
    );
  }
}
