import 'package:logger/logger.dart';

import '../models/book.dart';
import '../models/user.dart';
import '../models/shelf_system.dart';

class MockDatabaseService {
  static final Logger _logger = Logger();
  
  // Stockage en mémoire pour la démo
  static final List<Book> _books = [];
  static final List<User> _users = [];
  static final List<Room> _rooms = [
    Room(id: 'room-1', name: 'Bureau', description: 'Pièce de travail'),
    Room(id: 'room-2', name: 'Salon', description: 'Espace de détente'),
    Room(id: 'room-3', name: 'Chambre', description: 'Chambre à coucher'),
  ];
  static final List<Furniture> _furniture = [
    Furniture(
      id: 'furniture-1',
      roomId: 'room-1',
      name: 'Bibliothèque A',
      description: 'Bibliothèque principale du bureau',
      numberOfShelves: 5,
      placesPerShelf: 20,
    ),
    Furniture(
      id: 'furniture-2',
      roomId: 'room-2',
      name: 'Étagère TV',
      description: 'Étagère sous la télévision',
      numberOfShelves: 3,
      placesPerShelf: 15,
    ),
  ];
  static final List<BookLocation> _bookLocations = [];

  // Méthodes pour les livres
  Future<Book> addBook(Book book) async {
    _books.add(book);
    _logger.i('Book added: ${book.title}');
    return book;
  }

  Future<List<Book>> getAllBooks() async {
    _logger.i('Retrieved ${_books.length} books');
    return List.from(_books);
  }

  Future<Book?> getBookById(String id) async {
    try {
      return _books.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateBook(Book book) async {
    final index = _books.indexWhere((b) => b.id == book.id);
    if (index != -1) {
      _books[index] = book;
      _logger.i('Book updated: ${book.title}');
    }
  }

  Future<void> deleteBook(String id) async {
    _books.removeWhere((b) => b.id == id);
    _logger.i('Book deleted: $id');
  }


  // Méthodes pour les utilisateurs
  Future<User> addUser(User user) async {
    _users.add(user);
    _logger.i('User added: ${user.name}');
    return user;
  }

  Future<User?> getUserById(String id) async {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      return _users.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUser(User user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
      _logger.i('User updated: ${user.name}');
    }
  }

  Future<void> deleteUser(String id) async {
    _users.removeWhere((u) => u.id == id);
    _logger.i('User deleted: $id');
  }

  // Méthodes utilitaires

  // ===== MÉTHODES POUR LE NOUVEAU SYSTÈME D'ÉTAGÈRES =====
  
  // Gestion des pièces
  Future<List<Room>> getAllRooms() async {
    _logger.i('Retrieved ${_rooms.length} rooms');
    return List.from(_rooms);
  }

  Future<Room> addRoom(Room room) async {
    _rooms.add(room);
    _logger.i('Room added: ${room.name}');
    return room;
  }

  Future<void> updateRoom(Room room) async {
    final index = _rooms.indexWhere((r) => r.id == room.id);
    if (index != -1) {
      _rooms[index] = room;
      _logger.i('Room updated: ${room.name}');
    }
  }

  Future<void> deleteRoom(String roomId) async {
    _rooms.removeWhere((r) => r.id == roomId);
    _logger.i('Room deleted: $roomId');
  }

  // Gestion des meubles
  Future<List<Furniture>> getAllFurniture() async {
    _logger.i('Retrieved ${_furniture.length} furniture');
    return List.from(_furniture);
  }

  Future<Furniture> addFurniture(Furniture furniture) async {
    _furniture.add(furniture);
    _logger.i('Furniture added: ${furniture.name}');
    return furniture;
  }

  Future<void> updateFurniture(Furniture furniture) async {
    final index = _furniture.indexWhere((f) => f.id == furniture.id);
    if (index != -1) {
      _furniture[index] = furniture;
      _logger.i('Furniture updated: ${furniture.name}');
    }
  }

  Future<void> deleteFurniture(String furnitureId) async {
    _furniture.removeWhere((f) => f.id == furnitureId);
    _logger.i('Furniture deleted: $furnitureId');
  }

  // Gestion des positions des livres
  Future<List<BookLocation>> getAllBookLocations() async {
    _logger.i('Retrieved ${_bookLocations.length} book locations');
    return List.from(_bookLocations);
  }

  Future<BookLocation> addBookLocation(BookLocation bookLocation) async {
    _bookLocations.add(bookLocation);
    _logger.i('Book location added: ${bookLocation.bookId} -> ${bookLocation.furnitureId}:${bookLocation.shelfNumber}:${bookLocation.position}');
    return bookLocation;
  }

  Future<void> updateBookLocation(BookLocation bookLocation) async {
    final index = _bookLocations.indexWhere((bl) => bl.id == bookLocation.id);
    if (index != -1) {
      _bookLocations[index] = bookLocation;
      _logger.i('Book location updated: ${bookLocation.bookId}');
    }
  }

  Future<void> deleteBookLocation(String bookLocationId) async {
    _bookLocations.removeWhere((bl) => bl.id == bookLocationId);
    _logger.i('Book location deleted: $bookLocationId');
  }

  Future<void> clearAllData() async {
    _books.clear();
    _users.clear();
    _rooms.clear();
    _furniture.clear();
    _bookLocations.clear();
    _logger.i('All data cleared');
  }

  Future<void> close() async {
    _logger.i('Mock database closed');
  }
}
