import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../providers/books_provider.dart';
import '../../providers/shelf_provider.dart';

class BooksListScreen extends StatefulWidget {
  const BooksListScreen({super.key});

  @override
  State<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends State<BooksListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Charger les données du ShelfProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShelfProvider>(context, listen: false).loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes livres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/add-book'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(AppConfig.spacingM),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un livre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<BooksProvider>(context, listen: false)
                              .searchBooks('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                ),
              ),
              onChanged: (value) {
                Provider.of<BooksProvider>(context, listen: false)
                    .searchBooks(value);
              },
            ),
          ),

          // Liste des livres
          Expanded(
            child: Consumer<BooksProvider>(
              builder: (context, booksProvider, child) {
                if (booksProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final books = booksProvider.filteredBooks;

                if (books.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_books_outlined,
                          size: 64,
                          color: AppConfig.textHint,
                        ),
                        const SizedBox(height: AppConfig.spacingM),
                        Text(
                          booksProvider.searchQuery.isNotEmpty
                              ? 'Aucun livre trouvé'
                              : 'Aucun livre dans votre bibliothèque',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppConfig.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppConfig.spacingS),
                        Text(
                          booksProvider.searchQuery.isNotEmpty
                              ? 'Essayez avec d\'autres mots-clés'
                              : 'Commencez par ajouter votre premier livre',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppConfig.textSecondary,
                          ),
                        ),
                        if (booksProvider.searchQuery.isEmpty) ...[
                          const SizedBox(height: AppConfig.spacingL),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/add-book'),
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter un livre'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConfig.spacingM,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
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
                            if (book.isbn != null)
                              Text(
                                'ISBN: ${book.isbn}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            Consumer<ShelfProvider>(
                              builder: (context, shelfProvider, child) {
                                String locationString = 'Non rangé';
                                
                                // Debug: Afficher les valeurs du livre
                                print('DEBUG: Book ${book.title} - furnitureId: ${book.furnitureId}, shelfNumber: ${book.shelfNumber}, position: ${book.position}');
                                print('DEBUG: ShelfProvider has ${shelfProvider.rooms.length} rooms and ${shelfProvider.furniture.length} furniture');
                                
                                // Si le livre a des coordonnées de localisation
                                if (book.furnitureId != null && book.shelfNumber != null && book.position != null) {
                                  try {
                                    // Trouver le meuble
                                    final furniture = shelfProvider.furniture.firstWhere(
                                      (f) => f.id == book.furnitureId,
                                    );
                                    
                                    // Trouver la pièce
                                    final room = shelfProvider.rooms.firstWhere(
                                      (r) => r.id == furniture.roomId,
                                    );
                                    
                                    locationString = '${room.name} → ${furniture.name} → Étagère ${book.shelfNumber} → Position ${book.position}';
                                    print('DEBUG: Found location: $locationString');
                                  } catch (e) {
                                    locationString = 'Localisation incomplète: $e';
                                    print('DEBUG: Error finding location: $e');
                                  }
                                } else {
                                  print('DEBUG: Book missing location data');
                                }
                                
                                return Text(
                                  locationString,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: locationString == 'Non rangé' 
                                        ? AppConfig.errorColor 
                                        : AppConfig.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (book.isRead)
                              const Icon(
                                Icons.check_circle,
                                color: AppConfig.successColor,
                              ),
                            const SizedBox(width: AppConfig.spacingS),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => context.go('/book/${book.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add-book'),
        child: const Icon(Icons.add),
      ),
    );
  }
}