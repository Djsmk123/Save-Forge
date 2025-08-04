import 'package:fluent_ui/fluent_ui.dart';

class AppTheme {
  final ThemeMode themeMode;
  final FluentThemeData lightTheme;
  final FluentThemeData darkTheme;

  const AppTheme({
    required this.themeMode,
    required this.lightTheme,
    required this.darkTheme,
  });

  factory AppTheme.defaultTheme() => AppTheme(
        themeMode: ThemeMode.dark,
        lightTheme: _defaultDarkTheme,
        darkTheme: _defaultDarkTheme,
      );

  AppTheme copyWith({
    ThemeMode? themeMode,
    FluentThemeData? lightTheme,
    FluentThemeData? darkTheme,
  }) {
    return AppTheme(
      themeMode: themeMode ?? this.themeMode,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
    );
  }
}

class AppColors {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF0078D4);
  static const Color primaryPurple = Color(0xFF5B2BD9);
  static const Color primaryGreen = Color(0xFF107C10);
  static const Color primaryOrange = Color(0xFFD83B01);

  // Accent Colors
  static const Color accentBlue = Color(0xFF106EBE);
  static const Color accentPurple = Color(0xFF6B69D6);
  static const Color accentGreen = Color(0xFF107C10);
  static const Color accentOrange = Color(0xFFD83B01);

  // Neutral Colors
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralBlack = Color(0xFF000000);
  static const Color neutralGray10 = Color(0xFFFAFAFA);
  static const Color neutralGray20 = Color(0xFFF3F2F1);
  static const Color neutralGray30 = Color(0xFFEDEBE9);
  static const Color neutralGray40 = Color(0xFFE1DFDD);
  static const Color neutralGray50 = Color(0xFFC8C6C4);
  static const Color neutralGray60 = Color(0xFF8A8886);
  static const Color neutralGray70 = Color(0xFF605E5C);
  static const Color neutralGray80 = Color(0xFF323130);
  static const Color neutralGray90 = Color(0xFF201F1E);
  static const Color neutralGray100 = Color(0xFF0C0C0C);

  // Semantic Colors
  static const Color success = Color(0xFF107C10);
  static const Color warning = Color(0xFFD83B01);
  static const Color error = Color(0xFFD13438);
  static const Color info = Color(0xFF0078D4);

  // Glass Effect Colors
  static const Color glassLight = Color(0x1AFFFFFF);
  static const Color glassDark = Color(0x1A000000);
  static const Color glassBorderLight = Color(0x80FFFFFF);
  static const Color glassBorderDark = Color(0x80000000);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF0078D4),
    Color(0xFF5B2BD9),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF107C10),
    Color(0xFFD83B01),
  ];

  static const List<Color> glassGradientLight = [
    Color(0x1AFFFFFF),
    Color(0x0DFFFFFF),
  ];

  static const List<Color> glassGradientDark = [
    Color(0x1A000000),
    Color(0x0D000000),
  ];
}

class AppTypography {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
}


FluentThemeData get _defaultDarkTheme {
  return FluentThemeData(
    brightness: Brightness.dark,
    accentColor: Colors.blue,
    visualDensity: VisualDensity.standard,
    focusTheme: FocusThemeData(
      glowFactor: 0.0,
    ),
  );
} 