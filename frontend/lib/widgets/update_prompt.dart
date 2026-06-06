import 'package:flutter/material.dart';
import 'package:frontend/services/pwa_update_notifier.dart';
import 'package:provider/provider.dart';

class UpdatePrompt extends StatefulWidget {
  final Widget child;

  const UpdatePrompt({super.key, required this.child});

  @override
  State<UpdatePrompt> createState() => _UpdatePromptState();
}

class _UpdatePromptState extends State<UpdatePrompt> {
  bool _dialogShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = Provider.of<PwaUpdateNotifier>(context);

    if (notifier.updateAvailable && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUpdateDialog(notifier);
      });
    }
  }

  Future<void> _showUpdateDialog(PwaUpdateNotifier notifier) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: const Text(
            'A new version of Paint Constraints is ready. Reload now to apply the update.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await notifier.applyUpdate();
              },
              child: const Text('Reload Now'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
