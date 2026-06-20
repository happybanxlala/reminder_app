import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shared_pack_repository.dart';
import '../domain/shared_pack.dart';
import 'database_providers.dart';
import 'identity_providers.dart';

final sharedPackRepositoryProvider = Provider<SharedPackRepository>((ref) {
  return SharedPackRepository(
    ref.watch(appDatabaseProvider).reminderDao,
    currentActorId: () => currentActorId(ref),
  );
});

final currentLocalUserIdProvider = FutureProvider<String>((ref) {
  return ref.watch(currentAppUserIdProvider.future);
});

final localUsersProvider = FutureProvider<List<LocalUser>>((ref) {
  return ref.watch(sharedPackRepositoryProvider).listLocalUsers();
});

final packMembersProvider = FutureProvider.family<List<PackMember>, int>((
  ref,
  packId,
) {
  return ref.watch(sharedPackRepositoryProvider).listPackMembers(packId);
});

final packActivityEventsProvider =
    FutureProvider.family<List<ActivityEvent>, int>((ref, packId) {
      return ref
          .watch(sharedPackRepositoryProvider)
          .listActivityEventsForPack(packId);
    });
