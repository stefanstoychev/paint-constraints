import 'package:flutter/material.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/controllers/project_manager.dart';
import 'package:frontend/services/pwa_update_service.dart';
import 'package:frontend/services/solver_service.dart';
import 'package:frontend/widgets/project/project_gallery.dart';
import 'package:frontend/widgets/update_prompt.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pwaUpdateNotifier = await initPwaUpdateService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProjectManager()),
        ChangeNotifierProvider(create: (context) => SolverService()),
        ChangeNotifierProxyProvider<SolverService, CanvasController>(
          create: (context) => CanvasController(),
          update: (context, solver, canvasController) {
            canvasController?.setSolver(solver);
            return canvasController!;
          },
        ),
        ChangeNotifierProvider(create: (_) => pwaUpdateNotifier),
      ],
      child: const PaintConstraintsApp(),
    ),
  );
}

class PaintConstraintsApp extends StatelessWidget {
  const PaintConstraintsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: UpdatePrompt(child: ProjectGallery()),
      debugShowCheckedModeBanner: false,
    );
  }
}
