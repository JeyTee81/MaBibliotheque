import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/book.dart';

class BookEditDialog extends StatefulWidget {
  final Book? initialBook;
  final String ocrText;

  const BookEditDialog({
    super.key,
    this.initialBook,
    required this.ocrText,
  });

  @override
  State<BookEditDialog> createState() => _BookEditDialogState();
}

class _BookEditDialogState extends State<BookEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _isbnController;
  late final TextEditingController _publisherController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _genreController;
  late final TextEditingController _pageCountController;
  late final TextEditingController _languageController;
  late final TextEditingController _ratingController;

  @override
  void initState() {
    super.initState();
    
    _titleController = TextEditingController(text: widget.initialBook?.title ?? '');
    _authorController = TextEditingController(text: widget.initialBook?.author ?? '');
    _isbnController = TextEditingController(text: widget.initialBook?.isbn ?? '');
    _publisherController = TextEditingController(text: widget.initialBook?.publisher ?? '');
    _descriptionController = TextEditingController(text: widget.initialBook?.description ?? '');
    _genreController = TextEditingController(text: widget.initialBook?.genre ?? '');
    _pageCountController = TextEditingController(text: widget.initialBook?.pageCount?.toString() ?? '');
    _languageController = TextEditingController(text: widget.initialBook?.language ?? '');
    _ratingController = TextEditingController(text: widget.initialBook?.rating?.toString() ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _publisherController.dispose();
    _descriptionController.dispose();
    _genreController.dispose();
    _pageCountController.dispose();
    _languageController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // En-tête
            Row(
              children: [
                const Icon(Icons.edit),
                const SizedBox(width: 8),
                Text(
                  'Modifier les informations du livre',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const Divider(),
            
            // Texte OCR
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Texte détecté par OCR:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.ocrText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Formulaire
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Titre (obligatoire)
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre *',
                        hintText: 'Titre du livre',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Auteur (obligatoire)
                    TextField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: 'Auteur *',
                        hintText: 'Nom de l\'auteur',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ISBN
                    TextField(
                      controller: _isbnController,
                      decoration: const InputDecoration(
                        labelText: 'ISBN',
                        hintText: '978-...',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Éditeur
                    TextField(
                      controller: _publisherController,
                      decoration: const InputDecoration(
                        labelText: 'Éditeur',
                        hintText: 'Maison d\'édition',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Genre
                    TextField(
                      controller: _genreController,
                      decoration: const InputDecoration(
                        labelText: 'Genre',
                        hintText: 'Roman, Science-fiction, etc.',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Nombre de pages
                    TextField(
                      controller: _pageCountController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de pages',
                        hintText: '250',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Langue
                    TextField(
                      controller: _languageController,
                      decoration: const InputDecoration(
                        labelText: 'Langue',
                        hintText: 'fr, en, es, etc.',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.none,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Note
                    TextField(
                      controller: _ratingController,
                      decoration: const InputDecoration(
                        labelText: 'Note (0-5)',
                        hintText: '4.5',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Résumé du livre...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),
            
            const Divider(),
            
            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveBook,
                  child: const Text('Sauvegarder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveBook() {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le titre est obligatoire'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_authorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('L\'auteur est obligatoire'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Créer le livre modifié
    final modifiedBook = Book(
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      isbn: _isbnController.text.trim().isEmpty ? null : _isbnController.text.trim(),
      publisher: _publisherController.text.trim().isEmpty ? null : _publisherController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      genre: _genreController.text.trim().isEmpty ? null : _genreController.text.trim(),
      pageCount: _pageCountController.text.trim().isEmpty 
          ? null 
          : int.tryParse(_pageCountController.text.trim()),
      language: _languageController.text.trim().isEmpty ? null : _languageController.text.trim(),
      rating: _ratingController.text.trim().isEmpty 
          ? null 
          : double.tryParse(_ratingController.text.trim()),
      coverImageUrl: widget.initialBook?.coverImageUrl,
    );

    Navigator.of(context).pop(modifiedBook);
  }
}


