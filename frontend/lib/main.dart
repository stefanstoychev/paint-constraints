import 'package:flutter/material.dart';
import 'package:frontend/widgets/project/project_gallery.dart';
import 'package:provider/provider.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/controllers/project_manager.dart';

import 'controllers/color_range_model.dart';
import 'models/color_component.dart';

void main() => runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ProjectManager()),
          ChangeNotifierProvider(create: (context) => CanvasController()),
          ChangeNotifierProxyProvider<CanvasController, ColorRangeModel>(
            create: (context) => ColorRangeModel(),
            update: (context, controller, colorRangeModel) {
              if(controller.selectedIndices.isEmpty) {
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
          )
        ],
        child: const MaterialApp(
          home: ProjectGallery(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
