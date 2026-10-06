import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Noor design tokens — deep emerald + antique gold, tuned for contrast
/// and a calm, premium feel in both light and dark.
class AppColors {
  // Brand
  static const emerald = Color(0xFF0E6E5C);
  static const emeraldDeep = Color(0xFF0A4A3F);
  static const emeraldLight = Color(0xFF16A085);
  static const emeraldMist = Color(0xFFE6F2EF);

  static const gold = Color(0xFFD4AF37);
  static const goldSoft = Color(0xFFE8CE86);
  static const goldDeep = Color(0xFFB08A24);

  // Neutrals — light
  static const ink = Color(0xFF0F1F1B);
  static const inkSoft = Color(0xFF44544F);
  static const cream = Color(0xFFF7F4EC);
  static const creamCard = Color(0xFFFFFFFF);
  static const line = Color(0xFFE3DED2);

  // Neutrals — dark
  static const night = Color(0xFF0A1311);
  static const nightSurface = Color(0xFF0F1C19);
  static const nightCard = Color(0xFF162824);
  static const nightLine = Color(0xFF24382F);
}

/// Curated gradients used across headers, cards and the player.
class Grad {
  static const emerald = LinearGradient(
    colors: [AppColors.emeraldDeep, AppColors.emerald, AppColors.emeraldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const emeraldSoft = LinearGradient(
    colors: [Color(0xFF125E50), Color(0xFF0E6E5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const night = LinearGradient(
    colors: [Color(0xFF081714), Color(0xFF0E3B31), Color(0xFF0E6E5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gold = LinearGradient(
    colors: [AppColors.goldDeep, AppColors.gold, AppColors.goldSoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const goldSheen = LinearGradient(
    colors: [Color(0xFFF3E3B0), AppColors.goldSoft, AppColors.gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Motion tokens — one easing curve and a small set of durations so the whole
/// app feels like it was designed by one hand.
class Motion {
  static const curve = Curves.easeOutCubic;
  static const fast = Duration(milliseconds: 180);
  static const med = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 560);

  /// Slightly springy curve for entrances that should feel alive.
  static const spring = Curves.easeOutBack;

  /// Elevation shadows, in one place so every surface casts the same light.
  static List<BoxShadow> shadow(Color tint, {double alpha = 0.06, double blur = 18, double y = 6}) =>
      [BoxShadow(color: tint.withValues(alpha: alpha), blurRadius: blur, offset: Offset(0, y))];

  static List<BoxShadow> glow(Color color, {double alpha = 0.35, double blur = 28, double y = 12}) =>
      [BoxShadow(color: color.withValues(alpha: alpha), blurRadius: blur, offset: Offset(0, y))];
}

class AppTheme {
  static const _font = 'Jakarta';

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.emerald,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      surface: AppColors.cream,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.emeraldMist,
      outlineVariant: AppColors.line,
    );
    return _base(scheme, AppColors.cream, false);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.emeraldLight,
      onPrimary: const Color(0xFF00201A),
      secondary: AppColors.goldSoft,
      onSecondary: AppColors.ink,
      surface: AppColors.night,
      onSurface: const Color(0xFFEAF3F0),
      surfaceContainerHighest: AppColors.nightCard,
      outlineVariant: AppColors.nightLine,
    );
    return _base(scheme, AppColors.night, true);
  }

  static ThemeData _base(ColorScheme scheme, Color scaffold, bool isDark) {
    final txt = _textTheme(scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: _font,
      textTheme: txt,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: txt.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.nightCard : AppColors.creamCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 12.5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: isDark ? AppColors.nightSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: -0.1, color: scheme.onSurface),
        ),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: scheme.onSurface.withValues(alpha: 0.7))),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.6), thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? AppColors.nightCard : AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.nightSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        showDragHandle: true,
      ),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.nightCard : Colors.white,
        hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.4), fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primary.withValues(alpha: 0.18),
        thumbColor: scheme.primary,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final on = scheme.onSurface;
    return TextTheme(
      displaySmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1.0, color: on, height: 1.1),
      headlineMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.7, color: on, height: 1.15),
      headlineSmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: on, height: 1.2),
      titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4, color: on, fontSize: 20),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2, color: on, fontSize: 16),
      titleSmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.1, color: on, fontSize: 14),
      bodyLarge: TextStyle(fontWeight: FontWeight.w500, color: on, fontSize: 15, height: 1.45),
      bodyMedium: TextStyle(fontWeight: FontWeight.w500, color: on.withValues(alpha: 0.85), fontSize: 13.5, height: 1.45),
      bodySmall: TextStyle(fontWeight: FontWeight.w500, color: on.withValues(alpha: 0.6), fontSize: 12, height: 1.4),
      labelLarge: TextStyle(fontWeight: FontWeight.w700, color: on, fontSize: 13.5, letterSpacing: -0.1),
      labelSmall: TextStyle(fontWeight: FontWeight.w700, color: on.withValues(alpha: 0.6), fontSize: 10.5, letterSpacing: 0.6),
    );
  }
}
