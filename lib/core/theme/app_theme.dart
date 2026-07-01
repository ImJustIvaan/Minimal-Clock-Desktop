import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() => ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          surface: Color(0xFFF8F8F8),
          onSurface: Colors.black,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        useMaterial3: true,
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Color(0xFFF0F0F0),
          indicatorColor: Colors.black12,
        ),
      );

  static ThemeData dark() => ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Color(0xFF0A0A0A),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        useMaterial3: true,
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Color(0xFF111111),
          indicatorColor: Colors.white12,
        ),
      );
}
