import 'dart:io';
import 'package:logger/logger.dart';

import '../models/book.dart';
import 'ocr_service.dart';
import 'books_api_service.dart';

/// Service principal pour la reconnaissance et l'enrichissement automatique de livres
class BookRecognitionService {
  static final Logger _logger = Logger();
  
  final OCRService _ocrService;
  final BooksApiService _booksApiService;

  BookRecognitionService(this._ocrService, this._booksApiService);

  /// Processus complet : OCR + Enrichissement Google Books
  Future<Book?> recognizeBookFromImage(File imageFile) async {
    try {
      _logger.i('Starting book recognition from image...');
      
      // Étape 1: Extraction OCR
      final ocrResult = await _ocrService.extractTextFromImage(imageFile);
      if (ocrResult == null) {
        _logger.w('No text extracted from image');
        return null;
      }

      _logger.i('OCR completed with confidence: ${ocrResult.confidence}');

      // Étape 2: Extraction des informations du livre
      final bookInfo = _ocrService.extractBookInfoFromText(ocrResult.text);
      if (bookInfo == null) {
        _logger.w('No book information extracted from OCR text');
        return null;
      }

      _logger.i('Book info extracted: ${bookInfo.title} by ${bookInfo.author}');

      // Étape 3: Enrichissement via Google Books API
      final enrichedBook = await _booksApiService.findBookFromOcrData(
        title: bookInfo.title,
        author: bookInfo.author,
        isbn: bookInfo.isbn,
        publisher: bookInfo.publisher,
      );

      if (enrichedBook != null) {
        _logger.i('Book enriched successfully: ${enrichedBook.title}');
        return enrichedBook;
      } else {
        _logger.w('No matching book found in Google Books, creating from OCR data');
        // Créer un livre à partir des données OCR si aucun match trouvé
        return _createBookFromOcrData(bookInfo);
      }
    } catch (e) {
      _logger.e('Error in book recognition process: $e');
      return null;
    }
  }

  /// Recherche un livre par ISBN
  Future<Book?> findBookByIsbn(String isbn) async {
    try {
      _logger.i('Searching book by ISBN: $isbn');
      return await _booksApiService.searchBookByIsbn(isbn);
    } catch (e) {
      _logger.e('Error searching book by ISBN: $e');
      return null;
    }
  }

  /// Recherche un livre par titre et auteur
  Future<Book?> findBookByTitleAndAuthor(String title, String author) async {
    try {
      _logger.i('Searching book: "$title" by $author');
      return await _booksApiService.enrichBookInfo(title, author);
    } catch (e) {
      _logger.e('Error searching book by title/author: $e');
      return null;
    }
  }

  /// Recherche multiple de livres
  Future<List<Book>> searchBooks(String query, {int maxResults = 10}) async {
    try {
      _logger.i('Searching books with query: $query');
      return await _booksApiService.searchBooks(query, maxResults: maxResults);
    } catch (e) {
      _logger.e('Error searching books: $e');
      return [];
    }
  }

  /// Obtient des suggestions de livres similaires
  Future<List<Book>> getBookSuggestions(String bookId) async {
    try {
      _logger.i('Getting suggestions for book: $bookId');
      return await _booksApiService.getBookSuggestions(bookId);
    } catch (e) {
      _logger.e('Error getting book suggestions: $e');
      return [];
    }
  }

  /// Crée un livre à partir des données OCR si aucun match Google Books
  Book _createBookFromOcrData(BookInfo bookInfo) {
    return Book(
      title: bookInfo.title ?? 'Titre inconnu',
      author: bookInfo.author ?? 'Auteur inconnu',
      isbn: bookInfo.isbn,
      publisher: bookInfo.publisher,
      genre: bookInfo.genre,
      description: bookInfo.description,
      // Marquer comme non enrichi pour permettre un enrichissement ultérieur
      notes: 'Livre ajouté via reconnaissance OCR - enrichissement possible',
    );
  }

  /// Valide la qualité des données OCR
  bool _validateOcrQuality(OCRResult ocrResult) {
    // Seuil de confiance minimum
    if (ocrResult.confidence < 0.5) {
      _logger.w('Low OCR confidence: ${ocrResult.confidence}');
      return false;
    }

    // Vérifier la longueur du texte extrait
    if (ocrResult.text.length < 10) {
      _logger.w('OCR text too short: ${ocrResult.text.length} characters');
      return false;
    }

    return true;
  }

  /// Analyse la qualité des informations extraites
  BookInfoQuality _analyzeBookInfoQuality(BookInfo bookInfo) {
    int score = 0;
    final issues = <String>[];

    if (bookInfo.title != null && bookInfo.title!.isNotEmpty) {
      score += 3;
    } else {
      issues.add('Titre manquant');
    }

    if (bookInfo.author != null && bookInfo.author!.isNotEmpty) {
      score += 3;
    } else {
      issues.add('Auteur manquant');
    }

    if (bookInfo.isbn != null && bookInfo.isbn!.isNotEmpty) {
      score += 2;
    } else {
      issues.add('ISBN manquant');
    }

    if (bookInfo.publisher != null && bookInfo.publisher!.isNotEmpty) {
      score += 1;
    }

    if (bookInfo.genre != null && bookInfo.genre!.isNotEmpty) {
      score += 1;
    }

    return BookInfoQuality(
      score: score,
      maxScore: 10,
      issues: issues,
      quality: score >= 7 ? 'excellent' : score >= 5 ? 'good' : score >= 3 ? 'fair' : 'poor',
    );
  }
}

/// Classe pour évaluer la qualité des informations extraites
class BookInfoQuality {
  final int score;
  final int maxScore;
  final List<String> issues;
  final String quality; // excellent, good, fair, poor

  BookInfoQuality({
    required this.score,
    required this.maxScore,
    required this.issues,
    required this.quality,
  });

  double get percentage => (score / maxScore) * 100;
  bool get isGood => score >= 5;
  bool get isExcellent => score >= 7;
}

