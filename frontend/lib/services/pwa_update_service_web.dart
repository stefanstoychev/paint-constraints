import 'dart:async';
import 'dart:html';

import 'pwa_update_notifier.dart';

Future<PwaUpdateNotifier> initPwaUpdateService() async {
  final notifier = PwaUpdateNotifier();
  final serviceWorker = window.navigator.serviceWorker;
  if (serviceWorker == null) {
    return notifier;
  }

  try {
    final registration = await serviceWorker.register(
      'flutter_service_worker.js',
    );
    _watchForWaitingWorker(registration, notifier);
    _reloadOnControllerChange();
    _scheduleUpdateChecks(registration);
  } catch (error) {
    window.console.warn('PWA update registration failed: $error');
  }

  return notifier;
}

void _watchForWaitingWorker(
  ServiceWorkerRegistration registration,
  PwaUpdateNotifier notifier,
) {
  void checkWaiting(ServiceWorker? worker) {
    if (worker != null &&
        worker.state == 'installed' &&
        window.navigator.serviceWorker?.controller != null) {
      notifier.markUpdateAvailable(() => _activateWaitingWorker(worker));
    }
  }

  if (registration.waiting != null) {
    checkWaiting(registration.waiting);
  }

  registration.addEventListener('updatefound', (Event _) {
    final installingWorker = registration.installing;
    if (installingWorker == null) return;

    installingWorker.addEventListener('statechange', (Event _) {
      checkWaiting(installingWorker);
    });
  });
}

bool _reloadScheduled = false;

void _reloadOnControllerChange() {
  window.navigator.serviceWorker?.addEventListener('controllerchange', (
    Event _,
  ) {
    if (_reloadScheduled) {
      return;
    }
    _reloadScheduled = true;
    window.location.reload();
  });
}

void _activateWaitingWorker(ServiceWorker worker) {
  try {
    worker.postMessage({'type': 'SKIP_WAITING'});
  } catch (_) {
    window.console.warn(
      'Unable to send SKIP_WAITING message to service worker.',
    );
  }
}

void _scheduleUpdateChecks(ServiceWorkerRegistration registration) {
  registration.update();

  Timer.periodic(const Duration(hours: 4), (_) {
    registration.update();
  });

  window.onFocus.listen((_) {
    registration.update();
  });
}
