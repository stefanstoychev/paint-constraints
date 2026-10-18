import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

// Queries chromedriver for the active session ID, then uses the WebDriver
// /screenshot endpoint to capture a PNG — required because
// binding.takeScreenshot() returns empty bytes on Flutter web.
String? _sessionId;

Future<String?> _getSessionId() async {
  if (_sessionId != null) return _sessionId;
  try {
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse('http://localhost:4444/sessions'));
    final res = await req.close();
    final body = await res.transform(const Utf8Decoder()).join();
    client.close();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final sessions = data['value'] as List<dynamic>;
    if (sessions.isNotEmpty) {
      _sessionId = (sessions.first as Map<String, dynamic>)['id'] as String;
    }
  } catch (e) {
    stderr.writeln('Could not get WebDriver session: $e');
  }
  return _sessionId;
}

Future<List<int>?> _webDriverScreenshot() async {
  final sessionId = await _getSessionId();
  if (sessionId == null) return null;
  try {
    final client = HttpClient();
    final req = await client.getUrl(
      Uri.parse('http://localhost:4444/session/$sessionId/screenshot'),
    );
    final res = await req.close();
    final body = await res.transform(const Utf8Decoder()).join();
    client.close();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final b64 = data['value'] as String;
    return base64Decode(b64);
  } catch (e) {
    stderr.writeln('Screenshot failed: $e');
    return null;
  }
}

Future<void> main() => integrationDriver(
  onScreenshot: (
    String name,
    List<int> bytes, [
    Map<String, Object?>? args,
  ]) async {
    await Directory('screenshots').create(recursive: true);

    final imageBytes = bytes.isNotEmpty ? bytes : await _webDriverScreenshot();
    if (imageBytes != null) {
      await File('screenshots/$name.png').writeAsBytes(imageBytes);
      stdout.writeln('screenshot: screenshots/$name.png');
    } else {
      stderr.writeln('no bytes for screenshot: $name');
    }
    return true;
  },
);
