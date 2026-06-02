import 'package:flutter/foundation.dart';

class PwaUpdateNotifier extends ChangeNotifier {
  bool _updateAvailable = false;
  bool get updateAvailable => _updateAvailable;

  VoidCallback? _activateUpdate;

  void markUpdateAvailable(VoidCallback activateUpdate) {
    if (_updateAvailable) {
      return;
    }

    _updateAvailable = true;
    _activateUpdate = activateUpdate;
    notifyListeners();
  }

  Future<void> applyUpdate() async {
    _activateUpdate?.call();
  }
}
