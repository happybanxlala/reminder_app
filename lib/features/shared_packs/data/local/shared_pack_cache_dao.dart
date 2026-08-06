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
