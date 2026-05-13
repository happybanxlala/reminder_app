import 'attention_policy.dart';
import 'item.dart';
import 'item_action_record.dart';
import 'resource.dart';

enum ItemPackTemplateSource { builtin, custom }

class ItemPackTemplate {
  const ItemPackTemplate({
    required this.id,
    required this.source,
    required this.name,
    required this.category,
    required this.description,
    required this.items,
    this.resources = const <ResourceTemplateItem>[],
    this.consumptionRules = const <ResourceConsumptionRuleTemplate>[],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final ItemPackTemplateSource source;
  final String name;
  final String category;
  final String description;
  final List<ItemPackTemplateItem> items;
  final List<ResourceTemplateItem> resources;
  final List<ResourceConsumptionRuleTemplate> consumptionRules;
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
    this.logicalId,
    required this.title,
    this.description,
    required this.type,
    required this.config,
    this.attentionPolicySource = AttentionPolicySource.systemDefault,
  });

  final String? logicalId;
  final String title;
  final String? description;
  final ItemType type;
  final ItemConfig config;
  final AttentionPolicySource attentionPolicySource;
}

class ResourceTemplateItem {
  const ResourceTemplateItem({
    required this.logicalId,
    required this.title,
    this.description,
    required this.type,
    required this.config,
  });

  final String logicalId;
  final String title;
  final String? description;
  final ResourceType type;
  final ResourceConfig config;
}

class ResourceConsumptionRuleTemplate {
  const ResourceConsumptionRuleTemplate({
    required this.itemLogicalId,
    required this.resourceLogicalId,
    this.triggerActionType = ItemActionType.done,
    this.consumeAmount = 1,
    this.isEnabled = true,
  });

  final String itemLogicalId;
  final String resourceLogicalId;
  final ItemActionType triggerActionType;
  final int consumeAmount;
  final bool isEnabled;
}
