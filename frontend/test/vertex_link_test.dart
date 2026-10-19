import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/commands/vertex_commands.dart';
import 'package:frontend/commands/vertex_link_commands.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/models/canvas_data.dart';
import 'package:frontend/models/canvas_project.dart';
import 'package:frontend/models/point_constraint_models.dart';
import 'package:frontend/models/shape_data.dart';

ShapeData _square(double x, double y) => ShapeData(
  points: [
    Offset(x, y),
    Offset(x + 50, y),
    Offset(x + 50, y + 50),
    Offset(x, y + 50),
  ],
  hsv: const HSVColor.fromAHSV(1, 0, 0.5, 0.5),
);

CanvasController _controllerWithSquares(int count) {
  final controller = CanvasController();
  controller.allShapes = [
    for (int i = 0; i < count; i++) _square(100.0 * i + 50, 50),
  ];
  return controller;
}

void main() {
  test('VertexLink equality is unordered', () {
    const a = VertexRef(0, 1);
    const b = VertexRef(1, 2);
    expect(const VertexLink(a, b), const VertexLink(b, a));
    expect(const VertexLink(a, b).hashCode, const VertexLink(b, a).hashCode);
  });

  test('linkedGroup follows chains', () {
    final controller = _controllerWithSquares(3);
    controller.constraints.activeVertexLinks = [
      const VertexLink(VertexRef(0, 1), VertexRef(1, 0)),
      const VertexLink(VertexRef(1, 0), VertexRef(2, 3)),
    ];
    expect(controller.constraints.linkedGroup(const VertexRef(2, 3)), {
      const VertexRef(0, 1),
      const VertexRef(1, 0),
      const VertexRef(2, 3),
    });
    expect(controller.constraints.linkedGroup(const VertexRef(0, 0)), {
      const VertexRef(0, 0),
    });
  });

  test('AddVertexLinkCommand snaps b onto a, undo/redo restores', () {
    final controller = _controllerWithSquares(2);
    final Offset target = controller.allShapes[0].points[1];
    final Offset original = controller.allShapes[1].points[0];

    controller.executeCommand(
      AddVertexLinkCommand(
        controller,
        const VertexRef(0, 1),
        const VertexRef(1, 0),
      ),
    );
    expect(controller.allShapes[1].points[0], target);
    expect(controller.constraints.activeVertexLinks, hasLength(1));

    controller.undo();
    expect(controller.allShapes[1].points[0], original);
    expect(controller.constraints.activeVertexLinks, isEmpty);

    controller.redo();
    expect(controller.allShapes[1].points[0], target);
    expect(controller.constraints.activeVertexLinks, hasLength(1));
  });

  test('linking snaps the whole existing group of b', () {
    final controller = _controllerWithSquares(3);
    controller.executeCommand(
      AddVertexLinkCommand(
        controller,
        const VertexRef(1, 0),
        const VertexRef(2, 0),
      ),
    );
    controller.executeCommand(
      AddVertexLinkCommand(
        controller,
        const VertexRef(0, 2),
        const VertexRef(1, 0),
      ),
    );
    final Offset target = controller.allShapes[0].points[2];
    expect(controller.allShapes[1].points[0], target);
    expect(controller.allShapes[2].points[0], target);
  });

  test('add/delete vertex keeps link indices in sync', () {
    final controller = _controllerWithSquares(2);
    controller.constraints.activeVertexLinks = [
      const VertexLink(VertexRef(0, 2), VertexRef(1, 0)),
    ];

    controller.executeCommand(
      AddVertexCommand(controller, 0, 1, const Offset(75, 40)),
    );
    expect(
      controller.constraints.activeVertexLinks.single,
      const VertexLink(VertexRef(0, 3), VertexRef(1, 0)),
    );

    controller.undo();
    expect(
      controller.constraints.activeVertexLinks.single,
      const VertexLink(VertexRef(0, 2), VertexRef(1, 0)),
    );

    // Deleting a vertex before the linked one shifts it down.
    controller.executeCommand(
      DeleteVertexCommand(controller, 0, 0, controller.allShapes[0].points[0]),
    );
    expect(
      controller.constraints.activeVertexLinks.single,
      const VertexLink(VertexRef(0, 1), VertexRef(1, 0)),
    );
    controller.undo();

    // Deleting the linked vertex drops the link; undo restores it.
    controller.executeCommand(
      DeleteVertexCommand(controller, 0, 2, controller.allShapes[0].points[2]),
    );
    expect(controller.constraints.activeVertexLinks, isEmpty);
    controller.undo();
    expect(
      controller.constraints.activeVertexLinks.single,
      const VertexLink(VertexRef(0, 2), VertexRef(1, 0)),
    );
  });

  test('RemoveVertexLinksCommand removes and restores links', () {
    final controller = _controllerWithSquares(3);
    const links = [
      VertexLink(VertexRef(0, 1), VertexRef(1, 0)),
      VertexLink(VertexRef(1, 0), VertexRef(2, 3)),
    ];
    controller.constraints.activeVertexLinks = List.of(links);

    controller.executeCommand(RemoveVertexLinksCommand(controller, links));
    expect(controller.constraints.activeVertexLinks, isEmpty);
    controller.undo();
    expect(controller.constraints.activeVertexLinks.toSet(), links.toSet());
  });

  test('vertex links survive a save/load JSON round trip', () {
    final project = CanvasProject(
      id: 'p',
      name: 'p',
      canvasRect: const Rect.fromLTWH(0, 0, 500, 500),
      data: CanvasData(
        shapes: [_square(0, 0), _square(100, 0)],
        relationships: [],
        constraints: {},
        vertexLinks: const [VertexLink(VertexRef(0, 1), VertexRef(1, 0))],
      ),
      lastModified: DateTime(2026),
    );
    final decoded = CanvasProject.fromJson(
      jsonDecode(jsonEncode(project.toJson())) as Map<String, dynamic>,
    );
    expect(decoded.data.vertexLinks, project.data.vertexLinks);
  });

  test('old project JSON without vertexLinks still loads', () {
    final data = CanvasData.fromJson({
      'shapes': <dynamic>[],
      'relationships': <dynamic>[],
      'constraints': <dynamic>[],
    });
    expect(data.vertexLinks, isEmpty);
  });

  void drag(CanvasController controller, Offset from, Offset to) {
    controller.handleScaleStart(
      ScaleStartDetails(localFocalPoint: from, pointerCount: 1),
    );
    controller.handleScaleUpdate(
      ScaleUpdateDetails(localFocalPoint: to, pointerCount: 1),
    );
    controller.handleScaleEnd(ScaleEndDetails());
  }

  test('dragging a linked vertex moves its group in one undo step', () {
    final controller = _controllerWithSquares(2);
    controller.executeCommand(
      AddVertexLinkCommand(
        controller,
        const VertexRef(0, 1),
        const VertexRef(1, 0),
      ),
    );
    final Offset start = controller.allShapes[0].points[1];

    controller.toggleEditVerticesMode();
    controller.selectedIndices = [0];
    drag(controller, start, start + const Offset(10, 20));

    final Offset moved = start + const Offset(10, 20);
    expect(controller.allShapes[0].points[1], moved);
    expect(controller.allShapes[1].points[0], moved);

    controller.undo();
    expect(controller.allShapes[0].points[1], start);
    expect(controller.allShapes[1].points[0], start);
  });

  test('dragging a whole shape drags linked vertices of other shapes', () {
    final controller = _controllerWithSquares(2);
    controller.executeCommand(
      AddVertexLinkCommand(
        controller,
        const VertexRef(0, 1),
        const VertexRef(1, 0),
      ),
    );
    final List<Offset> otherBefore = List.of(controller.allShapes[1].points);

    controller.selectedIndices = [0];
    drag(controller, const Offset(75, 75), const Offset(80, 85));

    expect(
      controller.allShapes[1].points[0],
      otherBefore[0] + const Offset(5, 10),
    );
    expect(controller.allShapes[1].points.sublist(1), otherBefore.sublist(1));
    expect(
      controller.allShapes[1].points[0],
      controller.allShapes[0].points[1],
    );

    controller.undo();
    expect(controller.allShapes[1].points, otherBefore);
  });
}
