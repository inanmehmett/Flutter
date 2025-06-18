import 'package:flutter/material.dart';

class LevelTag extends StatelessWidget {
  final int level;

  const LevelTag({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getLevelColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Lvl $level',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _getLevelColor(),
        ),
      ),
    );
  }

  Color _getLevelColor() {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
