import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../providers/library_provider.dart';
import '../../widgets/statistics_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les statistiques
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LibraryProvider>(context, listen: false).loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<LibraryProvider>(context, listen: false).loadStatistics();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConfig.spacingM),
          child: Consumer<LibraryProvider>(
            builder: (context, libraryProvider, child) {
              if (libraryProvider.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppConfig.spacingXL),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final stats = libraryProvider.statistics;
              if (stats.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre principal
                  Text(
                    'Vue d\'ensemble de votre bibliothèque',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConfig.spacingS),
                  Text(
                    'Découvrez les statistiques de votre collection',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppConfig.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: AppConfig.spacingXL),

                  // Statistiques principales
                  _buildMainStatistics(stats),
                  
                  const SizedBox(height: AppConfig.spacingXL),

                  // Statistiques détaillées
                  _buildDetailedStatistics(stats),
                  
                  const SizedBox(height: AppConfig.spacingXL),

                  // Graphiques et visualisations (pour future implémentation)
                  _buildVisualizationsSection(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppConfig.textHint,
            ),
            const SizedBox(height: AppConfig.spacingL),
            Text(
              'Aucune statistique disponible',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppConfig.textSecondary,
              ),
            ),
            const SizedBox(height: AppConfig.spacingS),
            Text(
              'Ajoutez des livres à votre bibliothèque pour voir vos statistiques',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConfig.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatistics(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques principales',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConfig.spacingM),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppConfig.spacingM,
          mainAxisSpacing: AppConfig.spacingM,
          childAspectRatio: 1.3,
          children: [
            StatisticsCard(
              title: 'Total des livres',
              value: '${stats['totalBooks'] ?? 0}',
              icon: Icons.library_books,
              color: AppConfig.primaryColor,
            ),
            StatisticsCard(
              title: 'Livres lus',
              value: '${stats['readBooks'] ?? 0}',
              icon: Icons.check_circle,
              color: AppConfig.successColor,
            ),
            StatisticsCard(
              title: 'Non lus',
              value: '${stats['unreadBooks'] ?? 0}',
              icon: Icons.bookmark_border,
              color: AppConfig.warningColor,
            ),
            StatisticsCard(
              title: 'Pages totales',
              value: '${stats['totalPages'] ?? 0}',
              icon: Icons.description,
              color: AppConfig.infoColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedStatistics(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détails',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConfig.spacingM),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConfig.spacingL),
            child: Column(
              children: [
                _buildStatRow('Taux de lecture', _calculateReadingRate(stats)),
                const Divider(),
                _buildStatRow('Moyenne des pages', _calculateAveragePages(stats)),
                const Divider(),
                _buildStatRow('Dernière activité', _getLastActivity(stats)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConfig.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppConfig.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visualisations',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConfig.spacingM),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConfig.spacingL),
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 48,
                  color: AppConfig.textHint,
                ),
                const SizedBox(height: AppConfig.spacingM),
                Text(
                  'Graphiques et analyses',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppConfig.spacingS),
                Text(
                  'Les graphiques détaillés seront disponibles dans une future version',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConfig.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _calculateReadingRate(Map<String, dynamic> stats) {
    final total = stats['totalBooks'] ?? 0;
    final read = stats['readBooks'] ?? 0;
    if (total == 0) return '0%';
    return '${((read / total) * 100).round()}%';
  }

  String _calculateAveragePages(Map<String, dynamic> stats) {
    final total = stats['totalBooks'] ?? 0;
    final pages = stats['totalPages'] ?? 0;
    if (total == 0) return '0';
    return '${(pages / total).round()}';
  }

  String _getLastActivity(Map<String, dynamic> stats) {
    // Pour l'instant, retourner une valeur par défaut
    // Dans une vraie implémentation, on récupérerait la date du dernier livre ajouté
    return 'Récemment';
  }
}
