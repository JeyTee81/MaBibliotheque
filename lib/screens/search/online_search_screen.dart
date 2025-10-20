import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/models/book.dart';
import '../../providers/books_provider.dart';
import '../../providers/ocr_provider.dart';
import '../../widgets/location_selector_widget.dart';

class OnlineSearchScreen extends StatefulWidget {
  const OnlineSearchScreen({super.key});

  @override
  State<OnlineSearchScreen> createState() => _OnlineSearchScreenState();
}

class _OnlineSearchScreenState extends State<OnlineSearchScreen> {
  final _searchController = TextEditingController();
  List<Book> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchOnline() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final ocrProvider = Provider.of<OCRProvider>(context, listen: false);
      final results = await ocrProvider.searchBooks(_searchController.text.trim());
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la recherche: $e';
        _isSearching = false;
      });
    }
  }

  Future<void> _addToLibrary(Book book) async {
    // Variables pour la localisation
    String? selectedFurnitureId;
    int? selectedShelfNumber;
    int? selectedPosition;

    // Afficher le dialogue de sélection de localisation
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.add_location, color: AppConfig.primaryColor),
              const SizedBox(width: AppConfig.spacingS),
              const Text('Ajouter à la bibliothèque'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations du livre
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConfig.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConfig.spacingS),
                        Text(
                          'Par ${book.author}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (book.isbn != null) ...[
                          const SizedBox(height: AppConfig.spacingS),
                          Text(
                            'ISBN: ${book.isbn}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConfig.spacingM),
                
                // Section de localisation
                Text(
                  'Où ranger ce livre ?',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppConfig.spacingS),
                LocationSelectorWidget(
                  selectedFurnitureId: selectedFurnitureId,
                  selectedShelfNumber: selectedShelfNumber,
                  selectedPosition: selectedPosition,
                  onLocationSelected: (furnitureId, shelfNumber, position) {
                    print('DEBUG: Location selected - furnitureId: $furnitureId, shelfNumber: $shelfNumber, position: $position');
                    setState(() {
                      selectedFurnitureId = furnitureId;
                      selectedShelfNumber = shelfNumber;
                      selectedPosition = position;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      print('DEBUG: Saving book with location - furnitureId: $selectedFurnitureId, shelfNumber: $selectedShelfNumber, position: $selectedPosition');
      try {
        // Créer le livre avec la localisation
        final bookWithLocation = book.copyWith(
          furnitureId: selectedFurnitureId,
          shelfNumber: selectedShelfNumber,
          position: selectedPosition,
        );

        final booksProvider = Provider.of<BooksProvider>(context, listen: false);
        await booksProvider.addBook(bookWithLocation);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${book.title} ajouté à votre bibliothèque !'),
              backgroundColor: AppConfig.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'ajout: $e'),
              backgroundColor: AppConfig.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche en ligne'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConfig.spacingM),
        child: Column(
          children: [
            // Barre de recherche
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConfig.spacingM),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Rechercher un livre sur Google Books',
                        hintText: 'Titre, auteur, ISBN...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchResults.clear();
                                    _errorMessage = null;
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                        ),
                      ),
                      onSubmitted: (_) => _searchOnline(),
                    ),
                    const SizedBox(height: AppConfig.spacingM),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSearching ? null : _searchOnline,
                        icon: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isSearching ? 'Recherche...' : 'Rechercher'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppConfig.spacingM,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppConfig.spacingM),
            
            // Résultats de recherche
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
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

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppConfig.errorColor,
            ),
            const SizedBox(height: AppConfig.spacingM),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConfig.spacingM),
            ElevatedButton(
              onPressed: _searchOnline,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
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
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConfig.spacingS),
            Text(
              'Essayez avec d\'autres mots-clés',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConfig.textHint,
              ),
            ),
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
              Icons.search,
              size: 64,
              color: AppConfig.textHint,
            ),
            const SizedBox(height: AppConfig.spacingM),
            Text(
              'Recherchez un livre',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConfig.spacingS),
            Text(
              'Tapez le titre, l\'auteur ou l\'ISBN pour rechercher sur Google Books',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConfig.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppConfig.spacingM),
          child: ListTile(
            leading: book.coverImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppConfig.borderRadius),
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
                            color: AppConfig.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                          ),
                          child: const Icon(
                            Icons.book,
                            color: AppConfig.primaryColor,
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    width: 50,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppConfig.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                    ),
                    child: const Icon(
                      Icons.book,
                      color: AppConfig.primaryColor,
                    ),
                  ),
            title: Text(
              book.title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (book.author.isNotEmpty)
                  Text(
                    book.author,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (book.publisher != null)
                  Text(
                    book.publisher!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConfig.textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (book.publicationDate != null)
                  Text(
                    'Publié: ${book.publicationDate!.year}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConfig.textHint,
                    ),
                  ),
              ],
            ),
            trailing: ElevatedButton.icon(
              onPressed: () => _addToLibrary(book),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.successColor,
                foregroundColor: Colors.white,
              ),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
