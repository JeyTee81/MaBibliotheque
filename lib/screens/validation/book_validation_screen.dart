import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

import '../../providers/pending_books_provider.dart';
import '../../providers/books_provider.dart';
import '../../core/models/pending_book.dart';
import '../../core/models/book.dart';
import 'book_edit_dialog.dart';

class BookValidationScreen extends StatefulWidget {
  final String? pendingBookId;
  
  const BookValidationScreen({super.key, this.pendingBookId});

  @override
  State<BookValidationScreen> createState() => _BookValidationScreenState();
}

class _BookValidationScreenState extends State<BookValidationScreen> {
  static final Logger _logger = Logger();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Livres'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<PendingBooksProvider>(
            builder: (context, provider, child) {
              final stats = provider.getStats();
              return Chip(
                label: Text('${stats['pending']} en attente'),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<PendingBooksProvider>(
        builder: (context, provider, child) {
          // Si un ID spécifique est fourni, afficher ce livre
          if (widget.pendingBookId != null) {
            final allBooks = provider.allBooks;
            final specificBook = allBooks.firstWhere(
              (book) => book.id == widget.pendingBookId,
              orElse: () => throw Exception('Livre non trouvé'),
            );
            
            if (specificBook.status != 'pending') {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ce livre a déjà été traité',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Statut: ${specificBook.status}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Retour'),
                    ),
                  ],
                ),
              );
            }
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildPendingBookCard(specificBook),
            );
          }
          
          // Sinon, afficher tous les livres en attente
          final pendingBooks = provider.pendingBooks;
          
          if (pendingBooks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucun livre en attente de validation',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tous les livres ont été traités !',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingBooks.length,
            itemBuilder: (context, index) {
              final pendingBook = pendingBooks[index];
              return _buildPendingBookCard(pendingBook);
            },
          );
        },
      ),
    );
  }

  Widget _buildPendingBookCard(PendingBook pendingBook) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec image et infos de base
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image du livre (photo reçue de l'app mobile)
                Container(
                  width: 80,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(pendingBook.imageBase64),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.camera_alt, size: 40);
                      },
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Informations du livre
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pendingBook.recognizedBook?.title ?? 'Titre non reconnu',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pendingBook.recognizedBook?.author ?? 'Auteur non reconnu',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      
                      // Texte OCR
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
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
                              pendingBook.ocrText,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Informations de la requête
                      Row(
                        children: [
                          Icon(
                            Icons.phone_android,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Appareil: ${pendingBook.deviceId}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reçu: ${_formatDateTime(pendingBook.timestamp)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editBook(pendingBook),
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _validateBook(pendingBook),
                    icon: const Icon(Icons.check),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectBook(pendingBook),
                    icon: const Icon(Icons.close),
                    label: const Text('Rejeter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editBook(PendingBook pendingBook) async {
    final result = await showDialog<Book>(
      context: context,
      builder: (context) => BookEditDialog(
        initialBook: pendingBook.recognizedBook,
        ocrText: pendingBook.ocrText,
      ),
    );

    if (result != null) {
      final provider = Provider.of<PendingBooksProvider>(context, listen: false);
      provider.modifyBook(pendingBook.id, result);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Livre modifié: ${result.title}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  Future<void> _validateBook(PendingBook pendingBook) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valider le livre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir ajouter ce livre à votre bibliothèque ?'),
            const SizedBox(height: 16),
            Text(
              'Titre: ${pendingBook.recognizedBook?.title ?? 'Non reconnu'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Auteur: ${pendingBook.recognizedBook?.author ?? 'Non reconnu'}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final pendingProvider = Provider.of<PendingBooksProvider>(context, listen: false);
      final booksProvider = Provider.of<BooksProvider>(context, listen: false);
      
      final bookToAdd = pendingProvider.validateBook(pendingBook.id, null);
      
      if (bookToAdd != null) {
        await booksProvider.addBook(bookToAdd);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Livre ajouté: ${bookToAdd.title}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectBook(PendingBook pendingBook) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter le livre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pourquoi rejetez-vous ce livre ?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Raison (optionnel)',
                hintText: 'Ex: Mauvais livre, texte illisible...',
              ),
              maxLines: 3,
              onChanged: (value) {
                // Stocker la raison
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('Rejeté par l\'utilisateur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (reason != null) {
      final provider = Provider.of<PendingBooksProvider>(context, listen: false);
      provider.rejectBook(pendingBook.id, reason);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Livre rejeté'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

