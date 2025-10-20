import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/models/book.dart';
import '../../providers/books_provider.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;

  const BookDetailScreen({
    super.key,
    required this.bookId,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? _book;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  void _loadBook() {
    final booksProvider = Provider.of<BooksProvider>(context, listen: false);
    _book = booksProvider.getBookById(widget.bookId);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleReadStatus() async {
    if (_book == null) return;

    try {
      final updatedBook = Book(
        id: _book!.id,
        title: _book!.title,
        author: _book!.author,
        isbn: _book!.isbn,
        publisher: _book!.publisher,
        description: _book!.description,
        pageCount: _book!.pageCount,
        coverImageUrl: _book!.coverImageUrl,
        coverImagePath: _book!.coverImagePath,
        addedDate: _book!.addedDate,
        isRead: !_book!.isRead,
        rating: _book!.rating,
        notes: _book!.notes,
        genre: _book!.genre,
        language: _book!.language,
        publicationDate: _book!.publicationDate,
      );

      final booksProvider = Provider.of<BooksProvider>(context, listen: false);
      await booksProvider.updateBook(updatedBook);
      
      setState(() {
        _book = updatedBook;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _book!.isRead 
                ? 'Livre marqué comme lu' 
                : 'Livre marqué comme non lu'
          ),
          backgroundColor: AppConfig.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $e'),
          backgroundColor: AppConfig.errorColor,
        ),
      );
    }
  }

  Future<void> _deleteBook() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le livre'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce livre ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppConfig.errorColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final booksProvider = Provider.of<BooksProvider>(context, listen: false);
        await booksProvider.deleteBook(widget.bookId);
        
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: AppConfig.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_book == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Livre non trouvé'),
        ),
        body: const Center(
          child: Text('Ce livre n\'existe pas ou a été supprimé.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_book!.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  // TODO: Implémenter l'édition
                  break;
                case 'delete':
                  _deleteBook();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: AppConfig.spacingS),
                    Text('Modifier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppConfig.errorColor),
                    SizedBox(width: AppConfig.spacingS),
                    Text('Supprimer', style: TextStyle(color: AppConfig.errorColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConfig.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de couverture
            if (_book!.coverImageUrl != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  child: Image.network(
                    _book!.coverImageUrl!,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 300,
                        width: 200,
                        decoration: BoxDecoration(
                          color: AppConfig.backgroundSecondary,
                          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                        ),
                        child: const Icon(Icons.book, size: 64),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: AppConfig.spacingL),

            // Informations principales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConfig.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _book!.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConfig.spacingS),
                    Text(
                      'par ${_book!.author}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppConfig.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppConfig.spacingM),

                    // Statut de lecture
                    Row(
                      children: [
                        Icon(
                          _book!.isRead ? Icons.check_circle : Icons.bookmark_border,
                          color: _book!.isRead ? AppConfig.successColor : AppConfig.textSecondary,
                        ),
                        const SizedBox(width: AppConfig.spacingS),
                        Text(
                          _book!.isRead ? 'Lu' : 'Non lu',
                          style: TextStyle(
                            color: _book!.isRead ? AppConfig.successColor : AppConfig.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConfig.spacingM),

            // Informations détaillées
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConfig.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConfig.spacingM),

                    if (_book!.isbn != null) ...[
                      _buildInfoRow('ISBN', _book!.isbn!),
                      const SizedBox(height: AppConfig.spacingS),
                    ],
                    if (_book!.publisher != null) ...[
                      _buildInfoRow('Éditeur', _book!.publisher!),
                      const SizedBox(height: AppConfig.spacingS),
                    ],
                    if (_book!.pageCount != null) ...[
                      _buildInfoRow('Pages', _book!.pageCount.toString()),
                      const SizedBox(height: AppConfig.spacingS),
                    ],
                    if (_book!.language != null) ...[
                      _buildInfoRow('Langue', _book!.language!),
                      const SizedBox(height: AppConfig.spacingS),
                    ],
                    _buildInfoRow('Ajouté le', _formatDate(_book!.addedDate)),
                  ],
                ),
              ),
            ),

            if (_book!.description != null) ...[
              const SizedBox(height: AppConfig.spacingM),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConfig.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConfig.spacingM),
                      Text(_book!.description!),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppConfig.spacingL),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleReadStatus,
                    icon: Icon(_book!.isRead ? Icons.bookmark_border : Icons.check_circle),
                    label: Text(_book!.isRead ? 'Marquer non lu' : 'Marquer lu'),
                  ),
                ),
                const SizedBox(width: AppConfig.spacingM),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implémenter l'édition
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppConfig.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}