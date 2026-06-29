import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/identity_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';

void main() {
  test(
    'unified activity renders item resource stage and actor fallback',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final identity = IdentityRepository(db.reminderDao);
      final primary = await identity.ensureLocalIdentity();
      final packId = await ItemRepository(
        db.reminderDao,
      ).createPack(const ItemPackInput(title: 'Cats', iconEmoji: '🐱'));
      final now = DateTime(2026, 6, 29, 12);
      await db.reminderDao.insertLocalUser(
        LocalUsersCompanion.insert(
          id: 'member-b',
          displayName: '小安',
          createdAt: now.millisecondsSinceEpoch,
        ),
      );
      await db.reminderDao.insertLocalUser(
        LocalUsersCompanion.insert(
          id: 'member-blank',
          displayName: '',
          createdAt: now.millisecondsSinceEpoch,
        ),
      );
      final itemId = await db.reminderDao.insertItem(
        ItemsCompanion.insert(
          packId: packId,
          title: '餵貓',
          type: ItemType.stateBased.name,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      final resourceId = await db.reminderDao.insertResource(
        ResourcesCompanion.insert(
          packId: packId,
          title: '罐頭',
          type: ResourceType.quantityBased.name,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      final stageId = await db.reminderDao.insertStageTracker(
        StageTrackersCompanion.insert(
          packId: packId,
          title: '幼貓期',
          trackingStartDate: now.millisecondsSinceEpoch,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );

      await _insertActivity(
        db,
        packId: packId,
        actorUserId: 'member-b',
        entityType: 'item',
        entityId: itemId,
        action: 'item_completed',
        at: now,
      );
      await _insertActivity(
        db,
        packId: packId,
        actorUserId: primary.id,
        entityType: 'resource',
        entityId: resourceId,
        action: 'resource_incremented',
        at: now.subtract(const Duration(minutes: 1)),
      );
      await _insertActivity(
        db,
        packId: packId,
        actorUserId: 'member-blank',
        entityType: 'stage_tracker',
        entityId: stageId,
        action: 'stage_tracker_updated',
        at: now.subtract(const Duration(minutes: 2)),
      );

      final controller = ItemActivityFeedController(
        dao: db.reminderDao,
        previewDate: now,
      );
      await controller.refresh();

      expect(
        controller.state.items.map((entry) => entry.message),
        containsAll(['小安 完成了「餵貓」', '此裝置資料 補充了「罐頭」', '有成員 更新了「幼貓期」']),
      );
    },
  );

  test(
    'unified activity suppresses pending and confirmed duplicate projection',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final identity = IdentityRepository(db.reminderDao);
      final actor = await identity.ensureLocalIdentity();
      final packId = await ItemRepository(
        db.reminderDao,
      ).createPack(const ItemPackInput(title: 'Home', iconEmoji: '🏠'));
      final now = DateTime(2026, 6, 29, 12);
      final itemId = await db.reminderDao.insertItem(
        ItemsCompanion.insert(
          packId: packId,
          title: '倒垃圾',
          type: ItemType.stateBased.name,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      await _insertActivity(
        db,
        packId: packId,
        actorUserId: actor.id,
        entityType: 'item',
        entityId: itemId,
        action: 'item_updated',
        at: now,
      );
      await _insertActivity(
        db,
        packId: packId,
        actorUserId: actor.id,
        entityType: 'item',
        entityId: itemId,
        action: 'item_updated',
        at: now.add(const Duration(seconds: 30)),
        metadataJson: '{"remoteActivityId":"remote-activity-1"}',
      );

      final controller = ItemActivityFeedController(
        dao: db.reminderDao,
        previewDate: now,
      );
      await controller.refresh();

      expect(
        controller.state.items.where(
          (entry) => entry.message.contains('更新了「倒垃圾」'),
        ),
        hasLength(1),
      );
    },
  );
}

Future<void> _insertActivity(
  AppDatabase db, {
  required int packId,
  required String actorUserId,
  required String entityType,
  required int entityId,
  required String action,
  required DateTime at,
  String? metadataJson,
}) {
  return db.reminderDao.insertActivityEvent(
    ActivityEventsCompanion.insert(
      packId: packId,
      actorUserId: actorUserId,
      entityType: entityType,
      entityId: entityId,
      action: action,
      metadataJson: Value(metadataJson),
      createdAt: at.millisecondsSinceEpoch,
    ),
  );
}
