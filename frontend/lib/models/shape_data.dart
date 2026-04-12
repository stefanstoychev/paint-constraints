import 'package:flutter/foundation.dart';
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShapeData &&
        listEquals(points, other.points) &&
        hsv == other.hsv;
  }

  @override
  int get hashCode => Object.hashAll(points) ^ hsv.hashCode;
}
