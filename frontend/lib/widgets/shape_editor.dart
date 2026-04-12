import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/shape_data.dart';
import 'package:frontend/painters/relationship_painter.dart';

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

  double _currentScale = 1.0;
  Offset _currentOffset = Offset.zero;
  double _previousScale = 1.0;
  Offset _previousOffset = Offset.zero;
  Offset _previousFocalPoint = Offset.zero;

  int? _draggingShapeIndex;
  int? _draggingPointIndex;
  int? _selectedVertexIndex;
  Offset? _draggedPointInitialPosition;
  Offset? _dragStartWorldPoint;

  static const double _handleRadius = 25.0;
  static const double _segmentTapTolerance = 10.0;

  Offset _screenToWorld(Offset screenPoint) {
    return (screenPoint - _currentOffset) / _currentScale;
  }

  void _addShape() {
    setState(() {
      const List<Offset> newShapePoints = <Offset>[
        Offset(50, 50),
        Offset(150, 50),
        Offset(150, 150),
        Offset(50, 150),
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
      selectedIndices = <int>[allShapes.length - 1];
      _selectedVertexIndex = null;
    });
  }

  void _applyRelationship(ColorComponent component, double offsetValue) {
    if (selectedIndices.length != 2) return;
    final int sourceIdx = selectedIndices.first;
    final int targetIdx = selectedIndices.last;

    setState(() {
      final List<ShapeData> tempAllShapes = List<ShapeData>.from(allShapes);
      final HSVColor sourceHsv = tempAllShapes[sourceIdx].hsv;
      final HSVColor targetHsv = tempAllShapes[targetIdx].hsv;
      HSVColor newTargetHsv;

      switch (component) {
        case ColorComponent.hue:
          double newHue = (sourceHsv.hue + offsetValue) % 360;
          if (newHue < 0) newHue += 360;
          newTargetHsv = targetHsv.withHue(newHue);
          break;
        case ColorComponent.saturation:
          double newSaturation =
              (sourceHsv.saturation + offsetValue).clamp(0.0, 1.0);
          newTargetHsv = targetHsv.withSaturation(newSaturation);
          break;
        case ColorComponent.value:
          double newValue = (sourceHsv.value + offsetValue).clamp(0.0, 1.0);
          newTargetHsv = targetHsv.withValue(newValue);
          break;
      }

      tempAllShapes[targetIdx] =
          tempAllShapes[targetIdx].copyWith(hsv: newTargetHsv);
      allShapes = tempAllShapes;
    });
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

    late Offset projection;
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
          setState(() {
            _selectedVertexIndex = i;
          });
          return;
        }
      }

      for (int i = 0; i < points.length; i++) {
        final Offset p1 = points[i];
        final Offset p2 = points[(i + 1) % points.length];

        if (_distanceToSegment(worldPosition, p1, p2) <
            worldSegmentTapTolerance) {
          setState(() {
            final List<ShapeData> tempAllShapes = List<ShapeData>.from(allShapes);
            final List<Offset> currentPoints =
                List<Offset>.from(tempAllShapes[selectedShapeIndex].points);
            currentPoints.insert(i + 1, worldPosition);

            tempAllShapes[selectedShapeIndex] =
                tempAllShapes[selectedShapeIndex].copyWith(points: currentPoints);
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
      _selectedVertexIndex = null;
      if (tappedShapeIndex != null) {
        if (isEditVerticesMode) {
          selectedIndices = <int>[tappedShapeIndex];
        } else if (isLinkMode) {
          if (selectedIndices.contains(tappedShapeIndex)) {
            selectedIndices.remove(tappedShapeIndex);
          } else {
            if (selectedIndices.length < 2) {
              selectedIndices.add(tappedShapeIndex);
            } else {
              selectedIndices.removeAt(0);
              selectedIndices.add(tappedShapeIndex);
            }
          }
        } else {
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
    final Offset localFocalPoint = details.localFocalPoint;

    _previousScale = _currentScale;
    _previousOffset = _currentOffset;
    _previousFocalPoint = localFocalPoint;

    _draggingShapeIndex = null;
    _draggingPointIndex = null;
    _draggedPointInitialPosition = null;
    _dragStartWorldPoint = null;

    if (isEditVerticesMode && selectedIndices.length == 1 &&
        details.pointerCount == 1) {
      final Offset worldPosition = _screenToWorld(localFocalPoint);
      final double worldHandleRadius = _handleRadius / _currentScale;

      final int shapeIndex = selectedIndices.first;
      final ShapeData shape = allShapes[shapeIndex];
      for (int i = 0; i < shape.points.length; i++) {
        final Offset point = shape.points[i];
        if ((point - worldPosition).distance < worldHandleRadius) {
          _draggingShapeIndex = shapeIndex;
          _draggingPointIndex = i;
          _selectedVertexIndex = i;
          _draggedPointInitialPosition = point;
          _dragStartWorldPoint = worldPosition;
          return;
        }
      }
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      final Offset localFocalPoint = details.localFocalPoint;

      if (_draggingShapeIndex != null && _draggingPointIndex != null &&
          details.pointerCount == 1) {
        _selectedVertexIndex = _draggingPointIndex;
        final Offset currentWorldFocalPoint = _screenToWorld(localFocalPoint);
        final Offset deltaWorld = currentWorldFocalPoint - _dragStartWorldPoint!;

        final List<ShapeData> tempAllShapes = List<ShapeData>.from(allShapes);
        final List<Offset> updatedPoints =
            List<Offset>.from(tempAllShapes[_draggingShapeIndex!].points);
        updatedPoints[_draggingPointIndex!] =
            _draggedPointInitialPosition! + deltaWorld;

        tempAllShapes[_draggingShapeIndex!] =
            tempAllShapes[_draggingShapeIndex!].copyWith(points: updatedPoints);
        allShapes = tempAllShapes;
      } else {
        _currentScale = (_previousScale * details.scale).clamp(0.3, 5.0);

        final Offset focalPointAtStartWorld =
            (_previousFocalPoint - _previousOffset) / _previousScale;
        _currentOffset =
            localFocalPoint - focalPointAtStartWorld * _currentScale;
      }
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _draggingShapeIndex = null;
    _draggingPointIndex = null;
    _draggedPointInitialPosition = null;
    _dragStartWorldPoint = null;

    _previousScale = _currentScale;
    _previousOffset = _currentOffset;
  }

  void _deleteSelectedVertex() {
    if (!isEditVerticesMode || selectedIndices.length != 1 ||
        _selectedVertexIndex == null) {
      return;
    }

    final int shapeIndex = selectedIndices.first;
    final List<Offset> points = allShapes[shapeIndex].points;
    if (points.length <= 3) return;

    setState(() {
      final List<ShapeData> tempShapes = List<ShapeData>.from(allShapes);
      final List<Offset> updatedPoints = List<Offset>.from(points)
        ..removeAt(_selectedVertexIndex!);
      tempShapes[shapeIndex] = tempShapes[shapeIndex].copyWith(points: updatedPoints);
      allShapes = tempShapes;
      _selectedVertexIndex = null;
      _draggingPointIndex = null;
      _draggingShapeIndex = null;
    });
  }

  Future<void> _saveShapes() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(
      allShapes.map((shape) => shape.toJson()).toList(),
    );
    await prefs.setString('saved_shapes', json);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shapes saved'), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _loadShapes() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('saved_shapes');
    if (json != null) {
      try {
        final List<dynamic> decoded = jsonDecode(json);
        setState(() {
          allShapes = decoded
              .map((item) => ShapeData.fromJson(item as Map<String, dynamic>))
              .toList();
          selectedIndices.clear();
          _selectedVertexIndex = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shapes loaded'), duration: Duration(seconds: 1)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading shapes: $e')),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadShapes();
  }

  @override
  Widget build(BuildContext context) {
    final bool showAddPointIndicators =
        isEditVerticesMode && selectedIndices.length == 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditVerticesMode
              ? 'Edit Vertices Mode'
              : isLinkMode
                  ? 'Select 2 Shapes to Link'
                  : 'Shape Operations',
        ),
        actions: <Widget>[
          _buildModeButton(
            label: 'Link Mode',
            icon: Icons.link,
            isActive: isLinkMode,
            activeColor: Colors.green,
            onPressed: () => setState(() {
              isLinkMode = !isLinkMode;
              isEditVerticesMode = false;
              selectedIndices.clear();
              _selectedVertexIndex = null;
            }),
          ),
          _buildModeButton(
            label: 'Edit Vertices',
            icon: Icons.scatter_plot,
            isActive: isEditVerticesMode,
            activeColor: Colors.blue,
            onPressed: () => setState(() {
              isEditVerticesMode = !isEditVerticesMode;
              isLinkMode = false;
              selectedIndices.clear();
              _selectedVertexIndex = null;
            }),
          ),
          if (isEditVerticesMode)
            IconButton(
              icon: const Icon(Icons.delete),
              color: _selectedVertexIndex != null ? Colors.white : Colors.white38,
              onPressed:
                  _selectedVertexIndex != null ? _deleteSelectedVertex : null,
              tooltip: 'Delete selected vertex',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveShapes,
            tooltip: 'Save shapes',
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _loadShapes,
            tooltip: 'Load shapes',
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
              color: Colors.grey.shade900,
              child: CustomPaint(
                painter: RelationshipPainter(
                  shapes: allShapes,
                  selectedIndices: selectedIndices,
                  draggingShapeIndex: _draggingShapeIndex,
                  draggingPointIndex: _draggingPointIndex,
                  selectedVertexIndex: _selectedVertexIndex,
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
                        'Define Relationship (B = A + X)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildRelationshipRow(
                        'Hue (°)',
                        ColorComponent.hue,
                        <Map<String, dynamic>>[
                          {'label': 'Analogous (+30°)', 'value': 30.0},
                          {'label': 'Triadic (+120°)', 'value': 120.0},
                          {'label': 'Complementary (+180°)', 'value': 180.0},
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildRelationshipRow(
                        'Saturation',
                        ColorComponent.saturation,
                        <Map<String, dynamic>>[
                          {'label': 'Same', 'value': 0.0},
                          {'label': '+0.1', 'value': 0.1},
                          {'label': '-0.1', 'value': -0.1},
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildRelationshipRow(
                        'Value',
                        ColorComponent.value,
                        <Map<String, dynamic>>[
                          {'label': 'Same', 'value': 0.0},
                          {'label': '+0.1', 'value': 0.1},
                          {'label': '-0.1', 'value': -0.1},
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _buildZoomControls(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addShape,
        tooltip: 'Add New Shape',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: isActive ? activeColor : Colors.grey),
      label: Text(
        label,
        style: TextStyle(color: isActive ? activeColor : Colors.grey),
      ),
    );
  }

  Widget _buildZoomControls(BuildContext context) {
    return Positioned(
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
                  min: 0.3,
                  max: 5.0,
                  divisions: ((5.0 - 0.3) * 10).round(),
                  onChanged: (double newValue) {
                    setState(() {
                      _currentScale = newValue;
                      final Offset screenCenter = Offset(
                        MediaQuery.of(context).size.width / 2,
                        MediaQuery.of(context).size.height / 2,
                      );
                      final Offset centerWorldAtPrevScale =
                          (screenCenter - _previousOffset) / _previousScale;
                      _currentOffset =
                          screenCenter - centerWorldAtPrevScale * _currentScale;
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
                  label: option['label'] as String,
                  component: component,
                  offsetValue: option['value'] as double,
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
