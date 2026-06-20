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
  Future<void> signOut() async {
    final client = _runtime.client;
    if (client == null) {
      return;
    }
    // Anonymous remote users may not be recoverable after sign-out unless they
    // are later protected with Apple / Google / Email binding.
    await client.auth.signOut();
  }

  RemoteIdentity _toRemoteIdentity(User user) {
    return RemoteIdentity(
      remoteUserId: user.id,
      provider: AuthProviderType.supabaseAnonymous,
      isAnonymous: user.isAnonymous,
    );
  }
}
