import 'package:drift/drift.dart';

import '../domain/item_pack.dart';
import '../domain/shared_pack.dart';
import 'local/app_database.dart';
import 'local/reminder_dao.dart';

class SharedPackRepository {
  const SharedPackRepository(this._dao, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ReminderDao _dao;
  final DateTime Function() _clock;

  Future<List<LocalUser>> listLocalUsers() {
    return _dao.listLocalUsers();
  }

  Future<List<PackMember>> listPackMembers(int packId) {
    return _dao.listPackMembers(packId);
  }

  Future<List<ActivityEvent>> listActivityEventsForPack(int packId) {
    return _dao.listActivityEventsForPack(packId);
  }

  Future<bool> convertPackToShared(int packId, {String? hostUserId}) async {
    final pack = await _dao.getItemPackById(packId);
    if (pack == null ||
        pack.status == ItemPackStatus.archived ||
        pack.isSystemDefault ||
        pack.packType == ItemPackType.shared) {
      return false;
    }
    final host = hostUserId ?? AppDatabase.defaultHostUserId;
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final updated = await _dao.updateItemPackFields(
        packId,
        ItemPacksCompanion(
          packType: Value(ItemPackType.shared.name),
          hostUserId: Value(host),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      if (!updated) {
        return false;
      }
      await _dao.upsertPackMember(
        PackMembersCompanion.insert(
          packId: packId,
          userId: host,
          role: PackMemberRole.host.name,
          status: Value(PackMemberStatus.active.name),
          joinedAt: now.millisecondsSinceEpoch,
        ),
      );
      await _dao.insertActivityEvent(
        ActivityEventsCompanion.insert(
          packId: packId,
          actorUserId: host,
          entityType: 'pack',
          entityId: packId,
          action: 'pack_converted_to_shared',
          beforeJson: Value('{"pack_type":"${pack.packType.name}"}'),
          afterJson: Value('{"pack_type":"${ItemPackType.shared.name}"}'),
          createdAt: now.millisecondsSinceEpoch,
        ),
      );
      return true;
    });
  }

  Future<bool> addLocalMember(
    int packId, {
    String userId = AppDatabase.defaultMemberUserId,
    String? actorUserId,
  }) async {
    final pack = await _dao.getItemPackById(packId);
    if (pack == null ||
        pack.status == ItemPackStatus.archived ||
        pack.packType != ItemPackType.shared) {
      return false;
    }
    final actor =
        actorUserId ?? pack.hostUserId ?? AppDatabase.defaultHostUserId;
    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      await _dao.upsertPackMember(
        PackMembersCompanion.insert(
          packId: packId,
          userId: userId,
          role: PackMemberRole.member.name,
          status: Value(PackMemberStatus.active.name),
          joinedAt: now.millisecondsSinceEpoch,
        ),
      );
      await _dao.insertActivityEvent(
        ActivityEventsCompanion.insert(
          packId: packId,
          actorUserId: actor,
          entityType: 'pack_member',
          entityId: packId,
          action: 'member_added',
          metadataJson: Value('{"user_id":"$userId"}'),
          createdAt: now.millisecondsSinceEpoch,
        ),
      );
      return true;
    });
  }
}
