import 'package:flutter/material.dart';

class BookSection extends StatelessWidget {
  final String title;
  final List<dynamic> books;
  const BookSection({super.key, required this.title, required this.books});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ...books.map((book) => ListTile(title: Text(book.toString()))),
      ],
    );
  }
}
