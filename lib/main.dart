import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/books_provider.dart';
import 'providers/library_provider.dart';
import 'providers/ocr_provider.dart';
import 'providers/shelf_provider.dart';
import 'providers/pending_books_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/books/books_list_screen.dart';
import 'screens/books/add_book_screen.dart';
import 'screens/books/book_detail_screen.dart';
import 'screens/library/library_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/search/online_search_screen.dart';
import 'screens/shelf_management/shelf_management_screen.dart';
import 'screens/mobile_receiver/mobile_receiver_screen.dart';
import 'screens/validation/book_validation_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/statistics/statistics_screen.dart';
import 'widgets/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BookWormApp());
}

class BookWormApp extends StatelessWidget {
  const BookWormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BooksProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => OCRProvider()),
        ChangeNotifierProvider(create: (_) => ShelfProvider()),
        ChangeNotifierProvider(create: (_) => PendingBooksProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: AppConfig.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    // Routes d'authentification (sans navigation)
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    
    // Routes principales avec navigation (shell route)
    ShellRoute(
      builder: (context, state, child) => MainNavigationShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/books',
          builder: (context, state) => const BooksListScreen(),
        ),
        GoRoute(
          path: '/add-book',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return AddBookScreen(
              preFilledBook: extra?['preFilledBook'],
              preFilledImageBase64: extra?['preFilledImageBase64'],
              preFilledOcrText: extra?['preFilledOcrText'],
            );
          },
        ),
        GoRoute(
          path: '/book/:id',
          builder: (context, state) {
            final bookId = state.pathParameters['id']!;
            return BookDetailScreen(bookId: bookId);
          },
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/online-search',
          builder: (context, state) => const OnlineSearchScreen(),
        ),
        GoRoute(
          path: '/shelf-management',
          builder: (context, state) => const ShelfManagementScreen(),
        ),
        GoRoute(
          path: '/mobile-receiver',
          builder: (context, state) => const MobileReceiverScreen(),
        ),
        GoRoute(
          path: '/book-validation',
          builder: (context, state) => const BookValidationScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/statistics',
          builder: (context, state) => const StatisticsScreen(),
        ),
      ],
    ),
  ],
);
