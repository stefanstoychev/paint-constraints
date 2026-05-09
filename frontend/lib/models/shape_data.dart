import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ShapeData {
  final List<Offset> points;
  final HSVColor hsv;
  final int zIndex;

  const ShapeData({required this.points, required this.hsv, this.zIndex = 0});

  Color get color => hsv.toColor();

  ShapeData copyWith({List<Offset>? points, HSVColor? hsv, int? zIndex}) {
    return ShapeData(
      points: points ?? List<Offset>.from(this.points),
      hsv: hsv ?? this.hsv,
      zIndex: zIndex ?? this.zIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShapeData &&
        listEquals(points, other.points) &&
        hsv == other.hsv &&
        zIndex == other.zIndex;
  }

  @override
  int get hashCode => Object.hashAll(points) ^ hsv.hashCode ^ zIndex.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'hue': hsv.hue,
      'saturation': hsv.saturation,
      'value': hsv.value,
      'zIndex': zIndex,
    };
  }

  factory ShapeData.fromJson(Map<String, dynamic> json) {
    final pointsList = (json['points'] as List)
        .map((p) => Offset(p['dx'] as double, p['dy'] as double))
        .toList();
    final hsv = HSVColor.fromAHSV(
      1.0,
      json['hue'] as double,
      json['saturation'] as double,
      json['value'] as double,
    );
    return ShapeData(
      points: pointsList,
      hsv: hsv,
      zIndex: json['zIndex'] is int ? json['zIndex'] as int : 0,
    );
  }
}
