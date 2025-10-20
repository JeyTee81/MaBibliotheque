import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/vision/v1.dart';

import '../config/app_config.dart';

class OCRResult {
  final String text;
  final List<TextBlock> blocks;
  final double confidence;

  OCRResult({
    required this.text,
    required this.blocks,
    required this.confidence,
  });

  factory OCRResult.fromGoogleVision(Map<String, dynamic> response) {
    final textAnnotations = response['textAnnotations'] as List? ?? [];
    final fullText = textAnnotations.isNotEmpty 
        ? textAnnotations.first['description'] as String? ?? ''
        : '';
    
    final blocks = <TextBlock>[];
    double totalConfidence = 0.0;
    int blockCount = 0;

    for (final annotation in textAnnotations.skip(1)) {
      final block = TextBlock.fromGoogleVision(annotation);
      blocks.add(block);
      totalConfidence += block.confidence;
      blockCount++;
    }

    final averageConfidence = blockCount > 0 ? totalConfidence / blockCount : 0.0;

    return OCRResult(
      text: fullText,
      blocks: blocks,
      confidence: averageConfidence,
    );
  }
}

class TextBlock {
  final String text;
  final double confidence;
  final BoundingBox boundingBox;

  TextBlock({
    required this.text,
    required this.confidence,
    required this.boundingBox,
  });

  factory TextBlock.fromGoogleVision(Map<String, dynamic> annotation) {
    final text = annotation['description'] as String? ?? '';
    final confidence = (annotation['score'] as num?)?.toDouble() ?? 0.0;
    
    final vertices = annotation['boundingPoly']?['vertices'] as List? ?? [];
    final boundingBox = BoundingBox.fromVertices(vertices);

    return TextBlock(
      text: text,
      confidence: confidence,
      boundingBox: boundingBox,
    );
  }
}

class BoundingBox {
  final int x;
  final int y;
  final int width;
  final int height;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory BoundingBox.fromVertices(List<dynamic> vertices) {
    if (vertices.length < 2) {
      return BoundingBox(x: 0, y: 0, width: 0, height: 0);
    }

    final xCoords = vertices.map((v) => v['x'] as int? ?? 0).toList();
    final yCoords = vertices.map((v) => v['y'] as int? ?? 0).toList();

    final minX = xCoords.reduce((a, b) => a < b ? a : b);
    final maxX = xCoords.reduce((a, b) => a > b ? a : b);
    final minY = yCoords.reduce((a, b) => a < b ? a : b);
    final maxY = yCoords.reduce((a, b) => a > b ? a : b);

    return BoundingBox(
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY,
    );
  }
}

class BookInfo {
  final String? title;
  final String? author;
  final String? isbn;
  final String? publisher;
  final String? genre;
  final String? description;

  BookInfo({
    this.title,
    this.author,
    this.isbn,
    this.publisher,
    this.genre,
    this.description,
  });
}

class OCRService {
  static final Logger _logger = Logger();
  static const String _googleVisionApiUrl = 'https://vision.googleapis.com/v1/images:annotate';
  
  String? _apiKey;
  String? _projectId;
  AuthClient? _authClient;
  VisionApi? _visionApi;

  Future<void> initialize() async {
    try {
      // Use a timeout to prevent hanging during initialization
      await Future.any([
        _performInitialization(),
        Future.delayed(const Duration(seconds: 5), () => throw TimeoutException('OCR initialization timeout')),
      ]);
    } catch (e) {
      _logger.e('Failed to initialize OCR service: $e');
      // Continue without OCR functionality rather than crashing
    }
  }

  Future<void> _performInitialization() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('google_api_key');
    _projectId = prefs.getString('google_project_id');
    
    if (_apiKey == null || _projectId == null) {
      await _loadServiceAccountCredentials();
    }
  }

  Future<void> _loadServiceAccountCredentials() async {
    try {
      // Essayer d'abord le dossier config/ du projet
      final configFile = File('config/google_service_account.json');
      
      if (await configFile.exists()) {
        final credentialsContent = await configFile.readAsString();
        final credentials = json.decode(credentialsContent);
        
        _projectId = credentials['project_id'];
        _logger.i('Service account credentials loaded from config/');
        
        // Pour l'API Vision, nous avons besoin d'un token d'accès
        await _getAccessToken(credentials);
        return;
      }
      
      // Fallback vers le dossier documents de l'app
      final directory = await getApplicationDocumentsDirectory();
      final credentialsFile = File('${directory.path}/config/google_service_account.json');
      
      if (await credentialsFile.exists()) {
        final credentialsContent = await credentialsFile.readAsString();
        final credentials = json.decode(credentialsContent);
        
        _projectId = credentials['project_id'];
        _logger.i('Service account credentials loaded from app documents');
        await _getAccessToken(credentials);
      }
    } catch (e) {
      _logger.e('Failed to load service account credentials: $e');
    }
  }

  Future<void> _getAccessToken(Map<String, dynamic> credentials) async {
    try {
      // Créer un client d'authentification avec le service account
      final accountCredentials = ServiceAccountCredentials.fromJson(credentials);
      _authClient = await clientViaServiceAccount(
        accountCredentials,
        [VisionApi.cloudVisionScope],
      );
      
      // Initialiser l'API Vision
      _visionApi = VisionApi(_authClient!);
      _logger.i('Google Vision API client initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize Google Vision API client: $e');
    }
  }

  Future<OCRResult?> extractTextFromImage(File imageFile) async {
    _logger.i('Starting OCR text extraction for image: ${imageFile.path}');
    
    // Utiliser l'API Vision si disponible, sinon fallback vers mock
    if (_visionApi != null) {
      return await _extractTextWithVisionApi(imageFile);
    } else {
      _logger.w('Google Vision API not available, using mock OCR');
      return _mockOCRResult();
    }
  }

  Future<OCRResult?> _extractTextWithVisionApi(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Créer la requête pour l'API Vision
      final request = BatchAnnotateImagesRequest(
        requests: [
          AnnotateImageRequest(
            image: Image(content: base64Image),
            features: [
              Feature(type: 'TEXT_DETECTION', maxResults: 1),
            ],
          ),
        ],
      );

      _logger.i('Sending request to Google Vision API');
      final response = await _visionApi!.images.annotate(request);
      
      if (response.responses != null && response.responses!.isNotEmpty) {
        final firstResponse = response.responses!.first;
        
        if (firstResponse.textAnnotations != null && firstResponse.textAnnotations!.isNotEmpty) {
          _logger.i('OCR text extracted successfully: ${firstResponse.textAnnotations!.length} annotations');
          return _convertVisionResponseToOCRResult(firstResponse);
        } else {
          _logger.w('No text annotations found in the image');
        }
      } else {
        _logger.w('No responses received from Google Vision API');
      }
    } catch (e) {
      _logger.e('Error calling Google Vision API: $e');
    }

    return null;
  }

  OCRResult _convertVisionResponseToOCRResult(AnnotateImageResponse response) {
    final textAnnotations = response.textAnnotations ?? [];
    
    if (textAnnotations.isEmpty) {
      return OCRResult(
        text: '',
        blocks: [],
        confidence: 0.0,
      );
    }

    // Le premier élément contient tout le texte
    final fullText = textAnnotations.first.description ?? '';
    
    // Les autres éléments sont les blocs individuels
    final blocks = textAnnotations.skip(1).map((annotation) {
      return TextBlock(
        text: annotation.description ?? '',
        confidence: 1.0, // Google Vision ne fournit pas de score de confiance par bloc
        boundingBox: _convertBoundingPoly(annotation.boundingPoly),
      );
    }).toList();

    return OCRResult(
      text: fullText,
      blocks: blocks,
      confidence: 0.9, // Confiance par défaut
    );
  }

  BoundingBox _convertBoundingPoly(BoundingPoly? boundingPoly) {
    if (boundingPoly?.vertices == null || boundingPoly!.vertices!.isEmpty) {
      return BoundingBox(x: 0, y: 0, width: 0, height: 0);
    }

    final vertices = boundingPoly.vertices!;
    final xCoords = vertices.map((v) => v.x ?? 0).toList();
    final yCoords = vertices.map((v) => v.y ?? 0).toList();

    final minX = xCoords.reduce((a, b) => a < b ? a : b);
    final maxX = xCoords.reduce((a, b) => a > b ? a : b);
    final minY = yCoords.reduce((a, b) => a < b ? a : b);
    final maxY = yCoords.reduce((a, b) => a > b ? a : b);

    return BoundingBox(
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY,
    );
  }

  BookInfo? extractBookInfoFromText(String text) {
    try {
      final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      String? title;
      String? author;
      String? isbn;
      String? publisher;
      String? genre;

      // Recherche de l'ISBN
      final isbnRegex = RegExp(r'\b(?:ISBN(?:-1[03])?:? )?(?=[0-9X]{10}$|(?=(?:[0-9]+[- ]){3})[- 0-9X]{13}$|97[89][0-9]{10}$|(?=(?:[0-9]+[- ]){4})[- 0-9]{17}$)(?:97[89][- ]?)?[0-9]{1,5}[- ]?[0-9]+[- ]?[0-9]+[- ]?[0-9X]\b');
      final isbnMatch = isbnRegex.firstMatch(text);
      if (isbnMatch != null) {
        isbn = isbnMatch.group(0)?.replaceAll(RegExp(r'[^\dX]'), '');
      }

      // Le titre est généralement la première ligne significative
      if (lines.isNotEmpty) {
        title = lines.first.trim();
      }

      // Recherche de l'auteur (patterns communs)
      for (final line in lines) {
        final lowerLine = line.toLowerCase();
        if (lowerLine.contains('par ') || lowerLine.contains('by ') || 
            lowerLine.contains('auteur') || lowerLine.contains('author')) {
          author = line.replaceAll(RegExp(r'(par|by|auteur|author)[:\s]*', caseSensitive: false), '').trim();
          break;
        }
      }

      // Recherche de l'éditeur
      for (final line in lines) {
        final lowerLine = line.toLowerCase();
        if (lowerLine.contains('éditeur') || lowerLine.contains('publisher') || 
            lowerLine.contains('édition') || lowerLine.contains('edition')) {
          publisher = line.replaceAll(RegExp(r'(éditeur|publisher|édition|edition)[:\s]*', caseSensitive: false), '').trim();
          break;
        }
      }

      return BookInfo(
        title: title,
        author: author,
        isbn: isbn,
        publisher: publisher,
        genre: genre,
      );
    } catch (e) {
      _logger.e('Error extracting book info from text: $e');
      return null;
    }
  }

  Future<BookInfo?> extractBookInfoFromImage(File imageFile) async {
    final ocrResult = await extractTextFromImage(imageFile);
    if (ocrResult != null) {
      return extractBookInfoFromText(ocrResult.text);
    }
    return null;
  }

  /// Enrichit les informations d'un livre en utilisant Google Books API
  Future<BookInfo?> enrichBookInfoWithGoogleBooks(BookInfo bookInfo) async {
    try {
      // Cette méthode sera appelée depuis le service principal
      // qui aura accès à BooksApiService
      _logger.i('Book info ready for Google Books enrichment: ${bookInfo.title}');
      return bookInfo;
    } catch (e) {
      _logger.e('Error enriching book info with Google Books: $e');
      return bookInfo;
    }
  }

  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  void setProjectId(String projectId) {
    _projectId = projectId;
  }

  /// Extract text from image bytes (for mobile requests)
  Future<String> extractTextFromBytes(List<int> imageBytes) async {
    try {
      _logger.i('Extracting text from image bytes (${imageBytes.length} bytes)');
      
      // Utiliser l'API Vision si disponible, sinon fallback vers mock
      if (_visionApi != null) {
        return await _extractTextFromBytesWithVisionApi(imageBytes);
      } else {
        _logger.w('Google Vision API not available, using mock OCR');
        return _mockOCRResult().text;
      }
    } catch (e) {
      _logger.e('Error extracting text from bytes: $e');
      rethrow;
    }
  }

  Future<String> _extractTextFromBytesWithVisionApi(List<int> imageBytes) async {
    try {
      // Convertir les bytes en base64
      final base64Image = base64Encode(imageBytes);

      // Créer la requête pour l'API Vision
      final request = BatchAnnotateImagesRequest(
        requests: [
          AnnotateImageRequest(
            image: Image(content: base64Image),
            features: [
              Feature(type: 'TEXT_DETECTION', maxResults: 1),
            ],
          ),
        ],
      );

      _logger.i('Sending request to Google Vision API for bytes');
      final response = await _visionApi!.images.annotate(request);
      
      if (response.responses != null && response.responses!.isNotEmpty) {
        final firstResponse = response.responses!.first;
        
        if (firstResponse.textAnnotations != null && firstResponse.textAnnotations!.isNotEmpty) {
          final ocrResult = _convertVisionResponseToOCRResult(firstResponse);
          _logger.i('OCR text extracted from bytes: ${ocrResult.text.length} characters');
          return ocrResult.text;
        } else {
          _logger.w('No text annotations found in the image bytes');
          return '';
        }
      } else {
        _logger.w('No responses received from Google Vision API for bytes');
        return '';
      }
    } catch (e) {
      _logger.e('Error calling Google Vision API for bytes: $e');
      rethrow;
    }
  }

  /// Méthode mock pour tester l'OCR sans API key
  OCRResult _mockOCRResult() {
    _logger.i('Using mock OCR result for testing');
    
    // Texte mock d'un livre
    final mockText = '''Le Petit Prince
Antoine de Saint-Exupéry
ISBN: 9782070413061
Éditeur: Gallimard
Collection: Folio

Il était une fois un petit prince qui habitait une planète à peine plus grande que lui...''';

    final mockBlocks = [
      TextBlock(
        text: 'Le Petit Prince',
        confidence: 0.95,
        boundingBox: BoundingBox(x: 0, y: 0, width: 200, height: 30),
      ),
      TextBlock(
        text: 'Antoine de Saint-Exupéry',
        confidence: 0.90,
        boundingBox: BoundingBox(x: 0, y: 40, width: 250, height: 25),
      ),
      TextBlock(
        text: 'ISBN: 9782070413061',
        confidence: 0.85,
        boundingBox: BoundingBox(x: 0, y: 80, width: 180, height: 20),
      ),
    ];

    return OCRResult(
      text: mockText,
      blocks: mockBlocks,
      confidence: 0.90,
    );
  }
}
