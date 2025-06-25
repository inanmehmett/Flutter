import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class HighlightedTextView extends StatelessWidget {
  final String text;
  final int? highlightedWordIndex;
  final double fontSize;
  final Color textColor;
  final Color highlightColor;
  final Color backgroundColor;
  final double lineHeight;
  final EdgeInsets padding;
  final Function(int)? onWordTap;

  const HighlightedTextView({
    Key? key,
    required this.text,
    this.highlightedWordIndex,
    this.fontSize = 16.0,
    this.textColor = Colors.black87,
    this.highlightColor = Colors.yellow,
    this.backgroundColor = Colors.white,
    this.lineHeight = 1.6,
    this.padding = const EdgeInsets.all(16.0),
    this.onWordTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final words = _splitTextIntoWords(text);
    
    return Container(
      color: backgroundColor,
      padding: padding,
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: fontSize,
            height: lineHeight,
            color: textColor,
          ),
          children: _buildTextSpans(words),
        ),
      ),
    );
  }

  List<TextSpan> _buildTextSpans(List<String> words) {
    final spans = <TextSpan>[];
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final isHighlighted = i == highlightedWordIndex;
      
      TapGestureRecognizer? recognizer;
      if (onWordTap != null) {
        recognizer = TapGestureRecognizer();
        recognizer.onTap = () => onWordTap!(i);
      }
      
      spans.add(
        TextSpan(
          text: word,
          style: TextStyle(
            backgroundColor: isHighlighted ? highlightColor : Colors.transparent,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
          recognizer: recognizer,
        ),
      );
      
      // Add space between words (except for the last word)
      if (i < words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }
    
    return spans;
  }

  List<String> _splitTextIntoWords(String text) {
    // Split by whitespace and punctuation, but keep punctuation with words
    final regex = RegExp(r'\b\w+\b|[^\w\s]');
    final matches = regex.allMatches(text);
    return matches.map((match) => match.group(0)!).toList();
  }
} 