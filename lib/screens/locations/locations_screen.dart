import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/models/location.dart';
import '../../providers/location_provider.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationProvider>(context, listen: false).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emplacements'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddLocationDialog(),
          ),
        ],
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          if (locationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (locationProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppConfig.errorColor,
                  ),
                  const SizedBox(height: AppConfig.spacingM),
                  Text(
                    locationProvider.error!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConfig.spacingM),
                  ElevatedButton(
                    onPressed: () => locationProvider.loadData(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (locationProvider.locations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 64,
                    color: AppConfig.textHint,
                  ),
                  const SizedBox(height: AppConfig.spacingM),
                  Text(
                    'Aucun emplacement configuré',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppConfig.spacingS),
                  Text(
                    'Ajoutez des emplacements pour organiser vos livres',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppConfig.textHint,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConfig.spacingM),
                  ElevatedButton.icon(
                    onPressed: () => _showAddLocationDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un emplacement'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppConfig.spacingM),
            itemCount: locationProvider.locations.length,
            itemBuilder: (context, index) {
              final location = locationProvider.locations[index];
              final shelves = locationProvider.getShelvesByLocation(location.id);
              
              return Card(
                margin: const EdgeInsets.only(bottom: AppConfig.spacingM),
                child: ExpansionTile(
                  leading: const Icon(Icons.location_on, color: AppConfig.primaryColor),
                  title: Text(
                    location.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '${shelves.length} étagère${shelves.length > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppConfig.textHint,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppConfig.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (location.description != null) ...[
                            Text(
                              location.description!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppConfig.spacingM),
                          ],
                          
                          // Liste des étagères
                          if (shelves.isEmpty) ...[
                            Text(
                              'Aucune étagère configurée',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppConfig.textHint,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Étagères:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppConfig.spacingS),
                            ...shelves.map((shelf) => Padding(
                              padding: const EdgeInsets.only(left: AppConfig.spacingM, bottom: AppConfig.spacingS),
                              child: Row(
                                children: [
                                  const Icon(Icons.inventory, size: 16, color: AppConfig.textHint),
                                  const SizedBox(width: AppConfig.spacingS),
                                  Expanded(
                                    child: Text(
                                      '${shelf.name} (${shelf.maxBooks} places)',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16),
                                    onPressed: () => _showEditShelfDialog(shelf),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 16, color: AppConfig.errorColor),
                                    onPressed: () => _showDeleteShelfDialog(shelf),
                                  ),
                                ],
                              ),
                            )),
                          ],
                          
                          const SizedBox(height: AppConfig.spacingM),
                          
                          // Boutons d'action
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showAddShelfDialog(location.id),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Ajouter étagère'),
                                ),
                              ),
                              const SizedBox(width: AppConfig.spacingS),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showEditLocationDialog(location),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Modifier'),
                                ),
                              ),
                              const SizedBox(width: AppConfig.spacingS),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showDeleteLocationDialog(location),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Supprimer'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppConfig.errorColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddLocationDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un emplacement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'emplacement',
                hintText: 'Ex: Bureau, Salon, Chambre...',
              ),
            ),
            const SizedBox(height: AppConfig.spacingM),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Ex: Rayonnage du bureau principal',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Provider.of<LocationProvider>(context, listen: false).addLocation(
                  nameController.text.trim(),
                  description: descriptionController.text.trim().isNotEmpty 
                      ? descriptionController.text.trim() 
                      : null,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showEditLocationDialog(Location location) {
    final nameController = TextEditingController(text: location.name);
    final descriptionController = TextEditingController(text: location.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'emplacement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'emplacement',
              ),
            ),
            const SizedBox(height: AppConfig.spacingM),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final updatedLocation = location.copyWith(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isNotEmpty 
                      ? descriptionController.text.trim() 
                      : null,
                );
                Provider.of<LocationProvider>(context, listen: false).updateLocation(updatedLocation);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showDeleteLocationDialog(Location location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'emplacement'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${location.name}" ?\n\nCette action supprimera aussi toutes les étagères associées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<LocationProvider>(context, listen: false).deleteLocation(location.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showAddShelfDialog(String locationId) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final maxBooksController = TextEditingController(text: '50');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une étagère'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'étagère',
                hintText: 'Ex: Étagère 1, Rayon A...',
              ),
            ),
            const SizedBox(height: AppConfig.spacingM),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Ex: Étagère du haut',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppConfig.spacingM),
            TextField(
              controller: maxBooksController,
              decoration: const InputDecoration(
                labelText: 'Nombre maximum de livres',
                hintText: '50',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final maxBooks = int.tryParse(maxBooksController.text) ?? 50;
                Provider.of<LocationProvider>(context, listen: false).addShelf(
                  locationId: locationId,
                  name: nameController.text.trim(),
                  maxBooks: maxBooks,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showEditShelfDialog(Shelf shelf) {
    final nameController = TextEditingController(text: shelf.name);
    final descriptionController = TextEditingController(text: shelf.description ?? '');
    final maxBooksController = TextEditingController(text: shelf.maxBooks.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'étagère'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'étagère',
              ),
            ),
            const SizedBox(height: AppConfig.spacingM),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppConfig.spacingM),
            TextField(
              controller: maxBooksController,
              decoration: const InputDecoration(
                labelText: 'Nombre maximum de livres',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final maxBooks = int.tryParse(maxBooksController.text) ?? 50;
                final updatedShelf = shelf.copyWith(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isNotEmpty 
                      ? descriptionController.text.trim() 
                      : null,
                  maxBooks: maxBooks,
                );
                Provider.of<LocationProvider>(context, listen: false).updateShelf(updatedShelf);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showDeleteShelfDialog(Shelf shelf) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'étagère'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${shelf.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<LocationProvider>(context, listen: false).deleteShelf(shelf.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
