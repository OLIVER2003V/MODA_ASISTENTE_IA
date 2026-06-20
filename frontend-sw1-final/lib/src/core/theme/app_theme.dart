import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class AppPalette {
  AppPalette._();

  // ═══════════════════════════════════════════════════════════════
  // PALETA NEUTRA Y MODERNA - UNISEX
  // ═══════════════════════════════════════════════════════════════

  // Colores primarios - Azul acero elegante
  static const Color primary = Color(0xFF4A5568);      // Gris azulado principal
  static const Color primaryLight = Color(0xFF718096); // Gris azulado claro
  static const Color primaryDark = Color(0xFF2D3748);  // Gris azulado oscuro

  // Colores de acento - Elegante y versátil
  static const Color accent = Color(0xFF667EEA);       // Índigo moderno
  static const Color accentLight = Color(0xFF7C3AED); // Violeta elegante
  static const Color accentAlt = Color(0xFF3182CE);   // Azul profesional

  // Neutros claros
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAFAFA);
  static const Color lightGray = Color(0xFFF7FAFC);
  static const Color gray100 = Color(0xFFEDF2F7);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E0);

  // Neutros oscuros
  static const Color gray400 = Color(0xFFA0AEC0);
  static const Color gray500 = Color(0xFF718096);
  static const Color gray600 = Color(0xFF4A5568);
  static const Color gray700 = Color(0xFF2D3748);
  static const Color gray800 = Color(0xFF1A202C);
  static const Color gray900 = Color(0xFF171923);

  // Colores de estado
  static const Color success = Color(0xFF38A169);      // Verde elegante
  static const Color successLight = Color(0xFF68D391);
  static const Color error = Color(0xFFE53E3E);        // Rojo sobrio
  static const Color errorLight = Color(0xFFFC8181);
  static const Color warning = Color(0xFFD69E2E);      // Ámbar cálido
  static const Color warningLight = Color(0xFFF6E05E);
  static const Color info = Color(0xFF3182CE);         // Azul informativo

  // Colores especiales para moda
  static const Color gold = Color(0xFFB7791F);         // Dorado sobrio
  static const Color silver = Color(0xFF718096);       // Plateado
  static const Color bronze = Color(0xFF9C4221);       // Bronce

  // Degradados neutros
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [gray800, gray900],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [gray300, gray400],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ═══════════════════════════════════════════════════════════════
  // COLORES LEGACY (para compatibilidad)
  // ═══════════════════════════════════════════════════════════════
  static const Color softCoral = accent;
  static const Color warmBeige = gray200;
  static const Color charcoalGray = gray700;
  static const Color softGray = gray400;
  static const Color pureWhite = white;
  static const Color darkNavy = gray800;
  static const Color charcoal = gray700;
  static const Color softWhite = offWhite;
  static const Color cream = lightGray;
  static const Color peach = accentLight;
  static const Color taupe = gray500;
  static const Color sage = success;
}

class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════
  // TEMA CLARO
  // ═══════════════════════════════════════════════════════════════
  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: AppPalette.accent,
      onPrimary: AppPalette.white,
      primaryContainer: AppPalette.accent.withOpacity(0.1),
      secondary: AppPalette.primary,
      onSecondary: AppPalette.white,
      secondaryContainer: AppPalette.gray200,
      tertiary: AppPalette.accentAlt,
      surface: AppPalette.white,
      onSurface: AppPalette.gray800,
      background: AppPalette.lightGray,
      onBackground: AppPalette.gray800,
      error: AppPalette.error,
      onError: AppPalette.white,
      outline: AppPalette.gray300,
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  // ═══════════════════════════════════════════════════════════════
  // TEMA OSCURO
  // ═══════════════════════════════════════════════════════════════
  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: AppPalette.accent,
      onPrimary: AppPalette.white,
      primaryContainer: AppPalette.accent.withOpacity(0.2),
      secondary: AppPalette.primaryLight,
      onSecondary: AppPalette.white,
      secondaryContainer: AppPalette.gray700,
      tertiary: AppPalette.accentAlt,
      surface: AppPalette.gray800,
      onSurface: AppPalette.gray100,
      background: AppPalette.gray900,
      onBackground: AppPalette.gray100,
      error: AppPalette.errorLight,
      onError: AppPalette.gray900,
      outline: AppPalette.gray600,
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? AppPalette.gray100 : AppPalette.gray800;
    final subtleColor = isDark ? AppPalette.gray300 : AppPalette.gray500;
    final cardColor = isDark ? AppPalette.gray800 : AppPalette.white;
    final scaffoldColor = isDark ? AppPalette.gray900 : AppPalette.lightGray;
    final dividerColor = isDark ? AppPalette.gray700 : AppPalette.gray200;

    final baseTextTheme = Typography.englishLike2021.apply(
      bodyColor: textColor,
      displayColor: textColor,
      fontFamily: 'SF Pro Display',
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldColor,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          color: textColor,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
          color: textColor,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: textColor,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          height: 1.5,
          color: textColor,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          height: 1.5,
          color: subtleColor,
        ),
      ),
      appBarTheme: AppBarTheme(
        surfaceTintColor: Colors.transparent,
        backgroundColor: cardColor,
        foregroundColor: textColor,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 24,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: colorScheme.error.withOpacity(0.5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: TextStyle(
          color: subtleColor,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: subtleColor.withOpacity(0.7),
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return isDark ? AppPalette.gray700 : AppPalette.gray300;
            }
            return colorScheme.primary;
          }),
          foregroundColor: WidgetStatePropertyAll(AppPalette.white),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          ),
          elevation: WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            baseTextTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppPalette.white,
            ),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            isDark ? AppPalette.gray700 : AppPalette.gray800,
          ),
          foregroundColor: WidgetStatePropertyAll(AppPalette.white),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          ),
          elevation: WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(colorScheme.primary),
          textStyle: WidgetStatePropertyAll(
            baseTextTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(colorScheme.primary),
          side: WidgetStatePropertyAll(
            BorderSide(color: colorScheme.primary, width: 2),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        margin: EdgeInsets.zero,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
          side: BorderSide(
            color: dividerColor,
            width: 1,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppPalette.gray700.withOpacity(0.5)
            : AppPalette.gray200,
        selectedColor: colorScheme.primary,
        labelStyle: baseTextTheme.labelLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        shape: StadiumBorder(
          side: BorderSide(color: dividerColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppPalette.gray800 : cardColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppPalette.gray800 : cardColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: isDark ? AppPalette.gray200 : AppPalette.gray700,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppPalette.gray700 : AppPalette.gray800,
        contentTextStyle: TextStyle(color: AppPalette.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: subtleColor,
        textColor: textColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return isDark ? AppPalette.gray500 : AppPalette.gray400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withOpacity(0.3);
          }
          return isDark ? AppPalette.gray700 : AppPalette.gray300;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return subtleColor;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(AppPalette.white),
        side: BorderSide(color: subtleColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: dividerColor,
        circularTrackColor: dividerColor,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: AppPalette.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
