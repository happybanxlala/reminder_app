import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/shared_packs/application/shared_pack_read_models.dart';
import 'package:reminder_app/features/shared_packs/application/shared_pack_runtime_types.dart';
import 'package:reminder_app/features/shared_packs/data/local/drift_shared_cache_read_adapter.dart';
import 'package:reminder_app/features/shared_packs/domain/shared_pack_errors.dart';
import 'package:reminder_app/features/shared_packs/domain/shared_pack_ids.dart';
import 'package:reminder_app/features/shared_packs/domain/shared_pack_models.dart';
import 'package:reminder_app/features/shared_packs/domain/shared_pack_runtime_values.dart';

import 'support/shared_pack_projected_cache_fixture.dart';

const _request1 = '123e4567-e89b-42d3-a456-426614174001';
const _request2 = '123e4567-e89b-42d3-a456-426614174002';
const _request3 = '123e4567-e89b-42d3-a456-426614174003';

void main() {
  late AppDatabase database;
  late DriftSharedCacheReadAdapter adapter;

  setUp(() async {
    database = await openSharedPackTestDatabase();
    adapter = DriftSharedCacheReadAdapter(
      dao: database.sharedPackCacheDao,
      clock: FixedSharedUtcClock(
        UtcInstant(
          DateTime.fromMillisecondsSinceEpoch(
            sharedTestNowEpochMs,
            isUtc: true,
          ),
        ),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('fresh v6 cache emits an empty list and null exact detail', () async {
    final list = await adapter.watchPackList().first;
    final detail = await adapter.watchPackDetail(RemotePackId('P1')).first;

    expect(list.packs, isEmpty);
    expect(list.unresolved.entries, isEmpty);
    expect(detail, isNull);
    expect(await _count(database, 'shared_pack_cache'), 0);
    expect(await _count(database, 'shared_pending_mutation'), 0);
  });

  test(
    'Pack list maps exact identity, role, UTC, trust, and immutability',
    () async {
      await insertCoherentProjectedPack(
        database,
        packId: 'Pack-Case-Sensitive',
        title: 'Care List',
        currentMemberId: 'Member-A',
      );

      final model = await adapter.watchPackList().first;
      final entry = model.packs.single;
      expect(entry.remotePackId.value, 'Pack-Case-Sensitive');
      expect(entry.title, 'Care List');
      expect(entry.iconEmoji, '🤝');
      expect(entry.role, SharedRole.member);
      expect(entry.trust.trust, SharedCacheTrust.verified);
      expect(entry.trust.reason, isNull);
      expect(entry.trust.mutationBlocked, isFalse);
      expect(entry.lastVerifiedAt.value.isUtc, isTrue);
      expect(() => model.packs.add(entry), throwsUnsupportedError);
    },
  );

  test(
    'list stream emits insert, metadata, trust, and deletion updates',
    () async {
      final signatures = adapter.watchPackList().map((model) {
        if (model.packs.isEmpty) return 'empty';
        final entry = model.packs.single;
        return '${entry.title}:${entry.trust.trust.name}';
      }).distinct();
      final emissions = StreamIterator(signatures);
      addTearDown(emissions.cancel);
      expect(await _next(emissions), 'empty');

      await insertCoherentProjectedPack(database, packId: 'P1', title: 'Alpha');
      expect(await _next(emissions), 'Alpha:verified');
      await database.customStatement(
        'UPDATE shared_pack_cache SET title = ? WHERE remote_pack_id = ?',
        ['Beta', 'P1'],
      );
      database.markTablesUpdated([database.sharedPackCache]);
      expect(await _next(emissions), 'Beta:verified');
      await database.customStatement(
        '''UPDATE shared_pack_cache
         SET trust_state = 'needsRevalidation',
             trust_failure_reason = 'projectionFailed'
         WHERE remote_pack_id = ?''',
        ['P1'],
      );
      database.markTablesUpdated([database.sharedPackCache]);
      expect(await _next(emissions), 'Beta:needsRevalidation');
      await database.customStatement(
        'DELETE FROM shared_pack_cache WHERE remote_pack_id = ?',
        ['P1'],
      );
      database.markTablesUpdated([database.sharedPackCache]);
      expect(await _next(emissions), 'empty');
    },
  );

  test('inaccessible retained root remains visible and fail-closed', () async {
    await insertCoherentProjectedPack(
      database,
      packId: 'P1',
      trust: 'inaccessible',
      reason: 'permissionDenied',
    );

    final entry = (await adapter.watchPackList().first).packs.single;
    expect(entry.trust.trust, SharedCacheTrust.inaccessible);
    expect(entry.trust.reason, SharedTrustFailureReason.permissionDenied);
    expect(entry.trust.mutationBlocked, isTrue);
    expect(entry.trust.canRefreshOrRecheck, isTrue);
  });

  test(
    'detail maps coherent graph, duplicate names, completion, and Pack isolation',
    () async {
      await database.transaction(() async {
        await insertProjectedPack(
          database,
          packId: 'P1',
          title: 'Pack One',
          packVersion: 9,
        );
        await insertProjectedMembership(
          database,
          packId: 'P1',
          memberId: 'owner',
          role: 'owner',
          displayName: 'Same Name',
        );
        await insertProjectedMembership(
          database,
          packId: 'P1',
          memberId: 'actor',
          role: 'member',
          displayName: 'Same Name',
          isCurrent: true,
        );
        await insertProjectedMembership(
          database,
          packId: 'P1',
          memberId: 'extra',
          role: 'member',
          displayName: 'Extra',
        );
        await insertProjectedItem(
          database,
          packId: 'P1',
          itemId: 'same-item',
          completedAt: sharedTestNowEpochMs - 60000,
          completedBy: 'actor',
          itemVersion: 5,
          createdAt: sharedTestNowEpochMs - 5000,
          updatedAt: sharedTestNowEpochMs - 1000,
        );
        await insertProjectedItem(database, packId: 'P1', itemId: 'incomplete');

        await insertProjectedPack(database, packId: 'P2', title: 'Pack Two');
        await insertProjectedMembership(
          database,
          packId: 'P2',
          memberId: 'actor',
          role: 'owner',
          displayName: 'Foreign Actor',
          isCurrent: true,
        );
        await insertProjectedItem(
          database,
          packId: 'P2',
          itemId: 'same-item',
          completedAt: sharedTestNowEpochMs,
          completedBy: 'actor',
        );
      });

      final detail = await adapter.watchPackDetail(RemotePackId('P1')).first;
      expect(detail, isNotNull);
      expect(detail!.remotePackId.value, 'P1');
      expect(detail.packVersion.value, 9);
      expect(detail.currentMembership.remoteMemberId.value, 'actor');
      expect(detail.currentMembership.role, SharedRole.member);
      expect(detail.members, hasLength(3));
      expect(detail.activeItems, hasLength(2));
      expect(
        detail.activeItems.every((item) => item.remotePackId.value == 'P1'),
        isTrue,
      );
      final completed = detail.activeItems.singleWhere(
        (item) => item.remoteItemId.value == 'same-item',
      );
      expect(completed.itemVersion.value, 5);
      expect(completed.createdAt.value.isUtc, isTrue);
      expect(completed.updatedAt.value.isUtc, isTrue);
      expect(completed.completion!.actor.remoteMemberId.value, 'actor');
      expect(completed.completion!.actor.displayLabel, 'Same Name');
      expect(completed.completion!.actor.hasDuplicateDisplayName, isTrue);
      expect(
        detail.activeItems
            .singleWhere((item) => item.remoteItemId.value == 'incomplete')
            .completion,
        isNull,
      );
    },
  );

  test('detail stream removes stale children and never duplicates rows', () async {
    await database.transaction(() async {
      await insertCoherentProjectedPack(database, packId: 'P1', title: 'Alpha');
      await insertProjectedMembership(
        database,
        packId: 'P1',
        memberId: 'member-1',
        role: 'member',
        displayName: 'Member One',
      );
      await insertProjectedItem(database, packId: 'P1', itemId: 'item-1');
    });
    String signature(SharedPackDetailReadModel? detail) => detail == null
        ? 'null'
        : '${detail.title}|${detail.members.map((m) => m.displayName).join(',')}|${detail.activeItems.map((i) => i.title).join(',')}';
    final emissions = StreamIterator(
      adapter.watchPackDetail(RemotePackId('P1')).map(signature).distinct(),
    );
    addTearDown(emissions.cancel);
    expect(await _next(emissions), 'Alpha|Member One,Owner|Shared Item');

    await insertProjectedMembership(
      database,
      packId: 'P1',
      memberId: 'member-2',
      role: 'member',
      displayName: 'Member Two',
    );
    expect(
      await _next(emissions),
      'Alpha|Member One,Member Two,Owner|Shared Item',
    );
    await database.customStatement(
      '''UPDATE shared_membership_cache SET display_name = 'Renamed'
         WHERE remote_pack_id = 'P1' AND remote_member_id = 'member-2' ''',
    );
    database.markTablesUpdated([database.sharedMembershipCache]);
    expect(
      await _next(emissions),
      'Alpha|Member One,Renamed,Owner|Shared Item',
    );
    await database.customStatement('''DELETE FROM shared_membership_cache
         WHERE remote_pack_id = 'P1' AND remote_member_id = 'member-2' ''');
    database.markTablesUpdated([database.sharedMembershipCache]);
    expect(await _next(emissions), 'Alpha|Member One,Owner|Shared Item');
    await insertProjectedItem(
      database,
      packId: 'P1',
      itemId: 'item-2',
      title: 'Second',
    );
    expect(await _next(emissions), 'Alpha|Member One,Owner|Shared Item,Second');
    await database.customStatement(
      '''UPDATE shared_item_cache SET title = 'Updated'
         WHERE remote_pack_id = 'P1' AND remote_item_id = 'item-2' ''',
    );
    database.markTablesUpdated([database.sharedItemCache]);
    expect(
      await _next(emissions),
      'Alpha|Member One,Owner|Shared Item,Updated',
    );
    await database.customStatement('''DELETE FROM shared_item_cache
         WHERE remote_pack_id = 'P1' AND remote_item_id = 'item-2' ''');
    database.markTablesUpdated([database.sharedItemCache]);
    expect(await _next(emissions), 'Alpha|Member One,Owner|Shared Item');
    await database.customStatement(
      "UPDATE shared_pack_cache SET title = 'Beta' WHERE remote_pack_id = 'P1'",
    );
    database.markTablesUpdated([database.sharedPackCache]);
    expect(await _next(emissions), 'Beta|Member One,Owner|Shared Item');
    await database.customStatement(
      "DELETE FROM shared_pack_cache WHERE remote_pack_id = 'P1'",
    );
    database.markTablesUpdated([database.sharedPackCache]);
    expect(await _next(emissions), 'null');
  });

  test(
    'attention uses fixed UTC clock with exact boundaries and future clamp',
    () async {
      Future<SharedItemAttention> attention({
        required int elapsedMinutes,
        int warning = 10,
        int danger = 20,
      }) async {
        await database.transaction(() async {
          await database.customStatement('DELETE FROM shared_pack_cache');
          await insertCoherentProjectedPack(database, packId: 'P1');
          await insertProjectedItem(
            database,
            packId: 'P1',
            itemId: 'I',
            stateAnchorAt: sharedTestNowEpochMs - elapsedMinutes * 60000,
            warningAfterMinutes: warning,
            dangerAfterMinutes: danger,
          );
        });
        return (await adapter.watchPackDetail(RemotePackId('P1')).first)!
            .activeItems
            .single
            .attention;
      }

      expect(await attention(elapsedMinutes: -5), SharedItemAttention.normal);
      expect(await attention(elapsedMinutes: 9), SharedItemAttention.normal);
      expect(await attention(elapsedMinutes: 10), SharedItemAttention.warning);
      expect(await attention(elapsedMinutes: 19), SharedItemAttention.warning);
      expect(await attention(elapsedMinutes: 20), SharedItemAttention.danger);
      expect(await attention(elapsedMinutes: 21), SharedItemAttention.danger);
      expect(
        await attention(elapsedMinutes: 10, warning: 10, danger: 10),
        SharedItemAttention.danger,
      );
    },
  );

  test(
    'all exact trust reasons map and malformed combinations fail closed',
    () async {
      const needsReasons = [
        'remoteOutcomeUnknown',
        'projectionFailed',
        'snapshotValidationFailed',
        'unsupportedSnapshotSchema',
        'sameVersionContentConflict',
        'snapshotIntegrityFailed',
        'staleMutationBase',
      ];
      for (final reason in needsReasons) {
        await database.transaction(() async {
          await database.customStatement('DELETE FROM shared_pack_cache');
          await insertCoherentProjectedPack(
            database,
            packId: 'P1',
            trust: 'needsRevalidation',
            reason: reason,
          );
        });
        final trust = (await adapter.watchPackList().first).packs.single.trust;
        expect(trust.reason!.name, reason);
        expect(trust.mutationBlocked, isTrue);
      }
      for (final reason in ['permissionDenied', 'packNotFound']) {
        await database.transaction(() async {
          await database.customStatement('DELETE FROM shared_pack_cache');
          await insertCoherentProjectedPack(
            database,
            packId: 'P1',
            trust: 'inaccessible',
            reason: reason,
          );
        });
        final trust = (await adapter.watchPackList().first).packs.single.trust;
        expect(trust.reason!.name, reason);
        expect(trust.trust, SharedCacheTrust.inaccessible);
      }

      await database.transaction(() async {
        await database.customStatement('DELETE FROM shared_pack_cache');
        await insertCoherentProjectedPack(
          database,
          packId: 'P1',
          trust: 'needsRevalidation',
        );
      });
      await expectLater(adapter.watchPackList(), emitsError(isA<StateError>()));
    },
  );

  test(
    'mutation base is exact, deterministic, Pack-scoped, and reports failures',
    () async {
      expect(
        await adapter.readMutationBase(RemotePackId('missing')),
        isA<SharedLocalPortSuccess<SharedMutationBase?>>().having(
          (result) => result.value,
          'value',
          isNull,
        ),
      );
      await database.transaction(() async {
        await insertCoherentProjectedPack(database, packId: 'P1');
        await insertProjectedItem(
          database,
          packId: 'P1',
          itemId: 'z-item',
          itemVersion: 9,
        );
        await insertProjectedItem(
          database,
          packId: 'P1',
          itemId: 'a-item',
          itemVersion: 2,
        );
        await insertPendingMarker(
          database,
          operation: 'completeSharedItem',
          requestId: _request1,
          targetPackId: 'P1',
        );
        await insertCoherentProjectedPack(
          database,
          packId: 'P2',
          currentMemberId: 'current-member',
          trust: 'needsRevalidation',
          reason: 'staleMutationBase',
        );
        await insertProjectedItem(
          database,
          packId: 'P2',
          itemId: 'a-item',
          itemVersion: 99,
        );
      });

      final result = await adapter.readMutationBase(RemotePackId('P1'));
      expect(result, isA<SharedLocalPortSuccess<SharedMutationBase?>>());
      final base =
          (result as SharedLocalPortSuccess<SharedMutationBase?>).value!;
      expect(base.currentRole, SharedRole.owner);
      expect(base.hasUnresolvedMutation, isTrue);
      expect(base.itemVersions.map((item) => item.remoteItemId.value), [
        'a-item',
        'z-item',
      ]);
      expect(base.itemVersions.map((item) => item.itemVersion.value), [2, 9]);

      final memberResult = await adapter.readMutationBase(RemotePackId('P2'));
      final memberBase =
          (memberResult as SharedLocalPortSuccess<SharedMutationBase?>).value!;
      expect(memberBase.currentRole, SharedRole.member);
      expect(memberBase.trust, SharedCacheTrust.needsRevalidation);
      expect(memberBase.hasUnresolvedMutation, isFalse);
      expect(memberBase.itemVersions.single.itemVersion.value, 99);

      await database.close();
      final failure = await adapter.readMutationBase(RemotePackId('P1'));
      expect(
        failure,
        isA<SharedLocalPortFailure<SharedMutationBase?>>().having(
          (result) => result.family,
          'family',
          SharedLocalPortFailureFamily.readFailed,
        ),
      );
    },
  );

  test(
    'recovery marker stream maps typed fields and insert/update/delete order',
    () async {
      final signatures = adapter
          .watchRecoveryMarkers()
          .map(
            (markers) => markers
                .map(
                  (marker) =>
                      '${marker.operation.name}:${marker.targetRemotePackId?.value ?? '-'}',
                )
                .join(','),
          )
          .distinct();
      final emissions = StreamIterator(signatures);
      addTearDown(emissions.cancel);
      expect(await _next(emissions), '');
      await insertPendingMarker(
        database,
        operation: 'createSharedPack',
        requestId: _request1,
        createdAt: sharedTestNowEpochMs - 1,
      );
      expect(await _next(emissions), 'createSharedPack:-');
      await database.customStatement(
        '''UPDATE shared_pending_mutation SET target_remote_pack_id = 'P1'
         WHERE client_request_id = ?''',
        [_request1],
      );
      database.markTablesUpdated([database.sharedPendingMutation]);
      expect(await _next(emissions), 'createSharedPack:P1');
      await insertPendingMarker(
        database,
        operation: 'rotateInviteCode',
        requestId: _request2,
        targetPackId: 'P2',
        createdAt: sharedTestNowEpochMs,
      );
      expect(await _next(emissions), 'createSharedPack:P1,rotateInviteCode:P2');
      await database.customStatement(
        'DELETE FROM shared_pending_mutation WHERE client_request_id = ?',
        [_request1],
      );
      database.markTablesUpdated([database.sharedPendingMutation]);
      expect(await _next(emissions), 'rotateInviteCode:P2');

      final marker = (await adapter.watchRecoveryMarkers().first).single;
      expect(marker.clientRequestId.value, _request2);
      expect(marker.payloadFingerprint.value, sharedTestFingerprint);
      expect(marker.createdAt.value.isUtc, isTrue);
      expect(marker.status, SharedPendingMutationStatus.awaitingResolution);
      expect(await _count(database, 'shared_pending_mutation'), 1);
    },
  );

  test(
    'list/detail pending presentations update without replay or deletion',
    () async {
      await insertCoherentProjectedPack(database, packId: 'P1');
      final emissions = StreamIterator(
        adapter.watchPackList().map((model) {
          final entry = model.packs.single;
          return '${entry.pending?.operation.name ?? '-'}:${model.unresolved.entries.length}';
        }).distinct(),
      );
      addTearDown(emissions.cancel);
      expect(await _next(emissions), '-:0');
      await insertPendingMarker(
        database,
        operation: 'completeSharedItem',
        requestId: _request1,
        targetPackId: 'P1',
      );
      expect(await _next(emissions), 'completeSharedItem:0');
      await insertPendingMarker(
        database,
        operation: 'joinSharedPack',
        requestId: _request3,
        createdAt: sharedTestNowEpochMs + 1,
      );
      expect(await _next(emissions), 'completeSharedItem:1');

      final list = await adapter.watchPackList().first;
      expect(list.packs.single.pending!.availableActions, [
        PendingRecoveryAction.refresh,
        PendingRecoveryAction.sameIdReplay,
      ]);
      expect(list.unresolved.entries.single.availableActions, [
        PendingRecoveryAction.sameIdReplay,
      ]);
      expect(await _count(database, 'shared_pending_mutation'), 2);
    },
  );

  test(
    'incomplete root and unresolved actor produce observable terminal errors',
    () async {
      await insertProjectedPack(database, packId: 'P1');
      await expectLater(adapter.watchPackList(), emitsError(isA<StateError>()));

      await database.customStatement('DELETE FROM shared_pack_cache');
      await insertCoherentProjectedPack(database, packId: 'P2');
      await database.customStatement('PRAGMA foreign_keys = OFF');
      await insertProjectedItem(
        database,
        packId: 'P2',
        itemId: 'bad-actor',
        completedAt: sharedTestNowEpochMs,
        completedBy: 'foreign-member',
      );
      await expectLater(
        adapter.watchPackDetail(RemotePackId('P2')),
        emitsError(isA<StateError>()),
      );
      expect(await _count(database, 'shared_membership_cache'), 1);
      expect(await _count(database, 'shared_item_cache'), 1);
    },
  );

  test(
    'detail stream is invalidated by relevant pending insert and delete',
    () async {
      await insertCoherentProjectedPack(database, packId: 'P1');
      final emissions = StreamIterator(
        adapter
            .watchPackDetail(RemotePackId('P1'))
            .map((detail) => detail?.pending?.operation.name ?? '-')
            .distinct(),
      );
      addTearDown(emissions.cancel);
      expect(await _next(emissions), '-');

      await insertPendingMarker(
        database,
        operation: 'completeSharedItem',
        requestId: _request1,
        targetPackId: 'P1',
      );
      expect(await _next(emissions), 'completeSharedItem');
      await database.customStatement(
        'DELETE FROM shared_pending_mutation WHERE client_request_id = ?',
        [_request1],
      );
      database.markTablesUpdated([database.sharedPendingMutation]);
      expect(await _next(emissions), '-');
    },
  );

  test(
    'constraint-bypassed invalid enum is not normalized into a model',
    () async {
      await database.customStatement('PRAGMA ignore_check_constraints = ON');
      await insertProjectedPack(database, packId: 'P1', trust: 'invalidTrust');
      await insertProjectedMembership(
        database,
        packId: 'P1',
        memberId: 'owner',
        role: 'owner',
        displayName: 'Owner',
        isCurrent: true,
      );

      await expectLater(adapter.watchPackList(), emitsError(isA<StateError>()));
      final row = await database
          .customSelect(
            "SELECT trust_state FROM shared_pack_cache WHERE remote_pack_id = 'P1'",
          )
          .getSingle();
      expect(row.read<String>('trust_state'), 'invalidTrust');
    },
  );
}

Future<int> _count(AppDatabase database, String table) async {
  final row = await database
      .customSelect('SELECT COUNT(*) AS count FROM $table')
      .getSingle();
  return row.read<int>('count');
}

Future<T> _next<T>(StreamIterator<T> iterator) async {
  expect(await iterator.moveNext(), isTrue);
  return iterator.current;
}
