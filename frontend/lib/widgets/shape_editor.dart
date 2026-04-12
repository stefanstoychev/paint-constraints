import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/color_component.dart';
import 'package:frontend/models/color_constraints.dart';
import 'package:frontend/models/color_relationship.dart';
import 'package:frontend/models/shape_data.dart';
import 'package:frontend/painters/relationship_painter.dart';
import 'package:frontend/widgets/link_button.dart';

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
  bool showRelationships = true;

  final ColorConstraints colorConstraints =
      ColorConstraints.withCommonRelationships();

  // Store active relationships between shapes
  List<ShapeRelationship> activeRelationships = <ShapeRelationship>[];

  double _currentScale = 1.0;
  Offset _currentOffset = Offset.zero;
  double _previousScale = 1.0;
  Offset _previousOffset = Offset.zero;
  Offset _previousFocalPoint = Offset.zero;

  int? _draggingShapeIndex;
  int? _draggingPointIndex;
  bool _isDraggingWholeShape = false;
  int? _selectedVertexIndex;
  Offset? _draggedPointInitialPosition;
  Offset? _dragStartWorldPoint;
  Map<int, List<Offset>>? _draggedShapesInitialPoints;

  static const double _handleRadius = 25.0;
  static const double _segmentTapTolerance = 10.0;

  Offset _screenToWorld(Offset screenPoint) {
    return (screenPoint - _currentOffset) / _currentScale;
  }

  int _nextShapeZIndex() {
    if (allShapes.isEmpty) return 0;
    return allShapes.map<int>((ShapeData shape) => shape.zIndex).reduce(max) +
        1;
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

      final double randomHue = (DateTime.now().millisecond.toDouble() % 360)
          .roundToDouble();

      allShapes = <ShapeData>[
        ...allShapes,
        ShapeData(
          points: translatedPoints,
          hsv: HSVColor.fromAHSV(1, randomHue, 0.7, 0.8),
          zIndex: _nextShapeZIndex(),
        ),
      ];
      selectedIndices = <int>[allShapes.length - 1];
      _selectedVertexIndex = null;
    });
  }

  void _applyRelationship(ColorRelationship relationship) {
    if (selectedIndices.length != 2) return;
    final int sourceIdx = selectedIndices.first;
    final int targetIdx = selectedIndices.last;

    // Prevent creating a reverse relationship
    final bool hasReverseRelationship = activeRelationships.any(
      (ShapeRelationship r) =>
          r.sourceShapeIndex == targetIdx &&
          r.targetShapeIndex == sourceIdx &&
          r.relationship.component == relationship.component,
    );
    if (hasReverseRelationship) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reverse relationship already exists')),
      );
      return;
    }

    setState(() {
      // Create and store the relationship, replacing any existing relationship of the same type.
      final shapeRelationship = ShapeRelationship(
        sourceIdx,
        targetIdx,
        relationship,
      );
      final int existingRelationshipIndex = activeRelationships.indexWhere(
        (ShapeRelationship activeRelationship) =>
            activeRelationship.hasSameType(shapeRelationship),
      );

      if (existingRelationshipIndex != -1) {
        activeRelationships[existingRelationshipIndex] = shapeRelationship;
      } else {
        activeRelationships.add(shapeRelationship);
      }

      // Apply the relationship immediately
      final HSVColor targetHsv = allShapes[targetIdx].hsv;
      final HSVColor newTargetHsv = colorConstraints.applyOffset(
        targetHsv,
        relationship.component,
        relationship.offset,
      );

      final List<ShapeData> tempAllShapes = List<ShapeData>.from(allShapes);
      tempAllShapes[targetIdx] = tempAllShapes[targetIdx].copyWith(
        hsv: newTargetHsv,
      );
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
    final double l2 = (pow(p2.dx - p1.dx, 2) + pow(p2.dy - p1.dy, 2))
        .toDouble();
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
    final double worldSegmentTapTolerance =
        _segmentTapTolerance / _currentScale;

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
            final List<ShapeData> tempAllShapes = List<ShapeData>.from(
              allShapes,
            );
            final List<Offset> currentPoints = List<Offset>.from(
              tempAllShapes[selectedShapeIndex].points,
            );
            currentPoints.insert(i + 1, worldPosition);

            tempAllShapes[selectedShapeIndex] =
                tempAllShapes[selectedShapeIndex].copyWith(
                  points: currentPoints,
                );
            allShapes = tempAllShapes;
          });
          return;
        }
      }
    }

    int? tappedShapeIndex;
    final List<MapEntry<int, ShapeData>> sortedShapeEntries =
        allShapes.asMap().entries.toList()..sort((a, b) {
          final int zCompare = b.value.zIndex.compareTo(a.value.zIndex);
          return zCompare != 0 ? zCompare : b.key.compareTo(a.key);
        });

    for (final MapEntry<int, ShapeData> entry in sortedShapeEntries) {
      if (_isPointInPolygon(worldPosition, entry.value.points)) {
        tappedShapeIndex = entry.key;
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
          if (!selectedIndices.contains(tappedShapeIndex)) {
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
    _isDraggingWholeShape = false;
    _draggedPointInitialPosition = null;
    _dragStartWorldPoint = null;
    _draggedShapesInitialPoints = null;

    if (isEditVerticesMode &&
        selectedIndices.length == 1 &&
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

    if (!isLinkMode &&
        details.pointerCount == 1 &&
        selectedIndices.isNotEmpty) {
      final Offset worldPosition = _screenToWorld(localFocalPoint);
      for (final int index in selectedIndices.reversed) {
        if (_isPointInPolygon(worldPosition, allShapes[index].points)) {
          _isDraggingWholeShape = true;
          _dragStartWorldPoint = worldPosition;
          _draggedShapesInitialPoints = <int, List<Offset>>{};
          for (final int shapeIndex in selectedIndices) {
            _draggedShapesInitialPoints![shapeIndex] = List<Offset>.from(
              allShapes[shapeIndex].points,
            );
          }
          return;
        }
      }
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      final Offset localFocalPoint = details.localFocalPoint;

      if (_isDraggingWholeShape &&
          details.pointerCount == 1 &&
          _dragStartWorldPoint != null &&
          _draggedShapesInitialPoints != null) {
        final Offset currentWorldFocalPoint = _screenToWorld(localFocalPoint);
        final Offset deltaWorld =
            currentWorldFocalPoint - _dragStartWorldPoint!;

        final List<ShapeData> tempAllShapes = List<ShapeData>.from(allShapes);
        for (final int shapeIndex in selectedIndices) {
          final List<Offset>? initialPoints =
              _draggedShapesInitialPoints![shapeIndex];
          if (initialPoints != null) {
            final List<Offset> updatedPoints = initialPoints
                .map<Offset>((Offset point) => point + deltaWorld)
                .toList();
            tempAllShapes[shapeIndex] = tempAllShapes[shapeIndex].copyWith(
              points: updatedPoints,
            );
          }
        }
        allShapes = tempAllShapes;
      } else if (_draggingShapeIndex != null &&
          _draggingPointIndex != null &&
          details.pointerCount == 1) {
        _selectedVertexIndex = _draggingPointIndex;
        final Offset currentWorldFocalPoint = _screenToWorld(localFocalPoint);
        final Offset deltaWorld =
            currentWorldFocalPoint - _dragStartWorldPoint!;

        final List<ShapeData> tempAllShapes = List<ShapeData>.from(allShapes);
        final List<Offset> updatedPoints = List<Offset>.from(
          tempAllShapes[_draggingShapeIndex!].points,
        );
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
    _isDraggingWholeShape = false;
    _draggedPointInitialPosition = null;
    _dragStartWorldPoint = null;
    _draggedShapesInitialPoints = null;

    _previousScale = _currentScale;
    _previousOffset = _currentOffset;
  }

  void _updateZoomScale(double newScale) {
    setState(() {
      _currentScale = newScale.clamp(0.3, 5.0);
      final Offset screenCenter = Offset(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
      );
      final Offset centerWorldAtPrevScale =
          (screenCenter - _previousOffset) / _previousScale;
      _currentOffset = screenCenter - centerWorldAtPrevScale * _currentScale;
      _previousScale = _currentScale;
      _previousOffset = _currentOffset;
      _previousFocalPoint = screenCenter;
    });
  }

  void _deleteSelectedVertex() {
    if (!isEditVerticesMode ||
        selectedIndices.length != 1 ||
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
      tempShapes[shapeIndex] = tempShapes[shapeIndex].copyWith(
        points: updatedPoints,
      );
      allShapes = tempShapes;
      _selectedVertexIndex = null;
      _draggingPointIndex = null;
      _draggingShapeIndex = null;
    });
  }

  void _pushSelectedShapesToBack() {
    if (selectedIndices.isEmpty) return;

    setState(() {
      final List<ShapeData> tempShapes = List<ShapeData>.from(allShapes);
      final int minZIndex = allShapes
          .map<int>((ShapeData shape) => shape.zIndex)
          .reduce(min);
      final List<int> sortedSelectedIndices = List<int>.from(selectedIndices)
        ..sort((a, b) => allShapes[a].zIndex.compareTo(allShapes[b].zIndex));

      for (int i = 0; i < sortedSelectedIndices.length; i++) {
        final int shapeIndex = sortedSelectedIndices[i];
        tempShapes[shapeIndex] = tempShapes[shapeIndex].copyWith(
          zIndex: minZIndex - (sortedSelectedIndices.length - i),
        );
      }

      allShapes = tempShapes;
    });
  }

  void _sendSelectedShapesToFront() {
    if (selectedIndices.isEmpty) return;

    setState(() {
      final List<ShapeData> tempShapes = List<ShapeData>.from(allShapes);
      final int maxZIndex = allShapes
          .map<int>((ShapeData shape) => shape.zIndex)
          .reduce(max);
      final List<int> sortedSelectedIndices = List<int>.from(selectedIndices)
        ..sort((a, b) => allShapes[a].zIndex.compareTo(allShapes[b].zIndex));

      for (int i = 0; i < sortedSelectedIndices.length; i++) {
        final int shapeIndex = sortedSelectedIndices[i];
        tempShapes[shapeIndex] = tempShapes[shapeIndex].copyWith(
          zIndex: maxZIndex + i + 1,
        );
      }

      allShapes = tempShapes;
    });
  }

  Future<void> _saveShapes() async {
    final prefs = await SharedPreferences.getInstance();
    final shapesJson = jsonEncode(
      allShapes.map((shape) => shape.toJson()).toList(),
    );
    final relationshipsJson = jsonEncode(
      activeRelationships.map((rel) => rel.toJson()).toList(),
    );
    await prefs.setString('saved_shapes', shapesJson);
    await prefs.setString('saved_relationships', relationshipsJson);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shapes saved'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _loadShapes() async {
    final prefs = await SharedPreferences.getInstance();
    final shapesJson = prefs.getString('saved_shapes');
    final relationshipsJson = prefs.getString('saved_relationships');
    if (shapesJson != null) {
      try {
        final List<dynamic> shapesDecoded = jsonDecode(shapesJson);
        final List<ShapeRelationship> relationshipsDecoded =
            relationshipsJson != null
            ? (jsonDecode(relationshipsJson) as List<dynamic>)
                  .map(
                    (item) => ShapeRelationship.fromJson(
                      item as Map<String, dynamic>,
                    ),
                  )
                  .toList()
            : <ShapeRelationship>[];
        setState(() {
          allShapes = shapesDecoded
              .map((item) => ShapeData.fromJson(item as Map<String, dynamic>))
              .toList();
          activeRelationships = relationshipsDecoded;
          selectedIndices.clear();
          _selectedVertexIndex = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shapes loaded'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error loading shapes: $e')));
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
              color: _selectedVertexIndex != null
                  ? Colors.white
                  : Colors.white38,
              onPressed: _selectedVertexIndex != null
                  ? _deleteSelectedVertex
                  : null,
              tooltip: 'Delete selected vertex',
            ),
          if (!isLinkMode)
            IconButton(
              icon: Icon(
                showRelationships ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => showRelationships = !showRelationships),
              tooltip: showRelationships
                  ? 'Hide relationships'
                  : 'Show relationships',
            ),
          if (!isLinkMode)
            IconButton(
              icon: const Icon(Icons.vertical_align_top),
              onPressed: selectedIndices.isNotEmpty
                  ? _sendSelectedShapesToFront
                  : null,
              tooltip: 'Send selected shape to front',
            ),
          if (!isLinkMode)
            IconButton(
              icon: const Icon(Icons.vertical_align_bottom),
              onPressed: selectedIndices.isNotEmpty
                  ? _pushSelectedShapesToBack
                  : null,
              tooltip: 'Push selected shape to back',
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
        clipBehavior: Clip.none,
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
                  activeRelationships: activeRelationships,
                  draggingShapeIndex: _draggingShapeIndex,
                  draggingPointIndex: _draggingPointIndex,
                  selectedVertexIndex: _selectedVertexIndex,
                  handleRadius: _handleRadius,
                  isLinkMode: isLinkMode,
                  isEditVerticesMode: isEditVerticesMode,
                  showAddPointIndicators: showAddPointIndicators,
                  showRelationships: showRelationships,
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
                        'Define Relationship (B constraint relative to A)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildRelationshipRow(
                        'Hue Constraints',
                        colorConstraints.relationships
                            .where((r) => r.component == ColorComponent.hue)
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      _buildRelationshipRow(
                        'Saturation Constraints',
                        colorConstraints.relationships
                            .where(
                              (r) => r.component == ColorComponent.saturation,
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      _buildRelationshipRow(
                        'Value Constraints',
                        colorConstraints.relationships
                            .where((r) => r.component == ColorComponent.value)
                            .toList(),
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
      bottom: 20,
      left: 20,
      child: Card(
        color: Colors.black54,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.zoom_out, color: Colors.white),
                onPressed: () => _updateZoomScale(_currentScale - 0.2),
                tooltip: 'Zoom Out',
              ),
              SizedBox(
                width: 150,
                child: Slider(
                  value: _currentScale,
                  min: 0.3,
                  max: 5.0,
                  divisions: ((5.0 - 0.3) * 10).round(),
                  onChanged: (double newValue) => _updateZoomScale(newValue),
                  activeColor: Colors.white,
                  inactiveColor: Colors.white38,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, color: Colors.white),
                onPressed: () => _updateZoomScale(_currentScale + 0.2),
                tooltip: 'Zoom In',
              ),
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
    List<ColorRelationship> relationships,
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
          children: relationships
              .map<Widget>(
                (ColorRelationship relationship) => LinkButton(
                  label: _getRelationshipLabel(relationship),
                  relationship: relationship,
                  onPressed: _applyRelationship,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  String _getRelationshipLabel(ColorRelationship relationship) {
    final offsetStr = relationship.offset == 0
        ? ''
        : (relationship.offset > 0
              ? ' + ${relationship.offset.toStringAsFixed(1)}'
              : ' - ${relationship.offset.abs().toStringAsFixed(1)}');

    switch (relationship.component) {
      case ColorComponent.hue:
        return 'Hue ${relationship.operator.symbol}$offsetStr';
      case ColorComponent.saturation:
        return 'Sat ${relationship.operator.symbol}$offsetStr';
      case ColorComponent.value:
        return 'Val ${relationship.operator.symbol}$offsetStr';
    }
  }
}
