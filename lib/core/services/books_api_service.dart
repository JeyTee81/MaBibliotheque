import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:googleapis/books/v1.dart' as books;
import 'package:googleapis_auth/auth_io.dart';

import '../models/book.dart';
import '../config/app_config.dart';

class GoogleBooksResponse {
  final List<GoogleBook> items;
  final int totalItems;

  GoogleBooksResponse({
    required this.items,
    required this.totalItems,
  });

  factory GoogleBooksResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .map((item) => GoogleBook.fromJson(item))
        .toList();
    
    return GoogleBooksResponse(
      items: items,
      totalItems: json['totalItems'] ?? 0,
    );
  }
}

class GoogleBook {
  final String id;
  final VolumeInfo volumeInfo;

  GoogleBook({
    required this.id,
    required this.volumeInfo,
  });

  factory GoogleBook.fromJson(Map<String, dynamic> json) {
    return GoogleBook(
      id: json['id'] ?? '',
      volumeInfo: VolumeInfo.fromJson(json['volumeInfo'] ?? {}),
    );
  }

  Book toBook() {
    return Book(
      id: id,
      title: volumeInfo.title,
      author: volumeInfo.authors?.join(', ') ?? 'Auteur inconnu',
      isbn: volumeInfo.getIsbn(),
      publisher: volumeInfo.publisher,
      publicationDate: volumeInfo.publishedDate != null 
          ? DateTime.tryParse(volumeInfo.publishedDate!)
          : null,
      description: volumeInfo.description,
      coverImageUrl: volumeInfo.imageLinks?.thumbnail,
      pageCount: volumeInfo.pageCount,
      language: volumeInfo.language,
      rating: volumeInfo.averageRating,
    );
  }
}

class VolumeInfo {
  final String title;
  final List<String>? authors;
  final String? publisher;
  final String? publishedDate;
  final String? description;
  final int? pageCount;
  final String? language;
  final double? averageRating;
  final ImageLinks? imageLinks;
  final List<IndustryIdentifier>? industryIdentifiers;

  VolumeInfo({
    required this.title,
    this.authors,
    this.publisher,
    this.publishedDate,
    this.description,
    this.pageCount,
    this.language,
    this.averageRating,
    this.imageLinks,
    this.industryIdentifiers,
  });

  factory VolumeInfo.fromJson(Map<String, dynamic> json) {
    return VolumeInfo(
      title: json['title'] ?? '',
      authors: (json['authors'] as List?)?.cast<String>(),
      publisher: json['publisher'],
      publishedDate: json['publishedDate'],
      description: json['description'],
      pageCount: json['pageCount'],
      language: json['language'],
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      imageLinks: json['imageLinks'] != null 
          ? ImageLinks.fromJson(json['imageLinks'])
          : null,
      industryIdentifiers: (json['industryIdentifiers'] as List?)
          ?.map((id) => IndustryIdentifier.fromJson(id))
          .toList(),
    );
  }

  String? getIsbn() {
    if (industryIdentifiers == null) return null;
    
    // Recherche ISBN-13 en priorité, puis ISBN-10
    for (final identifier in industryIdentifiers!) {
      if (identifier.type == 'ISBN_13') {
        return identifier.identifier;
      }
    }
    
    for (final identifier in industryIdentifiers!) {
      if (identifier.type == 'ISBN_10') {
        return identifier.identifier;
      }
    }
    
    return null;
  }
}

class ImageLinks {
  final String? smallThumbnail;
  final String? thumbnail;

  ImageLinks({
    this.smallThumbnail,
    this.thumbnail,
  });

  factory ImageLinks.fromJson(Map<String, dynamic> json) {
    return ImageLinks(
      smallThumbnail: json['smallThumbnail'],
      thumbnail: json['thumbnail'],
    );
  }
}

class IndustryIdentifier {
  final String type;
  final String identifier;

  IndustryIdentifier({
    required this.type,
    required this.identifier,
  });

  factory IndustryIdentifier.fromJson(Map<String, dynamic> json) {
    return IndustryIdentifier(
      type: json['type'] ?? '',
      identifier: json['identifier'] ?? '',
    );
  }
}

class BooksApiService {
  static final Logger _logger = Logger();
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  
  String? _apiKey;
  books.BooksApi? _booksApi;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Use a timeout to prevent hanging during initialization
      await Future.any([
        _performInitialization(),
        Future.delayed(const Duration(seconds: 3), () => throw TimeoutException('Books API initialization timeout')),
      ]);
    } catch (e) {
      _logger.e('Failed to initialize Google Books API: $e');
      // Continue without Books API functionality rather than crashing
    }
  }

  Future<void> _performInitialization() async {
    // Initialiser l'API Google Books
    _booksApi = books.BooksApi(http.Client());
    _isInitialized = true;
    _logger.i('Google Books API initialized successfully');
  }

  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  Future<List<Book>> searchBooks(String query, {int maxResults = 10}) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$_baseUrl?q=$encodedQuery&maxResults=$maxResults';
      
      final response = await http.get(
        Uri.parse(url),
        headers: _apiKey != null ? {'Authorization': 'Bearer $_apiKey'} : {},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booksResponse = GoogleBooksResponse.fromJson(data);
        
        return booksResponse.items.map((googleBook) => googleBook.toBook()).toList();
      } else {
        _logger.e('Google Books API error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      _logger.e('Error searching books: $e');
      return [];
    }
  }

  Future<Book?> getBookByIsbn(String isbn) async {
    try {
      final results = await searchBooks('isbn:$isbn', maxResults: 1);
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      _logger.e('Error getting book by ISBN: $e');
      return null;
    }
  }

  Future<List<Book>> searchBooksByTitle(String title, {int maxResults = 10}) async {
    return await searchBooks('intitle:$title', maxResults: maxResults);
  }

  Future<List<Book>> searchBooksByAuthor(String author, {int maxResults = 10}) async {
    return await searchBooks('inauthor:$author', maxResults: maxResults);
  }

  Future<Book?> getBookDetails(String bookId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$bookId'),
        headers: _apiKey != null ? {'Authorization': 'Bearer $_apiKey'} : {},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final googleBook = GoogleBook.fromJson(data);
        return googleBook.toBook();
      } else {
        _logger.e('Google Books API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting book details: $e');
      return null;
    }
  }

  Future<List<Book>> getRelatedBooks(String bookId, {int maxResults = 5}) async {
    try {
      final book = await getBookDetails(bookId);
      if (book == null) return [];

      // Recherche de livres similaires par auteur et genre
      final authorBooks = await searchBooksByAuthor(book.author, maxResults: maxResults ~/ 2);
      final titleBooks = await searchBooksByTitle(book.title, maxResults: maxResults ~/ 2);
      
      final relatedBooks = <Book>[];
      relatedBooks.addAll(authorBooks);
      relatedBooks.addAll(titleBooks);
      
      // Supprimer les doublons et le livre original
      final uniqueBooks = <String, Book>{};
      for (final book in relatedBooks) {
        if (book.id != bookId) {
          uniqueBooks[book.id] = book;
        }
      }
      
      return uniqueBooks.values.take(maxResults).toList();
    } catch (e) {
      _logger.e('Error getting related books: $e');
      return [];
    }
  }

  // Méthodes spécialisées pour l'enrichissement automatique

  /// Recherche un livre par ISBN avec priorité
  Future<Book?> searchBookByIsbn(String isbn) async {
    try {
      // Nettoyer l'ISBN
      final cleanIsbn = isbn.replaceAll(RegExp(r'[^\dX]'), '');
      
      // Essayer d'abord avec l'ISBN exact
      final results = await searchBooks('isbn:$cleanIsbn', maxResults: 1);
      if (results.isNotEmpty) {
        return results.first;
      }
      
      // Essayer avec une recherche plus large
      final broadResults = await searchBooks(cleanIsbn, maxResults: 5);
      for (final book in broadResults) {
        if (book.isbn != null && book.isbn!.replaceAll(RegExp(r'[^\dX]'), '') == cleanIsbn) {
          return book;
        }
      }
      
      return null;
    } catch (e) {
      _logger.e('Error searching book by ISBN: $e');
      return null;
    }
  }

  /// Enrichit les informations d'un livre à partir de son titre et auteur
  Future<Book?> enrichBookInfo(String title, String author) async {
    try {
      // Recherche par titre et auteur
      final query = 'intitle:"$title" inauthor:"$author"';
      final results = await searchBooks(query, maxResults: 3);
      
      if (results.isNotEmpty) {
        // Retourner le premier résultat (le plus pertinent)
        return results.first;
      }
      
      // Si pas de résultat exact, essayer avec le titre seul
      final titleResults = await searchBooks('intitle:"$title"', maxResults: 5);
      if (titleResults.isNotEmpty) {
        // Chercher le meilleur match par auteur
        for (final book in titleResults) {
          if (book.author.toLowerCase().contains(author.toLowerCase()) ||
              author.toLowerCase().contains(book.author.toLowerCase())) {
            return book;
          }
        }
        // Si aucun match d'auteur, retourner le premier résultat
        return titleResults.first;
      }
      
      return null;
    } catch (e) {
      _logger.e('Error enriching book info: $e');
      return null;
    }
  }

  /// Recherche intelligente basée sur les informations extraites par OCR
  Future<Book?> findBookFromOcrData({
    String? title,
    String? author,
    String? isbn,
    String? publisher,
  }) async {
    try {
      // Priorité 1: Recherche par ISBN si disponible
      if (isbn != null && isbn.isNotEmpty) {
        final isbnResult = await searchBookByIsbn(isbn);
        if (isbnResult != null) {
          _logger.i('Book found by ISBN: ${isbnResult.title}');
          return isbnResult;
        }
      }
      
      // Priorité 2: Recherche par titre et auteur
      if (title != null && title.isNotEmpty && author != null && author.isNotEmpty) {
        final enrichedResult = await enrichBookInfo(title, author);
        if (enrichedResult != null) {
          _logger.i('Book found by title/author: ${enrichedResult.title}');
          return enrichedResult;
        }
      }
      
      // Priorité 3: Recherche par titre seul
      if (title != null && title.isNotEmpty) {
        final titleResults = await searchBooks('intitle:"$title"', maxResults: 1);
        if (titleResults.isNotEmpty) {
          _logger.i('Book found by title only: ${titleResults.first.title}');
          return titleResults.first;
        }
      }
      
      // Priorité 4: Recherche par auteur seul
      if (author != null && author.isNotEmpty) {
        final authorResults = await searchBooks('inauthor:"$author"', maxResults: 1);
        if (authorResults.isNotEmpty) {
          _logger.i('Book found by author only: ${authorResults.first.title}');
          return authorResults.first;
        }
      }
      
      _logger.w('No book found for OCR data: title=$title, author=$author, isbn=$isbn');
      return null;
    } catch (e) {
      _logger.e('Error finding book from OCR data: $e');
      return null;
    }
  }

  /// Obtient des suggestions de livres similaires
  Future<List<Book>> getBookSuggestions(String bookId) async {
    try {
      final book = await getBookDetails(bookId);
      if (book == null) return [];
      
      final suggestions = <Book>[];
      
      // Recherche par auteur
      final authorBooks = await searchBooksByAuthor(book.author, maxResults: 3);
      suggestions.addAll(authorBooks.where((b) => b.id != bookId));
      
      // Recherche par genre si disponible
      if (book.genre != null) {
        final genreBooks = await searchBooks('subject:"${book.genre}"', maxResults: 3);
        suggestions.addAll(genreBooks.where((b) => b.id != bookId));
      }
      
      // Supprimer les doublons et limiter
      final uniqueSuggestions = <String, Book>{};
      for (final suggestion in suggestions) {
        uniqueSuggestions[suggestion.id] = suggestion;
      }
      
      return uniqueSuggestions.values.take(5).toList();
    } catch (e) {
      _logger.e('Error getting book suggestions: $e');
      return [];
    }
  }
}
