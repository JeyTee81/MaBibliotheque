import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../providers/library_provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les statistiques après que le widget soit construit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatistics();
    });
  }

  Future<void> _loadStatistics() async {
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    await libraryProvider.loadStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque'),
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, libraryProvider, child) {
          if (libraryProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final stats = libraryProvider.statistics;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConfig.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistiques générales
                Text(
                  'Statistiques',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppConfig.spacingM),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppConfig.spacingM,
                  mainAxisSpacing: AppConfig.spacingM,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      'Total',
                      '${stats['totalBooks'] ?? 0}',
                      Icons.library_books,
                      AppConfig.primaryColor,
                    ),
                    _buildStatCard(
                      'Lus',
                      '${stats['readBooks'] ?? 0}',
                      Icons.check_circle,
                      AppConfig.successColor,
                    ),
                    _buildStatCard(
                      'Non lus',
                      '${stats['unreadBooks'] ?? 0}',
                      Icons.bookmark_border,
                      AppConfig.warningColor,
                    ),
                    _buildStatCard(
                      'Pages',
                      '${stats['totalPages'] ?? 0}',
                      Icons.description,
                      AppConfig.infoColor,
                    ),
                  ],
                ),

                const SizedBox(height: AppConfig.spacingL),

                // Statistiques avancées
                if (stats.isNotEmpty) ...[
                  Text(
                    'Détails',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppConfig.spacingM),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConfig.spacingM),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Auteur le plus lu',
                            stats['mostReadAuthor'] ?? 'Aucun',
                            Icons.person,
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Note moyenne',
                            stats['averageRating'] != null 
                                ? '${(stats['averageRating'] as double).toStringAsFixed(1)}/5'
                                : 'Aucune note',
                            Icons.star,
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Livres ajoutés ce mois',
                            '${stats['booksThisMonth'] ?? 0}',
                            Icons.calendar_month,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppConfig.spacingL),

                // Actions rapides
                Text(
                  'Actions rapides',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppConfig.spacingM),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implémenter l'export
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Exporter'),
                      ),
                    ),
                    const SizedBox(width: AppConfig.spacingM),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implémenter l'import
                        },
                        icon: const Icon(Icons.upload),
                        label: const Text('Importer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.spacingM),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: AppConfig.spacingS),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConfig.spacingXS),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConfig.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConfig.spacingS),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppConfig.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppConfig.spacingM),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppConfig.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}