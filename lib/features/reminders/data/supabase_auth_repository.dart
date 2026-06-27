import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/shared_pack.dart';
import 'auth_repository.dart';
import 'supabase_config.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._runtime);

  final SupabaseRuntime _runtime;

  SupabaseClient get _client {
    final client = _runtime.client;
    if (client == null) {
      final reason = _runtime.status == SupabaseRuntimeStatus.missingConfig
          ? RemoteAuthFailureReason.configMissing
          : RemoteAuthFailureReason.unavailable;
      throw RemoteAuthException(reason, _runtime.error);
    }
    return client;
  }

  @override
  Future<RemoteIdentity?> getCurrentRemoteIdentity() async {
    final client = _runtime.client;
    if (client == null) {
      return null;
    }
    final user = client.auth.currentUser;
    if (user == null) {
      return null;
    }
    return _toRemoteIdentity(user);
  }

  @override
  Future<RemoteIdentity> signInAnonymously() async {
    final current = await getCurrentRemoteIdentity();
    if (current != null) {
      return current;
    }

    try {
      final response = await _client.auth.signInAnonymously();
      final user = response.user ?? response.session?.user;
      if (user == null) {
        throw const RemoteAuthException(
          RemoteAuthFailureReason.remoteAuthFailed,
        );
      }
      return _toRemoteIdentity(user);
    } on RemoteAuthException {
      rethrow;
    } catch (error) {
      throw RemoteAuthException(
        RemoteAuthFailureReason.remoteAuthFailed,
        error,
      );
    }
  }

  @override
  Future<RemoteIdentity> linkWithApple() {
    throw const RemoteAuthException(RemoteAuthFailureReason.unsupported);
  }

  @override
  Future<RemoteIdentity> linkWithGoogle() {
    throw const RemoteAuthException(RemoteAuthFailureReason.unsupported);
  }

  @override
  Future<RemoteIdentity> linkWithEmail() {
    throw const RemoteAuthException(RemoteAuthFailureReason.unsupported);
  }

  @override
  Future<EmailBindingStartRemoteResult> startEmailBinding(String email) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const RemoteAuthException(RemoteAuthFailureReason.remoteAuthFailed);
    }
    if (!user.isAnonymous ||
        _providerFor(user) != AuthProviderType.supabaseAnonymous) {
      throw const RemoteAuthException(RemoteAuthFailureReason.notAnonymous);
    }
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(email: normalizedEmail),
      );
      final updatedUser = response.user ?? _client.auth.currentUser;
      if (updatedUser == null) {
        throw const RemoteAuthException(
          RemoteAuthFailureReason.remoteAuthFailed,
        );
      }
      if (updatedUser.id != user.id) {
        throw const RemoteAuthException(
          RemoteAuthFailureReason.uidChangedUnsafe,
        );
      }
      return EmailBindingStartRemoteResult(
        remoteUserId: user.id,
        email: normalizedEmail,
      );
    } on RemoteAuthException {
      rethrow;
    } on AuthException catch (error) {
      throw RemoteAuthException(_emailStartFailureReason(error), error);
    } catch (error) {
      throw RemoteAuthException(
        RemoteAuthFailureReason.remoteAuthFailed,
        error,
      );
    }
  }

  @override
  Future<RemoteIdentity> verifyEmailBinding({
    required String email,
    required String code,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw const RemoteAuthException(RemoteAuthFailureReason.remoteAuthFailed);
    }
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final response = await _client.auth.verifyOTP(
        email: normalizedEmail,
        token: code.trim(),
        type: OtpType.emailChange,
      );
      final verifiedUser =
          response.user ?? response.session?.user ?? _client.auth.currentUser;
      if (verifiedUser == null) {
        throw const RemoteAuthException(
          RemoteAuthFailureReason.remoteAuthFailed,
        );
      }
      if (verifiedUser.id != currentUser.id) {
        throw const RemoteAuthException(
          RemoteAuthFailureReason.uidChangedUnsafe,
        );
      }
      final identity = _emailLinkedIdentityFor(verifiedUser, normalizedEmail);
      if (identity == null) {
        throw const RemoteAuthException(
          RemoteAuthFailureReason.remoteAuthFailed,
        );
      }
      return identity;
    } on RemoteAuthException {
      rethrow;
    } on AuthException catch (error) {
      throw RemoteAuthException(_emailVerifyFailureReason(error), error);
    } catch (error) {
      throw RemoteAuthException(
        RemoteAuthFailureReason.remoteAuthFailed,
        error,
      );
    }
  }

  @override
  Future<void> signOut() async {
    final client = _runtime.client;
    if (client == null) {
      return;
    }
    // Anonymous remote users may not be recoverable after sign-out unless the
    // current session is protected first, such as with Email OTP binding.
    await client.auth.signOut();
  }

  RemoteIdentity _toRemoteIdentity(User user) {
    return RemoteIdentity(
      remoteUserId: user.id,
      provider: _providerFor(user),
      isAnonymous: user.isAnonymous,
    );
  }

  RemoteIdentity? _emailLinkedIdentityFor(User user, String email) {
    if (user.isAnonymous) {
      return null;
    }
    final providers =
        user.identities?.map((identity) => identity.provider).toSet() ??
        const <String>{};
    final hasEmailIdentity = providers.contains('email');
    final hasConfirmedEmail =
        user.email?.toLowerCase() == email && user.emailConfirmedAt != null;
    if (!hasEmailIdentity && !hasConfirmedEmail) {
      return null;
    }
    return RemoteIdentity(
      remoteUserId: user.id,
      provider: AuthProviderType.email,
      isAnonymous: false,
    );
  }

  AuthProviderType _providerFor(User user) {
    if (user.isAnonymous) {
      return AuthProviderType.supabaseAnonymous;
    }
    final providers =
        user.identities?.map((identity) => identity.provider).toSet() ??
        const <String>{};
    if (providers.contains('apple')) {
      return AuthProviderType.apple;
    }
    if (providers.contains('google')) {
      return AuthProviderType.google;
    }
    if (providers.contains('email')) {
      return AuthProviderType.email;
    }
    return AuthProviderType.supabaseAnonymous;
  }

  RemoteAuthFailureReason _emailStartFailureReason(AuthException error) {
    if (error is AuthSessionMissingException) {
      return RemoteAuthFailureReason.remoteAuthFailed;
    }
    final text = '${error.code ?? ''} ${error.message}'.toLowerCase();
    if (text.contains('invalid') && text.contains('email')) {
      return RemoteAuthFailureReason.emailInvalid;
    }
    if (text.contains('disabled') || text.contains('provider')) {
      return RemoteAuthFailureReason.providerUnavailable;
    }
    if (_isNetworkLike(error)) {
      return RemoteAuthFailureReason.networkFailed;
    }
    return RemoteAuthFailureReason.remoteAuthFailed;
  }

  RemoteAuthFailureReason _emailVerifyFailureReason(AuthException error) {
    if (error is AuthSessionMissingException) {
      return RemoteAuthFailureReason.remoteAuthFailed;
    }
    final text = '${error.code ?? ''} ${error.message}'.toLowerCase();
    if (text.contains('expired')) {
      return RemoteAuthFailureReason.expiredCode;
    }
    if (text.contains('invalid') ||
        text.contains('token') ||
        text.contains('otp')) {
      return RemoteAuthFailureReason.invalidCode;
    }
    if (text.contains('email')) {
      return RemoteAuthFailureReason.emailMismatch;
    }
    if (text.contains('disabled') || text.contains('provider')) {
      return RemoteAuthFailureReason.providerUnavailable;
    }
    if (_isNetworkLike(error)) {
      return RemoteAuthFailureReason.networkFailed;
    }
    return RemoteAuthFailureReason.remoteAuthFailed;
  }

  bool _isNetworkLike(AuthException error) {
    if (error is AuthRetryableFetchException) {
      return true;
    }
    final statusCode = int.tryParse(error.statusCode ?? '');
    return statusCode != null && statusCode >= 500;
  }
}
