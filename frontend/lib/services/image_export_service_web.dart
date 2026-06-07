import 'dart:html' as html;
import 'dart:typed_data';

class WebImageExportService {
  /// Download PNG file on web
  static void downloadCanvasAsPngWeb(
    String filename,
    Uint8List pngBytes,
  ) {
    try {
      final blob = html.Blob([pngBytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement()
        ..href = url
        ..target = 'blank'
        ..download = filename
        ..click();

      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error downloading PNG: $e');
      rethrow;
    }
  }
}
