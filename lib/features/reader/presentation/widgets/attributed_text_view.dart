import 'package:flutter/material.dart';

class AttributedTextView extends StatefulWidget {
  final String text;
  final ValueChanged<String?> onWordSelected;
  final bool showTooltip;
  final Offset tooltipPosition;
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final Color highlightColor;
  final TextRange? highlightRange;

  const AttributedTextView({
    super.key,
    required this.text,
    required this.onWordSelected,
    required this.showTooltip,
    required this.tooltipPosition,
    required this.fontSize,
    required this.textColor,
    required this.backgroundColor,
    this.highlightColor = Colors.orange,
    this.highlightRange,
  });

  @override
  State<AttributedTextView> createState() => _AttributedTextViewState();
}

class _AttributedTextViewState extends State<AttributedTextView> {
  final GlobalKey _textKey = GlobalKey();
  late TextSpan _textSpan;
  late TextPainter _textPainter;
  late List<TextPosition> _wordBoundaries;

  @override
  void initState() {
    super.initState();
    _initializeTextPainter();
  }

  @override
  void didUpdateWidget(AttributedTextView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.fontSize != widget.fontSize ||
        oldWidget.textColor != widget.textColor) {
      _initializeTextPainter();
    }
  }

  void _initializeTextPainter() {
    _textSpan = TextSpan(
      text: widget.text,
      style: TextStyle(
        fontSize: widget.fontSize,
        color: widget.textColor,
      ),
    );

    _textPainter = TextPainter(
      text: _textSpan,
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    _wordBoundaries = _getWordBoundaries();
  }

  List<TextPosition> _getWordBoundaries() {
    final List<TextPosition> boundaries = [];
    final RegExp wordRegex = RegExp(r'\b\w+\b');
    final matches = wordRegex.allMatches(widget.text);

    for (final match in matches) {
      boundaries.add(TextPosition(offset: match.start));
      boundaries.add(TextPosition(offset: match.end));
    }

    return boundaries;
  }

  String? _getWordAtPosition(Offset position) {
    final RenderBox? renderBox =
        _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final localPosition = renderBox.globalToLocal(position);
    final TextPosition textPosition =
        _textPainter.getPositionForOffset(localPosition);
    final int offset = textPosition.offset;

    // Find the word boundaries
    int start = 0;
    int end = widget.text.length;

    for (int i = 0; i < _wordBoundaries.length - 1; i += 2) {
      if (offset >= _wordBoundaries[i].offset &&
          offset <= _wordBoundaries[i + 1].offset) {
        start = _wordBoundaries[i].offset;
        end = _wordBoundaries[i + 1].offset;
        break;
      }
    }

    if (start < end) {
      String word = widget.text.substring(start, end);
      // Trim punctuation except hyphens and apostrophes
      word = word.replaceAll(RegExp(r"[^\w'-]"), '');
      return word.isNotEmpty ? word : null;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        final word = _getWordAtPosition(details.globalPosition);
        widget.onWordSelected(word);
      },
      child: Container(
        key: _textKey,
        color: widget.backgroundColor,
        child: SelectableText.rich(
          TextSpan(
            text: widget.text,
            style: TextStyle(
              fontSize: widget.fontSize,
              color: widget.textColor,
            ),
          ),
          onSelectionChanged: (selection, cause) {
            if (selection.isValid && selection.start != selection.end) {
              final word =
                  widget.text.substring(selection.start, selection.end);
              widget.onWordSelected(word);
            }
          },
        ),
      ),
    );
  }
}
