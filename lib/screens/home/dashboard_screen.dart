import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/books_provider.dart';
import '../../providers/library_provider.dart';
import '../../widgets/statistics_card.dart';
import '../../widgets/recent_books_list.dart';
import '../../widgets/quick_actions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les données après que le widget soit construit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final booksProvider = Provider.of<BooksProvider>(context, listen: false);
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    
    await Future.wait([
      booksProvider.loadBooks(),
      libraryProvider.loadStatistics(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.go('/profile');
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: AppConfig.spacingM),
                    Text('Profil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: AppConfig.spacingM),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConfig.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(),

              const SizedBox(height: AppConfig.spacingXL),

              // Navigation Buttons
              _buildNavigationButtons(),

              const SizedBox(height: AppConfig.spacingXL),

              // Recent Books
              _buildRecentBooksSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userName = authProvider.currentUser?.name ?? 'Utilisateur';
        final currentHour = DateTime.now().hour;
        String greeting;
        
        if (currentHour < 12) {
          greeting = 'Bonjour';
        } else if (currentHour < 18) {
          greeting = 'Bon après-midi';
        } else {
          greeting = 'Bonsoir';
        }

        return Container(
          padding: const EdgeInsets.all(AppConfig.spacingL),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppConfig.primaryColor,
                AppConfig.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Text(
                userName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConfig.spacingS),
              Text(
                'Gérez votre bibliothèque personnelle',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationButtons() {
    return Column(
      children: [
        // Première ligne - Actions principales
        Row(
          children: [
            Expanded(
              child: _buildNavButton(
                'Mes livres',
                Icons.library_books,
                AppConfig.primaryColor,
                () => context.go('/books'),
              ),
            ),
            const SizedBox(width: AppConfig.spacingM),
            Expanded(
              child: _buildNavButton(
                'Ajouter un livre',
                Icons.add_circle,
                AppConfig.successColor,
                () => context.go('/add-book'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppConfig.spacingM),
        
        // Deuxième ligne - Recherche et Bibliothèque
        Row(
          children: [
            Expanded(
              child: _buildNavButton(
                'Rechercher',
                Icons.search,
                AppConfig.infoColor,
                () => context.go('/search'),
              ),
            ),
            const SizedBox(width: AppConfig.spacingM),
            Expanded(
              child: _buildNavButton(
                'Bibliothèque',
                Icons.library_add,
                AppConfig.accentColor,
                () => context.go('/library'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppConfig.spacingM),
        
        // Troisième ligne - Recherche en ligne et Statistiques
        Row(
          children: [
            Expanded(
              child: _buildNavButton(
                'Recherche en ligne',
                Icons.web,
                AppConfig.secondaryColor,
                () => context.go('/online-search'),
              ),
            ),
            const SizedBox(width: AppConfig.spacingM),
            Expanded(
              child: _buildNavButton(
                'Statistiques',
                Icons.analytics,
                AppConfig.warningColor,
                () => context.go('/statistics'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppConfig.spacingM),
        
        // Quatrième ligne - Emplacements et Mobile
        Row(
          children: [
            Expanded(
              child: _buildNavButton(
                'Emplacements',
                Icons.home_work,
                AppConfig.textSecondary,
                () => context.go('/shelf-management'),
              ),
            ),
            const SizedBox(width: AppConfig.spacingM),
            Expanded(
              child: _buildNavButton(
                'Récepteur mobile',
                Icons.phone_android,
                AppConfig.primaryColor,
                () => context.go('/mobile-receiver'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: AppConfig.spacingS),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: AppConfig.fontSizeS,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBooksSection() {
    return Consumer<BooksProvider>(
      builder: (context, booksProvider, child) {
        if (booksProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final recentBooks = booksProvider.allBooks.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Livres récents',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                TextButton(
                  onPressed: () => context.go('/books'),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: AppConfig.spacingM),
            if (recentBooks.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppConfig.spacingL),
                decoration: BoxDecoration(
                  color: AppConfig.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  border: Border.all(color: AppConfig.textHint.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      size: 48,
                      color: AppConfig.textHint,
                    ),
                    const SizedBox(height: AppConfig.spacingM),
                    Text(
                      'Aucun livre dans votre bibliothèque',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppConfig.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppConfig.spacingS),
                    Text(
                      'Commencez par ajouter votre premier livre',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConfig.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              RecentBooksList(books: recentBooks),
          ],
        );
      },
    );
  }


  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }
}

