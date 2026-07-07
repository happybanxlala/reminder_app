import 'package:reminder_app/features/account/application/account_identity.dart';
import 'package:reminder_app/features/account/application/account_identity_runtime.dart';

class FakeAccountIdentityRuntime implements AccountIdentityRuntime {
  FakeAccountIdentityRuntime(this._snapshot);

  AccountIdentitySnapshot _snapshot;

  set snapshot(AccountIdentitySnapshot value) {
    _snapshot = value;
  }

  @override
  Future<AccountIdentitySnapshot> currentSnapshot() async => _snapshot;
}
