import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../core/models/book.dart';
import '../core/database/mock_database_service.dart';
import '../core/config/database_config.dart';
import '../core/database/postgresql_database_service.dart';

class LibraryProvider extends ChangeNotifier {
  static final Logger _logger = Logger();
  
  List<Book> _books = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Book> get books => _books;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialisation
  Future<void> loadBooks() async {
    _setLoading(true);
    try {
      if (DatabaseConfig.usePostgreSQL) {
        // Utiliser PostgreSQL
        final dbService = PostgreSQLDatabaseService();
        await dbService.initialize();
        _books = await dbService.getAllBooks();
        await dbService.close();
      } else {
        // Utiliser MockDatabaseService
        final mockDb = MockDatabaseService();
        _books = await mockDb.getAllBooks();
      }
      
      _logger.i('Loaded ${_books.length} books');
      _clearError();
    } catch (e) {
      _logger.e('Error loading books: $e');
      _setError('Erreur lors du chargement des livres: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Gestion des livres
  Future<void> addBook(Book book) async {
    try {
      if (DatabaseConfig.usePostgreSQL) {
        final dbService = PostgreSQLDatabaseService();
        await dbService.initialize();
        await dbService.addBook(book);
        await dbService.close();
      } else {
        final mockDb = MockDatabaseService();
        await mockDb.addBook(book);
      }
      
      _books.add(book);
      _logger.i('Added book: ${book.title}');
      notifyListeners();
    } catch (e) {
      _logger.e('Error adding book: $e');
      _setError('Erreur lors de l\'ajout du livre: $e');
    }
  }

  Future<void> updateBook(Book book) async {
    try {
      if (DatabaseConfig.usePostgreSQL) {
        final dbService = PostgreSQLDatabaseService();
        await dbService.initialize();
        await dbService.updateBook(book);
        await dbService.close();
      } else {
        final mockDb = MockDatabaseService();
        await mockDb.updateBook(book);
      }
      
      final index = _books.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        _books[index] = book;
        _logger.i('Updated book: ${book.title}');
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error updating book: $e');
      _setError('Erreur lors de la mise à jour du livre: $e');
    }
  }

  Future<void> deleteBook(String id) async {
    try {
      if (DatabaseConfig.usePostgreSQL) {
        final dbService = PostgreSQLDatabaseService();
        await dbService.initialize();
        await dbService.deleteBook(id);
        await dbService.close();
      } else {
        final mockDb = MockDatabaseService();
        await mockDb.deleteBook(id);
      }
      
      _books.removeWhere((b) => b.id == id);
      _logger.i('Deleted book: $id');
      notifyListeners();
    } catch (e) {
      _logger.e('Error deleting book: $e');
      _setError('Erreur lors de la suppression du livre: $e');
    }
  }

  // Méthodes utilitaires
  List<Book> get allBooks => _books;
  
  Book? getBookById(String id) {
    try {
      return _books.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Book> searchBooks(String query) {
    if (query.trim().isEmpty) return _books;
    
    final lowercaseQuery = query.toLowerCase();
    return _books.where((book) {
      return book.title.toLowerCase().contains(lowercaseQuery) ||
             book.author.toLowerCase().contains(lowercaseQuery) ||
             (book.isbn?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (book.publisher?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Méthodes pour les statistiques (compatibilité avec l'ancien système)
  Map<String, dynamic> get statistics => {
    'totalBooks': _books.length,
    'readBooks': _books.where((book) => book.isRead).length,
    'unreadBooks': _books.where((book) => !book.isRead).length,
    'booksThisMonth': _books.where((book) => 
      book.addedDate.isAfter(DateTime.now().subtract(const Duration(days: 30)))
    ).length,
  };

  Future<void> loadStatistics() async {
    // Les statistiques sont calculées à la volée, pas besoin de charger
    // Cette méthode existe pour la compatibilité avec l'ancien système
    await loadBooks(); // Recharger les livres pour avoir les stats à jour
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