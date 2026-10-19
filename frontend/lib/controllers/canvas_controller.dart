import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:frontend/commands/canvas_command.dart';
import 'package:frontend/commands/command_history.dart';
import 'package:frontend/controllers/project_manager.dart';
import 'package:frontend/models/canvas_data.dart';
import 'package:frontend/models/canvas_project.dart';
import 'package:frontend/models/color_constraint_models.dart';
import 'package:frontend/models/point_constraint_models.dart';
import 'package:frontend/models/shape_data.dart';
import 'package:frontend/services/solver_service.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/utils/geometry_utils.dart';

import '../commands/shape_commands.dart';
import '../commands/vertex_commands.dart';
import '../commands/vertex_link_commands.dart';
import 'constraint_manager.dart';
import 'viewport_controller.dart';

class CanvasController extends ChangeNotifier {
  final CommandHistory commandHistory = CommandHistory();

  // Sub-controllers
  late final ViewportController viewport = ViewportController()
    ..addListener(notifyListeners);
  late final ConstraintManager constraints = ConstraintManager()
    ..addListener(notifyListeners);

  List<ShapeData> allShapes = <ShapeData>[];
  List<int> selectedIndices = <int>[];

  EditMode editMode = EditMode.selectShape;

  bool get isLinkMode => editMode == EditMode.linkShapesColor;
  bool get isClampMode => editMode == EditMode.clampColor;
  bool get isEditVerticesMode => editMode == EditMode.editShapeVertexes;
  bool get isLinkVertexesMode => editMode == EditMode.linkVertexes;
  bool get isSplitShapeMode => editMode == EditMode.splitShape;

  bool isHueVisible = true;
  bool isSatVisible = true;
  bool isValueVisible = true;

  bool showRelationships = true;
  bool showColorLabels = false;

  CanvasProject? currentProject;
  late SolverService? _solverService;

  int? draggingShapeIndex;
  int? draggingPointIndex;
  bool _isDraggingWholeShape = false;
  int? selectedVertexIndex;
  Offset? _draggedPointInitialPosition;
  Offset? _dragStartWorldPoint;
  Map<int, List<Offset>>? _draggedShapesInitialPoints;
  // Vertices moved along with a drag because they are linked to it.
  Set<VertexRef> _draggedLinkedVertices = <VertexRef>{};

  VertexRef? pendingVertex;

  // Gesture tracking
  DateTime? _twoFingerGestureStartTime;
  int _tapPointerCount = 0;
  DateTime? _lastTwoFingerTapTime;

  static const double handleRadius = kHandleRadius;
  static const double _segmentTapTolerance = kSegmentTapTolerance;

  Rect get canvasRect =>
      currentProject?.canvasRect ?? const Rect.fromLTWH(20, 20, 460, 320);

  bool get hasSelected => selectedVertexIndex != null;

  bool get canRedo => commandHistory.canRedo;

  bool get canUndo => commandHistory.canUndo;

  void setSolver(SolverService solver) {
    _solverService = solver;
  }

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

  Future<void> solveRelationships(BuildContext context) async {
    await constraints.solveRelationships(
      context,
      solverService: _solverService,
      allShapes: allShapes,
      controller: this,
    );
  }

  void loadProject(CanvasProject project, {BuildContext? context}) {
    currentProject = project;
    allShapes = List.from(project.data.shapes);
    constraints.loadConstraints(
      project.data.relationships,
      project.data.constraints,
      project.data.vertexLinks,
    );

    commandHistory.clear();

    // Reset view
    viewport.resetZoomScale();
    selectedIndices = <int>[];
    selectedVertexIndex = null;
    pendingVertex = null;

    if (context != null) {
      fitToScreen(context);
    }

    notifyListeners();
  }

  Future<void> saveCurrentProject(
    BuildContext context,
    ProjectManager projectManager,
  ) async {
    if (currentProject == null) return;

    final thumbnail = await captureThumbnail();

    final updatedProject = currentProject!.copyWith(
      data: CanvasData(
        shapes: allShapes,
        relationships: constraints.activeRelationships,
        constraints: constraints.activeShapeColorConstraint,
        vertexLinks: List.of(constraints.activeVertexLinks),
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

      canvas.scale(scaleFactor);

      canvas.translate(-rect.left, -rect.top);

      final backgroundPaint = Paint()..color = Colors.white;
      canvas.drawRect(rect, backgroundPaint);

      final shapePaint = Paint()
        ..style = PaintingStyle.fill
        ..strokeWidth = 0.0;

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

  void toggleShowColorLabels() {
    showColorLabels = !showColorLabels;
    notifyListeners();
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
        .map<Offset>(
          (Offset p) => viewport.clampPoint(p + offsetTranslation, canvasRect),
        )
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

  void toggleClampMode() {
    toggleMode(EditMode.clampColor);
    selectedIndices = <int>[];
    selectedVertexIndex = null;
    notifyListeners();
  }

  void toggleMode(EditMode mode) {
    pendingVertex = null;
    if (mode != editMode) {
      editMode = mode;
    } else {
      editMode = EditMode.selectShape;
    }
  }

  void toggleLinkMode() {
    toggleMode(EditMode.linkShapesColor);
    selectedIndices = <int>[];
    selectedVertexIndex = null;
    notifyListeners();
  }

  void toggleEditVerticesMode() {
    toggleMode(EditMode.editShapeVertexes);
    selectedIndices = <int>[];
    selectedVertexIndex = null;
    notifyListeners();
  }

  void toggleLinkVertexesMode() {
    toggleMode(EditMode.linkVertexes);
    selectedIndices = <int>[];
    selectedVertexIndex = null;
    notifyListeners();
  }

  void toggleSplitShapeMode() {
    toggleMode(EditMode.splitShape);
    selectedIndices = <int>[];
    selectedVertexIndex = null;
    notifyListeners();
  }

  bool get canUnlinkPendingVertex =>
      pendingVertex != null && constraints.isLinked(pendingVertex!);

  /// Removes every link in the group of the pending vertex.
  void unlinkPendingVertex() {
    if (!canUnlinkPendingVertex) return;
    final Set<VertexRef> group = constraints.linkedGroup(pendingVertex!);
    final List<VertexLink> links = constraints.activeVertexLinks
        .where((l) => group.contains(l.a))
        .toList();
    pendingVertex = null;
    executeCommand(RemoveVertexLinksCommand(this, links));
  }

  /// Vertices of any shape under [worldPosition], topmost shape first.
  List<VertexRef> _verticesAt(Offset worldPosition) {
    final double worldHandleRadius = handleRadius / viewport.currentScale;
    final List<int> order = List<int>.generate(allShapes.length, (i) => i)
      ..sort((a, b) {
        final int zCompare = allShapes[b].zIndex.compareTo(allShapes[a].zIndex);
        return zCompare != 0 ? zCompare : b.compareTo(a);
      });
    final List<VertexRef> hits = <VertexRef>[];
    for (final int shapeIndex in order) {
      final List<Offset> points = allShapes[shapeIndex].points;
      for (int i = 0; i < points.length; i++) {
        if ((points[i] - worldPosition).distance < worldHandleRadius) {
          hits.add(VertexRef(shapeIndex, i));
        }
      }
    }
    return hits;
  }

  void _handleLinkVertexesTap(Offset worldPosition) {
    final List<VertexRef> hits = _verticesAt(worldPosition);
    final VertexRef? pending = pendingVertex;

    if (hits.isEmpty) {
      pendingVertex = null;
    } else if (pending == null) {
      pendingVertex = hits.first;
    } else {
      // Prefer a vertex that can actually be linked to the pending one, since
      // already-linked vertices sit on top of each other.
      final Set<VertexRef> pendingGroup = constraints.linkedGroup(pending);
      final VertexRef target = hits.firstWhere(
        (v) => v.shapeIndex != pending.shapeIndex && !pendingGroup.contains(v),
        orElse: () => hits.first,
      );
      if (target.shapeIndex == pending.shapeIndex ||
          pendingGroup.contains(target)) {
        pendingVertex = target;
      } else {
        executeCommand(AddVertexLinkCommand(this, pending, target));
        pendingVertex = null;
      }
    }
    notifyListeners();
  }

  void _handleSplitShapeTap(Offset worldPosition) {
    final List<VertexRef> hits = _verticesAt(worldPosition);
    final VertexRef? pending = pendingVertex;

    if (hits.isEmpty) {
      pendingVertex = null;
    } else if (pending == null) {
      pendingVertex = hits.first;
    } else {
      // Prefer another vertex of the pending vertex's shape.
      final VertexRef target = hits.firstWhere(
        (v) => v.shapeIndex == pending.shapeIndex && v != pending,
        orElse: () => hits.first,
      );
      if (target.shapeIndex == pending.shapeIndex &&
          GeometryUtils.isValidDiagonal(
            allShapes[target.shapeIndex].points,
            pending.vertexIndex,
            target.vertexIndex,
          )) {
        executeCommand(
          SplitShapeCommand(
            this,
            target.shapeIndex,
            pending.vertexIndex,
            target.vertexIndex,
          ),
        );
        pendingVertex = null;
      } else {
        // Neighbouring vertices, a cut leaving the shape, or another shape:
        // start over from the tapped vertex.
        pendingVertex = target;
      }
    }
    notifyListeners();
  }

  void toggleShowRelationships() {
    showRelationships = !showRelationships;
    notifyListeners();
  }

  void applyRelationship(ColorRelationship relationship, BuildContext context) {
    if (selectedIndices.length != 2) return;
    constraints.applyRelationship(
      sourceIdx: selectedIndices.first,
      targetIdx: selectedIndices.last,
      relationship: relationship,
      context: context,
      controller: this,
    );
  }

  void clearSelectedComponentRelationship(ColorComponent component) {
    if (selectedIndices.length != 2) return;
    constraints.clearComponentRelationship(
      shapeIndex1: selectedIndices.first,
      shapeIndex2: selectedIndices.last,
      component: component,
      controller: this,
    );
  }

  void clearSelectedRelationships() {
    if (selectedIndices.length != 2) return;
    constraints.clearSelectedRelationships(
      shapeIndex1: selectedIndices.first,
      shapeIndex2: selectedIndices.last,
      controller: this,
    );
  }

  void handleTapDown(TapDownDetails details) {
    if (draggingShapeIndex != null) return;

    final Offset worldPosition = viewport.screenToWorld(details.localPosition);
    final double worldHandleRadius = handleRadius / viewport.currentScale;
    final double worldSegmentTapTolerance =
        _segmentTapTolerance / viewport.currentScale;

    if (isLinkVertexesMode) {
      _handleLinkVertexesTap(worldPosition);
      return;
    }

    if (isSplitShapeMode) {
      _handleSplitShapeTap(worldPosition);
      return;
    }

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
              viewport.clampPoint(worldPosition, canvasRect),
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
          selectedIndices = List<int>.from(selectedIndices)
            ..remove(tappedShapeIndex);
        } else {
          if (selectedIndices.length < 2) {
            selectedIndices = List<int>.from(selectedIndices)
              ..add(tappedShapeIndex);
          } else {
            selectedIndices = [...selectedIndices.skip(1), tappedShapeIndex];
          }
        }
      } else {
        selectedIndices = <int>[tappedShapeIndex];
      }
    } else {
      selectedIndices = <int>[];
    }
    notifyListeners();
  }

  void handleScaleStart(ScaleStartDetails details) {
    final Offset localFocalPoint = details.localFocalPoint;

    viewport.prepareScaleStart(localFocalPoint);

    draggingShapeIndex = null;
    draggingPointIndex = null;
    _isDraggingWholeShape = false;
    _draggedPointInitialPosition = null;
    _dragStartWorldPoint = null;
    _draggedShapesInitialPoints = null;
    _draggedLinkedVertices = <VertexRef>{};

    _tapPointerCount = details.pointerCount;
    if (_tapPointerCount == 2) {
      _twoFingerGestureStartTime = DateTime.now();
    }

    if (isEditVerticesMode &&
        selectedIndices.length == 1 &&
        details.pointerCount == 1) {
      final Offset worldPosition = viewport.screenToWorld(localFocalPoint);
      final double worldHandleRadius = handleRadius / viewport.currentScale;

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
          _draggedLinkedVertices = constraints.linkedGroup(
            VertexRef(shapeIndex, i),
          )..remove(VertexRef(shapeIndex, i));
          _draggedShapesInitialPoints = <int, List<Offset>>{
            shapeIndex: List<Offset>.from(shape.points),
            for (final VertexRef v in _draggedLinkedVertices)
              v.shapeIndex: List<Offset>.from(allShapes[v.shapeIndex].points),
          };
          notifyListeners();
          return;
        }
      }
    }

    if (!isLinkMode &&
        details.pointerCount == 1 &&
        selectedIndices.isNotEmpty) {
      final Offset worldPosition = viewport.screenToWorld(localFocalPoint);
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
          _draggedLinkedVertices = _verticesLinkedToShapes(selectedIndices);
          for (final VertexRef v in _draggedLinkedVertices) {
            _draggedShapesInitialPoints!.putIfAbsent(
              v.shapeIndex,
              () => List<Offset>.from(allShapes[v.shapeIndex].points),
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
      final Offset currentWorldFocalPoint = viewport.screenToWorld(
        localFocalPoint,
      );
      final Offset deltaWorld = currentWorldFocalPoint - _dragStartWorldPoint!;

      final List<ShapeData> tempAllShapes = List<ShapeData>.from(allShapes);
      for (final MapEntry<int, List<Offset>> entry
          in _draggedShapesInitialPoints!.entries) {
        final int shapeIndex = entry.key;
        final bool isSelected = selectedIndices.contains(shapeIndex);
        final List<Offset> updatedPoints = <Offset>[
          for (int i = 0; i < entry.value.length; i++)
            isSelected ||
                    _draggedLinkedVertices.contains(VertexRef(shapeIndex, i))
                ? viewport.clampPoint(entry.value[i] + deltaWorld, canvasRect)
                : entry.value[i],
        ];
        tempAllShapes[shapeIndex] = tempAllShapes[shapeIndex].copyWith(
          points: updatedPoints,
        );
      }
      allShapes = tempAllShapes;
    } else if (draggingShapeIndex != null &&
        draggingPointIndex != null &&
        details.pointerCount == 1) {
      selectedVertexIndex = draggingPointIndex;
      final Offset currentWorldFocalPoint = viewport.screenToWorld(
        localFocalPoint,
      );
      final Offset deltaWorld = currentWorldFocalPoint - _dragStartWorldPoint!;

      final Offset newPosition = viewport.clampPoint(
        _draggedPointInitialPosition! + deltaWorld,
        canvasRect,
      );

      final List<ShapeData> tempAllShapes = List<ShapeData>.from(allShapes);
      for (final VertexRef v in <VertexRef>[
        VertexRef(draggingShapeIndex!, draggingPointIndex!),
        ..._draggedLinkedVertices,
      ]) {
        final List<Offset> updatedPoints = List<Offset>.from(
          tempAllShapes[v.shapeIndex].points,
        );
        updatedPoints[v.vertexIndex] = newPosition;
        tempAllShapes[v.shapeIndex] = tempAllShapes[v.shapeIndex].copyWith(
          points: updatedPoints,
        );
      }
      allShapes = tempAllShapes;
    } else {
      viewport.applyScaleUpdate(details);
    }
    notifyListeners();
  }

  void handleScaleEnd(ScaleEndDetails details) {
    if (_isDraggingWholeShape && _draggedShapesInitialPoints != null) {
      _commitMultiShapeMove();
    } else if (draggingShapeIndex != null &&
        draggingPointIndex != null &&
        _draggedPointInitialPosition != null &&
        _draggedLinkedVertices.isNotEmpty) {
      _commitMultiShapeMove();
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
    } else {
      viewport.finishScale();
    }

    draggingShapeIndex = null;
    draggingPointIndex = null;
    _isDraggingWholeShape = false;
    _draggedPointInitialPosition = null;
    _dragStartWorldPoint = null;
    _draggedShapesInitialPoints = null;
    _draggedLinkedVertices = <VertexRef>{};

    if (_tapPointerCount == 2 && _twoFingerGestureStartTime != null) {
      final duration = DateTime.now().difference(_twoFingerGestureStartTime!);
      if (duration.inMilliseconds < kTwoFingerGestureMaxMs) {
        _handleTwoFingerTap();
      }
    }
    _twoFingerGestureStartTime = null;
    _tapPointerCount = 0;

    notifyListeners();
  }

  /// Vertices of shapes outside [shapeIndices] linked to any of their vertices.
  Set<VertexRef> _verticesLinkedToShapes(List<int> shapeIndices) {
    final Set<VertexRef> result = <VertexRef>{};
    for (final int shapeIndex in shapeIndices) {
      for (int i = 0; i < allShapes[shapeIndex].points.length; i++) {
        final VertexRef v = VertexRef(shapeIndex, i);
        if (!constraints.isLinked(v)) continue;
        result.addAll(
          constraints
              .linkedGroup(v)
              .where((m) => !shapeIndices.contains(m.shapeIndex)),
        );
      }
    }
    return result;
  }

  /// Commits a drag that touched the shapes in [_draggedShapesInitialPoints]
  /// as a single undoable [MoveShapeCommand].
  void _commitMultiShapeMove() {
    final Map<int, List<Offset>> initialPoints = _draggedShapesInitialPoints!;
    final Map<int, List<Offset>> finalPoints = {
      for (final int shapeIndex in initialPoints.keys)
        shapeIndex: List<Offset>.from(allShapes[shapeIndex].points),
    };

    final tempShapes = List<ShapeData>.from(allShapes);
    for (final MapEntry<int, List<Offset>> entry in initialPoints.entries) {
      tempShapes[entry.key] = tempShapes[entry.key].copyWith(
        points: entry.value,
      );
    }
    allShapes = tempShapes;

    executeCommand(MoveShapeCommand(this, initialPoints, finalPoints));
  }

  void _handleTwoFingerTap() {
    final now = DateTime.now();
    if (_lastTwoFingerTapTime != null &&
        now.difference(_lastTwoFingerTapTime!).inMilliseconds <
            kDoubleTwoFingerTapWindowMs) {
      if (commandHistory.canUndo) {
        undo();
      }
      _lastTwoFingerTapTime = null;
    } else {
      _lastTwoFingerTapTime = now;
    }
  }

  void updateZoomScale(double newScale, Size screenSize) {
    viewport.updateZoomScale(newScale, screenSize);
  }

  void resetZoomScale() {
    viewport.resetZoomScale();
  }

  void handlePointerSignal(PointerSignalEvent event) {
    viewport.handlePointerSignal(event);
  }

  void fitToScreen(BuildContext context) {
    final availableSize = Size(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    viewport.fitToScreen(canvasRect, availableSize);
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

  void toggleHueVisible() {
    isHueVisible = !isHueVisible;
    notifyListeners();
  }

  void onToggleSatVisible() {
    isSatVisible = !isSatVisible;
    notifyListeners();
  }

  void onToggleValueVisible() {
    isValueVisible = !isValueVisible;
    notifyListeners();
  }

  void applyClamp(
    int startH,
    int endH,
    int startS,
    int endS,
    int startV,
    int endV,
  ) {
    if (selectedIndices.isEmpty) return;
    constraints.applyClamp(
      shapeIndex: selectedIndices.first,
      startH: startH,
      endH: endH,
      startS: startS,
      endS: endS,
      startV: startV,
      endV: endV,
      controller: this,
    );
  }
}
