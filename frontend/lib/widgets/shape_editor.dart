import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/painters/relationship_painter.dart';
import 'package:frontend/widgets/editor_app_bar.dart';
import 'package:frontend/widgets/relationship_panel.dart';
import 'package:frontend/widgets/zoom_controls.dart';
import 'package:frontend/widgets/canvas_grid.dart';
import 'package:frontend/controllers/project_manager.dart';
import 'package:frontend/models/canvas_project.dart';

class ShapeEditor extends StatefulWidget {
  final CanvasProject project;
  const ShapeEditor({super.key, required this.project});

  @override
  State<ShapeEditor> createState() => _ShapeEditorState();
}

class _ShapeEditorState extends State<ShapeEditor> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CanvasController>().loadProject(widget.project);
    });
  }

  @override
  Widget build(BuildContext context) {
    final CanvasController controller = context.watch<CanvasController>();
    final ProjectManager projectManager = context.read<ProjectManager>();

    final bool showAddPointIndicators =
        controller.isEditVerticesMode && controller.selectedIndices.length == 1;

    return Scaffold(
      appBar: EditorAppBar(
        isEditVerticesMode: controller.isEditVerticesMode,
        isLinkMode: controller.isLinkMode,
        showRelationships: controller.showRelationships,
        hasSelectedVertex: controller.selectedVertexIndex != null,
        hasSelectedShapes: controller.selectedIndices.isNotEmpty,
        onToggleLinkMode: controller.toggleLinkMode,
        onToggleEditVerticesMode: controller.toggleEditVerticesMode,
        onDeleteVertex: controller.deleteSelectedVertex,
        onToggleShowRelationships: controller.toggleShowRelationships,
        showColorLabels: controller.showColorLabels,
        onToggleShowColorLabels: controller.toggleShowColorLabels,
        onSendToFront: controller.sendSelectedShapesToFront,
        onPushToBack: controller.pushSelectedShapesToBack,
        canUndo: controller.commandHistory.canUndo,
        canRedo: controller.commandHistory.canRedo,
        onUndo: controller.undo,
        onRedo: controller.redo,
        onAddShape: controller.addShape,
        onSave: () => controller.saveCurrentProject(context, projectManager),
        onLoad: () => controller.loadProject(widget.project), // Revert to saved
        onSolve: () => controller.solveRelationships(context),
        projectName: widget.project.name,
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          GestureDetector(
            onTapDown: controller.handleTapDown,
            onScaleStart: controller.handleScaleStart,
            onScaleUpdate: controller.handleScaleUpdate,
            onScaleEnd: controller.handleScaleEnd,
            child: Container(
              color: Colors.grey.shade900,
              child: Stack(
                children: [
                  CanvasGrid(
                    scale: controller.currentScale,
                    offset: controller.currentOffset,
                    canvasRect: widget.project.canvasRect,
                  ),
                  CustomPaint(
                    size: Size.infinite,
                    painter: RelationshipPainter(
                      shapes: controller.allShapes,
                      selectedIndices: controller.selectedIndices,
                      activeRelationships: controller.activeRelationships,
                      draggingShapeIndex: controller.draggingShapeIndex,
                      draggingPointIndex: controller.draggingPointIndex,
                      selectedVertexIndex: controller.selectedVertexIndex,
                      handleRadius: CanvasController.handleRadius,
                      isLinkMode: controller.isLinkMode,
                      isEditVerticesMode: controller.isEditVerticesMode,
                      showAddPointIndicators: showAddPointIndicators,
                      showRelationships: controller.showRelationships,
                      showColorLabels: controller.showColorLabels,
                      scale: controller.currentScale,
                      offset: controller.currentOffset,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (controller.isLinkMode && controller.selectedIndices.length == 2)
            RelationshipPanel(
              colorConstraints: controller.colorConstraints,
              onRelationshipApplied: (relationship) =>
                  controller.applyRelationship(relationship, context),
            ),
          ZoomControls(
            currentScale: controller.currentScale,
            onZoomChanged: (scale) =>
                controller.updateZoomScale(scale, MediaQuery.of(context).size),
            onZoomReset: controller.resetZoomScale,
          ),
        ],
      ),
    );
  }
}
