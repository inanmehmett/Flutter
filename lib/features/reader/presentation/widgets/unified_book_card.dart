import 'package:flutter/material.dart';
import '../../domain/entities/book.dart';
import '../../data/models/book_model.dart';
import '../../../../core/config/app_config.dart';

class UnifiedBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;

  const UnifiedBookCard({
    super.key,
    required this.book,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _buildHorizontalCard(context);
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


  String _resolveImageUrl(String? imageUrl, String? iconUrl) {
    final url = (iconUrl != null && iconUrl.isNotEmpty) ? iconUrl : (imageUrl ?? '');
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${AppConfig.apiBaseUrl}$url';
    return '${AppConfig.apiBaseUrl}/$url';
  }
}
