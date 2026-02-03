import 'package:flutter/material.dart';

class AppTheme {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static void toggleFromBrightness(Brightness brightness) {
    final isDarkNow = brightness == Brightness.dark;
    mode.value = isDarkNow ? ThemeMode.light : ThemeMode.dark;
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.green,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: Colors.green,
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
