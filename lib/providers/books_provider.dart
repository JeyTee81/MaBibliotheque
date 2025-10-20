import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../core/models/book.dart';
import '../core/database/postgresql_database_service.dart';

class BooksProvider extends ChangeNotifier {
  static final Logger _logger = Logger();
  
  List<Book> _allBooks = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'title';
  bool _sortAscending = true;

  List<Book> get allBooks => _allBooks;
  List<Book> get filteredBooks => _filteredBooks;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  Future<void> loadBooks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final databaseService = PostgreSQLDatabaseService();
      await databaseService.initialize();
      _allBooks = await databaseService.getAllBooks();
      _applyFilters();
      _logger.i('Loaded ${_allBooks.length} books');
    } catch (e) {
      _logger.e('Error loading books: $e');
      _allBooks = [];
      _filteredBooks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBook(Book book) async {
    try {
      final databaseService = PostgreSQLDatabaseService();
      await databaseService.initialize();
      final addedBook = await databaseService.addBook(book);
      _allBooks.add(addedBook);
      _applyFilters();
      _logger.i('Added book: ${book.title}');
      notifyListeners();
    } catch (e) {
      _logger.e('Error adding book: $e');
      rethrow;
    }
  }

  Future<void> updateBook(Book book) async {
    try {
      final databaseService = PostgreSQLDatabaseService();
      await databaseService.initialize();
      await databaseService.updateBook(book);
      
      final index = _allBooks.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        _allBooks[index] = book;
        _applyFilters();
        _logger.i('Updated book: ${book.title}');
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error updating book: $e');
      rethrow;
    }
  }

  Future<void> deleteBook(String bookId) async {
    try {
      final databaseService = PostgreSQLDatabaseService();
      await databaseService.initialize();
      await databaseService.deleteBook(bookId);
      
      _allBooks.removeWhere((b) => b.id == bookId);
      _applyFilters();
      _logger.i('Deleted book: $bookId');
      notifyListeners();
    } catch (e) {
      _logger.e('Error deleting book: $e');
      rethrow;
    }
  }

  void searchBooks(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void sortBooks(String sortBy, {bool ascending = true}) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    List<Book> filtered = List.from(_allBooks);

    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((book) {
        return book.title.toLowerCase().contains(query) ||
               book.author.toLowerCase().contains(query) ||
               (book.isbn?.toLowerCase().contains(query) ?? false) ||
               (book.publisher?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Appliquer le tri
    filtered.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'author':
          comparison = a.author.compareTo(b.author);
          break;
        case 'addedDate':
          comparison = a.addedDate.compareTo(b.addedDate);
          break;
        case 'isRead':
          comparison = a.isRead == b.isRead ? 0 : (a.isRead ? 1 : -1);
          break;
        case 'rating':
          final aRating = a.rating ?? 0;
          final bRating = b.rating ?? 0;
          comparison = aRating.compareTo(bRating);
          break;
        default:
          comparison = a.title.compareTo(b.title);
      }

      return _sortAscending ? comparison : -comparison;
    });

    _filteredBooks = filtered;
  }

  List<Book> getBooksByStatus(bool isRead) {
    return _allBooks.where((book) => book.isRead == isRead).toList();
  }

  List<Book> getBooksByAuthor(String author) {
    return _allBooks.where((book) => 
      book.author.toLowerCase().contains(author.toLowerCase())
    ).toList();
  }

  List<Book> getRecentBooks({int limit = 5}) {
    final sortedBooks = List<Book>.from(_allBooks);
    sortedBooks.sort((a, b) => b.addedDate.compareTo(a.addedDate));
    return sortedBooks.take(limit).toList();
  }

  Book? getBookById(String id) {
    try {
      return _allBooks.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }

  int get totalBooks => _allBooks.length;
  int get readBooks => _allBooks.where((book) => book.isRead).length;
  int get unreadBooks => _allBooks.where((book) => !book.isRead).length;
  int get totalPages => _allBooks
      .where((book) => book.pageCount != null)
      .fold(0, (sum, book) => sum + (book.pageCount ?? 0));
}