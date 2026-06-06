import 'package:flutter/material.dart';
import 'package:frontend/widgets/project/project_gallery.dart';
import 'package:provider/provider.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/controllers/project_manager.dart';
import 'package:frontend/services/pwa_update_service.dart';
import 'package:frontend/widgets/update_prompt.dart';

import 'controllers/color_range_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pwaUpdateNotifier = await initPwaUpdateService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProjectManager()),
        ChangeNotifierProvider(create: (context) => CanvasController()),
        ChangeNotifierProvider(create: (_) => pwaUpdateNotifier),
        ChangeNotifierProxyProvider<CanvasController, ColorRangeModel>(
          create: (context) => ColorRangeModel(),
          update: (context, controller, colorRangeModel) {
            if (controller.selectedIndices.isEmpty) {
              return colorRangeModel!;
            }

            var index = controller.selectedIndices.first;

            controller.activeShapeColorConstraint
                .where((x) => x.sourceShapeIndex == index)
                .forEach((element) {
                  final minValue = element.min as double?;
                  final maxValue = element.max as double?;

                  if (minValue == null || maxValue == null) return;

                  colorRangeModel?.setRange(
                    element.component,
                    minValue,
                    maxValue,
                    notify: false,
                  );
                });

            return colorRangeModel!;
          },
        ),
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
