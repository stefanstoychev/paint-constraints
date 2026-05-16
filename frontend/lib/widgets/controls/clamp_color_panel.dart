import 'package:flutter/material.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:provider/provider.dart';

import '../../controllers/color_range_model.dart';
import '../color_range_wheel.dart';

class ClampColorPanel extends StatelessWidget {
  const ClampColorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    ColorRangeModel colorRangeModel = context.watch<ColorRangeModel>();
    return Card(
      elevation: 8,
      color: Colors.black.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            DartPadPreviewScreen(),
            Row(
              children: [
                Text("S", style: TextStyle(color: Colors.grey)),
                Flexible(
                  child: RangeSlider(
                    values: RangeValues(colorRangeModel.saturationStart, colorRangeModel.saturationEnd),
                    max: 100,
                    divisions: 10,
                    labels: RangeLabels(
                      colorRangeModel.saturationStart.toString(),
                      colorRangeModel.saturationEnd.toString(),
                    ),
                    onChanged: (RangeValues values) {
                      colorRangeModel.updateSaturation(values.start, values.end);
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text("V", style: TextStyle(color: Colors.grey)),
                Flexible(
                  child: RangeSlider(
                    values: RangeValues(colorRangeModel.valueStart, colorRangeModel.valueEnd),
                    max: 100,
                    divisions: 10,
                    labels: RangeLabels(
                      colorRangeModel.valueStart.toString(),
                      colorRangeModel.valueEnd.toString(),
                    ),
                    onChanged: (RangeValues values) {
                        colorRangeModel.updateValue(values.start, values.end);
                    },
                  ),
                ),
              ],
            ),

            ElevatedButton(
              onPressed: () {
                var colorRange = context.read<ColorRangeModel>();
                context.read<CanvasController>().applyClamp(
                  colorRange.hueStart.round(),
                  colorRange.hueEnd.round(),
                  colorRange.saturationStart.round(),
                  colorRange.saturationEnd.round(),
                  colorRange.valueStart.round(),
                  colorRange.valueEnd.round(),
                );
              },
              child: Text("apply"),
            ),
          ],
        ),
      ),
    );
  }
}
