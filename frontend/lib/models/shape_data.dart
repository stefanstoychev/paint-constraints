import 'package:flutter/material.dart';

enum ColorComponent { hue, saturation, value }

class ShapeData {
  final List<Offset> points;
  final HSVColor hsv;

  const ShapeData({required this.points, required this.hsv});

  Color get color => hsv.toColor();

  ShapeData copyWith({List<Offset>? points, HSVColor? hsv}) {
    return ShapeData(
      points: points ?? List<Offset>.from(this.points),
      hsv: hsv ?? this.hsv,
    );
  }
}
