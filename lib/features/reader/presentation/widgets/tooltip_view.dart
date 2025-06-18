import 'package:flutter/material.dart';

class TooltipView extends StatelessWidget {
  final String word;
  final String translation;
  final VoidCallback onClose;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onPronounceTap;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final Offset position;
  final double visibleScreenHeight;

  const TooltipView({
    super.key,
    required this.word,
    required this.translation,
    required this.onClose,
    this.onFavoriteTap,
    this.onPronounceTap,
    required this.backgroundColor,
    required this.textColor,
    required this.fontSize,
    required this.position,
    required this.visibleScreenHeight,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final tooltipWidth = 220.0;
    final tooltipHeight = 130.0;
    final screenPadding = 12.0;
    final arrowSize = 12.0;
    final minArrowInset = 18.0;

    // Calculate adjusted position
    final adjustedPosition = _getAdjustedPosition(
      screenSize: screenSize,
      tap: position,
      tooltipWidth: tooltipWidth,
      tooltipHeight: tooltipHeight,
      screenPadding: screenPadding,
      minArrowInset: minArrowInset,
    );

    final bubbleLeft = adjustedPosition.dx - tooltipWidth / 2;
    final arrowX = (position.dx - bubbleLeft)
        .clamp(minArrowInset, tooltipWidth - minArrowInset);
    final arrowIsTop = !(position.dy > visibleScreenHeight / 2);

    return Positioned(
      left: adjustedPosition.dx - tooltipWidth / 2,
      top: adjustedPosition.dy - (arrowIsTop ? tooltipHeight + arrowSize : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (arrowIsTop) _buildArrow(arrowX, arrowSize, true),
          _buildTooltipContent(
            context,
            tooltipWidth,
            tooltipHeight,
            arrowX,
            arrowSize,
            arrowIsTop,
          ),
          if (!arrowIsTop) _buildArrow(arrowX, arrowSize, false),
        ],
      ),
    );
  }

  Widget _buildArrow(double arrowX, double arrowSize, bool isTop) {
    final tooltipWidth = 220.0;
    return CustomPaint(
      size: Size(tooltipWidth, arrowSize),
      painter: ArrowPainter(
        arrowX: arrowX,
        arrowSize: arrowSize,
        isTop: isTop,
        color: backgroundColor,
      ),
    );
  }

  Widget _buildTooltipContent(
    BuildContext context,
    double tooltipWidth,
    double tooltipHeight,
    double arrowX,
    double arrowSize,
    bool arrowIsTop,
  ) {
    return Container(
      width: tooltipWidth,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        word,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (onFavoriteTap != null)
                      IconButton(
                        icon: const Icon(Icons.star, color: Colors.yellow),
                        onPressed: onFavoriteTap,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (onPronounceTap != null)
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.blue),
                        onPressed: onPronounceTap,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const Divider(),
                Text(
                  translation,
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              icon: const Icon(Icons.close, size: 14),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Offset _getAdjustedPosition({
    required Size screenSize,
    required Offset tap,
    required double tooltipWidth,
    required double tooltipHeight,
    required double screenPadding,
    required double minArrowInset,
  }) {
    var adjustedX = tap.dx;
    final tooltipHalfWidth = tooltipWidth / 2;
    final tooltipHalfHeight = tooltipHeight / 2;
    final spacingFromWord = 2.0;

    // X axis boundaries
    final minX = tooltipHalfWidth + screenPadding + minArrowInset;
    final maxX =
        screenSize.width - tooltipHalfWidth - screenPadding - minArrowInset;
    adjustedX = adjustedX.clamp(minX, maxX);

    // Y position calculation
    final midPoint = visibleScreenHeight / 2;
    final showAbove = tap.dy > midPoint;

    var adjustedY = showAbove
        ? tap.dy - tooltipHalfHeight - spacingFromWord
        : tap.dy + tooltipHalfHeight + spacingFromWord;

    // Screen boundaries
    final minY = tooltipHalfHeight + screenPadding;
    final maxY = visibleScreenHeight - tooltipHalfHeight - screenPadding;
    adjustedY = adjustedY.clamp(minY, maxY);

    return Offset(adjustedX, adjustedY);
  }
}

class ArrowPainter extends CustomPainter {
  final double arrowX;
  final double arrowSize;
  final bool isTop;
  final Color color;

  ArrowPainter({
    required this.arrowX,
    required this.arrowSize,
    required this.isTop,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isTop) {
      path.moveTo(arrowX - arrowSize, arrowSize);
      path.lineTo(arrowX, 0);
      path.lineTo(arrowX + arrowSize, arrowSize);
    } else {
      path.moveTo(arrowX - arrowSize, 0);
      path.lineTo(arrowX, arrowSize);
      path.lineTo(arrowX + arrowSize, 0);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) =>
      arrowX != oldDelegate.arrowX ||
      arrowSize != oldDelegate.arrowSize ||
      isTop != oldDelegate.isTop ||
      color != oldDelegate.color;
}
