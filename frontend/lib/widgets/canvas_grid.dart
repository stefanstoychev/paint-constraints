import 'package:flutter/material.dart';

import '../painters/grid_painter.dart';

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
      painter: GridPainter(scale: scale, offset: offset, canvasRect: canvasRect),
      size: Size.infinite,
    );
  }
}
