import 'package:flutter/material.dart';

class AttributedStringData {
  final String string;
  final TextStyle style;
  final Map<String, dynamic> attributes;

  AttributedStringData({
    required this.string,
    required this.style,
    this.attributes = const {},
  });

  Map<String, dynamic> toJson() => {
        'string': string,
        'style': {
          'fontSize': style.fontSize,
          'fontWeight': style.fontWeight?.index,
          'fontFamily': style.fontFamily,
          'height': style.height,
          'letterSpacing': style.letterSpacing,
        },
        'attributes': attributes,
      };

  factory AttributedStringData.fromJson(Map<String, dynamic> json) {
    final styleData = json['style'] as Map<String, dynamic>;
    return AttributedStringData(
      string: json['string'] as String,
      style: TextStyle(
        fontSize: styleData['fontSize'] as double?,
        fontWeight: styleData['fontWeight'] != null
            ? FontWeight.values[styleData['fontWeight'] as int]
            : null,
        fontFamily: styleData['fontFamily'] as String?,
        height: styleData['height'] as double?,
        letterSpacing: styleData['letterSpacing'] as double?,
      ),
      attributes: Map<String, dynamic>.from(json['attributes'] ?? {}),
    );
  }
}

class Range {
  final int start;
  final int end;

  const Range(this.start, this.end);

  int get length => end - start;

  bool intersects(Range other) {
    return start <= other.end && end >= other.start;
  }

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
      };

  factory Range.fromJson(Map<String, dynamic> json) {
    return Range(
      json['start'] as int,
      json['end'] as int,
    );
  }

  @override
  String toString() => 'Range($start, $end)';
} 