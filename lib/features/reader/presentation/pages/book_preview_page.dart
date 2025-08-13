import 'package:flutter/material.dart';
import '../../data/models/book_model.dart';

class BookPreviewPage extends StatelessWidget {
  final BookModel? book;
  const BookPreviewPage({Key? key, this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Eğer arguments ile BookModel gelirse onu kullan, yoksa mockBook göster
    final BookModel displayBook = book ?? ModalRoute.of(context)?.settings.arguments as BookModel? ?? _getMockBook();
    final imageUrl = displayBook.imageUrl ?? displayBook.iconUrl;
    final title = displayBook.title;
    final author = displayBook.author;
    final description = displayBook.summary ?? 'The murder of a curator at the Louvre reveals a sinister plot to uncover a secret that has been protected since the days of Christ. Only the victim\'s granddaughter and Robert Langdon, a famed symbologist, can untangle the clues he left behind.';
    final level = displayBook.textLevel ?? '1';
    final readingTime = displayBook.estimatedReadingTimeInMinutes;
    final rating = displayBook.rating ?? 4.5;

    final size = MediaQuery.of(context).size;
    final double coverHeight = (size.height * 0.35).clamp(220.0, 360.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Kapak görseli ve overlay (yüksekliği ekrana göre ayarlı)
            _buildCoverImageSection(context, imageUrl, coverHeight),
            // İçerik
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleAndAuthorSection(title, author),
                    SizedBox(height: 16),
                    _buildRatingSection(rating),
                    SizedBox(height: 16),
                    _buildDescriptionSection(description),
                    SizedBox(height: 16),
                    _buildMetadataSection(level, readingTime),
                    SizedBox(height: 32),
                    _buildStartReadingButton(context, displayBook),
                    SizedBox(height: 20), // Alt boşluk
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildCoverImageSection(BuildContext context, String? imageUrl, double coverHeight) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: coverHeight,
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.book, size: 80, color: Colors.grey[500]),
                  ),
                )
              : Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.book, size: 80, color: Colors.grey[500]),
                ),
        ),
        // Gradient overlay
        Container(
          width: double.infinity,
          height: coverHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white,
              ],
            ),
          ),
        ),
        // Back button
        Positioned(
          left: 16,
          top: 16,
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.5),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        // Search button
        Positioned(
          right: 16,
          top: 16,
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.5),
            child: IconButton(
              icon: Icon(Icons.search, color: Colors.orange),
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleAndAuthorSection(String title, String author) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Text(
          author,
          style: TextStyle(
            fontSize: 20,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(double rating) {
    return Row(
      children: [
        _StarRating(rating: rating),
        SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 20,
            color: Colors.orange[800],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(String description) {
    return Text(
      description,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[800],
        height: 1.5,
      ),
    );
  }

  Widget _buildMetadataSection(String level, int readingTime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LevelBadge(level: level),
        SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.timer, size: 18, color: Colors.grey[700]),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Estimated reading time: $readingTime minutes',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStartReadingButton(BuildContext context, BookModel book) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () {
              // Okumaya devam et butonu aksiyonu
              Navigator.pushNamed(context, '/reader', arguments: book);
            },
            child: Text(
              'Okumaya Başla',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          '📱 Çevrimdışı erişim mevcut',
          style: TextStyle(
            fontSize: 12,
            color: Colors.green[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1, // BookPreview, Books sekmesi altında
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/books');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/quiz');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book),
          label: 'Books',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.quiz),
          label: 'Quiz',
        ),
      ],
    );
  }

  // Mock data oluşturucu
  BookModel _getMockBook() {
    return BookModel(
      id: '1',
      title: 'The Da Vinci Code',
      author: 'Dan Brown',
      content: 'Sample content...',
      summary: 'The murder of a curator at the Louvre reveals a sinister plot to uncover a secret that has been protected since the days of Christ. Only the victim\'s granddaughter and Robert Langdon, a famed symbologist, can untangle the clues he left behind.',
      textLevel: '3',
      textLanguage: 'en',
      translationLanguage: 'tr',
      estimatedReadingTimeInMinutes: 45,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      imageUrl: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400&h=600&fit=crop',
      rating: 4.5,
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;
  const _LevelBadge({required this.level});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Level: $level',
        style: TextStyle(
          fontSize: 14,
          color: Colors.orange[800],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  const _StarRating({required this.rating});
  
  @override
  Widget build(BuildContext context) {
    int fullStars = rating.floor();
    bool halfStar = (rating - fullStars) >= 0.5;
    
    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: Colors.amber, size: 24);
        } else if (index == fullStars && halfStar) {
          return Icon(Icons.star_half, color: Colors.amber, size: 24);
        } else {
          return Icon(Icons.star_border, color: Colors.grey[400], size: 24);
        }
      }),
    );
  }
} 