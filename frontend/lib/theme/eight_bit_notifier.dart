import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 8비트 UI 모드 (기본값 false — 기존 라이트/다크만 쓰는 상태가 디폴트)
class EightBitNotifier extends ValueNotifier<bool> {
  static const _key = 'eight_bit_mode';

  EightBitNotifier() : super(false);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}
