import 'package:flutter/material.dart';

class CanvasGrid extends StatelessWidget {
  final double scale;
  final Offset offset;

  const CanvasGrid({super.key, required this.scale, required this.offset});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(scale: scale, offset: offset),
      size: Size.infinite,
    );
  }
}

class _GridPainter extends CustomPainter {
  final double scale;
  final Offset offset;

  _GridPainter({required this.scale, required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.0 / scale;

    const double gridSize = 25.0;

    // Calculate visible bounds in world coordinates
    final double left = -offset.dx / scale;
    final double top = -offset.dy / scale;
    final double right = (size.width - offset.dx) / scale;
    final double bottom = (size.height - offset.dy) / scale;

    // Adjust starts to align with grid
    final double startX = (left / gridSize).floor() * gridSize;
    final double startY = (top / gridSize).floor() * gridSize;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Draw artboard background
    const Rect artboardRect = Rect.fromLTWH(20, 20, 460, 320);
    final Paint artboardPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Paint artboardBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 / scale;

    canvas.drawRect(artboardRect, artboardPaint);
    canvas.drawRect(artboardRect, artboardBorderPaint);

    for (double x = startX; x <= right; x += gridSize) {
      canvas.drawLine(Offset(x, top), Offset(x, bottom), gridPaint);
    }
    for (double y = startY; y <= bottom; y += gridSize) {
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return scale != oldDelegate.scale || offset != oldDelegate.offset;
  }
}
