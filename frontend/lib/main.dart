import 'package:flutter/material.dart';
import 'package:frontend/widgets/gallery_view.dart';
import 'package:provider/provider.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/controllers/project_manager.dart';

void main() => runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ProjectManager()),
          ChangeNotifierProvider(create: (context) => CanvasController()),
        ],
        child: const MaterialApp(
          home: GalleryView(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
