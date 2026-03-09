import 'package:flutter/widgets.dart';

/// Simple static refresh notifier.
///
/// Register in initState:
///   QueueRefreshNotifier.register(_refresh);
///
/// Unregister in dispose:
///   QueueRefreshNotifier.unregister(_refresh);
///
/// Fire from anywhere:
///   QueueRefreshNotifier.triggerRefresh();
class QueueRefreshNotifier {
  static final List<VoidCallback> _listeners = [];

  static void register(VoidCallback cb) {
    if (!_listeners.contains(cb)) _listeners.add(cb);
  }

  static void unregister(VoidCallback cb) {
    _listeners.remove(cb);
  }

  /// Calls every registered listener on the next safe frame.
  static void triggerRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final cb in List<VoidCallback>.from(_listeners)) {
        cb();
      }
    });
  }
}
