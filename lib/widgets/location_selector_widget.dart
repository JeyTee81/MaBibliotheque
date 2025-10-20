import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_config.dart';
import '../providers/shelf_provider.dart';

class LocationSelectorWidget extends StatefulWidget {
  final String? selectedFurnitureId;
  final int? selectedShelfNumber;
  final int? selectedPosition;
  final Function(String? furnitureId, int? shelfNumber, int? position) onLocationSelected;

  const LocationSelectorWidget({
    super.key,
    this.selectedFurnitureId,
    this.selectedShelfNumber,
    this.selectedPosition,
    required this.onLocationSelected,
  });

  @override
  State<LocationSelectorWidget> createState() => _LocationSelectorWidgetState();
}

class _LocationSelectorWidgetState extends State<LocationSelectorWidget> {
  String? _selectedFurnitureId;
  int? _selectedShelfNumber;
  int? _selectedPosition;
  List<int> _availablePositions = [];

  @override
  void initState() {
    super.initState();
    _selectedFurnitureId = widget.selectedFurnitureId;
    _selectedShelfNumber = widget.selectedShelfNumber;
    _selectedPosition = widget.selectedPosition;
    
    // Charger les données du ShelfProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShelfProvider>(context, listen: false).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShelfProvider>(
      builder: (context, shelfProvider, child) {
        if (shelfProvider.rooms.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélection de la pièce et du meuble
            _buildFurnitureSelector(shelfProvider),
            
            if (_selectedFurnitureId != null) ...[
              const SizedBox(height: AppConfig.spacingM),
              // Sélection de l'étagère
              _buildShelfSelector(shelfProvider),
            ],
            
            if (_selectedFurnitureId != null && _selectedShelfNumber != null) ...[
              const SizedBox(height: AppConfig.spacingM),
              // Sélection de la position
              _buildPositionSelector(shelfProvider),
            ],
            
            if (_selectedFurnitureId != null && _selectedShelfNumber != null && _selectedPosition != null) ...[
              const SizedBox(height: AppConfig.spacingM),
              // Affichage de la localisation sélectionnée
              _buildSelectedLocation(shelfProvider),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppConfig.spacingM),
      decoration: BoxDecoration(
        color: AppConfig.textHint.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(color: AppConfig.textHint.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.home_work_outlined,
            size: 48,
            color: AppConfig.textHint,
          ),
          const SizedBox(height: AppConfig.spacingM),
          Text(
            'Aucun emplacement configuré',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppConfig.textHint,
            ),
          ),
          const SizedBox(height: AppConfig.spacingS),
          Text(
            'Configurez d\'abord vos pièces et meubles dans l\'onglet "Emplacements"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppConfig.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFurnitureSelector(ShelfProvider shelfProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emplacement',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppConfig.spacingS),
        DropdownButtonFormField<String>(
          value: _selectedFurnitureId,
          decoration: InputDecoration(
            labelText: 'Pièce → Meuble',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
          ),
          items: _buildFurnitureItems(shelfProvider),
          onChanged: (furnitureId) {
            setState(() {
              _selectedFurnitureId = furnitureId;
              _selectedShelfNumber = null;
              _selectedPosition = null;
              _availablePositions.clear();
            });
            _notifyLocationChange();
          },
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _buildFurnitureItems(ShelfProvider shelfProvider) {
    final items = <DropdownMenuItem<String>>[];
    
    for (final room in shelfProvider.rooms) {
      final furniture = shelfProvider.getFurnitureByRoom(room.id);
      
      for (final furnitureItem in furniture) {
        items.add(
          DropdownMenuItem(
            value: furnitureItem.id,
            child: Text('${room.name} → ${furnitureItem.name}'),
          ),
        );
      }
    }
    
    return items;
  }

  Widget _buildShelfSelector(ShelfProvider shelfProvider) {
    final furniture = shelfProvider.furniture.firstWhere(
      (f) => f.id == _selectedFurnitureId,
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Étagère',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppConfig.spacingS),
        DropdownButtonFormField<int>(
          value: _selectedShelfNumber,
          decoration: InputDecoration(
            labelText: 'Numéro d\'étagère',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
          ),
          items: List.generate(furniture.numberOfShelves, (index) {
            final shelfNumber = index + 1;
            return DropdownMenuItem(
              value: shelfNumber,
              child: Text('Étagère $shelfNumber'),
            );
          }),
          onChanged: (shelfNumber) {
            setState(() {
              _selectedShelfNumber = shelfNumber;
              _selectedPosition = null;
              _availablePositions = shelfProvider.getAvailablePositions(
                _selectedFurnitureId!,
                shelfNumber!,
              );
            });
            _notifyLocationChange();
          },
        ),
      ],
    );
  }

  Widget _buildPositionSelector(ShelfProvider shelfProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Position',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppConfig.spacingS),
        DropdownButtonFormField<int>(
          value: _selectedPosition,
          decoration: InputDecoration(
            labelText: 'Position sur l\'étagère',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
          ),
          items: _availablePositions.map((position) {
            return DropdownMenuItem(
              value: position,
              child: Text('Position $position'),
            );
          }).toList(),
          onChanged: (position) {
            setState(() {
              _selectedPosition = position;
            });
            _notifyLocationChange();
          },
        ),
      ],
    );
  }

  Widget _buildSelectedLocation(ShelfProvider shelfProvider) {
    final furniture = shelfProvider.furniture.firstWhere(
      (f) => f.id == _selectedFurnitureId,
    );
    final room = shelfProvider.rooms.firstWhere(
      (r) => r.id == furniture.roomId,
    );
    
    return Container(
      padding: const EdgeInsets.all(AppConfig.spacingM),
      decoration: BoxDecoration(
        color: AppConfig.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(color: AppConfig.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: AppConfig.primaryColor,
          ),
          const SizedBox(width: AppConfig.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Localisation sélectionnée:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${room.name} → ${furniture.name} → Étagère ${_selectedShelfNumber} → Position ${_selectedPosition}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _notifyLocationChange() {
    widget.onLocationSelected(
      _selectedFurnitureId,
      _selectedShelfNumber,
      _selectedPosition,
    );
  }
}
