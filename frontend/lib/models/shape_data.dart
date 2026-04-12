import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/color_constraints.dart';

enum ColorComponent { hue, saturation, value }

/// Represents a relationship between two shapes
class ShapeRelationship {
  final int sourceShapeIndex;
  final int targetShapeIndex;
  final ColorRelationship relationship;

  const ShapeRelationship(this.sourceShapeIndex, this.targetShapeIndex, this.relationship);

  bool hasSameType(ShapeRelationship other) {
    return other.sourceShapeIndex == sourceShapeIndex &&
        other.targetShapeIndex == targetShapeIndex &&
        other.relationship.component == relationship.component;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShapeRelationship &&
        other.sourceShapeIndex == sourceShapeIndex &&
        other.targetShapeIndex == targetShapeIndex &&
        other.relationship == relationship;
  }

  @override
  int get hashCode => Object.hash(sourceShapeIndex, targetShapeIndex, relationship);
}

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

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'hue': hsv.hue,
      'saturation': hsv.saturation,
      'value': hsv.value,
      'alpha': hsv.alpha,
    };
  }

  /// Create from JSON
  factory ShapeData.fromJson(Map<String, dynamic> json) {
    final pointsList = (json['points'] as List)
        .map((p) => Offset(p['dx'] as double, p['dy'] as double))
        .toList();
    final hsv = HSVColor.fromAHSV(
      json['alpha'] as double,
      json['hue'] as double,
      json['saturation'] as double,
      json['value'] as double,
    );
    return ShapeData(points: pointsList, hsv: hsv);
  }
}
