import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/models/color_constraint_models.dart';
import 'package:http/http.dart' as http;

class SolverService extends ChangeNotifier {
  String? _url;

  void setUrl(String url) {
    if (url == _url) {
      return;
    }
    _url = url;
    notifyListeners();
  }

  String getUrl() {

    return _url ?? 'https://paint-constraints-api.devfriday.top';
  }

  Future<List<SolveResult>?> solve(
    List<ShapeRelationship> relationships,
    Set<ShapeColorConstraint> activeShapeColorConstraint,
  ) async {
    try {
      final requestBody = {
        'relationships': relationships
            .map(
              (r) => {
                'color': _mapComponent(r.relationship.component),
                'operation': _mapOperator(r.relationship.operator),
                'indexes': [r.sourceShapeIndex, r.targetShapeIndex],
              },
            )
            .toList(),
        'constraints': activeShapeColorConstraint
            .map(
              (r) => {
                'component': _mapComponent(r.component),
                'index': r.sourceShapeIndex,
                'min': r.min,
                'max': r.max,
              },
            )
            .toList(),
      };

      final response = await http.post(
        Uri.parse('$_url/solve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => SolveResult.fromJson(item)).toList();
      } else {
        debugPrint('Solver error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Solver exception: $e');
      return null;
    }
  }

  String _mapComponent(ColorComponent component) {
    switch (component) {
      case ColorComponent.hue:
        return 'H';
      case ColorComponent.saturation:
        return 'S';
      case ColorComponent.value:
        return 'V';
    }
  }

  String _mapOperator(ComparisonOperator operator) {
    switch (operator) {
      case ComparisonOperator.lt:
        return 'LT';
      case ComparisonOperator.e:
        return 'E';
    }
  }
}

class SolveResult {
  final int index;
  final double h;
  final double s;
  final double v;

  SolveResult({
    required this.index,
    required this.h,
    required this.s,
    required this.v,
  });

  factory SolveResult.fromJson(Map<String, dynamic> json) {
    return SolveResult(
      index: json['index'] as int,
      h: (json['h'] as num).toDouble(),
      s: (json['s'] as num).toDouble(),
      v: (json['v'] as num).toDouble(),
    );
  }
}
