import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/models/book.dart';
import '../../providers/books_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<Book> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchBooks() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final booksProvider = Provider.of<BooksProvider>(context, listen: false);
      final query = _searchController.text.trim().toLowerCase();
      
      // Rechercher dans la bibliothèque locale
      final allBooks = booksProvider.allBooks;
      final results = allBooks.where((book) {
        return book.title.toLowerCase().contains(query) ||
               book.author.toLowerCase().contains(query) ||
               (book.isbn?.toLowerCase().contains(query) ?? false) ||
               (book.publisher?.toLowerCase().contains(query) ?? false);
      }).toList();
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la recherche: $e'),
          backgroundColor: AppConfig.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma bibliothèque'),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(AppConfig.spacingM),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher dans ma bibliothèque...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                      ),
                    ),
                    onSubmitted: (_) => _searchBooks(),
                  ),
                ),
                const SizedBox(width: AppConfig.spacingM),
                ElevatedButton(
                  onPressed: _isSearching ? null : _searchBooks,
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Rechercher'),
                ),
              ],
            ),
          ),

          // Résultats de recherche
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: AppConfig.textHint,
            ),
            const SizedBox(height: AppConfig.spacingM),
            Text(
              'Recherchez un livre',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppConfig.textSecondary,
              ),
            ),
            const SizedBox(height: AppConfig.spacingS),
            Text(
              'Tapez le titre, l\'auteur ou l\'ISBN',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConfig.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppConfig.spacingM),
            Text('Recherche en cours...'),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppConfig.textHint,
            ),
            const SizedBox(height: AppConfig.spacingM),
            Text(
              'Aucun résultat trouvé',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppConfig.textSecondary,
              ),
            ),
            const SizedBox(height: AppConfig.spacingS),
            Text(
              'Essayez avec d\'autres mots-clés',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConfig.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppConfig.spacingM),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppConfig.spacingM),
          child: ListTile(
            leading: book.coverImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      book.coverImageUrl!,
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 70,
                          decoration: BoxDecoration(
                            color: AppConfig.backgroundSecondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.book),
                        );
                      },
                    ),
                  )
                : Container(
                    width: 50,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppConfig.backgroundSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.book),
                  ),
            title: Text(
              book.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.author),
                if (book.publisher != null)
                  Text(
                    book.publisher!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (book.description != null)
                  Text(
                    book.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                // TODO: Implémenter l'ajout du livre à la bibliothèque
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité d\'ajout à venir'),
                  ),
                );
              },
              child: const Text('Ajouter'),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}