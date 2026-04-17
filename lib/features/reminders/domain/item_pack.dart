enum ItemPackStatus { active, archived }

class ItemPackInput {
  const ItemPackInput({required this.title, this.description});

  final String title;
  final String? description;
}

class ItemPack {
  const ItemPack({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.isSystemDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String? description;
  final ItemPackStatus status;
  final bool isSystemDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
}
