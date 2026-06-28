import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/reminder_dao.dart';
import '../data/resource_repository.dart';
import '../domain/remote_sync.dart';
import '../domain/resource.dart';
import 'database_providers.dart';
import 'identity_providers.dart';

class ResourceSyncStatus {
  const ResourceSyncStatus({
    required this.isRemoteBacked,
    this.remotePackSyncState,
    this.remoteResourceSyncState,
    this.pendingMutationStatus,
    this.lastSyncError,
  });

  static const localOnly = ResourceSyncStatus(isRemoteBacked: false);

  final bool isRemoteBacked;
  final RemotePackSyncState? remotePackSyncState;
  final RemoteResourceSyncState? remoteResourceSyncState;
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
      remoteResourceSyncState == RemoteResourceSyncState.stale ||
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

final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  return ResourceRepository(
    ref.watch(appDatabaseProvider).reminderDao,
    currentActorId: () => currentActorId(ref),
  );
});

final resourcesProvider = StreamProvider<List<ResourceBundle>>((ref) {
  return ref.watch(resourceRepositoryProvider).watchResources();
});

final managedResourcesProvider = StreamProvider<List<ResourceBundle>>((ref) {
  return ref.watch(resourceRepositoryProvider).watchManagedResources();
});

final resourceProvider = FutureProvider.family<ResourceBundle?, int>((ref, id) {
  return ref.watch(resourceRepositoryProvider).getResourceById(id);
});

final resourceSyncStatusProvider =
    FutureProvider.family<ResourceSyncStatus, int>((ref, resourceId) async {
      final dao = ref.watch(appDatabaseProvider).reminderDao;
      final bundle = await dao.getResourceBundleById(resourceId);
      if (bundle == null || !await dao.isRemoteBackedPack(bundle.pack.id)) {
        return ResourceSyncStatus.localOnly;
      }
      final packMetadata = await dao.getRemotePackSyncMetadataForLocalPack(
        bundle.pack.id,
      );
      final resourceMetadata = await dao
          .getRemoteResourceSyncMetadataForLocalResource(resourceId);
      final mutations = await dao.listSyncOutboxEntries(
        statuses: const {
          SyncOutboxStatus.pending,
          SyncOutboxStatus.syncing,
          SyncOutboxStatus.failed,
          SyncOutboxStatus.conflict,
          SyncOutboxStatus.noOp,
        },
      );
      SyncOutboxEntry? mutation;
      for (final entry in mutations) {
        if (entry.localEntityType == 'resource' &&
            entry.localEntityId == resourceId) {
          mutation = entry;
          break;
        }
      }
      return ResourceSyncStatus(
        isRemoteBacked: true,
        remotePackSyncState: packMetadata?.syncState,
        remoteResourceSyncState: resourceMetadata?.syncState,
        pendingMutationStatus: mutation?.status,
        lastSyncError: mutation?.lastError ?? resourceMetadata?.lastSyncError,
      );
    });

final resourceBindingsProvider =
    StreamProvider.family<List<ResourceBinding>, int>((ref, resourceId) {
      return ref.watch(resourceRepositoryProvider).watchBindings(resourceId);
    });

final resourceActionHistoryProvider =
    StreamProvider.family<List<ResourceActionRecord>, int>((ref, resourceId) {
      return ref
          .watch(resourceRepositoryProvider)
          .watchActionHistory(resourceId);
    });

final resourceActionHistoryEntriesProvider =
    StreamProvider.family<List<ResourceActionHistoryEntry>, int>((
      ref,
      resourceId,
    ) {
      return ref
          .watch(resourceRepositoryProvider)
          .watchActionHistoryEntries(resourceId);
    });

final resourceActionHistoryEntriesWithRevertedProvider =
    StreamProvider.family<List<ResourceActionHistoryEntry>, int>((
      ref,
      resourceId,
    ) {
      return ref
          .watch(resourceRepositoryProvider)
          .watchActionHistoryEntries(resourceId, includeReverted: true);
    });

final itemConsumptionRulesProvider =
    StreamProvider.family<List<ResourceConsumptionRule>, int>((ref, itemId) {
      return ref.watch(resourceRepositoryProvider).watchRulesForItem(itemId);
    });
