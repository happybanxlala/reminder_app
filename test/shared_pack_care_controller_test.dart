import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/auth_repository.dart';
import 'package:reminder_app/features/reminders/data/item_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_data_source.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_models.dart';
import 'package:reminder_app/features/reminders/domain/item.dart';
import 'package:reminder_app/features/reminders/domain/item_pack.dart';
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';
import 'package:reminder_app/features/reminders/providers/database_providers.dart';
import 'package:reminder_app/features/reminders/providers/identity_providers.dart';
import 'package:reminder_app/features/reminders/providers/item_providers.dart';
import 'package:reminder_app/features/reminders/providers/remote_shared_pack_providers.dart';
import 'package:reminder_app/features/reminders/providers/shared_pack_care_providers.dart';

void main() {
  test('invite flow converts personal pack and creates invite', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    final packId = await harness.createPersonalPackWithItem('Cats');
    final pack = (await harness.container
        .read(itemRepositoryProvider)
        .getPackById(packId))!;

    final result = await harness.container
        .read(sharedPackCareControllerProvider)
        .createInvite(pack);

    expect(result.succeeded, isTrue);
    expect(result.invite!.inviteCode, 'ABCD-1234-EFGH');
    expect(harness.remote.createdPackCount, 1);
    expect(harness.remote.createdInviteCount, 1);
    expect(harness.remote.createdItems.map((item) => item.title), ['Feed cat']);
    final sharedPack = await harness.container
        .read(itemRepositoryProvider)
        .getPackById(packId);
    expect(sharedPack!.packType, ItemPackType.shared);
  });

  test('invite flow reuses existing remote pack mapping', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    final packId = await harness.createPersonalPackWithItem('House');
    final repository = harness.container.read(itemRepositoryProvider);
    final pack = (await repository.getPackById(packId))!;
    final controller = harness.container.read(sharedPackCareControllerProvider);

    final first = await controller.createInvite(pack);
    final mappedPack = (await repository.getPackById(packId))!;
    final second = await controller.createInvite(mappedPack);

    expect(first.succeeded, isTrue);
    expect(second.succeeded, isTrue);
    expect(harness.remote.createdPackCount, 1);
    expect(harness.remote.createdInviteCount, 2);
  });

  test('join flow imports remote snapshot as local mirror', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);

    final result = await harness.container
        .read(sharedPackCareControllerProvider)
        .joinWithInviteCode('ABCD-1234-EFGH');

    expect(result.succeeded, isTrue);
    expect(result.packTitle, 'Joined Cats');
    expect(harness.remote.joinInviteCount, 1);
    expect(harness.remote.fetchSnapshotCount, 1);
    final packs = await harness.container
        .read(itemRepositoryProvider)
        .watchPacks()
        .first;
    expect(packs.map((pack) => pack.title), contains('Joined Cats'));
  });

  test('join failure returns user-safe message', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    harness.remote.joinFailure =
        RemoteSharedPackFailureReason.remoteInviteExpired;

    final result = await harness.container
        .read(sharedPackCareControllerProvider)
        .joinWithInviteCode('EXPIRED');

    expect(result.succeeded, isFalse);
    expect(result.errorMessage, '邀請碼已過期，請對方重新建立邀請。');
    final packs = await harness.container
        .read(itemRepositoryProvider)
        .watchPacks()
        .first;
    expect(packs.where((pack) => pack.title == 'Joined Cats'), isEmpty);
  });
}

class _Harness {
  const _Harness({
    required this.db,
    required this.container,
    required this.remote,
  });

  final AppDatabase db;
  final ProviderContainer container;
  final _FakeRemoteSharedPackDataSource remote;

  static Future<_Harness> create() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final remote = _FakeRemoteSharedPackDataSource();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        remoteSharedPackDataSourceProvider.overrideWithValue(remote),
      ],
    );
    await container.read(currentAppUserProvider.future);
    return _Harness(db: db, container: container, remote: remote);
  }

  Future<int> createPersonalPackWithItem(String title) async {
    final repository = container.read(itemRepositoryProvider);
    final packId = await repository.createPack(ItemPackInput(title: title));
    await repository.createItem(
      ItemInput(
        title: 'Feed cat',
        type: ItemType.stateBased,
        config: const StateBasedItemConfig(
          warningAfter: Duration(days: 1),
          dangerAfter: Duration(days: 2),
        ),
        packId: packId,
      ),
    );
    return packId;
  }

  Future<void> close() async {
    container.dispose();
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await db.close();
        return;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    }
  }
}

class _RemoteItemDraft {
  const _RemoteItemDraft({required this.id, required this.title});

  final String id;
  final String title;
}

class _FakeRemoteSharedPackDataSource implements RemoteSharedPackDataSource {
  int profileUpsertCount = 0;
  int createdPackCount = 0;
  int createdInviteCount = 0;
  int joinInviteCount = 0;
  int fetchSnapshotCount = 0;
  RemoteSharedPackFailureReason? joinFailure;
  final createdItems = <_RemoteItemDraft>[];

  @override
  Future<String> upsertCurrentProfile({required String displayName}) async {
    profileUpsertCount += 1;
    return 'fake_profile';
  }

  @override
  Future<String> createSharedPack({
    required String name,
    String? description,
  }) async {
    createdPackCount += 1;
    return 'remote_pack_$createdPackCount';
  }

  @override
  Future<RemotePackInvite> createPackInvite({required String packId}) async {
    createdInviteCount += 1;
    return RemotePackInvite(
      inviteId: 'invite_$createdInviteCount',
      inviteCode: 'ABCD-1234-EFGH',
      expiresAt: DateTime(2026, 6, 29),
      maxUses: 10,
    );
  }

  @override
  Future<String> createPackItem({
    required String packId,
    required String title,
    String? note,
  }) async {
    final id = 'remote_item_${createdItems.length + 1}';
    createdItems.add(_RemoteItemDraft(id: id, title: title));
    return id;
  }

  @override
  Future<RemoteJoinPackResult> joinPackWithInvite({
    required String inviteCode,
  }) async {
    joinInviteCount += 1;
    final failure = joinFailure;
    if (failure != null) {
      throw RemoteSharedPackException(failure);
    }
    return const RemoteJoinPackResult(
      status: RemoteJoinPackStatus.joined,
      remotePackId: 'joined_remote_pack',
      memberId: 'member_1',
      role: 'member',
    );
  }

  @override
  Future<RemotePackSnapshot> fetchPackSnapshot(String remotePackId) async {
    fetchSnapshotCount += 1;
    return RemotePackSnapshot(
      id: remotePackId,
      name: 'Joined Cats',
      description: null,
      hostUserId: 'remote_host',
      status: 'active',
      createdAt: DateTime(2026, 6, 20),
      updatedAt: DateTime(2026, 6, 21),
      members: [
        RemotePackMemberSnapshot(
          id: 'member_host',
          packId: remotePackId,
          userId: 'remote_host',
          displayName: 'Host',
          role: 'host',
          status: 'active',
          joinedAt: DateTime(2026, 6, 20),
        ),
      ],
      items: [
        RemoteItemSnapshot(
          id: 'remote_item_1',
          packId: remotePackId,
          title: 'Clean litter',
          status: 'active',
          createdByUserId: 'remote_host',
          updatedByUserId: 'remote_host',
          createdAt: DateTime(2026, 6, 20),
          updatedAt: DateTime(2026, 6, 21),
        ),
      ],
      completions: const [],
      activityEvents: const [],
    );
  }

  @override
  Future<RemoteItemCompletionResult> completePackItem({
    required String itemId,
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemoteRevokeInviteResult> revokePackInvite({
    required String inviteId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }

  @override
  Future<RemoteItemUndoResult> undoPackItemCompletion({
    required String itemId,
    String? clientMutationId,
  }) {
    throw const RemoteSharedPackException(
      RemoteSharedPackFailureReason.remoteUnknownFailure,
    );
  }
}
