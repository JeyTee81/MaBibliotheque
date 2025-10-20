import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(
              child: Text('Utilisateur non connecté'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConfig.spacingM),
            child: Column(
              children: [
                // Informations utilisateur
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConfig.spacingL),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppConfig.primaryColor,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConfig.spacingM),
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConfig.spacingS),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppConfig.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppConfig.spacingS),
                        Text(
                          'Membre depuis ${_formatDate(user.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConfig.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppConfig.spacingL),

                // Options du profil
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Modifier le profil'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Implémenter la modification du profil
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonctionnalité à venir'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.security),
                        title: const Text('Sécurité'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Implémenter les paramètres de sécurité
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonctionnalité à venir'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notifications'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Implémenter les paramètres de notifications
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonctionnalité à venir'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help),
                        title: const Text('Aide et support'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Implémenter l'aide
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonctionnalité à venir'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConfig.spacingL),

                // Informations sur l'application
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('À propos'),
                        subtitle: Text('Version ${AppConfig.appVersion}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showAboutDialog(context);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip),
                        title: const Text('Politique de confidentialité'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Implémenter la politique de confidentialité
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonctionnalité à venir'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.description),
                        title: const Text('Conditions d\'utilisation'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Implémenter les conditions d'utilisation
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonctionnalité à venir'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConfig.spacingL),

                // Bouton de déconnexion
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.errorColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                  ),
                ),

                const SizedBox(height: AppConfig.spacingL),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConfig.appName,
      applicationVersion: AppConfig.appVersion,
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppConfig.primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.menu_book,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        Text(AppConfig.appDescription),
        const SizedBox(height: AppConfig.spacingM),
        const Text(
          'BookWorm est une application de gestion de bibliothèque personnelle '
          'qui vous permet d\'organiser vos livres, de suivre votre progression '
          'de lecture et de découvrir de nouveaux ouvrages.',
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppConfig.errorColor),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}