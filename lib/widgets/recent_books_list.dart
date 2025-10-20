import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/models/book.dart';

class RecentBooksList extends StatelessWidget {
  final List<Book> books;

  const RecentBooksList({
    super.key,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppConfig.spacingS),
          child: ListTile(
            leading: book.coverImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      book.coverImageUrl!,
                      width: 40,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 40,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppConfig.backgroundSecondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.book, size: 20),
                        );
                      },
                    ),
                  )
                : Container(
                    width: 40,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppConfig.backgroundSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.book, size: 20),
                  ),
            title: Text(
              book.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (book.isRead)
                  const Icon(
                    Icons.check_circle,
                    color: AppConfig.successColor,
                    size: 16,
                  ),
                const SizedBox(width: AppConfig.spacingS),
                const Icon(Icons.chevron_right, size: 16),
              ],
            ),
            onTap: () => context.go('/book/${book.id}'),
          ),
        );
      },
    );
  }
}