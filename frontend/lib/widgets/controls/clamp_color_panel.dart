import 'package:flutter/material.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/models/color_component.dart';
import 'package:provider/provider.dart';

class ClampColorPanel extends StatefulWidget {
  const ClampColorPanel({super.key});

  @override
  State<ClampColorPanel> createState() => _ClampColorPanelState();
}

class _ClampColorPanelState extends State<ClampColorPanel> {
  RangeValues _currentRangeValuesH = const RangeValues(0, 360);
  RangeValues _currentRangeValuesV = const RangeValues(0, 100);
  RangeValues _currentRangeValuesS = const RangeValues(0, 100);

  @override
  void initState() {
    var controller = context.read<CanvasController>();
    var index = controller.selectedIndices.first;

    controller.activeShapeColorConstraint
        .where((x) => x.sourceShapeIndex == index)
        .forEach((element) {
      var range = RangeValues(element.min as double, element.max as double);
      switch(element.component){
        case ColorComponent.hue:
          _currentRangeValuesH = range;
          break;
        case ColorComponent.value:
          _currentRangeValuesV = range;
          break;
        case ColorComponent.saturation:
          _currentRangeValuesS = range;
          break;
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
      child: Card(
        elevation: 8,
        color: Colors.black.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              RangeSlider(
                values: _currentRangeValuesH,
                max: 360,
                divisions: 36,
                labels: RangeLabels(
                  _currentRangeValuesH.start.round().toString(),
                  _currentRangeValuesH.end.round().toString(),
                ),
                onChanged: (RangeValues values) {
                  setState(() {
                    _currentRangeValuesH = values;
                  });
                },
              ),
              RangeSlider(
                values: _currentRangeValuesV,
                max: 100,
                divisions: 10,
                labels: RangeLabels(
                  _currentRangeValuesV.start.round().toString(),
                  _currentRangeValuesV.end.round().toString(),
                ),
                onChanged: (RangeValues values) {
                  setState(() {
                    _currentRangeValuesV = values;
                  });
                },
              ),
              RangeSlider(
                values: _currentRangeValuesS,
                max: 100,
                divisions: 10,
                labels: RangeLabels(
                  _currentRangeValuesS.start.round().toString(),
                  _currentRangeValuesS.end.round().toString(),
                ),
                onChanged: (RangeValues values) {
                  setState(() {
                    _currentRangeValuesS = values;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () => context.read<CanvasController>().applyClamp(
                  _currentRangeValuesH.start.round(),
                  _currentRangeValuesH.end.round(),
                  _currentRangeValuesS.start.round(),
                  _currentRangeValuesS.end.round(),
                  _currentRangeValuesV.start.round(),
                  _currentRangeValuesV.end.round(),
                ),
                child: Text("apply"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
