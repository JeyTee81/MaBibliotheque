import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../core/models/shelf_system.dart';
import '../core/services/shelf_manager.dart';
import '../core/database/postgresql_database_service.dart';

class ShelfProvider extends ChangeNotifier {
  static final Logger _logger = Logger();
  
  List<Room> _rooms = [];
  List<Furniture> _furniture = [];
  List<BookLocation> _bookLocations = [];
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Room> get rooms => _rooms;
  List<Furniture> get furniture => _furniture;
  List<BookLocation> get bookLocations => _bookLocations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialisation
  Future<void> loadData() async {
    _setLoading(true);
    try {
      // Utiliser PostgreSQL exclusivement
      final dbService = PostgreSQLDatabaseService();
      await dbService.initialize();
      
      _rooms = await dbService.getAllRooms();
      _furniture = await dbService.getAllFurniture();
      _bookLocations = await dbService.getAllBookLocations();
      
      await dbService.close();
      
      _logger.i('Loaded ${_rooms.length} rooms, ${_furniture.length} furniture, ${_bookLocations.length} book locations');
      _clearError();
    } catch (e) {
      _logger.e('Error loading shelf data: $e');
      _setError('Erreur lors du chargement des emplacements: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Gestion des pièces
  Future<void> addRoom(String name, {String? description}) async {
    try {
      final room = await ShelfManager.addRoom(name, description: description);
      _rooms.add(room);
      _logger.i('Added room: $name');
      notifyListeners();
    } catch (e) {
      _logger.e('Error adding room: $e');
      _setError('Erreur lors de l\'ajout de la pièce: $e');
    }
  }

  Future<void> updateRoom(Room room) async {
    try {
      await ShelfManager.updateRoom(room);
      final index = _rooms.indexWhere((r) => r.id == room.id);
      if (index != -1) {
        _rooms[index] = room;
        _logger.i('Updated room: ${room.name}');
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error updating room: $e');
      _setError('Erreur lors de la mise à jour de la pièce: $e');
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await ShelfManager.deleteRoom(roomId);
      _rooms.removeWhere((r) => r.id == roomId);
      _furniture.removeWhere((f) => f.roomId == roomId);
      _bookLocations.removeWhere((bl) => 
        _furniture.any((f) => f.id == bl.furnitureId && f.roomId == roomId)
      );
      _logger.i('Deleted room: $roomId');
      notifyListeners();
    } catch (e) {
      _logger.e('Error deleting room: $e');
      _setError('Erreur lors de la suppression de la pièce: $e');
    }
  }

  // Gestion des meubles
  List<Furniture> getFurnitureByRoom(String roomId) {
    return _furniture.where((f) => f.roomId == roomId).toList();
  }

  Future<void> addFurniture({
    required String roomId,
    required String name,
    String? description,
    required int numberOfShelves,
    required int placesPerShelf,
  }) async {
    try {
      final furniture = await ShelfManager.addFurniture(
        roomId: roomId,
        name: name,
        description: description,
        numberOfShelves: numberOfShelves,
        placesPerShelf: placesPerShelf,
      );
      _furniture.add(furniture);
      _logger.i('Added furniture: $name in room $roomId');
      notifyListeners();
    } catch (e) {
      _logger.e('Error adding furniture: $e');
      _setError('Erreur lors de l\'ajout du meuble: $e');
    }
  }

  Future<void> updateFurniture(Furniture furniture) async {
    try {
      await ShelfManager.updateFurniture(furniture);
      final index = _furniture.indexWhere((f) => f.id == furniture.id);
      if (index != -1) {
        _furniture[index] = furniture;
        _logger.i('Updated furniture: ${furniture.name}');
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error updating furniture: $e');
      _setError('Erreur lors de la mise à jour du meuble: $e');
    }
  }

  Future<void> deleteFurniture(String furnitureId) async {
    try {
      await ShelfManager.deleteFurniture(furnitureId);
      _furniture.removeWhere((f) => f.id == furnitureId);
      _bookLocations.removeWhere((bl) => bl.furnitureId == furnitureId);
      _logger.i('Deleted furniture: $furnitureId');
      notifyListeners();
    } catch (e) {
      _logger.e('Error deleting furniture: $e');
      _setError('Erreur lors de la suppression du meuble: $e');
    }
  }

  // Gestion des positions des livres
  BookLocation? getBookLocation(String bookId) {
    return ShelfManager.getBookLocation(bookId);
  }

  List<BookLocation> getBookLocationsByFurniture(String furnitureId) {
    return _bookLocations.where((bl) => bl.furnitureId == furnitureId).toList();
  }

  Future<void> assignBookToLocation({
    required String bookId,
    required String furnitureId,
    required int shelfNumber,
    required int position,
  }) async {
    try {
      await ShelfManager.assignBookToLocation(
        bookId: bookId,
        furnitureId: furnitureId,
        shelfNumber: shelfNumber,
        position: position,
      );
      
      // Mettre à jour le cache local
      _bookLocations.removeWhere((bl) => bl.bookId == bookId);
      final newLocation = ShelfManager.getBookLocation(bookId);
      if (newLocation != null) {
        _bookLocations.add(newLocation);
      }
      
      _logger.i('Assigned book $bookId to location');
      notifyListeners();
    } catch (e) {
      _logger.e('Error assigning book location: $e');
      _setError('Erreur lors de l\'assignation de la position: $e');
    }
  }

  Future<void> removeBookFromLocation(String bookId) async {
    try {
      await ShelfManager.removeBookFromLocation(bookId);
      _bookLocations.removeWhere((bl) => bl.bookId == bookId);
      _logger.i('Removed book $bookId from location');
      notifyListeners();
    } catch (e) {
      _logger.e('Error removing book location: $e');
      _setError('Erreur lors de la suppression de la position: $e');
    }
  }

  // Méthodes utilitaires
  bool isPositionAvailable(String furnitureId, int shelfNumber, int position) {
    return !_bookLocations.any((bl) => 
      bl.furnitureId == furnitureId && 
      bl.shelfNumber == shelfNumber && 
      bl.position == position
    );
  }

  List<int> getAvailablePositions(String furnitureId, int shelfNumber) {
    try {
      final furniture = _furniture.firstWhere((f) => f.id == furnitureId);
      final usedPositions = _bookLocations
          .where((bl) => bl.furnitureId == furnitureId && bl.shelfNumber == shelfNumber)
          .map((bl) => bl.position)
          .toSet();
      
      final availablePositions = <int>[];
      for (int i = 1; i <= furniture.placesPerShelf; i++) {
        if (!usedPositions.contains(i)) {
          availablePositions.add(i);
        }
      }
      
      return availablePositions;
    } catch (e) {
      _logger.e('Error getting available positions: $e');
      return [];
    }
  }

  String getBookLocationString(String bookId) {
    return ShelfManager.getBookLocationString(bookId);
  }

  Map<String, dynamic> getRoomStats(String roomId) {
    final roomFurniture = getFurnitureByRoom(roomId);
    final totalPlaces = roomFurniture.fold<int>(0, (sum, f) => sum + f.totalPlaces);
    final occupiedPlaces = _bookLocations
        .where((bl) => roomFurniture.any((f) => f.id == bl.furnitureId))
        .length;
    
    return {
      'totalPlaces': totalPlaces,
      'occupiedPlaces': occupiedPlaces,
      'availablePlaces': totalPlaces - occupiedPlaces,
      'occupationRate': totalPlaces > 0 ? (occupiedPlaces / totalPlaces * 100).round() : 0,
    };
  }

  Map<String, dynamic> getOccupationStats() {
    return ShelfManager.getOccupationStats();
  }

  List<Map<String, dynamic>> getAllRoomStats() {
    return ShelfManager.getRoomStats();
  }

  // Méthodes privées
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
