import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class ColorRangeModel extends ChangeNotifier {
  double _hueStart = 0, _hueEnd = 60;

  double get hueStart => _hueStart;
  double get hueEnd => _hueEnd;

  void updateHue(double start, double end) {
    _hueStart = start;
    _hueEnd = end;
    notifyListeners();
  }
}

class DartPadPreviewScreen extends StatelessWidget {
  const DartPadPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Hue Wheel Controller'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<ColorRangeModel>(
        builder: (context, model, _) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  HueWheel(model: model),
                  const SizedBox(height: 40),
                  Text(
                    'Range: ${model.hueStart.toInt()}° - ${model.hueEnd.toInt()}°',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
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

class HueWheel extends StatefulWidget {
  final ColorRangeModel model;
  const HueWheel({super.key, required this.model});

  @override
  State<HueWheel> createState() => _HueWheelState();
}

class _HueWheelState extends State<HueWheel> {
  int? _draggingHandle;

  @override
  Widget build(BuildContext context) {
    const size = 280.0;
    return GestureDetector(
      onPanStart: (details) {
        final center = const Offset(size / 2, size / 2);
        final touch = details.localPosition - center;
        double angle = math.atan2(touch.dy, touch.dx) * 180 / math.pi;
        if (angle < 0) angle += 360;

        final startRad = widget.model.hueStart * math.pi / 180;
        final endRad = widget.model.hueEnd * math.pi / 180;
        final startPos = Offset(math.cos(startRad), math.sin(startRad)) * (size / 2);
        final endPos = Offset(math.cos(endRad), math.sin(endRad)) * (size / 2);

        final distToStart = (touch - startPos).distance;
        final distToEnd = (touch - endPos).distance;

        if (distToStart < 40) {
          _draggingHandle = 0;
        } else if (distToEnd < 40) {
          _draggingHandle = 1;
        }
      },
      onPanUpdate: (details) {
        if (_draggingHandle == null) return;
        final center = const Offset(size / 2, size / 2);
        final touch = details.localPosition - center;
        double angle = math.atan2(touch.dy, touch.dx) * 180 / math.pi;
        if (angle < 0) angle += 360;

        if (_draggingHandle == 0) {
          widget.model.updateHue(angle, widget.model.hueEnd);
        } else {
          widget.model.updateHue(widget.model.hueStart, angle);
        }
      },
      onPanEnd: (_) => _draggingHandle = null,
      child: CustomPaint(
        size: const Size(size, size),
        painter: HueWheelPainter(widget.model.hueStart, widget.model.hueEnd),
      ),
    );
  }
}

class HueWheelPainter extends CustomPainter {
  final double start;
  final double end;
  HueWheelPainter(this.start, this.end);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final bgPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 30..color = Colors.white10;
    canvas.drawCircle(center, radius - 15, bgPaint);

    final activePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 30;
    
    // Fix: Ensure startAngle < endAngle for the shader
    double s = start * math.pi / 180;
    double e = end * math.pi / 180;
    if (s >= e) e += 2 * math.pi;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 15), s, e - s, false, activePaint..shader = SweepGradient(
      colors: List.generate(360, (i) => HSVColor.fromAHSV(1.0, i.toDouble(), 0.8, 0.9).toColor()),
      startAngle: 0,
      endAngle: 2 * math.pi,
    ).createShader(rect));

    final handlePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = Colors.black.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 3;
    
    _drawHandle(canvas, center, radius - 15, start, handlePaint, strokePaint);
    _drawHandle(canvas, center, radius - 15, end, handlePaint, strokePaint);
  }

  void _drawHandle(Canvas canvas, Offset center, double radius, double angle, Paint fill, Paint stroke) {
    final rad = angle * math.pi / 180;
    final pos = Offset(center.dx + math.cos(rad) * radius, center.dy + math.sin(rad) * radius);
    canvas.drawCircle(pos, 14, fill);
    canvas.drawCircle(pos, 14, stroke);
  }

  @override
  bool shouldRepaint(covariant HueWheelPainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.end != end;
  }
}
