
import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final double scale;
  final Offset offset;
  final Rect canvasRect;

  GridPainter({
    required this.scale,
    required this.offset,
    required this.canvasRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    const double gridSize = 25.0;

    for (double x = gridSize; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = gridSize; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Draw artboard background
    final Paint artboardPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Paint artboardBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 / scale;

    canvas.drawRect(canvasRect, artboardPaint);
    canvas.drawRect(canvasRect, artboardBorderPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return scale != oldDelegate.scale || offset != oldDelegate.offset;
  }
}
