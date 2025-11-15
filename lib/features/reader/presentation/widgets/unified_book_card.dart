import 'package:flutter/material.dart';
import '../../domain/entities/book.dart';
import '../../data/models/book_model.dart';
import '../../../../core/config/app_config.dart';

class UnifiedBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final bool isGridLayout;

  const UnifiedBookCard({
    super.key,
    required this.book,
    this.onTap,
    this.isGridLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    return isGridLayout ? _buildGridCard(context) : _buildHorizontalCard(context);
  }

  Widget _buildHorizontalCard(BuildContext context) {
    final cover = _resolveImageUrl(book.imageUrl, book.iconUrl);
    const double cardWidth = 121;
    final double coverHeight = cardWidth * 1.30;

    return SizedBox(
      width: cardWidth,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ?? () {
          Navigator.pushNamed(
            context,
            '/book-preview',
            arguments: BookModel.fromBook(book),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: coverHeight,
                width: double.infinity,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                child: cover.isEmpty
                    ? const Icon(Icons.menu_book, size: 40)
                    : Image.network(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.menu_book, size: 40),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Daily English',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${book.estimatedReadingTimeInMinutes} min • Lvl ${book.textLevel ?? '1'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 13,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    final cover = _resolveImageUrl(book.imageUrl, book.iconUrl);
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ?? () {
          Navigator.pushNamed(
            context,
            '/book-preview',
            arguments: BookModel.fromBook(book),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Container(
                  height: 100, // Reduced height to prevent overflow
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  child: cover.isEmpty
                      ? const Icon(Icons.menu_book, size: 36)
                      : Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.menu_book, size: 36),
                        ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Lvl ${book.textLevel ?? '1'}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '${book.estimatedReadingTimeInMinutes}dk',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveImageUrl(String? imageUrl, String? iconUrl) {
    final url = (iconUrl != null && iconUrl.isNotEmpty) ? iconUrl : (imageUrl ?? '');
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${AppConfig.apiBaseUrl}$url';
    return '${AppConfig.apiBaseUrl}/$url';
  }
}
