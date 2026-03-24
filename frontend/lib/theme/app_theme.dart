import 'package:flutter/material.dart';
import 'eight_bit_style.dart';

class AppTheme {
  static const _fontGalmuri = 'Galmuri11';
  /// 브랜드 팔레트: 골든 옐로 + 비비드 오렌지
  static const Color brandYellow = Color(0xFFF7C948);
  static const Color brandOrange = Color(0xFFF6993F);
  /// 졸음 스낵바 등 — 흰 글자 대비용 진한 오렌지
  static const Color drowsyAccent = Color(0xFFD35400);
  /// 자리 이탈 뱃지·테두리 (브랜드 오렌지와 구분되는 톤)
  static const Color awaySeatAccent = Color(0xFFF57C00);

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandYellow,
      brightness: Brightness.light,
    ).copyWith(
      secondary: brandOrange,
      onSecondary: const Color(0xFF3D2200),
      secondaryContainer: const Color(0xFFFFE0B8),
      onSecondaryContainer: const Color(0xFF5C3000),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandYellow,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: brandOrange,
      onSecondary: const Color(0xFF1F1200),
      secondaryContainer: const Color(0xFF6D3D12),
      onSecondaryContainer: const Color(0xFFFFE0B8),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(centerTitle: true),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// 8비트 모드 + 라이트(패미컴·핸드헬드 느낌)
  static ThemeData get eightBitLightTheme {
    const outline = Color(0xFF2c2620);
    const bg = Color(0xFFd8cfa8);
    const surface = Color(0xFFe8dfc4);
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF3cb878),
      onPrimary: Color(0xFF0a1f12),
      primaryContainer: Color(0xFF8fdfaa),
      onPrimaryContainer: Color(0xFF0a1f12),
      secondary: Color(0xFFe8a010),
      onSecondary: Color(0xFF2a1a00),
      secondaryContainer: Color(0xFFffd78a),
      onSecondaryContainer: Color(0xFF2a1a00),
      tertiary: Color(0xFF5c6bc0),
      onTertiary: Color(0xFF0d1020),
      error: Color(0xFFc62828),
      onError: Color(0xFFffffff),
      surface: surface,
      onSurface: Color(0xFF2c2620),
      surfaceContainerHighest: Color(0xFFcfc4a8),
      onSurfaceVariant: Color(0xFF4a4035),
      outline: outline,
      outlineVariant: Color(0xFF6a5c4a),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF2c2620),
      onInverseSurface: Color(0xFFe8dfc4),
      inversePrimary: Color(0xFF8fdfaa),
    );
    return _buildEightBitTheme(scheme, bg, outline);
  }

  /// 8비트 모드 + 다크(야간 픽셀 RPG 느낌)
  static ThemeData get eightBitDarkTheme {
    const outline = Color(0xFF9a93c8);
    const bg = Color(0xFF12101f);
    const surface = Color(0xFF1e1a32);
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF5cf0a8),
      onPrimary: Color(0xFF051a10),
      primaryContainer: Color(0xFF1f6b48),
      onPrimaryContainer: Color(0xFFd4ffe8),
      secondary: Color(0xFFffd54a),
      onSecondary: Color(0xFF2a2000),
      secondaryContainer: Color(0xFF6b5200),
      onSecondaryContainer: Color(0xFFfff4c2),
      tertiary: Color(0xFF82b1ff),
      onTertiary: Color(0xFF0a1528),
      error: Color(0xFFff8a80),
      onError: Color(0xFF2a0a08),
      surface: surface,
      onSurface: Color(0xFFe8e4ff),
      surfaceContainerHighest: Color(0xFF2d2848),
      onSurfaceVariant: Color(0xFFc4bdd8),
      outline: outline,
      outlineVariant: Color(0xFF5c5478),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFe8e4ff),
      onInverseSurface: Color(0xFF12101f),
      inversePrimary: Color(0xFF1f6b48),
    );
    return _buildEightBitTheme(scheme, bg, outline);
  }

  /// 8비트 테마 전용 — inherit 불일치 시 NavigationBar 등에서 TextStyle.lerp 예외가 나므로 false 고정
  static TextStyle _ebText(
    Color color, {
    double fontSize = 14,
    FontWeight? fontWeight,
  }) {
    return TextStyle(
      fontFamily: _fontGalmuri,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      inherit: false,
      height: 1.25,
      // ListTile 등이 textBaseline null이면 defaults.titleTextStyle!.textBaseline! 에서 크래시
      textBaseline: TextBaseline.alphabetic,
    );
  }

  static const TextStyle _ebTextBtn = TextStyle(
    fontFamily: _fontGalmuri,
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  );

  static ThemeData _buildEightBitTheme(
    ColorScheme scheme,
    Color scaffoldBg,
    Color outline,
  ) {
    final borderSide = BorderSide(color: outline, width: 3);
    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontGalmuri,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      extensions: const [EightBitStyle()],
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        shape: Border(bottom: borderSide),
        titleTextStyle:
            _ebText(scheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: borderSide,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          textStyle: _ebTextBtn,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: borderSide,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: _ebTextBtn,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: borderSide,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: _ebTextBtn,
          side: borderSide,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: _ebTextBtn,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        extendedTextStyle: _ebTextBtn,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: borderSide,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((_) {
          return TextStyle(
            fontFamily: _fontGalmuri,
            fontSize: 10,
            inherit: false,
            height: 1.2,
            color: scheme.onSurfaceVariant,
          );
        }),
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: outline, width: 4),
        ),
        titleTextStyle:
            _ebText(scheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
        contentTextStyle: _ebText(scheme.onSurface, fontSize: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.fixed,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: borderSide,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        labelStyle: _ebText(scheme.onSurface, fontSize: 11),
        side: borderSide,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: borderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: scheme.primary, width: 3),
        ),
        labelStyle: _ebText(scheme.onSurfaceVariant, fontSize: 14),
        hintStyle: _ebText(scheme.onSurfaceVariant, fontSize: 14),
      ),
      dividerTheme: DividerThemeData(
        color: outline,
        thickness: 3,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        titleTextStyle: _ebText(scheme.onSurface, fontSize: 14),
        subtitleTextStyle: _ebText(scheme.onSurfaceVariant, fontSize: 11),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.outline;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return scheme.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.all(outline),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: outline, width: 4),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: _ebText(scheme.onSurface, fontSize: 48),
        displayMedium: _ebText(scheme.onSurface, fontSize: 40),
        displaySmall: _ebText(scheme.onSurface, fontSize: 32),
        headlineLarge: _ebText(scheme.onSurface, fontSize: 28),
        headlineMedium: _ebText(scheme.onSurface, fontSize: 24),
        headlineSmall: _ebText(scheme.onSurface, fontSize: 22),
        titleLarge: _ebText(scheme.onSurface, fontSize: 20),
        titleMedium: _ebText(scheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: _ebText(scheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: _ebText(scheme.onSurface, fontSize: 16),
        bodyMedium: _ebText(scheme.onSurface, fontSize: 14),
        bodySmall: _ebText(scheme.onSurfaceVariant, fontSize: 12),
        labelLarge: _ebText(scheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: _ebText(scheme.onSurfaceVariant, fontSize: 12),
        labelSmall: _ebText(scheme.onSurfaceVariant, fontSize: 10),
      ),
    );
  }
}
