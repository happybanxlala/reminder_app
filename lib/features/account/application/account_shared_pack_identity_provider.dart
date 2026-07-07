import '../../shared_pack/application/shared_pack_identity_provider.dart';
import 'account_identity.dart';
import 'account_identity_result.dart';
import 'account_identity_runtime.dart';

class AccountBackedSharedPackIdentityProvider
    implements SharedPackIdentityProvider {
  const AccountBackedSharedPackIdentityProvider(this._runtime);

  final AccountIdentityRuntime _runtime;

  @override
  Future<String> currentIdentityId() async {
    final snapshot = await _runtime.currentSnapshot();
    final identity = snapshot.identity;

    if (snapshot.status == AccountBindingStatus.bound && identity != null) {
      final accountId = identity.accountId.trim();
      if (accountId.isNotEmpty) {
        return accountId;
      }
    }

    throw AccountIdentityUnavailableException(
      status: snapshot.status,
      message: _messageFor(snapshot.status),
    );
  }

  String _messageFor(AccountBindingStatus status) {
    switch (status) {
      case AccountBindingStatus.unbound:
        return 'Account is not bound.';
      case AccountBindingStatus.binding:
        return 'Account binding is not complete.';
      case AccountBindingStatus.bound:
        return 'Account identity is unavailable.';
      case AccountBindingStatus.bindingFailed:
        return 'Account binding failed.';
      case AccountBindingStatus.needsReauth:
        return 'Account verification is required.';
    }
  }
}
