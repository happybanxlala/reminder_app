import 'shared_pack.dart';

enum ItemPackStatus { active, archived }

class ItemPackInput {
  const ItemPackInput({
    required this.title,
    this.description,
    this.iconEmoji = '🏷️',
  });

  final String title;
  final String? description;
  final String iconEmoji;
}

class ItemPack {
  const ItemPack({
    required this.id,
    required this.title,
    this.description,
    this.iconEmoji = '🏷️',
    this.orderIndex = 0,
    required this.status,
    required this.isSystemDefault,
    this.packType = ItemPackType.personal,
    this.hostUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String? description;
  final String iconEmoji;
  final int orderIndex;
  final ItemPackStatus status;
  final bool isSystemDefault;
  final ItemPackType packType;
  final String? hostUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
}
