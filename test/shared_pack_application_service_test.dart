import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/account/application/account_identity.dart';
import 'package:reminder_app/features/account/application/account_shared_pack_identity_provider.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/shared_pack/application/shared_pack_application_result.dart';
import 'package:reminder_app/features/shared_pack/application/shared_pack_application_service.dart';
import 'package:reminder_app/features/shared_pack/application/shared_pack_identity_provider.dart';
import 'package:reminder_app/features/shared_pack/data/shared_pack_cache_projection_service.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_dto.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_repository.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_request_ids.dart';

import 'support/fake_account_identity_runtime.dart';

void main() {
  group('SharedPackApplicationService', () {
    test('createSharedPack calls remote then projects pack shell', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final remote = _FakeRemoteRepository();
      final service = _service(db, remote);

      final result = await service.createSharedPack(packName: ' Family Care ');

      expect(result.isSuccess, isTrue);
      final success = result.requireValue;
      expect(success.remoteResponse.remotePackId, _remotePackId);
      expect(success.projection.createdPack, isTrue);
      expect(remote.createRequests, hasLength(1));
      expect(remote.createRequests.single.name, 'Family Care');
      expect(remote.createRequests.single.ownerIdentityId, _ownerIdentityId);

      final mapping = await db
          .select(db.sharedPackRemotePackMappings)
          .getSingle();
      expect(mapping.remotePackId, _remotePackId);
    });

    test('createSharedPack remote failure does not project cache', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final remote = _FakeRemoteRepository()
        ..createFailure = const SharedPackRemoteException(
          requestId: SharedPackRemoteRequestIds.createPackV1,
          operation: 'shared_pack_create_pack_v1',
          message: 'failed',
        );
      final service = _service(db, remote);

      final result = await service.createSharedPack(packName: 'Family Care');

      expect(result.isFailure, isTrue);
      expect(result.error!.code, SharedPackApplicationErrorCode.remoteFailure);
      expect(result.error!.requestId, SharedPackRemoteRequestIds.createPackV1);
      expect(await db.select(db.sharedPackRemotePackMappings).get(), isEmpty);
      final nonSystemPacks = (await db.select(db.itemPacks).get()).where(
        (pack) => !pack.isSystemDefault,
      );
      expect(nonSystemPacks, isEmpty);
    });

    test('generateInvite resolves local pack mapping', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final remote = _FakeRemoteRepository();
      final projection = _projection(db);
      final shell = await projection.projectPackShell(
        remotePackId: _remotePackId,
        packName: 'Family Care',
      );
      final service = _service(db, remote, projection: projection);

      final result = await service.generateInvite(
        localPackId: shell.localPackId,
      );

      expect(result.isSuccess, isTrue);
      expect(result.requireValue.inviteCode, 'K7M4Q9');
      expect(remote.generateInviteRequests, hasLength(1));
      expect(remote.generateInviteRequests.single.remotePackId, _remotePackId);
      expect(
        remote.generateInviteRequests.single.requesterIdentityId,
        _ownerIdentityId,
      );
    });

    test('generateInvite missing pack mapping does not call remote', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final remote = _FakeRemoteRepository();
      final service = _service(db, remote);

      final result = await service.generateInvite(localPackId: 999);

      expect(result.isFailure, isTrue);
      expect(
        result.error!.code,
        SharedPackApplicationErrorCode.missingPackMapping,
      );
      expect(remote.generateInviteRequests, isEmpty);
    });

    test('previewInvite calls remote and does not write local cache', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final remote = _FakeRemoteRepository();
      final service = _service(db, remote);

      final result = await service.previewInvite(inviteCode: 'k7m 4q9');

      expect(result.isSuccess, isTrue);
      expect(result.requireValue.isJoinable, isTrue);
      expect(remote.previewInviteRequests, hasLength(1));
      expect(remote.previewInviteRequests.single.inviteCode, 'k7m 4q9');
      final nonSystemPacks = (await db.select(db.itemPacks).get()).where(
        (pack) => !pack.isSystemDefault,
      );
      expect(nonSystemPacks, isEmpty);
      expect(await db.select(db.sharedPackRemotePackMappings).get(), isEmpty);
    });

    test('joinByInvite calls remote then projects pack shell', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final remote = _FakeRemoteRepository();
      final service = _service(db, remote);

      final result = await service.joinByInvite(inviteCode: 'K7M4Q9');

      expect(result.isSuccess, isTrue);
      expect(result.requireValue.refreshRecommended, isTrue);
      expect(remote.joinByInviteRequests, hasLength(1));
      expect(
        remote.joinByInviteRequests.single.joinerIdentityId,
        _ownerIdentityId,
      );

      final mapping = await db
          .select(db.sharedPackRemotePackMappings)
          .getSingle();
      expect(mapping.remotePackId, _remotePackId);
    });

    test('refreshSharedPack fetches snapshot then projects cache', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final remote = _FakeRemoteRepository();
      final projection = _projection(db);
      final shell = await projection.projectPackShell(
        remotePackId: _remotePackId,
        packName: 'Family Care',
      );
      final service = _service(db, remote, projection: projection);

      final result = await service.refreshSharedPack(
        localPackId: shell.localPackId,
      );

      expect(result.isSuccess, isTrue);
      expect(result.requireValue.createdItemsCount, 1);
      expect(remote.fetchSnapshotRequests, hasLength(1));
      expect(remote.fetchSnapshotRequests.single.remotePackId, _remotePackId);
      expect(
        await db.select(db.sharedPackRemoteItemMappings).get(),
        hasLength(1),
      );
    });

    test(
      'refreshSharedPack missing pack mapping does not call remote',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final remote = _FakeRemoteRepository();
        final service = _service(db, remote);

        final result = await service.refreshSharedPack(localPackId: 999);

        expect(result.isFailure, isTrue);
        expect(
          result.error!.code,
          SharedPackApplicationErrorCode.missingPackMapping,
        );
        expect(remote.fetchSnapshotRequests, isEmpty);
      },
    );

    test(
      'updateSharedItemState resolves item mapping then projects cache',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final remote = _FakeRemoteRepository();
        final projection = _projection(db);
        final snapshot = await projection.projectSnapshot(_snapshot());
        final service = _service(db, remote, projection: projection);

        final result = await service.updateSharedItemState(
          localItemId: snapshot.localItemIds.single,
          newState: ' done ',
          completedAt: DateTime.utc(2026, 7, 6, 8),
        );

        expect(result.isSuccess, isTrue);
        expect(
          result.requireValue.status,
          SharedPackItemStateProjectionStatus.projected,
        );
        expect(remote.updateItemStateRequests, hasLength(1));
        expect(
          remote.updateItemStateRequests.single.remoteItemId,
          _remoteItemId,
        );
        expect(remote.updateItemStateRequests.single.newState, 'done');
      },
    );

    test(
      'updateSharedItemState missing item mapping does not call remote',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final remote = _FakeRemoteRepository();
        final service = _service(db, remote);

        final result = await service.updateSharedItemState(
          localItemId: 999,
          newState: 'done',
        );

        expect(result.isFailure, isTrue);
        expect(
          result.error!.code,
          SharedPackApplicationErrorCode.missingItemMapping,
        );
        expect(remote.updateItemStateRequests, isEmpty);
      },
    );

    test('identity failure does not call remote', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final remote = _FakeRemoteRepository();
      final service = _service(
        db,
        remote,
        identityProvider: _ThrowingIdentityProvider(),
      );

      final result = await service.createSharedPack(packName: 'Family Care');

      expect(result.isFailure, isTrue);
      expect(
        result.error!.code,
        SharedPackApplicationErrorCode.missingIdentity,
      );
      expect(remote.createRequests, isEmpty);
    });

    test('projection failure is surfaced after remote success', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final remote = _FakeRemoteRepository();
      final service = _service(
        db,
        remote,
        projection: _ThrowingProjectionService(db),
      );

      final result = await service.createSharedPack(packName: 'Family Care');

      expect(remote.createRequests, hasLength(1));
      expect(result.isFailure, isTrue);
      expect(
        result.error!.code,
        SharedPackApplicationErrorCode.projectionFailure,
      );
      expect(result.error!.requestId, SharedPackRemoteRequestIds.createPackV1);
    });

    test('application service source does not import or call Supabase', () {
      final source = File(
        'lib/features/shared_pack/application/shared_pack_application_service.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('package:supabase')));
      expect(
        source,
        isNot(
          contains(
            'Supabase'
            'Client',
          ),
        ),
      );
      expect(source, isNot(contains('.rpc(')));
      expect(source, isNot(contains('.from(')));
    });

    test('documentation references application service boundary', () {
      final catalog = File(
        'docs/core/07_remote_request_catalog.md',
      ).readAsStringSync();
      final schemaContract = File(
        'docs/core/08_shared_pack_remote_schema_v1.md',
      ).readAsStringSync();
      final manualTest = File(
        'docs/core/manual_tests/shared_pack_v1_application_service_manual_test.md',
      );

      expect(manualTest.existsSync(), isTrue);
      expect(
        catalog,
        contains('SharedPackApplicationService.createSharedPack'),
      );
      expect(catalog, contains('SharedPackApplicationService.generateInvite'));
      expect(catalog, contains('SharedPackApplicationService.previewInvite'));
      expect(catalog, contains('SharedPackApplicationService.joinByInvite'));
      expect(
        catalog,
        contains('SharedPackApplicationService.refreshSharedPack'),
      );
      expect(
        catalog,
        contains('SharedPackApplicationService.updateSharedItemState'),
      );
      expect(
        catalog,
        contains('test/shared_pack_application_service_test.dart'),
      );
      expect(schemaContract, contains('## 6.1 Application Service Boundary'));
      expect(
        schemaContract,
        contains(
          'lib/features/shared_pack/application/shared_pack_application_service.dart',
        ),
      );
    });
  });
}

SharedPackApplicationService _service(
  AppDatabase db,
  _FakeRemoteRepository remote, {
  SharedPackCacheProjectionService? projection,
  SharedPackIdentityProvider? identityProvider,
}) {
  return SharedPackApplicationService(
    remoteRepository: remote,
    cacheProjectionService: projection ?? _projection(db),
    identityProvider:
        identityProvider ??
        AccountBackedSharedPackIdentityProvider(
          FakeAccountIdentityRuntime(
            AccountIdentitySnapshot.bound(
              identity: AccountIdentity(accountId: _ownerIdentityId),
            ),
          ),
        ),
  );
}

SharedPackCacheProjectionService _projection(AppDatabase db) {
  return SharedPackCacheProjectionService(
    db,
    clock: () => DateTime.utc(2026, 7, 6, 10),
  );
}

FetchSharedPackSnapshotRemoteResponse _snapshot() {
  return FetchSharedPackSnapshotRemoteResponse(
    remotePackId: _remotePackId,
    packName: 'Family Care',
    requesterRole: 'owner',
    items: [
      SharedPackSnapshotItemRemoteDto(
        remoteItemId: _remoteItemId,
        title: 'Medication',
        notes: 'After breakfast',
        state: 'open',
        createdAt: DateTime.utc(2026, 7, 1, 8),
        updatedAt: DateTime.utc(2026, 7, 1, 8, 30),
      ),
    ],
  );
}

class _FakeRemoteRepository implements SharedPackRemoteRepository {
  Object? createFailure;

  final createRequests = <CreateSharedPackRemoteRequest>[];
  final generateInviteRequests = <GenerateSharedPackInviteRemoteRequest>[];
  final previewInviteRequests = <PreviewSharedPackInviteRemoteRequest>[];
  final joinByInviteRequests = <JoinSharedPackByInviteRemoteRequest>[];
  final fetchSnapshotRequests = <FetchSharedPackSnapshotRemoteRequest>[];
  final updateItemStateRequests = <UpdateSharedPackItemStateRemoteRequest>[];

  @override
  Future<CreateSharedPackRemoteResponse> createPack(
    CreateSharedPackRemoteRequest request,
  ) async {
    createRequests.add(request);
    final failure = createFailure;
    if (failure != null) {
      throw failure;
    }
    return const CreateSharedPackRemoteResponse(
      remotePackId: _remotePackId,
      name: 'Family Care',
      ownerMembershipId: _membershipId,
    );
  }

  @override
  Future<GenerateSharedPackInviteRemoteResponse> generateInvite(
    GenerateSharedPackInviteRemoteRequest request,
  ) async {
    generateInviteRequests.add(request);
    return GenerateSharedPackInviteRemoteResponse(
      inviteId: _inviteId,
      inviteCode: 'K7M4Q9',
      expiresAt: DateTime.utc(2026, 7, 7),
    );
  }

  @override
  Future<PreviewSharedPackInviteRemoteResponse> previewInvite(
    PreviewSharedPackInviteRemoteRequest request,
  ) async {
    previewInviteRequests.add(request);
    return const PreviewSharedPackInviteRemoteResponse(
      remotePackId: _remotePackId,
      packName: 'Family Care',
      isJoinable: true,
    );
  }

  @override
  Future<JoinSharedPackByInviteRemoteResponse> joinByInvite(
    JoinSharedPackByInviteRemoteRequest request,
  ) async {
    joinByInviteRequests.add(request);
    return const JoinSharedPackByInviteRemoteResponse(
      remotePackId: _remotePackId,
      membershipId: _membershipId,
      packName: 'Family Care',
    );
  }

  @override
  Future<FetchSharedPackSnapshotRemoteResponse> fetchSnapshot(
    FetchSharedPackSnapshotRemoteRequest request,
  ) async {
    fetchSnapshotRequests.add(request);
    return _snapshot();
  }

  @override
  Future<UpdateSharedPackItemStateRemoteResponse> updateItemState(
    UpdateSharedPackItemStateRemoteRequest request,
  ) async {
    updateItemStateRequests.add(request);
    return UpdateSharedPackItemStateRemoteResponse(
      remoteItemId: request.remoteItemId,
      remotePackId: _remotePackId,
      state: request.newState,
      lastCompletedAt: request.completedAt,
      updatedAt: DateTime.utc(2026, 7, 6, 8, 1),
    );
  }
}

class _ThrowingIdentityProvider implements SharedPackIdentityProvider {
  @override
  Future<String> currentIdentityId() async {
    throw StateError('identity unavailable');
  }
}

class _ThrowingProjectionService extends SharedPackCacheProjectionService {
  _ThrowingProjectionService(super.db);

  @override
  Future<SharedPackPackShellProjectionResult> projectPackShell({
    required String remotePackId,
    required String packName,
  }) async {
    throw StateError('projection unavailable');
  }
}

const _ownerIdentityId = '00000000-0000-4000-8000-000000000001';
const _remotePackId = '00000000-0000-4000-8000-000000000010';
const _remoteItemId = '00000000-0000-4000-8000-000000000020';
const _membershipId = '00000000-0000-4000-8000-000000000030';
const _inviteId = '00000000-0000-4000-8000-000000000040';
