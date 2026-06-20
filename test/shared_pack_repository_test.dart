import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/identity_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/resource_repository.dart';
import 'package:reminder_app/features/reminders/data/shared_pack_repository.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_models.dart';
import 'package:reminder_app/features/reminders/data/stage_tracker_repository.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/resource.dart';
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';
import 'package:reminder_app/features/reminders/domain/stage_occurrence.dart';
import 'package:reminder_app/features/reminders/domain/stage_record.dart';

void main() {
  test(
    'shared pack phase 1 records actors, events, and acknowledgements',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final itemRepository = ItemRepository(db.reminderDao);
      final resourceRepository = ResourceRepository(db.reminderDao);
      var stageNow = DateTime(2026, 6, 22);
      final stageRepository = StageTrackerRepository(
        db.reminderDao,
        clock: () => stageNow,
      );
      final sharedRepository = SharedPackRepository(db.reminderDao);

      final packId = await itemRepository.createPack(
        const ItemPackInput(title: 'Cat Care'),
      );

      expect(await sharedRepository.convertPackToShared(packId), isTrue);
      expect(await sharedRepository.convertPackToShared(packId), isFalse);

      final sharedPack = await itemRepository.getPackById(packId);
      final members = await sharedRepository.listPackMembers(packId);
      expect(sharedPack!.packType, ItemPackType.shared);
      expect(sharedPack.hostUserId, AppDatabase.defaultHostUserId);
      expect(
        members.map((member) => '${member.userId}:${member.role.name}'),
        contains('${AppDatabase.defaultHostUserId}:host'),
      );

      final itemId = await itemRepository.createItem(
        ItemInput(
          title: 'Refill food',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
          packId: packId,
        ),
      );
      expect(
        await itemRepository.markDone(
          itemId,
          doneAt: DateTime(2026, 6, 19),
          actorUserId: AppDatabase.defaultMemberUserId,
        ),
        isFalse,
      );
      expect(await sharedRepository.addLocalMember(packId), isTrue);
      expect(
        await itemRepository.assignItemToUser(
          itemId,
          assignedToUserId: AppDatabase.defaultMemberUserId,
        ),
        isTrue,
      );
      final assignedItem = await itemRepository.getItemById(itemId);
      expect(
        assignedItem!.item.assignedToUserId,
        AppDatabase.defaultMemberUserId,
      );

      expect(
        await itemRepository.markDone(
          itemId,
          doneAt: DateTime(2026, 6, 20),
          actorUserId: AppDatabase.defaultMemberUserId,
        ),
        isTrue,
      );
      expect(
        await itemRepository.markDone(
          itemId,
          doneAt: DateTime(2026, 6, 21),
          actorUserId: AppDatabase.defaultHostUserId,
        ),
        isFalse,
      );

      var completions = await db.reminderDao.listItemCompletions(itemId);
      expect(completions, hasLength(1));
      expect(
        completions.single.completedByUserId,
        AppDatabase.defaultMemberUserId,
      );
      expect(completions.single.undoneByUserId, isNull);

      final doneRecord = (await itemRepository.listActionHistory(
        itemId,
      )).firstWhere((record) => record.actionType.name == 'done');
      expect(
        await itemRepository.undoDone(
          doneRecord.id,
          revertedAt: DateTime(2026, 6, 21),
          actorUserId: AppDatabase.defaultHostUserId,
        ),
        isTrue,
      );
      completions = await db.reminderDao.listItemCompletions(itemId);
      expect(
        completions.single.completedByUserId,
        AppDatabase.defaultMemberUserId,
      );
      expect(completions.single.undoneByUserId, AppDatabase.defaultHostUserId);
      expect(completions.single.undoneAt, DateTime(2026, 6, 21));

      expect(
        await itemRepository.markDone(
          itemId,
          doneAt: DateTime(2026, 6, 20),
          actorUserId: AppDatabase.defaultHostUserId,
        ),
        isTrue,
      );
      completions = await db.reminderDao.listItemCompletions(itemId);
      expect(completions, hasLength(2));
      expect(completions.last.completedByUserId, AppDatabase.defaultHostUserId);

      final resourceId = await resourceRepository.createResource(
        ResourceInput(
          title: 'Food cans',
          type: ResourceType.quantityBased,
          packId: packId,
          config: const QuantityBasedResourceConfig(
            currentQuantity: 5,
            unitLabel: 'can',
            warningThreshold: 2,
            dangerThreshold: 1,
          ),
        ),
      );
      expect(
        await resourceRepository.adjustResourceQuantity(
          resourceId,
          newQuantity: 6,
          actorUserId: 'user_missing',
        ),
        isFalse,
      );
      expect(
        await resourceRepository.adjustResourceQuantity(
          resourceId,
          newQuantity: 7,
          actorUserId: AppDatabase.defaultMemberUserId,
        ),
        isTrue,
      );
      expect(
        await resourceRepository.incrementResourceQuantity(
          resourceId,
          amount: 3,
          actorUserId: AppDatabase.defaultHostUserId,
        ),
        isTrue,
      );
      expect(
        await resourceRepository.decrementResourceQuantity(
          resourceId,
          amount: 4,
          actorUserId: AppDatabase.defaultMemberUserId,
        ),
        isTrue,
      );

      final resourceEvents = await resourceRepository
          .listResourceEventsForResource(resourceId);
      expect(resourceEvents.map((event) => event.changeType), [
        ResourceEventChangeType.adjust,
        ResourceEventChangeType.increment,
        ResourceEventChangeType.decrement,
      ]);
      expect(resourceEvents.first.previousValue, 5);
      expect(resourceEvents.first.newValue, 7);
      expect(resourceEvents[1].deltaValue, 3);
      expect(resourceEvents[2].deltaValue, -4);

      final trackerId = await stageRepository.createStageTracker(
        StageTrackerInput(
          title: 'Growth',
          trackingStartDate: DateTime(2026, 6, 1),
          packId: packId,
        ),
      );
      final stageRecordId = await stageRepository.createImportantStage(
        trackerId,
        ManualStageInput(
          label: 'Vet check',
          occurrenceDate: DateTime(2026, 6, 20),
        ),
      );
      final occurrence = StageOccurrence(
        stageTrackerId: trackerId,
        stageRecordId: stageRecordId,
        sourceType: StageRecordSourceType.manual,
        occurrenceDate: DateTime(2026, 6, 20),
        label: 'Vet check',
        reminderOffsetDays: 0,
        recordStatus: StageRecordStatus.normal,
      );
      await stageRepository.acknowledgeOccurrence(
        occurrence,
        actorUserId: 'user_missing',
      );
      await stageRepository.acknowledgeOccurrence(
        occurrence,
        actorUserId: AppDatabase.defaultHostUserId,
      );
      stageNow = DateTime(2026, 6, 23);
      await stageRepository.acknowledgeOccurrence(
        occurrence,
        actorUserId: AppDatabase.defaultHostUserId,
      );
      await stageRepository.acknowledgeOccurrence(
        occurrence,
        actorUserId: AppDatabase.defaultMemberUserId,
      );
      final acknowledgements = await stageRepository
          .listStageAcknowledgementsForRecord(stageRecordId);
      expect(acknowledgements, hasLength(2));
      expect(
        acknowledgements.map((item) => item.userId),
        containsAll([
          AppDatabase.defaultHostUserId,
          AppDatabase.defaultMemberUserId,
        ]),
      );
      expect(
        acknowledgements
            .singleWhere((item) => item.userId == AppDatabase.defaultHostUserId)
            .acknowledgedAt,
        DateTime(2026, 6, 23),
      );

      final activity = await sharedRepository.listActivityEventsForPack(packId);
      expect(
        activity.map((event) => event.action),
        containsAll([
          'pack_converted_to_shared',
          'member_added',
          'item_created',
          'item_assigned',
          'item_completed',
          'item_undone',
          'resource_adjusted',
          'resource_incremented',
          'resource_decremented',
          'stage_acknowledged',
        ]),
      );
    },
  );

  test(
    'current local user remains shared actor after remote identity link',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final identityRepository = IdentityRepository(db.reminderDao);
      final localUser = await identityRepository.ensureLocalIdentity();
      Future<String> currentActor() async =>
          (await identityRepository.getCurrentAppUser()).id;
      final itemRepository = ItemRepository(
        db.reminderDao,
        currentActorId: currentActor,
      );
      final sharedRepository = SharedPackRepository(
        db.reminderDao,
        currentActorId: currentActor,
      );

      final packId = await itemRepository.createPack(
        const ItemPackInput(title: 'Shared identity'),
      );
      expect(await sharedRepository.convertPackToShared(packId), isTrue);
      final memberBeforeLink = await db.reminderDao.getPackMember(
        packId: packId,
        userId: localUser.id,
      );
      expect(memberBeforeLink, isNotNull);

      final linked = await identityRepository.linkRemoteIdentity(
        remoteUserId: 'fake_supabase_user_current',
        provider: AuthProviderType.supabaseAnonymous,
      );
      final itemId = await itemRepository.createItem(
        ItemInput(
          title: 'Water plants',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
          packId: packId,
        ),
      );

      expect(await itemRepository.markDone(itemId), isTrue);
      final completions = await db.reminderDao.listItemCompletions(itemId);
      expect(completions.single.completedByUserId, localUser.id);
      expect(completions.single.completedByUserId, isNot(linked.remoteUserId));
      expect(
        await db.reminderDao.getPackMember(
          packId: packId,
          userId: localUser.id,
        ),
        isNotNull,
      );
    },
  );

  test(
    'shared operation is rejected when current local user is not member',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final identityRepository = IdentityRepository(db.reminderDao);
      await identityRepository.ensureLocalIdentity();
      Future<String> currentActor() async =>
          (await identityRepository.getCurrentAppUser()).id;
      final itemRepository = ItemRepository(
        db.reminderDao,
        currentActorId: currentActor,
      );
      final sharedRepository = SharedPackRepository(
        db.reminderDao,
        currentActorId: currentActor,
      );

      final packId = await itemRepository.createPack(
        const ItemPackInput(title: 'Host-owned'),
      );
      expect(
        await sharedRepository.convertPackToShared(
          packId,
          hostUserId: AppDatabase.defaultHostUserId,
        ),
        isTrue,
      );
      final itemId = await itemRepository.createItem(
        ItemInput(
          title: 'Non-member task',
          type: ItemType.stateBased,
          config: const StateBasedItemConfig(
            warningAfter: Duration(days: 1),
            dangerAfter: Duration(days: 2),
          ),
          packId: packId,
        ),
      );

      expect(await itemRepository.markDone(itemId), isFalse);
      expect(await db.reminderDao.listItemCompletions(itemId), isEmpty);
    },
  );
}
