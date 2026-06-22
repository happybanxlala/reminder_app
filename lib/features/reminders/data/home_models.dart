import '../domain/item.dart';
import '../domain/item_action_record.dart';
import '../domain/remote_sync.dart';
import '../domain/resource.dart';
import '../domain/stage_occurrence.dart';
import '../domain/stage_record.dart';
import 'local/reminder_dao.dart';

sealed class HomeEntry {
  const HomeEntry();
}

class ItemHomeEntry extends HomeEntry {
  const ItemHomeEntry({
    required this.bundle,
    required this.status,
    this.elapsed,
    this.syncStatus = HomeItemSyncStatus.localOnly,
  });

  final ItemBundle bundle;
  final ItemStatus status;
  final Duration? elapsed;
  final HomeItemSyncStatus syncStatus;
}

class HomeItemSyncStatus {
  const HomeItemSyncStatus({
    required this.isRemoteBacked,
    this.remotePackSyncState,
    this.remoteItemSyncState,
    this.pendingMutationAction,
    this.pendingMutationStatus,
    this.lastSyncError,
  });

  static const localOnly = HomeItemSyncStatus(isRemoteBacked: false);

  final bool isRemoteBacked;
  final RemotePackSyncState? remotePackSyncState;
  final RemoteItemSyncState? remoteItemSyncState;
  final SyncOutboxActionType? pendingMutationAction;
  final SyncOutboxStatus? pendingMutationStatus;
  final String? lastSyncError;

  bool get hasPendingMutation =>
      pendingMutationStatus == SyncOutboxStatus.pending ||
      pendingMutationStatus == SyncOutboxStatus.syncing;

  bool get hasFailedMutation =>
      pendingMutationStatus == SyncOutboxStatus.failed ||
      pendingMutationStatus == SyncOutboxStatus.conflict;

  bool get isStale =>
      remotePackSyncState == RemotePackSyncState.stale ||
      remoteItemSyncState == RemoteItemSyncState.stale ||
      pendingMutationStatus == SyncOutboxStatus.noOp;

  bool get isAccessLost =>
      remotePackSyncState == RemotePackSyncState.accessLost ||
      remotePackSyncState == RemotePackSyncState.removed;

  bool get hasVisibleStatus =>
      isRemoteBacked &&
      (hasPendingMutation ||
          hasFailedMutation ||
          isStale ||
          isAccessLost ||
          (lastSyncError?.trim().isNotEmpty ?? false));
}

enum HomeAttentionEntryType { item, resource }

enum HomeAttentionSeverity { danger, warning }

class HomeAttentionEntry extends HomeEntry {
  const HomeAttentionEntry._({
    required this.type,
    required this.severity,
    required this.stableKey,
    required this.urgencyDate,
    this.itemEntry,
    this.resourceBundle,
  });

  factory HomeAttentionEntry.item({
    required ItemHomeEntry entry,
    required HomeAttentionSeverity severity,
    required DateTime? urgencyDate,
  }) {
    return HomeAttentionEntry._(
      type: HomeAttentionEntryType.item,
      severity: severity,
      stableKey: 'item-${entry.bundle.item.id}',
      urgencyDate: urgencyDate,
      itemEntry: entry,
    );
  }

  factory HomeAttentionEntry.resource({
    required ResourceBundle bundle,
    required HomeAttentionSeverity severity,
    required DateTime? urgencyDate,
  }) {
    return HomeAttentionEntry._(
      type: HomeAttentionEntryType.resource,
      severity: severity,
      stableKey: 'resource-${bundle.resource.id}',
      urgencyDate: urgencyDate,
      resourceBundle: bundle,
    );
  }

  final HomeAttentionEntryType type;
  final HomeAttentionSeverity severity;
  final String stableKey;
  final DateTime? urgencyDate;
  final ItemHomeEntry? itemEntry;
  final ResourceBundle? resourceBundle;

  int get packId {
    return switch (type) {
      HomeAttentionEntryType.item => itemEntry!.bundle.item.packId,
      HomeAttentionEntryType.resource => resourceBundle!.resource.packId,
    };
  }

  String get title {
    return switch (type) {
      HomeAttentionEntryType.item => itemEntry!.bundle.item.title,
      HomeAttentionEntryType.resource => resourceBundle!.resource.title,
    };
  }

  DateTime get createdAt {
    return switch (type) {
      HomeAttentionEntryType.item => itemEntry!.bundle.item.createdAt,
      HomeAttentionEntryType.resource => resourceBundle!.resource.createdAt,
    };
  }

  int get sourceId {
    return switch (type) {
      HomeAttentionEntryType.item => itemEntry!.bundle.item.id,
      HomeAttentionEntryType.resource => resourceBundle!.resource.id,
    };
  }

  ItemStatus? get itemStatus => itemEntry?.status;

  ResourceStatus? get resourceStatus {
    if (type != HomeAttentionEntryType.resource) {
      return null;
    }
    return switch (severity) {
      HomeAttentionSeverity.danger => ResourceStatus.danger,
      HomeAttentionSeverity.warning => ResourceStatus.warning,
    };
  }
}

class StageHomeEntry extends HomeEntry {
  const StageHomeEntry(this.occurrence);

  final StageOccurrence occurrence;
}

enum TodayCompletedEntryType {
  itemDone,
  resourceRefilled,
  resourceAdjusted,
  stageAcknowledged,
}

class TodayCompletedEntry extends HomeEntry {
  const TodayCompletedEntry._({
    required this.type,
    required this.stableKey,
    required this.packId,
    required this.title,
    required this.actionDate,
    this.itemActionEntry,
    this.resourceActionEntry,
    this.stageActionEntry,
    this.itemSyncStatus = HomeItemSyncStatus.localOnly,
  });

  factory TodayCompletedEntry.itemDone(
    ItemActionEntry entry, {
    HomeItemSyncStatus syncStatus = HomeItemSyncStatus.localOnly,
  }) {
    return TodayCompletedEntry._(
      type: TodayCompletedEntryType.itemDone,
      stableKey: 'completed-item-${entry.record.id}',
      packId: entry.item.packId,
      title: entry.item.title,
      actionDate: entry.record.actionDate,
      itemActionEntry: entry,
      itemSyncStatus: syncStatus,
    );
  }

  factory TodayCompletedEntry.resource(ResourceActionEntry entry) {
    final type = switch (entry.record.actionType) {
      ResourceActionType.adjusted => TodayCompletedEntryType.resourceAdjusted,
      _ => TodayCompletedEntryType.resourceRefilled,
    };
    return TodayCompletedEntry._(
      type: type,
      stableKey: 'completed-resource-${entry.record.id}',
      packId: entry.resource.packId,
      title: entry.resource.title,
      actionDate: entry.record.actionDate,
      resourceActionEntry: entry,
    );
  }

  factory TodayCompletedEntry.stageAcknowledged(StageActionEntry entry) {
    return TodayCompletedEntry._(
      type: TodayCompletedEntryType.stageAcknowledged,
      stableKey: 'completed-stage-${entry.record.id}',
      packId: entry.stageTracker.packId,
      title: entry.record.label,
      actionDate: entry.record.updatedAt,
      stageActionEntry: entry,
    );
  }

  final TodayCompletedEntryType type;
  final String stableKey;
  final int packId;
  final String title;
  final DateTime actionDate;
  final ItemActionEntry? itemActionEntry;
  final ResourceActionEntry? resourceActionEntry;
  final StageActionEntry? stageActionEntry;
  final HomeItemSyncStatus itemSyncStatus;

  ItemActionRecord? get itemActionRecord => itemActionEntry?.record;

  ResourceActionRecord? get resourceActionRecord => resourceActionEntry?.record;

  StageRecord? get stageRecord => stageActionEntry?.record;

  bool get canUndo {
    final record = itemActionRecord;
    return type == TodayCompletedEntryType.itemDone &&
        record != null &&
        !record.isReverted &&
        record.payload?['undoSnapshot'] is Map;
  }
}
