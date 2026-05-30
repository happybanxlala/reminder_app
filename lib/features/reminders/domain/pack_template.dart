import 'attention_policy.dart';
import 'item.dart';
import 'item_pack.dart';

enum PackTemplateSource { defaultTemplate, custom }

class PackTemplate {
  const PackTemplate({
    required this.id,
    required this.source,
    required this.templateName,
    required this.iconEmoji,
    this.description,
    required this.items,
  });

  final String id;
  final PackTemplateSource source;
  final String templateName;
  final String iconEmoji;
  final String? description;
  final List<PackTemplateItem> items;

  String get packName => '$templateName(模版)';
}

class PackTemplateItem {
  const PackTemplateItem({
    required this.title,
    required this.type,
    required this.config,
    this.attentionPolicySource = AttentionPolicySource.systemDefault,
  });

  final String title;
  final ItemType type;
  final ItemConfig config;
  final AttentionPolicySource attentionPolicySource;
}

class TemplateCreationResult {
  const TemplateCreationResult({
    required this.packId,
    required this.packName,
    required this.itemIds,
  });

  final int packId;
  final String packName;
  final List<int> itemIds;
}

class SavePackTemplateInput {
  const SavePackTemplateInput({
    required this.pack,
    required this.templateName,
    required this.items,
  });

  final ItemPack pack;
  final String templateName;
  final List<Item> items;
}
