import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/attention_policy.dart';
import '../domain/item.dart';
import '../domain/item_action_record.dart';
import '../domain/item_pack.dart';
import '../domain/remote_sync.dart';
import '../domain/shared_pack.dart';
import 'identity_repository.dart';
import 'local/app_database.dart';
import 'local/reminder_dao.dart';
import 'remote_shared_pack_models.dart';
import 'remote_shared_pack_repository.dart';

enum RemoteSnapshotImportSource {
  localMappedPack,
  joinedRemotePack,
  manualDeveloperImport,
}

enum RemoteSnapshotImportStatus {
  success,
  alreadyImported,
  updatedExistingMirror,
  partialImport,
  failed,
  conflict,
}

class RemoteSnapshotImportResult {
  const RemoteSnapshotImportResult({
    required this.status,
    required this.remotePackId,
    this.localPackId,
    this.membersCreated = 0,
    this.membersUpdated = 0,
    this.itemsCreated = 0,
    this.itemsUpdated = 0,
    this.completionsCreated = 0,
    this.completionsUpdated = 0,
    this.activityCreated = 0,
    this.activityUpdated = 0,
    this.skipped = 0,
    this.warnings = const [],
  });

  final RemoteSnapshotImportStatus status;
  final String remotePackId;
  final int? localPackId;
  final int membersCreated;
  final int membersUpdated;
  final int itemsCreated;
  final int itemsUpdated;
  final int completionsCreated;
  final int completionsUpdated;
  final int activityCreated;
  final int activityUpdated;
  final int skipped;
  final List<String> warnings;

  bool get succeeded =>
      status != RemoteSnapshotImportStatus.failed &&
      status != RemoteSnapshotImportStatus.conflict;
}

class RemoteSnapshotImportService {
  const RemoteSnapshotImportService({
    required ReminderDao dao,
    required IdentityRepository identityRepository,
    DateTime Function()? clock,
  }) : _dao = dao,
       _identityRepository = identityRepository,
       _clock = clock ?? DateTime.now;

  static const localEntityCompletion = 'item_completion';
  static const localEntityActivity = 'activity_event';
  static const remoteTableCompletions = 'item_completions';
  static const remoteTableActivityEvents = 'activity_events';

  final ReminderDao _dao;
  final IdentityRepository _identityRepository;
  final DateTime Function() _clock;

  Future<RemoteSnapshotImportResult> importRemotePackSnapshot({
    required RemotePackSnapshot snapshot,
    required RemoteSnapshotImportSource source,
  }) async {
    final _ = source;
    final currentUser = await _identityRepository.getCurrentAppUser();
    final warnings = <String>[];
    var membersCreated = 0;
    var membersUpdated = 0;
    var itemsCreated = 0;
    var itemsUpdated = 0;
    var completionsCreated = 0;
    var completionsUpdated = 0;
    var activityCreated = 0;
    var activityUpdated = 0;
    var skipped = 0;

    try {
      final localPackId = await _dao.attachedDatabase.transaction(() async {
        final packId = await _ensureLocalPack(snapshot);
        await _upsertPackMappingAndMetadata(
          snapshot: snapshot,
          localPackId: packId,
          currentUser: currentUser,
        );

        final userMap = <String, LocalUser>{};
        for (final member in snapshot.members) {
          final before = await _dao.getLocalUserByRemoteUserId(member.userId);
          final localUser = await _ensureRemoteUser(
            remoteUserId: member.userId,
            displayName: member.displayName,
            currentUser: currentUser,
          );
          userMap[member.userId] = localUser;
          if (before == null && localUser.id.startsWith(_placeholderPrefix)) {
            membersCreated++;
          }
          final previousMember = await _dao.getPackMember(
            packId: packId,
            userId: localUser.id,
          );
          await _dao.upsertPackMember(
            PackMembersCompanion.insert(
              packId: packId,
              userId: localUser.id,
              role: _localMemberRole(member.role).name,
              status: Value(_localMemberStatus(member.status).name),
              joinedAt: member.joinedAt.millisecondsSinceEpoch,
            ),
          );
          previousMember == null ? membersCreated++ : membersUpdated++;
        }

        final hostUser = userMap[snapshot.hostUserId];
        if (hostUser != null) {
          await _dao.updateItemPackFields(
            packId,
            ItemPacksCompanion(
              hostUserId: Value(hostUser.id),
              updatedAt: Value(_millis(snapshot.updatedAt)),
            ),
          );
        }

        final itemIdsByRemoteId = <String, int>{};
        for (final item in snapshot.items) {
          final existingId = await _findLocalEntityId(
            localEntityType: RemoteSharedPackRepository.localEntityItem,
            remoteTable: RemoteSharedPackRepository.remoteTableItems,
            remoteEntityId: item.id,
          );
          final localItemId =
              existingId ??
              await _insertLocalItem(
                snapshot: item,
                localPackId: packId,
                assignedToUserId: _localUserId(userMap, item.assignedToUserId),
              );
          if (existingId == null) {
            itemsCreated++;
          } else {
            itemsUpdated++;
            await _updateLocalItem(
              localItemId: localItemId,
              snapshot: item,
              assignedToUserId: _localUserId(userMap, item.assignedToUserId),
            );
          }
          itemIdsByRemoteId[item.id] = localItemId;
          await _upsertItemMappingAndMetadata(
            snapshot: item,
            localPackId: packId,
            localItemId: localItemId,
          );
        }

        final completionIdsByRemoteId = <String, int>{};
        for (final completion in snapshot.completions) {
          final localItemId = itemIdsByRemoteId[completion.itemId];
          if (localItemId == null) {
            skipped++;
            warnings.add(
              'Skipped completion ${completion.id}: remote item is not mapped.',
            );
            continue;
          }
          final completedBy = await _ensureRemoteUser(
            remoteUserId: completion.completedByUserId,
            displayName: null,
            currentUser: currentUser,
          );
          LocalUser? undoneBy;
          if (completion.undoneByUserId != null) {
            undoneBy = await _ensureRemoteUser(
              remoteUserId: completion.undoneByUserId!,
              displayName: null,
              currentUser: currentUser,
            );
          }
          final existingId = await _findLocalEntityId(
            localEntityType: localEntityCompletion,
            remoteTable: remoteTableCompletions,
            remoteEntityId: completion.id,
          );
          final localCompletionId =
              existingId ??
              await _insertLocalCompletion(
                snapshot: completion,
                localPackId: packId,
                localItemId: localItemId,
                completedByUserId: completedBy.id,
                undoneByUserId: undoneBy?.id,
              );
          if (existingId == null) {
            completionsCreated++;
          } else {
            completionsUpdated++;
          }
          completionIdsByRemoteId[completion.id] = localCompletionId;
          await _upsertCompletionMappingAndMetadata(
            snapshot: completion,
            localPackId: packId,
            localItemId: localItemId,
            localCompletionId: localCompletionId,
          );
        }

        for (final event in snapshot.activityEvents) {
          final localEntityId = _activityEntityId(
            event: event,
            localPackId: packId,
            itemIdsByRemoteId: itemIdsByRemoteId,
            completionIdsByRemoteId: completionIdsByRemoteId,
          );
          if (localEntityId == null) {
            skipped++;
            warnings.add(
              'Skipped activity ${event.id}: remote entity is not mappable.',
            );
            continue;
          }
          final existingId = await _findLocalEntityId(
            localEntityType: localEntityActivity,
            remoteTable: remoteTableActivityEvents,
            remoteEntityId: event.id,
          );
          if (existingId != null) {
            activityUpdated++;
            continue;
          }
          final actor = event.actorUserId == null
              ? await _ensureSystemActor()
              : await _ensureRemoteUser(
                  remoteUserId: event.actorUserId!,
                  displayName: event.actorDisplayNameSnapshot,
                  currentUser: currentUser,
                );
          final localActivityId = await _insertLocalActivityEvent(
            snapshot: event,
            localPackId: packId,
            localEntityId: localEntityId,
            actorUserId: actor.id,
          );
          await _upsertSyncMapping(
            localEntityType: localEntityActivity,
            localEntityId: localActivityId,
            remoteTable: remoteTableActivityEvents,
            remoteEntityId: event.id,
            now: _clock(),
          );
          activityCreated++;
        }

        return packId;
      });

      final created =
          membersCreated + itemsCreated + completionsCreated + activityCreated;
      final updated =
          membersUpdated + itemsUpdated + completionsUpdated + activityUpdated;
      final status = warnings.isNotEmpty || skipped > 0
          ? RemoteSnapshotImportStatus.partialImport
          : created > 0
          ? RemoteSnapshotImportStatus.success
          : updated > 0
          ? RemoteSnapshotImportStatus.updatedExistingMirror
          : RemoteSnapshotImportStatus.alreadyImported;
      return RemoteSnapshotImportResult(
        status: status,
        remotePackId: snapshot.id,
        localPackId: localPackId,
        membersCreated: membersCreated,
        membersUpdated: membersUpdated,
        itemsCreated: itemsCreated,
        itemsUpdated: itemsUpdated,
        completionsCreated: completionsCreated,
        completionsUpdated: completionsUpdated,
        activityCreated: activityCreated,
        activityUpdated: activityUpdated,
        skipped: skipped,
        warnings: List.unmodifiable(warnings),
      );
    } catch (_) {
      return RemoteSnapshotImportResult(
        status: RemoteSnapshotImportStatus.failed,
        remotePackId: snapshot.id,
        skipped: skipped,
        warnings: List.unmodifiable(warnings),
      );
    }
  }

  Future<int> _ensureLocalPack(RemotePackSnapshot snapshot) async {
    final mapped = await _findLocalEntityId(
      localEntityType: RemoteSharedPackRepository.localEntityPack,
      remoteTable: RemoteSharedPackRepository.remoteTablePacks,
      remoteEntityId: snapshot.id,
    );
    if (mapped != null) {
      await _dao.updateItemPackFields(
        mapped,
        ItemPacksCompanion(
          title: Value(snapshot.name),
          description: Value(snapshot.description),
          status: Value(_localPackStatus(snapshot.status).name),
          updatedAt: Value(_millis(snapshot.updatedAt)),
        ),
      );
      return mapped;
    }
    final metadata = await _dao.getRemotePackSyncMetadataForRemotePack(
      snapshot.id,
    );
    if (metadata != null) {
      return metadata.localPackId;
    }
    return _dao.insertItemPack(
      ItemPacksCompanion.insert(
        title: snapshot.name,
        description: Value(snapshot.description),
        status: Value(_localPackStatus(snapshot.status).name),
        packType: Value(ItemPackType.shared.name),
        createdAt: _millis(snapshot.createdAt),
        updatedAt: _millis(snapshot.updatedAt),
      ),
    );
  }

  Future<int> _insertLocalItem({
    required RemoteItemSnapshot snapshot,
    required int localPackId,
    required String? assignedToUserId,
  }) {
    return _dao.insertItem(
      ItemsCompanion.insert(
        packId: localPackId,
        title: snapshot.title,
        description: Value(snapshot.note),
        status: Value(_localItemStatus(snapshot.status).name),
        type: ItemType.stateBased.name,
        attentionPolicySource: Value(AttentionPolicySource.systemDefault.name),
        assignedToUserId: Value(assignedToUserId),
        createdAt: _millis(snapshot.createdAt),
        updatedAt: _millis(snapshot.updatedAt),
      ),
    );
  }

  Future<void> _updateLocalItem({
    required int localItemId,
    required RemoteItemSnapshot snapshot,
    required String? assignedToUserId,
  }) async {
    await _dao.updateItemFields(
      localItemId,
      ItemsCompanion(
        title: Value(snapshot.title),
        description: Value(snapshot.note),
        status: Value(_localItemStatus(snapshot.status).name),
        assignedToUserId: Value(assignedToUserId),
        updatedAt: Value(_millis(snapshot.updatedAt)),
      ),
    );
  }

  Future<int> _insertLocalCompletion({
    required RemoteItemCompletionSnapshot snapshot,
    required int localPackId,
    required int localItemId,
    required String completedByUserId,
    required String? undoneByUserId,
  }) async {
    final payload = ItemActionRecord.encodePayload({
      'remoteImported': true,
      'remoteCompletionId': snapshot.id,
      'remoteItemId': snapshot.itemId,
      'remotePackId': snapshot.packId,
    });
    final actionId = await _dao.insertItemActionRecord(
      ItemActionRecordsCompanion.insert(
        itemId: localItemId,
        actionType: ItemActionType.done.name,
        actionDate: _millis(snapshot.completedAt),
        payload: Value(payload),
        createdAt: _millis(snapshot.createdAt),
        updatedAt: _millis(snapshot.createdAt),
      ),
    );
    return _dao.insertItemCompletion(
      ItemCompletionsCompanion.insert(
        itemId: localItemId,
        packId: localPackId,
        itemActionRecordId: actionId,
        completedByUserId: completedByUserId,
        completedAt: _millis(snapshot.completedAt),
        undoneByUserId: Value(undoneByUserId),
        undoneAt: Value(_millisOrNull(snapshot.undoneAt)),
        clientMutationId: Value(snapshot.clientMutationId),
        createdAt: _millis(snapshot.createdAt),
      ),
    );
  }

  Future<int> _insertLocalActivityEvent({
    required RemoteActivityEventSnapshot snapshot,
    required int localPackId,
    required int localEntityId,
    required String actorUserId,
  }) {
    return _dao.insertActivityEvent(
      ActivityEventsCompanion.insert(
        packId: localPackId,
        actorUserId: actorUserId,
        entityType: snapshot.entityType,
        entityId: localEntityId,
        action: snapshot.action,
        beforeJson: Value(_encodeMap(snapshot.beforeJson)),
        afterJson: Value(_encodeMap(snapshot.afterJson)),
        metadataJson: Value(
          _encodeMap({
            'remoteActivityId': snapshot.id,
            'remoteEntityType': snapshot.entityType,
            'remoteEntityId': snapshot.entityId,
            'actorRemoteUserId': snapshot.actorUserId,
            'actorDisplayNameSnapshot': snapshot.actorDisplayNameSnapshot,
            'remoteMetadata': snapshot.metadataJson,
          }),
        ),
        createdAt: _millis(snapshot.createdAt),
      ),
    );
  }

  Future<void> _upsertPackMappingAndMetadata({
    required RemotePackSnapshot snapshot,
    required int localPackId,
    required LocalUser currentUser,
  }) async {
    final now = _clock();
    await _upsertSyncMapping(
      localEntityType: RemoteSharedPackRepository.localEntityPack,
      localEntityId: localPackId,
      remoteTable: RemoteSharedPackRepository.remoteTablePacks,
      remoteEntityId: snapshot.id,
      now: now,
    );
    RemotePackMemberSnapshot? currentMember;
    for (final member in snapshot.members) {
      if (member.userId == currentUser.remoteUserId) {
        currentMember = member;
        break;
      }
    }
    final existing = await _dao.getRemotePackSyncMetadataForLocalPack(
      localPackId,
    );
    final entry = RemotePackSyncMetadataCompanion(
      localPackId: Value(localPackId),
      remotePackId: Value(snapshot.id),
      syncKind: Value(RemotePackSyncKind.remoteBacked.storageValue),
      syncState: Value(RemotePackSyncState.synced.storageValue),
      currentUserRemoteRole: Value(
        currentMember == null
            ? null
            : RemoteUserRoleStorage.parse(currentMember.role).storageValue,
      ),
      currentUserRemoteStatus: Value(
        currentMember == null
            ? null
            : RemoteUserStatusStorage.parse(currentMember.status).storageValue,
      ),
      lastRemoteSnapshotAt: Value(_millis(snapshot.updatedAt)),
      lastSuccessfulSyncAt: Value(now.millisecondsSinceEpoch),
      lastSyncError: const Value(null),
      updatedAt: Value(now.millisecondsSinceEpoch),
    );
    if (existing == null) {
      await _dao.insertRemotePackSyncMetadata(
        RemotePackSyncMetadataCompanion.insert(
          localPackId: localPackId,
          remotePackId: snapshot.id,
          syncKind: RemotePackSyncKind.remoteBacked.storageValue,
          syncState: RemotePackSyncState.synced.storageValue,
          currentUserRemoteRole: entry.currentUserRemoteRole,
          currentUserRemoteStatus: entry.currentUserRemoteStatus,
          lastRemoteSnapshotAt: entry.lastRemoteSnapshotAt,
          lastSuccessfulSyncAt: entry.lastSuccessfulSyncAt,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
    } else {
      await _dao.updateRemotePackSyncMetadata(existing.id, entry);
    }
  }

  Future<void> _upsertItemMappingAndMetadata({
    required RemoteItemSnapshot snapshot,
    required int localPackId,
    required int localItemId,
  }) async {
    final now = _clock();
    await _upsertSyncMapping(
      localEntityType: RemoteSharedPackRepository.localEntityItem,
      localEntityId: localItemId,
      remoteTable: RemoteSharedPackRepository.remoteTableItems,
      remoteEntityId: snapshot.id,
      now: now,
    );
    final syncState = switch (snapshot.status) {
      'archived' => RemoteItemSyncState.archived,
      'deleted' => RemoteItemSyncState.deleted,
      _ => RemoteItemSyncState.synced,
    };
    final existing = await _dao.getRemoteItemSyncMetadataForLocalItem(
      localItemId,
    );
    if (existing == null) {
      await _dao.insertRemoteItemSyncMetadata(
        RemoteItemSyncMetadataCompanion.insert(
          localItemId: localItemId,
          localPackId: localPackId,
          remoteItemId: snapshot.id,
          remotePackId: snapshot.packId,
          syncState: syncState.storageValue,
          remoteStatus: Value(snapshot.status),
          remoteUpdatedAt: Value(_millis(snapshot.updatedAt)),
          lastPulledAt: Value(now.millisecondsSinceEpoch),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
    } else {
      await _dao.updateRemoteItemSyncMetadata(
        existing.id,
        RemoteItemSyncMetadataCompanion(
          syncState: Value(syncState.storageValue),
          remoteStatus: Value(snapshot.status),
          remoteUpdatedAt: Value(_millis(snapshot.updatedAt)),
          lastPulledAt: Value(now.millisecondsSinceEpoch),
          lastSyncError: const Value(null),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
    }
  }

  Future<void> _upsertCompletionMappingAndMetadata({
    required RemoteItemCompletionSnapshot snapshot,
    required int localPackId,
    required int localItemId,
    required int localCompletionId,
  }) async {
    final now = _clock();
    await _upsertSyncMapping(
      localEntityType: localEntityCompletion,
      localEntityId: localCompletionId,
      remoteTable: remoteTableCompletions,
      remoteEntityId: snapshot.id,
      now: now,
    );
    final completionState = snapshot.undoneAt == null
        ? RemoteCompletionState.remoteImported
        : RemoteCompletionState.undoneRemote;
    final existing = await _dao
        .getRemoteCompletionSyncMetadataForRemoteCompletion(snapshot.id);
    if (existing == null) {
      await _dao.insertRemoteCompletionSyncMetadata(
        RemoteCompletionSyncMetadataCompanion.insert(
          localCompletionId: Value(localCompletionId),
          localItemId: localItemId,
          localPackId: localPackId,
          remoteCompletionId: Value(snapshot.id),
          remoteItemId: snapshot.itemId,
          remotePackId: snapshot.packId,
          syncState: RemoteCompletionSyncState.synced.storageValue,
          completionState: completionState.storageValue,
          clientMutationId: Value(snapshot.clientMutationId),
          remoteCompletedByUserId: Value(snapshot.completedByUserId),
          remoteCompletedAt: Value(_millis(snapshot.completedAt)),
          remoteUndoneByUserId: Value(snapshot.undoneByUserId),
          remoteUndoneAt: Value(_millisOrNull(snapshot.undoneAt)),
          lastPulledAt: Value(now.millisecondsSinceEpoch),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
    } else {
      await _dao.updateRemoteCompletionSyncMetadata(
        existing.id,
        RemoteCompletionSyncMetadataCompanion(
          localCompletionId: Value(localCompletionId),
          syncState: Value(RemoteCompletionSyncState.synced.storageValue),
          completionState: Value(completionState.storageValue),
          clientMutationId: Value(snapshot.clientMutationId),
          remoteCompletedByUserId: Value(snapshot.completedByUserId),
          remoteCompletedAt: Value(_millis(snapshot.completedAt)),
          remoteUndoneByUserId: Value(snapshot.undoneByUserId),
          remoteUndoneAt: Value(_millisOrNull(snapshot.undoneAt)),
          lastPulledAt: Value(now.millisecondsSinceEpoch),
          lastSyncError: const Value(null),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
    }
  }

  Future<int> _upsertSyncMapping({
    required String localEntityType,
    required int localEntityId,
    required String remoteTable,
    required String remoteEntityId,
    required DateTime now,
  }) {
    return _dao.upsertSyncMapping(
      SyncMappingsCompanion.insert(
        localEntityType: localEntityType,
        localEntityId: localEntityId,
        remoteTable: remoteTable,
        remoteEntityId: remoteEntityId,
        syncState: SyncMappingState.linked.storageValue,
        lastPulledAt: Value(now.millisecondsSinceEpoch),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<int?> _findLocalEntityId({
    required String localEntityType,
    required String remoteTable,
    required String remoteEntityId,
  }) async {
    final mapping = await _dao.getSyncMappingByRemote(
      localEntityType: localEntityType,
      remoteTable: remoteTable,
      remoteEntityId: remoteEntityId,
    );
    if (mapping != null) {
      return mapping.localEntityId;
    }
    if (localEntityType == RemoteSharedPackRepository.localEntityItem) {
      final metadata = await _dao.getRemoteItemSyncMetadataForRemoteItem(
        remoteEntityId,
      );
      return metadata?.localItemId;
    }
    if (localEntityType == localEntityCompletion) {
      final metadata = await _dao
          .getRemoteCompletionSyncMetadataForRemoteCompletion(remoteEntityId);
      return metadata?.localCompletionId;
    }
    return null;
  }

  Future<LocalUser> _ensureRemoteUser({
    required String remoteUserId,
    required String? displayName,
    required LocalUser currentUser,
  }) async {
    if (currentUser.remoteUserId == remoteUserId) {
      return currentUser;
    }
    final existing = await _dao.getLocalUserByRemoteUserId(remoteUserId);
    if (existing != null) {
      return existing;
    }
    final id = '$_placeholderPrefix${_safeIdentifier(remoteUserId)}';
    final byId = await _dao.getLocalUserById(id);
    if (byId != null) {
      return byId;
    }
    final now = _clock().millisecondsSinceEpoch;
    await _dao.insertLocalUser(
      LocalUsersCompanion.insert(
        id: id,
        displayName: displayName ?? 'Remote member ${_shortId(remoteUserId)}',
        identityKind: Value(LocalUserIdentityKind.placeholder.storageValue),
        remoteUserId: Value(remoteUserId),
        isPrimary: const Value(false),
        createdAt: now,
        updatedAt: Value(now),
      ),
    );
    return (await _dao.getLocalUserById(id))!;
  }

  Future<LocalUser> _ensureSystemActor() async {
    const id = 'remote_system_actor';
    final existing = await _dao.getLocalUserById(id);
    if (existing != null) {
      return existing;
    }
    final now = _clock().millisecondsSinceEpoch;
    await _dao.insertLocalUser(
      LocalUsersCompanion.insert(
        id: id,
        displayName: 'Remote system',
        identityKind: Value(LocalUserIdentityKind.placeholder.storageValue),
        isPrimary: const Value(false),
        createdAt: now,
        updatedAt: Value(now),
      ),
    );
    return (await _dao.getLocalUserById(id))!;
  }

  int? _activityEntityId({
    required RemoteActivityEventSnapshot event,
    required int localPackId,
    required Map<String, int> itemIdsByRemoteId,
    required Map<String, int> completionIdsByRemoteId,
  }) {
    return switch (event.entityType) {
      'pack' => localPackId,
      'item' => itemIdsByRemoteId[event.entityId],
      'item_completion' => completionIdsByRemoteId[event.entityId],
      _ => null,
    };
  }

  String? _localUserId(Map<String, LocalUser> users, String? remoteUserId) {
    if (remoteUserId == null) {
      return null;
    }
    return users[remoteUserId]?.id;
  }

  ItemPackStatus _localPackStatus(String remoteStatus) {
    return remoteStatus == 'archived'
        ? ItemPackStatus.archived
        : ItemPackStatus.active;
  }

  ItemLifecycleStatus _localItemStatus(String remoteStatus) {
    return switch (remoteStatus) {
      'archived' || 'deleted' => ItemLifecycleStatus.archived,
      _ => ItemLifecycleStatus.active,
    };
  }

  PackMemberRole _localMemberRole(String remoteRole) {
    return remoteRole == 'host' ? PackMemberRole.host : PackMemberRole.member;
  }

  PackMemberStatus _localMemberStatus(String remoteStatus) {
    return remoteStatus == 'removed'
        ? PackMemberStatus.removed
        : PackMemberStatus.active;
  }

  String? _encodeMap(Map<String, Object?>? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return jsonEncode(value);
  }

  int _millis(DateTime dateTime) => dateTime.millisecondsSinceEpoch;

  int? _millisOrNull(DateTime? dateTime) => dateTime?.millisecondsSinceEpoch;

  String _safeIdentifier(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }

  String _shortId(String value) {
    return value.length <= 8 ? value : value.substring(0, 8);
  }

  static const _placeholderPrefix = 'remote_placeholder_';
}
