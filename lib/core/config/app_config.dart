import 'package:flutter/material.dart';

class AppConfig {
  // App Information
  static const String appName = 'BookWorm';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Gestionnaire de bibliothèque personnelle avec reconnaissance OCR';

  // API Configuration
  static const String googleVisionApiUrl = 'https://vision.googleapis.com/v1/images:annotate';
  static const String googleBooksApiUrl = 'https://www.googleapis.com/books/v1/volumes';
  static const String googleProjectId = 'bookworm-474713';
  
  // Database Configuration
  static const String databaseHost = 'localhost';
  static const int databasePort = 5432;
  static const String databaseName = 'bookworm_db';
  static const String databaseUsername = 'bookworm_user';
  static const String databasePassword = 'bookworm_password';

  // OCR Configuration
  static const double ocrConfidenceThreshold = 0.7;
  static const String isbnRegexPattern = r'\b(?:ISBN(?:-1[03])?:? )?(?=[0-9X]{10}$|(?=(?:[0-9]+[- ]){3})[- 0-9X]{13}$|97[89][0-9]{10}$|(?=(?:[0-9]+[- ]){4})[- 0-9]{17}$)(?:97[89][- ]?)?[0-9]{1,5}[- ]?[0-9]+[- ]?[0-9]+[- ]?[0-9X]\b';

  // Image Configuration
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const int imageQuality = 85;

  // Search Configuration
  static const int maxSearchResults = 50;
  static const int maxGoogleBooksResults = 10;

  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;

  // Colors
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color infoColor = Color(0xFF2196F3);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Background Colors
  static const Color backgroundPrimary = Color(0xFFFAFAFA);
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color backgroundCard = Color(0xFFFFFFFF);

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Font Sizes
  static const double fontSizeXS = 10.0;
  static const double fontSizeS = 12.0;
  static const double fontSizeM = 14.0;
  static const double fontSizeL = 16.0;
  static const double fontSizeXL = 18.0;
  static const double fontSizeXXL = 24.0;
  static const double fontSizeTitle = 28.0;
  static const double fontSizeHeadline = 32.0;

  // Icon Sizes
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;

  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxTitleLength = 500;
  static const int maxAuthorLength = 255;
  static const int maxDescriptionLength = 2000;
  static const int maxNotesLength = 1000;

  // Default Values
  static const String defaultLanguage = 'fr';
  static const String defaultShelfName = 'Général';
  static const int defaultShelfCapacity = 50;

  // File Paths
  static const String imagesPath = 'images';
  static const String configPath = 'config';
  static const String logsPath = 'logs';

  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  // Network Configuration
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;

  // Development
  static const bool isDebugMode = true;
  static const bool enableLogging = true;
  static const bool enableAnalytics = false;
}
