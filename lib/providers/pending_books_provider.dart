import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../core/models/pending_book.dart';
import '../core/models/book.dart';

class PendingBooksProvider extends ChangeNotifier {
  static final Logger _logger = Logger();
  
  List<PendingBook> _pendingBooks = [];
  
  // Getters
  List<PendingBook> get pendingBooks => _pendingBooks.where((b) => b.status == 'pending').toList();
  List<PendingBook> get allBooks => List.from(_pendingBooks);
  int get pendingCount => pendingBooks.length;
  int get totalCount => _pendingBooks.length;

  /// Ajouter un livre en attente
  void addPendingBook(PendingBook pendingBook) {
    _pendingBooks.add(pendingBook);
    _logger.i('📚 Livre en attente ajouté: ${pendingBook.id}');
    notifyListeners();
  }

  /// Valider un livre (l'ajouter définitivement à la bibliothèque)
  Book? validateBook(String pendingBookId, Book? modifiedBook) {
    final index = _pendingBooks.indexWhere((b) => b.id == pendingBookId);
    if (index != -1) {
      final pendingBook = _pendingBooks[index];
      final bookToAdd = modifiedBook ?? pendingBook.recognizedBook;
      
      if (bookToAdd != null) {
        _pendingBooks[index] = pendingBook.copyWith(
          status: 'validated',
          finalBook: bookToAdd,
        );
        _logger.i('✅ Livre validé: ${bookToAdd.title}');
        notifyListeners();
        return bookToAdd; // Retourner le livre pour l'ajouter à la bibliothèque
      }
    }
    return null;
  }

  /// Rejeter un livre
  void rejectBook(String pendingBookId, String? reason) {
    final index = _pendingBooks.indexWhere((b) => b.id == pendingBookId);
    if (index != -1) {
      _pendingBooks[index] = _pendingBooks[index].copyWith(
        status: 'rejected',
        error: reason ?? 'Rejeté par l\'utilisateur',
      );
      _logger.i('❌ Livre rejeté: ${_pendingBooks[index].id}');
      notifyListeners();
    }
  }

  /// Modifier un livre en attente
  void modifyBook(String pendingBookId, Book modifiedBook) {
    final index = _pendingBooks.indexWhere((b) => b.id == pendingBookId);
    if (index != -1) {
      _pendingBooks[index] = _pendingBooks[index].copyWith(
        status: 'modified',
        finalBook: modifiedBook,
      );
      _logger.i('✏️ Livre modifié: ${modifiedBook.title}');
      notifyListeners();
    }
  }

  /// Supprimer un livre en attente
  void removePendingBook(String pendingBookId) {
    _pendingBooks.removeWhere((b) => b.id == pendingBookId);
    _logger.i('🗑️ Livre en attente supprimé: $pendingBookId');
    notifyListeners();
  }

  /// Obtenir un livre en attente par ID
  PendingBook? getPendingBook(String id) {
    try {
      return _pendingBooks.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir les statistiques
  Map<String, int> getStats() {
    return {
      'pending': _pendingBooks.where((b) => b.status == 'pending').length,
      'validated': _pendingBooks.where((b) => b.status == 'validated').length,
      'rejected': _pendingBooks.where((b) => b.status == 'rejected').length,
      'modified': _pendingBooks.where((b) => b.status == 'modified').length,
      'total': _pendingBooks.length,
    };
  }

  /// Nettoyer les anciens livres (plus de 7 jours)
  void cleanupOldBooks() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    final initialCount = _pendingBooks.length;
    
    _pendingBooks.removeWhere((book) => 
      book.timestamp.isBefore(cutoffDate) && 
      book.status != 'pending'
    );
    
    final removedCount = initialCount - _pendingBooks.length;
    if (removedCount > 0) {
      _logger.i('🧹 Nettoyage: $removedCount anciens livres supprimés');
      notifyListeners();
    }
  }
}
