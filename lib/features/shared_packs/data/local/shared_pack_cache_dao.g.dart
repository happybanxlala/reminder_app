// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_pack_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$SharedPackCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $SharedPackCacheTable get sharedPackCache => attachedDatabase.sharedPackCache;
  $SharedMembershipCacheTable get sharedMembershipCache =>
      attachedDatabase.sharedMembershipCache;
  $SharedItemCacheTable get sharedItemCache => attachedDatabase.sharedItemCache;
  $SharedPendingMutationTable get sharedPendingMutation =>
      attachedDatabase.sharedPendingMutation;
  SharedPackCacheDaoManager get managers => SharedPackCacheDaoManager(this);
}

class SharedPackCacheDaoManager {
  final _$SharedPackCacheDaoMixin _db;
  SharedPackCacheDaoManager(this._db);
  $$SharedPackCacheTableTableManager get sharedPackCache =>
      $$SharedPackCacheTableTableManager(
        _db.attachedDatabase,
        _db.sharedPackCache,
      );
  $$SharedMembershipCacheTableTableManager get sharedMembershipCache =>
      $$SharedMembershipCacheTableTableManager(
        _db.attachedDatabase,
        _db.sharedMembershipCache,
      );
  $$SharedItemCacheTableTableManager get sharedItemCache =>
      $$SharedItemCacheTableTableManager(
        _db.attachedDatabase,
        _db.sharedItemCache,
      );
  $$SharedPendingMutationTableTableManager get sharedPendingMutation =>
      $$SharedPendingMutationTableTableManager(
        _db.attachedDatabase,
        _db.sharedPendingMutation,
      );
}
