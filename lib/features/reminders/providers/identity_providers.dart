import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/identity_repository.dart';
import '../domain/shared_pack.dart';
import 'database_providers.dart';

final identityRepositoryProvider = Provider<IdentityRepository>((ref) {
  return IdentityRepository(ref.watch(appDatabaseProvider).reminderDao);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FakeAuthRepository();
});

final currentAppUserProvider = FutureProvider<LocalUser>((ref) {
  return ref.watch(identityRepositoryProvider).getCurrentAppUser();
});

final currentAppUserIdProvider = FutureProvider<String>((ref) async {
  return (await ref.watch(currentAppUserProvider.future)).id;
});

Future<String> currentActorId(Ref ref) async {
  return (await ref.read(identityRepositoryProvider).getCurrentAppUser()).id;
}
