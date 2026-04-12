import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'color_component.dart';
import 'color_relationship.dart';
import 'comparison_operator.dart';

/// Represents a relationship between two shapes
class ShapeRelationship {
  final int sourceShapeIndex;
  final int targetShapeIndex;
  final ColorRelationship relationship;

  const ShapeRelationship(
    this.sourceShapeIndex,
    this.targetShapeIndex,
    this.relationship,
  );

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
  int get hashCode =>
      Object.hash(sourceShapeIndex, targetShapeIndex, relationship);

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'sourceShapeIndex': sourceShapeIndex,
      'targetShapeIndex': targetShapeIndex,
      'component': relationship.component.name,
      'operator': relationship.operator.name,
      'offset': relationship.offset,
    };
  }

  /// Create from JSON
  factory ShapeRelationship.fromJson(Map<String, dynamic> json) {
    final component = ColorComponent.values.firstWhere(
      (e) => e.name == json['component'],
    );
    final operator = ComparisonOperator.values.firstWhere(
      (e) => e.name == json['operator'],
    );
    final relationship = ColorRelationship(
      component,
      operator,
      json['offset'] as double,
    );
    return ShapeRelationship(
      json['sourceShapeIndex'] as int,
      json['targetShapeIndex'] as int,
      relationship,
    );
  }
}

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

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'hue': hsv.hue,
      'saturation': hsv.saturation,
      'value': hsv.value,
      'alpha': hsv.alpha,
      'zIndex': zIndex,
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
    return ShapeData(
      points: pointsList,
      hsv: hsv,
      zIndex: json['zIndex'] is int ? json['zIndex'] as int : 0,
    );
  }
}
