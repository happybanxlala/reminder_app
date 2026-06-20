import 'dart:math';

import '../domain/shared_pack.dart';

class RemoteIdentity {
  const RemoteIdentity({required this.remoteUserId, required this.provider});

  final String remoteUserId;
  final AuthProviderType provider;
}

abstract class AuthRepository {
  Future<RemoteIdentity?> getCurrentRemoteIdentity();
  Future<RemoteIdentity> signInAnonymously();
  Future<RemoteIdentity> linkWithApple();
  Future<RemoteIdentity> linkWithGoogle();
  Future<RemoteIdentity> linkWithEmail();
  Future<void> signOut();
}

class FakeAuthRepository implements AuthRepository {
  RemoteIdentity? _current;

  @override
  Future<RemoteIdentity?> getCurrentRemoteIdentity() async => _current;

  @override
  Future<RemoteIdentity> signInAnonymously() {
    return _setIdentity(AuthProviderType.supabaseAnonymous);
  }

  @override
  Future<RemoteIdentity> linkWithApple() {
    return _setIdentity(AuthProviderType.apple);
  }

  @override
  Future<RemoteIdentity> linkWithGoogle() {
    return _setIdentity(AuthProviderType.google);
  }

  @override
  Future<RemoteIdentity> linkWithEmail() {
    return _setIdentity(AuthProviderType.email);
  }

  @override
  Future<void> signOut() async {
    _current = null;
  }

  Future<RemoteIdentity> _setIdentity(AuthProviderType provider) async {
    final prefix = provider == AuthProviderType.supabaseAnonymous
        ? 'fake_supabase_user'
        : 'fake_${provider.storageValue}_user';
    final identity = RemoteIdentity(
      remoteUserId: '${prefix}_${_generateGuid()}',
      provider: provider,
    );
    _current = identity;
    return identity;
  }

  static String _generateGuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final buffer = StringBuffer();
    for (var i = 0; i < bytes.length; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(hex(bytes[i]));
    }
    return buffer.toString();
  }
}
