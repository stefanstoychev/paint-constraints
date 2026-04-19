import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:frontend/models/canvas_data.dart';
import 'package:frontend/models/color_constraints.dart';
import 'package:frontend/models/color_relationship.dart';
import 'package:frontend/models/shape_data.dart';
import 'package:frontend/utils/geometry_utils.dart';

import 'package:frontend/models/canvas_project.dart';
import 'package:frontend/controllers/project_manager.dart';
import 'package:frontend/commands/canvas_command.dart';
import 'package:frontend/commands/command_history.dart';
import 'package:frontend/commands/shape_commands.dart';
import 'package:frontend/commands/vertex_commands.dart';
import 'package:frontend/commands/relationship_commands.dart';
import 'package:frontend/services/solver_service.dart';

class CanvasController extends ChangeNotifier {
  final CommandHistory commandHistory = CommandHistory();

  void executeCommand(CanvasCommand command) {
    commandHistory.execute(command);
    notifyListeners();
  }

  void undo() {
    commandHistory.undo();
    notifyListeners();
  }

  void redo() {
    commandHistory.redo();
    notifyListeners();
  }

  CanvasProject? currentProject;
  final SolverService _solverService = SolverService();

  String get solverUrl => _solverService.baseUrl;
  set solverUrl(String value) {
    _solverService.baseUrl = value;
    notifyListeners();
  }

  Future<void> solveRelationships(BuildContext context) async {
    if (activeRelationships.isEmpty) return;

    final results = await _solverService.solve(activeRelationships);
    if (results != null) {
      final Map<int, HSVColor> oldColors = {};
      final Map<int, HSVColor> newColors = {};
      
      for (final result in results) {
        if (result.index >= 0 && result.index < allShapes.length) {
          oldColors[result.index] = allShapes[result.index].hsv;
          newColors[result.index] = HSVColor.fromAHSV(
            1.0, 
            result.h, 
            result.s / 100, 
            result.v / 100,
          );
        }
      }
      
      if (newColors.isNotEmpty) {
        executeCommand(UpdateShapeColorsCommand(this, oldColors, newColors));
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to solve constraints')),
        );
      }
    }
  }

  void loadProject(CanvasProject project) {
    currentProject = project;
    allShapes = List.from(project.data.shapes);
    activeRelationships = List.from(project.data.relationships);
    
    // Reset view
    currentScale = 1.0;
    currentOffset = Offset.zero;
    selectedIndices.clear();
    selectedVertexIndex = null;
    
    notifyListeners();
  }

  Future<void> saveCurrentProject(BuildContext context, ProjectManager projectManager) async {
    if (currentProject == null) return;
    
    final thumbnail = await captureThumbnail();
    
    final updatedProject = currentProject!.copyWith(
      data: CanvasData(
        shapes: allShapes,
        relationships: activeRelationships,
      ),
      thumbnailBase64: thumbnail,
    );
    
    await projectManager.updateProject(updatedProject);
    currentProject = updatedProject;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project saved'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<String?> captureThumbnail() async {
    try {
      final rect = canvasRect;
      
      // Use a slightly higher resolution for better clarity
      const double targetWidth = 300.0;
      final double scaleFactor = targetWidth / rect.width;
      final double targetHeight = rect.height * scaleFactor;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 1. Scale to target dimensions
      canvas.scale(scaleFactor);
      
      // 2. Translate to align artboard top-left with (0,0)
      canvas.translate(-rect.left, -rect.top);

      // 3. Draw artboard background (using world coordinates)
      final backgroundPaint = Paint()..color = Colors.white;
      canvas.drawRect(rect, backgroundPaint);

      // 4. Draw shapes
      final shapePaint = Paint()..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (final shape in allShapes) {
        final path = Path();
        if (shape.points.isNotEmpty) {
          path.moveTo(shape.points[0].dx, shape.points[0].dy);
          for (int i = 1; i < shape.points.length; i++) {
            path.lineTo(shape.points[i].dx, shape.points[i].dy);
          }
          path.close();
        }

        shapePaint.color = shape.hsv.toColor();
        canvas.drawPath(path, shapePaint);

        strokePaint.color =
            shape.hsv.withValue(max(0, shape.hsv.value - 0.2)).toColor();
        canvas.drawPath(path, strokePaint);
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        targetWidth.toInt(),
        targetHeight.toInt(),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;
      return base64Encode(byteData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error capturing thumbnail: $e');
      return null;
    }
  }

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
  bool showColorLabels = false;

  void toggleShowColorLabels() {
    showColorLabels = !showColorLabels;
    notifyListeners();
  }

  final ColorConstraints colorConstraints =
      ColorConstraints.withCommonRelationships();

  List<ShapeRelationship> activeRelationships = <ShapeRelationship>[];

  double currentScale = 1.0;
  Offset currentOffset = Offset.zero;
  double _previousScale = 1.0;
  Offset _previousOffset = Offset.zero;
  Offset _previousFocalPoint = Offset.zero;

  int? draggingShapeIndex;
  int? draggingPointIndex;
  bool _isDraggingWholeShape = false;
  int? selectedVertexIndex;
  Offset? _draggedPointInitialPosition;
  Offset? _dragStartWorldPoint;
  Map<int, List<Offset>>? _draggedShapesInitialPoints;

  // Gesture tracking
  DateTime? _twoFingerGestureStartTime;
  int _tapPointerCount = 0;
  DateTime? _lastTwoFingerTapTime;

  static const double handleRadius = 25.0;
  static const double _segmentTapTolerance = 10.0;

  Rect get canvasRect => currentProject?.canvasRect ?? const Rect.fromLTWH(20, 20, 460, 320);

  Offset _screenToWorld(Offset screenPoint) {
    return (screenPoint - currentOffset) / currentScale;
  }

  Offset _clampPoint(Offset point) {
    final rect = canvasRect;
    return Offset(
      point.dx.clamp(rect.left, rect.right),
      point.dy.clamp(rect.top, rect.bottom),
    );
  }

  int _nextShapeZIndex() {
    if (allShapes.isEmpty) return 0;
    return allShapes.map<int>((ShapeData shape) => shape.zIndex).reduce(max) +
        1;
  }

  void addShape() {
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
        .map<Offset>((Offset p) => _clampPoint(p + offsetTranslation))
        .toList();

    final double randomHue = (DateTime.now().millisecond.toDouble() % 360)
        .roundToDouble();

    final newShape = ShapeData(
      points: translatedPoints,
      hsv: HSVColor.fromAHSV(1, randomHue, 0.7, 0.8),
      zIndex: _nextShapeZIndex(),
    );

    executeCommand(AddShapeCommand(this, newShape));
  }

  void toggleLinkMode() {
    isLinkMode = !isLinkMode;
    isEditVerticesMode = false;
    selectedIndices.clear();
    selectedVertexIndex = null;
    notifyListeners();
  }

  void toggleEditVerticesMode() {
    isEditVerticesMode = !isEditVerticesMode;
    isLinkMode = false;
    selectedIndices.clear();
    selectedVertexIndex = null;
    notifyListeners();
  }

  void toggleShowRelationships() {
    showRelationships = !showRelationships;
    notifyListeners();
  }

  void applyRelationship(ColorRelationship relationship, BuildContext context) {
    if (selectedIndices.length != 2) return;
    final int sourceIdx = selectedIndices.first;
    final int targetIdx = selectedIndices.last;

    final bool hasReverseRelationship = activeRelationships.any(
      (ShapeRelationship r) =>
          r.sourceShapeIndex == targetIdx &&
          r.targetShapeIndex == sourceIdx &&
          r.relationship.component == relationship.component,
    );
    if (hasReverseRelationship) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reverse relationship already exists')),
        );
      }
      return;
    }

    final shapeRelationship = ShapeRelationship(
      sourceIdx,
      targetIdx,
      relationship,
    );
    final int existingRelationshipIndex = activeRelationships.indexWhere(
      (ShapeRelationship activeRelationship) =>
          activeRelationship.hasSameType(shapeRelationship),
    );

    final HSVColor targetHsv = allShapes[targetIdx].hsv;
    final HSVColor newTargetHsv = colorConstraints.applyOffset(
      targetHsv,
      relationship.component,
      relationship.offset,
    );

    ShapeRelationship? prevRelationship;
    if (existingRelationshipIndex != -1) {
      prevRelationship = activeRelationships[existingRelationshipIndex];
    }

    executeCommand(
      ApplyRelationshipCommand(
        controller: this,
        newRelationship: shapeRelationship,
        newTargetHsv: newTargetHsv,
        targetShapeIndex: targetIdx,
        previousRelationship: prevRelationship,
        previousTargetHsv: targetHsv,
      ),
    );
  }

  void handleTapDown(TapDownDetails details) {
    if (draggingShapeIndex != null) return;

    final Offset worldPosition = _screenToWorld(details.localPosition);
    final double worldHandleRadius = handleRadius / currentScale;
    final double worldSegmentTapTolerance = _segmentTapTolerance / currentScale;

    if (isEditVerticesMode && selectedIndices.length == 1) {
      final int selectedShapeIndex = selectedIndices.first;
      final List<Offset> points = allShapes[selectedShapeIndex].points;

      for (int i = 0; i < points.length; i++) {
        if ((points[i] - worldPosition).distance < worldHandleRadius) {
          selectedVertexIndex = i;
          notifyListeners();
          return;
        }
      }

      for (int i = 0; i < points.length; i++) {
        final Offset p1 = points[i];
        final Offset p2 = points[(i + 1) % points.length];

        if (GeometryUtils.distanceToSegment(worldPosition, p1, p2) <
            worldSegmentTapTolerance) {
          executeCommand(
            AddVertexCommand(
              this,
              selectedShapeIndex,
              i + 1,
              _clampPoint(worldPosition),
            ),
          );
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
      if (GeometryUtils.isPointInPolygon(worldPosition, entry.value.points)) {
        tappedShapeIndex = entry.key;
        break;
      }
    }

    selectedVertexIndex = null;
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
        selectedIndices.clear();
        if (!selectedIndices.contains(tappedShapeIndex)) {
          selectedIndices.add(tappedShapeIndex);
        }
      }
    } else {
      selectedIndices.clear();
    }
    notifyListeners();
  }

  void handleScaleStart(ScaleStartDetails details) {
    final Offset localFocalPoint = details.localFocalPoint;

    _previousScale = currentScale;
    _previousOffset = currentOffset;
    _previousFocalPoint = localFocalPoint;

    draggingShapeIndex = null;
    draggingPointIndex = null;
    _isDraggingWholeShape = false;
    _draggedPointInitialPosition = null;
    _dragStartWorldPoint = null;
    _draggedShapesInitialPoints = null;

    _tapPointerCount = details.pointerCount;
    if (_tapPointerCount == 2) {
      _twoFingerGestureStartTime = DateTime.now();
    }

    if (isEditVerticesMode &&
        selectedIndices.length == 1 &&
        details.pointerCount == 1) {
      final Offset worldPosition = _screenToWorld(localFocalPoint);
      final double worldHandleRadius = handleRadius / currentScale;

      final int shapeIndex = selectedIndices.first;
      final ShapeData shape = allShapes[shapeIndex];
      for (int i = 0; i < shape.points.length; i++) {
        final Offset point = shape.points[i];
        if ((point - worldPosition).distance < worldHandleRadius) {
          draggingShapeIndex = shapeIndex;
          draggingPointIndex = i;
          selectedVertexIndex = i;
          _draggedPointInitialPosition = point;
          _dragStartWorldPoint = worldPosition;
          notifyListeners();
          return;
        }
      }
    }

    if (!isLinkMode &&
        details.pointerCount == 1 &&
        selectedIndices.isNotEmpty) {
      final Offset worldPosition = _screenToWorld(localFocalPoint);
      for (final int index in selectedIndices.reversed) {
        if (GeometryUtils.isPointInPolygon(
          worldPosition,
          allShapes[index].points,
        )) {
          _isDraggingWholeShape = true;
          _dragStartWorldPoint = worldPosition;
          _draggedShapesInitialPoints = <int, List<Offset>>{};
          for (final int shapeIndex in selectedIndices) {
            _draggedShapesInitialPoints![shapeIndex] = List<Offset>.from(
              allShapes[shapeIndex].points,
            );
          }
          notifyListeners();
          return;
        }
      }
    }
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    final Offset localFocalPoint = details.localFocalPoint;

    if (_isDraggingWholeShape &&
        details.pointerCount == 1 &&
        _dragStartWorldPoint != null &&
        _draggedShapesInitialPoints != null) {
      final Offset currentWorldFocalPoint = _screenToWorld(localFocalPoint);
      final Offset deltaWorld = currentWorldFocalPoint - _dragStartWorldPoint!;

      final List<ShapeData> tempAllShapes = List<ShapeData>.from(allShapes);
      for (final int shapeIndex in selectedIndices) {
        final List<Offset>? initialPoints =
            _draggedShapesInitialPoints![shapeIndex];
        if (initialPoints != null) {
          final List<Offset> updatedPoints = initialPoints
              .map<Offset>((Offset point) => _clampPoint(point + deltaWorld))
              .toList();
          tempAllShapes[shapeIndex] = tempAllShapes[shapeIndex].copyWith(
            points: updatedPoints,
          );
        }
      }
      allShapes = tempAllShapes;
    } else if (draggingShapeIndex != null &&
        draggingPointIndex != null &&
        details.pointerCount == 1) {
      selectedVertexIndex = draggingPointIndex;
      final Offset currentWorldFocalPoint = _screenToWorld(localFocalPoint);
      final Offset deltaWorld = currentWorldFocalPoint - _dragStartWorldPoint!;

      final List<ShapeData> tempAllShapes = List<ShapeData>.from(allShapes);
      final List<Offset> updatedPoints = List<Offset>.from(
        tempAllShapes[draggingShapeIndex!].points,
      );
      updatedPoints[draggingPointIndex!] =
          _clampPoint(_draggedPointInitialPosition! + deltaWorld);

      tempAllShapes[draggingShapeIndex!] = tempAllShapes[draggingShapeIndex!]
          .copyWith(points: updatedPoints);
      allShapes = tempAllShapes;
    } else {
      currentScale = (_previousScale * details.scale).clamp(0.3, 5.0);

      final Offset focalPointAtStartWorld =
          (_previousFocalPoint - _previousOffset) / _previousScale;
      currentOffset = localFocalPoint - focalPointAtStartWorld * currentScale;
    }
    notifyListeners();
  }

  void handleScaleEnd(ScaleEndDetails details) {
    if (_isDraggingWholeShape && _draggedShapesInitialPoints != null) {
      final Map<int, List<Offset>> finalPoints = {};
      for (final int shapeIndex in selectedIndices) {
        finalPoints[shapeIndex] = List<Offset>.from(
          allShapes[shapeIndex].points,
        );
      }

      final tempShapes = List<ShapeData>.from(allShapes);
      for (final int shapeIndex in selectedIndices) {
        if (_draggedShapesInitialPoints!.containsKey(shapeIndex)) {
          tempShapes[shapeIndex] = tempShapes[shapeIndex].copyWith(
            points: _draggedShapesInitialPoints![shapeIndex],
          );
        }
      }
      allShapes = tempShapes;

      executeCommand(
        MoveShapeCommand(this, _draggedShapesInitialPoints!, finalPoints),
      );
    } else if (draggingShapeIndex != null &&
        draggingPointIndex != null &&
        _draggedPointInitialPosition != null) {
      final finalPosition =
          allShapes[draggingShapeIndex!].points[draggingPointIndex!];

      final tempShapes = List<ShapeData>.from(allShapes);
      final points = List<Offset>.from(tempShapes[draggingShapeIndex!].points);
      points[draggingPointIndex!] = _draggedPointInitialPosition!;
      tempShapes[draggingShapeIndex!] = tempShapes[draggingShapeIndex!]
          .copyWith(points: points);
      allShapes = tempShapes;

      executeCommand(
        MoveVertexCommand(
          this,
          draggingShapeIndex!,
          draggingPointIndex!,
          _draggedPointInitialPosition!,
          finalPosition,
        ),
      );
    }

    draggingShapeIndex = null;
    draggingPointIndex = null;
    _isDraggingWholeShape = false;
    _draggedPointInitialPosition = null;
    _dragStartWorldPoint = null;
    _draggedShapesInitialPoints = null;

    if (_tapPointerCount == 2 && _twoFingerGestureStartTime != null) {
      final duration = DateTime.now().difference(_twoFingerGestureStartTime!);
      if (duration.inMilliseconds < 300) {
        _handleTwoFingerTap();
      }
    }
    _twoFingerGestureStartTime = null;
    _tapPointerCount = 0;

    _previousScale = currentScale;
    _previousOffset = currentOffset;
    notifyListeners();
  }

  void _handleTwoFingerTap() {
    final now = DateTime.now();
    if (_lastTwoFingerTapTime != null &&
        now.difference(_lastTwoFingerTapTime!).inMilliseconds < 500) {
      if (commandHistory.canUndo) {
        undo();
      }
      _lastTwoFingerTapTime = null;
    } else {
      _lastTwoFingerTapTime = now;
    }
  }

  void updateZoomScale(double newScale, Size screenSize) {
    currentScale = newScale.clamp(0.3, 5.0);
    final Offset screenCenter = Offset(
      screenSize.width / 2,
      screenSize.height / 2,
    );
    final Offset centerWorldAtPrevScale =
        (screenCenter - _previousOffset) / _previousScale;
    currentOffset = screenCenter - centerWorldAtPrevScale * currentScale;
    _previousScale = currentScale;
    _previousOffset = currentOffset;
    _previousFocalPoint = screenCenter;
    notifyListeners();
  }

  void resetZoomScale() {
    currentScale = 1.0;
    currentOffset = Offset.zero;
    _previousScale = 1.0;
    _previousOffset = Offset.zero;
    _previousFocalPoint = Offset.zero;
    notifyListeners();
  }

  void deleteSelectedVertex() {
    if (!isEditVerticesMode ||
        selectedIndices.length != 1 ||
        selectedVertexIndex == null) {
      return;
    }

    final int shapeIndex = selectedIndices.first;
    final List<Offset> points = allShapes[shapeIndex].points;
    if (points.length <= 3) return;

    final position = points[selectedVertexIndex!];
    executeCommand(
      DeleteVertexCommand(this, shapeIndex, selectedVertexIndex!, position),
    );
  }

  void pushSelectedShapesToBack() {
    if (selectedIndices.isEmpty) return;

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

    executeCommand(
      ReorderShapesCommand(this, List.from(allShapes), tempShapes),
    );
  }

  void sendSelectedShapesToFront() {
    if (selectedIndices.isEmpty) return;

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

    executeCommand(
      ReorderShapesCommand(this, List.from(allShapes), tempShapes),
    );
  }
}
