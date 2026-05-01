import 'item.dart';

enum ItemPackTemplateSource { builtin, custom }

class ItemPackTemplate {
  const ItemPackTemplate({
    required this.id,
    required this.source,
    required this.name,
    required this.category,
    required this.description,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final ItemPackTemplateSource source;
  final String name;
  final String category;
  final String description;
  final List<ItemPackTemplateItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int? get customId {
    if (source != ItemPackTemplateSource.custom) {
      return null;
    }
    return int.tryParse(id.replaceFirst('custom-', ''));
  }
}

class ItemPackTemplateInput {
  const ItemPackTemplateInput({
    required this.name,
    required this.category,
    required this.description,
  });

  final String name;
  final String category;
  final String description;
}

class ItemPackTemplateItem {
  const ItemPackTemplateItem({
    required this.title,
    this.description,
    required this.type,
    required this.config,
  });

  final String title;
  final String? description;
  final ItemType type;
  final ItemConfig config;
}
