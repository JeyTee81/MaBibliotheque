import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';

class MainNavigationShell extends StatelessWidget {
  final Widget child;

  const MainNavigationShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: AppConfig.primaryColor,
        unselectedItemColor: AppConfig.textHint,
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Livres',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Ajouter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_add),
            label: 'Bibliothèque',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Recherche',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.web),
            label: 'En ligne',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work),
            label: 'Emplacements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_android),
            label: 'Mobile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    
    switch (location) {
      case '/dashboard':
        return 0;
      case '/books':
        return 1;
      case '/add-book':
        return 2;
      case '/library':
        return 3;
      case '/search':
        return 4;
      case '/online-search':
        return 5;
      case '/shelf-management':
        return 6;
      case '/mobile-receiver':
        return 7;
      case '/profile':
        return 8;
      case '/statistics':
        return 8;
      default:
        return 0;
    }
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/books');
        break;
      case 2:
        context.go('/add-book');
        break;
      case 3:
        context.go('/library');
        break;
      case 4:
        context.go('/search');
        break;
      case 5:
        context.go('/online-search');
        break;
      case 6:
        context.go('/shelf-management');
        break;
      case 7:
        context.go('/mobile-receiver');
        break;
      case 8:
        context.go('/profile');
        break;
    }
  }
}
