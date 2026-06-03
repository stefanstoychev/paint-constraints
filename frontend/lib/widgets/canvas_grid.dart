import 'package:flutter/material.dart';

class CanvasGrid extends StatelessWidget {
  final double scale;
  final Offset offset;
  final Rect canvasRect;

  const CanvasGrid({
    super.key,
    required this.scale,
    required this.offset,
    required this.canvasRect,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(scale: scale, offset: offset, canvasRect: canvasRect),
      size: Size.infinite,
    );
  }
}

class _GridPainter extends CustomPainter {
  final double scale;
  final Offset offset;
  final Rect canvasRect;

  _GridPainter({
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
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return scale != oldDelegate.scale || offset != oldDelegate.offset;
  }
}

