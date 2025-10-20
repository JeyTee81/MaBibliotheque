import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/models/shelf_system.dart';
import '../../providers/shelf_provider.dart';

class ShelfManagementScreen extends StatefulWidget {
  const ShelfManagementScreen({super.key});

  @override
  State<ShelfManagementScreen> createState() => _ShelfManagementScreenState();
}

class _ShelfManagementScreenState extends State<ShelfManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShelfProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Emplacements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRoomDialog(),
          ),
        ],
      ),
      body: Consumer<ShelfProvider>(
        builder: (context, shelfProvider, child) {
          if (shelfProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (shelfProvider.rooms.isEmpty) {
            return _buildEmptyState();
          }

          return _buildRoomsList(shelfProvider);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            size: 80,
            color: AppConfig.textHint,
          ),
          const SizedBox(height: AppConfig.spacingL),
          Text(
            'Aucune pièce configurée',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppConfig.textHint,
            ),
          ),
          const SizedBox(height: AppConfig.spacingM),
          Text(
            'Commencez par ajouter une pièce (Bureau, Salon, etc.)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppConfig.textHint,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConfig.spacingL),
          ElevatedButton.icon(
            onPressed: () => _showAddRoomDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une pièce'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList(ShelfProvider shelfProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConfig.spacingM),
      itemCount: shelfProvider.rooms.length,
      itemBuilder: (context, index) {
        final room = shelfProvider.rooms[index];
        final furniture = shelfProvider.getFurnitureByRoom(room.id);
        final stats = shelfProvider.getRoomStats(room.id);
        
        return Card(
          margin: const EdgeInsets.only(bottom: AppConfig.spacingM),
          child: ExpansionTile(
            leading: const Icon(Icons.home, color: AppConfig.primaryColor),
            title: Text(room.name),
            subtitle: Text('${furniture.length} meuble${furniture.length > 1 ? 's' : ''} • ${stats['totalPlaces']} places'),
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConfig.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistiques de la pièce
                    _buildRoomStats(stats),
                    const SizedBox(height: AppConfig.spacingM),
                    
                    // Liste des meubles
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Meubles:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddFurnitureDialog(room),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConfig.spacingS),
                    
                    if (furniture.isEmpty) ...[
                      Text(
                        'Aucun meuble configuré',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppConfig.textHint,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else ...[
                      ...furniture.map((furniture) => _buildFurnitureCard(furniture, shelfProvider)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoomStats(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(AppConfig.spacingM),
      decoration: BoxDecoration(
        color: AppConfig.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Places totales', stats['totalPlaces'].toString()),
          _buildStatItem('Occupées', stats['occupiedPlaces'].toString()),
          _buildStatItem('Disponibles', stats['availablePlaces'].toString()),
          _buildStatItem('Taux', '${stats['occupationRate']}%'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppConfig.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppConfig.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildFurnitureCard(Furniture furniture, ShelfProvider shelfProvider) {
    final bookLocations = shelfProvider.getBookLocationsByFurniture(furniture.id);
    final occupiedPlaces = bookLocations.length;
    final availablePlaces = furniture.totalPlaces - occupiedPlaces;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppConfig.spacingS),
      child: ListTile(
        leading: const Icon(Icons.inventory_2, color: AppConfig.textHint),
        title: Text(furniture.name),
        subtitle: Text(
          '${furniture.numberOfShelves} étagère${furniture.numberOfShelves > 1 ? 's' : ''} • '
          '${furniture.placesPerShelf} places/étagère • '
          '$occupiedPlaces/$availablePlaces occupées'
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: AppConfig.spacingS),
                  Text('Modifier'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 16, color: AppConfig.errorColor),
                  SizedBox(width: AppConfig.spacingS),
                  Text('Supprimer', style: TextStyle(color: AppConfig.errorColor)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditFurnitureDialog(furniture);
            } else if (value == 'delete') {
              _showDeleteFurnitureDialog(furniture);
            }
          },
        ),
        onTap: () => _showFurnitureDetails(furniture, shelfProvider),
      ),
    );
  }

  // ===== DIALOGS =====

  void _showAddRoomDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une pièce'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la pièce',
                hintText: 'Ex: Bureau, Salon, Chambre...',
              ),
            ),
            const SizedBox(height: AppConfig.spacingM),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Ex: Bureau principal, Salon de lecture...',
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
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                try {
                  await context.read<ShelfProvider>().addRoom(
                    nameController.text.trim(),
                    description: descriptionController.text.trim().isNotEmpty 
                        ? descriptionController.text.trim() 
                        : null,
                  );
                  if (mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: AppConfig.errorColor,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showAddFurnitureDialog(Room room) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final shelvesController = TextEditingController(text: '1');
    final placesController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter un meuble dans ${room.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du meuble',
                hintText: 'Ex: Meuble 1, Bibliothèque A...',
              ),
            ),
            const SizedBox(height: AppConfig.spacingM),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Ex: Meuble principal, Bibliothèque fiction...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppConfig.spacingM),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: shelvesController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre d\'étagères',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppConfig.spacingM),
                Expanded(
                  child: TextField(
                    controller: placesController,
                    decoration: const InputDecoration(
                      labelText: 'Places par étagère',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                try {
                  final numberOfShelves = int.tryParse(shelvesController.text) ?? 1;
                  final placesPerShelf = int.tryParse(placesController.text) ?? 10;
                  
                  await context.read<ShelfProvider>().addFurniture(
                    roomId: room.id,
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isNotEmpty 
                        ? descriptionController.text.trim() 
                        : null,
                    numberOfShelves: numberOfShelves,
                    placesPerShelf: placesPerShelf,
                  );
                  if (mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: AppConfig.errorColor,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showEditFurnitureDialog(Furniture furniture) {
    // TODO: Implémenter l'édition
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Édition à implémenter')),
    );
  }

  void _showDeleteFurnitureDialog(Furniture furniture) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le meuble'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${furniture.name}" ?\n\nTous les livres rangés dans ce meuble seront déplacés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<ShelfProvider>().deleteFurniture(furniture.id);
                if (mounted) Navigator.of(context).pop();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: AppConfig.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.errorColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showFurnitureDetails(Furniture furniture, ShelfProvider shelfProvider) {
    // TODO: Implémenter les détails du meuble avec vue des étagères
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Détails du meuble à implémenter')),
    );
  }
}
