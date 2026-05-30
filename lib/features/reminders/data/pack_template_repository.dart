import 'package:drift/drift.dart';

import '../domain/attention_policy.dart';
import '../domain/item.dart';
import '../domain/item_pack.dart';
import '../domain/pack_template.dart';
import '../domain/repeat_rule_v2.dart';
import 'default_pack_templates.dart';
import 'local/app_database.dart';
import 'local/reminder_dao.dart';

class PackTemplateRepository {
  PackTemplateRepository(this._dao, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ReminderDao _dao;
  final DateTime Function() _clock;

  Stream<List<PackTemplate>> watchCustomTemplates() {
    return _dao.watchCustomPackTemplateRows().map(
      (rows) => rows.map(_mapCustomTemplate).toList(growable: false),
    );
  }

  Stream<List<PackTemplate>> watchPackTemplates() {
    return watchCustomTemplates().map(
      (customTemplates) => [...defaultPackTemplates, ...customTemplates],
    );
  }

  Future<int> savePackAsTemplate({
    required int packId,
    required String templateName,
  }) async {
    final trimmedName = templateName.trim();
    if (trimmedName.isEmpty) {
      throw StateError('Template name is required.');
    }
    final pack = await _dao.getItemPackById(packId);
    if (pack == null || pack.status != ItemPackStatus.active) {
      throw StateError('Pack not found.');
    }
    final activeItems =
        (await _dao.listItemBundles(
              statuses: const {ItemLifecycleStatus.active},
            ))
            .where((bundle) => bundle.item.packId == packId)
            .map((bundle) => bundle.item)
            .toList(growable: false);
    if (activeItems.isEmpty) {
      throw StateError('Pack has no active items.');
    }

    final now = _clock();
    return _dao.attachedDatabase.transaction(() async {
      final templateId = await _dao.insertPackTemplate(
        PackTemplatesCompanion.insert(
          templateName: trimmedName,
          iconEmoji: Value(pack.iconEmoji),
          description: Value(pack.description),
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      );
      for (var index = 0; index < activeItems.length; index++) {
        await _dao.insertPackTemplateItem(
          _templateItemCompanion(
            activeItems[index],
            templateId: templateId,
            orderIndex: index,
            now: now,
          ),
        );
      }
      return templateId;
    });
  }

  PackTemplate _mapCustomTemplate(CustomPackTemplateRows rows) {
    return PackTemplate(
      id: 'custom-${rows.template.id}',
      source: PackTemplateSource.custom,
      templateName: rows.template.templateName,
      iconEmoji: rows.template.iconEmoji,
      description: rows.template.description,
      items: rows.items.map(_mapCustomTemplateItem).toList(growable: false),
    );
  }

  PackTemplateItem _mapCustomTemplateItem(PackTemplateItemRow row) {
    final type = ItemType.values.byName(row.type);
    return PackTemplateItem(
      title: row.title,
      type: type,
      attentionPolicySource: _attentionPolicySource(row.attentionPolicySource),
      config: _templateItemConfig(row, type),
    );
  }

  ItemConfig _templateItemConfig(PackTemplateItemRow row, ItemType type) {
    return switch (type) {
      ItemType.fixed => FixedItemConfig(
        scheduleType: FixedScheduleType.values.byName(
          row.fixedScheduleType ?? FixedScheduleType.oneTime.name,
        ),
        scheduleInterval: row.fixedScheduleInterval ?? 1,
        monthlyDay: row.fixedMonthlyDay,
        repeatRuleV2: RepeatRuleV2.parse(row.fixedRepeatRuleV2),
        timeOfDay: row.fixedTimeOfDay,
        overduePolicy: ItemOverduePolicy.values.byName(
          row.fixedOverduePolicy ?? ItemOverduePolicy.autoAdvance.name,
        ),
        infoBefore: Duration(minutes: row.fixedExpectedBeforeMinutes ?? 0),
        warningBefore: Duration(minutes: row.fixedWarningBeforeMinutes ?? 0),
        dangerBefore: Duration(minutes: row.fixedDangerBeforeMinutes ?? 0),
      ),
      ItemType.stateBased => StateBasedItemConfig(
        infoAfter: Duration(minutes: row.stateExpectedAfterMinutes ?? 0),
        warningAfter: Duration(minutes: row.stateWarningAfterMinutes ?? 0),
        dangerAfter: Duration(minutes: row.stateDangerAfterMinutes ?? 0),
      ),
    };
  }

  PackTemplateItemsCompanion _templateItemCompanion(
    Item item, {
    required int templateId,
    required int orderIndex,
    required DateTime now,
  }) {
    final config = item.config;
    return PackTemplateItemsCompanion.insert(
      templateId: templateId,
      orderIndex: Value(orderIndex),
      title: item.title,
      type: item.type.name,
      attentionPolicySource: Value(item.attentionPolicySource.name),
      fixedScheduleType: Value(_fixedScheduleType(config)),
      fixedScheduleInterval: Value(_fixedScheduleInterval(config)),
      fixedMonthlyDay: Value(_fixedMonthlyDay(config)),
      fixedRepeatRuleV2: Value(_fixedRepeatRuleV2(config)),
      fixedTimeOfDay: Value(_fixedTimeOfDay(config)),
      fixedOverduePolicy: Value(_fixedOverduePolicy(config)),
      fixedExpectedBeforeMinutes: Value(
        _durationMinutes(_fixedInfoBefore(config)),
      ),
      fixedWarningBeforeMinutes: Value(
        _durationMinutes(_fixedWarningBefore(config)),
      ),
      fixedDangerBeforeMinutes: Value(
        _durationMinutes(_fixedDangerBefore(config)),
      ),
      stateExpectedAfterMinutes: Value(
        _durationMinutes(_stateInfoAfter(config)),
      ),
      stateWarningAfterMinutes: Value(
        _durationMinutes(_stateWarningAfter(config)),
      ),
      stateDangerAfterMinutes: Value(
        _durationMinutes(_stateDangerAfter(config)),
      ),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
  }

  AttentionPolicySource _attentionPolicySource(String value) {
    return AttentionPolicySource.values
            .cast<AttentionPolicySource?>()
            .firstWhere(
              (candidate) => candidate?.name == value,
              orElse: () => AttentionPolicySource.systemDefault,
            ) ??
        AttentionPolicySource.systemDefault;
  }

  String? _fixedScheduleType(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.scheduleType.name,
      _ => null,
    };
  }

  int? _fixedScheduleInterval(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.scheduleInterval,
      _ => null,
    };
  }

  int? _fixedMonthlyDay(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.monthlyDay,
      _ => null,
    };
  }

  String? _fixedRepeatRuleV2(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.repeatRuleV2?.encode(),
      _ => null,
    };
  }

  String? _fixedTimeOfDay(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.timeOfDay,
      _ => null,
    };
  }

  String? _fixedOverduePolicy(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.overduePolicy.name,
      _ => null,
    };
  }

  Duration? _fixedInfoBefore(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.infoBefore,
      _ => null,
    };
  }

  Duration? _fixedWarningBefore(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.warningBefore,
      _ => null,
    };
  }

  Duration? _fixedDangerBefore(ItemConfig config) {
    return switch (config) {
      FixedItemConfig fixed => fixed.dangerBefore,
      _ => null,
    };
  }

  Duration? _stateInfoAfter(ItemConfig config) {
    return switch (config) {
      StateBasedItemConfig state => state.infoAfter,
      _ => null,
    };
  }

  Duration? _stateWarningAfter(ItemConfig config) {
    return switch (config) {
      StateBasedItemConfig state => state.warningAfter,
      _ => null,
    };
  }

  Duration? _stateDangerAfter(ItemConfig config) {
    return switch (config) {
      StateBasedItemConfig state => state.dangerAfter,
      _ => null,
    };
  }

  int? _durationMinutes(Duration? value) => value?.inMinutes;
}
