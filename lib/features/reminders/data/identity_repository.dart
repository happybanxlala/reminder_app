import 'dart:math';

import 'package:drift/drift.dart';

import '../domain/shared_pack.dart';
import 'local/app_database.dart';
import 'local/reminder_dao.dart';

class IdentityRepository {
  const IdentityRepository(this._dao, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ReminderDao _dao;
  final DateTime Function() _clock;

  Future<LocalUser> ensureLocalIdentity() async {
    await ensureAppInstallation();
    final existing = await _dao.getPrimaryLocalUser();
    if (existing != null) {
      await _touchLocalUser(existing.id);
      return (await _dao.getLocalUserById(existing.id)) ?? existing;
    }

    final now = _clock();
    final id = _generateGuid();
    await _dao.insertLocalUser(
      LocalUsersCompanion.insert(
        id: id,
        displayName: '此裝置資料',
        identityKind: Value(LocalUserIdentityKind.local.storageValue),
        isPrimary: const Value(true),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: Value(now.millisecondsSinceEpoch),
        lastSeenAt: Value(now.millisecondsSinceEpoch),
      ),
    );
    return (await _dao.getLocalUserById(id))!;
  }

  Future<AppInstallation> ensureAppInstallation() async {
    await _dao.attachedDatabase.ensureAppInstallation();
    final installation = await _dao.getAppInstallation();
    if (installation == null) {
      throw StateError('Missing app installation identity');
    }
    return installation;
  }

  Future<LocalUser> getCurrentAppUser() {
    return ensureLocalIdentity();
  }

  Stream<LocalUser> watchCurrentAppUser() {
    return Stream.fromFuture(ensureLocalIdentity()).asyncExpand((_) {
      return _dao
          .watchPrimaryLocalUser()
          .where((user) => user != null)
          .cast<LocalUser>();
    });
  }

  Future<LocalUser> linkRemoteIdentity({
    required String remoteUserId,
    required AuthProviderType provider,
  }) async {
    final user = await ensureLocalIdentity();
    final now = _clock();
    final identityKind = provider == AuthProviderType.supabaseAnonymous
        ? LocalUserIdentityKind.anonymousRemote
        : LocalUserIdentityKind.linked;
    final updated = await _dao.updateLocalUserFields(
      user.id,
      LocalUsersCompanion(
        identityKind: Value(identityKind.storageValue),
        remoteUserId: Value(remoteUserId),
        remoteProvider: Value(provider.storageValue),
        linkedAt: Value(now.millisecondsSinceEpoch),
        lastSeenAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
    if (!updated) {
      throw StateError('Missing local identity');
    }
    return (await _dao.getLocalUserById(user.id))!;
  }

  Future<void> _touchLocalUser(String id) {
    final now = _clock();
    return _dao.updateLocalUserFields(
      id,
      LocalUsersCompanion(
        lastSeenAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
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
