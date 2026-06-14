import 'package:flutter/foundation.dart';

import '../data/home_widget_native_bridge.dart';
import '../data/home_widget_pending_action.dart';
import 'home_widget_action_service.dart';

enum HomeWidgetPendingActionConsumeResult {
  none,
  completed,
  undone,
  invalid,
  duplicate,
  failed,
}

class HomeWidgetPendingActionService {
  HomeWidgetPendingActionService({
    required HomeWidgetNativeBridge nativeBridge,
    required HomeWidgetActionExecutor actionService,
  }) : _nativeBridge = nativeBridge,
       _actionService = actionService;

  final HomeWidgetNativeBridge _nativeBridge;
  final HomeWidgetActionExecutor _actionService;
  final Set<String> _consumedKeys = <String>{};
  bool _isConsuming = false;

  Future<HomeWidgetPendingActionConsumeResult> consumePendingAction() async {
    if (_isConsuming) {
      return HomeWidgetPendingActionConsumeResult.none;
    }
    _isConsuming = true;
    try {
      final pending = await _nativeBridge.readAndClearPendingAction();
      if (pending == null) {
        return HomeWidgetPendingActionConsumeResult.none;
      }

      final key = pending.duplicateKey;
      if (_consumedKeys.contains(key)) {
        _log('Ignored duplicate widget action: ${pending.rawAction}');
        await _actionService.refreshSnapshot();
        return HomeWidgetPendingActionConsumeResult.duplicate;
      }
      _consumedKeys.add(key);

      final action = pending.action;
      if (action == null || !pending.hasValidEntryId) {
        _log('Ignored invalid widget action: ${pending.rawAction}');
        await _actionService.refreshSnapshot();
        return HomeWidgetPendingActionConsumeResult.invalid;
      }

      final handled = switch (action) {
        HomeWidgetPendingActionKind.complete =>
          await _actionService.completeEntry(pending.entryId.trim()),
        HomeWidgetPendingActionKind.undo =>
          await _actionService.undoCompletedEntry(pending.entryId.trim()),
      };
      await _actionService.refreshSnapshot();
      if (!handled) {
        _log('Widget action failed closed: ${pending.rawAction}');
        return HomeWidgetPendingActionConsumeResult.failed;
      }
      return switch (action) {
        HomeWidgetPendingActionKind.complete =>
          HomeWidgetPendingActionConsumeResult.completed,
        HomeWidgetPendingActionKind.undo =>
          HomeWidgetPendingActionConsumeResult.undone,
      };
    } finally {
      _isConsuming = false;
    }
  }

  void startListeningForNativeActions() {
    _nativeBridge.setPendingActionAvailableHandler(consumePendingAction);
  }

  void stopListeningForNativeActions() {
    _nativeBridge.setPendingActionAvailableHandler(null);
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}
