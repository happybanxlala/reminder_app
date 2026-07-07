import 'account_identity.dart';

abstract class AccountIdentityRuntime {
  Future<AccountIdentitySnapshot> currentSnapshot();
}

class DefaultUnboundAccountIdentityRuntime implements AccountIdentityRuntime {
  const DefaultUnboundAccountIdentityRuntime();

  @override
  Future<AccountIdentitySnapshot> currentSnapshot() async {
    return AccountIdentitySnapshot.unbound();
  }
}
