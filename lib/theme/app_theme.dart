import 'package:flutter/material.dart';

/// NER-SHIELD design tokens.
abstract final class AppColors {
  static const primary = Color(0xFF1B2A4A);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFD9E2FF);
  static const onPrimaryContainer = Color(0xFF001945);
  static const secondary = Color(0xFF55607A);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFDAE2F9);
  static const onSecondaryContainer = Color(0xFF121D32);
  static const surface = Color(0xFFFDFCFF);
  static const surfaceVariant = Color(0xFFE1E2EC);
  static const onSurface = Color(0xFF1A1C1E);
  static const onSurfaceVariant = Color(0xFF44464E);
  static const outline = Color(0xFF757780);

  // Safety/status — always used WITH labels/icons, never color alone.
  static const okGreen = Color(0xFF1E7A3C);
  static const warnAmber = Color(0xFF9A6A00);
  static const dangerRed = Color(0xFFBA1A1A);
  static const unknownGray = Color(0xFF5E5E66);
  static const infoBlue = Color(0xFF00639C);
  static const emergency = Color(0xFF991B1B);
  static const emergencyBg = Color(0xFFFFEDED);
}

/// NER-SHIELD Material 3 theme factory (docs/ui-ux-plan.md §design language).
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      error: AppColors.dangerRed,
      onError: Colors.white,
      errorContainer: AppColors.emergencyBg,
      onErrorContainer: AppColors.emergency,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: Color(0xFFC4C6D0),
    );
    return _build(scheme);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFB4C5FF),
      onPrimary: Color(0xFF173060),
      primaryContainer: Color(0xFF2E4771),
      onPrimaryContainer: AppColors.primaryContainer,
      secondary: Color(0xFFBEC6DE),
      onSecondary: Color(0xFF283248),
      secondaryContainer: Color(0xFF3E4860),
      onSecondaryContainer: AppColors.secondaryContainer,
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF121317),
      onSurface: Color(0xFFE2E2E9),
      surfaceContainerHighest: Color(0xFF27282E),
      onSurfaceVariant: Color(0xFFC4C6D0),
      outline: Color(0xFF8E9099),
      outlineVariant: Color(0xFF44464E),
    );
    return _build(scheme);
  }

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    );
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: base.chipTheme.copyWith(
        side: const BorderSide(color: Colors.transparent),
        labelStyle: base.textTheme.labelMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    );
  }
}

extension AppThemeExtension on BuildContext {
  ThemeData get appTheme => Theme.of(this);
}