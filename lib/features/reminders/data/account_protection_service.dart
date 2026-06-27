import '../domain/account_protection.dart';
import '../domain/shared_pack.dart';
import 'auth_repository.dart';
import 'identity_repository.dart';

class AccountProtectionService {
  const AccountProtectionService({
    required IdentityRepository identityRepository,
    required AuthRepository authRepository,
  }) : _identityRepository = identityRepository,
       _authRepository = authRepository;

  final IdentityRepository _identityRepository;
  final AuthRepository _authRepository;

  Future<AccountProtectionSnapshot> getStatus() async {
    final localUser = await _identityRepository.ensureLocalIdentity();
    final remoteIdentity = await _safeCurrentRemoteIdentity();
    if (remoteIdentity.failed) {
      return AccountProtectionSnapshot(
        status: AccountProtectionStatus.unavailable,
        localUser: localUser,
      );
    }
    return _snapshotFor(localUser, remoteIdentity);
  }

  Future<AccountBindingOutcome> bindWithProvider(
    AccountBindingProvider provider,
  ) async {
    final localUser = await _identityRepository.ensureLocalIdentity();
    final currentSnapshot = _snapshotFor(
      localUser,
      await _safeCurrentRemoteIdentity(),
    );
    if (_isLinkedProtectedLocalUser(localUser)) {
      return AccountBindingOutcome(
        result: AccountBindingResult.alreadyLinked,
        snapshot: currentSnapshot,
      );
    }
    if (localUser.remoteUserId != null &&
        currentSnapshot.status ==
            AccountProtectionStatus.remoteSessionMissing) {
      return AccountBindingOutcome(
        result: AccountBindingResult.remoteSessionMissing,
        snapshot: currentSnapshot,
      );
    }

    try {
      final remoteIdentity = await _linkRemoteIdentity(provider);
      if (remoteIdentity.isAnonymous ||
          remoteIdentity.provider == AuthProviderType.supabaseAnonymous) {
        return AccountBindingOutcome(
          result: AccountBindingResult.remoteAuthFailed,
          snapshot: currentSnapshot,
        );
      }
      final linkedUser = await _identityRepository.linkRemoteIdentity(
        remoteUserId: remoteIdentity.remoteUserId,
        provider: remoteIdentity.provider,
      );
      return AccountBindingOutcome(
        result: AccountBindingResult.linked,
        snapshot: _snapshotFor(
          linkedUser,
          _CurrentRemoteIdentityResult(identity: remoteIdentity),
        ),
      );
    } on RemoteAuthException catch (error) {
      return AccountBindingOutcome(
        result: _bindingResultForFailure(error.reason),
        snapshot: currentSnapshot,
      );
    } catch (_) {
      return AccountBindingOutcome(
        result: AccountBindingResult.remoteAuthFailed,
        snapshot: currentSnapshot,
      );
    }
  }

  Future<_CurrentRemoteIdentityResult> _safeCurrentRemoteIdentity() async {
    try {
      return _CurrentRemoteIdentityResult(
        identity: await _authRepository.getCurrentRemoteIdentity(),
      );
    } catch (_) {
      return const _CurrentRemoteIdentityResult(failed: true);
    }
  }

  Future<RemoteIdentity> _linkRemoteIdentity(AccountBindingProvider provider) {
    return switch (provider) {
      AccountBindingProvider.apple => _authRepository.linkWithApple(),
      AccountBindingProvider.google => _authRepository.linkWithGoogle(),
      AccountBindingProvider.email => _authRepository.linkWithEmail(),
    };
  }

  AccountProtectionSnapshot _snapshotFor(
    LocalUser localUser,
    _CurrentRemoteIdentityResult remoteIdentity,
  ) {
    final status = remoteIdentity.failed
        ? AccountProtectionStatus.unavailable
        : _statusFor(localUser, remoteIdentity.identity);
    return AccountProtectionSnapshot(
      status: status,
      localUser: localUser,
      currentRemoteUserId: remoteIdentity.identity?.remoteUserId,
      currentRemoteProvider: remoteIdentity.identity?.provider,
      currentRemoteIsAnonymous: remoteIdentity.identity?.isAnonymous ?? false,
    );
  }

  AccountProtectionStatus _statusFor(
    LocalUser localUser,
    RemoteIdentity? remoteIdentity,
  ) {
    if (localUser.remoteUserId == null) {
      return AccountProtectionStatus.localOnly;
    }
    if (remoteIdentity == null ||
        remoteIdentity.remoteUserId != localUser.remoteUserId) {
      return AccountProtectionStatus.remoteSessionMissing;
    }
    if (_isLinkedProtectedLocalUser(localUser) &&
        !remoteIdentity.isAnonymous &&
        remoteIdentity.provider != AuthProviderType.supabaseAnonymous) {
      return AccountProtectionStatus.linkedProtected;
    }
    if (localUser.identityKind == LocalUserIdentityKind.anonymousRemote ||
        localUser.remoteProvider == AuthProviderType.supabaseAnonymous ||
        remoteIdentity.isAnonymous) {
      return AccountProtectionStatus.anonymousUnprotected;
    }
    return AccountProtectionStatus.unsupported;
  }

  bool _isLinkedProtectedLocalUser(LocalUser localUser) {
    return localUser.identityKind == LocalUserIdentityKind.linked &&
        localUser.remoteProvider != null &&
        localUser.remoteProvider != AuthProviderType.supabaseAnonymous;
  }

  AccountBindingResult _bindingResultForFailure(
    RemoteAuthFailureReason reason,
  ) {
    return switch (reason) {
      RemoteAuthFailureReason.configMissing =>
        AccountBindingResult.configMissing,
      RemoteAuthFailureReason.unsupported => AccountBindingResult.unsupported,
      RemoteAuthFailureReason.unavailable ||
      RemoteAuthFailureReason.remoteAuthFailed =>
        AccountBindingResult.remoteAuthFailed,
    };
  }
}

class _CurrentRemoteIdentityResult {
  const _CurrentRemoteIdentityResult({this.identity, this.failed = false});

  final RemoteIdentity? identity;
  final bool failed;
}
