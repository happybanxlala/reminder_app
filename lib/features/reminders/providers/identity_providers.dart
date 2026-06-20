import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/anonymous_remote_identity_service.dart';
import '../data/auth_repository.dart';
import '../data/identity_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../data/supabase_config.dart';
import '../domain/shared_pack.dart';
import 'database_providers.dart';

final identityRepositoryProvider = Provider<IdentityRepository>((ref) {
  return IdentityRepository(ref.watch(appDatabaseProvider).reminderDao);
});

final supabaseRuntimeProvider = Provider<SupabaseRuntime>((ref) {
  return currentReminderSupabaseRuntime();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final runtime = ref.watch(supabaseRuntimeProvider);
  if (runtime.isAvailable) {
    return SupabaseAuthRepository(runtime);
  }
  final reason = runtime.status == SupabaseRuntimeStatus.missingConfig
      ? RemoteAuthFailureReason.configMissing
      : RemoteAuthFailureReason.unavailable;
  return DisabledAuthRepository(reason);
});

final anonymousRemoteIdentityServiceProvider =
    Provider<AnonymousRemoteIdentityService>((ref) {
      return AnonymousRemoteIdentityService(
        identityRepository: ref.watch(identityRepositoryProvider),
        authRepository: ref.watch(authRepositoryProvider),
      );
    });

final supabaseRuntimeStatusProvider = Provider<SupabaseRuntimeStatus>((ref) {
  return ref.watch(supabaseRuntimeProvider).status;
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
