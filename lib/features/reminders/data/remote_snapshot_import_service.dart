import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/attention_policy.dart';
import '../domain/item.dart';
import '../domain/item_action_record.dart';
import '../domain/item_pack.dart';
import '../domain/remote_sync.dart';
import '../domain/resource.dart';
import '../domain/shared_pack.dart';
import '../domain/stage_record.dart';
import '../domain/stage_rule.dart';
import '../domain/stage_tracker.dart';
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
  static const localEntityResourceEvent = 'resource_event';
  static const localEntityActivity = 'activity_event';
  static const localEntityStageAcknowledgement = 'stage_acknowledgement';
  static const remoteTableCompletions = 'item_completions';
  static const remoteTableResourceEvents = 'resource_events';
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
        final snapshotLocalUserIds = <String>{};
        for (final member in snapshot.members) {
          final before = await _dao.getLocalUserByRemoteUserId(member.userId);
          final localUser = await _ensureRemoteUser(
            remoteUserId: member.userId,
            displayName: member.displayName,
            currentUser: currentUser,
          );
          userMap[member.userId] = localUser;
          snapshotLocalUserIds.add(localUser.id);
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
        final localMembers = await _dao.listPackMembers(packId);
        for (final member in localMembers) {
          if (member.status == PackMemberStatus.active &&
              !snapshotLocalUserIds.contains(member.userId)) {
            final updated = await _dao.updatePackMemberStatus(
              packId: packId,
              userId: member.userId,
              status: PackMemberStatus.removed,
            );
            if (updated) {
              membersUpdated++;
            }
          }
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

        final resourceIdsByRemoteId = <String, int>{};
        for (final resource in snapshot.resources) {
          final existingId = await _findLocalEntityId(
            localEntityType: RemoteSharedPackRepository.localEntityResource,
            remoteTable: RemoteSharedPackRepository.remoteTableResources,
            remoteEntityId: resource.id,
          );
          final localResourceId =
              existingId ??
              await _insertLocalResource(
                snapshot: resource,
                localPackId: packId,
              );
          if (existingId == null) {
            itemsCreated++;
          } else {
            itemsUpdated++;
            await _updateLocalResource(
              localResourceId: localResourceId,
              snapshot: resource,
            );
          }
          resourceIdsByRemoteId[resource.id] = localResourceId;
          await _upsertResourceMappingAndMetadata(
            snapshot: resource,
            localPackId: packId,
            localResourceId: localResourceId,
          );
        }

        final stageTrackerIdsByRemoteId = <String, int>{};
        for (final tracker in snapshot.stageTrackers) {
          final existingId = await _findLocalEntityId(
            localEntityType: RemoteSharedPackRepository.localEntityStageTracker,
            remoteTable: RemoteSharedPackRepository.remoteTableStageTrackers,
            remoteEntityId: tracker.id,
          );
          final localTrackerId =
              existingId ??
              await _insertLocalStageTracker(
                snapshot: tracker,
                localPackId: packId,
              );
          if (existingId == null) {
            itemsCreated++;
          } else {
            itemsUpdated++;
            await _updateLocalStageTracker(
              localStageTrackerId: localTrackerId,
              snapshot: tracker,
              localPackId: packId,
            );
          }
          stageTrackerIdsByRemoteId[tracker.id] = localTrackerId;
          await _upsertStageMappingAndMetadata(
            localEntityType: RemoteSharedPackRepository.localEntityStageTracker,
            remoteTable: RemoteSharedPackRepository.remoteTableStageTrackers,
            localEntityId: localTrackerId,
            localPackId: packId,
            remoteEntityId: tracker.id,
            remotePackId: tracker.packId,
            remoteStatus: tracker.status,
            remoteUpdatedAt: tracker.updatedAt,
          );
        }

        final stageRuleIdsByRemoteId = <String, int>{};
        for (final rule in snapshot.stageRules) {
          final localTrackerId = stageTrackerIdsByRemoteId[rule.stageTrackerId];
          if (localTrackerId == null) {
            skipped++;
            warnings.add(
              'Skipped stage rule ${rule.id}: remote tracker is not mapped.',
            );
            continue;
          }
          final existingId = await _findLocalEntityId(
            localEntityType: RemoteSharedPackRepository.localEntityStageRule,
            remoteTable: RemoteSharedPackRepository.remoteTableStageRules,
            remoteEntityId: rule.id,
          );
          final localRuleId =
              existingId ??
              await _insertLocalStageRule(
                snapshot: rule,
                localStageTrackerId: localTrackerId,
              );
          if (existingId == null) {
            itemsCreated++;
          } else {
            itemsUpdated++;
            await _updateLocalStageRule(
              localStageRuleId: localRuleId,
              localStageTrackerId: localTrackerId,
              snapshot: rule,
            );
          }
          stageRuleIdsByRemoteId[rule.id] = localRuleId;
          await _upsertStageMappingAndMetadata(
            localEntityType: RemoteSharedPackRepository.localEntityStageRule,
            remoteTable: RemoteSharedPackRepository.remoteTableStageRules,
            localEntityId: localRuleId,
            localPackId: packId,
            remoteEntityId: rule.id,
            remotePackId: rule.packId,
            remoteStatus: rule.status,
            remoteUpdatedAt: rule.updatedAt,
          );
        }

        final stageRecordIdsByRemoteId = <String, int>{};
        for (final record in snapshot.stageRecords) {
          final localTrackerId =
              stageTrackerIdsByRemoteId[record.stageTrackerId];
          if (localTrackerId == null) {
            skipped++;
            warnings.add(
              'Skipped stage record ${record.id}: remote tracker is not mapped.',
            );
            continue;
          }
          final localRuleId = record.stageRuleId == null
              ? null
              : stageRuleIdsByRemoteId[record.stageRuleId];
          final existingId = await _findLocalEntityId(
            localEntityType: RemoteSharedPackRepository.localEntityStageRecord,
            remoteTable: RemoteSharedPackRepository.remoteTableStageRecords,
            remoteEntityId: record.id,
          );
          final localRecordId =
              existingId ??
              await _insertLocalStageRecord(
                snapshot: record,
                localStageTrackerId: localTrackerId,
                localStageRuleId: localRuleId,
              );
          if (existingId == null) {
            itemsCreated++;
          } else {
            itemsUpdated++;
            await _updateLocalStageRecord(
              localStageRecordId: localRecordId,
              localStageTrackerId: localTrackerId,
              localStageRuleId: localRuleId,
              snapshot: record,
            );
          }
          stageRecordIdsByRemoteId[record.id] = localRecordId;
          await _upsertStageMappingAndMetadata(
            localEntityType: RemoteSharedPackRepository.localEntityStageRecord,
            remoteTable: RemoteSharedPackRepository.remoteTableStageRecords,
            localEntityId: localRecordId,
            localPackId: packId,
            remoteEntityId: record.id,
            remotePackId: record.packId,
            remoteStatus: record.status,
            remoteUpdatedAt: record.updatedAt,
          );
        }

        for (final acknowledgement in snapshot.stageAcknowledgements) {
          final localStageRecordId =
              stageRecordIdsByRemoteId[acknowledgement.stageRecordId];
          if (localStageRecordId == null) {
            skipped++;
            warnings.add(
              'Skipped stage acknowledgement ${acknowledgement.id}: remote stage record is not mapped.',
            );
            continue;
          }
          final user = await _ensureRemoteUser(
            remoteUserId: acknowledgement.userId,
            displayName: null,
            currentUser: currentUser,
          );
          final existingId = await _findLocalEntityId(
            localEntityType: localEntityStageAcknowledgement,
            remoteTable:
                RemoteSharedPackRepository.remoteTableStageAcknowledgements,
            remoteEntityId: acknowledgement.id,
          );
          await _dao.upsertStageAcknowledgement(
            StageAcknowledgementsCompanion.insert(
              stageRecordId: localStageRecordId,
              packId: packId,
              userId: user.id,
              acknowledgedAt: _millis(acknowledgement.acknowledgedAt),
            ),
          );
          final rows = await _dao.listStageAcknowledgementsForRecord(
            localStageRecordId,
          );
          StageAcknowledgement? localAcknowledgement;
          for (final row in rows) {
            if (row.userId == user.id) {
              localAcknowledgement = row;
              break;
            }
          }
          if (localAcknowledgement != null) {
            await _upsertSyncMapping(
              localEntityType: localEntityStageAcknowledgement,
              localEntityId: localAcknowledgement.id,
              remoteTable:
                  RemoteSharedPackRepository.remoteTableStageAcknowledgements,
              remoteEntityId: acknowledgement.id,
              now: _clock(),
            );
          }
          existingId == null ? activityCreated++ : activityUpdated++;
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
            await _updateLocalCompletion(
              localCompletionId: localCompletionId,
              snapshot: completion,
              undoneByUserId: undoneBy?.id,
            );
          }
          await _projectRemoteCompletionUndo(
            localCompletionId: localCompletionId,
            snapshot: completion,
            undoneByUserId: undoneBy?.id,
          );
          completionIdsByRemoteId[completion.id] = localCompletionId;
          await _upsertCompletionMappingAndMetadata(
            snapshot: completion,
            localPackId: packId,
            localItemId: localItemId,
            localCompletionId: localCompletionId,
          );
        }

        for (final event in snapshot.resourceEvents) {
          final localResourceId = resourceIdsByRemoteId[event.resourceId];
          if (localResourceId == null) {
            skipped++;
            warnings.add(
              'Skipped resource event ${event.id}: remote resource is not mapped.',
            );
            continue;
          }
          final existingId = await _findLocalEntityId(
            localEntityType: localEntityResourceEvent,
            remoteTable: remoteTableResourceEvents,
            remoteEntityId: event.id,
          );
          if (existingId != null) {
            activityUpdated++;
            continue;
          }
          final actor = await _ensureRemoteUser(
            remoteUserId: event.actorUserId,
            displayName: null,
            currentUser: currentUser,
          );
          final localEventId = await _insertLocalResourceEvent(
            snapshot: event,
            localPackId: packId,
            localResourceId: localResourceId,
            actorUserId: actor.id,
          );
          await _insertLocalResourceActionFromEvent(
            snapshot: event,
            localResourceId: localResourceId,
          );
          await _upsertSyncMapping(
            localEntityType: localEntityResourceEvent,
            localEntityId: localEventId,
            remoteTable: remoteTableResourceEvents,
            remoteEntityId: event.id,
            now: _clock(),
          );
          activityCreated++;
        }

        for (final event in snapshot.activityEvents) {
          final localEntityId = _activityEntityId(
            event: event,
            localPackId: packId,
            itemIdsByRemoteId: itemIdsByRemoteId,
            resourceIdsByRemoteId: resourceIdsByRemoteId,
            completionIdsByRemoteId: completionIdsByRemoteId,
            stageTrackerIdsByRemoteId: stageTrackerIdsByRemoteId,
            stageRuleIdsByRemoteId: stageRuleIdsByRemoteId,
            stageRecordIdsByRemoteId: stageRecordIdsByRemoteId,
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

  Future<int> _insertLocalResource({
    required RemoteResourceSnapshot snapshot,
    required int localPackId,
  }) {
    return _dao.insertResource(
      ResourcesCompanion.insert(
        packId: localPackId,
        title: snapshot.title,
        description: Value(snapshot.description),
        status: Value(_localResourceStatus(snapshot.status).name),
        type: _localResourceType(snapshot.type).name,
        timeAnchorDate: Value(_millisOrNull(snapshot.timeAnchorDate)),
        timeDurationDays: Value(snapshot.timeDurationDays),
        timeExpectedBeforeDays: Value(snapshot.timeExpectedBeforeDays),
        timeWarningBeforeDays: Value(snapshot.timeWarningBeforeDays),
        timeDangerBeforeDays: Value(snapshot.timeDangerBeforeDays),
        quantityCurrent: Value(snapshot.quantityCurrent),
        quantityUnitLabel: Value(snapshot.quantityUnitLabel),
        quantityExpectedThreshold: Value(snapshot.quantityExpectedThreshold),
        quantityWarningThreshold: Value(snapshot.quantityWarningThreshold),
        quantityDangerThreshold: Value(snapshot.quantityDangerThreshold),
        lastRefilledAt: Value(_millisOrNull(snapshot.lastRefilledAt)),
        createdAt: _millis(snapshot.createdAt),
        updatedAt: _millis(snapshot.updatedAt),
      ),
    );
  }

  Future<void> _updateLocalResource({
    required int localResourceId,
    required RemoteResourceSnapshot snapshot,
  }) async {
    await _dao.updateResourceFields(
      localResourceId,
      ResourcesCompanion(
        title: Value(snapshot.title),
        description: Value(snapshot.description),
        status: Value(_localResourceStatus(snapshot.status).name),
        timeAnchorDate: Value(_millisOrNull(snapshot.timeAnchorDate)),
        timeDurationDays: Value(snapshot.timeDurationDays),
        timeExpectedBeforeDays: Value(snapshot.timeExpectedBeforeDays),
        timeWarningBeforeDays: Value(snapshot.timeWarningBeforeDays),
        timeDangerBeforeDays: Value(snapshot.timeDangerBeforeDays),
        quantityCurrent: Value(snapshot.quantityCurrent),
        quantityUnitLabel: Value(snapshot.quantityUnitLabel),
        quantityExpectedThreshold: Value(snapshot.quantityExpectedThreshold),
        quantityWarningThreshold: Value(snapshot.quantityWarningThreshold),
        quantityDangerThreshold: Value(snapshot.quantityDangerThreshold),
        lastRefilledAt: Value(_millisOrNull(snapshot.lastRefilledAt)),
        updatedAt: Value(_millis(snapshot.updatedAt)),
      ),
    );
  }

  Future<int> _insertLocalStageTracker({
    required RemoteStageTrackerSnapshot snapshot,
    required int localPackId,
  }) {
    return _dao.insertStageTracker(
      StageTrackersCompanion.insert(
        packId: localPackId,
        title: snapshot.title,
        subjectName: Value(snapshot.subjectName),
        trackingStartDate: _millis(snapshot.trackingStartDate),
        trackingEndDate: Value(_millisOrNull(snapshot.trackingEndDate)),
        status: Value(_localStageTrackerStatus(snapshot.status).name),
        createdAt: _millis(snapshot.createdAt),
        updatedAt: _millis(snapshot.updatedAt),
      ),
    );
  }

  Future<void> _updateLocalStageTracker({
    required int localStageTrackerId,
    required int localPackId,
    required RemoteStageTrackerSnapshot snapshot,
  }) async {
    final current = await _dao.getStageTrackerById(localStageTrackerId);
    if (current == null) {
      return;
    }
    await _dao.updateStageTrackerRecord(
      StageTrackerRow(
        id: localStageTrackerId,
        packId: localPackId,
        title: snapshot.title,
        subjectName: snapshot.subjectName,
        trackingStartDate: _millis(snapshot.trackingStartDate),
        trackingEndDate: _millisOrNull(snapshot.trackingEndDate),
        status: _localStageTrackerStatus(snapshot.status).name,
        isSystemDefault: current.isSystemDefault,
        systemKey: current.systemKey,
        isHidden: current.isHidden,
        createdAt: _millis(snapshot.createdAt),
        updatedAt: _millis(snapshot.updatedAt),
      ),
    );
  }

  Future<int> _insertLocalStageRule({
    required RemoteStageRuleSnapshot snapshot,
    required int localStageTrackerId,
  }) {
    return _dao.insertStageRule(
      StageRulesCompanion.insert(
        stageTrackerId: localStageTrackerId,
        type: _localStageRuleType(snapshot.type).name,
        intervalValue: snapshot.intervalValue,
        intervalUnit: _localStageIntervalUnit(snapshot.intervalUnit).name,
        labelTemplate: Value(snapshot.labelTemplate),
        reminderOffsetDays: Value(snapshot.reminderOffsetDays),
        status: Value(_localStageRuleStatus(snapshot.status).name),
        createdAt: _millis(snapshot.createdAt),
        updatedAt: _millis(snapshot.updatedAt),
      ),
    );
  }

  Future<void> _updateLocalStageRule({
    required int localStageRuleId,
    required int localStageTrackerId,
    required RemoteStageRuleSnapshot snapshot,
  }) async {
    await _dao.updateStageRuleRecord(
      StageRuleRow(
        id: localStageRuleId,
        stageTrackerId: localStageTrackerId,
        type: _localStageRuleType(snapshot.type).name,
        intervalValue: snapshot.intervalValue,
        intervalUnit: _localStageIntervalUnit(snapshot.intervalUnit).name,
        labelTemplate: snapshot.labelTemplate,
        reminderOffsetDays: snapshot.reminderOffsetDays,
        status: _localStageRuleStatus(snapshot.status).name,
        createdAt: _millis(snapshot.createdAt),
        updatedAt: _millis(snapshot.updatedAt),
      ),
    );
  }

  Future<int> _insertLocalStageRecord({
    required RemoteStageRecordSnapshot snapshot,
    required int localStageTrackerId,
    required int? localStageRuleId,
  }) {
    return _dao.insertStageRecord(
      StageRecordsCompanion.insert(
        stageTrackerId: localStageTrackerId,
        stageRuleId: Value(localStageRuleId),
        sourceType: _localStageRecordSourceType(snapshot.sourceType).name,
        occurrenceIndex: Value(snapshot.occurrenceIndex),
        occurrenceDate: _millis(snapshot.occurrenceDate),
        relativeAmount: Value(snapshot.relativeAmount),
        relativeUnit: Value(
          snapshot.relativeUnit == null
              ? null
              : _localStageIntervalUnit(snapshot.relativeUnit!).name,
        ),
        status: Value(_localStageRecordStatus(snapshot.status).name),
        label: snapshot.label,
        note: Value(snapshot.note),
        reminderOffsetDays: Value(snapshot.reminderOffsetDays),
        createdAt: _millis(snapshot.createdAt),
        updatedAt: _millis(snapshot.updatedAt),
      ),
    );
  }

  Future<void> _updateLocalStageRecord({
    required int localStageRecordId,
    required int localStageTrackerId,
    required int? localStageRuleId,
    required RemoteStageRecordSnapshot snapshot,
  }) async {
    await _dao.updateStageRecordRecord(
      StageRecordRow(
        id: localStageRecordId,
        stageTrackerId: localStageTrackerId,
        stageRuleId: localStageRuleId,
        sourceType: _localStageRecordSourceType(snapshot.sourceType).name,
        occurrenceIndex: snapshot.occurrenceIndex,
        occurrenceDate: _millis(snapshot.occurrenceDate),
        relativeAmount: snapshot.relativeAmount,
        relativeUnit: snapshot.relativeUnit == null
            ? null
            : _localStageIntervalUnit(snapshot.relativeUnit!).name,
        status: _localStageRecordStatus(snapshot.status).name,
        label: snapshot.label,
        note: snapshot.note,
        reminderOffsetDays: snapshot.reminderOffsetDays,
        createdAt: _millis(snapshot.createdAt),
        updatedAt: _millis(snapshot.updatedAt),
      ),
    );
  }

  Future<int> _insertLocalResourceEvent({
    required RemoteResourceEventSnapshot snapshot,
    required int localPackId,
    required int localResourceId,
    required String actorUserId,
  }) {
    return _dao.insertResourceEvent(
      ResourceEventsCompanion.insert(
        resourceId: localResourceId,
        packId: localPackId,
        actorUserId: actorUserId,
        changeType: _localResourceEventChangeType(snapshot.changeType).name,
        previousValue: Value(snapshot.previousValue),
        newValue: Value(snapshot.newValue),
        deltaValue: Value(snapshot.deltaValue),
        unit: Value(snapshot.unit),
        createdAt: _millis(snapshot.createdAt),
        metadataJson: Value(
          _encodeMap({
            'remoteResourceEventId': snapshot.id,
            'remoteResourceId': snapshot.resourceId,
            'actorRemoteUserId': snapshot.actorUserId,
            'remoteMetadata': snapshot.metadataJson,
          }),
        ),
      ),
    );
  }

  Future<void> _insertLocalResourceActionFromEvent({
    required RemoteResourceEventSnapshot snapshot,
    required int localResourceId,
  }) async {
    await _dao.insertResourceActionRecord(
      ResourceActionRecordsCompanion.insert(
        resourceId: localResourceId,
        actionType: _resourceActionTypeFromEvent(snapshot).name,
        actionDate: _millis(snapshot.createdAt),
        amount: Value(snapshot.deltaValue?.abs()),
        resultingQuantity: Value(snapshot.newValue),
        remark: Value(_remoteResourceEventRemark(snapshot)),
        createdAt: _millis(snapshot.createdAt),
        updatedAt: _millis(snapshot.createdAt),
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

  Future<void> _updateLocalCompletion({
    required int localCompletionId,
    required RemoteItemCompletionSnapshot snapshot,
    required String? undoneByUserId,
  }) async {
    await _dao.updateItemCompletionFields(
      localCompletionId,
      ItemCompletionsCompanion(
        undoneByUserId: Value(undoneByUserId),
        undoneAt: Value(_millisOrNull(snapshot.undoneAt)),
        clientMutationId: Value(snapshot.clientMutationId),
      ),
    );
  }

  Future<void> _projectRemoteCompletionUndo({
    required int localCompletionId,
    required RemoteItemCompletionSnapshot snapshot,
    required String? undoneByUserId,
  }) async {
    if (snapshot.undoneAt == null || undoneByUserId == null) {
      return;
    }
    final completion = await _dao.getItemCompletionById(localCompletionId);
    if (completion == null) {
      return;
    }
    final doneRecord = await _dao.getItemActionRecordById(
      completion.itemActionRecordId,
    );
    if (doneRecord == null || doneRecord.actionType != ItemActionType.done) {
      return;
    }
    if (doneRecord.isReverted &&
        doneRecord.revertedAt?.isAtSameMomentAs(snapshot.undoneAt!) == true) {
      return;
    }

    final now = _clock();
    var revertedRecordId = doneRecord.revertedByActionRecordId;
    revertedRecordId ??= await _dao.insertItemActionRecord(
      ItemActionRecordsCompanion.insert(
        itemId: doneRecord.itemId,
        actionType: ItemActionType.reverted.name,
        actionDate: snapshot.undoneAt!.millisecondsSinceEpoch,
        payload: Value(
          ItemActionRecord.encodePayload({
            'remoteImported': true,
            'remoteCompletionId': snapshot.id,
            'remoteItemId': snapshot.itemId,
            'remotePackId': snapshot.packId,
            'reason': 'remote_undo',
            'revertedActionRecordId': doneRecord.id,
            'undoneByRemoteUserId': snapshot.undoneByUserId,
          }),
        ),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );

    await _dao.updateItemActionRecordFields(
      doneRecord.id,
      ItemActionRecordsCompanion(
        isReverted: const Value(true),
        revertedAt: Value(snapshot.undoneAt!.millisecondsSinceEpoch),
        revertedByActionRecordId: Value(revertedRecordId),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
    await _dao.markItemCompletionUndoneById(
      completionId: localCompletionId,
      undoneByUserId: undoneByUserId,
      undoneAt: snapshot.undoneAt!,
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
          remoteItemId: Value(snapshot.id),
          remotePackId: Value(snapshot.packId),
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

  Future<void> _upsertResourceMappingAndMetadata({
    required RemoteResourceSnapshot snapshot,
    required int localPackId,
    required int localResourceId,
  }) async {
    final now = _clock();
    await _upsertSyncMapping(
      localEntityType: RemoteSharedPackRepository.localEntityResource,
      localEntityId: localResourceId,
      remoteTable: RemoteSharedPackRepository.remoteTableResources,
      remoteEntityId: snapshot.id,
      now: now,
    );
    final syncState = switch (snapshot.status) {
      'archived' => RemoteResourceSyncState.archived,
      'deleted' => RemoteResourceSyncState.deleted,
      _ => RemoteResourceSyncState.synced,
    };
    final existing = await _dao.getRemoteResourceSyncMetadataForLocalResource(
      localResourceId,
    );
    if (existing == null) {
      await _dao.insertRemoteResourceSyncMetadata(
        RemoteResourceSyncMetadataCompanion.insert(
          localResourceId: localResourceId,
          localPackId: localPackId,
          remoteResourceId: snapshot.id,
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
      await _dao.updateRemoteResourceSyncMetadata(
        existing.id,
        RemoteResourceSyncMetadataCompanion(
          syncState: Value(syncState.storageValue),
          remoteStatus: Value(snapshot.status),
          remoteUpdatedAt: Value(_millis(snapshot.updatedAt)),
          lastPulledAt: Value(now.millisecondsSinceEpoch),
          lastSyncError: const Value(null),
          archivedAt: syncState == RemoteResourceSyncState.archived
              ? Value(_millis(snapshot.updatedAt))
              : const Value.absent(),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
    }
  }

  Future<void> _upsertStageMappingAndMetadata({
    required String localEntityType,
    required String remoteTable,
    required int localEntityId,
    required int localPackId,
    required String remoteEntityId,
    required String remotePackId,
    required String remoteStatus,
    required DateTime remoteUpdatedAt,
  }) async {
    final now = _clock();
    await _upsertSyncMapping(
      localEntityType: localEntityType,
      localEntityId: localEntityId,
      remoteTable: remoteTable,
      remoteEntityId: remoteEntityId,
      now: now,
    );
    final syncState = switch (remoteStatus) {
      'archived' => RemoteStageSyncState.archived,
      'deleted' => RemoteStageSyncState.deleted,
      _ => RemoteStageSyncState.synced,
    };
    final existing = await _dao.getRemoteStageSyncMetadataForLocalEntity(
      localEntityType: localEntityType,
      localEntityId: localEntityId,
    );
    if (existing == null) {
      await _dao.insertRemoteStageSyncMetadata(
        RemoteStageSyncMetadataCompanion.insert(
          localEntityType: localEntityType,
          localEntityId: localEntityId,
          localPackId: localPackId,
          remoteEntityId: remoteEntityId,
          remotePackId: remotePackId,
          syncState: syncState.storageValue,
          remoteStatus: Value(remoteStatus),
          remoteUpdatedAt: Value(_millis(remoteUpdatedAt)),
          lastPulledAt: Value(now.millisecondsSinceEpoch),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
          archivedAt: syncState == RemoteStageSyncState.archived
              ? Value(_millis(remoteUpdatedAt))
              : const Value.absent(),
        ),
      );
      return;
    }
    await _dao.updateRemoteStageSyncMetadata(
      existing.id,
      RemoteStageSyncMetadataCompanion(
        remoteEntityId: Value(remoteEntityId),
        remotePackId: Value(remotePackId),
        syncState: Value(syncState.storageValue),
        remoteStatus: Value(remoteStatus),
        remoteUpdatedAt: Value(_millis(remoteUpdatedAt)),
        lastPulledAt: Value(now.millisecondsSinceEpoch),
        lastSyncError: const Value(null),
        archivedAt: syncState == RemoteStageSyncState.archived
            ? Value(_millis(remoteUpdatedAt))
            : const Value.absent(),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
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
    if (localEntityType == RemoteSharedPackRepository.localEntityResource) {
      final metadata = await _dao
          .getRemoteResourceSyncMetadataForRemoteResource(remoteEntityId);
      return metadata?.localResourceId;
    }
    if (localEntityType == RemoteSharedPackRepository.localEntityStageTracker ||
        localEntityType == RemoteSharedPackRepository.localEntityStageRule ||
        localEntityType == RemoteSharedPackRepository.localEntityStageRecord) {
      final metadata = await _dao.getRemoteStageSyncMetadataForRemoteEntity(
        localEntityType: localEntityType,
        remoteEntityId: remoteEntityId,
      );
      return metadata?.localEntityId;
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
    required Map<String, int> resourceIdsByRemoteId,
    required Map<String, int> completionIdsByRemoteId,
    required Map<String, int> stageTrackerIdsByRemoteId,
    required Map<String, int> stageRuleIdsByRemoteId,
    required Map<String, int> stageRecordIdsByRemoteId,
  }) {
    return switch (event.entityType) {
      'pack' => localPackId,
      'item' => itemIdsByRemoteId[event.entityId],
      'resource' => resourceIdsByRemoteId[event.entityId],
      'item_completion' => completionIdsByRemoteId[event.entityId],
      'stage_tracker' => stageTrackerIdsByRemoteId[event.entityId],
      'stage_rule' => stageRuleIdsByRemoteId[event.entityId],
      'stage_record' || 'stage' => stageRecordIdsByRemoteId[event.entityId],
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

  ResourceLifecycleStatus _localResourceStatus(String remoteStatus) {
    return switch (remoteStatus) {
      'archived' || 'deleted' => ResourceLifecycleStatus.archived,
      'paused' => ResourceLifecycleStatus.paused,
      _ => ResourceLifecycleStatus.active,
    };
  }

  ResourceType _localResourceType(String remoteType) {
    return remoteType == ResourceType.timeBased.name ||
            remoteType == 'time_based'
        ? ResourceType.timeBased
        : ResourceType.quantityBased;
  }

  ResourceEventChangeType _localResourceEventChangeType(String remoteType) {
    return switch (remoteType) {
      'increment' ||
      'refill' ||
      'refilled' => ResourceEventChangeType.increment,
      'decrement' ||
      'consume' ||
      'consumed' => ResourceEventChangeType.decrement,
      _ => ResourceEventChangeType.adjust,
    };
  }

  ResourceActionType _resourceActionTypeFromEvent(
    RemoteResourceEventSnapshot snapshot,
  ) {
    final action = snapshot.metadataJson?['resource_action'];
    if (action is String) {
      return switch (action) {
        'refilled' => ResourceActionType.refilled,
        'consumed' => ResourceActionType.consumed,
        'reverted' => ResourceActionType.reverted,
        _ => ResourceActionType.adjusted,
      };
    }
    return switch (_localResourceEventChangeType(snapshot.changeType)) {
      ResourceEventChangeType.increment => ResourceActionType.refilled,
      ResourceEventChangeType.decrement => ResourceActionType.adjusted,
      ResourceEventChangeType.adjust => ResourceActionType.adjusted,
    };
  }

  String? _remoteResourceEventRemark(RemoteResourceEventSnapshot snapshot) {
    final remark = snapshot.metadataJson?['remark'];
    return remark is String && remark.trim().isNotEmpty ? remark : null;
  }

  StageTrackerStatus _localStageTrackerStatus(String remoteStatus) {
    return remoteStatus == 'archived'
        ? StageTrackerStatus.archived
        : StageTrackerStatus.active;
  }

  StageRuleStatus _localStageRuleStatus(String remoteStatus) {
    return switch (remoteStatus) {
      'archived' => StageRuleStatus.archived,
      'paused' => StageRuleStatus.paused,
      _ => StageRuleStatus.active,
    };
  }

  StageRecordStatus _localStageRecordStatus(String remoteStatus) {
    return switch (remoteStatus) {
      'archived' => StageRecordStatus.archived,
      'ignored' => StageRecordStatus.ignored,
      'acknowledged' => StageRecordStatus.acknowledged,
      _ => StageRecordStatus.normal,
    };
  }

  StageRuleType _localStageRuleType(String remoteType) {
    return switch (remoteType) {
      'every_n_weeks' || 'everyNWeeks' => StageRuleType.everyNWeeks,
      'every_n_months' || 'everyNMonths' => StageRuleType.everyNMonths,
      'every_n_years' || 'everyNYears' => StageRuleType.everyNYears,
      _ => StageRuleType.everyNDays,
    };
  }

  StageIntervalUnit _localStageIntervalUnit(String remoteUnit) {
    return switch (remoteUnit) {
      'weeks' => StageIntervalUnit.weeks,
      'months' => StageIntervalUnit.months,
      'years' => StageIntervalUnit.years,
      _ => StageIntervalUnit.days,
    };
  }

  StageRecordSourceType _localStageRecordSourceType(String remoteSourceType) {
    return remoteSourceType == 'manual'
        ? StageRecordSourceType.manual
        : StageRecordSourceType.generated;
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
