import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reminders/providers/developer_settings_providers.dart';
import '../../reminders/providers/home_providers.dart';
import '../../reminders/providers/item_providers.dart';
import '../application/home_widget_action_service.dart';
import '../application/home_widget_pending_action_service.dart';
import '../application/home_widget_snapshot_service.dart';
import '../data/home_widget_native_bridge.dart';
import '../data/home_widget_snapshot_store.dart';

final homeWidgetNativeBridgeProvider = Provider<HomeWidgetNativeBridge>((ref) {
  return const HomeWidgetNativeBridge();
});

final homeWidgetSnapshotStoreProvider = Provider<HomeWidgetSnapshotStore>((
  ref,
) {
  final nativeBridge = ref.watch(homeWidgetNativeBridgeProvider);
  return FileHomeWidgetSnapshotStore(
    directoryProvider: nativeBridge.appGroupContainerDirectory,
  );
});

final homeWidgetSnapshotServiceProvider = Provider<HomeWidgetSnapshotService>((
  ref,
) {
  return HomeWidgetSnapshotService(
    homeRepository: ref.watch(homeRepositoryProvider),
    currentDate: ref.watch(effectivePreviewDateProvider),
  );
});

final homeWidgetActionServiceProvider = Provider<HomeWidgetActionService>((
  ref,
) {
  return HomeWidgetActionService(
    snapshotService: ref.watch(homeWidgetSnapshotServiceProvider),
    snapshotStore: ref.watch(homeWidgetSnapshotStoreProvider),
    itemRepository: ref.watch(itemRepositoryProvider),
    currentDate: ref.watch(effectivePreviewDateProvider),
    nativeBridge: ref.watch(homeWidgetNativeBridgeProvider),
  );
});

final homeWidgetPendingActionServiceProvider =
    Provider<HomeWidgetPendingActionService>((ref) {
      return HomeWidgetPendingActionService(
        nativeBridge: ref.watch(homeWidgetNativeBridgeProvider),
        actionService: ref.watch(homeWidgetActionServiceProvider),
      );
    });
