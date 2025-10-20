import 'package:flutter/material.dart';
import '../core/config/app_config.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConfig.primaryColor,
        brightness: Brightness.light,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppConfig.backgroundPrimary,
        foregroundColor: AppConfig.textPrimary,
        titleTextStyle: TextStyle(
          color: AppConfig.textPrimary,
          fontSize: AppConfig.fontSizeXL,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: AppConfig.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        color: AppConfig.backgroundCard,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConfig.spacingL,
            vertical: AppConfig.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConfig.spacingM,
            vertical: AppConfig.spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          borderSide: const BorderSide(color: AppConfig.textHint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          borderSide: const BorderSide(color: AppConfig.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          borderSide: const BorderSide(color: AppConfig.errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConfig.spacingM,
          vertical: AppConfig.spacingM,
        ),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: AppConfig.fontSizeHeadline,
          fontWeight: FontWeight.bold,
          color: AppConfig.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: AppConfig.fontSizeTitle,
          fontWeight: FontWeight.bold,
          color: AppConfig.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: AppConfig.fontSizeXXL,
          fontWeight: FontWeight.w600,
          color: AppConfig.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: AppConfig.fontSizeXL,
          fontWeight: FontWeight.w600,
          color: AppConfig.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: AppConfig.fontSizeL,
          fontWeight: FontWeight.w600,
          color: AppConfig.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: AppConfig.fontSizeM,
          fontWeight: FontWeight.w500,
          color: AppConfig.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: AppConfig.fontSizeL,
          color: AppConfig.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: AppConfig.fontSizeM,
          color: AppConfig.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: AppConfig.fontSizeS,
          color: AppConfig.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: AppConfig.fontSizeM,
          fontWeight: FontWeight.w500,
          color: AppConfig.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: AppConfig.fontSizeS,
          color: AppConfig.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: AppConfig.fontSizeXS,
          color: AppConfig.textHint,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppConfig.textSecondary,
        size: AppConfig.iconSizeM,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 8,
        backgroundColor: AppConfig.backgroundCard,
        selectedItemColor: AppConfig.primaryColor,
        unselectedItemColor: AppConfig.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppConfig.textHint,
        thickness: 1,
        space: 1,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppConfig.backgroundSecondary,
        selectedColor: AppConfig.primaryColor,
        labelStyle: const TextStyle(color: AppConfig.textPrimary),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConfig.spacingM,
          vertical: AppConfig.spacingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConfig.primaryColor,
        brightness: Brightness.dark,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF121212),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: AppConfig.fontSizeXL,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: AppConfig.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        color: const Color(0xFF1E1E1E),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConfig.spacingL,
            vertical: AppConfig.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConfig.spacingM,
            vertical: AppConfig.spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          borderSide: const BorderSide(color: AppConfig.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          borderSide: const BorderSide(color: AppConfig.errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConfig.spacingM,
          vertical: AppConfig.spacingM,
        ),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: AppConfig.fontSizeHeadline,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: AppConfig.fontSizeTitle,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontSize: AppConfig.fontSizeXXL,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: AppConfig.fontSizeXL,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: AppConfig.fontSizeL,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: AppConfig.fontSizeM,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: AppConfig.fontSizeL,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: AppConfig.fontSizeM,
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          fontSize: AppConfig.fontSizeS,
          color: Color(0xFFB0B0B0),
        ),
        labelLarge: TextStyle(
          fontSize: AppConfig.fontSizeM,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontSize: AppConfig.fontSizeS,
          color: Color(0xFFB0B0B0),
        ),
        labelSmall: TextStyle(
          fontSize: AppConfig.fontSizeXS,
          color: Color(0xFF757575),
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: Color(0xFFB0B0B0),
        size: AppConfig.iconSizeM,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 8,
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: AppConfig.primaryColor,
        unselectedItemColor: Color(0xFFB0B0B0),
        type: BottomNavigationBarType.fixed,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFF424242),
        thickness: 1,
        space: 1,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2E2E2E),
        selectedColor: AppConfig.primaryColor,
        labelStyle: const TextStyle(color: Colors.white),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConfig.spacingM,
          vertical: AppConfig.spacingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
      ),
    );
  }
}

