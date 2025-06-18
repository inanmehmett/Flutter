import 'package:flutter/material.dart';
import '../../domain/entities/book.dart';
import 'level_tag.dart';
import 'reading_time_view.dart';

class BookDetails extends StatelessWidget {
  final Book book;

  const BookDetails({
    super.key,
    required this.book,
  });

  int? _parseLevel(String? level) {
    if (level == null) return null;
    try {
      return int.parse(level);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = _parseLevel(book.textLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (book.author.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            book.author,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            if (level != null) LevelTag(level: level),
            if (level != null)
              const SizedBox(width: 8),
            ReadingTimeView(
              minutes: book.estimatedReadingTimeInMinutes,
            ),
          ],
        ),
      ],
    );
  }
}
