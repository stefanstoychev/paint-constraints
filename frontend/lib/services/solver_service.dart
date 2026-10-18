import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    if (_url != null) {
      return _url!;
    }

    // Check if a build-time API_URL is supplied via --dart-define
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    return 'https://paint-constraints-api.devfriday.top';
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
                'color': r.relationship.component.toApiString(), // Refactored usage
                'operation': r.relationship.operator.toApiString(), // Refactored usage
                'indexes': [r.sourceShapeIndex, r.targetShapeIndex],
              },
            )
            .toList(),
        'constraints': activeShapeColorConstraint
            .map(
              (r) => {
                'component': r.component.toApiString(), // Refactored usage
                'index': r.sourceShapeIndex,
                'min': r.min,
                'max': r.max,
              },
            )
            .toList(),
      };

      final response = await http
          .post(
            Uri.parse('${getUrl()}/solve'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
          return data
              .map((item) => SolveResult.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint('Solver parse error: $e');
          return null;
        }
      } else {
        debugPrint('Solver error: ${response.statusCode} ${response.body}');
        return null;
      }
    } on TimeoutException {
      debugPrint('Solver request timed out');
      return null;
    } catch (e) {
      debugPrint('Solver exception: $e');
      return null;
    }
  }

  // Private methods are removed and replaced by extensions below.
}

extension ColorComponentMapping on ColorComponent {
  String toApiString() {
    switch (this) {
      case ColorComponent.hue:
        return 'H';
      case ColorComponent.saturation:
        return 'S';
      case ColorComponent.value:
          return 'V';
    }
  }
}

extension ComparisonOperatorMapping on ComparisonOperator {
  String toApiString() {
    switch (this) {
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
