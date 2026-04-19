import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/color_component.dart';
import 'package:frontend/models/color_relationship.dart';
import 'package:frontend/models/shape_data.dart';

class RelationshipPainter extends CustomPainter {
  static const double _relationshipLabelFontSize = 16.0;
  static const double _relationshipLabelSpacing = 16.0;
  static const double _shapeLabelFontSize = 16.0;
  static const double _arrowSize = 8.0;
  RelationshipPainter({
    required this.shapes,
    required this.selectedIndices,
    required this.activeRelationships,
    this.draggingShapeIndex,
    this.draggingPointIndex,
    this.selectedVertexIndex,
    required this.handleRadius,
    required this.isLinkMode,
    required this.isEditVerticesMode,
    required this.showAddPointIndicators,
    required this.showRelationships,
    required this.showColorLabels,
    required this.scale,
    required this.offset,
  });

  final List<ShapeData> shapes;
  final List<int> selectedIndices;
  final List<ShapeRelationship> activeRelationships;
  final int? draggingShapeIndex;
  final int? draggingPointIndex;
  final int? selectedVertexIndex;
  final double handleRadius;
  final bool isLinkMode;
  final bool isEditVerticesMode;
  final bool showAddPointIndicators;
  final bool showRelationships;
  final bool showColorLabels;
  final double scale;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    final Paint segmentIndicatorPaint = _buildSegmentIndicatorPaint();
    final Paint segmentPointPaint = _buildSegmentPointPaint();

    final int? firstSelected = _linkLabelIndex(isFirst: true);
    final int? lastSelected = _linkLabelIndex(isFirst: false);

    final List<MapEntry<int, ShapeData>> sortedShapes =
        shapes.asMap().entries.toList()..sort((a, b) {
          final int zCompare = a.value.zIndex.compareTo(b.value.zIndex);
          if (zCompare != 0) return zCompare;
          return a.key.compareTo(b.key);
        });

    for (final MapEntry<int, ShapeData> entry in sortedShapes) {
      final int i = entry.key;
      final ShapeData shape = entry.value;
      final bool isSelected = selectedIndices.contains(i);

      _paintShape(canvas, shape, isSelected);

      if (isSelected && isEditVerticesMode) {
        _paintVertexHandles(canvas, shape, i);
        if (showAddPointIndicators) {
          _paintAddPointIndicators(
            canvas,
            shape,
            segmentIndicatorPaint,
            segmentPointPaint,
          );
        }
      }

      final String? labelText = _shapeLabel(i, firstSelected, lastSelected);
      if (labelText != null) {
        _paintShapeLabel(canvas, labelText, shape.points, textPainter);
      }

      if (showColorLabels) {
        _paintColorLabel(canvas, shape, textPainter);
      }
    }

    // Paint relationship lines
    if (showRelationships || isLinkMode) {
      _paintRelationships(canvas, textPainter);
    }

    canvas.restore();
  }

  Paint _buildShapeFillPaint(ShapeData shape) {
    return Paint()
      ..color = shape.color
      ..style = PaintingStyle.fill;
  }

  Paint _buildShapeStrokePaint(bool isSelected) {
    return Paint()
      ..color = isSelected ? Colors.orange : Colors.white24
      ..strokeWidth = isSelected ? 4 / scale : 1.5 / scale
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
    final Paint selectedHandlePaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / scale;
    final Paint strokePaint = _buildHandleStrokePaint();

    for (int j = 0; j < shape.points.length; j++) {
      final Offset point = shape.points[j];
      final bool isDraggingThisHandle =
          draggingShapeIndex == shapeIndex && draggingPointIndex == j;
      final bool isSelectedHandle =
          selectedVertexIndex != null &&
          selectedVertexIndex == j &&
          selectedIndices.contains(shapeIndex);
      canvas.drawCircle(
        point,
        handleRadius / scale,
        isDraggingThisHandle ? activeFillPaint : fillPaint,
      );
      canvas.drawCircle(point, handleRadius / scale, strokePaint);
      if (isSelectedHandle) {
        canvas.drawCircle(
          point,
          handleRadius / scale + 2.0 / scale,
          selectedHandlePaint,
        );
      }
    }
  }

  void _paintAddPointIndicators(
    Canvas canvas,
    ShapeData shape,
    Paint indicatorPaint,
    Paint pointPaint,
  ) {
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
      path.lineTo(p1.dx + (p2.dx - p1.dx) * end, p1.dy + (p2.dy - p1.dy) * end);
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

  void _paintShapeLabel(
    Canvas canvas,
    String labelText,
    List<Offset> points,
    TextPainter textPainter,
  ) {
    final Offset center = _polygonCentroid(points);
    textPainter.text = TextSpan(
      text: labelText,
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: _shapeLabelFontSize,
      ),
    );
    textPainter.layout();
    final double textScale = 1 / scale;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(textScale);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  void _paintColorLabel(
    Canvas canvas,
    ShapeData shape,
    TextPainter textPainter,
  ) {
    final Offset center = _polygonCentroid(shape.points);
    final String labelText =
        'H:${shape.hsv.hue.toInt()} S:${(shape.hsv.saturation * 100).toInt()} V:${(shape.hsv.value * 100).toInt()}';

    textPainter.text = TextSpan(
      text: labelText,
      style: TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black54,
      ),
    );
    textPainter.layout();

    final double textScale = 1 / scale;
    canvas.save();
    canvas.translate(center.dx, center.dy + 15 / scale); // Slightly below center
    canvas.scale(textScale);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  void _paintRelationships(Canvas canvas, TextPainter textPainter) {
    final Paint linePaint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..strokeWidth = 2.0 / scale
      ..style = PaintingStyle.stroke;

    final Paint arrowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    for (final ShapeRelationship relationship in activeRelationships) {
      if (relationship.sourceShapeIndex >= shapes.length ||
          relationship.targetShapeIndex >= shapes.length) {
        continue;
      }

      final ShapeData sourceShape = shapes[relationship.sourceShapeIndex];
      final ShapeData targetShape = shapes[relationship.targetShapeIndex];

      final Offset sourceCenter = _polygonCentroid(sourceShape.points);
      final Offset targetCenter = _polygonCentroid(targetShape.points);

      // Draw the line
      canvas.drawLine(sourceCenter, targetCenter, linePaint);

      // Draw arrowhead at target end
      _drawArrowhead(canvas, sourceCenter, targetCenter, arrowPaint);

      // Draw relationship text in the middle with an offset so multiple labels don't overlap.
      final Offset direction = targetCenter - sourceCenter;
      final double distance = direction.distance;
      final Offset normalizedDirection = distance == 0
          ? const Offset(0, 0)
          : direction / distance;
      final Offset perpendicular = Offset(
        -normalizedDirection.dy,
        normalizedDirection.dx,
      );
      final Offset midPoint = Offset(
        (sourceCenter.dx + targetCenter.dx) / 2,
        (sourceCenter.dy + targetCenter.dy) / 2,
      );
      final double labelSpacing = _relationshipLabelSpacing;
      final Offset labelOffset =
          perpendicular *
          _getRelationshipLabelOffset(relationship.relationship.component) *
          labelSpacing;

      final String label = _getRelationshipLabel(relationship.relationship);
      _paintRelationshipLabel(
        canvas,
        label,
        midPoint + labelOffset,
        textPainter,
      );
    }
  }

  double _getRelationshipLabelOffset(ColorComponent component) {
    switch (component) {
      case ColorComponent.hue:
        return -1.0;
      case ColorComponent.saturation:
        return 0.0;
      case ColorComponent.value:
        return 1.0;
    }
  }

  void _drawArrowhead(Canvas canvas, Offset from, Offset to, Paint paint) {
    const double arrowSize = _arrowSize;
    final Offset direction = (to - from);
    final double length = direction.distance;
    if (length == 0) return;

    final Offset normalizedDirection = direction / length;
    final Offset perpendicular =
        Offset(-normalizedDirection.dy, normalizedDirection.dx) *
        arrowSize *
        0.5;

    final Offset arrowTip = to;
    final Offset arrowBase1 =
        to - normalizedDirection * arrowSize + perpendicular;
    final Offset arrowBase2 =
        to - normalizedDirection * arrowSize - perpendicular;

    final Path arrowPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(arrowBase1.dx, arrowBase1.dy)
      ..lineTo(arrowBase2.dx, arrowBase2.dy)
      ..close();

    canvas.drawPath(arrowPath, paint);
  }

  String _getRelationshipLabel(ColorRelationship relationship) {
    final offsetStr = relationship.offset == 0
        ? ''
        : (relationship.offset > 0
              ? ' + ${relationship.offset.toStringAsFixed(1)}'
              : ' - ${relationship.offset.abs().toStringAsFixed(1)}');

    final String prefix;
    switch (relationship.component) {
      case ColorComponent.hue:
        prefix = 'h';
        break;
      case ColorComponent.saturation:
        prefix = 's';
        break;
      case ColorComponent.value:
        prefix = 'v';
        break;
    }

    return '$prefix${relationship.operator.symbol}$offsetStr';
  }

  void _paintRelationshipLabel(
    Canvas canvas,
    String text,
    Offset position,
    TextPainter textPainter,
  ) {
    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.blue.shade800,
        fontSize: _relationshipLabelFontSize,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.white.withOpacity(0.8),
      ),
    );
    textPainter.layout();
    final double textScale = 1 / scale;
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.scale(textScale);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
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
    if (showAddPointIndicators != oldDelegate.showAddPointIndicators) {
      return true;
    }
    if (showRelationships != oldDelegate.showRelationships) return true;
    if (showColorLabels != oldDelegate.showColorLabels) return true;
    if (scale != oldDelegate.scale) return true;
    if (offset != oldDelegate.offset) return true;
    if (!listEquals(activeRelationships, oldDelegate.activeRelationships)) {
      return true;
    }
    return false;
  }
}
