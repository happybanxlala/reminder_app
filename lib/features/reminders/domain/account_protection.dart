import 'shared_pack.dart';

enum AccountProtectionStatus {
  localOnly,
  anonymousUnprotected,
  linkedProtected,
  remoteSessionMissing,
  unsupported,
  unavailable,
}

enum AccountBindingProvider { apple, google, email }

enum AccountBindingResult {
  linked,
  alreadyLinked,
  unsupported,
  configMissing,
  remoteAuthFailed,
  remoteSessionMissing,
}

enum EmailBindingStartStatus {
  codeSent,
  alreadyBound,
  notAnonymous,
  configMissing,
  remoteAuthRequired,
  emailInvalid,
  providerUnavailable,
  unknownFailure,
}

enum EmailBindingVerifyStatus {
  bound,
  alreadyBound,
  invalidCode,
  expiredCode,
  emailMismatch,
  uidChangedUnsafe,
  configMissing,
  remoteAuthRequired,
  providerUnavailable,
  networkFailed,
  unknownFailure,
}

class AccountProtectionSnapshot {
  const AccountProtectionSnapshot({
    required this.status,
    required this.localUser,
    this.currentRemoteUserId,
    this.currentRemoteProvider,
    this.currentRemoteIsAnonymous = false,
  });

  final AccountProtectionStatus status;
  final LocalUser localUser;
  final String? currentRemoteUserId;
  final AuthProviderType? currentRemoteProvider;
  final bool currentRemoteIsAnonymous;

  bool get isProtected => status == AccountProtectionStatus.linkedProtected;
}

class AccountBindingOutcome {
  const AccountBindingOutcome({required this.result, required this.snapshot});

  final AccountBindingResult result;
  final AccountProtectionSnapshot snapshot;

  bool get succeeded =>
      result == AccountBindingResult.linked ||
      result == AccountBindingResult.alreadyLinked;
}

class EmailBindingStartOutcome {
  const EmailBindingStartOutcome({
    required this.status,
    required this.snapshot,
    this.normalizedEmail,
  });

  final EmailBindingStartStatus status;
  final AccountProtectionSnapshot snapshot;
  final String? normalizedEmail;

  bool get codeSent => status == EmailBindingStartStatus.codeSent;
}

class EmailBindingVerifyOutcome {
  const EmailBindingVerifyOutcome({
    required this.status,
    required this.snapshot,
  });

  final EmailBindingVerifyStatus status;
  final AccountProtectionSnapshot snapshot;

  bool get succeeded =>
      status == EmailBindingVerifyStatus.bound ||
      status == EmailBindingVerifyStatus.alreadyBound;
}

extension AccountBindingProviderAuthProvider on AccountBindingProvider {
  AuthProviderType get authProvider {
    return switch (this) {
      AccountBindingProvider.apple => AuthProviderType.apple,
      AccountBindingProvider.google => AuthProviderType.google,
      AccountBindingProvider.email => AuthProviderType.email,
    };
  }
}
