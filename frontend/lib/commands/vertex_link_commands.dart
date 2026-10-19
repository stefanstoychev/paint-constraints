import 'dart:ui';

import '../controllers/canvas_controller.dart';
import '../models/point_constraint_models.dart';
import '../models/shape_data.dart';
import 'canvas_command.dart';

/// Links two vertices and snaps [b]'s whole linked group onto [a].
class AddVertexLinkCommand implements CanvasCommand {
  final CanvasController controller;
  final VertexLink link;
  final Map<int, List<Offset>> initialPoints = {};
  final Map<int, List<Offset>> finalPoints = {};

  AddVertexLinkCommand(this.controller, VertexRef a, VertexRef b)
    : link = VertexLink(a, b) {
    final shapes = controller.allShapes;
    final Offset target = shapes[a.shapeIndex].points[a.vertexIndex];
    for (final VertexRef v in controller.constraints.linkedGroup(b)) {
      initialPoints.putIfAbsent(
        v.shapeIndex,
        () => List<Offset>.from(shapes[v.shapeIndex].points),
      );
      finalPoints.putIfAbsent(
        v.shapeIndex,
        () => List<Offset>.from(shapes[v.shapeIndex].points),
      )[v.vertexIndex] = target;
    }
  }

  @override
  void execute() {
    controller.constraints.activeVertexLinks = [
      ...controller.constraints.activeVertexLinks,
      link,
    ];
    _applyPoints(controller, finalPoints);
  }

  @override
  void undo() {
    controller.constraints.activeVertexLinks = controller
        .constraints
        .activeVertexLinks
        .where((l) => l != link)
        .toList();
    _applyPoints(controller, initialPoints);
  }
}

/// Removes links; vertices stay where they are.
class RemoveVertexLinksCommand implements CanvasCommand {
  final CanvasController controller;
  final List<VertexLink> links;

  RemoveVertexLinksCommand(this.controller, this.links);

  @override
  void execute() {
    controller.constraints.activeVertexLinks = controller
        .constraints
        .activeVertexLinks
        .where((l) => !links.contains(l))
        .toList();
  }

  @override
  void undo() {
    controller.constraints.activeVertexLinks = [
      ...controller.constraints.activeVertexLinks,
      ...links,
    ];
  }
}

void _applyPoints(CanvasController controller, Map<int, List<Offset>> points) {
  final shapes = List<ShapeData>.from(controller.allShapes);
  for (final entry in points.entries) {
    if (entry.key < shapes.length) {
      shapes[entry.key] = shapes[entry.key].copyWith(points: entry.value);
    }
  }
  controller.allShapes = shapes;
}
