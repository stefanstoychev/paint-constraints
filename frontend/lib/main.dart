import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

void main() => runApp(
      const MaterialApp(home: ShapeEditor(), debugShowCheckedModeBanner: false),
    );

enum ColorComponent { hue, saturation, value }

class ShapeData {
  final List<Offset> points;
  final HSVColor hsv;
  ShapeData({required this.points, required this.hsv});

  Color get color => hsv.toColor();

  ShapeData copyWith({List<Offset>? points, HSVColor? hsv}) {
    return ShapeData(
      points: points ?? List<Offset>.from(this.points),
      hsv: hsv ?? this.hsv,
    );
  }
}

class ShapeEditor extends StatefulWidget {
  const ShapeEditor({super.key});
  @override
  State<ShapeEditor> createState() => _ShapeEditorState();
}

class _ShapeEditorState extends State<ShapeEditor> {
  List<ShapeData> allShapes = <ShapeData>[
    ShapeData(
      points: <Offset>[
        const Offset(50, 100),
        const Offset(150, 100),
        const Offset(150, 200),
        const Offset(50, 200),
      ],
      hsv: HSVColor.fromAHSV(1, 180, 0.7, 0.8),
    ),
    ShapeData(
      points: <Offset>[
        const Offset(250, 100),
        const Offset(350, 100),
        const Offset(350, 200),
        const Offset(250, 200),
      ],
      hsv: HSVColor.fromAHSV(1, 210, 0.7, 0.8),
    ),
  ];

  List<int> selectedIndices = <int>[];
  bool isLinkMode = false;
  bool isEditVerticesMode = false;

  // Zoom and Pan state
  double _currentScale = 1.0;
  Offset _currentOffset = Offset.zero;
  double _previousScale = 1.0;
  Offset _previousOffset = Offset.zero;
  Offset _previousFocalPoint = Offset.zero;
  final double _minScale = 0.3;
  final double _maxScale = 5.0;

  int? _draggingShapeIndex;
  int? _draggingPointIndex;
  Offset? _draggedPointInitialPosition;
  Offset? _dragStartWorldPoint;

  // Handle radius and segment tolerance are screen-space values.
  static const double _handleRadius = 25.0;
  static const double _segmentTapTolerance = 10.0;

  // Converts a screen-space coordinate to a world-space coordinate
  Offset _screenToWorld(Offset screenPoint) {
    return (screenPoint - _currentOffset) / _currentScale;
  }

  void _addShape() {
    setState(() {
      final List<Offset> newShapePoints = <Offset>[
        const Offset(50, 50),
        const Offset(150, 50),
        const Offset(150, 150),
        const Offset(50, 150),
      ];
      final Offset offsetTranslation = Offset(
        (allShapes.length * 20.0) % 200 + 50,
        (allShapes.length * 20.0) % 200 + 50,
      );
      final List<Offset> translatedPoints = newShapePoints
          .map<Offset>((Offset p) => p + offsetTranslation)
          .toList();

      final double randomHue =
          (DateTime.now().millisecond.toDouble() % 360).roundToDouble();

      allShapes = <ShapeData>[
        ...allShapes,
        ShapeData(
          points: translatedPoints,
          hsv: HSVColor.fromAHSV(1, randomHue, 0.7, 0.8),
        ),
      ];
      selectedIndices.clear();
      selectedIndices.add(allShapes.length - 1);
    });
  }

  void _applyRelationship(ColorComponent component, double offset) {
    if (selectedIndices.length == 2) {
      final int sourceIdx = selectedIndices.first;
      final int targetIdx = selectedIndices.last;

      setState(() {
        final List<ShapeData> tempAllShapes = List<ShapeData>.from(allShapes);

        final HSVColor sourceHsv = tempAllShapes[sourceIdx].hsv;
        HSVColor targetHsv = tempAllShapes[targetIdx].hsv;
        HSVColor newTargetHsv;

        switch (component) {
          case ColorComponent.hue:
            double newHue = (sourceHsv.hue + offset) % 360;
            if (newHue < 0) newHue += 360;
            newTargetHsv = targetHsv.withHue(newHue);
            break;
          case ColorComponent.saturation:
            double newSaturation =
                (sourceHsv.saturation + offset).clamp(0.0, 1.0);
            newTargetHsv = targetHsv.withSaturation(newSaturation);
            break;
          case ColorComponent.value:
            double newValue = (sourceHsv.value + offset).clamp(0.0, 1.0);
            newTargetHsv = targetHsv.withValue(newValue);
            break;
        }
        tempAllShapes[targetIdx] =
            tempAllShapes[targetIdx].copyWith(hsv: newTargetHsv);
        allShapes = tempAllShapes;
      });
    }
  }

  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final Offset pI = polygon[i];
      final Offset pJ = polygon[j];

      if (((pI.dy > point.dy) != (pJ.dy > point.dy)) &&
          (point.dx <
              (pJ.dx - pI.dx) * (point.dy - pI.dy) / (pJ.dy - pI.dy) + pI.dx)) {
        inside = !inside;
      }
    }
    return inside;
  }

  double _distanceToSegment(Offset p, Offset p1, Offset p2) {
    final double l2 =
        (pow(p2.dx - p1.dx, 2) + pow(p2.dy - p1.dy, 2)).toDouble();
    if (l2 == 0.0) return (p - p1).distance;

    final double t =
        ((p.dx - p1.dx) * (p2.dx - p1.dx) + (p.dy - p1.dy) * (p2.dy - p1.dy)) /
            l2;

    Offset projection;
    if (t < 0.0) {
      projection = p1;
    } else if (t > 1.0) {
      projection = p2;
    } else {
      projection = Offset(
        p1.dx + t * (p2.dx - p1.dx),
        p1.dy + t * (p2.dy - p1.dy),
      );
    }
    return (p - projection).distance;
  }

  void _handleTapDown(TapDownDetails details) {
    if (_draggingShapeIndex != null) return;

    final Offset worldPosition = _screenToWorld(details.localPosition);
    final double worldHandleRadius = _handleRadius / _currentScale;
    final double worldSegmentTapTolerance = _segmentTapTolerance / _currentScale;

    if (isEditVerticesMode && selectedIndices.length == 1) {
      final int selectedShapeIndex = selectedIndices.first;
      final List<Offset> points = allShapes[selectedShapeIndex].points;

      for (int i = 0; i < points.length; i++) {
        if ((points[i] - worldPosition).distance < worldHandleRadius) {
          // Tapped on a handle, do nothing specific here, _handleScaleStart will pick it up
          return;
        }
      }

      for (int i = 0; i < points.length; i++) {
        final Offset p1 = points[i];
        final Offset p2 = points[(i + 1) % points.length];

        if (_distanceToSegment(worldPosition, p1, p2) <
            worldSegmentTapTolerance) {
          setState(() {
            final List<ShapeData> tempAllShapes =
                List<ShapeData>.from(allShapes);
            final List<Offset> currentPoints =
                List<Offset>.from(tempAllShapes[selectedShapeIndex].points);
            currentPoints.insert(i + 1, worldPosition);

            tempAllShapes[selectedShapeIndex] = tempAllShapes[selectedShapeIndex]
                .copyWith(points: currentPoints);
            allShapes = tempAllShapes;
          });
          return;
        }
      }
    }

    int? tappedShapeIndex;
    for (int i = allShapes.length - 1; i >= 0; i--) {
      if (_isPointInPolygon(worldPosition, allShapes[i].points)) {
        tappedShapeIndex = i;
        break;
      }
    }

    setState(() {
      if (tappedShapeIndex != null) {
        if (isEditVerticesMode) {
          selectedIndices.clear();
          selectedIndices.add(tappedShapeIndex);
        } else if (isLinkMode) {
          if (selectedIndices.contains(tappedShapeIndex)) {
            selectedIndices.remove(tappedShapeIndex);
          } else {
            if (selectedIndices.length < 2) {
              selectedIndices.add(tappedShapeIndex);
            } else {
              // Replace the oldest selection if more than 2 are selected
              if (selectedIndices.isNotEmpty) {
                selectedIndices.removeAt(0);
              }
              selectedIndices.add(tappedShapeIndex);
            }
          }
        } else {
          // Standard selection mode (toggle selection)
          if (selectedIndices.contains(tappedShapeIndex)) {
            selectedIndices.remove(tappedShapeIndex);
          } else {
            selectedIndices.add(tappedShapeIndex);
          }
        }
      } else {
        selectedIndices.clear();
      }
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _previousScale = _currentScale;
    _previousOffset = _currentOffset;
    _previousFocalPoint = details.focalPoint;

    // Reset drag state
    _draggingShapeIndex = null;
    _draggingPointIndex = null;
    _draggedPointInitialPosition = null;
    _dragStartWorldPoint = null;

    // Check if a point is being dragged (only with a single pointer in edit mode)
    if (isEditVerticesMode && selectedIndices.length == 1 && details.pointerCount == 1) {
      final Offset worldPosition = _screenToWorld(details.focalPoint);
      final double worldHandleRadius = _handleRadius / _currentScale;

      final int shapeIndex = selectedIndices.first;
      final ShapeData shape = allShapes[shapeIndex];
      for (int i = 0; i < shape.points.length; i++) {
        final Offset point = shape.points[i];
        if ((point - worldPosition).distance < worldHandleRadius) {
          _draggingShapeIndex = shapeIndex;
          _draggingPointIndex = i;
          _draggedPointInitialPosition = point;
          _dragStartWorldPoint = worldPosition;
          return;
        }
      }
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (_draggingShapeIndex != null && _draggingPointIndex != null && details.pointerCount == 1) {
        // User is dragging a vertex with a single pointer in edit mode
        final Offset currentWorldFocalPoint = _screenToWorld(details.focalPoint);
        final Offset deltaWorld = currentWorldFocalPoint - _dragStartWorldPoint!;

        final List<ShapeData> tempAllShapes = List<ShapeData>.from(allShapes);
        final List<Offset> updatedPoints = List<Offset>.from(
          tempAllShapes[_draggingShapeIndex!].points,
        );
        updatedPoints[_draggingPointIndex!] = _draggedPointInitialPosition! + deltaWorld;

        tempAllShapes[_draggingShapeIndex!] =
            tempAllShapes[_draggingShapeIndex!].copyWith(points: updatedPoints);
        allShapes = tempAllShapes;
      } else {
        // Multi-touch gesture: pan and zoom canvas. OR Single-touch gesture: pan canvas.
        // The ScaleUpdateDetails.scale will be 1.0 for single-finger pan.
        _currentScale = (_previousScale * details.scale).clamp(_minScale, _maxScale);

        final Offset focalPointAtStartWorld = (_previousFocalPoint - _previousOffset) / _previousScale;

        _currentOffset = details.focalPoint - focalPointAtStartWorld * _currentScale;
      }
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    // Clear point dragging state
    _draggingShapeIndex = null;
    _draggingPointIndex = null;
    _draggedPointInitialPosition = null;
    _dragStartWorldPoint = null;

    // Update previous state for potential next gesture
    _previousScale = _currentScale;
    _previousOffset = _currentOffset;
  }

  @override
  Widget build(BuildContext context) {
    final bool showAddPointIndicators =
        isEditVerticesMode && selectedIndices.length == 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditVerticesMode
              ? "Edit Vertices Mode"
              : isLinkMode
                  ? "Select 2 Shapes to Link"
                  : "Shape Operations", // Changed title to be more generic
        ),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () => setState(() {
              isLinkMode = !isLinkMode;
              isEditVerticesMode = false;
              selectedIndices.clear();
            }),
            icon: Icon(
              Icons.link,
              color: isLinkMode ? Colors.green : Colors.grey,
            ),
            label: Text(
              "Link Mode",
              style: TextStyle(color: isLinkMode ? Colors.green : Colors.grey),
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() {
              isEditVerticesMode = !isEditVerticesMode;
              isLinkMode = false;
              selectedIndices.clear();
            }),
            icon: Icon(
              Icons.scatter_plot,
              color: isEditVerticesMode ? Colors.blue : Colors.grey,
            ),
            label: Text(
              "Edit Vertices",
              style: TextStyle(
                color: isEditVerticesMode ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          GestureDetector(
            onTapDown: _handleTapDown,
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
            child: Container(
              color: Colors.white,
              child: CustomPaint(
                painter: RelationshipPainter(
                  shapes: allShapes,
                  selectedIndices: selectedIndices,
                  draggingShapeIndex: _draggingShapeIndex,
                  draggingPointIndex: _draggingPointIndex,
                  handleRadius: _handleRadius,
                  isLinkMode: isLinkMode,
                  isEditVerticesMode: isEditVerticesMode,
                  showAddPointIndicators: showAddPointIndicators,
                  scale: _currentScale,
                  offset: _currentOffset,
                ),
                child: Container(),
              ),
            ),
          ),

          // --- Relationship UI Panel ---
          if (isLinkMode && selectedIndices.length == 2)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        "Define Relationship (B = A + X)",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildRelationshipRow(
                        "Hue (°)",
                        ColorComponent.hue,
                        <Map<String, dynamic>>[
                          {"label": "Analogous (+30°)", "value": 30.0},
                          {"label": "Triadic (+120°)", "value": 120.0},
                          {"label": "Complementary (+180°)", "value": 180.0},
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildRelationshipRow(
                        "Saturation",
                        ColorComponent.saturation,
                        <Map<String, dynamic>>[
                          {"label": "Same", "value": 0.0},
                          {"label": "+0.1", "value": 0.1},
                          {"label": "-0.1", "value": -0.1},
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildRelationshipRow(
                        "Value",
                        ColorComponent.value,
                        <Map<String, dynamic>>[
                          {"label": "Same", "value": 0.0},
                          {"label": "+0.1", "value": 0.1},
                          {"label": "-0.1", "value": -0.1},
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // --- Zoom Controls ---
          Positioned(
            top: 20,
            right: 20,
            child: Card(
              color: Colors.black54,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.zoom_out, color: Colors.white),
                    SizedBox(
                      width: 150,
                      child: Slider(
                        value: _currentScale,
                        min: _minScale,
                        max: _maxScale,
                        divisions: ((_maxScale - _minScale) * 10).round(),
                        onChanged: (double newValue) {
                          setState(() {
                            _currentScale = newValue;
                            final Offset screenCenter = Offset(
                              MediaQuery.of(context).size.width / 2,
                              MediaQuery.of(context).size.height / 2,
                            );
                            // Calculate world point at screen center before scale change
                            final Offset centerWorldAtPrevScale = (screenCenter - _previousOffset) / _previousScale;
                            // New offset to keep that world point under the screen center
                            _currentOffset = screenCenter - centerWorldAtPrevScale * _currentScale;

                            _previousScale = _currentScale;
                            _previousOffset = _currentOffset;
                            _previousFocalPoint = screenCenter;
                          });
                        },
                        activeColor: Colors.white,
                        inactiveColor: Colors.white38,
                      ),
                    ),
                    const Icon(Icons.zoom_in, color: Colors.white),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _currentScale = 1.0;
                          _currentOffset = Offset.zero;
                          _previousScale = 1.0;
                          _previousOffset = Offset.zero;
                          _previousFocalPoint = Offset.zero;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addShape,
        tooltip: 'Add New Shape',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRelationshipRow(
    String title,
    ColorComponent component,
    List<Map<String, dynamic>> options,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: options
              .map<Widget>(
                (Map<String, dynamic> option) => LinkButton(
                  label: option["label"] as String,
                  component: component,
                  offsetValue: option["value"] as double,
                  onPressed: _applyRelationship,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class LinkButton extends StatelessWidget {
  final String label;
  final ColorComponent component;
  final double offsetValue;
  final void Function(ColorComponent, double) onPressed;

  const LinkButton({
    super.key,
    required this.label,
    required this.component,
    required this.offsetValue,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onPressed(component, offsetValue),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        textStyle: const TextStyle(fontSize: 10),
      ),
      child: Text(label),
    );
  }
}

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

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final int? firstSelected = selectedIndices.length == 2 && isLinkMode
        ? selectedIndices.first
        : null;
    final int? lastSelected = selectedIndices.length == 2 && isLinkMode
        ? selectedIndices.last
        : null;

    final Paint segmentIndicatorPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / scale
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: <Color>[Colors.blueAccent, Colors.purpleAccent],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 0));

    final Paint segmentAddPointPaint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < shapes.length; i++) {
      final bool isSelected = selectedIndices.contains(i);
      final Paint fillPaint = Paint()
        ..color = shapes[i].color.withAlpha(
              (shapes[i].color.alpha * 0.5).round(),
            )
        ..style = PaintingStyle.fill;
      final Paint strokePaint = Paint()
        ..color = isSelected ? Colors.orange : Colors.black26
        ..strokeWidth = isSelected ? 4 / scale : 1 / scale
        ..style = PaintingStyle.stroke;

      final Path path = Path()..addPolygon(shapes[i].points, true);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);

      if (isSelected && isEditVerticesMode) {
        final Paint handleFillPaint = Paint()
          ..color = Colors.blue.withOpacity(0.7)
          ..style = PaintingStyle.fill;
        final Paint activeHandleFillPaint = Paint()
          ..color = Colors.red;
        final Paint handleStrokePaint = Paint()
          ..color = Colors.blueGrey
          ..strokeWidth = 1.5 / scale
          ..style = PaintingStyle.stroke;

        for (int j = 0; j < shapes[i].points.length; j++) {
          final Offset point = shapes[i].points[j];
          final bool isCurrentlyDraggingThisHandle =
              (draggingShapeIndex == i && draggingPointIndex == j);
          canvas.drawCircle(
            point,
            handleRadius / scale,
            isCurrentlyDraggingThisHandle
                ? activeHandleFillPaint
                : handleFillPaint,
          );
          canvas.drawCircle(point, handleRadius / scale, handleStrokePaint);
        }

        if (showAddPointIndicators) {
          for (int j = 0; j < shapes[i].points.length; j++) {
            final Offset p1 = shapes[i].points[j];
            final Offset p2 =
                shapes[i].points[(j + 1) % shapes[i].points.length];
            final Offset midPoint =
                Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);

            final Path dashedPath = Path();
            for (double start = 0.0; start < 1.0; start += 0.05) {
              final double end = start + 0.03;
              if (end > 1.0) break;
              dashedPath.moveTo(
                  p1.dx + (p2.dx - p1.dx) * start, p1.dy + (p2.dy - p1.dy) * start);
              dashedPath.lineTo(
                  p1.dx + (p2.dx - p1.dx) * end, p1.dy + (p2.dy - p1.dy) * end);
            }
            canvas.drawPath(dashedPath, segmentIndicatorPaint);

            canvas.drawCircle(
                midPoint, handleRadius / 2 / scale, segmentAddPointPaint);
          }
        }
      }

      String? labelText;
      if (firstSelected != null && lastSelected != null) {
        if (i == firstSelected) {
          labelText = "A";
        } else if (i == lastSelected) {
          labelText = "B";
        }
      }

      if (labelText != null) {
        Offset center = Offset.zero;
        if (shapes[i].points.isNotEmpty) {
          for (final Offset p in shapes[i].points) {
            center += p;
          }
          center = Offset(
            center.dx / shapes[i].points.length,
            center.dy / shapes[i].points.length,
          );
        }
       
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
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RelationshipPainter oldDelegate) {
    if (!identical(shapes, oldDelegate.shapes)) {
      return true;
    }

    if (shapes.length != oldDelegate.shapes.length) return true;

    for (int i = 0; i < shapes.length; i++) {
      if (!identical(shapes[i], oldDelegate.shapes[i])) {
        return true;
      }
    }

    if (!listEquals(selectedIndices, oldDelegate.selectedIndices)) return true;
    if (draggingShapeIndex != oldDelegate.draggingShapeIndex) return true;
    if (draggingPointIndex != oldDelegate.draggingPointIndex) return true;
    if (isLinkMode != oldDelegate.isLinkMode) return true;
    if (isEditVerticesMode != oldDelegate.isEditVerticesMode) return true;
    if (handleRadius != oldDelegate.handleRadius) return true;
    if (showAddPointIndicators != oldDelegate.showAddPointIndicators) {
      return true;
    }
    if (scale != oldDelegate.scale) return true;
    if (offset != oldDelegate.offset) return true;

    return false;
  }
}