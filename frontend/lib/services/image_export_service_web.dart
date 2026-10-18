import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

class WebImageExportService {
  static void downloadCanvasAsPngWeb(String filename, Uint8List pngBytes) {
    try {
      final blob = web.Blob(
        [pngBytes.buffer.toJS].toJS,
        web.BlobPropertyBag(type: 'image/png'),
      );
      final url = web.URL.createObjectURL(blob);
      final anchor =
          web.document.createElement('a') as web.HTMLAnchorElement;
      anchor.href = url;
      anchor.download = filename;
      anchor.click();
      web.URL.revokeObjectURL(url);
    } catch (e) {
      debugPrint('Error downloading PNG: $e');
      rethrow;
    }
  }
}
