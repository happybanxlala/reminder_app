import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/home_widget/application/home_widget_action_service.dart';
import 'package:reminder_app/features/home_widget/application/home_widget_pending_action_service.dart';
import 'package:reminder_app/features/home_widget/data/home_widget_native_bridge.dart';
import 'package:reminder_app/features/home_widget/data/home_widget_pending_action.dart';
import 'package:reminder_app/features/home_widget/data/home_widget_snapshot.dart';
import 'package:reminder_app/features/home_widget/data/home_widget_tab.dart';

void main() {
  test('pending action parses Android and iOS transport records', () {
    final android = HomeWidgetPendingAction.fromJson({
      'action': 'complete',
      'entryId': 'item-1',
      'sourcePlatform': 'android',
      'createdAt': 1781000000000,
      'nonce': 'android-nonce',
    });
    final ios = HomeWidgetPendingAction.fromJson({
      'action': 'undo',
      'entryId': 'done-1',
      'sourcePlatform': 'ios',
      'createdAt': 1781000000001,
      'nonce': 'ios-nonce',
    });

    expect(android.action, HomeWidgetPendingActionKind.complete);
    expect(android.sourcePlatform, HomeWidgetPendingActionSource.android);
    expect(android.isValid, isTrue);
    expect(ios.action, HomeWidgetPendingActionKind.undo);
    expect(ios.sourcePlatform, HomeWidgetPendingActionSource.ios);
    expect(ios.isValid, isTrue);
  });

  test('complete action is cleared then routed exactly once', () async {
    final calls = <String>[];
    final bridge = _FakeNativeBridge(
      calls: calls,
      actions: [
        const HomeWidgetPendingAction(
          rawAction: 'complete',
          entryId: 'item-1',
          sourcePlatform: HomeWidgetPendingActionSource.android,
          nonce: 'nonce-1',
        ),
      ],
    );
    final executor = _FakeActionExecutor(calls: calls);
    final service = HomeWidgetPendingActionService(
      nativeBridge: bridge,
      actionService: executor,
    );

    final result = await service.consumePendingAction();

    expect(result, HomeWidgetPendingActionConsumeResult.completed);
    expect(executor.completedEntries, ['item-1']);
    expect(executor.undoneEntries, isEmpty);
    expect(executor.refreshCount, 1);
    expect(calls, ['clear', 'complete:item-1', 'refresh']);
  });

  test('undo action routes to undoCompletedEntry', () async {
    final bridge = _FakeNativeBridge(
      actions: [
        const HomeWidgetPendingAction(
          rawAction: 'undo',
          entryId: 'done-1',
          sourcePlatform: HomeWidgetPendingActionSource.ios,
          nonce: 'nonce-2',
        ),
      ],
    );
    final executor = _FakeActionExecutor();
    final service = HomeWidgetPendingActionService(
      nativeBridge: bridge,
      actionService: executor,
    );

    final result = await service.consumePendingAction();

    expect(result, HomeWidgetPendingActionConsumeResult.undone);
    expect(executor.completedEntries, isEmpty);
    expect(executor.undoneEntries, ['done-1']);
    expect(executor.refreshCount, 1);
  });

  test('invalid action and missing entry id fail closed and refresh', () async {
    final bridge = _FakeNativeBridge(
      actions: [
        const HomeWidgetPendingAction(
          rawAction: 'refill',
          entryId: 'resource-1',
          sourcePlatform: HomeWidgetPendingActionSource.android,
          nonce: 'nonce-3',
        ),
        const HomeWidgetPendingAction(
          rawAction: 'complete',
          entryId: '',
          sourcePlatform: HomeWidgetPendingActionSource.ios,
          nonce: 'nonce-4',
        ),
      ],
    );
    final executor = _FakeActionExecutor();
    final service = HomeWidgetPendingActionService(
      nativeBridge: bridge,
      actionService: executor,
    );

    expect(
      await service.consumePendingAction(),
      HomeWidgetPendingActionConsumeResult.invalid,
    );
    expect(
      await service.consumePendingAction(),
      HomeWidgetPendingActionConsumeResult.invalid,
    );
    expect(executor.completedEntries, isEmpty);
    expect(executor.undoneEntries, isEmpty);
    expect(executor.refreshCount, 2);
  });

  test('same nonce is not consumed twice in one process', () async {
    final bridge = _FakeNativeBridge(
      actions: [
        const HomeWidgetPendingAction(
          rawAction: 'complete',
          entryId: 'item-1',
          sourcePlatform: HomeWidgetPendingActionSource.android,
          nonce: 'same-nonce',
        ),
        const HomeWidgetPendingAction(
          rawAction: 'complete',
          entryId: 'item-1',
          sourcePlatform: HomeWidgetPendingActionSource.android,
          nonce: 'same-nonce',
        ),
      ],
    );
    final executor = _FakeActionExecutor();
    final service = HomeWidgetPendingActionService(
      nativeBridge: bridge,
      actionService: executor,
    );

    expect(
      await service.consumePendingAction(),
      HomeWidgetPendingActionConsumeResult.completed,
    );
    expect(
      await service.consumePendingAction(),
      HomeWidgetPendingActionConsumeResult.duplicate,
    );

    expect(executor.completedEntries, ['item-1']);
    expect(executor.refreshCount, 2);
  });

  test('failed repository action still refreshes snapshot', () async {
    final bridge = _FakeNativeBridge(
      actions: [
        const HomeWidgetPendingAction(
          rawAction: 'complete',
          entryId: 'missing',
          sourcePlatform: HomeWidgetPendingActionSource.android,
          nonce: 'nonce-5',
        ),
      ],
    );
    final executor = _FakeActionExecutor(completeResult: false);
    final service = HomeWidgetPendingActionService(
      nativeBridge: bridge,
      actionService: executor,
    );

    expect(
      await service.consumePendingAction(),
      HomeWidgetPendingActionConsumeResult.failed,
    );
    expect(executor.completedEntries, ['missing']);
    expect(executor.refreshCount, 1);
  });

  test('native callback triggers pending action consumption', () async {
    final bridge = _FakeNativeBridge(
      actions: [
        const HomeWidgetPendingAction(
          rawAction: 'undo',
          entryId: 'done-1',
          sourcePlatform: HomeWidgetPendingActionSource.android,
          nonce: 'nonce-6',
        ),
      ],
    );
    final executor = _FakeActionExecutor();
    final service = HomeWidgetPendingActionService(
      nativeBridge: bridge,
      actionService: executor,
    );

    service.startListeningForNativeActions();
    await bridge.triggerPendingActionAvailable();

    expect(executor.undoneEntries, ['done-1']);
    expect(executor.refreshCount, 1);
  });

  test('no pending action does not refresh snapshot', () async {
    final bridge = _FakeNativeBridge(actions: []);
    final executor = _FakeActionExecutor();
    final service = HomeWidgetPendingActionService(
      nativeBridge: bridge,
      actionService: executor,
    );

    expect(
      await service.consumePendingAction(),
      HomeWidgetPendingActionConsumeResult.none,
    );
    expect(executor.refreshCount, 0);
  });
}

class _FakeNativeBridge extends HomeWidgetNativeBridge {
  _FakeNativeBridge({required this.actions, List<String>? calls})
    : calls = calls ?? <String>[];

  final List<HomeWidgetPendingAction?> actions;
  final List<String> calls;
  Future<void> Function()? _handler;

  @override
  Future<HomeWidgetPendingAction?> readAndClearPendingAction() async {
    calls.add('clear');
    if (actions.isEmpty) {
      return null;
    }
    return actions.removeAt(0);
  }

  @override
  void setPendingActionAvailableHandler(Future<void> Function()? handler) {
    _handler = handler;
  }

  Future<void> triggerPendingActionAvailable() async {
    await _handler?.call();
  }
}

class _FakeActionExecutor implements HomeWidgetActionExecutor {
  _FakeActionExecutor({this.completeResult = true, List<String>? calls})
    : calls = calls ?? <String>[];

  final bool completeResult;
  final List<String> calls;
  final List<String> completedEntries = <String>[];
  final List<String> undoneEntries = <String>[];
  int refreshCount = 0;

  @override
  Future<bool> completeEntry(String entryId) async {
    calls.add('complete:$entryId');
    completedEntries.add(entryId);
    return completeResult;
  }

  @override
  Future<HomeWidgetSnapshot> refreshSnapshot({
    HomeWidgetTabId? selectedTab,
  }) async {
    calls.add('refresh');
    refreshCount += 1;
    return HomeWidgetSnapshot(
      schemaVersion: HomeWidgetSnapshot.currentSchemaVersion,
      updatedAt: DateTime(2026, 6, 10, 9),
      selectedTab: selectedTab ?? HomeWidgetTabId.needsHandling,
      tabs: const <HomeWidgetTab>[],
    );
  }

  @override
  Future<bool> undoCompletedEntry(String entryId) async {
    calls.add('undo:$entryId');
    undoneEntries.add(entryId);
    return true;
  }
}
