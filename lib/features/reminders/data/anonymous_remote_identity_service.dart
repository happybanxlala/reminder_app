import '../domain/shared_pack.dart';
import 'auth_repository.dart';
import 'identity_repository.dart';

enum AnonymousRemoteIdentityStatus {
  success,
  alreadyLinked,
  configMissing,
  remoteAuthFailed,
}

class AnonymousRemoteIdentityResult {
  const AnonymousRemoteIdentityResult({
    required this.status,
    this.user,
    this.error,
  });

  final AnonymousRemoteIdentityStatus status;
  final LocalUser? user;
  final Object? error;
}

class AnonymousRemoteIdentityService {
  const AnonymousRemoteIdentityService({
    required IdentityRepository identityRepository,
    required AuthRepository authRepository,
  }) : _identityRepository = identityRepository,
       _authRepository = authRepository;

  final IdentityRepository _identityRepository;
  final AuthRepository _authRepository;

  Future<AnonymousRemoteIdentityResult> ensureAnonymousRemoteIdentity() async {
    final localUser = await _identityRepository.ensureLocalIdentity();
    if (_isAnonymousRemoteLinked(localUser)) {
      return AnonymousRemoteIdentityResult(
        status: AnonymousRemoteIdentityStatus.alreadyLinked,
        user: localUser,
      );
    }

    try {
      final remoteIdentity = await _authRepository.signInAnonymously();
      if (remoteIdentity.provider != AuthProviderType.supabaseAnonymous) {
        return const AnonymousRemoteIdentityResult(
          status: AnonymousRemoteIdentityStatus.remoteAuthFailed,
        );
      }
      final linkedUser = await _identityRepository.linkRemoteIdentity(
        remoteUserId: remoteIdentity.remoteUserId,
        provider: AuthProviderType.supabaseAnonymous,
      );
      return AnonymousRemoteIdentityResult(
        status: AnonymousRemoteIdentityStatus.success,
        user: linkedUser,
      );
    } on RemoteAuthException catch (error) {
      return AnonymousRemoteIdentityResult(
        status: error.reason == RemoteAuthFailureReason.configMissing
            ? AnonymousRemoteIdentityStatus.configMissing
            : AnonymousRemoteIdentityStatus.remoteAuthFailed,
        user: localUser,
        error: error,
      );
    } catch (error) {
      return AnonymousRemoteIdentityResult(
        status: AnonymousRemoteIdentityStatus.remoteAuthFailed,
        user: localUser,
        error: error,
      );
    }
  }

  bool _isAnonymousRemoteLinked(LocalUser user) {
    return user.remoteUserId != null &&
        user.remoteProvider == AuthProviderType.supabaseAnonymous &&
        user.identityKind == LocalUserIdentityKind.anonymousRemote;
  }
}
