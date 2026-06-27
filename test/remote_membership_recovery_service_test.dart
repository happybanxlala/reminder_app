import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/anonymous_remote_identity_service.dart';
import 'package:reminder_app/features/reminders/data/account_protection_service.dart';
import 'package:reminder_app/features/reminders/data/auth_repository.dart';
import 'package:reminder_app/features/reminders/data/identity_repository.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/reminders/data/remote_membership_recovery_service.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_data_source.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_models.dart';
import 'package:reminder_app/features/reminders/data/remote_shared_pack_repository.dart';
import 'package:reminder_app/features/reminders/data/remote_snapshot_import_service.dart';
import 'package:reminder_app/features/reminders/domain/remote_membership_recovery.dart';
import 'package:reminder_app/features/reminders/domain/remote_sync.dart';
import 'package:reminder_app/features/reminders/domain/shared_pack.dart';

void main() {
  test('restores active remote membership through snapshot import', () async {
    final env = await _Env.create();
    addTearDown(env.close);
    env.remote.memberships = [_membership('recover-pack')];
    env.remote.snapshots['recover-pack'] = _snapshot('recover-pack');

    final result = await env.service.restoreActiveMemberships();

    expect(result.status, RemoteMembershipRecoveryStatus.restored);
    expect(result.summary.discoveredCount, 1);
    expect(result.summary.eligibleCount, 1);
    expect(result.summary.createdLocalMirrorCount, 1);
    expect(result.summary.failedCount, 0);
    final mapping = await env.db.reminderDao.getSyncMappingByRemote(
      localEntityType: RemoteSharedPackRepository.localEntityPack,
      remoteTable: RemoteSharedPackRepository.remoteTablePacks,
      remoteEntityId: 'recover-pack',
    );
    expect(mapping, isNotNull);
    final packs = await env.db.reminderDao.listItemPacks();
    expect(packs.any((pack) => pack.title == 'Recovered cats'), isTrue);
    expect(await env.db.reminderDao.listSyncOutboxEntries(), isEmpty);
  });

  test('empty discovery returns nothingToRecover', () async {
    final env = await _Env.create();
    addTearDown(env.close);

    final result = await env.service.restoreActiveMemberships();

    expect(result.status, RemoteMembershipRecoveryStatus.nothingToRecover);
    expect(result.summary.discoveredCount, 0);
    expect(env.remote.snapshotCalls, 0);
  });

  test('anonymous unprotected user is blocked by default', () async {
    final env = await _Env.create(
      localRemoteProvider: AuthProviderType.supabaseAnonymous,
      currentRemoteIdentity: const RemoteIdentity(
        remoteUserId: 'remote-member',
        provider: AuthProviderType.supabaseAnonymous,
        isAnonymous: true,
      ),
    );
    addTearDown(env.close);
    env.remote.memberships = [_membership('recover-pack')];

    final result = await env.service.restoreActiveMemberships();

    expect(result.status, RemoteMembershipRecoveryStatus.accountNotProtected);
    expect(env.remote.discoveryCalls, 0);
    expect(env.remote.snapshotCalls, 0);
  });

  test('local-only user is blocked before discovery', () async {
    final env = await _Env.create(linkLocalRemoteIdentity: false);
    addTearDown(env.close);
    env.remote.memberships = [_membership('recover-pack')];

    final result = await env.service.restoreActiveMemberships();

    expect(result.status, RemoteMembershipRecoveryStatus.accountNotProtected);
    expect(env.remote.discoveryCalls, 0);
  });

  test('missing remote session is blocked before discovery', () async {
    final env = await _Env.create(currentRemoteIdentity: null);
    addTearDown(env.close);
    env.remote.memberships = [_membership('recover-pack')];

    final result = await env.service.restoreActiveMemberships();

    expect(result.status, RemoteMembershipRecoveryStatus.remoteSessionMissing);
    expect(env.remote.discoveryCalls, 0);
  });

  test('discovery config failure maps to typed status', () async {
    final env = await _Env.create();
    addTearDown(env.close);
    env.remote.discoveryFailure =
        RemoteSharedPackFailureReason.supabaseConfigMissing;

    final result = await env.service.restoreActiveMemberships();

    expect(result.status, RemoteMembershipRecoveryStatus.configMissing);
    expect(env.remote.snapshotCalls, 0);
  });

  test('one failed pull produces partiallyRecovered without retry', () async {
    final env = await _Env.create();
    addTearDown(env.close);
    env.remote.memberships = [_membership('ok-pack'), _membership('lost-pack')];
    env.remote.snapshots['ok-pack'] = _snapshot('ok-pack');
    env.remote.snapshotFailures['lost-pack'] =
        RemoteSharedPackFailureReason.remoteRlsRejected;

    final result = await env.service.restoreActiveMemberships();

    expect(result.status, RemoteMembershipRecoveryStatus.partiallyRecovered);
    expect(result.summary.createdLocalMirrorCount, 1);
    expect(result.summary.failedCount, 1);
    expect(env.remote.snapshotCalls, 2);
  });

  test('inactive and archived packs are skipped without importing', () async {
    final env = await _Env.create();
    addTearDown(env.close);
    env.remote.memberships = [
      _membership('removed-pack', memberStatus: 'removed'),
      _membership('archived-pack', packStatus: 'archived'),
    ];

    final result = await env.service.restoreActiveMemberships();

    expect(result.status, RemoteMembershipRecoveryStatus.nothingToRecover);
    expect(result.summary.discoveredCount, 2);
    expect(result.summary.eligibleCount, 0);
    expect(result.summary.skippedCount, 2);
    expect(result.summary.archivedSkippedCount, 1);
    expect(env.remote.snapshotCalls, 0);
  });

  test(
    'repeated recovery refreshes existing mirror without duplicates',
    () async {
      final env = await _Env.create();
      addTearDown(env.close);
      env.remote.memberships = [_membership('recover-pack')];
      env.remote.snapshots['recover-pack'] = _snapshot('recover-pack');

      final first = await env.service.restoreActiveMemberships();
      final second = await env.service.restoreActiveMemberships();

      expect(first.summary.createdLocalMirrorCount, 1);
      expect(second.summary.refreshedExistingCount, 1);
      final packs = await env.db.reminderDao.listItemPacks();
      expect(
        packs.where((pack) => pack.title == 'Recovered cats'),
        hasLength(1),
      );
      expect(
        (await env.db.reminderDao.listPackMembers(
          first.summary.restoredLocalPackIds.single,
        )).length,
        2,
      );
      expect(await env.db.reminderDao.listSyncOutboxEntries(), isEmpty);
    },
  );

  test(
    'existing pending outbox is preserved and reported as warning',
    () async {
      final env = await _Env.create();
      addTearDown(env.close);
      env.remote.memberships = [_membership('recover-pack')];
      env.remote.snapshots['recover-pack'] = _snapshot('recover-pack');
      final first = await env.service.restoreActiveMemberships();
      final itemMetadata = await env.db.reminderDao
          .getRemoteItemSyncMetadataForRemoteItem('remote-item-1');
      await env.insertOutbox(
        localPackId: first.summary.restoredLocalPackIds.single,
        localItemId: itemMetadata!.localItemId,
      );

      final second = await env.service.restoreActiveMemberships();

      expect(second.status, RemoteMembershipRecoveryStatus.restored);
      expect(second.summary.warnings, contains('pendingLocalMutations'));
      final outbox = await env.db.reminderDao.listSyncOutboxEntries();
      expect(outbox.single.status, SyncOutboxStatus.pending);
      expect(env.remote.snapshotCalls, 2);
    },
  );
}

class _Env {
  const _Env({required this.db, required this.remote, required this.service});

  final AppDatabase db;
  final _RecoveryRemoteDataSource remote;
  final RemoteMembershipRecoveryService service;

  static Future<_Env> create({
    bool linkLocalRemoteIdentity = true,
    AuthProviderType localRemoteProvider = AuthProviderType.google,
    RemoteIdentity? currentRemoteIdentity = const RemoteIdentity(
      remoteUserId: 'remote-member',
      provider: AuthProviderType.google,
    ),
  }) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final identity = IdentityRepository(db.reminderDao);
    if (linkLocalRemoteIdentity) {
      await identity.linkRemoteIdentity(
        remoteUserId: 'remote-member',
        provider: localRemoteProvider,
      );
    } else {
      await identity.ensureLocalIdentity();
    }
    final authRepository = _FixedAuthRepository(currentRemoteIdentity);
    final remote = _RecoveryRemoteDataSource();
    final repository = RemoteSharedPackRepository(
      dao: db.reminderDao,
      identityRepository: identity,
      anonymousIdentityService: AnonymousRemoteIdentityService(
        identityRepository: identity,
        authRepository: authRepository,
      ),
      remoteDataSource: remote,
    );
    final service = RemoteMembershipRecoveryService(
      dao: db.reminderDao,
      accountProtectionService: AccountProtectionService(
        identityRepository: identity,
        authRepository: authRepository,
      ),
      remoteRepository: repository,
      importService: RemoteSnapshotImportService(
        dao: db.reminderDao,
        identityRepository: identity,
      ),
    );
    return _Env(db: db, remote: remote, service: service);
  }

  Future<void> close() => db.close();

  Future<void> insertOutbox({
    required int localPackId,
    required int localItemId,
  }) async {
    final now = DateTime(2026, 6, 21, 12, 30).millisecondsSinceEpoch;
    final localUsers = await db.reminderDao.listLocalUsers();
    final localUser = localUsers.firstWhere(
      (user) => user.remoteUserId == 'remote-member',
    );
    await db.reminderDao.insertSyncOutbox(
      SyncOutboxCompanion.insert(
        localPackId: localPackId,
        remotePackId: const Value('recover-pack'),
        localEntityType: RemoteSnapshotImportService.localEntityCompletion,
        localEntityId: const Value(1),
        remoteEntityId: const Value('remote-item-1'),
        actionType: SyncOutboxActionType.completeItem.storageValue,
        payloadJson: jsonEncode({
          'remotePackId': 'recover-pack',
          'remoteItemId': 'remote-item-1',
          'localPackId': localPackId,
          'localItemId': localItemId,
          'localCompletionId': 1,
          'clientMutationId': 'client-mutation-1',
        }),
        clientMutationId: 'client-mutation-1',
        actorLocalUserId: localUser.id,
        actorRemoteUserId: const Value('remote-member'),
        createdAt: now,
        updatedAt: now,
        status: SyncOutboxStatus.pending.storageValue,
      ),
    );
  }
}

class _RecoveryRemoteDataSource extends DisabledRemoteSharedPackDataSource {
  _RecoveryRemoteDataSource()
    : super(RemoteSharedPackFailureReason.remoteUnknownFailure);

  List<RemoteRecoverablePack> memberships = const [];
  RemoteSharedPackFailureReason? discoveryFailure;
  final snapshots = <String, RemotePackSnapshot>{};
  final snapshotFailures = <String, RemoteSharedPackFailureReason>{};
  int discoveryCalls = 0;
  int snapshotCalls = 0;

  @override
  Future<List<RemoteRecoverablePack>> fetchActiveMembershipPacks() async {
    discoveryCalls += 1;
    final failure = discoveryFailure;
    if (failure != null) {
      throw RemoteSharedPackException(failure);
    }
    return memberships;
  }

  @override
  Future<RemotePackSnapshot> fetchPackSnapshot(String remotePackId) async {
    snapshotCalls += 1;
    final failure = snapshotFailures[remotePackId];
    if (failure != null) {
      throw RemoteSharedPackException(failure);
    }
    final snapshot = snapshots[remotePackId];
    if (snapshot == null) {
      throw const RemoteSharedPackException(
        RemoteSharedPackFailureReason.malformedRemoteData,
      );
    }
    return snapshot;
  }
}

class _FixedAuthRepository implements AuthRepository {
  const _FixedAuthRepository(this.identity);

  final RemoteIdentity? identity;

  @override
  Future<RemoteIdentity?> getCurrentRemoteIdentity() async => identity;

  @override
  Future<RemoteIdentity> signInAnonymously() {
    return Future.value(
      const RemoteIdentity(
        remoteUserId: 'remote-member',
        provider: AuthProviderType.supabaseAnonymous,
        isAnonymous: true,
      ),
    );
  }

  @override
  Future<RemoteIdentity> linkWithApple() => throw UnimplementedError();

  @override
  Future<RemoteIdentity> linkWithGoogle() => throw UnimplementedError();

  @override
  Future<RemoteIdentity> linkWithEmail() => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

RemoteRecoverablePack _membership(
  String remotePackId, {
  String memberStatus = 'active',
  String packStatus = 'active',
}) {
  return RemoteRecoverablePack(
    remotePackId: remotePackId,
    name: 'Recovered cats',
    role: 'member',
    memberStatus: memberStatus,
    packStatus: packStatus,
    hostUserId: 'remote-host',
    updatedAt: DateTime(2026, 6, 21),
  );
}

RemotePackSnapshot _snapshot(String remotePackId) {
  return RemotePackSnapshot(
    id: remotePackId,
    name: 'Recovered cats',
    hostUserId: 'remote-host',
    status: 'active',
    createdAt: DateTime(2026, 6, 20),
    updatedAt: DateTime(2026, 6, 21),
    members: [
      RemotePackMemberSnapshot(
        id: 'member-host',
        packId: remotePackId,
        userId: 'remote-host',
        displayName: 'Host',
        role: 'host',
        status: 'active',
        joinedAt: DateTime(2026, 6, 20),
      ),
      RemotePackMemberSnapshot(
        id: 'member-current',
        packId: remotePackId,
        userId: 'remote-member',
        displayName: 'Me',
        role: 'member',
        status: 'active',
        joinedAt: DateTime(2026, 6, 21),
      ),
    ],
    items: [
      RemoteItemSnapshot(
        id: 'remote-item-1',
        packId: remotePackId,
        title: 'Feed cats',
        status: 'active',
        createdByUserId: 'remote-host',
        updatedByUserId: 'remote-host',
        createdAt: DateTime(2026, 6, 20),
        updatedAt: DateTime(2026, 6, 21),
      ),
    ],
    completions: const [],
    activityEvents: [
      RemoteActivityEventSnapshot(
        id: 'remote-activity-1',
        packId: remotePackId,
        actorUserId: 'remote-host',
        actorDisplayNameSnapshot: 'Host',
        entityType: 'pack',
        entityId: remotePackId,
        action: 'pack_created',
        createdAt: DateTime(2026, 6, 20),
      ),
    ],
  );
}
