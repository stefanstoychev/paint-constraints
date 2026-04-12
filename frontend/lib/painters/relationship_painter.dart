import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/shape_data.dart';

class RelationshipPainter extends CustomPainter {
  final List<ShapeData> shapes;
  final List<int> selectedIndices;
  final int? draggingShapeIndex;
  final int? draggingPointIndex;
  final double handleRadius;
  final bool isLinkMode;
  final bool isEditVerticesMode;
  final bool showAddPointIndicators;
  final double scale;
  final Offset offset;

  RelationshipPainter({
    required this.shapes,
    required this.selectedIndices,
    this.draggingShapeIndex,
    this.draggingPointIndex,
    required this.handleRadius,
    required this.isLinkMode,
    required this.isEditVerticesMode,
    required this.showAddPointIndicators,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    final Paint segmentIndicatorPaint = _buildSegmentIndicatorPaint();
    final Paint segmentPointPaint = _buildSegmentPointPaint();

    final int? firstSelected = _linkLabelIndex(isFirst: true);
    final int? lastSelected = _linkLabelIndex(isFirst: false);

    for (int i = 0; i < shapes.length; i++) {
      final bool isSelected = selectedIndices.contains(i);
      final ShapeData shape = shapes[i];

      _paintShape(canvas, shape, isSelected);

      if (isSelected && isEditVerticesMode) {
        _paintVertexHandles(canvas, shape, i);
        if (showAddPointIndicators) {
          _paintAddPointIndicators(canvas, shape, segmentIndicatorPaint, segmentPointPaint);
        }
      }

      final String? labelText = _shapeLabel(i, firstSelected, lastSelected);
      if (labelText != null) {
        _paintShapeLabel(canvas, labelText, shape.points, textPainter);
      }
    }

    canvas.restore();
  }

  Paint _buildShapeFillPaint(ShapeData shape) {
    return Paint()
      ..color = shape.color.withAlpha((shape.color.alpha * 0.5).round())
      ..style = PaintingStyle.fill;
  }

  Paint _buildShapeStrokePaint(bool isSelected) {
    return Paint()
      ..color = isSelected ? Colors.orange : Colors.black26
      ..strokeWidth = isSelected ? 4 / scale : 1 / scale
      ..style = PaintingStyle.stroke;
  }

  Paint _buildHandleFillPaint() {
    return Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..style = PaintingStyle.fill;
  }

  Paint _buildActiveHandleFillPaint() {
    return Paint()..color = Colors.red;
  }

  Paint _buildHandleStrokePaint() {
    return Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 1.5 / scale
      ..style = PaintingStyle.stroke;
  }

  Paint _buildSegmentIndicatorPaint() {
    return Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / scale
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: <Color>[Colors.blueAccent, Colors.purpleAccent],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 0));
  }

  Paint _buildSegmentPointPaint() {
    return Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..style = PaintingStyle.fill;
  }

  void _paintShape(Canvas canvas, ShapeData shape, bool isSelected) {
    final Path path = Path()..addPolygon(shape.points, true);
    canvas.drawPath(path, _buildShapeFillPaint(shape));
    canvas.drawPath(path, _buildShapeStrokePaint(isSelected));
  }

  void _paintVertexHandles(Canvas canvas, ShapeData shape, int shapeIndex) {
    final Paint fillPaint = _buildHandleFillPaint();
    final Paint activeFillPaint = _buildActiveHandleFillPaint();
    final Paint strokePaint = _buildHandleStrokePaint();

    for (int j = 0; j < shape.points.length; j++) {
      final Offset point = shape.points[j];
      final bool isDraggingThisHandle =
          draggingShapeIndex == shapeIndex && draggingPointIndex == j;
      canvas.drawCircle(
        point,
        handleRadius / scale,
        isDraggingThisHandle ? activeFillPaint : fillPaint,
      );
      canvas.drawCircle(point, handleRadius / scale, strokePaint);
    }
  }

  void _paintAddPointIndicators(Canvas canvas, ShapeData shape, Paint indicatorPaint, Paint pointPaint) {
    for (int j = 0; j < shape.points.length; j++) {
      final Offset p1 = shape.points[j];
      final Offset p2 = shape.points[(j + 1) % shape.points.length];
      final Offset midPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      canvas.drawPath(_buildDashedPath(p1, p2), indicatorPaint);
      canvas.drawCircle(midPoint, handleRadius / 2 / scale, pointPaint);
    }
  }

  Path _buildDashedPath(Offset p1, Offset p2) {
    final Path path = Path();
    for (double start = 0.0; start < 1.0; start += 0.05) {
      final double end = start + 0.03;
      if (end > 1.0) break;
      path.moveTo(
        p1.dx + (p2.dx - p1.dx) * start,
        p1.dy + (p2.dy - p1.dy) * start,
      );
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * end,
        p1.dy + (p2.dy - p1.dy) * end,
      );
    }
    return path;
  }

  String? _shapeLabel(int index, int? firstSelected, int? lastSelected) {
    if (firstSelected == null || lastSelected == null) return null;
    if (index == firstSelected) return 'A';
    if (index == lastSelected) return 'B';
    return null;
  }

  int? _linkLabelIndex({required bool isFirst}) {
    if (!isLinkMode || selectedIndices.length != 2) return null;
    return isFirst ? selectedIndices.first : selectedIndices.last;
  }

  void _paintShapeLabel(Canvas canvas, String labelText, List<Offset> points, TextPainter textPainter) {
    final Offset center = _polygonCentroid(points);
    textPainter.text = TextSpan(
      text: labelText,
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
    textPainter.layout();
    final double textScale = 1 / scale;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(textScale);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  Offset _polygonCentroid(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;
    if (points.length == 1) return points.first;

    double area = 0.0;
    double centroidX = 0.0;
    double centroidY = 0.0;

    for (int i = 0, j = points.length - 1; i < points.length; j = i++) {
      final Offset current = points[i];
      final Offset previous = points[j];
      final double cross = previous.dx * current.dy - current.dx * previous.dy;
      area += cross;
      centroidX += (previous.dx + current.dx) * cross;
      centroidY += (previous.dy + current.dy) * cross;
    }

    area *= 0.5;
    if (area.abs() < 1e-9) {
      return Offset(
        points.map((p) => p.dx).reduce((a, b) => a + b) / points.length,
        points.map((p) => p.dy).reduce((a, b) => a + b) / points.length,
      );
    }

    return Offset(centroidX / (6 * area), centroidY / (6 * area));
  }

  @override
  bool shouldRepaint(covariant RelationshipPainter oldDelegate) {
    if (!listEquals(shapes, oldDelegate.shapes)) return true;
    if (!listEquals(selectedIndices, oldDelegate.selectedIndices)) return true;
    if (draggingShapeIndex != oldDelegate.draggingShapeIndex) return true;
    if (draggingPointIndex != oldDelegate.draggingPointIndex) return true;
    if (isLinkMode != oldDelegate.isLinkMode) return true;
    if (isEditVerticesMode != oldDelegate.isEditVerticesMode) return true;
    if (handleRadius != oldDelegate.handleRadius) return true;
    if (showAddPointIndicators != oldDelegate.showAddPointIndicators) return true;
    if (scale != oldDelegate.scale) return true;
    if (offset != oldDelegate.offset) return true;
    return false;
  }
}
