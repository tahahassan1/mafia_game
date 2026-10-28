import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppColors {
  static const Color brandPrimary = Color(0xFFD62828);
  static const Color onBrandPrimary = Color(0xFFFFFFFF);
  static const Color canvas = Color(0xFF0B0B0B);
  static const Color surface = Color(0xFF161616);
  static const Color surfaceRaised = Color(0xFF202020);
  static const Color ink = Color(0xFFF5F1E8);
  static const Color textSecondary = Color(0xFFA8A29A);
  static const Color divider = Color(0xFF2E2E2E);
  static const Color danger = Color(0xFFFF5A52);
  static const Color dangerSurface = Color(0xFF2A1010);
  static const Color teamMafia = brandPrimary;
  static const Color teamCivilian = ink;
  static const Color teamNeutral = Color(0xFFE3B23C);
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double screenInset = md;
  static const double screenInsetWide = lg;
}

abstract final class AppRadii {
  static const double control = 4;
  static const double card = 4;
  static const double timer = 0;
  static const double sheetTop = 4;
  static const BorderRadius controlBorder = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius cardBorder = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius sheetTopBorder = BorderRadius.vertical(
    top: Radius.circular(sheetTop),
  );
}

abstract final class AppBorders {
  static const double strong = 3;
  static const double quiet = 1.5;
}

abstract final class AppSizes {
  static const double minControlHeight = 56;
  static const double minTouchTarget = 48;
  static const double lottieDefault = 160;
  static const double lottiePlaceholder = 180;
  static const double contentMaxWidth = 480;
}

abstract final class AppShadows {
  static const Offset hardOffset = Offset(4, 4);
  static const List<BoxShadow> primaryButton = <BoxShadow>[
    BoxShadow(color: AppColors.ink, offset: hardOffset),
  ];
  static const List<BoxShadow> revealCard = <BoxShadow>[
    BoxShadow(color: AppColors.brandPrimary, offset: hardOffset),
  ];

  static List<BoxShadow> hard(Color color) => <BoxShadow>[
    BoxShadow(color: color, offset: hardOffset),
  ];
}

abstract final class AppDecorations {
  static BoxDecoration hardShadow({
    required Color color,
    required Color shadowColor,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius,
      border: border,
      boxShadow: AppShadows.hard(shadowColor),
    );
  }
}

abstract final class AppFonts {
  static const String cairo = 'Cairo';
}

abstract final class AppStyles {
  static const TextStyle timerDigits = TextStyle(
    fontFamily: AppFonts.cairo,
    fontSize: 80,
    height: 88 / 80,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const TextStyle roleName = TextStyle(
    fontFamily: AppFonts.cairo,
    fontSize: 44,
    height: 56 / 44,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const TextStyle handoffName = TextStyle(
    fontFamily: AppFonts.cairo,
    fontSize: 36,
    height: 48 / 36,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const TextStyle screenTitle = TextStyle(
    fontFamily: AppFonts.cairo,
    fontSize: 24,
    height: 34 / 24,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const TextStyle sectionHeading = TextStyle(
    fontFamily: AppFonts.cairo,
    fontSize: 18,
    height: 28 / 18,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: AppFonts.cairo,
    fontSize: 16,
    height: 26 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.cairo,
    fontSize: 16,
    height: 26 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontFamily: AppFonts.cairo,
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle supporting = TextStyle(
    fontFamily: AppFonts.cairo,
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle metadata = TextStyle(
    fontFamily: AppFonts.cairo,
    fontSize: 12,
    height: 20 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextTheme textTheme = TextTheme(
    displayLarge: timerDigits,
    displayMedium: roleName,
    displaySmall: handoffName,
    headlineLarge: screenTitle,
    headlineMedium: screenTitle,
    headlineSmall: screenTitle,
    titleLarge: sectionHeading,
    titleMedium: sectionHeading,
    titleSmall: bodyStrong,
    bodyLarge: bodyStrong,
    bodyMedium: body,
    bodySmall: supporting,
    labelLarge: buttonLabel,
    labelMedium: bodyStrong,
    labelSmall: metadata,
  );
}

abstract final class AppColorScheme {
  static const ColorScheme dark = ColorScheme.dark(
    primary: AppColors.brandPrimary,
    onPrimary: AppColors.onBrandPrimary,
    secondary: AppColors.ink,
    onSecondary: AppColors.canvas,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    error: AppColors.danger,
    onError: AppColors.canvas,
    outline: AppColors.divider,
  );
}

abstract final class AppSystemUi {
  static const SystemUiOverlayStyle overlay = SystemUiOverlayStyle(
    statusBarColor: AppColors.canvas,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.canvas,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: AppColors.canvas,
    systemNavigationBarContrastEnforced: false,
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: AppFonts.cairo,
    colorScheme: AppColorScheme.dark,
    scaffoldBackgroundColor: AppColors.canvas,
    canvasColor: AppColors.canvas,
    cardColor: AppColors.surface,
    dividerColor: AppColors.divider,
    textTheme: AppStyles.textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
