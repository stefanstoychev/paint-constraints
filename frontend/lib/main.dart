import 'package:flutter/material.dart';
import 'package:frontend/widgets/shape_editor.dart';
import 'package:provider/provider.dart';
import 'package:frontend/controllers/canvas_controller.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (context) => CanvasController(),
    child: const MaterialApp(home: ShapeEditor(), debugShowCheckedModeBanner: false),
  ),
);
