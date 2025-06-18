import 'package:flutter/material.dart';
import '../../domain/entities/book.dart';
import 'book_cover.dart';
import 'book_details.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final bool showDetails;
  final Size size;
  final VoidCallback? onTap;

  const BookCard({
    super.key,
    required this.book,
    this.showDetails = true,
    this.size = const Size(120, 160),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookCover(book: book, size: size),
        if (showDetails) ...[
          const SizedBox(height: 8),
          BookDetails(book: book),
        ],
      ],
    );

    final card = Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: content,
      ),
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
