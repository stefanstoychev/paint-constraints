import 'package:flutter/material.dart';
import 'package:frontend/widgets/color_range_wheel.dart';
import 'package:frontend/widgets/project/project_gallery.dart';
import 'package:provider/provider.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/controllers/project_manager.dart';

import 'controllers/color_range_model.dart';
import 'models/color_constraint_models.dart';

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
                switch(element.component){
                  case ColorComponent.hue:
                    colorRangeModel?.setHue(element.min as double, element.max as double);
                    break;
                  case ColorComponent.value:
                    colorRangeModel?.setValue(element.min as double, element.max as double);
                    break;
                  case ColorComponent.saturation:
                    colorRangeModel?.setSaturation(element.min as double, element.max as double);
                    break;
                }
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
