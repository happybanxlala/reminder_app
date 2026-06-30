import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';
import 'package:reminder_app/features/shared_pack/data/shared_pack_cache_projection_service.dart';
import 'package:reminder_app/features/shared_pack/remote/shared_pack_remote_dto.dart';

void main() {
  group('SharedPackCacheProjectionService', () {
    test('pack shell projection creates and resolves pack mapping', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final service = _service(db);

      final result = await service.projectPackShell(
        remotePackId: _remotePackId,
        packName: 'Family Care',
      );

      expect(result.createdPack, isTrue);
      expect(result.updatedPack, isFalse);

      final mapping = await service.resolveRemotePackMappingByLocalPackId(
        result.localPackId,
      );
      expect(mapping, isA<SharedPackRemotePackMappingRef>());
      expect(mapping!.remotePackId, _remotePackId);

      final pack = await (db.select(
        db.itemPacks,
      )..where((table) => table.id.equals(result.localPackId))).getSingle();
      expect(pack.title, 'Family Care');
      expect(pack.description, 'Shared Pack cache projection');
    });

    test('pack shell projection is idempotent and updates title', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final service = _service(db);

      final first = await service.projectPackShell(
        remotePackId: _remotePackId,
        packName: 'Family Care',
      );
      final second = await service.projectPackShell(
        remotePackId: _remotePackId,
        packName: 'Updated Family Care',
      );

      expect(second.createdPack, isFalse);
      expect(second.updatedPack, isTrue);
      expect(second.localPackId, first.localPackId);
      expect(
        await db.select(db.sharedPackRemotePackMappings).get(),
        hasLength(1),
      );

      final pack = await (db.select(
        db.itemPacks,
      )..where((table) => table.id.equals(first.localPackId))).getSingle();
      expect(pack.title, 'Updated Family Care');
    });

    test('creates pack and item mappings for a new remote snapshot', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final service = _service(db);

      final result = await service.projectSnapshot(_snapshot());

      expect(result.createdPack, isTrue);
      expect(result.createdItemsCount, 2);
      expect(result.updatedItemsCount, 0);

      final packs = await db.select(db.itemPacks).get();
      final nonSystemPacks = packs.where((pack) => !pack.isSystemDefault);
      expect(nonSystemPacks, hasLength(1));
      expect(nonSystemPacks.single.title, 'Family Care');

      final packMappings = await db
          .select(db.sharedPackRemotePackMappings)
          .get();
      expect(packMappings, hasLength(1));
      expect(packMappings.single.localPackId, result.localPackId);
      expect(packMappings.single.remotePackId, _remotePackId);

      final items = await db.select(db.items).get();
      expect(items, hasLength(2));
      expect(
        items.map((item) => item.title),
        containsAll(['Medication', 'Water plants']),
      );

      final itemMappings = await db
          .select(db.sharedPackRemoteItemMappings)
          .get();
      expect(itemMappings, hasLength(2));
      expect(
        itemMappings.map((mapping) => mapping.remoteItemId),
        containsAll([_remoteItemIdA, _remoteItemIdB]),
      );
      expect(
        itemMappings.every(
          (mapping) => mapping.localPackId == result.localPackId,
        ),
        isTrue,
      );
    });

    test('repeated snapshot projection is idempotent', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final service = _service(db);

      final first = await service.projectSnapshot(_snapshot());
      final second = await service.projectSnapshot(_snapshot());

      expect(second.createdPack, isFalse);
      expect(second.updatedPack, isTrue);
      expect(second.localPackId, first.localPackId);
      expect(second.createdItemsCount, 0);
      expect(second.updatedItemsCount, 2);
      expect(second.localItemIds, first.localItemIds);
      expect(
        await db.select(db.sharedPackRemotePackMappings).get(),
        hasLength(1),
      );
      expect(
        await db.select(db.sharedPackRemoteItemMappings).get(),
        hasLength(2),
      );

      final nonSystemPacks = (await db.select(db.itemPacks).get()).where(
        (pack) => !pack.isSystemDefault,
      );
      expect(nonSystemPacks, hasLength(1));
      expect(await db.select(db.items).get(), hasLength(2));
    });

    test('later snapshot updates pack and item cache fields', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final service = _service(db);

      await service.projectSnapshot(_snapshot());
      await service.projectSnapshot(
        _snapshot(
          packName: 'Family Care Updated',
          items: [
            _snapshotItem(
              remoteItemId: _remoteItemIdA,
              title: 'Medication Updated',
              notes: 'After breakfast',
              state: 'done',
              lastCompletedAt: DateTime.utc(2026, 7, 3, 8),
              updatedAt: DateTime.utc(2026, 7, 3, 8, 1),
            ),
          ],
        ),
      );

      final packMapping = await db
          .select(db.sharedPackRemotePackMappings)
          .getSingle();
      final pack =
          await (db.select(db.itemPacks)
                ..where((table) => table.id.equals(packMapping.localPackId)))
              .getSingle();
      expect(pack.title, 'Family Care Updated');

      final itemMapping =
          await (db.select(db.sharedPackRemoteItemMappings)
                ..where((table) => table.remoteItemId.equals(_remoteItemIdA)))
              .getSingle();
      final item =
          await (db.select(db.items)
                ..where((table) => table.id.equals(itemMapping.localItemId)))
              .getSingle();
      expect(item.title, 'Medication Updated');
      expect(item.description, 'After breakfast');
      expect(
        item.lastDoneAt,
        DateTime.utc(2026, 7, 3, 8).millisecondsSinceEpoch,
      );
      expect(
        item.updatedAt,
        DateTime.utc(2026, 7, 3, 8, 1).millisecondsSinceEpoch,
      );
      expect(itemMapping.lastRemoteState, 'done');
      expect(
        itemMapping.lastRemoteCompletedAt,
        DateTime.utc(2026, 7, 3, 8).millisecondsSinceEpoch,
      );
    });

    test('item state projection updates mapped local item', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final service = _service(db);

      final snapshotResult = await service.projectSnapshot(_snapshot());
      final stateResult = await service.projectItemState(
        UpdateSharedPackItemStateRemoteResponse(
          remoteItemId: _remoteItemIdA,
          remotePackId: _remotePackId,
          state: 'done',
          lastCompletedAt: DateTime.utc(2026, 7, 4, 9),
          updatedAt: DateTime.utc(2026, 7, 4, 9, 1),
        ),
      );

      expect(stateResult.status, SharedPackItemStateProjectionStatus.projected);
      expect(stateResult.localPackId, snapshotResult.localPackId);

      final mapping =
          await (db.select(db.sharedPackRemoteItemMappings)
                ..where((table) => table.remoteItemId.equals(_remoteItemIdA)))
              .getSingle();
      final item = await (db.select(
        db.items,
      )..where((table) => table.id.equals(mapping.localItemId))).getSingle();
      expect(
        item.lastDoneAt,
        DateTime.utc(2026, 7, 4, 9).millisecondsSinceEpoch,
      );
      expect(
        item.updatedAt,
        DateTime.utc(2026, 7, 4, 9, 1).millisecondsSinceEpoch,
      );
      expect(mapping.lastRemoteState, 'done');
    });

    test('mapping resolvers return null when mappings are missing', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final service = _service(db);

      expect(
        await service.resolveRemotePackMappingByLocalPackId(1001),
        equals(null),
      );
      expect(
        await service.resolveRemoteItemMappingByLocalItemId(2001),
        equals(null),
      );
    });

    test('mapping resolvers return pack and item mapping refs', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final service = _service(db);

      final projection = await service.projectSnapshot(_snapshot());
      final localItemId = projection.localItemIds.first;

      final packMapping = await service.resolveRemotePackMappingByLocalPackId(
        projection.localPackId,
      );
      final itemMapping = await service.resolveRemoteItemMappingByLocalItemId(
        localItemId,
      );

      expect(packMapping, isA<SharedPackRemotePackMappingRef>());
      expect(packMapping!.remotePackId, _remotePackId);
      expect(itemMapping, isA<SharedPackRemoteItemMappingRef>());
      expect(itemMapping!.localItemId, localItemId);
      expect(itemMapping.remoteItemId, _remoteItemIdA);
      expect(itemMapping.localPackId, projection.localPackId);
      expect(itemMapping.remotePackId, _remotePackId);
    });

    test(
      'item state projection without mapping is an explicit no-op',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final service = _service(db);

        final result = await service.projectItemState(
          UpdateSharedPackItemStateRemoteResponse(
            remoteItemId: _remoteItemIdA,
            remotePackId: _remotePackId,
            state: 'done',
            lastCompletedAt: DateTime.utc(2026, 7, 4, 9),
            updatedAt: DateTime.utc(2026, 7, 4, 9, 1),
          ),
        );

        expect(
          result.status,
          SharedPackItemStateProjectionStatus.missingMapping,
        );
        expect(await db.select(db.sharedPackRemoteItemMappings).get(), isEmpty);
        expect(await db.select(db.items).get(), isEmpty);
      },
    );

    test('projection does not alter existing Personal Pack data', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final service = _service(db);
      final createdAt = DateTime.utc(2026, 7, 1).millisecondsSinceEpoch;
      final personalPackId = await db
          .into(db.itemPacks)
          .insert(
            ItemPacksCompanion.insert(
              title: 'Personal Pack',
              description: const Value('Keep this untouched'),
              iconEmoji: const Value('🏠'),
              status: const Value('active'),
              isSystemDefault: const Value(false),
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
          );

      await service.projectSnapshot(_snapshot());

      final personalPack = await (db.select(
        db.itemPacks,
      )..where((table) => table.id.equals(personalPackId))).getSingle();
      expect(personalPack.title, 'Personal Pack');
      expect(personalPack.description, 'Keep this untouched');

      final mapping = await db
          .select(db.sharedPackRemotePackMappings)
          .getSingle();
      expect(mapping.localPackId, isNot(personalPackId));
    });

    test('projection layer does not import or call Supabase', () {
      final source = File(
        'lib/features/shared_pack/data/shared_pack_cache_projection_service.dart',
      ).readAsStringSync();

      expect(
        source,
        isNot(
          contains(
            'package:'
            'supabase',
          ),
        ),
      );
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

    test('documentation references mapping and projection boundaries', () {
      final coreSpec = File(
        'docs/core/04_core_model_spec_v1.md',
      ).readAsStringSync();
      final schemaContract = File(
        'docs/core/08_shared_pack_remote_schema_v1.md',
      ).readAsStringSync();
      final catalog = File(
        'docs/core/07_remote_request_catalog.md',
      ).readAsStringSync();

      for (final doc in [coreSpec, schemaContract, catalog]) {
        expect(doc, contains('shared_pack_remote_pack_mappings'));
        expect(doc, contains('shared_pack_remote_item_mappings'));
      }
      expect(
        schemaContract,
        contains(
          'lib/features/shared_pack/data/shared_pack_cache_projection_service.dart',
        ),
      );
      expect(catalog, contains('local_pack_id <-> remote_pack_id'));
      expect(catalog, contains('local_item_id <-> remote_item_id'));
    });
  });
}

SharedPackCacheProjectionService _service(AppDatabase db) {
  return SharedPackCacheProjectionService(
    db,
    clock: () => DateTime.utc(2026, 7, 5, 10),
  );
}

FetchSharedPackSnapshotRemoteResponse _snapshot({
  String packName = 'Family Care',
  List<SharedPackSnapshotItemRemoteDto>? items,
}) {
  return FetchSharedPackSnapshotRemoteResponse(
    remotePackId: _remotePackId,
    packName: packName,
    requesterRole: 'owner',
    items:
        items ??
        [
          _snapshotItem(remoteItemId: _remoteItemIdA, title: 'Medication'),
          _snapshotItem(remoteItemId: _remoteItemIdB, title: 'Water plants'),
        ],
  );
}

SharedPackSnapshotItemRemoteDto _snapshotItem({
  required String remoteItemId,
  required String title,
  String? notes = 'Original notes',
  String state = 'open',
  DateTime? lastCompletedAt,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return SharedPackSnapshotItemRemoteDto(
    remoteItemId: remoteItemId,
    title: title,
    notes: notes,
    schedulePayload: const {'kind': 'unmapped'},
    state: state,
    lastCompletedAt: lastCompletedAt,
    updatedByIdentityId: _ownerIdentityId,
    createdAt: createdAt ?? DateTime.utc(2026, 7, 1, 8),
    updatedAt: updatedAt ?? DateTime.utc(2026, 7, 1, 8, 30),
  );
}

const _remotePackId = '00000000-0000-4000-8000-000000000010';
const _remoteItemIdA = '00000000-0000-4000-8000-000000000020';
const _remoteItemIdB = '00000000-0000-4000-8000-000000000021';
const _ownerIdentityId = '00000000-0000-4000-8000-000000000001';
