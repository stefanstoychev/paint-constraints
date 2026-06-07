import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:frontend/models/shape_data.dart';

// Conditionally import web-specific implementation
// ignore: uri_does_not_exist
import 'image_export_service_web.dart'
    if (dart.library.html) 'image_export_service_web.dart'
    as web_service;

class ImageExportService {
  /// Export canvas shapes as PNG (high resolution)
  static Future<ui.Image?> captureCanvasAsImage({
    required List<ShapeData> shapes,
    required Rect canvasRect,
    double targetWidth = 1920.0,
  }) async {
    try {
      final scaleFactor = targetWidth / canvasRect.width;
      final targetHeight = canvasRect.height * scaleFactor;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.scale(scaleFactor);
      canvas.translate(-canvasRect.left, -canvasRect.top);

      // Draw background
      final backgroundPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
      canvas.drawRect(canvasRect, backgroundPaint);

      // Draw shapes
      final shapePaint = ui.Paint()
        ..style = PaintingStyle.fill
        ..strokeWidth = 0.0;

      for (final shape in shapes) {
        final path = Path();
        if (shape.points.isNotEmpty) {
          path.moveTo(shape.points[0].dx, shape.points[0].dy);
          for (int i = 1; i < shape.points.length; i++) {
            path.lineTo(shape.points[i].dx, shape.points[i].dy);
          }
          path.close();
        }

        shapePaint.color = shape.hsv.toColor();
        canvas.drawPath(path, shapePaint);
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        targetWidth.toInt(),
        targetHeight.toInt(),
      );

      return image;
    } catch (e) {
      if (kDebugMode) {
        print('Error capturing canvas as image: $e');
      }
      rethrow;
    }
  }

  /// Export canvas to PNG bytes
  static Future<Uint8List?> exportCanvasAsPngBytes({
    required List<ShapeData> shapes,
    required Rect canvasRect,
    double targetWidth = 1920.0,
  }) async {
    try {
      final image = await captureCanvasAsImage(
        shapes: shapes,
        canvasRect: canvasRect,
        targetWidth: targetWidth,
      );

      if (image == null) return null;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      return byteData.buffer.asUint8List();
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting canvas as PNG: $e');
      }
      rethrow;
    }
  }

  /// Download PNG file (web only)
  static Future<void> downloadCanvasAsPng({
    required List<ShapeData> shapes,
    required Rect canvasRect,
    required String filename,
    double targetWidth = 1920.0,
  }) async {
    try {
      final pngBytes = await exportCanvasAsPngBytes(
        shapes: shapes,
        canvasRect: canvasRect,
        targetWidth: targetWidth,
      );

      if (pngBytes == null) return;

      if (kIsWeb) {
        _downloadFileWeb('$filename.png', pngBytes);
      } else {
        throw UnsupportedError(
          'Download is only supported on web platform.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading PNG: $e');
      }
      rethrow;
    }
  }

  /// Web-specific file download
  static void _downloadFileWeb(String filename, Uint8List bytes) {
    if (!kIsWeb) return;

    try {
      web_service.WebImageExportService.downloadCanvasAsPngWeb(filename, bytes);
    } catch (e) {
      if (kDebugMode) {
        print('Error in web download: $e');
      }
      rethrow;
    }
  }
}
