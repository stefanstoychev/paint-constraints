import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'pwa_update_notifier.dart';

Future<PwaUpdateNotifier> initPwaUpdateService() async {
  final notifier = PwaUpdateNotifier();
  final serviceWorker = web.window.navigator.serviceWorker;

  try {
    final registration = await serviceWorker
        .register('flutter_service_worker.js'.toJS)
        .toDart;
    _watchForWaitingWorker(registration, notifier);
    _reloadOnControllerChange();
    _scheduleUpdateChecks(registration);
  } catch (error) {
    web.console.warn('PWA update registration failed: $error'.toJS);
  }

  return notifier;
}

void _watchForWaitingWorker(
  web.ServiceWorkerRegistration registration,
  PwaUpdateNotifier notifier,
) {
  void checkWaiting(web.ServiceWorker? worker) {
    if (worker != null &&
        worker.state == 'installed' &&
        web.window.navigator.serviceWorker.controller != null) {
      notifier.markUpdateAvailable(() => _activateWaitingWorker(worker));
    }
  }

  if (registration.waiting != null) {
    checkWaiting(registration.waiting);
  }

  registration.addEventListener(
    'updatefound',
    ((web.Event _) {
      final installingWorker = registration.installing;
      if (installingWorker == null) return;
      installingWorker.addEventListener(
        'statechange',
        ((web.Event _) => checkWaiting(installingWorker)).toJS,
      );
    }).toJS,
  );
}

bool _reloadScheduled = false;

void _reloadOnControllerChange() {
  web.window.navigator.serviceWorker.addEventListener(
    'controllerchange',
    ((web.Event _) {
      if (_reloadScheduled) return;
      _reloadScheduled = true;
      web.window.location.reload();
    }).toJS,
  );
}

void _activateWaitingWorker(web.ServiceWorker worker) {
  try {
    final message = JSObject();
    message['type'] = 'SKIP_WAITING'.toJS;
    worker.postMessage(message);
  } catch (_) {
    web.console.warn(
      'Unable to send SKIP_WAITING message to service worker.'.toJS,
    );
  }
}

void _scheduleUpdateChecks(web.ServiceWorkerRegistration registration) {
  registration.update();

  Timer.periodic(const Duration(hours: 4), (_) {
    registration.update();
  });

  web.window.addEventListener(
    'focus',
    ((web.Event _) => registration.update()).toJS,
  );
}
