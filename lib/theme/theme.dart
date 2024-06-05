import 'package:flutter/material.dart';

class AppTheme {
  // Define primary colors
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color primaryColorLight = Color(0xFF63A4FF);
  static const Color primaryColorDark = Color(0xFF004BA0);
  static const Color secondaryColor = Color(0xFFFFC107);
  static const Color backgroundColor = Color(0xFFE0E0E0);
  static const Color textColor = Color(0xFF212121);
  static const Color errorColor = Color(0xFFD32F2F);

  // Define text styles
  static const TextStyle headline1 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle headline6 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    color: textColor,
  );

  static const TextStyle button = TextStyle(
    fontSize: 18,
    color: Colors.white,
  );

  // Define button styles
  static final ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    textStyle: button,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );

  // Define input decoration
  static InputDecoration inputDecoration(String labelText) {
    return InputDecoration(
      border: OutlineInputBorder(),
      labelText: labelText,
      labelStyle: TextStyle(color: textColor),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
    );
  }

  // Define the overall theme
  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryColor,
      primaryColorLight: primaryColorLight,
      primaryColorDark: primaryColorDark,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        secondary: secondaryColor,
        error: errorColor,
        background: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(),
        labelStyle: TextStyle(color: textColor),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}
