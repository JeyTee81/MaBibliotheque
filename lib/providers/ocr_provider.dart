import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../core/services/ocr_service.dart';
import '../core/services/books_api_service.dart';
import '../core/models/book.dart';

class OCRProvider extends ChangeNotifier {
  static final Logger _logger = Logger();
  
  final OCRService _ocrService = OCRService();
  final BooksApiService _booksApiService = BooksApiService();
  
  bool _isProcessing = false;
  String? _extractedText;
  Book? _detectedBook;
  String? _errorMessage;

  bool get isProcessing => _isProcessing;
  String? get extractedText => _extractedText;
  Book? get detectedBook => _detectedBook;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    try {
      // Initialize services asynchronously to avoid blocking the main thread
      await Future.wait([
        _ocrService.initialize().catchError((e) {
          _logger.w('OCR service initialization failed: $e');
          return null;
        }),
        _booksApiService.initialize().catchError((e) {
          _logger.w('Books API service initialization failed: $e');
          return null;
        }),
      ]);
      _logger.i('OCR and Books API services initialized');
    } catch (e) {
      _logger.e('Error initializing OCR services: $e');
      _errorMessage = 'Erreur d\'initialisation des services OCR';
      notifyListeners();
    }
  }

  Future<void> processImage(File imageFile) async {
    _isProcessing = true;
    _errorMessage = null;
    _extractedText = null;
    _detectedBook = null;
    notifyListeners();

    try {
      // Étape 1: Extraction du texte avec OCR
      _logger.i('Starting OCR text extraction');
      final ocrResult = await _ocrService.extractTextFromImage(imageFile);
      
      if (ocrResult == null) {
        throw Exception('Impossible d\'extraire le texte de l\'image');
      }

      _extractedText = ocrResult.text;
      _logger.i('OCR text extracted: ${_extractedText!.length} characters');
      notifyListeners();

      // Étape 2: Extraction des informations du livre
      final bookInfo = _ocrService.extractBookInfoFromText(_extractedText!);
      
      if (bookInfo == null) {
        _logger.w('No book information extracted from OCR text');
        return;
      }

      _logger.i('Book info extracted: ${bookInfo.title} by ${bookInfo.author}');

      // Étape 3: Recherche dans Google Books API
      _logger.i('Searching in Google Books API');
      final enrichedBook = await _booksApiService.findBookFromOcrData(
        title: bookInfo.title,
        author: bookInfo.author,
        isbn: bookInfo.isbn,
        publisher: bookInfo.publisher,
      );

      if (enrichedBook != null) {
        _detectedBook = enrichedBook;
        _logger.i('Book found and enriched: ${enrichedBook.title}');
      } else {
        _logger.w('Book not found in Google Books API');
        // Créer un livre basique avec les informations OCR
        _detectedBook = Book(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: bookInfo.title ?? 'Titre inconnu',
          author: bookInfo.author ?? 'Auteur inconnu',
          isbn: bookInfo.isbn,
          publisher: bookInfo.publisher,
          description: bookInfo.description,
          addedDate: DateTime.now(),
          isRead: false,
        );
      }
    } catch (e) {
      _logger.e('Error processing image: $e');
      _errorMessage = e.toString();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void clearResults() {
    _extractedText = null;
    _detectedBook = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<List<Book>> searchBooks(String query) async {
    try {
      _logger.i('Searching books with query: $query');
      return await _booksApiService.searchBooks(query);
    } catch (e) {
      _logger.e('Error searching books: $e');
      return [];
    }
  }

  Future<Book?> getBookByIsbn(String isbn) async {
    try {
      _logger.i('Getting book by ISBN: $isbn');
      return await _booksApiService.getBookByIsbn(isbn);
    } catch (e) {
      _logger.e('Error getting book by ISBN: $e');
      return null;
    }
  }

  void setApiKey(String apiKey) {
    _ocrService.setApiKey(apiKey);
    _booksApiService.setApiKey(apiKey);
    _logger.i('API key set for OCR and Books services');
  }

  /// Extract text from image bytes (for mobile requests)
  Future<String> extractTextFromImageBytes(List<int> imageBytes) async {
    try {
      _logger.i('Extracting text from image bytes (${imageBytes.length} bytes)');
      return await _ocrService.extractTextFromBytes(imageBytes);
    } catch (e) {
      _logger.e('Error extracting text from bytes: $e');
      rethrow;
    }
  }
}
