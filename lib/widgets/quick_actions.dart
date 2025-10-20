import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
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
            _buildActionCard(
              context,
              'Ajouter un livre',
              Icons.add_circle,
              AppConfig.primaryColor,
              () => context.go('/add-book'),
            ),
            _buildActionCard(
              context,
              'Rechercher',
              Icons.search,
              AppConfig.infoColor,
              () => context.go('/search'),
            ),
            _buildActionCard(
              context,
              'Mes livres',
              Icons.library_books,
              AppConfig.secondaryColor,
              () => context.go('/books'),
            ),
            _buildActionCard(
              context,
              'Bibliothèque',
              Icons.shelves,
              AppConfig.accentColor,
              () => context.go('/library'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
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
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}