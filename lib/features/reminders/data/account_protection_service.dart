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

  Future<EmailBindingStartOutcome> startEmailBinding(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    final localUser = await _identityRepository.ensureLocalIdentity();
    final currentRemote = await _safeCurrentRemoteIdentity();
    final currentSnapshot = _snapshotFor(localUser, currentRemote);
    if (!_isValidEmail(normalizedEmail)) {
      return EmailBindingStartOutcome(
        status: EmailBindingStartStatus.emailInvalid,
        snapshot: currentSnapshot,
      );
    }
    if (currentSnapshot.status == AccountProtectionStatus.linkedProtected &&
        localUser.remoteProvider == AuthProviderType.email) {
      return EmailBindingStartOutcome(
        status: EmailBindingStartStatus.alreadyBound,
        snapshot: currentSnapshot,
        normalizedEmail: normalizedEmail,
      );
    }
    if (currentRemote.failed) {
      return EmailBindingStartOutcome(
        status: EmailBindingStartStatus.providerUnavailable,
        snapshot: currentSnapshot,
      );
    }
    final remoteIdentity = currentRemote.identity;
    if (localUser.remoteUserId == null ||
        remoteIdentity == null ||
        remoteIdentity.remoteUserId != localUser.remoteUserId) {
      return EmailBindingStartOutcome(
        status: EmailBindingStartStatus.remoteAuthRequired,
        snapshot: currentSnapshot,
      );
    }
    if (!remoteIdentity.isAnonymous ||
        remoteIdentity.provider != AuthProviderType.supabaseAnonymous) {
      return EmailBindingStartOutcome(
        status: EmailBindingStartStatus.notAnonymous,
        snapshot: currentSnapshot,
      );
    }

    try {
      final started = await _authRepository.startEmailBinding(normalizedEmail);
      if (started.remoteUserId != localUser.remoteUserId) {
        return EmailBindingStartOutcome(
          status: EmailBindingStartStatus.unknownFailure,
          snapshot: currentSnapshot,
        );
      }
      return EmailBindingStartOutcome(
        status: EmailBindingStartStatus.codeSent,
        snapshot: currentSnapshot,
        normalizedEmail: started.email,
      );
    } on RemoteAuthException catch (error) {
      return EmailBindingStartOutcome(
        status: _emailStartStatusForFailure(error.reason),
        snapshot: currentSnapshot,
      );
    } catch (_) {
      return EmailBindingStartOutcome(
        status: EmailBindingStartStatus.unknownFailure,
        snapshot: currentSnapshot,
      );
    }
  }

  Future<EmailBindingVerifyOutcome> verifyEmailBinding({
    required String email,
    required String code,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final trimmedCode = code.trim();
    final localUser = await _identityRepository.ensureLocalIdentity();
    final currentRemote = await _safeCurrentRemoteIdentity();
    final currentSnapshot = _snapshotFor(localUser, currentRemote);
    if (currentSnapshot.status == AccountProtectionStatus.linkedProtected &&
        localUser.remoteProvider == AuthProviderType.email) {
      return EmailBindingVerifyOutcome(
        status: EmailBindingVerifyStatus.alreadyBound,
        snapshot: currentSnapshot,
      );
    }
    if (!_isValidEmail(normalizedEmail)) {
      return EmailBindingVerifyOutcome(
        status: EmailBindingVerifyStatus.emailMismatch,
        snapshot: currentSnapshot,
      );
    }
    if (trimmedCode.isEmpty) {
      return EmailBindingVerifyOutcome(
        status: EmailBindingVerifyStatus.invalidCode,
        snapshot: currentSnapshot,
      );
    }
    if (currentRemote.failed) {
      return EmailBindingVerifyOutcome(
        status: EmailBindingVerifyStatus.providerUnavailable,
        snapshot: currentSnapshot,
      );
    }
    final remoteIdentity = currentRemote.identity;
    if (localUser.remoteUserId == null ||
        remoteIdentity == null ||
        remoteIdentity.remoteUserId != localUser.remoteUserId) {
      return EmailBindingVerifyOutcome(
        status: EmailBindingVerifyStatus.remoteAuthRequired,
        snapshot: currentSnapshot,
      );
    }

    try {
      final verified = await _authRepository.verifyEmailBinding(
        email: normalizedEmail,
        code: trimmedCode,
      );
      if (verified.remoteUserId != localUser.remoteUserId) {
        return EmailBindingVerifyOutcome(
          status: EmailBindingVerifyStatus.uidChangedUnsafe,
          snapshot: currentSnapshot,
        );
      }
      if (verified.isAnonymous || verified.provider != AuthProviderType.email) {
        return EmailBindingVerifyOutcome(
          status: EmailBindingVerifyStatus.unknownFailure,
          snapshot: currentSnapshot,
        );
      }
      final linkedUser = await _identityRepository.linkRemoteIdentity(
        remoteUserId: verified.remoteUserId,
        provider: AuthProviderType.email,
      );
      return EmailBindingVerifyOutcome(
        status: EmailBindingVerifyStatus.bound,
        snapshot: _snapshotFor(
          linkedUser,
          _CurrentRemoteIdentityResult(identity: verified),
        ),
      );
    } on RemoteAuthException catch (error) {
      return EmailBindingVerifyOutcome(
        status: _emailVerifyStatusForFailure(error.reason),
        snapshot: currentSnapshot,
      );
    } catch (_) {
      return EmailBindingVerifyOutcome(
        status: EmailBindingVerifyStatus.unknownFailure,
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
      RemoteAuthFailureReason.remoteAuthFailed ||
      RemoteAuthFailureReason.notAnonymous ||
      RemoteAuthFailureReason.emailInvalid ||
      RemoteAuthFailureReason.providerUnavailable ||
      RemoteAuthFailureReason.invalidCode ||
      RemoteAuthFailureReason.expiredCode ||
      RemoteAuthFailureReason.emailMismatch ||
      RemoteAuthFailureReason.uidChangedUnsafe ||
      RemoteAuthFailureReason.networkFailed =>
        AccountBindingResult.remoteAuthFailed,
    };
  }

  EmailBindingStartStatus _emailStartStatusForFailure(
    RemoteAuthFailureReason reason,
  ) {
    return switch (reason) {
      RemoteAuthFailureReason.configMissing =>
        EmailBindingStartStatus.configMissing,
      RemoteAuthFailureReason.emailInvalid =>
        EmailBindingStartStatus.emailInvalid,
      RemoteAuthFailureReason.notAnonymous =>
        EmailBindingStartStatus.notAnonymous,
      RemoteAuthFailureReason.unsupported ||
      RemoteAuthFailureReason.providerUnavailable =>
        EmailBindingStartStatus.providerUnavailable,
      RemoteAuthFailureReason.unavailable ||
      RemoteAuthFailureReason.networkFailed =>
        EmailBindingStartStatus.providerUnavailable,
      RemoteAuthFailureReason.remoteAuthFailed =>
        EmailBindingStartStatus.remoteAuthRequired,
      RemoteAuthFailureReason.invalidCode ||
      RemoteAuthFailureReason.expiredCode ||
      RemoteAuthFailureReason.emailMismatch ||
      RemoteAuthFailureReason.uidChangedUnsafe =>
        EmailBindingStartStatus.unknownFailure,
    };
  }

  EmailBindingVerifyStatus _emailVerifyStatusForFailure(
    RemoteAuthFailureReason reason,
  ) {
    return switch (reason) {
      RemoteAuthFailureReason.configMissing =>
        EmailBindingVerifyStatus.configMissing,
      RemoteAuthFailureReason.invalidCode =>
        EmailBindingVerifyStatus.invalidCode,
      RemoteAuthFailureReason.expiredCode =>
        EmailBindingVerifyStatus.expiredCode,
      RemoteAuthFailureReason.emailMismatch =>
        EmailBindingVerifyStatus.emailMismatch,
      RemoteAuthFailureReason.uidChangedUnsafe =>
        EmailBindingVerifyStatus.uidChangedUnsafe,
      RemoteAuthFailureReason.unsupported ||
      RemoteAuthFailureReason.providerUnavailable ||
      RemoteAuthFailureReason.notAnonymous =>
        EmailBindingVerifyStatus.providerUnavailable,
      RemoteAuthFailureReason.networkFailed ||
      RemoteAuthFailureReason.unavailable =>
        EmailBindingVerifyStatus.networkFailed,
      RemoteAuthFailureReason.remoteAuthFailed =>
        EmailBindingVerifyStatus.remoteAuthRequired,
      RemoteAuthFailureReason.emailInvalid =>
        EmailBindingVerifyStatus.emailMismatch,
    };
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
}

class _CurrentRemoteIdentityResult {
  const _CurrentRemoteIdentityResult({this.identity, this.failed = false});

  final RemoteIdentity? identity;
  final bool failed;
}
