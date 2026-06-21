import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote_shared_pack_data_source.dart';
import '../data/remote_shared_pack_models.dart';
import '../data/remote_shared_pack_repository.dart';
import '../data/supabase_config.dart';
import 'database_providers.dart';
import 'identity_providers.dart';

final remoteSharedPackDataSourceProvider = Provider<RemoteSharedPackDataSource>(
  (ref) {
    final runtime = ref.watch(supabaseRuntimeProvider);
    if (runtime.isAvailable) {
      return SupabaseRemoteSharedPackDataSource(runtime);
    }
    final reason = runtime.status == SupabaseRuntimeStatus.missingConfig
        ? RemoteSharedPackFailureReason.supabaseConfigMissing
        : RemoteSharedPackFailureReason.remoteNetworkFailed;
    return DisabledRemoteSharedPackDataSource(reason);
  },
);

final remoteSharedPackRepositoryProvider = Provider<RemoteSharedPackRepository>(
  (ref) {
    return RemoteSharedPackRepository(
      dao: ref.watch(appDatabaseProvider).reminderDao,
      identityRepository: ref.watch(identityRepositoryProvider),
      anonymousIdentityService: ref.watch(
        anonymousRemoteIdentityServiceProvider,
      ),
      remoteDataSource: ref.watch(remoteSharedPackDataSourceProvider),
    );
  },
);
