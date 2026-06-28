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
import 'package:reminder_app/features/reminders/domain/remote_pack_freshness.dart';
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';
import 'package:reminder_app/features/reminders/presentation/text/reminder_ui_text.dart';
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
    expect(result.invite!.inviteCode, 'K7M4Q9');
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
    expect(first.invite!.inviteId, second.invite!.inviteId);
    expect(harness.remote.createdInviteCount, 1);
  });

  test('refresh invite invalidates old invite and returns new code', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    final packId = await harness.createPersonalPackWithItem('House');
    final repository = harness.container.read(itemRepositoryProvider);
    final pack = (await repository.getPackById(packId))!;
    final controller = harness.container.read(sharedPackCareControllerProvider);

    final first = await controller.createInvite(pack);
    final mappedPack = (await repository.getPackById(packId))!;
    final refreshed = await controller.refreshInviteForPack(mappedPack);

    expect(first.succeeded, isTrue);
    expect(refreshed.succeeded, isTrue);
    expect(refreshed.invite!.inviteCode, isNot(first.invite!.inviteCode));
    expect(harness.remote.revokedInviteIds, [first.invite!.inviteId]);
    expect(harness.remote.createdInviteCount, 2);
  });

  test('pack care view model exposes active invite when reopened', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    final packId = await harness.createPersonalPackWithItem('House');
    final repository = harness.container.read(itemRepositoryProvider);
    final pack = (await repository.getPackById(packId))!;

    await harness.container
        .read(sharedPackCareControllerProvider)
        .createInvite(pack);
    final mappedPack = (await repository.getPackById(packId))!;
    final viewModel = await harness.container.read(
      packCareViewModelProvider(mappedPack).future,
    );

    expect(viewModel.activeInvite!.inviteCode, 'K7M4Q9');
    expect(viewModel.rowStatusLabel, ReminderUiText.packCareInviteActiveLabel);
  });

  test(
    'remote-backed care view model exposes member freshness labels',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.close);
      harness.remote.freshnessRows = [
        RemotePackMemberFreshness(
          remoteUserId: 'remote_host',
          displayName: 'Host',
          role: 'host',
          memberStatus: 'active',
          status: RemotePackFreshnessStatus.upToDate,
          lastImportedAt: DateTime(2026, 6, 21, 12),
        ),
      ];

      final join = await harness.container
          .read(sharedPackCareControllerProvider)
          .joinWithInviteCode('k7m 4q9');
      expect(join.succeeded, isTrue);
      final packs = await harness.container
          .read(itemRepositoryProvider)
          .watchPacks()
          .first;
      final remotePack = packs.firstWhere(
        (pack) => pack.title == 'Joined Cats',
      );

      final viewModel = await harness.container.read(
        packCareViewModelProvider(remotePack).future,
      );

      expect(viewModel.isRemoteBacked, isTrue);
      expect(viewModel.members.single.freshnessLabel, '已更新至最新資料');
      expect(
        viewModel.members.single.lastImportedAt,
        DateTime(2026, 6, 21, 12),
      );
    },
  );

  test('normalizes invite code input before join', () async {
    expect(normalizeInviteCode(' k7m-4q9 '), 'K7M4Q9');
    expect(normalizeInviteCode('K7M 4Q9'), 'K7M4Q9');
    expect(normalizeInviteCode('k7m—4q9'), 'K7M4Q9');
  });

  test(
    'invite flow stops before invite when profile bootstrap is rejected',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.close);
      harness.remote.profileFailure =
          RemoteSharedPackFailureReason.remoteRlsRejected;
      final packId = await harness.createPersonalPackWithItem('Cats');
      final pack = (await harness.container
          .read(itemRepositoryProvider)
          .getPackById(packId))!;

      final result = await harness.container
          .read(sharedPackCareControllerProvider)
          .createInvite(pack);

      expect(result.succeeded, isFalse);
      expect(result.errorMessage, '遠端資料庫權限不足，請稍後再試。');
      expect(harness.remote.profileUpsertCount, 1);
      expect(harness.remote.createdPackCount, 0);
      expect(harness.remote.createdInviteCount, 0);
    },
  );

  test(
    'invite flow stops before invite when remote pack bootstrap is rejected',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.close);
      harness.remote.packCreateFailure =
          RemoteSharedPackFailureReason.remoteRlsRejected;
      final packId = await harness.createPersonalPackWithItem('Cats');
      final pack = (await harness.container
          .read(itemRepositoryProvider)
          .getPackById(packId))!;

      final result = await harness.container
          .read(sharedPackCareControllerProvider)
          .createInvite(pack);

      expect(result.succeeded, isFalse);
      expect(result.errorMessage, '遠端資料庫權限不足，請稍後再試。');
      expect(harness.remote.profileUpsertCount, 1);
      expect(harness.remote.createdPackCount, 1);
      expect(harness.remote.createdInviteCount, 0);
    },
  );

  test('invite flow reports specific RLS grant failure message', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    harness.remote.inviteFailure =
        RemoteSharedPackFailureReason.remoteRlsRejected;
    final packId = await harness.createPersonalPackWithItem('Cats');
    final pack = (await harness.container
        .read(itemRepositoryProvider)
        .getPackById(packId))!;

    final result = await harness.container
        .read(sharedPackCareControllerProvider)
        .createInvite(pack);

    expect(result.succeeded, isFalse);
    expect(result.errorMessage, '遠端資料庫權限不足，請稍後再試。');
    expect(harness.remote.createdPackCount, 1);
    expect(harness.remote.createdInviteCount, 1);
  });

  test('join flow imports remote snapshot as local mirror', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);

    final result = await harness.container
        .read(sharedPackCareControllerProvider)
        .joinWithInviteCode('k7m 4q9');

    expect(result.succeeded, isTrue);
    expect(result.packTitle, 'Joined Cats');
    expect(harness.remote.lastJoinedInviteCode, 'K7M4Q9');
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
    expect(result.errorMessage, '這個邀請碼已過期，請向對方索取新的邀請碼。');
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
  String? lastJoinedInviteCode;
  RemoteSharedPackFailureReason? profileFailure;
  RemoteSharedPackFailureReason? packCreateFailure;
  RemoteSharedPackFailureReason? inviteFailure;
  RemoteSharedPackFailureReason? joinFailure;
  RemotePackInvite? activeInvite;
  List<RemotePackMemberFreshness> freshnessRows = const [];
  final revokedInviteIds = <String>[];
  final createdItems = <_RemoteItemDraft>[];

  @override
  Future<String> upsertCurrentProfile({required String displayName}) async {
    profileUpsertCount += 1;
    final failure = profileFailure;
    if (failure != null) {
      throw RemoteSharedPackException(
        failure,
        null,
        'upsert_current_profile',
        '42501',
      );
    }
    return 'fake_profile';
  }

  @override
  Future<String> createSharedPack({
    required String name,
    String? description,
  }) async {
    createdPackCount += 1;
    final failure = packCreateFailure;
    if (failure != null) {
      throw RemoteSharedPackException(
        failure,
        null,
        'create_shared_pack',
        '42501',
      );
    }
    return 'remote_pack_$createdPackCount';
  }

  @override
  Future<RemotePackInvite> createPackInvite({required String packId}) async {
    return ensureActivePackInvite(packId: packId);
  }

  @override
  Future<RemotePackInviteState> fetchPackInviteState({
    required String packId,
  }) async {
    return RemotePackInviteState(activeInvite: activeInvite);
  }

  @override
  Future<RemotePackInvite> ensureActivePackInvite({
    required String packId,
  }) async {
    if (activeInvite != null) {
      return activeInvite!;
    }
    createdInviteCount += 1;
    final failure = inviteFailure;
    if (failure != null) {
      throw RemoteSharedPackException(
        failure,
        null,
        'create_pack_invite',
        '42501',
      );
    }
    activeInvite = RemotePackInvite(
      inviteId: 'invite_$createdInviteCount',
      inviteCode: 'K7M4Q9',
      expiresAt: DateTime(2026, 6, 29),
      maxUses: 10,
    );
    return activeInvite!;
  }

  @override
  Future<RemotePackInvite> refreshPackInvite({required String packId}) async {
    final existing = activeInvite;
    if (existing != null) {
      revokedInviteIds.add(existing.inviteId);
    }
    activeInvite = null;
    final invite = await ensureActivePackInvite(packId: packId);
    activeInvite = RemotePackInvite(
      inviteId: invite.inviteId,
      inviteCode: 'P8W6RA',
      expiresAt: invite.expiresAt,
      maxUses: invite.maxUses,
    );
    return activeInvite!;
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
  Future<RemoteItemCreateResult> createPackItemV2({
    required String packId,
    required String title,
    String? note,
    String? clientMutationId,
  }) async {
    return RemoteItemCreateResult(
      itemId: await createPackItem(packId: packId, title: title, note: note),
    );
  }

  @override
  Future<RemoteItemMutationResult> updatePackItem({
    required String itemId,
    required String title,
    String? note,
    String? assignedToUserId,
    String? clientMutationId,
  }) async {
    return RemoteItemMutationResult(itemId: itemId, status: 'updated');
  }

  @override
  Future<RemoteItemMutationResult> archivePackItem({
    required String itemId,
    String? clientMutationId,
  }) async {
    return RemoteItemMutationResult(itemId: itemId, status: 'archived');
  }

  @override
  Future<RemoteJoinPackResult> joinPackWithInvite({
    required String inviteCode,
  }) async {
    joinInviteCount += 1;
    lastJoinedInviteCode = inviteCode;
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
  Future<List<RemoteRecoverablePack>> fetchActiveMembershipPacks() async {
    return [
      RemoteRecoverablePack(
        remotePackId: 'joined_remote_pack',
        name: 'Joined Cats',
        role: 'member',
        memberStatus: 'active',
        packStatus: 'active',
        hostUserId: 'remote_host',
        updatedAt: DateTime(2026, 6, 21),
      ),
    ];
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

  @override
  Future<void> reportPackSnapshotImported({
    required String remotePackId,
    String? latestActivityEventId,
    DateTime? latestActivityAt,
  }) async {}

  @override
  Future<List<RemotePackMemberFreshness>> getPackMemberFreshness({
    required String remotePackId,
  }) async {
    return freshnessRows;
  }
}
