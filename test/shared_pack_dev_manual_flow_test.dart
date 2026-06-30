import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/shared_pack/application/shared_pack_application_service.dart';
import 'package:reminder_app/features/shared_pack/application/shared_pack_identity_provider.dart';
import 'package:reminder_app/features/shared_pack/data/shared_pack_cache_projection_service.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_dto.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_repository.dart';

void main() {
  group('Shared Pack dev/manual flow harness', () {
    test('runs owner and joiner application service flow end to end', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final fakeRemote = _DevManualFakeRemoteRepository();
      final projection = SharedPackCacheProjectionService(
        db,
        clock: () => DateTime.utc(2026, 7, 7, 10),
      );
      final ownerService = _service(
        remote: fakeRemote,
        projection: projection,
        identityId: _ownerIdentityId,
      );
      final joinerService = _service(
        remote: fakeRemote,
        projection: projection,
        identityId: _joinerIdentityId,
      );

      final createResult = await ownerService.createSharedPack(
        packName: 'Family Care',
      );
      expect(createResult.isSuccess, isTrue);
      final createdPack = createResult.requireValue;
      expect(createdPack.remoteResponse.remotePackId, _remotePackId);
      expect(createdPack.projection.createdPack, isTrue);

      final packMappingAfterCreate = await db
          .select(db.sharedPackRemotePackMappings)
          .getSingle();
      expect(packMappingAfterCreate.remotePackId, _remotePackId);
      final localPackId = packMappingAfterCreate.localPackId;

      final inviteResult = await ownerService.generateInvite(
        localPackId: localPackId,
      );
      expect(inviteResult.isSuccess, isTrue);
      final inviteCode = inviteResult.requireValue.inviteCode;
      expect(inviteCode, hasLength(6));
      expect(
        RegExp(r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$').hasMatch(inviteCode),
        isTrue,
      );

      final packCountBeforePreview = await db
          .select(db.sharedPackRemotePackMappings)
          .get()
          .then((rows) => rows.length);
      final previewResult = await joinerService.previewInvite(
        inviteCode: inviteCode,
      );
      expect(previewResult.isSuccess, isTrue);
      expect(previewResult.requireValue.remotePackId, _remotePackId);
      final packCountAfterPreview = await db
          .select(db.sharedPackRemotePackMappings)
          .get()
          .then((rows) => rows.length);
      expect(packCountAfterPreview, packCountBeforePreview);

      final joinResult = await joinerService.joinByInvite(
        inviteCode: inviteCode,
      );
      expect(joinResult.isSuccess, isTrue);
      expect(joinResult.requireValue.refreshRecommended, isTrue);
      expect(joinResult.requireValue.projection.localPackId, localPackId);
      expect(
        await db.select(db.sharedPackRemotePackMappings).get(),
        hasLength(1),
      );

      final firstRefresh = await joinerService.refreshSharedPack(
        localPackId: localPackId,
      );
      expect(firstRefresh.isSuccess, isTrue);
      expect(firstRefresh.requireValue.createdItemsCount, 1);
      expect(firstRefresh.requireValue.updatedItemsCount, 0);
      expect(
        await db.select(db.sharedPackRemoteItemMappings).get(),
        hasLength(1),
      );
      final itemMapping = await db
          .select(db.sharedPackRemoteItemMappings)
          .getSingle();
      expect(itemMapping.remoteItemId, _remoteItemId);
      final localItemId = itemMapping.localItemId;

      final idempotentRefresh = await joinerService.refreshSharedPack(
        localPackId: localPackId,
      );
      expect(idempotentRefresh.isSuccess, isTrue);
      expect(idempotentRefresh.requireValue.createdItemsCount, 0);
      expect(idempotentRefresh.requireValue.updatedItemsCount, 1);
      expect(
        await db.select(db.sharedPackRemotePackMappings).get(),
        hasLength(1),
      );
      expect(
        await db.select(db.sharedPackRemoteItemMappings).get(),
        hasLength(1),
      );

      final completedAt = DateTime.utc(2026, 7, 7, 9, 30);
      final updateResult = await joinerService.updateSharedItemState(
        localItemId: localItemId,
        newState: 'done',
        completedAt: completedAt,
      );
      expect(updateResult.isSuccess, isTrue);
      final mappedItemAfterUpdate = await (db.select(
        db.items,
      )..where((table) => table.id.equals(localItemId))).getSingle();
      expect(
        mappedItemAfterUpdate.lastDoneAt,
        completedAt.millisecondsSinceEpoch,
      );

      final mappingAfterUpdate = await db
          .select(db.sharedPackRemoteItemMappings)
          .getSingle();
      expect(mappingAfterUpdate.lastRemoteState, 'done');
      expect(
        mappingAfterUpdate.lastRemoteCompletedAt,
        completedAt.millisecondsSinceEpoch,
      );

      final secondRefresh = await ownerService.refreshSharedPack(
        localPackId: localPackId,
      );
      expect(secondRefresh.isSuccess, isTrue);
      expect(secondRefresh.requireValue.createdItemsCount, 0);
      expect(secondRefresh.requireValue.updatedItemsCount, 1);
      expect(await db.select(db.items).get(), hasLength(1));
      expect(
        await db.select(db.sharedPackRemoteItemMappings).get(),
        hasLength(1),
      );

      final mappedItemAfterSecondRefresh = await (db.select(
        db.items,
      )..where((table) => table.id.equals(localItemId))).getSingle();
      expect(
        mappedItemAfterSecondRefresh.lastDoneAt,
        completedAt.millisecondsSinceEpoch,
      );
      expect(fakeRemote.createRequests, hasLength(1));
      expect(fakeRemote.generateInviteRequests, hasLength(1));
      expect(fakeRemote.previewInviteRequests, hasLength(1));
      expect(fakeRemote.joinByInviteRequests, hasLength(1));
      expect(fakeRemote.fetchSnapshotRequests, hasLength(3));
      expect(fakeRemote.updateItemStateRequests, hasLength(1));
    });

    test('harness source is dev/manual only and contains no secrets', () {
      final source = File(
        'test/shared_pack_dev_manual_flow_test.dart',
      ).readAsStringSync();
      final forbiddenSecrets = [
        'SUPABASE'
            '_URL',
        'anon'
            '_key',
        'service'
            '_role',
        'DATABASE'
            '_URL',
        'postgresql'
            '://',
        'supabase'
            '.co',
        'ey'
            'J',
      ];
      final forbiddenProductionImports = [
        'package:reminder_app/'
            'app/',
        'package:reminder_app/features/reminders/'
            'ui/',
        'package:reminder_app/features/reminders/'
            'providers/',
      ];

      for (final pattern in [
        ...forbiddenSecrets,
        ...forbiddenProductionImports,
      ]) {
        expect(source, isNot(contains(pattern)));
      }
    });

    test('docs reference dev/manual flow coverage', () {
      final catalog = File(
        'docs/core/07_remote_request_catalog.md',
      ).readAsStringSync();
      final schemaContract = File(
        'docs/core/08_shared_pack_remote_schema_v1.md',
      ).readAsStringSync();
      final manualDoc = File(
        'docs/core/manual_tests/shared_pack_v1_application_service_manual_test.md',
      ).readAsStringSync();

      expect(catalog, contains('test/shared_pack_dev_manual_flow_test.dart'));
      expect(schemaContract, contains('## 6.2 Dev-only Manual Flow Harness'));
      expect(
        schemaContract,
        contains('test/shared_pack_dev_manual_flow_test.dart'),
      );
      expect(
        manualDoc,
        contains('flutter test test/shared_pack_dev_manual_flow_test.dart'),
      );
    });
  });
}

SharedPackApplicationService _service({
  required SharedPackRemoteRepository remote,
  required SharedPackCacheProjectionService projection,
  required String identityId,
}) {
  return SharedPackApplicationService(
    remoteRepository: remote,
    cacheProjectionService: projection,
    identityProvider: StaticSharedPackIdentityProvider(identityId),
  );
}

class _DevManualFakeRemoteRepository implements SharedPackRemoteRepository {
  _DevManualFakeRemoteRepository()
    : _item = _RemoteItemState(
        remoteItemId: _remoteItemId,
        title: 'Medication',
        notes: 'After breakfast',
        state: 'open',
        createdAt: DateTime.utc(2026, 7, 1, 8),
        updatedAt: DateTime.utc(2026, 7, 1, 8, 30),
      );

  final _RemoteItemState _item;
  String? _packName;
  var _ownerMembershipCreated = false;
  var _joinerMembershipCreated = false;

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
    _packName = request.name;
    _ownerMembershipCreated = true;
    return const CreateSharedPackRemoteResponse(
      remotePackId: _remotePackId,
      name: 'Family Care',
      ownerMembershipId: _ownerMembershipId,
    );
  }

  @override
  Future<GenerateSharedPackInviteRemoteResponse> generateInvite(
    GenerateSharedPackInviteRemoteRequest request,
  ) async {
    generateInviteRequests.add(request);
    _expectPackExists();
    expect(request.remotePackId, _remotePackId);
    expect(request.requesterIdentityId, _ownerIdentityId);
    return GenerateSharedPackInviteRemoteResponse(
      inviteId: _inviteId,
      inviteCode: _inviteCode,
      expiresAt: DateTime.utc(2026, 7, 8),
    );
  }

  @override
  Future<PreviewSharedPackInviteRemoteResponse> previewInvite(
    PreviewSharedPackInviteRemoteRequest request,
  ) async {
    previewInviteRequests.add(request);
    _expectPackExists();
    expect(request.inviteCode, _inviteCode);
    return PreviewSharedPackInviteRemoteResponse(
      remotePackId: _remotePackId,
      packName: _packName,
      isJoinable: true,
    );
  }

  @override
  Future<JoinSharedPackByInviteRemoteResponse> joinByInvite(
    JoinSharedPackByInviteRemoteRequest request,
  ) async {
    joinByInviteRequests.add(request);
    _expectPackExists();
    expect(request.inviteCode, _inviteCode);
    expect(request.joinerIdentityId, _joinerIdentityId);
    _joinerMembershipCreated = true;
    return JoinSharedPackByInviteRemoteResponse(
      remotePackId: _remotePackId,
      membershipId: _joinerMembershipId,
      packName: _packName!,
    );
  }

  @override
  Future<FetchSharedPackSnapshotRemoteResponse> fetchSnapshot(
    FetchSharedPackSnapshotRemoteRequest request,
  ) async {
    fetchSnapshotRequests.add(request);
    _expectPackExists();
    expect(request.remotePackId, _remotePackId);
    expect(
      request.requesterIdentityId == _ownerIdentityId ||
          request.requesterIdentityId == _joinerIdentityId,
      isTrue,
    );
    if (request.requesterIdentityId == _joinerIdentityId) {
      expect(_joinerMembershipCreated, isTrue);
    }
    return FetchSharedPackSnapshotRemoteResponse(
      remotePackId: _remotePackId,
      packName: _packName!,
      requesterRole: request.requesterIdentityId == _ownerIdentityId
          ? 'owner'
          : 'member',
      items: [_item.toDto()],
    );
  }

  @override
  Future<UpdateSharedPackItemStateRemoteResponse> updateItemState(
    UpdateSharedPackItemStateRemoteRequest request,
  ) async {
    updateItemStateRequests.add(request);
    _expectPackExists();
    expect(request.remoteItemId, _remoteItemId);
    expect(request.requesterIdentityId, _joinerIdentityId);
    _item.state = request.newState;
    _item.lastCompletedAt = request.completedAt;
    _item.updatedAt = DateTime.utc(2026, 7, 7, 9, 31);
    return UpdateSharedPackItemStateRemoteResponse(
      remoteItemId: _remoteItemId,
      remotePackId: _remotePackId,
      state: _item.state,
      lastCompletedAt: _item.lastCompletedAt,
      updatedAt: _item.updatedAt,
    );
  }

  void _expectPackExists() {
    expect(_packName, isNotNull);
    expect(_ownerMembershipCreated, isTrue);
  }
}

class _RemoteItemState {
  _RemoteItemState({
    required this.remoteItemId,
    required this.title,
    required this.notes,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
  });

  final String remoteItemId;
  final String title;
  final String notes;
  String state;
  DateTime? lastCompletedAt;
  final DateTime createdAt;
  DateTime updatedAt;

  SharedPackSnapshotItemRemoteDto toDto() {
    return SharedPackSnapshotItemRemoteDto(
      remoteItemId: remoteItemId,
      title: title,
      notes: notes,
      state: state,
      lastCompletedAt: lastCompletedAt,
      updatedByIdentityId: _joinerIdentityId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

const _ownerIdentityId = '00000000-0000-4000-8000-000000000001';
const _joinerIdentityId = '00000000-0000-4000-8000-000000000002';
const _remotePackId = '00000000-0000-4000-8000-000000000010';
const _remoteItemId = '00000000-0000-4000-8000-000000000020';
const _ownerMembershipId = '00000000-0000-4000-8000-000000000030';
const _joinerMembershipId = '00000000-0000-4000-8000-000000000031';
const _inviteId = '00000000-0000-4000-8000-000000000040';
const _inviteCode = 'K7M4Q9';
