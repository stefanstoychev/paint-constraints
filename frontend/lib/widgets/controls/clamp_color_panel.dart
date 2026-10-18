import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:provider/provider.dart';

import '../../controllers/color_range_model.dart';
import '../color_range_wheel.dart';

class ClampColorPanel extends StatelessWidget {
  const ClampColorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final canvasController = context.read<CanvasController>();
    return ChangeNotifierProvider(
      create: (context) =>
          ColorRangeModel.fromCanvasController(canvasController),
      child: Builder(
        builder: (context) {
          final ColorRangeModel colorRangeModel = context
              .watch<ColorRangeModel>();
          final double midHue =
              (colorRangeModel.hueStart + colorRangeModel.hueEnd) / 2;
          final Color satStart =
              HSVColor.fromAHSV(1, midHue, 0, 0.75).toColor();
          final Color satEnd =
              HSVColor.fromAHSV(1, midHue, 1, 0.75).toColor();
          final Color valEnd = HSVColor.fromAHSV(1, midHue, 0.8, 1).toColor();

          return Card(
            elevation: 8,
            color: Colors.black.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  HueWheel(
                    onChangeEnd: () {
                      final colorRange = context.read<ColorRangeModel>();
                      context.read<CanvasController>().applyClamp(
                        colorRange.hueStart.round(),
                        colorRange.hueEnd.round(),
                        colorRange.saturationStart.round(),
                        colorRange.saturationEnd.round(),
                        colorRange.valueStart.round(),
                        colorRange.valueEnd.round(),
                      );
                    },
                  ),
                  Row(
                    children: [
                      const Text("S", style: TextStyle(color: Colors.grey)),
                      Flexible(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            rangeTrackShape: _GradientRangeTrackShape(
                              startColor: satStart,
                              endColor: satEnd,
                            ),
                          ),
                          child: RangeSlider(
                            values: RangeValues(
                              colorRangeModel.saturationStart,
                              colorRangeModel.saturationEnd,
                            ),
                            max: 100,
                            divisions: 10,
                            labels: RangeLabels(
                              colorRangeModel.saturationStart.toString(),
                              colorRangeModel.saturationEnd.toString(),
                            ),
                            onChanged: (RangeValues values) {
                              colorRangeModel.updateSaturation(
                                values.start,
                                values.end,
                              );
                            },
                            onChangeEnd: (RangeValues values) {
                              context.read<CanvasController>().applyClamp(
                                colorRangeModel.hueStart.round(),
                                colorRangeModel.hueEnd.round(),
                                values.start.round(),
                                values.end.round(),
                                colorRangeModel.valueStart.round(),
                                colorRangeModel.valueEnd.round(),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("V", style: TextStyle(color: Colors.grey)),
                      Flexible(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            rangeTrackShape: _GradientRangeTrackShape(
                              startColor: Colors.black,
                              endColor: valEnd,
                            ),
                          ),
                          child: RangeSlider(
                            values: RangeValues(
                              colorRangeModel.valueStart,
                              colorRangeModel.valueEnd,
                            ),
                            max: 100,
                            divisions: 10,
                            labels: RangeLabels(
                              colorRangeModel.valueStart.toString(),
                              colorRangeModel.valueEnd.toString(),
                            ),
                            onChanged: (RangeValues values) {
                              colorRangeModel.updateValue(
                                values.start,
                                values.end,
                              );
                            },
                            onChangeEnd: (RangeValues values) {
                              context.read<CanvasController>().applyClamp(
                                colorRangeModel.hueStart.round(),
                                colorRangeModel.hueEnd.round(),
                                colorRangeModel.saturationStart.round(),
                                colorRangeModel.saturationEnd.round(),
                                values.start.round(),
                                values.end.round(),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GradientRangeTrackShape extends RangeSliderTrackShape {
  final Color startColor;
  final Color endColor;

  const _GradientRangeTrackShape({
    required this.startColor,
    required this.endColor,
  });

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(offset.dx, trackTop, parentBox.size.width, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint paint = Paint()
      ..shader = ui.Gradient.linear(
        trackRect.centerLeft,
        trackRect.centerRight,
        [startColor, endColor],
      );

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, Radius.circular(trackRect.height / 2)),
      paint,
    );
  }
}
