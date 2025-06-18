import 'package:flutter/material.dart';

enum FontType {
  systemRegular('System Regular'),
  systemBold('System Bold'),
  georgia('Georgia'),
  palatino('Palatino'),
  sfPro('SF Pro');

  final String displayName;
  const FontType(this.displayName);

  String get fontName {
    switch (this) {
      case FontType.systemRegular:
      case FontType.systemBold:
        return 'System';
      case FontType.georgia:
        return 'Georgia';
      case FontType.palatino:
        return 'Palatino';
      case FontType.sfPro:
        return '.SFProText-Regular';
    }
  }

  FontWeight get fontWeight {
    switch (this) {
      case FontType.systemBold:
        return FontWeight.bold;
      default:
        return FontWeight.normal;
    }
  }
}
