import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Emerald & gold palette with fluid, rounded surfaces.
class AppColors {
  static const emerald = Color(0xFF0E6E5C);
  static const emeraldDeep = Color(0xFF0A4A3F);
  static const emeraldLight = Color(0xFF16A085);
  static const gold = Color(0xFFD4AF37);
  static const goldSoft = Color(0xFFE8CE86);
  static const ink = Color(0xFF10221E);
  static const night = Color(0xFF0B1412);
  static const nightSurface = Color(0xFF12201C);
  static const nightCard = Color(0xFF182A25);
  static const cream = Color(0xFFFBF8F1);
  static const creamCard = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.emerald,
      secondary: AppColors.gold,
      surface: AppColors.cream,
      surfaceContainerHighest: const Color(0xFFEFEAE0),
    );
    return _base(scheme, AppColors.cream);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.emeraldLight,
      secondary: AppColors.gold,
      surface: AppColors.night,
      surfaceContainerHighest: AppColors.nightCard,
    );
    return _base(scheme, AppColors.night);
  }

  static ThemeData _base(ColorScheme scheme, Color scaffold) {
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: 'Roboto',
      splashFactory: InkSparkle.splashFactory,
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
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.nightCard : AppColors.creamCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: isDark ? AppColors.nightSurface : Colors.white,
        elevation: 0,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: scheme.onSurface)),
      ),
      dividerTheme: DividerThemeData(color: scheme.onSurface.withValues(alpha: 0.08), thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.nightCard : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

/// Decorative gradients used across headers and the player.
class Grad {
  static const emerald = LinearGradient(
    colors: [AppColors.emeraldDeep, AppColors.emerald, AppColors.emeraldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const night = LinearGradient(
    colors: [Color(0xFF0A1F1A), Color(0xFF123B32), Color(0xFF0E6E5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gold = LinearGradient(
    colors: [AppColors.gold, AppColors.goldSoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const emeraldDeepBar = LinearGradient(
    colors: [AppColors.emeraldDeep, AppColors.emerald],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
