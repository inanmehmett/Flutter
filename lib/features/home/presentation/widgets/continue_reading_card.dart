import 'package:flutter/material.dart';
import '../../../../core/storage/last_read_manager.dart';
import '../../../../core/di/injection.dart';
import '../../../reader/domain/entities/book.dart';
import '../../../../core/config/app_config.dart';

/// Continue reading section showing recent books with progress.
/// 
/// Features:
/// - iOS 17 style design
/// - Horizontal scrollable book cards
/// - Progress indicators
/// - Empty and loading states
class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final lastReadManager = getIt<LastReadManager>();
    
    return StreamBuilder<LastReadInfo?>(
      stream: lastReadManager.updates,
      builder: (context, _) {
        return FutureBuilder<List<LastReadInfo>>(
          future: lastReadManager.getRecentReads(limit: 5),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <LastReadInfo>[];
            
            if (snapshot.connectionState == ConnectionState.waiting && items.isEmpty) {
              return const _LoadingCard();
            }

            if (items.isEmpty) {
              return const _EmptyCard();
            }

            return _BookListCard(items: items);
          },
        );
      },
    );
  }
}

/// Loading state card
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Loading...',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 17,
                color: Color(0xFF1D1D1F),
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state card
class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.book_outlined,
              color: Color(0xFF8E8E93),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'No recent books',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 17,
                color: Color(0xFF1D1D1F),
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Book list with horizontal scroll
class _BookListCard extends StatelessWidget {
  final List<LastReadInfo> items;

  const _BookListCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Continue Reading',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final cardHeight = screenWidth < 400 ? 110.0 : 128.0;
              
              return SizedBox(
                height: cardHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length.clamp(0, 5),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final info = items[index];
                    return _BookCard(info: info, cardHeight: cardHeight);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Individual book card with progress
class _BookCard extends StatelessWidget {
  final LastReadInfo info;
  final double cardHeight;

  const _BookCard({
    required this.info,
    required this.cardHeight,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 400 ? 300.0 : 340.0;
    final coverHeight = cardHeight - 32;
    final coverWidth = coverHeight * 0.68;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tintedBg = isDark
        ? Colors.white.withOpacity(0.06)
        : Theme.of(context).colorScheme.primary.withOpacity(0.06);
    final tintedBorder = isDark
        ? Colors.white.withOpacity(0.10)
        : Theme.of(context).colorScheme.primary.withOpacity(0.12);
    
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pushNamed(context, '/reader', arguments: info.book);
      },
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: tintedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tintedBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildCover(context, coverHeight, coverWidth),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBookInfo(screenWidth),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFC7C7CC),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context, double height, double width) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: height,
            width: width,
            color: const Color(0xFFF2F2F7),
            child: _CoverImage(info: info),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E5EA),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (info.pageIndex + 1) / 50,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF007AFF),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookInfo(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            info.book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: screenWidth < 400 ? 14 : 15,
              height: 1.2,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Page ${info.pageIndex + 1} • ${info.book.estimatedReadingTimeInMinutes}m',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: screenWidth < 400 ? 12 : 13,
            color: const Color(0xFF8E8E93),
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Level ${info.book.textLevel ?? '1'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: screenWidth < 400 ? 10 : 11,
            color: const Color(0xFF34C759),
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

/// Cover image with error handling
class _CoverImage extends StatelessWidget {
  final LastReadInfo info;

  const _CoverImage({required this.info});

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveImageUrl(info.book.imageUrl, info.book.iconUrl);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        width: 48,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
        child: resolved.isEmpty
            ? const Icon(Icons.menu_book, size: 24)
            : Image.network(
                resolved,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.menu_book, size: 24),
              ),
      ),
    );
  }

  String _resolveImageUrl(String? imageUrl, String? iconUrl) {
    final url = (iconUrl != null && iconUrl.isNotEmpty)
        ? iconUrl
        : (imageUrl ?? '');
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${AppConfig.apiBaseUrl}$url';
    return '${AppConfig.apiBaseUrl}/$url';
  }
}

