import 'package:drift/drift.dart';

import '../../../reminders/data/local/app_database.dart';
import 'shared_pack_cache_tables.dart';

part 'shared_pack_cache_dao.g.dart';

@DriftAccessor(
  tables: [
    SharedPackCache,
    SharedMembershipCache,
    SharedItemCache,
    SharedPendingMutation,
  ],
)
class SharedPackCacheDao extends DatabaseAccessor<AppDatabase>
    with _$SharedPackCacheDaoMixin {
  SharedPackCacheDao(super.attachedDatabase);

  Stream<List<SharedPackCacheRow>> watchAllPackRoots() {
    return (select(
      sharedPackCache,
    )..orderBy([(row) => OrderingTerm.asc(row.remotePackId)])).watch();
  }

  Stream<SharedPackCacheRow?> watchPackRoot(String remotePackId) {
    return (select(sharedPackCache)
          ..where((row) => row.remotePackId.equals(remotePackId)))
        .watchSingleOrNull();
  }

  Stream<SharedMembershipCacheRow?> watchCurrentMembership(
    String remotePackId,
  ) {
    return (select(sharedMembershipCache)..where(
          (row) =>
              row.remotePackId.equals(remotePackId) &
              row.isCurrentMembership.equals(true),
        ))
        .watchSingleOrNull();
  }

  Stream<List<SharedMembershipCacheRow>> watchMemberships(String remotePackId) {
    return (select(sharedMembershipCache)
          ..where((row) => row.remotePackId.equals(remotePackId))
          ..orderBy([(row) => OrderingTerm.asc(row.remoteMemberId)]))
        .watch();
  }

  Stream<List<SharedItemCacheRow>> watchActiveItems(String remotePackId) {
    return (select(sharedItemCache)
          ..where(
            (row) =>
                row.remotePackId.equals(remotePackId) &
                row.type.equals('stateBased') &
                row.lifecycleStatus.equals('active'),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.remoteItemId)]))
        .watch();
  }

  Stream<List<SharedPendingMutationRow>> watchPendingMutationMarkers() {
    return (select(sharedPendingMutation)..orderBy([
          (row) => OrderingTerm.asc(row.createdAt),
          (row) => OrderingTerm.asc(row.operationName),
          (row) => OrderingTerm.asc(row.clientRequestId),
        ]))
        .watch();
  }

  Future<bool> hasUnresolvedMutation(String remotePackId) async {
    final row =
        await (selectOnly(sharedPendingMutation)
              ..addColumns([sharedPendingMutation.localId])
              ..where(
                sharedPendingMutation.targetRemotePackId.equals(remotePackId),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// Emits one coherently reread local snapshot whenever a list dependency
  /// changes. The trigger query observes all relevant tables, while the
  /// transaction prevents a projected graph from being assembled from
  /// different committed database states.
  Stream<SharedPackListCacheSnapshot> watchPackListCacheSnapshot() {
    return _watchReadDependencies().asyncMap((_) {
      return attachedDatabase.transaction(() async {
        final packs = await (select(
          sharedPackCache,
        )..orderBy([(row) => OrderingTerm.asc(row.remotePackId)])).get();
        final memberships =
            await (select(sharedMembershipCache)..orderBy([
                  (row) => OrderingTerm.asc(row.remotePackId),
                  (row) => OrderingTerm.asc(row.remoteMemberId),
                ]))
                .get();
        final pending = await _orderedPendingQuery().get();
        return SharedPackListCacheSnapshot(
          packs: packs,
          memberships: memberships,
          pending: pending,
        );
      });
    });
  }

  Stream<SharedPackDetailCacheSnapshot> watchPackDetailCacheSnapshot(
    String remotePackId,
  ) {
    return _watchReadDependencies().asyncMap((_) {
      return attachedDatabase.transaction(() async {
        final pack =
            await (select(sharedPackCache)
                  ..where((row) => row.remotePackId.equals(remotePackId)))
                .getSingleOrNull();
        final memberships =
            await (select(sharedMembershipCache)
                  ..where((row) => row.remotePackId.equals(remotePackId))
                  ..orderBy([(row) => OrderingTerm.asc(row.remoteMemberId)]))
                .get();
        final items =
            await (select(sharedItemCache)
                  ..where((row) => row.remotePackId.equals(remotePackId))
                  ..orderBy([(row) => OrderingTerm.asc(row.remoteItemId)]))
                .get();
        final pending =
            await (_orderedPendingQuery()
                  ..where((row) => row.targetRemotePackId.equals(remotePackId)))
                .get();
        return SharedPackDetailCacheSnapshot(
          pack: pack,
          memberships: memberships,
          activeItems: items,
          pending: pending,
        );
      });
    });
  }

  Future<SharedMutationBaseCacheSnapshot?> readMutationBaseCacheSnapshot(
    String remotePackId,
  ) {
    return attachedDatabase.transaction(() async {
      final pack =
          await (select(sharedPackCache)
                ..where((row) => row.remotePackId.equals(remotePackId)))
              .getSingleOrNull();
      if (pack == null) {
        return null;
      }
      final memberships =
          await (select(sharedMembershipCache)
                ..where((row) => row.remotePackId.equals(remotePackId))
                ..orderBy([(row) => OrderingTerm.asc(row.remoteMemberId)]))
              .get();
      final items =
          await (select(sharedItemCache)
                ..where((row) => row.remotePackId.equals(remotePackId))
                ..orderBy([(row) => OrderingTerm.asc(row.remoteItemId)]))
              .get();
      final hasPending = await hasUnresolvedMutation(remotePackId);
      return SharedMutationBaseCacheSnapshot(
        pack: pack,
        memberships: memberships,
        activeItems: items,
        hasUnresolvedMutation: hasPending,
      );
    });
  }

  Stream<QueryRow> _watchReadDependencies() {
    return customSelect(
      'SELECT 1 AS shared_cache_read_trigger',
      readsFrom: {
        sharedPackCache,
        sharedMembershipCache,
        sharedItemCache,
        sharedPendingMutation,
      },
    ).watchSingle();
  }

  SimpleSelectStatement<$SharedPendingMutationTable, SharedPendingMutationRow>
  _orderedPendingQuery() {
    return select(sharedPendingMutation)..orderBy([
      (row) => OrderingTerm.asc(row.createdAt),
      (row) => OrderingTerm.asc(row.operationName),
      (row) => OrderingTerm.asc(row.clientRequestId),
    ]);
  }

  Future<int> insertPack(SharedPackCacheCompanion entry) {
    return into(sharedPackCache).insert(entry);
  }

  Future<int> insertMembership(SharedMembershipCacheCompanion entry) {
    return into(sharedMembershipCache).insert(entry);
  }

  Future<int> insertItem(SharedItemCacheCompanion entry) {
    return into(sharedItemCache).insert(entry);
  }

  Future<int> insertPendingMutation(SharedPendingMutationCompanion entry) {
    return into(sharedPendingMutation).insert(entry);
  }

  Future<SharedItemCacheRow?> getItem({
    required String remotePackId,
    required String remoteItemId,
  }) {
    return (select(sharedItemCache)..where(
          (row) =>
              row.remotePackId.equals(remotePackId) &
              row.remoteItemId.equals(remoteItemId),
        ))
        .getSingleOrNull();
  }

  Future<int> updateItem({
    required String remotePackId,
    required String remoteItemId,
    required SharedItemCacheCompanion changes,
  }) {
    return (update(sharedItemCache)..where(
          (row) =>
              row.remotePackId.equals(remotePackId) &
              row.remoteItemId.equals(remoteItemId),
        ))
        .write(changes);
  }

  Future<int> deleteItem({
    required String remotePackId,
    required String remoteItemId,
  }) {
    return (delete(sharedItemCache)..where(
          (row) =>
              row.remotePackId.equals(remotePackId) &
              row.remoteItemId.equals(remoteItemId),
        ))
        .go();
  }
}

final class SharedPackListCacheSnapshot {
  const SharedPackListCacheSnapshot({
    required this.packs,
    required this.memberships,
    required this.pending,
  });

  final List<SharedPackCacheRow> packs;
  final List<SharedMembershipCacheRow> memberships;
  final List<SharedPendingMutationRow> pending;
}

final class SharedPackDetailCacheSnapshot {
  const SharedPackDetailCacheSnapshot({
    required this.pack,
    required this.memberships,
    required this.activeItems,
    required this.pending,
  });

  final SharedPackCacheRow? pack;
  final List<SharedMembershipCacheRow> memberships;
  final List<SharedItemCacheRow> activeItems;
  final List<SharedPendingMutationRow> pending;
}

final class SharedMutationBaseCacheSnapshot {
  const SharedMutationBaseCacheSnapshot({
    required this.pack,
    required this.memberships,
    required this.activeItems,
    required this.hasUnresolvedMutation,
  });

  final SharedPackCacheRow pack;
  final List<SharedMembershipCacheRow> memberships;
  final List<SharedItemCacheRow> activeItems;
  final bool hasUnresolvedMutation;
}
