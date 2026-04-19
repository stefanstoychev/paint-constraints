import 'package:flutter/material.dart';
import 'package:frontend/models/canvas_data.dart';

class CanvasProject {
  final String id;
  final String name;
  final Rect canvasRect;
  final CanvasData data;
  final DateTime lastModified;

  CanvasProject({
    required this.id,
    required this.name,
    required this.canvasRect,
    required this.data,
    required this.lastModified,
  });

  CanvasProject copyWith({
    String? name,
    Rect? canvasRect,
    CanvasData? data,
    DateTime? lastModified,
  }) {
    return CanvasProject(
      id: id,
      name: name ?? this.name,
      canvasRect: canvasRect ?? this.canvasRect,
      data: data ?? this.data,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'canvasRect': {
        'left': canvasRect.left,
        'top': canvasRect.top,
        'width': canvasRect.width,
        'height': canvasRect.height,
      },
      'data': {
        'shapes': data.shapes.map((s) => s.toJson()).toList(),
        'relationships': data.relationships.map((r) => r.toJson()).toList(),
      },
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory CanvasProject.fromJson(Map<String, dynamic> json) {
    final rectJson = json['canvasRect'] as Map<String, dynamic>;
    final dataJson = json['data'] as Map<String, dynamic>;

    return CanvasProject(
      id: json['id'],
      name: json['name'],
      canvasRect: Rect.fromLTWH(
        (rectJson['left'] as num).toDouble(),
        (rectJson['top'] as num).toDouble(),
        (rectJson['width'] as num).toDouble(),
        (rectJson['height'] as num).toDouble(),
      ),
      data: CanvasData.fromJson(dataJson),
      lastModified: DateTime.parse(json['lastModified']),
    );
  }
}
