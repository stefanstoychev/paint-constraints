import 'package:flutter/material.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/controllers/project_manager.dart';
import 'package:frontend/models/canvas_project.dart';
import 'package:frontend/painters/canvas_painter.dart';
import 'package:frontend/widgets/canvas_grid.dart';
import 'package:frontend/widgets/controls/clamp_color_panel.dart';
import 'package:frontend/widgets/controls/editor_app_bar.dart';
import 'package:frontend/widgets/controls/relationship_panel.dart';
import 'package:provider/provider.dart';

import 'controls/onscreen_menu.dart';
import 'controls/zoom_controls.dart';

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
        onToggleShowRelationships: controller.toggleShowRelationships,
        showColorLabels: controller.showColorLabels,
        onSave: () => controller.saveCurrentProject(context, projectManager),
        onLoad: () => controller.loadProject(widget.project),
        onSolve: () => controller.solveRelationships(context),
        onUpdateSolverUrl: (url) => controller.solverUrl = url,
        projectName: widget.project.name,
        solverUrl: controller.solverUrl,
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Listener(
            onPointerSignal: controller.handlePointerSignal,
            child: GestureDetector(
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
                      painter: CanvasPainter(
                        shapes: controller.allShapes,
                        selectedIndices: controller.selectedIndices,
                        activeRelationships: controller.activeRelationships,
                        draggingShapeIndex: controller.draggingShapeIndex,
                        draggingPointIndex: controller.draggingPointIndex,
                        selectedVertexIndex: controller.selectedVertexIndex,
                        handleRadius: CanvasController.handleRadius,
                        isLinkMode: controller.isLinkMode,
                        isHueVisible: controller.isHueVisible,
                        isSatVisible: controller.isSatVisible,
                        isValueVisible: controller.isValueVisible,
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
          ),
          if (controller.isLinkMode && controller.selectedIndices.length == 2)
            RelationshipPanel(
              onRelationshipApplied: (relationship) =>
                  controller.applyRelationship(relationship, context),
              onClearRelationships: controller.clearSelectedRelationships,
              activeRelationships: controller.activeRelationships
                  .where(
                    (r) =>
                        r.sourceShapeIndex ==
                            controller.selectedIndices.first &&
                        r.targetShapeIndex == controller.selectedIndices.last,
                  )
                  .map((r) => r.relationship)
                  .toList(),
            ),
          if (controller.isClampMode && controller.selectedIndices.length == 1)
            Positioned(top: 20, right: 20, child: SizedBox(
                width: 300,
                height: 400,
                child: ClampColorPanel())),
          Positioned(bottom: 20, left: 20, child: ZoomControls()),
          Positioned(top: 20, left: 20, child: OnscreenMenu()),
        ],
      ),
    );
  }
}
