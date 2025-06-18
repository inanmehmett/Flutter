import 'package:flutter/material.dart';
import '../../domain/entities/book.dart';

class BookCover extends StatelessWidget {
  final Book book;
  final Size size;

  const BookCover({
    super.key,
    required this.book,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (book.iconUrl != null && book.iconUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          book.iconUrl!,
          width: size.width,
          height: size.height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackCover(),
        ),
      );
    }
    return _buildFallbackCover();
  }

  Widget _buildFallbackCover() {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.book,
        size: 24,
        color: Colors.orange,
      ),
    );
  }
}
