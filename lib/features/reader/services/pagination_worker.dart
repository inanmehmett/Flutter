import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PaginationWorker {
  static Future<AttributedStringData> makePage({
    required String fullText,
    required Range range,
    required TextStyle style,
    required Size size,
  }) async {
    return compute(_makePageInIsolate, {
      'text': fullText,
      'range': range,
      'style': style,
      'size': size,
    });
  }

  static AttributedStringData _makePageInIsolate(Map<String, dynamic> params) {
    final String text = params['text'] as String;
    final Range range = params['range'] as Range;
    final TextStyle style = params['style'] as TextStyle;
    final Size size = params['size'] as Size;

    final substring = text.substring(range.start, range.end);
    return AttributedStringData(
      string: substring,
      style: style,
    );
  }
}

class AttributedStringData {
  final String string;
  final TextStyle style;

  AttributedStringData({
    required this.string,
    required this.style,
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
    );
  }
}

class Range {
  final int start;
  final int end;

  Range(this.start, this.end);

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
}
