import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:postgres/postgres.dart';

import '../models/book.dart';
import '../models/user.dart';
import '../models/shelf_system.dart';
import '../config/database_config.dart';

/// Service PostgreSQL pour la gestion de la base de données
class PostgreSQLDatabaseService {
  static final Logger _logger = Logger();
  static Connection? _connection;
  static String? lastError;

  /// Initialise la connexion à la base de données
  Future<void> initialize() async {
    try {
      _logger.i('🔌 PostgreSQL: Connecting to ${DatabaseConfig.postgresHost}:${DatabaseConfig.postgresPort}/${DatabaseConfig.postgresDatabase} as ${DatabaseConfig.postgresUsername}');
      
      _connection = await Connection.open(
        Endpoint(
          host: DatabaseConfig.postgresHost,
          port: DatabaseConfig.postgresPort,
          database: DatabaseConfig.postgresDatabase,
          username: DatabaseConfig.postgresUsername,
          password: DatabaseConfig.postgresPassword,
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.disable,
        ),
      );
      
      // Configuration de l'encodage pour les caractères français
      await _connection!.execute(Sql("SET client_encoding = 'UTF8'"));
      await _connection!.execute(Sql("SET default_text_search_config = 'french'"));
      
      _logger.i('✅ PostgreSQL: Connected successfully');
      lastError = null;
    } catch (e) {
      lastError = 'Failed to connect to PostgreSQL: $e';
      _logger.e('❌ PostgreSQL: Connection failed: $e');
      throw Exception(lastError);
    }
  }

  /// Ferme la connexion
  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
    _logger.i('Connexion PostgreSQL fermée');
  }

  /// Vérifie si la connexion est active
  bool get isConnected => _connection != null;

  /// Exécute une requête SELECT
  Future<List<Map<String, dynamic>>> select(String query, [List<dynamic>? parameters]) async {
    if (_connection == null) {
      _logger.e('❌ PostgreSQL: Database not connected');
      throw Exception('Database not connected');
    }
    
    try {
      _logger.i('🔍 PostgreSQL: Executing query: $query');
      final results = await _connection!.execute(Sql(query), parameters: parameters ?? []);
      _logger.i('✅ PostgreSQL: Query executed successfully, ${results.length} rows returned');
      return results.map((row) => row.toColumnMap()).toList();
    } catch (e) {
      lastError = 'Query failed: $e';
      _logger.e('❌ PostgreSQL: Query failed: $e');
      throw Exception(lastError);
    }
  }

  /// Exécute une requête INSERT/UPDATE/DELETE
  Future<int> execute(String query, [List<dynamic>? parameters]) async {
    if (_connection == null) {
      throw Exception('Database not connected');
    }
    
    try {
      final results = await _connection!.execute(Sql(query), parameters: parameters ?? []);
      return results.affectedRows;
    } catch (e) {
      lastError = 'Query failed: $e';
      throw Exception(lastError);
    }
  }

  /// Exécute une requête INSERT et retourne l'ID généré
  Future<int> insertAndGetId(String query, [List<dynamic>? parameters]) async {
    if (_connection == null) {
      throw Exception('Database not connected');
    }
    
    try {
      final results = await _connection!.execute(Sql(query), parameters: parameters ?? []);
      if (results.isNotEmpty) {
        return results.first[0] as int;
      }
      throw Exception('No ID returned from insert');
    } catch (e) {
      lastError = 'Insert failed: $e';
      throw Exception(lastError);
    }
  }

  // ===== GESTION DES LIVRES =====

  /// Récupère tous les livres
  Future<List<Book>> getAllBooks() async {
    try {
      final results = await select('SELECT * FROM books ORDER BY added_date DESC');
      return results.map((data) => Book.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get books: $e';
      throw Exception(lastError);
    }
  }

  /// Ajoute un nouveau livre
  Future<Book> addBook(Book book) async {
    try {
      final query = '''
        INSERT INTO books (id, title, author, isbn, publisher, publication_date, genre, description, 
                          cover_image_url, cover_image_path, page_count, language, rating, 
                          furniture_id, shelf_number, position, added_date, updated_at, is_read, read_date, notes)
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13, \$14, \$15, \$16, \$17, \$18, \$19, \$20, \$21)
      ''';
      await execute(query, [
        book.id,
        book.title,
        book.author,
        book.isbn,
        book.publisher,
        book.publicationDate?.toIso8601String(),
        book.genre,
        book.description,
        book.coverImageUrl,
        book.coverImagePath,
        book.pageCount,
        book.language,
        book.rating,
        book.furnitureId,
        book.shelfNumber,
        book.position,
        book.addedDate.toIso8601String(),
        book.updatedAt.toIso8601String(),
        book.isRead,
        book.readDate?.toIso8601String(),
        book.notes,
      ]);
      _logger.i('Livre ajouté: ${book.title}');
      return book;
    } catch (e) {
      lastError = 'Failed to add book: $e';
      throw Exception(lastError);
    }
  }

  /// Met à jour un livre
  Future<Book> updateBook(Book book) async {
    try {
      final query = '''
        UPDATE books 
        SET title = \$1, author = \$2, isbn = \$3, publisher = \$4, publication_date = \$5, 
            genre = \$6, description = \$7, cover_image_url = \$8, cover_image_path = \$9, 
            page_count = \$10, language = \$11, rating = \$12, furniture_id = \$13, 
            shelf_number = \$14, position = \$15, updated_at = \$16, is_read = \$17, 
            read_date = \$18, notes = \$19
        WHERE id = \$20
      ''';
      await execute(query, [
        book.title,
        book.author,
        book.isbn,
        book.publisher,
        book.publicationDate?.toIso8601String(),
        book.genre,
        book.description,
        book.coverImageUrl,
        book.coverImagePath,
        book.pageCount,
        book.language,
        book.rating,
        book.furnitureId,
        book.shelfNumber,
        book.position,
        book.updatedAt.toIso8601String(),
        book.isRead,
        book.readDate?.toIso8601String(),
        book.notes,
        book.id,
      ]);
      _logger.i('Livre mis à jour: ${book.title}');
      return book;
    } catch (e) {
      lastError = 'Failed to update book: $e';
      throw Exception(lastError);
    }
  }

  /// Supprime un livre
  Future<void> deleteBook(String bookId) async {
    try {
      await execute('DELETE FROM books WHERE id = \$1', [bookId]);
      _logger.i('Livre supprimé: $bookId');
    } catch (e) {
      lastError = 'Failed to delete book: $e';
      throw Exception(lastError);
    }
  }

  // ===== GESTION DES UTILISATEURS =====

  /// Récupère tous les utilisateurs
  Future<List<User>> getAllUsers() async {
    try {
      final results = await select('SELECT * FROM users ORDER BY created_at DESC');
      return results.map((data) => User.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get users: $e';
      throw Exception(lastError);
    }
  }

  /// Ajoute un nouvel utilisateur
  Future<User> addUser(User user) async {
    try {
      final query = '''
        INSERT INTO users (id, name, email, password_hash, created_at, updated_at)
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6)
      ''';
      await execute(query, [
        user.id,
        user.name,
        user.email,
        user.passwordHash,
        user.createdAt.toIso8601String(),
        user.updatedAt.toIso8601String(),
      ]);
      _logger.i('Utilisateur ajouté: ${user.name}');
      return user;
    } catch (e) {
      lastError = 'Failed to add user: $e';
      throw Exception(lastError);
    }
  }

  /// Met à jour un utilisateur
  Future<User> updateUser(User user) async {
    try {
      final query = '''
        UPDATE users 
        SET name = \$1, email = \$2, password_hash = \$3, updated_at = \$4
        WHERE id = \$5
      ''';
      await execute(query, [
        user.name,
        user.email,
        user.passwordHash,
        user.updatedAt.toIso8601String(),
        user.id,
      ]);
      _logger.i('Utilisateur mis à jour: ${user.name}');
      return user;
    } catch (e) {
      lastError = 'Failed to update user: $e';
      throw Exception(lastError);
    }
  }

  /// Supprime un utilisateur
  Future<void> deleteUser(String userId) async {
    try {
      await execute('DELETE FROM users WHERE id = \$1', [userId]);
      _logger.i('Utilisateur supprimé: $userId');
    } catch (e) {
      lastError = 'Failed to delete user: $e';
      throw Exception(lastError);
    }
  }

  // ===== GESTION DES PIÈCES =====

  /// Récupère toutes les pièces
  Future<List<Room>> getAllRooms() async {
    try {
      final results = await select('SELECT * FROM rooms ORDER BY name');
      return results.map((data) => Room.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get rooms: $e';
      throw Exception(lastError);
    }
  }

  /// Ajoute une nouvelle pièce
  Future<Room> addRoom(Room room) async {
    try {
      final query = '''
        INSERT INTO rooms (id, name, description, created_at, updated_at)
        VALUES (\$1, \$2, \$3, \$4, \$5)
      ''';
      await execute(query, [
        room.id,
        room.name,
        room.description,
        room.createdAt.toIso8601String(),
        room.createdAt.toIso8601String(),
      ]);
      _logger.i('Pièce ajoutée: ${room.name}');
      return room;
    } catch (e) {
      lastError = 'Failed to add room: $e';
      throw Exception(lastError);
    }
  }

  /// Met à jour une pièce
  Future<Room> updateRoom(Room room) async {
    try {
      final query = '''
        UPDATE rooms 
        SET name = \$1, description = \$2, updated_at = \$3
        WHERE id = \$4
      ''';
      await execute(query, [
        room.name,
        room.description,
        DateTime.now().toIso8601String(),
        room.id,
      ]);
      _logger.i('Pièce mise à jour: ${room.name}');
      return room;
    } catch (e) {
      lastError = 'Failed to update room: $e';
      throw Exception(lastError);
    }
  }

  /// Supprime une pièce
  Future<void> deleteRoom(String roomId) async {
    try {
      await execute('DELETE FROM rooms WHERE id = \$1', [roomId]);
      _logger.i('Pièce supprimée: $roomId');
    } catch (e) {
      lastError = 'Failed to delete room: $e';
      throw Exception(lastError);
    }
  }

  // ===== GESTION DES MEUBLES =====

  /// Récupère tous les meubles
  Future<List<Furniture>> getAllFurniture() async {
    try {
      final results = await select('SELECT * FROM furniture ORDER BY name');
      return results.map((data) => Furniture.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get furniture: $e';
      throw Exception(lastError);
    }
  }

  /// Ajoute un nouveau meuble
  Future<Furniture> addFurniture(Furniture furniture) async {
    try {
      final query = '''
        INSERT INTO furniture (id, room_id, name, description, number_of_shelves, places_per_shelf, created_at, updated_at)
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8)
      ''';
      await execute(query, [
        furniture.id,
        furniture.roomId,
        furniture.name,
        furniture.description,
        furniture.numberOfShelves,
        furniture.placesPerShelf,
        furniture.createdAt.toIso8601String(),
        furniture.createdAt.toIso8601String(),
      ]);
      _logger.i('Meuble ajouté: ${furniture.name}');
      return furniture;
    } catch (e) {
      lastError = 'Failed to add furniture: $e';
      throw Exception(lastError);
    }
  }

  /// Met à jour un meuble
  Future<Furniture> updateFurniture(Furniture furniture) async {
    try {
      final query = '''
        UPDATE furniture 
        SET room_id = \$1, name = \$2, description = \$3, number_of_shelves = \$4, 
            places_per_shelf = \$5, updated_at = \$6
        WHERE id = \$7
      ''';
      await execute(query, [
        furniture.roomId,
        furniture.name,
        furniture.description,
        furniture.numberOfShelves,
        furniture.placesPerShelf,
        DateTime.now().toIso8601String(),
        furniture.id,
      ]);
      _logger.i('Meuble mis à jour: ${furniture.name}');
      return furniture;
    } catch (e) {
      lastError = 'Failed to update furniture: $e';
      throw Exception(lastError);
    }
  }

  /// Supprime un meuble
  Future<void> deleteFurniture(String furnitureId) async {
    try {
      await execute('DELETE FROM furniture WHERE id = \$1', [furnitureId]);
      _logger.i('Meuble supprimé: $furnitureId');
    } catch (e) {
      lastError = 'Failed to delete furniture: $e';
      throw Exception(lastError);
    }
  }

  // ===== GESTION DES POSITIONS DES LIVRES =====

  /// Récupère toutes les positions des livres
  Future<List<BookLocation>> getAllBookLocations() async {
    try {
      final results = await select('SELECT * FROM book_locations ORDER BY assigned_at DESC');
      return results.map((data) => BookLocation.fromMap(data)).toList();
    } catch (e) {
      lastError = 'Failed to get book locations: $e';
      throw Exception(lastError);
    }
  }

  /// Ajoute une nouvelle position de livre
  Future<BookLocation> addBookLocation(BookLocation bookLocation) async {
    try {
      final query = '''
        INSERT INTO book_locations (id, book_id, furniture_id, shelf_number, position, assigned_at)
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6)
      ''';
      await execute(query, [
        bookLocation.id,
        bookLocation.bookId,
        bookLocation.furnitureId,
        bookLocation.shelfNumber,
        bookLocation.position,
        bookLocation.assignedAt.toIso8601String(),
      ]);
      _logger.i('Position ajoutée: ${bookLocation.bookId}');
      return bookLocation;
    } catch (e) {
      lastError = 'Failed to add book location: $e';
      throw Exception(lastError);
    }
  }

  /// Met à jour une position de livre
  Future<BookLocation> updateBookLocation(BookLocation bookLocation) async {
    try {
      final query = '''
        UPDATE book_locations 
        SET book_id = \$1, furniture_id = \$2, shelf_number = \$3, position = \$4
        WHERE id = \$5
      ''';
      await execute(query, [
        bookLocation.bookId,
        bookLocation.furnitureId,
        bookLocation.shelfNumber,
        bookLocation.position,
        bookLocation.id,
      ]);
      _logger.i('Position mise à jour: ${bookLocation.bookId}');
      return bookLocation;
    } catch (e) {
      lastError = 'Failed to update book location: $e';
      throw Exception(lastError);
    }
  }

  /// Supprime une position de livre
  Future<void> deleteBookLocation(String bookLocationId) async {
    try {
      await execute('DELETE FROM book_locations WHERE id = \$1', [bookLocationId]);
      _logger.i('Position supprimée: $bookLocationId');
    } catch (e) {
      lastError = 'Failed to delete book location: $e';
      throw Exception(lastError);
    }
  }

  // ===== FONCTIONS UTILITAIRES =====

  /// Récupère la chaîne de localisation d'un livre
  Future<String> getBookLocationString(String bookId) async {
    try {
      final results = await select('SELECT get_book_location(\$1) as location', [bookId]);
      if (results.isNotEmpty) {
        return results.first['location'] as String;
      }
      return 'Non rangé';
    } catch (e) {
      _logger.e('Erreur lors de la récupération de la localisation: $e');
      return 'Non rangé';
    }
  }

  /// Récupère les positions disponibles pour un meuble et une étagère
  Future<List<int>> getAvailablePositions(String furnitureId, int shelfNumber) async {
    try {
      final results = await select('SELECT get_available_positions(\$1, \$2) as positions', [furnitureId, shelfNumber]);
      if (results.isNotEmpty) {
        final positionsStr = results.first['positions'] as String;
        if (positionsStr.isEmpty) return [];
        return positionsStr.split(',').map((s) => int.parse(s.trim())).toList();
      }
      return [];
    } catch (e) {
      _logger.e('Erreur lors de la récupération des positions disponibles: $e');
      return [];
    }
  }

  /// Vide toutes les données (pour les tests)
  Future<void> clearAllData() async {
    try {
      await execute('DELETE FROM book_locations');
      await execute('DELETE FROM books');
      await execute('DELETE FROM furniture');
      await execute('DELETE FROM rooms');
      await execute('DELETE FROM users');
      _logger.i('Toutes les données ont été supprimées');
    } catch (e) {
      lastError = 'Failed to clear data: $e';
      throw Exception(lastError);
    }
  }

  /// Teste la connexion à la base de données
  Future<bool> testConnection() async {
    try {
      if (_connection == null) {
        await initialize();
      }
      await select('SELECT 1');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Force la réinitialisation de la connexion
  Future<void> forceReinitialize() async {
    try {
      _logger.i('🔄 PostgreSQL: Force reinitializing connection...');
      await close();
      await initialize();
      _logger.i('✅ PostgreSQL: Connection reinitialized successfully');
    } catch (e) {
      _logger.e('❌ PostgreSQL: Failed to reinitialize connection: $e');
      throw Exception('Failed to reinitialize PostgreSQL connection: $e');
    }
  }
}