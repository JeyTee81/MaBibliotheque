import 'package:logger/logger.dart';

import '../models/shelf_system.dart';
import '../database/postgresql_database_service.dart';

/// Gestionnaire du système d'étagères hiérarchique
class ShelfManager {
  static final Logger _logger = Logger();
  static final PostgreSQLDatabaseService _database = PostgreSQLDatabaseService();

  // Cache en mémoire pour les performances
  static final List<Room> _rooms = [];
  static final List<Furniture> _furniture = [];
  static final List<BookLocation> _bookLocations = [];

  /// Initialise le système en chargeant toutes les données
  static Future<void> initialize() async {
    try {
      _logger.i('Initializing ShelfManager...');
      
      // Initialiser la connexion PostgreSQL
      await _database.initialize();
      
      // Charger les pièces
      _rooms.clear();
      _rooms.addAll(await _database.getAllRooms());
      
      // Charger les meubles
      _furniture.clear();
      _furniture.addAll(await _database.getAllFurniture());
      
      // Charger les positions des livres
      _bookLocations.clear();
      _bookLocations.addAll(await _database.getAllBookLocations());
      
      _logger.i('ShelfManager initialized: ${_rooms.length} rooms, ${_furniture.length} furniture, ${_bookLocations.length} book locations');
    } catch (e) {
      _logger.e('Error initializing ShelfManager: $e');
      rethrow;
    }
  }

  // ===== GESTION DES PIÈCES =====
  
  static List<Room> get rooms => List.from(_rooms);
  
  static Future<Room> addRoom(String name, {String? description}) async {
    try {
      final room = Room(name: name, description: description);
      final addedRoom = await _database.addRoom(room);
      _rooms.add(addedRoom);
      _logger.i('Added room: $name');
      return addedRoom;
    } catch (e) {
      _logger.e('Error adding room: $e');
      rethrow;
    }
  }

  static Future<void> updateRoom(Room room) async {
    try {
      await _database.updateRoom(room);
      final index = _rooms.indexWhere((r) => r.id == room.id);
      if (index != -1) {
        _rooms[index] = room;
        _logger.i('Updated room: ${room.name}');
      }
    } catch (e) {
      _logger.e('Error updating room: $e');
      rethrow;
    }
  }

  static Future<void> deleteRoom(String roomId) async {
    try {
      // Supprimer tous les meubles de cette pièce
      final furnitureToDelete = _furniture.where((f) => f.roomId == roomId).toList();
      for (final furniture in furnitureToDelete) {
        await deleteFurniture(furniture.id);
      }
      
      // Supprimer la pièce
      await _database.deleteRoom(roomId);
      _rooms.removeWhere((r) => r.id == roomId);
      _logger.i('Deleted room: $roomId');
    } catch (e) {
      _logger.e('Error deleting room: $e');
      rethrow;
    }
  }

  // ===== GESTION DES MEUBLES =====
  
  static List<Furniture> getFurnitureByRoom(String roomId) {
    return _furniture.where((f) => f.roomId == roomId).toList();
  }
  
  static Future<Furniture> addFurniture({
    required String roomId,
    required String name,
    String? description,
    required int numberOfShelves,
    required int placesPerShelf,
  }) async {
    try {
      final furniture = Furniture(
        roomId: roomId,
        name: name,
        description: description,
        numberOfShelves: numberOfShelves,
        placesPerShelf: placesPerShelf,
      );
      final addedFurniture = await _database.addFurniture(furniture);
      _furniture.add(addedFurniture);
      _logger.i('Added furniture: $name in room $roomId');
      return addedFurniture;
    } catch (e) {
      _logger.e('Error adding furniture: $e');
      rethrow;
    }
  }

  static Future<void> updateFurniture(Furniture furniture) async {
    try {
      await _database.updateFurniture(furniture);
      final index = _furniture.indexWhere((f) => f.id == furniture.id);
      if (index != -1) {
        _furniture[index] = furniture;
        _logger.i('Updated furniture: ${furniture.name}');
      }
    } catch (e) {
      _logger.e('Error updating furniture: $e');
      rethrow;
    }
  }

  static Future<void> deleteFurniture(String furnitureId) async {
    try {
      // Supprimer toutes les positions des livres sur ce meuble
      final locationsToDelete = _bookLocations.where((bl) => bl.furnitureId == furnitureId).toList();
      for (final location in locationsToDelete) {
        await _database.deleteBookLocation(location.id);
      }
      _bookLocations.removeWhere((bl) => bl.furnitureId == furnitureId);
      
      // Supprimer le meuble
      await _database.deleteFurniture(furnitureId);
      _furniture.removeWhere((f) => f.id == furnitureId);
      _logger.i('Deleted furniture: $furnitureId');
    } catch (e) {
      _logger.e('Error deleting furniture: $e');
      rethrow;
    }
  }

  // ===== GESTION DES POSITIONS DES LIVRES =====
  
  static BookLocation? getBookLocation(String bookId) {
    try {
      return _bookLocations.firstWhere((bl) => bl.bookId == bookId);
    } catch (e) {
      return null;
    }
  }

  static Future<void> assignBookToLocation({
    required String bookId,
    required String furnitureId,
    required int shelfNumber,
    required int position,
  }) async {
    try {
      // Vérifier que la position est disponible
      if (!isPositionAvailable(furnitureId, shelfNumber, position)) {
        throw Exception('Position déjà occupée');
      }

      // Supprimer l'ancienne position si elle existe
      await removeBookFromLocation(bookId);

      // Créer la nouvelle position
      final bookLocation = BookLocation(
        bookId: bookId,
        furnitureId: furnitureId,
        shelfNumber: shelfNumber,
        position: position,
      );

      final addedLocation = await _database.addBookLocation(bookLocation);
      _bookLocations.add(addedLocation);
      _logger.i('Assigned book $bookId to furniture $furnitureId, shelf $shelfNumber, position $position');
    } catch (e) {
      _logger.e('Error assigning book location: $e');
      rethrow;
    }
  }

  static Future<void> removeBookFromLocation(String bookId) async {
    try {
      final existingLocation = getBookLocation(bookId);
      if (existingLocation != null) {
        await _database.deleteBookLocation(existingLocation.id);
        _bookLocations.removeWhere((bl) => bl.bookId == bookId);
        _logger.i('Removed book $bookId from location');
      }
    } catch (e) {
      _logger.e('Error removing book location: $e');
      rethrow;
    }
  }

  // ===== MÉTHODES UTILITAIRES =====
  
  /// Vérifie si une position est disponible
  static bool isPositionAvailable(String furnitureId, int shelfNumber, int position) {
    return !_bookLocations.any((bl) => 
      bl.furnitureId == furnitureId && 
      bl.shelfNumber == shelfNumber && 
      bl.position == position
    );
  }

  /// Retourne les positions disponibles pour un meuble et une étagère
  static List<int> getAvailablePositions(String furnitureId, int shelfNumber) {
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
  }

  /// Retourne une description complète de la localisation d'un livre
  static String getBookLocationString(String bookId) {
    final location = getBookLocation(bookId);
    if (location == null) return 'Non rangé';
    
    final furniture = _furniture.firstWhere((f) => f.id == location.furnitureId);
    final room = _rooms.firstWhere((r) => r.id == furniture.roomId);
    
    return '${room.name} → ${furniture.name} → Étagère ${location.shelfNumber} → Position ${location.position}';
  }

  /// Retourne les statistiques d'occupation
  static Map<String, dynamic> getOccupationStats() {
    final totalPlaces = _furniture.fold<int>(0, (sum, f) => sum + f.totalPlaces);
    final occupiedPlaces = _bookLocations.length;
    final availablePlaces = totalPlaces - occupiedPlaces;
    
    return {
      'totalPlaces': totalPlaces,
      'occupiedPlaces': occupiedPlaces,
      'availablePlaces': availablePlaces,
      'occupationRate': totalPlaces > 0 ? (occupiedPlaces / totalPlaces * 100).round() : 0,
    };
  }

  /// Retourne les statistiques par pièce
  static List<Map<String, dynamic>> getRoomStats() {
    return _rooms.map((room) {
      final roomFurniture = getFurnitureByRoom(room.id);
      final totalPlaces = roomFurniture.fold<int>(0, (sum, f) => sum + f.totalPlaces);
      final occupiedPlaces = _bookLocations
          .where((bl) => roomFurniture.any((f) => f.id == bl.furnitureId))
          .length;
      
      return {
        'room': room,
        'furnitureCount': roomFurniture.length,
        'totalPlaces': totalPlaces,
        'occupiedPlaces': occupiedPlaces,
        'availablePlaces': totalPlaces - occupiedPlaces,
        'occupationRate': totalPlaces > 0 ? (occupiedPlaces / totalPlaces * 100).round() : 0,
      };
    }).toList();
  }
}
