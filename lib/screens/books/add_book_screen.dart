import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/models/book.dart';
import '../../providers/books_provider.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/books_api_service.dart';
import '../../core/services/camera_service.dart';
import '../../widgets/location_selector_widget.dart';

class AddBookScreen extends StatefulWidget {
  final Book? preFilledBook;
  final String? preFilledImageBase64;
  final String? preFilledOcrText;
  
  const AddBookScreen({
    super.key,
    this.preFilledBook,
    this.preFilledImageBase64,
    this.preFilledOcrText,
  });

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _publisherController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pageCountController = TextEditingController();
  
  File? _selectedImage;
  Book? _detectedBook;
  bool _isProcessing = false;
  String? _ocrText;
  String _processingStatus = '';
  
  // Variables pour la localisation
  String? _selectedFurnitureId;
  int? _selectedShelfNumber;
  int? _selectedPosition;
  
  final CameraService _cameraService = CameraService();
  final OCRService _ocrService = OCRService();
  final BooksApiService _booksApiService = BooksApiService();

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _preFillData();
  }

  void _preFillData() {
    if (widget.preFilledBook != null) {
      final book = widget.preFilledBook!;
      _titleController.text = book.title;
      _authorController.text = book.author;
      _isbnController.text = book.isbn ?? '';
      _publisherController.text = book.publisher ?? '';
      _descriptionController.text = book.description ?? '';
      _pageCountController.text = book.pageCount?.toString() ?? '';
      _selectedFurnitureId = book.furnitureId;
      _selectedShelfNumber = book.shelfNumber;
      _selectedPosition = book.position;
    }
    
    if (widget.preFilledOcrText != null) {
      _ocrText = widget.preFilledOcrText;
    }
    
    if (widget.preFilledImageBase64 != null) {
      // Convertir l'image base64 en fichier temporaire
      _loadImageFromBase64(widget.preFilledImageBase64!);
    }
  }

  Future<void> _loadImageFromBase64(String base64String) async {
    try {
      final bytes = base64Decode(base64String);
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(bytes);
      setState(() {
        _selectedImage = tempFile;
      });
    } catch (e) {
      print('Erreur lors du chargement de l\'image: $e');
    }
  }

  Future<void> _initializeServices() async {
    print('DEBUG: Initializing services');
    await _ocrService.initialize();
    print('DEBUG: OCR service initialized');
    await _booksApiService.initialize();
    print('DEBUG: Books API service initialized');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _publisherController.dispose();
    _descriptionController.dispose();
    _pageCountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    print('DEBUG: _pickImage() called');
    try {
      print('DEBUG: Calling showImageSourceDialog');
      final File? imageFile = await _cameraService.showImageSourceDialog(context);
      print('DEBUG: showImageSourceDialog returned: ${imageFile != null ? imageFile.path : "null"}');
      
      if (imageFile != null) {
        print('DEBUG: Image file received, setting state and processing');
        setState(() {
          _selectedImage = imageFile;
          _isProcessing = true;
        });
        
        // Temporisation pour stabiliser l'image avant l'analyse OCR
        print('DEBUG: Starting image stabilization delay (2 seconds)');
        setState(() {
          _processingStatus = 'Stabilisation de l\'image...';
        });
        await Future.delayed(const Duration(seconds: 2));
        
        print('DEBUG: Calling _processImage()');
        await _processImage();
        print('DEBUG: _processImage() completed');
      } else {
        print('DEBUG: No image file received');
      }
    } catch (e) {
      print('DEBUG: Error in _pickImage(): $e');
      _showErrorSnackBar('Erreur lors de la sélection de l\'image: $e');
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) {
      print('DEBUG: No image selected');
      return;
    }

    print('DEBUG: Starting image processing for: ${_selectedImage!.path}');

    try {
      // Étape 1: Extraction du texte avec OCR
      print('DEBUG: Step 1 - Starting OCR extraction');
      setState(() {
        _processingStatus = 'Analyse OCR en cours...';
      });
      final ocrResult = await _ocrService.extractTextFromImage(_selectedImage!);
      
      if (ocrResult != null) {
        print('DEBUG: OCR result received: ${ocrResult.text.length} characters');
        setState(() {
          _ocrText = ocrResult.text;
        });

        // Étape 2: Extraction des informations du livre
        print('DEBUG: Step 2 - Extracting book info from OCR text');
        setState(() {
          _processingStatus = 'Extraction des informations du livre...';
        });
        final bookInfo = _ocrService.extractBookInfoFromText(ocrResult.text);
        
        if (bookInfo != null) {
          print('DEBUG: Book info extracted - Title: ${bookInfo.title}, Author: ${bookInfo.author}');
          
          // Étape 3: Recherche dans Google Books API
          print('DEBUG: Step 3 - Searching in Google Books API');
          setState(() {
            _processingStatus = 'Recherche dans Google Books...';
          });
          final enrichedBook = await _booksApiService.findBookFromOcrData(
            title: bookInfo.title,
            author: bookInfo.author,
            isbn: bookInfo.isbn,
            publisher: bookInfo.publisher,
          );

          print('DEBUG: Google Books search completed - Found: ${enrichedBook != null}');

          setState(() {
            _detectedBook = enrichedBook;
            if (enrichedBook != null) {
              _titleController.text = enrichedBook.title;
              _authorController.text = enrichedBook.author;
              _isbnController.text = enrichedBook.isbn ?? '';
              _publisherController.text = enrichedBook.publisher ?? '';
              _descriptionController.text = enrichedBook.description ?? '';
              _pageCountController.text = enrichedBook.pageCount?.toString() ?? '';
            } else if (bookInfo.title != null || bookInfo.author != null) {
              // Utiliser les informations extraites par OCR même si pas trouvé dans Google Books
              _titleController.text = bookInfo.title ?? '';
              _authorController.text = bookInfo.author ?? '';
              _isbnController.text = bookInfo.isbn ?? '';
              _publisherController.text = bookInfo.publisher ?? '';
            }
            _isProcessing = false;
            _processingStatus = '';
          });

          if (enrichedBook != null) {
            _showSuccessSnackBar('Livre détecté et enrichi avec succès !');
          } else {
            _showInfoSnackBar('Texte extrait, mais livre non trouvé dans Google Books. Vous pouvez compléter manuellement.');
          }
        } else {
          print('DEBUG: No book info extracted from OCR text');
          setState(() {
            _isProcessing = false;
            _processingStatus = '';
          });
          _showInfoSnackBar('Aucune information de livre détectée dans l\'image.');
        }
      } else {
        print('DEBUG: OCR extraction failed');
        setState(() {
          _isProcessing = false;
          _processingStatus = '';
        });
        _showErrorSnackBar('Impossible d\'extraire le texte de l\'image.');
      }
    } catch (e) {
      print('DEBUG: Error during image processing: $e');
      setState(() {
        _isProcessing = false;
        _processingStatus = '';
      });
      _showErrorSnackBar('Erreur lors du traitement de l\'image: $e');
    }
  }

  Future<void> _saveBook() async {
    print('DEBUG: _saveBook() called');
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Form validation failed');
      return;
    }

    print('DEBUG: Form validation passed, creating book');
    try {
      final book = Book(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        isbn: _isbnController.text.trim().isNotEmpty ? _isbnController.text.trim() : null,
        publisher: _publisherController.text.trim().isNotEmpty ? _publisherController.text.trim() : null,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        pageCount: _pageCountController.text.trim().isNotEmpty ? int.tryParse(_pageCountController.text.trim()) : null,
        coverImagePath: _selectedImage?.path,
        furnitureId: _selectedFurnitureId,
        shelfNumber: _selectedShelfNumber,
        position: _selectedPosition,
        addedDate: DateTime.now(),
        isRead: false,
        rating: null,
        notes: null,
        genre: null,
        language: null,
        publicationDate: null,
        coverImageUrl: null,
      );

      print('DEBUG: Book created, adding to provider');
      final booksProvider = Provider.of<BooksProvider>(context, listen: false);
      await booksProvider.addBook(book);
      print('DEBUG: Book added successfully');

      if (mounted) {
        _showSuccessSnackBar('Livre ajouté avec succès !');
        context.pop();
      }
    } catch (e) {
      print('DEBUG: Error in _saveBook(): $e');
      _showErrorSnackBar('Erreur lors de l\'ajout du livre: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConfig.errorColor,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConfig.successColor,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConfig.infoColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preFilledBook != null ? 'Valider le livre mobile' : 'Ajouter un livre'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _saveBook,
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConfig.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section photographie
              _buildPhotoSection(),
              
              const SizedBox(height: AppConfig.spacingL),
              
              // Section formulaire
              _buildFormSection(),
              
              const SizedBox(height: AppConfig.spacingL),
              
              // Section localisation
              _buildLocationSection(),
              
              const SizedBox(height: AppConfig.spacingL),
              
              // Section texte OCR (si disponible)
              if (_ocrText != null) _buildOcrSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.camera_alt, color: AppConfig.primaryColor),
                const SizedBox(width: AppConfig.spacingS),
                Text(
                  'Photographier un livre',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppConfig.spacingM),
            
            if (_selectedImage != null) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  border: Border.all(color: AppConfig.textHint),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppConfig.spacingM),
            ],
            
            if (_isProcessing) ...[
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppConfig.spacingM),
                    Text(
                      _processingStatus.isNotEmpty 
                        ? _processingStatus 
                        : 'Traitement de l\'image en cours...',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_selectedImage == null ? 'Photographier un livre' : 'Changer l\'image'),
                ),
              ),
            ],
            
            if (_detectedBook != null) ...[
              const SizedBox(height: AppConfig.spacingM),
              Container(
                padding: const EdgeInsets.all(AppConfig.spacingM),
                decoration: BoxDecoration(
                  color: AppConfig.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  border: Border.all(color: AppConfig.successColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppConfig.successColor),
                    const SizedBox(width: AppConfig.spacingS),
                    Expanded(
                      child: Text(
                        'Livre détecté: ${_detectedBook!.title}',
                        style: const TextStyle(
                          color: AppConfig.successColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, color: AppConfig.primaryColor),
                const SizedBox(width: AppConfig.spacingS),
                Text(
                  'Informations du livre',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppConfig.spacingM),
            
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                hintText: 'Entrez le titre du livre',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le titre est obligatoire';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppConfig.spacingM),
            
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Auteur *',
                hintText: 'Entrez le nom de l\'auteur',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'L\'auteur est obligatoire';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppConfig.spacingM),
            
            TextFormField(
              controller: _isbnController,
              decoration: const InputDecoration(
                labelText: 'ISBN',
                hintText: 'Entrez l\'ISBN du livre',
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            
            const SizedBox(height: AppConfig.spacingM),
            
            TextFormField(
              controller: _publisherController,
              decoration: const InputDecoration(
                labelText: 'Éditeur',
                hintText: 'Entrez l\'éditeur',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            
            const SizedBox(height: AppConfig.spacingM),
            
            TextFormField(
              controller: _pageCountController,
              decoration: const InputDecoration(
                labelText: 'Nombre de pages',
                hintText: 'Entrez le nombre de pages',
                prefixIcon: Icon(Icons.pages),
              ),
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: AppConfig.spacingM),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Entrez une description du livre',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOcrSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_fields, color: AppConfig.primaryColor),
                const SizedBox(width: AppConfig.spacingS),
                Text(
                  'Texte extrait',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppConfig.spacingM),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConfig.spacingM),
              decoration: BoxDecoration(
                color: AppConfig.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                border: Border.all(color: AppConfig.textHint.withOpacity(0.3)),
              ),
              child: Text(
                _ocrText!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppConfig.primaryColor),
                const SizedBox(width: AppConfig.spacingS),
                Text(
                  'Localisation physique',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppConfig.spacingM),
            Text(
              'Sélectionnez où ranger ce livre dans votre bibliothèque physique.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConfig.textHint,
              ),
            ),
            const SizedBox(height: AppConfig.spacingM),
            LocationSelectorWidget(
              selectedFurnitureId: _selectedFurnitureId,
              selectedShelfNumber: _selectedShelfNumber,
              selectedPosition: _selectedPosition,
              onLocationSelected: (furnitureId, shelfNumber, position) {
                setState(() {
                  _selectedFurnitureId = furnitureId;
                  _selectedShelfNumber = shelfNumber;
                  _selectedPosition = position;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

