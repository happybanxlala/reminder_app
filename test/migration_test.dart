import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';

void main() {
  test('database uses schema version 7 and core tables are writable', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 7);

    final appInstallationId = await db
        .into(db.appInstallations)
        .insert(
          AppInstallationsCompanion.insert(
            installationGuid: '11111111-1111-4111-8111-111111111111',
            createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            lastSeenAt: DateTime(2026, 4, 2).millisecondsSinceEpoch,
          ),
        );

    final packId = await db
        .into(db.itemPacks)
        .insert(
          ItemPacksCompanion.insert(
            title: 'Cats',
            description: const Value('Cat care'),
            status: const Value('active'),
            isSystemDefault: const Value(false),
            createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
          ),
        );

    final itemId = await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            packId: packId,
            title: 'Clean litter box',
            description: const Value('State based'),
            type: 'stateBased',
            attentionPolicySource: const Value('systemDefault'),
            fixedScheduleType: const Value.absent(),
            fixedScheduleInterval: const Value.absent(),
            fixedMonthlyDay: const Value.absent(),
            fixedRepeatRuleV2: const Value.absent(),
            fixedAnchorDate: const Value.absent(),
            fixedDueDate: const Value.absent(),
            fixedTimeOfDay: const Value.absent(),
            fixedOverduePolicy: const Value.absent(),
            fixedExpectedBeforeMinutes: const Value.absent(),
            fixedWarningBeforeMinutes: const Value.absent(),
            fixedDangerBeforeMinutes: const Value.absent(),
            stateAnchorDate: const Value.absent(),
            stateExpectedAfterMinutes: const Value(2880),
            stateWarningAfterMinutes: const Value(2880),
            stateDangerAfterMinutes: const Value(5760),
            lastDoneAt: const Value.absent(),
            createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
          ),
        );

    final templateId = await db
        .into(db.packTemplates)
        .insert(
          PackTemplatesCompanion.insert(
            templateName: '家務',
            iconEmoji: const Value('🏠'),
            description: const Value('定期清潔'),
            createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
          ),
        );
    final templateItemId = await db
        .into(db.packTemplateItems)
        .insert(
          PackTemplateItemsCompanion.insert(
            templateId: templateId,
            orderIndex: const Value(0),
            title: '倒垃圾',
            type: 'fixed',
            fixedScheduleType: const Value('everyXDays'),
            fixedScheduleInterval: const Value(2),
            fixedWarningBeforeMinutes: const Value(1440),
            fixedDangerBeforeMinutes: const Value(0),
            createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
          ),
        );

    final resourceId = await db
        .into(db.resources)
        .insert(
          ResourcesCompanion.insert(
            packId: packId,
            title: 'Water filter',
            type: 'quantityBased',
            quantityCurrent: const Value(5),
            quantityUnitLabel: const Value('個'),
            quantityWarningThreshold: const Value(2),
            quantityDangerThreshold: const Value(1),
            createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
          ),
        );
    final consumptionRuleId = await db
        .into(db.resourceConsumptionRules)
        .insert(
          ResourceConsumptionRulesCompanion.insert(
            resourceId: resourceId,
            itemId: itemId,
            consumeAmount: const Value(1),
            createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
          ),
        );
    final resourceActionId = await db
        .into(db.resourceActionRecords)
        .insert(
          ResourceActionRecordsCompanion.insert(
            resourceId: resourceId,
            actionType: 'created',
            actionDate: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            resultingQuantity: const Value(5),
            createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
          ),
        );

    final stageTrackerId = await db
        .into(db.stageTrackers)
        .insert(
          StageTrackersCompanion.insert(
            packId: packId,
            title: 'Stage smoke test',
            trackingStartDate: DateTime(2026, 4, 10).millisecondsSinceEpoch,
            status: const Value('active'),
            createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
          ),
        );

    final ruleId = await db
        .into(db.stageRules)
        .insert(
          StageRulesCompanion.insert(
            stageTrackerId: stageTrackerId,
            type: 'every_n_days',
            intervalValue: 1,
            intervalUnit: 'days',
            labelTemplate: const Value('第 {value}{unit}'),
            reminderOffsetDays: const Value(0),
            status: const Value('active'),
            createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
          ),
        );

    final recordId = await db
        .into(db.stageRecords)
        .insert(
          StageRecordsCompanion.insert(
            stageTrackerId: stageTrackerId,
            stageRuleId: Value(ruleId),
            sourceType: 'generated',
            occurrenceIndex: const Value(1),
            occurrenceDate: DateTime(2026, 4, 10).millisecondsSinceEpoch,
            status: const Value('acknowledged'),
            label: '滿 1 天',
            createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            updatedAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
          ),
        );

    final completionId = await db
        .into(db.itemCompletions)
        .insert(
          ItemCompletionsCompanion.insert(
            itemId: itemId,
            packId: packId,
            itemActionRecordId: await db
                .into(db.itemActionRecords)
                .insert(
                  ItemActionRecordsCompanion.insert(
                    itemId: itemId,
                    actionType: 'done',
                    actionDate: DateTime(2026, 4, 10).millisecondsSinceEpoch,
                    createdAt: DateTime(2026, 4, 10).millisecondsSinceEpoch,
                    updatedAt: DateTime(2026, 4, 10).millisecondsSinceEpoch,
                  ),
                ),
            completedByUserId: AppDatabase.defaultHostUserId,
            completedAt: DateTime(2026, 4, 10).millisecondsSinceEpoch,
            createdAt: DateTime(2026, 4, 10).millisecondsSinceEpoch,
          ),
        );
    final resourceEventId = await db
        .into(db.resourceEvents)
        .insert(
          ResourceEventsCompanion.insert(
            resourceId: resourceId,
            packId: packId,
            actorUserId: AppDatabase.defaultHostUserId,
            changeType: 'adjust',
            previousValue: const Value(4),
            newValue: const Value(5),
            createdAt: DateTime(2026, 4, 10).millisecondsSinceEpoch,
          ),
        );
    final stageAcknowledgementId = await db
        .into(db.stageAcknowledgements)
        .insert(
          StageAcknowledgementsCompanion.insert(
            stageRecordId: recordId,
            packId: packId,
            userId: AppDatabase.defaultHostUserId,
            acknowledgedAt: DateTime(2026, 4, 10).millisecondsSinceEpoch,
          ),
        );
    final activityEventId = await db
        .into(db.activityEvents)
        .insert(
          ActivityEventsCompanion.insert(
            packId: packId,
            actorUserId: AppDatabase.defaultHostUserId,
            entityType: 'item',
            entityId: itemId,
            action: 'item_completed',
            createdAt: DateTime(2026, 4, 10).millisecondsSinceEpoch,
          ),
        );

    expect(packId, greaterThan(0));
    expect(appInstallationId, greaterThan(0));
    expect(itemId, greaterThan(0));
    expect(templateId, greaterThan(0));
    expect(templateItemId, greaterThan(0));
    expect(resourceId, greaterThan(0));
    expect(consumptionRuleId, greaterThan(0));
    expect(resourceActionId, greaterThan(0));
    expect(stageTrackerId, greaterThan(0));
    expect(ruleId, greaterThan(0));
    expect(recordId, greaterThan(0));
    expect(completionId, greaterThan(0));
    expect(resourceEventId, greaterThan(0));
    expect(stageAcknowledgementId, greaterThan(0));
    expect(activityEventId, greaterThan(0));

    await db
        .into(db.appSettingsEntries)
        .insertOnConflictUpdate(
          AppSettingsEntriesCompanion.insert(
            id: const Value(1),
            reminderTone: const Value('early'),
            notificationReminderTime: const Value('20:30'),
            createdAt: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            updatedAt: DateTime(2026, 4, 2).millisecondsSinceEpoch,
          ),
        );

    final defaultPacks = await (db.select(
      db.itemPacks,
    )..where((t) => t.isSystemDefault.equals(true))).get();
    final items = await db.select(db.items).get();
    final packs = await db.select(db.itemPacks).get();
    final localUsers = await db.select(db.localUsers).get();
    final appInstallations = await db.select(db.appInstallations).get();
    final stageTrackers = await db.select(db.stageTrackers).get();
    final settings = await db.select(db.appSettingsEntries).get();
    final templates = await db.select(db.packTemplates).get();
    final templateItems = await db.select(db.packTemplateItems).get();
    expect(defaultPacks, hasLength(1));
    expect(localUsers.first.identityKind, 'local');
    expect(localUsers.first.remoteUserId, null);
    expect(appInstallations, isNotEmpty);
    expect(packs.firstWhere((pack) => pack.id == packId).packType, 'personal');
    expect(packs.firstWhere((pack) => pack.id == packId).hostUserId, null);
    expect(items.single.status, 'active');
    expect(items.single.assignedToUserId, null);
    expect(items.single.attentionPolicySource, 'systemDefault');
    expect(
      stageTrackers.where((tracker) => tracker.systemKey == 'reminder_app'),
      hasLength(1),
    );
    expect(
      stageTrackers
          .firstWhere((tracker) => tracker.id == stageTrackerId)
          .isSystemDefault,
      isFalse,
    );
    expect(settings.single.reminderTone, 'early');
    expect(settings.single.notificationReminderTime, '20:30');
    expect(templates.single.templateName, '家務');
    expect(templateItems.single.title, '倒垃圾');
  });
}
