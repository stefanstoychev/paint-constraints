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
      painter: _GridPainter(
        scale: scale,
        offset: offset,
        canvasRect: canvasRect,
      ),
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
    // 1. Draw Grid (Widget/Screen Coordinates)
    // The grid lines must be drawn relative to the current widget size first.
    _paintGridLines(canvas, size);

    // 2. Prepare for World Space Drawing
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // 3. Draw Artboard Background (World Coordinates)
    _paintArtboardBackground(canvas);

    // Restore canvas to its original state after drawing the artboard elements
    canvas.restore();
  }

  void _paintGridLines(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    const double gridSize = 25.0;

    // Vertical Lines
    for (double x = gridSize; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    // Horizontal Lines
    for (double y = gridSize; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _paintArtboardBackground(Canvas canvas) {
    // Paint for the opaque white background of the artboard area.
    final Paint artboardFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Paint for the semi-transparent boundary outline.
    final Paint artboardBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 / scale; // Calculate stroke width based on current scale

    // Draw the main filled rectangle (the area content is defined by canvasRect).
    canvas.drawRect(canvasRect, artboardFillPaint);
    
    // Draw the border around the defined canvas boundary.
    canvas.drawRect(canvasRect, artboardBorderPaint);
  }


  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return scale != oldDelegate.scale || offset != oldDelegate.offset;
  }
}
