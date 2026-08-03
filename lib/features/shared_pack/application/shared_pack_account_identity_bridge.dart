import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/application/account_shared_pack_identity_provider.dart';
import '../../account/application/account_status_ui_controller.dart';
import 'shared_pack_identity_provider.dart';

final sharedPackAccountIdentityProvider = Provider<SharedPackIdentityProvider>((
  ref,
) {
  final runtime = ref.watch(accountIdentityRuntimeProvider);
  return AccountBackedSharedPackIdentityProvider(runtime);
});
