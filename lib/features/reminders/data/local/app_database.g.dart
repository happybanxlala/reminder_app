// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ItemPacksTable extends ItemPacks
    with TableInfo<$ItemPacksTable, ItemPackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemPacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconEmojiMeta = const VerificationMeta(
    'iconEmoji',
  );
  @override
  late final GeneratedColumn<String> iconEmoji = GeneratedColumn<String>(
    'icon_emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('📌'),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _isSystemDefaultMeta = const VerificationMeta(
    'isSystemDefault',
  );
  @override
  late final GeneratedColumn<bool> isSystemDefault = GeneratedColumn<bool>(
    'is_system_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    iconEmoji,
    orderIndex,
    status,
    isSystemDefault,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_packs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemPackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('icon_emoji')) {
      context.handle(
        _iconEmojiMeta,
        iconEmoji.isAcceptableOrUnknown(data['icon_emoji']!, _iconEmojiMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('is_system_default')) {
      context.handle(
        _isSystemDefaultMeta,
        isSystemDefault.isAcceptableOrUnknown(
          data['is_system_default']!,
          _isSystemDefaultMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemPackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemPackRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      iconEmoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_emoji'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      isSystemDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system_default'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ItemPacksTable createAlias(String alias) {
    return $ItemPacksTable(attachedDatabase, alias);
  }
}

class ItemPackRow extends DataClass implements Insertable<ItemPackRow> {
  final int id;
  final String title;
  final String? description;
  final String iconEmoji;
  final int orderIndex;
  final String status;
  final bool isSystemDefault;
  final int createdAt;
  final int updatedAt;
  const ItemPackRow({
    required this.id,
    required this.title,
    this.description,
    required this.iconEmoji,
    required this.orderIndex,
    required this.status,
    required this.isSystemDefault,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['icon_emoji'] = Variable<String>(iconEmoji);
    map['order_index'] = Variable<int>(orderIndex);
    map['status'] = Variable<String>(status);
    map['is_system_default'] = Variable<bool>(isSystemDefault);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ItemPacksCompanion toCompanion(bool nullToAbsent) {
    return ItemPacksCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      iconEmoji: Value(iconEmoji),
      orderIndex: Value(orderIndex),
      status: Value(status),
      isSystemDefault: Value(isSystemDefault),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ItemPackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemPackRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      iconEmoji: serializer.fromJson<String>(json['iconEmoji']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      status: serializer.fromJson<String>(json['status']),
      isSystemDefault: serializer.fromJson<bool>(json['isSystemDefault']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'iconEmoji': serializer.toJson<String>(iconEmoji),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'status': serializer.toJson<String>(status),
      'isSystemDefault': serializer.toJson<bool>(isSystemDefault),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ItemPackRow copyWith({
    int? id,
    String? title,
    Value<String?> description = const Value.absent(),
    String? iconEmoji,
    int? orderIndex,
    String? status,
    bool? isSystemDefault,
    int? createdAt,
    int? updatedAt,
  }) => ItemPackRow(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    iconEmoji: iconEmoji ?? this.iconEmoji,
    orderIndex: orderIndex ?? this.orderIndex,
    status: status ?? this.status,
    isSystemDefault: isSystemDefault ?? this.isSystemDefault,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ItemPackRow copyWithCompanion(ItemPacksCompanion data) {
    return ItemPackRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      iconEmoji: data.iconEmoji.present ? data.iconEmoji.value : this.iconEmoji,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      status: data.status.present ? data.status.value : this.status,
      isSystemDefault: data.isSystemDefault.present
          ? data.isSystemDefault.value
          : this.isSystemDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemPackRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('iconEmoji: $iconEmoji, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('status: $status, ')
          ..write('isSystemDefault: $isSystemDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    iconEmoji,
    orderIndex,
    status,
    isSystemDefault,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemPackRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.iconEmoji == this.iconEmoji &&
          other.orderIndex == this.orderIndex &&
          other.status == this.status &&
          other.isSystemDefault == this.isSystemDefault &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ItemPacksCompanion extends UpdateCompanion<ItemPackRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> iconEmoji;
  final Value<int> orderIndex;
  final Value<String> status;
  final Value<bool> isSystemDefault;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ItemPacksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.iconEmoji = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.status = const Value.absent(),
    this.isSystemDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ItemPacksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.iconEmoji = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.status = const Value.absent(),
    this.isSystemDefault = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ItemPackRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? iconEmoji,
    Expression<int>? orderIndex,
    Expression<String>? status,
    Expression<bool>? isSystemDefault,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (iconEmoji != null) 'icon_emoji': iconEmoji,
      if (orderIndex != null) 'order_index': orderIndex,
      if (status != null) 'status': status,
      if (isSystemDefault != null) 'is_system_default': isSystemDefault,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ItemPacksCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? iconEmoji,
    Value<int>? orderIndex,
    Value<String>? status,
    Value<bool>? isSystemDefault,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ItemPacksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      orderIndex: orderIndex ?? this.orderIndex,
      status: status ?? this.status,
      isSystemDefault: isSystemDefault ?? this.isSystemDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (iconEmoji.present) {
      map['icon_emoji'] = Variable<String>(iconEmoji.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isSystemDefault.present) {
      map['is_system_default'] = Variable<bool>(isSystemDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemPacksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('iconEmoji: $iconEmoji, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('status: $status, ')
          ..write('isSystemDefault: $isSystemDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, ItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _packIdMeta = const VerificationMeta('packId');
  @override
  late final GeneratedColumn<int> packId = GeneratedColumn<int>(
    'pack_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES item_packs (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attentionPolicySourceMeta =
      const VerificationMeta('attentionPolicySource');
  @override
  late final GeneratedColumn<String> attentionPolicySource =
      GeneratedColumn<String>(
        'attention_policy_source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('systemDefault'),
      );
  static const VerificationMeta _fixedScheduleTypeMeta = const VerificationMeta(
    'fixedScheduleType',
  );
  @override
  late final GeneratedColumn<String> fixedScheduleType =
      GeneratedColumn<String>(
        'fixed_schedule_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fixedScheduleIntervalMeta =
      const VerificationMeta('fixedScheduleInterval');
  @override
  late final GeneratedColumn<int> fixedScheduleInterval = GeneratedColumn<int>(
    'fixed_schedule_interval',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixedMonthlyDayMeta = const VerificationMeta(
    'fixedMonthlyDay',
  );
  @override
  late final GeneratedColumn<int> fixedMonthlyDay = GeneratedColumn<int>(
    'fixed_monthly_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixedRepeatRuleV2Meta = const VerificationMeta(
    'fixedRepeatRuleV2',
  );
  @override
  late final GeneratedColumn<String> fixedRepeatRuleV2 =
      GeneratedColumn<String>(
        'fixed_repeat_rule_v2',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fixedAnchorDateMeta = const VerificationMeta(
    'fixedAnchorDate',
  );
  @override
  late final GeneratedColumn<int> fixedAnchorDate = GeneratedColumn<int>(
    'fixed_anchor_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixedDueDateMeta = const VerificationMeta(
    'fixedDueDate',
  );
  @override
  late final GeneratedColumn<int> fixedDueDate = GeneratedColumn<int>(
    'fixed_due_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixedTimeOfDayMeta = const VerificationMeta(
    'fixedTimeOfDay',
  );
  @override
  late final GeneratedColumn<String> fixedTimeOfDay = GeneratedColumn<String>(
    'fixed_time_of_day',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixedOverduePolicyMeta =
      const VerificationMeta('fixedOverduePolicy');
  @override
  late final GeneratedColumn<String> fixedOverduePolicy =
      GeneratedColumn<String>(
        'fixed_overdue_policy',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fixedExpectedBeforeMinutesMeta =
      const VerificationMeta('fixedExpectedBeforeMinutes');
  @override
  late final GeneratedColumn<int> fixedExpectedBeforeMinutes =
      GeneratedColumn<int>(
        'fixed_expected_before_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fixedWarningBeforeMinutesMeta =
      const VerificationMeta('fixedWarningBeforeMinutes');
  @override
  late final GeneratedColumn<int> fixedWarningBeforeMinutes =
      GeneratedColumn<int>(
        'fixed_warning_before_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fixedDangerBeforeMinutesMeta =
      const VerificationMeta('fixedDangerBeforeMinutes');
  @override
  late final GeneratedColumn<int> fixedDangerBeforeMinutes =
      GeneratedColumn<int>(
        'fixed_danger_before_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _stateAnchorDateMeta = const VerificationMeta(
    'stateAnchorDate',
  );
  @override
  late final GeneratedColumn<int> stateAnchorDate = GeneratedColumn<int>(
    'state_anchor_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateExpectedAfterMinutesMeta =
      const VerificationMeta('stateExpectedAfterMinutes');
  @override
  late final GeneratedColumn<int> stateExpectedAfterMinutes =
      GeneratedColumn<int>(
        'state_expected_after_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _stateWarningAfterMinutesMeta =
      const VerificationMeta('stateWarningAfterMinutes');
  @override
  late final GeneratedColumn<int> stateWarningAfterMinutes =
      GeneratedColumn<int>(
        'state_warning_after_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _stateDangerAfterMinutesMeta =
      const VerificationMeta('stateDangerAfterMinutes');
  @override
  late final GeneratedColumn<int> stateDangerAfterMinutes =
      GeneratedColumn<int>(
        'state_danger_after_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastDoneAtMeta = const VerificationMeta(
    'lastDoneAt',
  );
  @override
  late final GeneratedColumn<int> lastDoneAt = GeneratedColumn<int>(
    'last_done_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    packId,
    title,
    description,
    status,
    type,
    attentionPolicySource,
    fixedScheduleType,
    fixedScheduleInterval,
    fixedMonthlyDay,
    fixedRepeatRuleV2,
    fixedAnchorDate,
    fixedDueDate,
    fixedTimeOfDay,
    fixedOverduePolicy,
    fixedExpectedBeforeMinutes,
    fixedWarningBeforeMinutes,
    fixedDangerBeforeMinutes,
    stateAnchorDate,
    stateExpectedAfterMinutes,
    stateWarningAfterMinutes,
    stateDangerAfterMinutes,
    lastDoneAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pack_id')) {
      context.handle(
        _packIdMeta,
        packId.isAcceptableOrUnknown(data['pack_id']!, _packIdMeta),
      );
    } else if (isInserting) {
      context.missing(_packIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('attention_policy_source')) {
      context.handle(
        _attentionPolicySourceMeta,
        attentionPolicySource.isAcceptableOrUnknown(
          data['attention_policy_source']!,
          _attentionPolicySourceMeta,
        ),
      );
    }
    if (data.containsKey('fixed_schedule_type')) {
      context.handle(
        _fixedScheduleTypeMeta,
        fixedScheduleType.isAcceptableOrUnknown(
          data['fixed_schedule_type']!,
          _fixedScheduleTypeMeta,
        ),
      );
    }
    if (data.containsKey('fixed_schedule_interval')) {
      context.handle(
        _fixedScheduleIntervalMeta,
        fixedScheduleInterval.isAcceptableOrUnknown(
          data['fixed_schedule_interval']!,
          _fixedScheduleIntervalMeta,
        ),
      );
    }
    if (data.containsKey('fixed_monthly_day')) {
      context.handle(
        _fixedMonthlyDayMeta,
        fixedMonthlyDay.isAcceptableOrUnknown(
          data['fixed_monthly_day']!,
          _fixedMonthlyDayMeta,
        ),
      );
    }
    if (data.containsKey('fixed_repeat_rule_v2')) {
      context.handle(
        _fixedRepeatRuleV2Meta,
        fixedRepeatRuleV2.isAcceptableOrUnknown(
          data['fixed_repeat_rule_v2']!,
          _fixedRepeatRuleV2Meta,
        ),
      );
    }
    if (data.containsKey('fixed_anchor_date')) {
      context.handle(
        _fixedAnchorDateMeta,
        fixedAnchorDate.isAcceptableOrUnknown(
          data['fixed_anchor_date']!,
          _fixedAnchorDateMeta,
        ),
      );
    }
    if (data.containsKey('fixed_due_date')) {
      context.handle(
        _fixedDueDateMeta,
        fixedDueDate.isAcceptableOrUnknown(
          data['fixed_due_date']!,
          _fixedDueDateMeta,
        ),
      );
    }
    if (data.containsKey('fixed_time_of_day')) {
      context.handle(
        _fixedTimeOfDayMeta,
        fixedTimeOfDay.isAcceptableOrUnknown(
          data['fixed_time_of_day']!,
          _fixedTimeOfDayMeta,
        ),
      );
    }
    if (data.containsKey('fixed_overdue_policy')) {
      context.handle(
        _fixedOverduePolicyMeta,
        fixedOverduePolicy.isAcceptableOrUnknown(
          data['fixed_overdue_policy']!,
          _fixedOverduePolicyMeta,
        ),
      );
    }
    if (data.containsKey('fixed_expected_before_minutes')) {
      context.handle(
        _fixedExpectedBeforeMinutesMeta,
        fixedExpectedBeforeMinutes.isAcceptableOrUnknown(
          data['fixed_expected_before_minutes']!,
          _fixedExpectedBeforeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('fixed_warning_before_minutes')) {
      context.handle(
        _fixedWarningBeforeMinutesMeta,
        fixedWarningBeforeMinutes.isAcceptableOrUnknown(
          data['fixed_warning_before_minutes']!,
          _fixedWarningBeforeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('fixed_danger_before_minutes')) {
      context.handle(
        _fixedDangerBeforeMinutesMeta,
        fixedDangerBeforeMinutes.isAcceptableOrUnknown(
          data['fixed_danger_before_minutes']!,
          _fixedDangerBeforeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('state_anchor_date')) {
      context.handle(
        _stateAnchorDateMeta,
        stateAnchorDate.isAcceptableOrUnknown(
          data['state_anchor_date']!,
          _stateAnchorDateMeta,
        ),
      );
    }
    if (data.containsKey('state_expected_after_minutes')) {
      context.handle(
        _stateExpectedAfterMinutesMeta,
        stateExpectedAfterMinutes.isAcceptableOrUnknown(
          data['state_expected_after_minutes']!,
          _stateExpectedAfterMinutesMeta,
        ),
      );
    }
    if (data.containsKey('state_warning_after_minutes')) {
      context.handle(
        _stateWarningAfterMinutesMeta,
        stateWarningAfterMinutes.isAcceptableOrUnknown(
          data['state_warning_after_minutes']!,
          _stateWarningAfterMinutesMeta,
        ),
      );
    }
    if (data.containsKey('state_danger_after_minutes')) {
      context.handle(
        _stateDangerAfterMinutesMeta,
        stateDangerAfterMinutes.isAcceptableOrUnknown(
          data['state_danger_after_minutes']!,
          _stateDangerAfterMinutesMeta,
        ),
      );
    }
    if (data.containsKey('last_done_at')) {
      context.handle(
        _lastDoneAtMeta,
        lastDoneAt.isAcceptableOrUnknown(
          data['last_done_at']!,
          _lastDoneAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      packId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pack_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      attentionPolicySource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attention_policy_source'],
      )!,
      fixedScheduleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_schedule_type'],
      ),
      fixedScheduleInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_schedule_interval'],
      ),
      fixedMonthlyDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_monthly_day'],
      ),
      fixedRepeatRuleV2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_repeat_rule_v2'],
      ),
      fixedAnchorDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_anchor_date'],
      ),
      fixedDueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_due_date'],
      ),
      fixedTimeOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_time_of_day'],
      ),
      fixedOverduePolicy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_overdue_policy'],
      ),
      fixedExpectedBeforeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_expected_before_minutes'],
      ),
      fixedWarningBeforeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_warning_before_minutes'],
      ),
      fixedDangerBeforeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_danger_before_minutes'],
      ),
      stateAnchorDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state_anchor_date'],
      ),
      stateExpectedAfterMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state_expected_after_minutes'],
      ),
      stateWarningAfterMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state_warning_after_minutes'],
      ),
      stateDangerAfterMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state_danger_after_minutes'],
      ),
      lastDoneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_done_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class ItemRow extends DataClass implements Insertable<ItemRow> {
  final int id;
  final int packId;
  final String title;
  final String? description;
  final String status;
  final String type;
  final String attentionPolicySource;
  final String? fixedScheduleType;
  final int? fixedScheduleInterval;
  final int? fixedMonthlyDay;
  final String? fixedRepeatRuleV2;
  final int? fixedAnchorDate;
  final int? fixedDueDate;
  final String? fixedTimeOfDay;
  final String? fixedOverduePolicy;
  final int? fixedExpectedBeforeMinutes;
  final int? fixedWarningBeforeMinutes;
  final int? fixedDangerBeforeMinutes;
  final int? stateAnchorDate;
  final int? stateExpectedAfterMinutes;
  final int? stateWarningAfterMinutes;
  final int? stateDangerAfterMinutes;
  final int? lastDoneAt;
  final int createdAt;
  final int updatedAt;
  const ItemRow({
    required this.id,
    required this.packId,
    required this.title,
    this.description,
    required this.status,
    required this.type,
    required this.attentionPolicySource,
    this.fixedScheduleType,
    this.fixedScheduleInterval,
    this.fixedMonthlyDay,
    this.fixedRepeatRuleV2,
    this.fixedAnchorDate,
    this.fixedDueDate,
    this.fixedTimeOfDay,
    this.fixedOverduePolicy,
    this.fixedExpectedBeforeMinutes,
    this.fixedWarningBeforeMinutes,
    this.fixedDangerBeforeMinutes,
    this.stateAnchorDate,
    this.stateExpectedAfterMinutes,
    this.stateWarningAfterMinutes,
    this.stateDangerAfterMinutes,
    this.lastDoneAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pack_id'] = Variable<int>(packId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['status'] = Variable<String>(status);
    map['type'] = Variable<String>(type);
    map['attention_policy_source'] = Variable<String>(attentionPolicySource);
    if (!nullToAbsent || fixedScheduleType != null) {
      map['fixed_schedule_type'] = Variable<String>(fixedScheduleType);
    }
    if (!nullToAbsent || fixedScheduleInterval != null) {
      map['fixed_schedule_interval'] = Variable<int>(fixedScheduleInterval);
    }
    if (!nullToAbsent || fixedMonthlyDay != null) {
      map['fixed_monthly_day'] = Variable<int>(fixedMonthlyDay);
    }
    if (!nullToAbsent || fixedRepeatRuleV2 != null) {
      map['fixed_repeat_rule_v2'] = Variable<String>(fixedRepeatRuleV2);
    }
    if (!nullToAbsent || fixedAnchorDate != null) {
      map['fixed_anchor_date'] = Variable<int>(fixedAnchorDate);
    }
    if (!nullToAbsent || fixedDueDate != null) {
      map['fixed_due_date'] = Variable<int>(fixedDueDate);
    }
    if (!nullToAbsent || fixedTimeOfDay != null) {
      map['fixed_time_of_day'] = Variable<String>(fixedTimeOfDay);
    }
    if (!nullToAbsent || fixedOverduePolicy != null) {
      map['fixed_overdue_policy'] = Variable<String>(fixedOverduePolicy);
    }
    if (!nullToAbsent || fixedExpectedBeforeMinutes != null) {
      map['fixed_expected_before_minutes'] = Variable<int>(
        fixedExpectedBeforeMinutes,
      );
    }
    if (!nullToAbsent || fixedWarningBeforeMinutes != null) {
      map['fixed_warning_before_minutes'] = Variable<int>(
        fixedWarningBeforeMinutes,
      );
    }
    if (!nullToAbsent || fixedDangerBeforeMinutes != null) {
      map['fixed_danger_before_minutes'] = Variable<int>(
        fixedDangerBeforeMinutes,
      );
    }
    if (!nullToAbsent || stateAnchorDate != null) {
      map['state_anchor_date'] = Variable<int>(stateAnchorDate);
    }
    if (!nullToAbsent || stateExpectedAfterMinutes != null) {
      map['state_expected_after_minutes'] = Variable<int>(
        stateExpectedAfterMinutes,
      );
    }
    if (!nullToAbsent || stateWarningAfterMinutes != null) {
      map['state_warning_after_minutes'] = Variable<int>(
        stateWarningAfterMinutes,
      );
    }
    if (!nullToAbsent || stateDangerAfterMinutes != null) {
      map['state_danger_after_minutes'] = Variable<int>(
        stateDangerAfterMinutes,
      );
    }
    if (!nullToAbsent || lastDoneAt != null) {
      map['last_done_at'] = Variable<int>(lastDoneAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      packId: Value(packId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      status: Value(status),
      type: Value(type),
      attentionPolicySource: Value(attentionPolicySource),
      fixedScheduleType: fixedScheduleType == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedScheduleType),
      fixedScheduleInterval: fixedScheduleInterval == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedScheduleInterval),
      fixedMonthlyDay: fixedMonthlyDay == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedMonthlyDay),
      fixedRepeatRuleV2: fixedRepeatRuleV2 == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedRepeatRuleV2),
      fixedAnchorDate: fixedAnchorDate == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedAnchorDate),
      fixedDueDate: fixedDueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedDueDate),
      fixedTimeOfDay: fixedTimeOfDay == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedTimeOfDay),
      fixedOverduePolicy: fixedOverduePolicy == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedOverduePolicy),
      fixedExpectedBeforeMinutes:
          fixedExpectedBeforeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedExpectedBeforeMinutes),
      fixedWarningBeforeMinutes:
          fixedWarningBeforeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedWarningBeforeMinutes),
      fixedDangerBeforeMinutes: fixedDangerBeforeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedDangerBeforeMinutes),
      stateAnchorDate: stateAnchorDate == null && nullToAbsent
          ? const Value.absent()
          : Value(stateAnchorDate),
      stateExpectedAfterMinutes:
          stateExpectedAfterMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(stateExpectedAfterMinutes),
      stateWarningAfterMinutes: stateWarningAfterMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(stateWarningAfterMinutes),
      stateDangerAfterMinutes: stateDangerAfterMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(stateDangerAfterMinutes),
      lastDoneAt: lastDoneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDoneAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemRow(
      id: serializer.fromJson<int>(json['id']),
      packId: serializer.fromJson<int>(json['packId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      type: serializer.fromJson<String>(json['type']),
      attentionPolicySource: serializer.fromJson<String>(
        json['attentionPolicySource'],
      ),
      fixedScheduleType: serializer.fromJson<String?>(
        json['fixedScheduleType'],
      ),
      fixedScheduleInterval: serializer.fromJson<int?>(
        json['fixedScheduleInterval'],
      ),
      fixedMonthlyDay: serializer.fromJson<int?>(json['fixedMonthlyDay']),
      fixedRepeatRuleV2: serializer.fromJson<String?>(
        json['fixedRepeatRuleV2'],
      ),
      fixedAnchorDate: serializer.fromJson<int?>(json['fixedAnchorDate']),
      fixedDueDate: serializer.fromJson<int?>(json['fixedDueDate']),
      fixedTimeOfDay: serializer.fromJson<String?>(json['fixedTimeOfDay']),
      fixedOverduePolicy: serializer.fromJson<String?>(
        json['fixedOverduePolicy'],
      ),
      fixedExpectedBeforeMinutes: serializer.fromJson<int?>(
        json['fixedExpectedBeforeMinutes'],
      ),
      fixedWarningBeforeMinutes: serializer.fromJson<int?>(
        json['fixedWarningBeforeMinutes'],
      ),
      fixedDangerBeforeMinutes: serializer.fromJson<int?>(
        json['fixedDangerBeforeMinutes'],
      ),
      stateAnchorDate: serializer.fromJson<int?>(json['stateAnchorDate']),
      stateExpectedAfterMinutes: serializer.fromJson<int?>(
        json['stateExpectedAfterMinutes'],
      ),
      stateWarningAfterMinutes: serializer.fromJson<int?>(
        json['stateWarningAfterMinutes'],
      ),
      stateDangerAfterMinutes: serializer.fromJson<int?>(
        json['stateDangerAfterMinutes'],
      ),
      lastDoneAt: serializer.fromJson<int?>(json['lastDoneAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'packId': serializer.toJson<int>(packId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'status': serializer.toJson<String>(status),
      'type': serializer.toJson<String>(type),
      'attentionPolicySource': serializer.toJson<String>(attentionPolicySource),
      'fixedScheduleType': serializer.toJson<String?>(fixedScheduleType),
      'fixedScheduleInterval': serializer.toJson<int?>(fixedScheduleInterval),
      'fixedMonthlyDay': serializer.toJson<int?>(fixedMonthlyDay),
      'fixedRepeatRuleV2': serializer.toJson<String?>(fixedRepeatRuleV2),
      'fixedAnchorDate': serializer.toJson<int?>(fixedAnchorDate),
      'fixedDueDate': serializer.toJson<int?>(fixedDueDate),
      'fixedTimeOfDay': serializer.toJson<String?>(fixedTimeOfDay),
      'fixedOverduePolicy': serializer.toJson<String?>(fixedOverduePolicy),
      'fixedExpectedBeforeMinutes': serializer.toJson<int?>(
        fixedExpectedBeforeMinutes,
      ),
      'fixedWarningBeforeMinutes': serializer.toJson<int?>(
        fixedWarningBeforeMinutes,
      ),
      'fixedDangerBeforeMinutes': serializer.toJson<int?>(
        fixedDangerBeforeMinutes,
      ),
      'stateAnchorDate': serializer.toJson<int?>(stateAnchorDate),
      'stateExpectedAfterMinutes': serializer.toJson<int?>(
        stateExpectedAfterMinutes,
      ),
      'stateWarningAfterMinutes': serializer.toJson<int?>(
        stateWarningAfterMinutes,
      ),
      'stateDangerAfterMinutes': serializer.toJson<int?>(
        stateDangerAfterMinutes,
      ),
      'lastDoneAt': serializer.toJson<int?>(lastDoneAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ItemRow copyWith({
    int? id,
    int? packId,
    String? title,
    Value<String?> description = const Value.absent(),
    String? status,
    String? type,
    String? attentionPolicySource,
    Value<String?> fixedScheduleType = const Value.absent(),
    Value<int?> fixedScheduleInterval = const Value.absent(),
    Value<int?> fixedMonthlyDay = const Value.absent(),
    Value<String?> fixedRepeatRuleV2 = const Value.absent(),
    Value<int?> fixedAnchorDate = const Value.absent(),
    Value<int?> fixedDueDate = const Value.absent(),
    Value<String?> fixedTimeOfDay = const Value.absent(),
    Value<String?> fixedOverduePolicy = const Value.absent(),
    Value<int?> fixedExpectedBeforeMinutes = const Value.absent(),
    Value<int?> fixedWarningBeforeMinutes = const Value.absent(),
    Value<int?> fixedDangerBeforeMinutes = const Value.absent(),
    Value<int?> stateAnchorDate = const Value.absent(),
    Value<int?> stateExpectedAfterMinutes = const Value.absent(),
    Value<int?> stateWarningAfterMinutes = const Value.absent(),
    Value<int?> stateDangerAfterMinutes = const Value.absent(),
    Value<int?> lastDoneAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => ItemRow(
    id: id ?? this.id,
    packId: packId ?? this.packId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    status: status ?? this.status,
    type: type ?? this.type,
    attentionPolicySource: attentionPolicySource ?? this.attentionPolicySource,
    fixedScheduleType: fixedScheduleType.present
        ? fixedScheduleType.value
        : this.fixedScheduleType,
    fixedScheduleInterval: fixedScheduleInterval.present
        ? fixedScheduleInterval.value
        : this.fixedScheduleInterval,
    fixedMonthlyDay: fixedMonthlyDay.present
        ? fixedMonthlyDay.value
        : this.fixedMonthlyDay,
    fixedRepeatRuleV2: fixedRepeatRuleV2.present
        ? fixedRepeatRuleV2.value
        : this.fixedRepeatRuleV2,
    fixedAnchorDate: fixedAnchorDate.present
        ? fixedAnchorDate.value
        : this.fixedAnchorDate,
    fixedDueDate: fixedDueDate.present ? fixedDueDate.value : this.fixedDueDate,
    fixedTimeOfDay: fixedTimeOfDay.present
        ? fixedTimeOfDay.value
        : this.fixedTimeOfDay,
    fixedOverduePolicy: fixedOverduePolicy.present
        ? fixedOverduePolicy.value
        : this.fixedOverduePolicy,
    fixedExpectedBeforeMinutes: fixedExpectedBeforeMinutes.present
        ? fixedExpectedBeforeMinutes.value
        : this.fixedExpectedBeforeMinutes,
    fixedWarningBeforeMinutes: fixedWarningBeforeMinutes.present
        ? fixedWarningBeforeMinutes.value
        : this.fixedWarningBeforeMinutes,
    fixedDangerBeforeMinutes: fixedDangerBeforeMinutes.present
        ? fixedDangerBeforeMinutes.value
        : this.fixedDangerBeforeMinutes,
    stateAnchorDate: stateAnchorDate.present
        ? stateAnchorDate.value
        : this.stateAnchorDate,
    stateExpectedAfterMinutes: stateExpectedAfterMinutes.present
        ? stateExpectedAfterMinutes.value
        : this.stateExpectedAfterMinutes,
    stateWarningAfterMinutes: stateWarningAfterMinutes.present
        ? stateWarningAfterMinutes.value
        : this.stateWarningAfterMinutes,
    stateDangerAfterMinutes: stateDangerAfterMinutes.present
        ? stateDangerAfterMinutes.value
        : this.stateDangerAfterMinutes,
    lastDoneAt: lastDoneAt.present ? lastDoneAt.value : this.lastDoneAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ItemRow copyWithCompanion(ItemsCompanion data) {
    return ItemRow(
      id: data.id.present ? data.id.value : this.id,
      packId: data.packId.present ? data.packId.value : this.packId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
      type: data.type.present ? data.type.value : this.type,
      attentionPolicySource: data.attentionPolicySource.present
          ? data.attentionPolicySource.value
          : this.attentionPolicySource,
      fixedScheduleType: data.fixedScheduleType.present
          ? data.fixedScheduleType.value
          : this.fixedScheduleType,
      fixedScheduleInterval: data.fixedScheduleInterval.present
          ? data.fixedScheduleInterval.value
          : this.fixedScheduleInterval,
      fixedMonthlyDay: data.fixedMonthlyDay.present
          ? data.fixedMonthlyDay.value
          : this.fixedMonthlyDay,
      fixedRepeatRuleV2: data.fixedRepeatRuleV2.present
          ? data.fixedRepeatRuleV2.value
          : this.fixedRepeatRuleV2,
      fixedAnchorDate: data.fixedAnchorDate.present
          ? data.fixedAnchorDate.value
          : this.fixedAnchorDate,
      fixedDueDate: data.fixedDueDate.present
          ? data.fixedDueDate.value
          : this.fixedDueDate,
      fixedTimeOfDay: data.fixedTimeOfDay.present
          ? data.fixedTimeOfDay.value
          : this.fixedTimeOfDay,
      fixedOverduePolicy: data.fixedOverduePolicy.present
          ? data.fixedOverduePolicy.value
          : this.fixedOverduePolicy,
      fixedExpectedBeforeMinutes: data.fixedExpectedBeforeMinutes.present
          ? data.fixedExpectedBeforeMinutes.value
          : this.fixedExpectedBeforeMinutes,
      fixedWarningBeforeMinutes: data.fixedWarningBeforeMinutes.present
          ? data.fixedWarningBeforeMinutes.value
          : this.fixedWarningBeforeMinutes,
      fixedDangerBeforeMinutes: data.fixedDangerBeforeMinutes.present
          ? data.fixedDangerBeforeMinutes.value
          : this.fixedDangerBeforeMinutes,
      stateAnchorDate: data.stateAnchorDate.present
          ? data.stateAnchorDate.value
          : this.stateAnchorDate,
      stateExpectedAfterMinutes: data.stateExpectedAfterMinutes.present
          ? data.stateExpectedAfterMinutes.value
          : this.stateExpectedAfterMinutes,
      stateWarningAfterMinutes: data.stateWarningAfterMinutes.present
          ? data.stateWarningAfterMinutes.value
          : this.stateWarningAfterMinutes,
      stateDangerAfterMinutes: data.stateDangerAfterMinutes.present
          ? data.stateDangerAfterMinutes.value
          : this.stateDangerAfterMinutes,
      lastDoneAt: data.lastDoneAt.present
          ? data.lastDoneAt.value
          : this.lastDoneAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemRow(')
          ..write('id: $id, ')
          ..write('packId: $packId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('attentionPolicySource: $attentionPolicySource, ')
          ..write('fixedScheduleType: $fixedScheduleType, ')
          ..write('fixedScheduleInterval: $fixedScheduleInterval, ')
          ..write('fixedMonthlyDay: $fixedMonthlyDay, ')
          ..write('fixedRepeatRuleV2: $fixedRepeatRuleV2, ')
          ..write('fixedAnchorDate: $fixedAnchorDate, ')
          ..write('fixedDueDate: $fixedDueDate, ')
          ..write('fixedTimeOfDay: $fixedTimeOfDay, ')
          ..write('fixedOverduePolicy: $fixedOverduePolicy, ')
          ..write('fixedExpectedBeforeMinutes: $fixedExpectedBeforeMinutes, ')
          ..write('fixedWarningBeforeMinutes: $fixedWarningBeforeMinutes, ')
          ..write('fixedDangerBeforeMinutes: $fixedDangerBeforeMinutes, ')
          ..write('stateAnchorDate: $stateAnchorDate, ')
          ..write('stateExpectedAfterMinutes: $stateExpectedAfterMinutes, ')
          ..write('stateWarningAfterMinutes: $stateWarningAfterMinutes, ')
          ..write('stateDangerAfterMinutes: $stateDangerAfterMinutes, ')
          ..write('lastDoneAt: $lastDoneAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    packId,
    title,
    description,
    status,
    type,
    attentionPolicySource,
    fixedScheduleType,
    fixedScheduleInterval,
    fixedMonthlyDay,
    fixedRepeatRuleV2,
    fixedAnchorDate,
    fixedDueDate,
    fixedTimeOfDay,
    fixedOverduePolicy,
    fixedExpectedBeforeMinutes,
    fixedWarningBeforeMinutes,
    fixedDangerBeforeMinutes,
    stateAnchorDate,
    stateExpectedAfterMinutes,
    stateWarningAfterMinutes,
    stateDangerAfterMinutes,
    lastDoneAt,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemRow &&
          other.id == this.id &&
          other.packId == this.packId &&
          other.title == this.title &&
          other.description == this.description &&
          other.status == this.status &&
          other.type == this.type &&
          other.attentionPolicySource == this.attentionPolicySource &&
          other.fixedScheduleType == this.fixedScheduleType &&
          other.fixedScheduleInterval == this.fixedScheduleInterval &&
          other.fixedMonthlyDay == this.fixedMonthlyDay &&
          other.fixedRepeatRuleV2 == this.fixedRepeatRuleV2 &&
          other.fixedAnchorDate == this.fixedAnchorDate &&
          other.fixedDueDate == this.fixedDueDate &&
          other.fixedTimeOfDay == this.fixedTimeOfDay &&
          other.fixedOverduePolicy == this.fixedOverduePolicy &&
          other.fixedExpectedBeforeMinutes == this.fixedExpectedBeforeMinutes &&
          other.fixedWarningBeforeMinutes == this.fixedWarningBeforeMinutes &&
          other.fixedDangerBeforeMinutes == this.fixedDangerBeforeMinutes &&
          other.stateAnchorDate == this.stateAnchorDate &&
          other.stateExpectedAfterMinutes == this.stateExpectedAfterMinutes &&
          other.stateWarningAfterMinutes == this.stateWarningAfterMinutes &&
          other.stateDangerAfterMinutes == this.stateDangerAfterMinutes &&
          other.lastDoneAt == this.lastDoneAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ItemsCompanion extends UpdateCompanion<ItemRow> {
  final Value<int> id;
  final Value<int> packId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> status;
  final Value<String> type;
  final Value<String> attentionPolicySource;
  final Value<String?> fixedScheduleType;
  final Value<int?> fixedScheduleInterval;
  final Value<int?> fixedMonthlyDay;
  final Value<String?> fixedRepeatRuleV2;
  final Value<int?> fixedAnchorDate;
  final Value<int?> fixedDueDate;
  final Value<String?> fixedTimeOfDay;
  final Value<String?> fixedOverduePolicy;
  final Value<int?> fixedExpectedBeforeMinutes;
  final Value<int?> fixedWarningBeforeMinutes;
  final Value<int?> fixedDangerBeforeMinutes;
  final Value<int?> stateAnchorDate;
  final Value<int?> stateExpectedAfterMinutes;
  final Value<int?> stateWarningAfterMinutes;
  final Value<int?> stateDangerAfterMinutes;
  final Value<int?> lastDoneAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.packId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.type = const Value.absent(),
    this.attentionPolicySource = const Value.absent(),
    this.fixedScheduleType = const Value.absent(),
    this.fixedScheduleInterval = const Value.absent(),
    this.fixedMonthlyDay = const Value.absent(),
    this.fixedRepeatRuleV2 = const Value.absent(),
    this.fixedAnchorDate = const Value.absent(),
    this.fixedDueDate = const Value.absent(),
    this.fixedTimeOfDay = const Value.absent(),
    this.fixedOverduePolicy = const Value.absent(),
    this.fixedExpectedBeforeMinutes = const Value.absent(),
    this.fixedWarningBeforeMinutes = const Value.absent(),
    this.fixedDangerBeforeMinutes = const Value.absent(),
    this.stateAnchorDate = const Value.absent(),
    this.stateExpectedAfterMinutes = const Value.absent(),
    this.stateWarningAfterMinutes = const Value.absent(),
    this.stateDangerAfterMinutes = const Value.absent(),
    this.lastDoneAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ItemsCompanion.insert({
    this.id = const Value.absent(),
    required int packId,
    required String title,
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    required String type,
    this.attentionPolicySource = const Value.absent(),
    this.fixedScheduleType = const Value.absent(),
    this.fixedScheduleInterval = const Value.absent(),
    this.fixedMonthlyDay = const Value.absent(),
    this.fixedRepeatRuleV2 = const Value.absent(),
    this.fixedAnchorDate = const Value.absent(),
    this.fixedDueDate = const Value.absent(),
    this.fixedTimeOfDay = const Value.absent(),
    this.fixedOverduePolicy = const Value.absent(),
    this.fixedExpectedBeforeMinutes = const Value.absent(),
    this.fixedWarningBeforeMinutes = const Value.absent(),
    this.fixedDangerBeforeMinutes = const Value.absent(),
    this.stateAnchorDate = const Value.absent(),
    this.stateExpectedAfterMinutes = const Value.absent(),
    this.stateWarningAfterMinutes = const Value.absent(),
    this.stateDangerAfterMinutes = const Value.absent(),
    this.lastDoneAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : packId = Value(packId),
       title = Value(title),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ItemRow> custom({
    Expression<int>? id,
    Expression<int>? packId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? status,
    Expression<String>? type,
    Expression<String>? attentionPolicySource,
    Expression<String>? fixedScheduleType,
    Expression<int>? fixedScheduleInterval,
    Expression<int>? fixedMonthlyDay,
    Expression<String>? fixedRepeatRuleV2,
    Expression<int>? fixedAnchorDate,
    Expression<int>? fixedDueDate,
    Expression<String>? fixedTimeOfDay,
    Expression<String>? fixedOverduePolicy,
    Expression<int>? fixedExpectedBeforeMinutes,
    Expression<int>? fixedWarningBeforeMinutes,
    Expression<int>? fixedDangerBeforeMinutes,
    Expression<int>? stateAnchorDate,
    Expression<int>? stateExpectedAfterMinutes,
    Expression<int>? stateWarningAfterMinutes,
    Expression<int>? stateDangerAfterMinutes,
    Expression<int>? lastDoneAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packId != null) 'pack_id': packId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      if (attentionPolicySource != null)
        'attention_policy_source': attentionPolicySource,
      if (fixedScheduleType != null) 'fixed_schedule_type': fixedScheduleType,
      if (fixedScheduleInterval != null)
        'fixed_schedule_interval': fixedScheduleInterval,
      if (fixedMonthlyDay != null) 'fixed_monthly_day': fixedMonthlyDay,
      if (fixedRepeatRuleV2 != null) 'fixed_repeat_rule_v2': fixedRepeatRuleV2,
      if (fixedAnchorDate != null) 'fixed_anchor_date': fixedAnchorDate,
      if (fixedDueDate != null) 'fixed_due_date': fixedDueDate,
      if (fixedTimeOfDay != null) 'fixed_time_of_day': fixedTimeOfDay,
      if (fixedOverduePolicy != null)
        'fixed_overdue_policy': fixedOverduePolicy,
      if (fixedExpectedBeforeMinutes != null)
        'fixed_expected_before_minutes': fixedExpectedBeforeMinutes,
      if (fixedWarningBeforeMinutes != null)
        'fixed_warning_before_minutes': fixedWarningBeforeMinutes,
      if (fixedDangerBeforeMinutes != null)
        'fixed_danger_before_minutes': fixedDangerBeforeMinutes,
      if (stateAnchorDate != null) 'state_anchor_date': stateAnchorDate,
      if (stateExpectedAfterMinutes != null)
        'state_expected_after_minutes': stateExpectedAfterMinutes,
      if (stateWarningAfterMinutes != null)
        'state_warning_after_minutes': stateWarningAfterMinutes,
      if (stateDangerAfterMinutes != null)
        'state_danger_after_minutes': stateDangerAfterMinutes,
      if (lastDoneAt != null) 'last_done_at': lastDoneAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? packId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? status,
    Value<String>? type,
    Value<String>? attentionPolicySource,
    Value<String?>? fixedScheduleType,
    Value<int?>? fixedScheduleInterval,
    Value<int?>? fixedMonthlyDay,
    Value<String?>? fixedRepeatRuleV2,
    Value<int?>? fixedAnchorDate,
    Value<int?>? fixedDueDate,
    Value<String?>? fixedTimeOfDay,
    Value<String?>? fixedOverduePolicy,
    Value<int?>? fixedExpectedBeforeMinutes,
    Value<int?>? fixedWarningBeforeMinutes,
    Value<int?>? fixedDangerBeforeMinutes,
    Value<int?>? stateAnchorDate,
    Value<int?>? stateExpectedAfterMinutes,
    Value<int?>? stateWarningAfterMinutes,
    Value<int?>? stateDangerAfterMinutes,
    Value<int?>? lastDoneAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      packId: packId ?? this.packId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      type: type ?? this.type,
      attentionPolicySource:
          attentionPolicySource ?? this.attentionPolicySource,
      fixedScheduleType: fixedScheduleType ?? this.fixedScheduleType,
      fixedScheduleInterval:
          fixedScheduleInterval ?? this.fixedScheduleInterval,
      fixedMonthlyDay: fixedMonthlyDay ?? this.fixedMonthlyDay,
      fixedRepeatRuleV2: fixedRepeatRuleV2 ?? this.fixedRepeatRuleV2,
      fixedAnchorDate: fixedAnchorDate ?? this.fixedAnchorDate,
      fixedDueDate: fixedDueDate ?? this.fixedDueDate,
      fixedTimeOfDay: fixedTimeOfDay ?? this.fixedTimeOfDay,
      fixedOverduePolicy: fixedOverduePolicy ?? this.fixedOverduePolicy,
      fixedExpectedBeforeMinutes:
          fixedExpectedBeforeMinutes ?? this.fixedExpectedBeforeMinutes,
      fixedWarningBeforeMinutes:
          fixedWarningBeforeMinutes ?? this.fixedWarningBeforeMinutes,
      fixedDangerBeforeMinutes:
          fixedDangerBeforeMinutes ?? this.fixedDangerBeforeMinutes,
      stateAnchorDate: stateAnchorDate ?? this.stateAnchorDate,
      stateExpectedAfterMinutes:
          stateExpectedAfterMinutes ?? this.stateExpectedAfterMinutes,
      stateWarningAfterMinutes:
          stateWarningAfterMinutes ?? this.stateWarningAfterMinutes,
      stateDangerAfterMinutes:
          stateDangerAfterMinutes ?? this.stateDangerAfterMinutes,
      lastDoneAt: lastDoneAt ?? this.lastDoneAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (packId.present) {
      map['pack_id'] = Variable<int>(packId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (attentionPolicySource.present) {
      map['attention_policy_source'] = Variable<String>(
        attentionPolicySource.value,
      );
    }
    if (fixedScheduleType.present) {
      map['fixed_schedule_type'] = Variable<String>(fixedScheduleType.value);
    }
    if (fixedScheduleInterval.present) {
      map['fixed_schedule_interval'] = Variable<int>(
        fixedScheduleInterval.value,
      );
    }
    if (fixedMonthlyDay.present) {
      map['fixed_monthly_day'] = Variable<int>(fixedMonthlyDay.value);
    }
    if (fixedRepeatRuleV2.present) {
      map['fixed_repeat_rule_v2'] = Variable<String>(fixedRepeatRuleV2.value);
    }
    if (fixedAnchorDate.present) {
      map['fixed_anchor_date'] = Variable<int>(fixedAnchorDate.value);
    }
    if (fixedDueDate.present) {
      map['fixed_due_date'] = Variable<int>(fixedDueDate.value);
    }
    if (fixedTimeOfDay.present) {
      map['fixed_time_of_day'] = Variable<String>(fixedTimeOfDay.value);
    }
    if (fixedOverduePolicy.present) {
      map['fixed_overdue_policy'] = Variable<String>(fixedOverduePolicy.value);
    }
    if (fixedExpectedBeforeMinutes.present) {
      map['fixed_expected_before_minutes'] = Variable<int>(
        fixedExpectedBeforeMinutes.value,
      );
    }
    if (fixedWarningBeforeMinutes.present) {
      map['fixed_warning_before_minutes'] = Variable<int>(
        fixedWarningBeforeMinutes.value,
      );
    }
    if (fixedDangerBeforeMinutes.present) {
      map['fixed_danger_before_minutes'] = Variable<int>(
        fixedDangerBeforeMinutes.value,
      );
    }
    if (stateAnchorDate.present) {
      map['state_anchor_date'] = Variable<int>(stateAnchorDate.value);
    }
    if (stateExpectedAfterMinutes.present) {
      map['state_expected_after_minutes'] = Variable<int>(
        stateExpectedAfterMinutes.value,
      );
    }
    if (stateWarningAfterMinutes.present) {
      map['state_warning_after_minutes'] = Variable<int>(
        stateWarningAfterMinutes.value,
      );
    }
    if (stateDangerAfterMinutes.present) {
      map['state_danger_after_minutes'] = Variable<int>(
        stateDangerAfterMinutes.value,
      );
    }
    if (lastDoneAt.present) {
      map['last_done_at'] = Variable<int>(lastDoneAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('packId: $packId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('attentionPolicySource: $attentionPolicySource, ')
          ..write('fixedScheduleType: $fixedScheduleType, ')
          ..write('fixedScheduleInterval: $fixedScheduleInterval, ')
          ..write('fixedMonthlyDay: $fixedMonthlyDay, ')
          ..write('fixedRepeatRuleV2: $fixedRepeatRuleV2, ')
          ..write('fixedAnchorDate: $fixedAnchorDate, ')
          ..write('fixedDueDate: $fixedDueDate, ')
          ..write('fixedTimeOfDay: $fixedTimeOfDay, ')
          ..write('fixedOverduePolicy: $fixedOverduePolicy, ')
          ..write('fixedExpectedBeforeMinutes: $fixedExpectedBeforeMinutes, ')
          ..write('fixedWarningBeforeMinutes: $fixedWarningBeforeMinutes, ')
          ..write('fixedDangerBeforeMinutes: $fixedDangerBeforeMinutes, ')
          ..write('stateAnchorDate: $stateAnchorDate, ')
          ..write('stateExpectedAfterMinutes: $stateExpectedAfterMinutes, ')
          ..write('stateWarningAfterMinutes: $stateWarningAfterMinutes, ')
          ..write('stateDangerAfterMinutes: $stateDangerAfterMinutes, ')
          ..write('lastDoneAt: $lastDoneAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PackTemplatesTable extends PackTemplates
    with TableInfo<$PackTemplatesTable, PackTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PackTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _templateNameMeta = const VerificationMeta(
    'templateName',
  );
  @override
  late final GeneratedColumn<String> templateName = GeneratedColumn<String>(
    'template_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconEmojiMeta = const VerificationMeta(
    'iconEmoji',
  );
  @override
  late final GeneratedColumn<String> iconEmoji = GeneratedColumn<String>(
    'icon_emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('🏷️'),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateName,
    iconEmoji,
    description,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pack_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<PackTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template_name')) {
      context.handle(
        _templateNameMeta,
        templateName.isAcceptableOrUnknown(
          data['template_name']!,
          _templateNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateNameMeta);
    }
    if (data.containsKey('icon_emoji')) {
      context.handle(
        _iconEmojiMeta,
        iconEmoji.isAcceptableOrUnknown(data['icon_emoji']!, _iconEmojiMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PackTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PackTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      templateName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_name'],
      )!,
      iconEmoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_emoji'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PackTemplatesTable createAlias(String alias) {
    return $PackTemplatesTable(attachedDatabase, alias);
  }
}

class PackTemplateRow extends DataClass implements Insertable<PackTemplateRow> {
  final int id;
  final String templateName;
  final String iconEmoji;
  final String? description;
  final int createdAt;
  final int updatedAt;
  const PackTemplateRow({
    required this.id,
    required this.templateName,
    required this.iconEmoji,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template_name'] = Variable<String>(templateName);
    map['icon_emoji'] = Variable<String>(iconEmoji);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PackTemplatesCompanion toCompanion(bool nullToAbsent) {
    return PackTemplatesCompanion(
      id: Value(id),
      templateName: Value(templateName),
      iconEmoji: Value(iconEmoji),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PackTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PackTemplateRow(
      id: serializer.fromJson<int>(json['id']),
      templateName: serializer.fromJson<String>(json['templateName']),
      iconEmoji: serializer.fromJson<String>(json['iconEmoji']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateName': serializer.toJson<String>(templateName),
      'iconEmoji': serializer.toJson<String>(iconEmoji),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  PackTemplateRow copyWith({
    int? id,
    String? templateName,
    String? iconEmoji,
    Value<String?> description = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => PackTemplateRow(
    id: id ?? this.id,
    templateName: templateName ?? this.templateName,
    iconEmoji: iconEmoji ?? this.iconEmoji,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PackTemplateRow copyWithCompanion(PackTemplatesCompanion data) {
    return PackTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      templateName: data.templateName.present
          ? data.templateName.value
          : this.templateName,
      iconEmoji: data.iconEmoji.present ? data.iconEmoji.value : this.iconEmoji,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PackTemplateRow(')
          ..write('id: $id, ')
          ..write('templateName: $templateName, ')
          ..write('iconEmoji: $iconEmoji, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateName,
    iconEmoji,
    description,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PackTemplateRow &&
          other.id == this.id &&
          other.templateName == this.templateName &&
          other.iconEmoji == this.iconEmoji &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PackTemplatesCompanion extends UpdateCompanion<PackTemplateRow> {
  final Value<int> id;
  final Value<String> templateName;
  final Value<String> iconEmoji;
  final Value<String?> description;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const PackTemplatesCompanion({
    this.id = const Value.absent(),
    this.templateName = const Value.absent(),
    this.iconEmoji = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PackTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String templateName,
    this.iconEmoji = const Value.absent(),
    this.description = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : templateName = Value(templateName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PackTemplateRow> custom({
    Expression<int>? id,
    Expression<String>? templateName,
    Expression<String>? iconEmoji,
    Expression<String>? description,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateName != null) 'template_name': templateName,
      if (iconEmoji != null) 'icon_emoji': iconEmoji,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PackTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? templateName,
    Value<String>? iconEmoji,
    Value<String?>? description,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return PackTemplatesCompanion(
      id: id ?? this.id,
      templateName: templateName ?? this.templateName,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (templateName.present) {
      map['template_name'] = Variable<String>(templateName.value);
    }
    if (iconEmoji.present) {
      map['icon_emoji'] = Variable<String>(iconEmoji.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PackTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('templateName: $templateName, ')
          ..write('iconEmoji: $iconEmoji, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PackTemplateItemsTable extends PackTemplateItems
    with TableInfo<$PackTemplateItemsTable, PackTemplateItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PackTemplateItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pack_templates (id)',
    ),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attentionPolicySourceMeta =
      const VerificationMeta('attentionPolicySource');
  @override
  late final GeneratedColumn<String> attentionPolicySource =
      GeneratedColumn<String>(
        'attention_policy_source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('systemDefault'),
      );
  static const VerificationMeta _fixedScheduleTypeMeta = const VerificationMeta(
    'fixedScheduleType',
  );
  @override
  late final GeneratedColumn<String> fixedScheduleType =
      GeneratedColumn<String>(
        'fixed_schedule_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fixedScheduleIntervalMeta =
      const VerificationMeta('fixedScheduleInterval');
  @override
  late final GeneratedColumn<int> fixedScheduleInterval = GeneratedColumn<int>(
    'fixed_schedule_interval',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixedMonthlyDayMeta = const VerificationMeta(
    'fixedMonthlyDay',
  );
  @override
  late final GeneratedColumn<int> fixedMonthlyDay = GeneratedColumn<int>(
    'fixed_monthly_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixedRepeatRuleV2Meta = const VerificationMeta(
    'fixedRepeatRuleV2',
  );
  @override
  late final GeneratedColumn<String> fixedRepeatRuleV2 =
      GeneratedColumn<String>(
        'fixed_repeat_rule_v2',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fixedTimeOfDayMeta = const VerificationMeta(
    'fixedTimeOfDay',
  );
  @override
  late final GeneratedColumn<String> fixedTimeOfDay = GeneratedColumn<String>(
    'fixed_time_of_day',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixedOverduePolicyMeta =
      const VerificationMeta('fixedOverduePolicy');
  @override
  late final GeneratedColumn<String> fixedOverduePolicy =
      GeneratedColumn<String>(
        'fixed_overdue_policy',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fixedExpectedBeforeMinutesMeta =
      const VerificationMeta('fixedExpectedBeforeMinutes');
  @override
  late final GeneratedColumn<int> fixedExpectedBeforeMinutes =
      GeneratedColumn<int>(
        'fixed_expected_before_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fixedWarningBeforeMinutesMeta =
      const VerificationMeta('fixedWarningBeforeMinutes');
  @override
  late final GeneratedColumn<int> fixedWarningBeforeMinutes =
      GeneratedColumn<int>(
        'fixed_warning_before_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fixedDangerBeforeMinutesMeta =
      const VerificationMeta('fixedDangerBeforeMinutes');
  @override
  late final GeneratedColumn<int> fixedDangerBeforeMinutes =
      GeneratedColumn<int>(
        'fixed_danger_before_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _stateExpectedAfterMinutesMeta =
      const VerificationMeta('stateExpectedAfterMinutes');
  @override
  late final GeneratedColumn<int> stateExpectedAfterMinutes =
      GeneratedColumn<int>(
        'state_expected_after_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _stateWarningAfterMinutesMeta =
      const VerificationMeta('stateWarningAfterMinutes');
  @override
  late final GeneratedColumn<int> stateWarningAfterMinutes =
      GeneratedColumn<int>(
        'state_warning_after_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _stateDangerAfterMinutesMeta =
      const VerificationMeta('stateDangerAfterMinutes');
  @override
  late final GeneratedColumn<int> stateDangerAfterMinutes =
      GeneratedColumn<int>(
        'state_danger_after_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    orderIndex,
    title,
    type,
    attentionPolicySource,
    fixedScheduleType,
    fixedScheduleInterval,
    fixedMonthlyDay,
    fixedRepeatRuleV2,
    fixedTimeOfDay,
    fixedOverduePolicy,
    fixedExpectedBeforeMinutes,
    fixedWarningBeforeMinutes,
    fixedDangerBeforeMinutes,
    stateExpectedAfterMinutes,
    stateWarningAfterMinutes,
    stateDangerAfterMinutes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pack_template_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PackTemplateItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('attention_policy_source')) {
      context.handle(
        _attentionPolicySourceMeta,
        attentionPolicySource.isAcceptableOrUnknown(
          data['attention_policy_source']!,
          _attentionPolicySourceMeta,
        ),
      );
    }
    if (data.containsKey('fixed_schedule_type')) {
      context.handle(
        _fixedScheduleTypeMeta,
        fixedScheduleType.isAcceptableOrUnknown(
          data['fixed_schedule_type']!,
          _fixedScheduleTypeMeta,
        ),
      );
    }
    if (data.containsKey('fixed_schedule_interval')) {
      context.handle(
        _fixedScheduleIntervalMeta,
        fixedScheduleInterval.isAcceptableOrUnknown(
          data['fixed_schedule_interval']!,
          _fixedScheduleIntervalMeta,
        ),
      );
    }
    if (data.containsKey('fixed_monthly_day')) {
      context.handle(
        _fixedMonthlyDayMeta,
        fixedMonthlyDay.isAcceptableOrUnknown(
          data['fixed_monthly_day']!,
          _fixedMonthlyDayMeta,
        ),
      );
    }
    if (data.containsKey('fixed_repeat_rule_v2')) {
      context.handle(
        _fixedRepeatRuleV2Meta,
        fixedRepeatRuleV2.isAcceptableOrUnknown(
          data['fixed_repeat_rule_v2']!,
          _fixedRepeatRuleV2Meta,
        ),
      );
    }
    if (data.containsKey('fixed_time_of_day')) {
      context.handle(
        _fixedTimeOfDayMeta,
        fixedTimeOfDay.isAcceptableOrUnknown(
          data['fixed_time_of_day']!,
          _fixedTimeOfDayMeta,
        ),
      );
    }
    if (data.containsKey('fixed_overdue_policy')) {
      context.handle(
        _fixedOverduePolicyMeta,
        fixedOverduePolicy.isAcceptableOrUnknown(
          data['fixed_overdue_policy']!,
          _fixedOverduePolicyMeta,
        ),
      );
    }
    if (data.containsKey('fixed_expected_before_minutes')) {
      context.handle(
        _fixedExpectedBeforeMinutesMeta,
        fixedExpectedBeforeMinutes.isAcceptableOrUnknown(
          data['fixed_expected_before_minutes']!,
          _fixedExpectedBeforeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('fixed_warning_before_minutes')) {
      context.handle(
        _fixedWarningBeforeMinutesMeta,
        fixedWarningBeforeMinutes.isAcceptableOrUnknown(
          data['fixed_warning_before_minutes']!,
          _fixedWarningBeforeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('fixed_danger_before_minutes')) {
      context.handle(
        _fixedDangerBeforeMinutesMeta,
        fixedDangerBeforeMinutes.isAcceptableOrUnknown(
          data['fixed_danger_before_minutes']!,
          _fixedDangerBeforeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('state_expected_after_minutes')) {
      context.handle(
        _stateExpectedAfterMinutesMeta,
        stateExpectedAfterMinutes.isAcceptableOrUnknown(
          data['state_expected_after_minutes']!,
          _stateExpectedAfterMinutesMeta,
        ),
      );
    }
    if (data.containsKey('state_warning_after_minutes')) {
      context.handle(
        _stateWarningAfterMinutesMeta,
        stateWarningAfterMinutes.isAcceptableOrUnknown(
          data['state_warning_after_minutes']!,
          _stateWarningAfterMinutesMeta,
        ),
      );
    }
    if (data.containsKey('state_danger_after_minutes')) {
      context.handle(
        _stateDangerAfterMinutesMeta,
        stateDangerAfterMinutes.isAcceptableOrUnknown(
          data['state_danger_after_minutes']!,
          _stateDangerAfterMinutesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PackTemplateItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PackTemplateItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      attentionPolicySource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attention_policy_source'],
      )!,
      fixedScheduleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_schedule_type'],
      ),
      fixedScheduleInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_schedule_interval'],
      ),
      fixedMonthlyDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_monthly_day'],
      ),
      fixedRepeatRuleV2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_repeat_rule_v2'],
      ),
      fixedTimeOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_time_of_day'],
      ),
      fixedOverduePolicy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_overdue_policy'],
      ),
      fixedExpectedBeforeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_expected_before_minutes'],
      ),
      fixedWarningBeforeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_warning_before_minutes'],
      ),
      fixedDangerBeforeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_danger_before_minutes'],
      ),
      stateExpectedAfterMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state_expected_after_minutes'],
      ),
      stateWarningAfterMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state_warning_after_minutes'],
      ),
      stateDangerAfterMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state_danger_after_minutes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PackTemplateItemsTable createAlias(String alias) {
    return $PackTemplateItemsTable(attachedDatabase, alias);
  }
}

class PackTemplateItemRow extends DataClass
    implements Insertable<PackTemplateItemRow> {
  final int id;
  final int templateId;
  final int orderIndex;
  final String title;
  final String type;
  final String attentionPolicySource;
  final String? fixedScheduleType;
  final int? fixedScheduleInterval;
  final int? fixedMonthlyDay;
  final String? fixedRepeatRuleV2;
  final String? fixedTimeOfDay;
  final String? fixedOverduePolicy;
  final int? fixedExpectedBeforeMinutes;
  final int? fixedWarningBeforeMinutes;
  final int? fixedDangerBeforeMinutes;
  final int? stateExpectedAfterMinutes;
  final int? stateWarningAfterMinutes;
  final int? stateDangerAfterMinutes;
  final int createdAt;
  final int updatedAt;
  const PackTemplateItemRow({
    required this.id,
    required this.templateId,
    required this.orderIndex,
    required this.title,
    required this.type,
    required this.attentionPolicySource,
    this.fixedScheduleType,
    this.fixedScheduleInterval,
    this.fixedMonthlyDay,
    this.fixedRepeatRuleV2,
    this.fixedTimeOfDay,
    this.fixedOverduePolicy,
    this.fixedExpectedBeforeMinutes,
    this.fixedWarningBeforeMinutes,
    this.fixedDangerBeforeMinutes,
    this.stateExpectedAfterMinutes,
    this.stateWarningAfterMinutes,
    this.stateDangerAfterMinutes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template_id'] = Variable<int>(templateId);
    map['order_index'] = Variable<int>(orderIndex);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    map['attention_policy_source'] = Variable<String>(attentionPolicySource);
    if (!nullToAbsent || fixedScheduleType != null) {
      map['fixed_schedule_type'] = Variable<String>(fixedScheduleType);
    }
    if (!nullToAbsent || fixedScheduleInterval != null) {
      map['fixed_schedule_interval'] = Variable<int>(fixedScheduleInterval);
    }
    if (!nullToAbsent || fixedMonthlyDay != null) {
      map['fixed_monthly_day'] = Variable<int>(fixedMonthlyDay);
    }
    if (!nullToAbsent || fixedRepeatRuleV2 != null) {
      map['fixed_repeat_rule_v2'] = Variable<String>(fixedRepeatRuleV2);
    }
    if (!nullToAbsent || fixedTimeOfDay != null) {
      map['fixed_time_of_day'] = Variable<String>(fixedTimeOfDay);
    }
    if (!nullToAbsent || fixedOverduePolicy != null) {
      map['fixed_overdue_policy'] = Variable<String>(fixedOverduePolicy);
    }
    if (!nullToAbsent || fixedExpectedBeforeMinutes != null) {
      map['fixed_expected_before_minutes'] = Variable<int>(
        fixedExpectedBeforeMinutes,
      );
    }
    if (!nullToAbsent || fixedWarningBeforeMinutes != null) {
      map['fixed_warning_before_minutes'] = Variable<int>(
        fixedWarningBeforeMinutes,
      );
    }
    if (!nullToAbsent || fixedDangerBeforeMinutes != null) {
      map['fixed_danger_before_minutes'] = Variable<int>(
        fixedDangerBeforeMinutes,
      );
    }
    if (!nullToAbsent || stateExpectedAfterMinutes != null) {
      map['state_expected_after_minutes'] = Variable<int>(
        stateExpectedAfterMinutes,
      );
    }
    if (!nullToAbsent || stateWarningAfterMinutes != null) {
      map['state_warning_after_minutes'] = Variable<int>(
        stateWarningAfterMinutes,
      );
    }
    if (!nullToAbsent || stateDangerAfterMinutes != null) {
      map['state_danger_after_minutes'] = Variable<int>(
        stateDangerAfterMinutes,
      );
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PackTemplateItemsCompanion toCompanion(bool nullToAbsent) {
    return PackTemplateItemsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      orderIndex: Value(orderIndex),
      title: Value(title),
      type: Value(type),
      attentionPolicySource: Value(attentionPolicySource),
      fixedScheduleType: fixedScheduleType == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedScheduleType),
      fixedScheduleInterval: fixedScheduleInterval == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedScheduleInterval),
      fixedMonthlyDay: fixedMonthlyDay == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedMonthlyDay),
      fixedRepeatRuleV2: fixedRepeatRuleV2 == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedRepeatRuleV2),
      fixedTimeOfDay: fixedTimeOfDay == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedTimeOfDay),
      fixedOverduePolicy: fixedOverduePolicy == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedOverduePolicy),
      fixedExpectedBeforeMinutes:
          fixedExpectedBeforeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedExpectedBeforeMinutes),
      fixedWarningBeforeMinutes:
          fixedWarningBeforeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedWarningBeforeMinutes),
      fixedDangerBeforeMinutes: fixedDangerBeforeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedDangerBeforeMinutes),
      stateExpectedAfterMinutes:
          stateExpectedAfterMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(stateExpectedAfterMinutes),
      stateWarningAfterMinutes: stateWarningAfterMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(stateWarningAfterMinutes),
      stateDangerAfterMinutes: stateDangerAfterMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(stateDangerAfterMinutes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PackTemplateItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PackTemplateItemRow(
      id: serializer.fromJson<int>(json['id']),
      templateId: serializer.fromJson<int>(json['templateId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      attentionPolicySource: serializer.fromJson<String>(
        json['attentionPolicySource'],
      ),
      fixedScheduleType: serializer.fromJson<String?>(
        json['fixedScheduleType'],
      ),
      fixedScheduleInterval: serializer.fromJson<int?>(
        json['fixedScheduleInterval'],
      ),
      fixedMonthlyDay: serializer.fromJson<int?>(json['fixedMonthlyDay']),
      fixedRepeatRuleV2: serializer.fromJson<String?>(
        json['fixedRepeatRuleV2'],
      ),
      fixedTimeOfDay: serializer.fromJson<String?>(json['fixedTimeOfDay']),
      fixedOverduePolicy: serializer.fromJson<String?>(
        json['fixedOverduePolicy'],
      ),
      fixedExpectedBeforeMinutes: serializer.fromJson<int?>(
        json['fixedExpectedBeforeMinutes'],
      ),
      fixedWarningBeforeMinutes: serializer.fromJson<int?>(
        json['fixedWarningBeforeMinutes'],
      ),
      fixedDangerBeforeMinutes: serializer.fromJson<int?>(
        json['fixedDangerBeforeMinutes'],
      ),
      stateExpectedAfterMinutes: serializer.fromJson<int?>(
        json['stateExpectedAfterMinutes'],
      ),
      stateWarningAfterMinutes: serializer.fromJson<int?>(
        json['stateWarningAfterMinutes'],
      ),
      stateDangerAfterMinutes: serializer.fromJson<int?>(
        json['stateDangerAfterMinutes'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateId': serializer.toJson<int>(templateId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'attentionPolicySource': serializer.toJson<String>(attentionPolicySource),
      'fixedScheduleType': serializer.toJson<String?>(fixedScheduleType),
      'fixedScheduleInterval': serializer.toJson<int?>(fixedScheduleInterval),
      'fixedMonthlyDay': serializer.toJson<int?>(fixedMonthlyDay),
      'fixedRepeatRuleV2': serializer.toJson<String?>(fixedRepeatRuleV2),
      'fixedTimeOfDay': serializer.toJson<String?>(fixedTimeOfDay),
      'fixedOverduePolicy': serializer.toJson<String?>(fixedOverduePolicy),
      'fixedExpectedBeforeMinutes': serializer.toJson<int?>(
        fixedExpectedBeforeMinutes,
      ),
      'fixedWarningBeforeMinutes': serializer.toJson<int?>(
        fixedWarningBeforeMinutes,
      ),
      'fixedDangerBeforeMinutes': serializer.toJson<int?>(
        fixedDangerBeforeMinutes,
      ),
      'stateExpectedAfterMinutes': serializer.toJson<int?>(
        stateExpectedAfterMinutes,
      ),
      'stateWarningAfterMinutes': serializer.toJson<int?>(
        stateWarningAfterMinutes,
      ),
      'stateDangerAfterMinutes': serializer.toJson<int?>(
        stateDangerAfterMinutes,
      ),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  PackTemplateItemRow copyWith({
    int? id,
    int? templateId,
    int? orderIndex,
    String? title,
    String? type,
    String? attentionPolicySource,
    Value<String?> fixedScheduleType = const Value.absent(),
    Value<int?> fixedScheduleInterval = const Value.absent(),
    Value<int?> fixedMonthlyDay = const Value.absent(),
    Value<String?> fixedRepeatRuleV2 = const Value.absent(),
    Value<String?> fixedTimeOfDay = const Value.absent(),
    Value<String?> fixedOverduePolicy = const Value.absent(),
    Value<int?> fixedExpectedBeforeMinutes = const Value.absent(),
    Value<int?> fixedWarningBeforeMinutes = const Value.absent(),
    Value<int?> fixedDangerBeforeMinutes = const Value.absent(),
    Value<int?> stateExpectedAfterMinutes = const Value.absent(),
    Value<int?> stateWarningAfterMinutes = const Value.absent(),
    Value<int?> stateDangerAfterMinutes = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => PackTemplateItemRow(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    orderIndex: orderIndex ?? this.orderIndex,
    title: title ?? this.title,
    type: type ?? this.type,
    attentionPolicySource: attentionPolicySource ?? this.attentionPolicySource,
    fixedScheduleType: fixedScheduleType.present
        ? fixedScheduleType.value
        : this.fixedScheduleType,
    fixedScheduleInterval: fixedScheduleInterval.present
        ? fixedScheduleInterval.value
        : this.fixedScheduleInterval,
    fixedMonthlyDay: fixedMonthlyDay.present
        ? fixedMonthlyDay.value
        : this.fixedMonthlyDay,
    fixedRepeatRuleV2: fixedRepeatRuleV2.present
        ? fixedRepeatRuleV2.value
        : this.fixedRepeatRuleV2,
    fixedTimeOfDay: fixedTimeOfDay.present
        ? fixedTimeOfDay.value
        : this.fixedTimeOfDay,
    fixedOverduePolicy: fixedOverduePolicy.present
        ? fixedOverduePolicy.value
        : this.fixedOverduePolicy,
    fixedExpectedBeforeMinutes: fixedExpectedBeforeMinutes.present
        ? fixedExpectedBeforeMinutes.value
        : this.fixedExpectedBeforeMinutes,
    fixedWarningBeforeMinutes: fixedWarningBeforeMinutes.present
        ? fixedWarningBeforeMinutes.value
        : this.fixedWarningBeforeMinutes,
    fixedDangerBeforeMinutes: fixedDangerBeforeMinutes.present
        ? fixedDangerBeforeMinutes.value
        : this.fixedDangerBeforeMinutes,
    stateExpectedAfterMinutes: stateExpectedAfterMinutes.present
        ? stateExpectedAfterMinutes.value
        : this.stateExpectedAfterMinutes,
    stateWarningAfterMinutes: stateWarningAfterMinutes.present
        ? stateWarningAfterMinutes.value
        : this.stateWarningAfterMinutes,
    stateDangerAfterMinutes: stateDangerAfterMinutes.present
        ? stateDangerAfterMinutes.value
        : this.stateDangerAfterMinutes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PackTemplateItemRow copyWithCompanion(PackTemplateItemsCompanion data) {
    return PackTemplateItemRow(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      attentionPolicySource: data.attentionPolicySource.present
          ? data.attentionPolicySource.value
          : this.attentionPolicySource,
      fixedScheduleType: data.fixedScheduleType.present
          ? data.fixedScheduleType.value
          : this.fixedScheduleType,
      fixedScheduleInterval: data.fixedScheduleInterval.present
          ? data.fixedScheduleInterval.value
          : this.fixedScheduleInterval,
      fixedMonthlyDay: data.fixedMonthlyDay.present
          ? data.fixedMonthlyDay.value
          : this.fixedMonthlyDay,
      fixedRepeatRuleV2: data.fixedRepeatRuleV2.present
          ? data.fixedRepeatRuleV2.value
          : this.fixedRepeatRuleV2,
      fixedTimeOfDay: data.fixedTimeOfDay.present
          ? data.fixedTimeOfDay.value
          : this.fixedTimeOfDay,
      fixedOverduePolicy: data.fixedOverduePolicy.present
          ? data.fixedOverduePolicy.value
          : this.fixedOverduePolicy,
      fixedExpectedBeforeMinutes: data.fixedExpectedBeforeMinutes.present
          ? data.fixedExpectedBeforeMinutes.value
          : this.fixedExpectedBeforeMinutes,
      fixedWarningBeforeMinutes: data.fixedWarningBeforeMinutes.present
          ? data.fixedWarningBeforeMinutes.value
          : this.fixedWarningBeforeMinutes,
      fixedDangerBeforeMinutes: data.fixedDangerBeforeMinutes.present
          ? data.fixedDangerBeforeMinutes.value
          : this.fixedDangerBeforeMinutes,
      stateExpectedAfterMinutes: data.stateExpectedAfterMinutes.present
          ? data.stateExpectedAfterMinutes.value
          : this.stateExpectedAfterMinutes,
      stateWarningAfterMinutes: data.stateWarningAfterMinutes.present
          ? data.stateWarningAfterMinutes.value
          : this.stateWarningAfterMinutes,
      stateDangerAfterMinutes: data.stateDangerAfterMinutes.present
          ? data.stateDangerAfterMinutes.value
          : this.stateDangerAfterMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PackTemplateItemRow(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('attentionPolicySource: $attentionPolicySource, ')
          ..write('fixedScheduleType: $fixedScheduleType, ')
          ..write('fixedScheduleInterval: $fixedScheduleInterval, ')
          ..write('fixedMonthlyDay: $fixedMonthlyDay, ')
          ..write('fixedRepeatRuleV2: $fixedRepeatRuleV2, ')
          ..write('fixedTimeOfDay: $fixedTimeOfDay, ')
          ..write('fixedOverduePolicy: $fixedOverduePolicy, ')
          ..write('fixedExpectedBeforeMinutes: $fixedExpectedBeforeMinutes, ')
          ..write('fixedWarningBeforeMinutes: $fixedWarningBeforeMinutes, ')
          ..write('fixedDangerBeforeMinutes: $fixedDangerBeforeMinutes, ')
          ..write('stateExpectedAfterMinutes: $stateExpectedAfterMinutes, ')
          ..write('stateWarningAfterMinutes: $stateWarningAfterMinutes, ')
          ..write('stateDangerAfterMinutes: $stateDangerAfterMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    orderIndex,
    title,
    type,
    attentionPolicySource,
    fixedScheduleType,
    fixedScheduleInterval,
    fixedMonthlyDay,
    fixedRepeatRuleV2,
    fixedTimeOfDay,
    fixedOverduePolicy,
    fixedExpectedBeforeMinutes,
    fixedWarningBeforeMinutes,
    fixedDangerBeforeMinutes,
    stateExpectedAfterMinutes,
    stateWarningAfterMinutes,
    stateDangerAfterMinutes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PackTemplateItemRow &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.orderIndex == this.orderIndex &&
          other.title == this.title &&
          other.type == this.type &&
          other.attentionPolicySource == this.attentionPolicySource &&
          other.fixedScheduleType == this.fixedScheduleType &&
          other.fixedScheduleInterval == this.fixedScheduleInterval &&
          other.fixedMonthlyDay == this.fixedMonthlyDay &&
          other.fixedRepeatRuleV2 == this.fixedRepeatRuleV2 &&
          other.fixedTimeOfDay == this.fixedTimeOfDay &&
          other.fixedOverduePolicy == this.fixedOverduePolicy &&
          other.fixedExpectedBeforeMinutes == this.fixedExpectedBeforeMinutes &&
          other.fixedWarningBeforeMinutes == this.fixedWarningBeforeMinutes &&
          other.fixedDangerBeforeMinutes == this.fixedDangerBeforeMinutes &&
          other.stateExpectedAfterMinutes == this.stateExpectedAfterMinutes &&
          other.stateWarningAfterMinutes == this.stateWarningAfterMinutes &&
          other.stateDangerAfterMinutes == this.stateDangerAfterMinutes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PackTemplateItemsCompanion extends UpdateCompanion<PackTemplateItemRow> {
  final Value<int> id;
  final Value<int> templateId;
  final Value<int> orderIndex;
  final Value<String> title;
  final Value<String> type;
  final Value<String> attentionPolicySource;
  final Value<String?> fixedScheduleType;
  final Value<int?> fixedScheduleInterval;
  final Value<int?> fixedMonthlyDay;
  final Value<String?> fixedRepeatRuleV2;
  final Value<String?> fixedTimeOfDay;
  final Value<String?> fixedOverduePolicy;
  final Value<int?> fixedExpectedBeforeMinutes;
  final Value<int?> fixedWarningBeforeMinutes;
  final Value<int?> fixedDangerBeforeMinutes;
  final Value<int?> stateExpectedAfterMinutes;
  final Value<int?> stateWarningAfterMinutes;
  final Value<int?> stateDangerAfterMinutes;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const PackTemplateItemsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.attentionPolicySource = const Value.absent(),
    this.fixedScheduleType = const Value.absent(),
    this.fixedScheduleInterval = const Value.absent(),
    this.fixedMonthlyDay = const Value.absent(),
    this.fixedRepeatRuleV2 = const Value.absent(),
    this.fixedTimeOfDay = const Value.absent(),
    this.fixedOverduePolicy = const Value.absent(),
    this.fixedExpectedBeforeMinutes = const Value.absent(),
    this.fixedWarningBeforeMinutes = const Value.absent(),
    this.fixedDangerBeforeMinutes = const Value.absent(),
    this.stateExpectedAfterMinutes = const Value.absent(),
    this.stateWarningAfterMinutes = const Value.absent(),
    this.stateDangerAfterMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PackTemplateItemsCompanion.insert({
    this.id = const Value.absent(),
    required int templateId,
    this.orderIndex = const Value.absent(),
    required String title,
    required String type,
    this.attentionPolicySource = const Value.absent(),
    this.fixedScheduleType = const Value.absent(),
    this.fixedScheduleInterval = const Value.absent(),
    this.fixedMonthlyDay = const Value.absent(),
    this.fixedRepeatRuleV2 = const Value.absent(),
    this.fixedTimeOfDay = const Value.absent(),
    this.fixedOverduePolicy = const Value.absent(),
    this.fixedExpectedBeforeMinutes = const Value.absent(),
    this.fixedWarningBeforeMinutes = const Value.absent(),
    this.fixedDangerBeforeMinutes = const Value.absent(),
    this.stateExpectedAfterMinutes = const Value.absent(),
    this.stateWarningAfterMinutes = const Value.absent(),
    this.stateDangerAfterMinutes = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : templateId = Value(templateId),
       title = Value(title),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PackTemplateItemRow> custom({
    Expression<int>? id,
    Expression<int>? templateId,
    Expression<int>? orderIndex,
    Expression<String>? title,
    Expression<String>? type,
    Expression<String>? attentionPolicySource,
    Expression<String>? fixedScheduleType,
    Expression<int>? fixedScheduleInterval,
    Expression<int>? fixedMonthlyDay,
    Expression<String>? fixedRepeatRuleV2,
    Expression<String>? fixedTimeOfDay,
    Expression<String>? fixedOverduePolicy,
    Expression<int>? fixedExpectedBeforeMinutes,
    Expression<int>? fixedWarningBeforeMinutes,
    Expression<int>? fixedDangerBeforeMinutes,
    Expression<int>? stateExpectedAfterMinutes,
    Expression<int>? stateWarningAfterMinutes,
    Expression<int>? stateDangerAfterMinutes,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (attentionPolicySource != null)
        'attention_policy_source': attentionPolicySource,
      if (fixedScheduleType != null) 'fixed_schedule_type': fixedScheduleType,
      if (fixedScheduleInterval != null)
        'fixed_schedule_interval': fixedScheduleInterval,
      if (fixedMonthlyDay != null) 'fixed_monthly_day': fixedMonthlyDay,
      if (fixedRepeatRuleV2 != null) 'fixed_repeat_rule_v2': fixedRepeatRuleV2,
      if (fixedTimeOfDay != null) 'fixed_time_of_day': fixedTimeOfDay,
      if (fixedOverduePolicy != null)
        'fixed_overdue_policy': fixedOverduePolicy,
      if (fixedExpectedBeforeMinutes != null)
        'fixed_expected_before_minutes': fixedExpectedBeforeMinutes,
      if (fixedWarningBeforeMinutes != null)
        'fixed_warning_before_minutes': fixedWarningBeforeMinutes,
      if (fixedDangerBeforeMinutes != null)
        'fixed_danger_before_minutes': fixedDangerBeforeMinutes,
      if (stateExpectedAfterMinutes != null)
        'state_expected_after_minutes': stateExpectedAfterMinutes,
      if (stateWarningAfterMinutes != null)
        'state_warning_after_minutes': stateWarningAfterMinutes,
      if (stateDangerAfterMinutes != null)
        'state_danger_after_minutes': stateDangerAfterMinutes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PackTemplateItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? templateId,
    Value<int>? orderIndex,
    Value<String>? title,
    Value<String>? type,
    Value<String>? attentionPolicySource,
    Value<String?>? fixedScheduleType,
    Value<int?>? fixedScheduleInterval,
    Value<int?>? fixedMonthlyDay,
    Value<String?>? fixedRepeatRuleV2,
    Value<String?>? fixedTimeOfDay,
    Value<String?>? fixedOverduePolicy,
    Value<int?>? fixedExpectedBeforeMinutes,
    Value<int?>? fixedWarningBeforeMinutes,
    Value<int?>? fixedDangerBeforeMinutes,
    Value<int?>? stateExpectedAfterMinutes,
    Value<int?>? stateWarningAfterMinutes,
    Value<int?>? stateDangerAfterMinutes,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return PackTemplateItemsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      orderIndex: orderIndex ?? this.orderIndex,
      title: title ?? this.title,
      type: type ?? this.type,
      attentionPolicySource:
          attentionPolicySource ?? this.attentionPolicySource,
      fixedScheduleType: fixedScheduleType ?? this.fixedScheduleType,
      fixedScheduleInterval:
          fixedScheduleInterval ?? this.fixedScheduleInterval,
      fixedMonthlyDay: fixedMonthlyDay ?? this.fixedMonthlyDay,
      fixedRepeatRuleV2: fixedRepeatRuleV2 ?? this.fixedRepeatRuleV2,
      fixedTimeOfDay: fixedTimeOfDay ?? this.fixedTimeOfDay,
      fixedOverduePolicy: fixedOverduePolicy ?? this.fixedOverduePolicy,
      fixedExpectedBeforeMinutes:
          fixedExpectedBeforeMinutes ?? this.fixedExpectedBeforeMinutes,
      fixedWarningBeforeMinutes:
          fixedWarningBeforeMinutes ?? this.fixedWarningBeforeMinutes,
      fixedDangerBeforeMinutes:
          fixedDangerBeforeMinutes ?? this.fixedDangerBeforeMinutes,
      stateExpectedAfterMinutes:
          stateExpectedAfterMinutes ?? this.stateExpectedAfterMinutes,
      stateWarningAfterMinutes:
          stateWarningAfterMinutes ?? this.stateWarningAfterMinutes,
      stateDangerAfterMinutes:
          stateDangerAfterMinutes ?? this.stateDangerAfterMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (attentionPolicySource.present) {
      map['attention_policy_source'] = Variable<String>(
        attentionPolicySource.value,
      );
    }
    if (fixedScheduleType.present) {
      map['fixed_schedule_type'] = Variable<String>(fixedScheduleType.value);
    }
    if (fixedScheduleInterval.present) {
      map['fixed_schedule_interval'] = Variable<int>(
        fixedScheduleInterval.value,
      );
    }
    if (fixedMonthlyDay.present) {
      map['fixed_monthly_day'] = Variable<int>(fixedMonthlyDay.value);
    }
    if (fixedRepeatRuleV2.present) {
      map['fixed_repeat_rule_v2'] = Variable<String>(fixedRepeatRuleV2.value);
    }
    if (fixedTimeOfDay.present) {
      map['fixed_time_of_day'] = Variable<String>(fixedTimeOfDay.value);
    }
    if (fixedOverduePolicy.present) {
      map['fixed_overdue_policy'] = Variable<String>(fixedOverduePolicy.value);
    }
    if (fixedExpectedBeforeMinutes.present) {
      map['fixed_expected_before_minutes'] = Variable<int>(
        fixedExpectedBeforeMinutes.value,
      );
    }
    if (fixedWarningBeforeMinutes.present) {
      map['fixed_warning_before_minutes'] = Variable<int>(
        fixedWarningBeforeMinutes.value,
      );
    }
    if (fixedDangerBeforeMinutes.present) {
      map['fixed_danger_before_minutes'] = Variable<int>(
        fixedDangerBeforeMinutes.value,
      );
    }
    if (stateExpectedAfterMinutes.present) {
      map['state_expected_after_minutes'] = Variable<int>(
        stateExpectedAfterMinutes.value,
      );
    }
    if (stateWarningAfterMinutes.present) {
      map['state_warning_after_minutes'] = Variable<int>(
        stateWarningAfterMinutes.value,
      );
    }
    if (stateDangerAfterMinutes.present) {
      map['state_danger_after_minutes'] = Variable<int>(
        stateDangerAfterMinutes.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PackTemplateItemsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('attentionPolicySource: $attentionPolicySource, ')
          ..write('fixedScheduleType: $fixedScheduleType, ')
          ..write('fixedScheduleInterval: $fixedScheduleInterval, ')
          ..write('fixedMonthlyDay: $fixedMonthlyDay, ')
          ..write('fixedRepeatRuleV2: $fixedRepeatRuleV2, ')
          ..write('fixedTimeOfDay: $fixedTimeOfDay, ')
          ..write('fixedOverduePolicy: $fixedOverduePolicy, ')
          ..write('fixedExpectedBeforeMinutes: $fixedExpectedBeforeMinutes, ')
          ..write('fixedWarningBeforeMinutes: $fixedWarningBeforeMinutes, ')
          ..write('fixedDangerBeforeMinutes: $fixedDangerBeforeMinutes, ')
          ..write('stateExpectedAfterMinutes: $stateExpectedAfterMinutes, ')
          ..write('stateWarningAfterMinutes: $stateWarningAfterMinutes, ')
          ..write('stateDangerAfterMinutes: $stateDangerAfterMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ResourcesTable extends Resources
    with TableInfo<$ResourcesTable, ResourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _packIdMeta = const VerificationMeta('packId');
  @override
  late final GeneratedColumn<int> packId = GeneratedColumn<int>(
    'pack_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES item_packs (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeAnchorDateMeta = const VerificationMeta(
    'timeAnchorDate',
  );
  @override
  late final GeneratedColumn<int> timeAnchorDate = GeneratedColumn<int>(
    'time_anchor_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeDurationDaysMeta = const VerificationMeta(
    'timeDurationDays',
  );
  @override
  late final GeneratedColumn<int> timeDurationDays = GeneratedColumn<int>(
    'time_duration_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeExpectedBeforeDaysMeta =
      const VerificationMeta('timeExpectedBeforeDays');
  @override
  late final GeneratedColumn<int> timeExpectedBeforeDays = GeneratedColumn<int>(
    'time_expected_before_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeWarningBeforeDaysMeta =
      const VerificationMeta('timeWarningBeforeDays');
  @override
  late final GeneratedColumn<int> timeWarningBeforeDays = GeneratedColumn<int>(
    'time_warning_before_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeDangerBeforeDaysMeta =
      const VerificationMeta('timeDangerBeforeDays');
  @override
  late final GeneratedColumn<int> timeDangerBeforeDays = GeneratedColumn<int>(
    'time_danger_before_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityCurrentMeta = const VerificationMeta(
    'quantityCurrent',
  );
  @override
  late final GeneratedColumn<int> quantityCurrent = GeneratedColumn<int>(
    'quantity_current',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityUnitLabelMeta = const VerificationMeta(
    'quantityUnitLabel',
  );
  @override
  late final GeneratedColumn<String> quantityUnitLabel =
      GeneratedColumn<String>(
        'quantity_unit_label',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _quantityExpectedThresholdMeta =
      const VerificationMeta('quantityExpectedThreshold');
  @override
  late final GeneratedColumn<int> quantityExpectedThreshold =
      GeneratedColumn<int>(
        'quantity_expected_threshold',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _quantityWarningThresholdMeta =
      const VerificationMeta('quantityWarningThreshold');
  @override
  late final GeneratedColumn<int> quantityWarningThreshold =
      GeneratedColumn<int>(
        'quantity_warning_threshold',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _quantityDangerThresholdMeta =
      const VerificationMeta('quantityDangerThreshold');
  @override
  late final GeneratedColumn<int> quantityDangerThreshold =
      GeneratedColumn<int>(
        'quantity_danger_threshold',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastRefilledAtMeta = const VerificationMeta(
    'lastRefilledAt',
  );
  @override
  late final GeneratedColumn<int> lastRefilledAt = GeneratedColumn<int>(
    'last_refilled_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    packId,
    title,
    description,
    status,
    type,
    timeAnchorDate,
    timeDurationDays,
    timeExpectedBeforeDays,
    timeWarningBeforeDays,
    timeDangerBeforeDays,
    quantityCurrent,
    quantityUnitLabel,
    quantityExpectedThreshold,
    quantityWarningThreshold,
    quantityDangerThreshold,
    lastRefilledAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'resources';
  @override
  VerificationContext validateIntegrity(
    Insertable<ResourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pack_id')) {
      context.handle(
        _packIdMeta,
        packId.isAcceptableOrUnknown(data['pack_id']!, _packIdMeta),
      );
    } else if (isInserting) {
      context.missing(_packIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('time_anchor_date')) {
      context.handle(
        _timeAnchorDateMeta,
        timeAnchorDate.isAcceptableOrUnknown(
          data['time_anchor_date']!,
          _timeAnchorDateMeta,
        ),
      );
    }
    if (data.containsKey('time_duration_days')) {
      context.handle(
        _timeDurationDaysMeta,
        timeDurationDays.isAcceptableOrUnknown(
          data['time_duration_days']!,
          _timeDurationDaysMeta,
        ),
      );
    }
    if (data.containsKey('time_expected_before_days')) {
      context.handle(
        _timeExpectedBeforeDaysMeta,
        timeExpectedBeforeDays.isAcceptableOrUnknown(
          data['time_expected_before_days']!,
          _timeExpectedBeforeDaysMeta,
        ),
      );
    }
    if (data.containsKey('time_warning_before_days')) {
      context.handle(
        _timeWarningBeforeDaysMeta,
        timeWarningBeforeDays.isAcceptableOrUnknown(
          data['time_warning_before_days']!,
          _timeWarningBeforeDaysMeta,
        ),
      );
    }
    if (data.containsKey('time_danger_before_days')) {
      context.handle(
        _timeDangerBeforeDaysMeta,
        timeDangerBeforeDays.isAcceptableOrUnknown(
          data['time_danger_before_days']!,
          _timeDangerBeforeDaysMeta,
        ),
      );
    }
    if (data.containsKey('quantity_current')) {
      context.handle(
        _quantityCurrentMeta,
        quantityCurrent.isAcceptableOrUnknown(
          data['quantity_current']!,
          _quantityCurrentMeta,
        ),
      );
    }
    if (data.containsKey('quantity_unit_label')) {
      context.handle(
        _quantityUnitLabelMeta,
        quantityUnitLabel.isAcceptableOrUnknown(
          data['quantity_unit_label']!,
          _quantityUnitLabelMeta,
        ),
      );
    }
    if (data.containsKey('quantity_expected_threshold')) {
      context.handle(
        _quantityExpectedThresholdMeta,
        quantityExpectedThreshold.isAcceptableOrUnknown(
          data['quantity_expected_threshold']!,
          _quantityExpectedThresholdMeta,
        ),
      );
    }
    if (data.containsKey('quantity_warning_threshold')) {
      context.handle(
        _quantityWarningThresholdMeta,
        quantityWarningThreshold.isAcceptableOrUnknown(
          data['quantity_warning_threshold']!,
          _quantityWarningThresholdMeta,
        ),
      );
    }
    if (data.containsKey('quantity_danger_threshold')) {
      context.handle(
        _quantityDangerThresholdMeta,
        quantityDangerThreshold.isAcceptableOrUnknown(
          data['quantity_danger_threshold']!,
          _quantityDangerThresholdMeta,
        ),
      );
    }
    if (data.containsKey('last_refilled_at')) {
      context.handle(
        _lastRefilledAtMeta,
        lastRefilledAt.isAcceptableOrUnknown(
          data['last_refilled_at']!,
          _lastRefilledAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ResourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResourceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      packId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pack_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      timeAnchorDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_anchor_date'],
      ),
      timeDurationDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_duration_days'],
      ),
      timeExpectedBeforeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_expected_before_days'],
      ),
      timeWarningBeforeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_warning_before_days'],
      ),
      timeDangerBeforeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_danger_before_days'],
      ),
      quantityCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_current'],
      ),
      quantityUnitLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity_unit_label'],
      ),
      quantityExpectedThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_expected_threshold'],
      ),
      quantityWarningThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_warning_threshold'],
      ),
      quantityDangerThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_danger_threshold'],
      ),
      lastRefilledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_refilled_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ResourcesTable createAlias(String alias) {
    return $ResourcesTable(attachedDatabase, alias);
  }
}

class ResourceRow extends DataClass implements Insertable<ResourceRow> {
  final int id;
  final int packId;
  final String title;
  final String? description;
  final String status;
  final String type;
  final int? timeAnchorDate;
  final int? timeDurationDays;
  final int? timeExpectedBeforeDays;
  final int? timeWarningBeforeDays;
  final int? timeDangerBeforeDays;
  final int? quantityCurrent;
  final String? quantityUnitLabel;
  final int? quantityExpectedThreshold;
  final int? quantityWarningThreshold;
  final int? quantityDangerThreshold;
  final int? lastRefilledAt;
  final int createdAt;
  final int updatedAt;
  const ResourceRow({
    required this.id,
    required this.packId,
    required this.title,
    this.description,
    required this.status,
    required this.type,
    this.timeAnchorDate,
    this.timeDurationDays,
    this.timeExpectedBeforeDays,
    this.timeWarningBeforeDays,
    this.timeDangerBeforeDays,
    this.quantityCurrent,
    this.quantityUnitLabel,
    this.quantityExpectedThreshold,
    this.quantityWarningThreshold,
    this.quantityDangerThreshold,
    this.lastRefilledAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pack_id'] = Variable<int>(packId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['status'] = Variable<String>(status);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || timeAnchorDate != null) {
      map['time_anchor_date'] = Variable<int>(timeAnchorDate);
    }
    if (!nullToAbsent || timeDurationDays != null) {
      map['time_duration_days'] = Variable<int>(timeDurationDays);
    }
    if (!nullToAbsent || timeExpectedBeforeDays != null) {
      map['time_expected_before_days'] = Variable<int>(timeExpectedBeforeDays);
    }
    if (!nullToAbsent || timeWarningBeforeDays != null) {
      map['time_warning_before_days'] = Variable<int>(timeWarningBeforeDays);
    }
    if (!nullToAbsent || timeDangerBeforeDays != null) {
      map['time_danger_before_days'] = Variable<int>(timeDangerBeforeDays);
    }
    if (!nullToAbsent || quantityCurrent != null) {
      map['quantity_current'] = Variable<int>(quantityCurrent);
    }
    if (!nullToAbsent || quantityUnitLabel != null) {
      map['quantity_unit_label'] = Variable<String>(quantityUnitLabel);
    }
    if (!nullToAbsent || quantityExpectedThreshold != null) {
      map['quantity_expected_threshold'] = Variable<int>(
        quantityExpectedThreshold,
      );
    }
    if (!nullToAbsent || quantityWarningThreshold != null) {
      map['quantity_warning_threshold'] = Variable<int>(
        quantityWarningThreshold,
      );
    }
    if (!nullToAbsent || quantityDangerThreshold != null) {
      map['quantity_danger_threshold'] = Variable<int>(quantityDangerThreshold);
    }
    if (!nullToAbsent || lastRefilledAt != null) {
      map['last_refilled_at'] = Variable<int>(lastRefilledAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ResourcesCompanion toCompanion(bool nullToAbsent) {
    return ResourcesCompanion(
      id: Value(id),
      packId: Value(packId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      status: Value(status),
      type: Value(type),
      timeAnchorDate: timeAnchorDate == null && nullToAbsent
          ? const Value.absent()
          : Value(timeAnchorDate),
      timeDurationDays: timeDurationDays == null && nullToAbsent
          ? const Value.absent()
          : Value(timeDurationDays),
      timeExpectedBeforeDays: timeExpectedBeforeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(timeExpectedBeforeDays),
      timeWarningBeforeDays: timeWarningBeforeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(timeWarningBeforeDays),
      timeDangerBeforeDays: timeDangerBeforeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(timeDangerBeforeDays),
      quantityCurrent: quantityCurrent == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityCurrent),
      quantityUnitLabel: quantityUnitLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityUnitLabel),
      quantityExpectedThreshold:
          quantityExpectedThreshold == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityExpectedThreshold),
      quantityWarningThreshold: quantityWarningThreshold == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityWarningThreshold),
      quantityDangerThreshold: quantityDangerThreshold == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityDangerThreshold),
      lastRefilledAt: lastRefilledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRefilledAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ResourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ResourceRow(
      id: serializer.fromJson<int>(json['id']),
      packId: serializer.fromJson<int>(json['packId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      type: serializer.fromJson<String>(json['type']),
      timeAnchorDate: serializer.fromJson<int?>(json['timeAnchorDate']),
      timeDurationDays: serializer.fromJson<int?>(json['timeDurationDays']),
      timeExpectedBeforeDays: serializer.fromJson<int?>(
        json['timeExpectedBeforeDays'],
      ),
      timeWarningBeforeDays: serializer.fromJson<int?>(
        json['timeWarningBeforeDays'],
      ),
      timeDangerBeforeDays: serializer.fromJson<int?>(
        json['timeDangerBeforeDays'],
      ),
      quantityCurrent: serializer.fromJson<int?>(json['quantityCurrent']),
      quantityUnitLabel: serializer.fromJson<String?>(
        json['quantityUnitLabel'],
      ),
      quantityExpectedThreshold: serializer.fromJson<int?>(
        json['quantityExpectedThreshold'],
      ),
      quantityWarningThreshold: serializer.fromJson<int?>(
        json['quantityWarningThreshold'],
      ),
      quantityDangerThreshold: serializer.fromJson<int?>(
        json['quantityDangerThreshold'],
      ),
      lastRefilledAt: serializer.fromJson<int?>(json['lastRefilledAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'packId': serializer.toJson<int>(packId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'status': serializer.toJson<String>(status),
      'type': serializer.toJson<String>(type),
      'timeAnchorDate': serializer.toJson<int?>(timeAnchorDate),
      'timeDurationDays': serializer.toJson<int?>(timeDurationDays),
      'timeExpectedBeforeDays': serializer.toJson<int?>(timeExpectedBeforeDays),
      'timeWarningBeforeDays': serializer.toJson<int?>(timeWarningBeforeDays),
      'timeDangerBeforeDays': serializer.toJson<int?>(timeDangerBeforeDays),
      'quantityCurrent': serializer.toJson<int?>(quantityCurrent),
      'quantityUnitLabel': serializer.toJson<String?>(quantityUnitLabel),
      'quantityExpectedThreshold': serializer.toJson<int?>(
        quantityExpectedThreshold,
      ),
      'quantityWarningThreshold': serializer.toJson<int?>(
        quantityWarningThreshold,
      ),
      'quantityDangerThreshold': serializer.toJson<int?>(
        quantityDangerThreshold,
      ),
      'lastRefilledAt': serializer.toJson<int?>(lastRefilledAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ResourceRow copyWith({
    int? id,
    int? packId,
    String? title,
    Value<String?> description = const Value.absent(),
    String? status,
    String? type,
    Value<int?> timeAnchorDate = const Value.absent(),
    Value<int?> timeDurationDays = const Value.absent(),
    Value<int?> timeExpectedBeforeDays = const Value.absent(),
    Value<int?> timeWarningBeforeDays = const Value.absent(),
    Value<int?> timeDangerBeforeDays = const Value.absent(),
    Value<int?> quantityCurrent = const Value.absent(),
    Value<String?> quantityUnitLabel = const Value.absent(),
    Value<int?> quantityExpectedThreshold = const Value.absent(),
    Value<int?> quantityWarningThreshold = const Value.absent(),
    Value<int?> quantityDangerThreshold = const Value.absent(),
    Value<int?> lastRefilledAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => ResourceRow(
    id: id ?? this.id,
    packId: packId ?? this.packId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    status: status ?? this.status,
    type: type ?? this.type,
    timeAnchorDate: timeAnchorDate.present
        ? timeAnchorDate.value
        : this.timeAnchorDate,
    timeDurationDays: timeDurationDays.present
        ? timeDurationDays.value
        : this.timeDurationDays,
    timeExpectedBeforeDays: timeExpectedBeforeDays.present
        ? timeExpectedBeforeDays.value
        : this.timeExpectedBeforeDays,
    timeWarningBeforeDays: timeWarningBeforeDays.present
        ? timeWarningBeforeDays.value
        : this.timeWarningBeforeDays,
    timeDangerBeforeDays: timeDangerBeforeDays.present
        ? timeDangerBeforeDays.value
        : this.timeDangerBeforeDays,
    quantityCurrent: quantityCurrent.present
        ? quantityCurrent.value
        : this.quantityCurrent,
    quantityUnitLabel: quantityUnitLabel.present
        ? quantityUnitLabel.value
        : this.quantityUnitLabel,
    quantityExpectedThreshold: quantityExpectedThreshold.present
        ? quantityExpectedThreshold.value
        : this.quantityExpectedThreshold,
    quantityWarningThreshold: quantityWarningThreshold.present
        ? quantityWarningThreshold.value
        : this.quantityWarningThreshold,
    quantityDangerThreshold: quantityDangerThreshold.present
        ? quantityDangerThreshold.value
        : this.quantityDangerThreshold,
    lastRefilledAt: lastRefilledAt.present
        ? lastRefilledAt.value
        : this.lastRefilledAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ResourceRow copyWithCompanion(ResourcesCompanion data) {
    return ResourceRow(
      id: data.id.present ? data.id.value : this.id,
      packId: data.packId.present ? data.packId.value : this.packId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
      type: data.type.present ? data.type.value : this.type,
      timeAnchorDate: data.timeAnchorDate.present
          ? data.timeAnchorDate.value
          : this.timeAnchorDate,
      timeDurationDays: data.timeDurationDays.present
          ? data.timeDurationDays.value
          : this.timeDurationDays,
      timeExpectedBeforeDays: data.timeExpectedBeforeDays.present
          ? data.timeExpectedBeforeDays.value
          : this.timeExpectedBeforeDays,
      timeWarningBeforeDays: data.timeWarningBeforeDays.present
          ? data.timeWarningBeforeDays.value
          : this.timeWarningBeforeDays,
      timeDangerBeforeDays: data.timeDangerBeforeDays.present
          ? data.timeDangerBeforeDays.value
          : this.timeDangerBeforeDays,
      quantityCurrent: data.quantityCurrent.present
          ? data.quantityCurrent.value
          : this.quantityCurrent,
      quantityUnitLabel: data.quantityUnitLabel.present
          ? data.quantityUnitLabel.value
          : this.quantityUnitLabel,
      quantityExpectedThreshold: data.quantityExpectedThreshold.present
          ? data.quantityExpectedThreshold.value
          : this.quantityExpectedThreshold,
      quantityWarningThreshold: data.quantityWarningThreshold.present
          ? data.quantityWarningThreshold.value
          : this.quantityWarningThreshold,
      quantityDangerThreshold: data.quantityDangerThreshold.present
          ? data.quantityDangerThreshold.value
          : this.quantityDangerThreshold,
      lastRefilledAt: data.lastRefilledAt.present
          ? data.lastRefilledAt.value
          : this.lastRefilledAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ResourceRow(')
          ..write('id: $id, ')
          ..write('packId: $packId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('timeAnchorDate: $timeAnchorDate, ')
          ..write('timeDurationDays: $timeDurationDays, ')
          ..write('timeExpectedBeforeDays: $timeExpectedBeforeDays, ')
          ..write('timeWarningBeforeDays: $timeWarningBeforeDays, ')
          ..write('timeDangerBeforeDays: $timeDangerBeforeDays, ')
          ..write('quantityCurrent: $quantityCurrent, ')
          ..write('quantityUnitLabel: $quantityUnitLabel, ')
          ..write('quantityExpectedThreshold: $quantityExpectedThreshold, ')
          ..write('quantityWarningThreshold: $quantityWarningThreshold, ')
          ..write('quantityDangerThreshold: $quantityDangerThreshold, ')
          ..write('lastRefilledAt: $lastRefilledAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    packId,
    title,
    description,
    status,
    type,
    timeAnchorDate,
    timeDurationDays,
    timeExpectedBeforeDays,
    timeWarningBeforeDays,
    timeDangerBeforeDays,
    quantityCurrent,
    quantityUnitLabel,
    quantityExpectedThreshold,
    quantityWarningThreshold,
    quantityDangerThreshold,
    lastRefilledAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResourceRow &&
          other.id == this.id &&
          other.packId == this.packId &&
          other.title == this.title &&
          other.description == this.description &&
          other.status == this.status &&
          other.type == this.type &&
          other.timeAnchorDate == this.timeAnchorDate &&
          other.timeDurationDays == this.timeDurationDays &&
          other.timeExpectedBeforeDays == this.timeExpectedBeforeDays &&
          other.timeWarningBeforeDays == this.timeWarningBeforeDays &&
          other.timeDangerBeforeDays == this.timeDangerBeforeDays &&
          other.quantityCurrent == this.quantityCurrent &&
          other.quantityUnitLabel == this.quantityUnitLabel &&
          other.quantityExpectedThreshold == this.quantityExpectedThreshold &&
          other.quantityWarningThreshold == this.quantityWarningThreshold &&
          other.quantityDangerThreshold == this.quantityDangerThreshold &&
          other.lastRefilledAt == this.lastRefilledAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ResourcesCompanion extends UpdateCompanion<ResourceRow> {
  final Value<int> id;
  final Value<int> packId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> status;
  final Value<String> type;
  final Value<int?> timeAnchorDate;
  final Value<int?> timeDurationDays;
  final Value<int?> timeExpectedBeforeDays;
  final Value<int?> timeWarningBeforeDays;
  final Value<int?> timeDangerBeforeDays;
  final Value<int?> quantityCurrent;
  final Value<String?> quantityUnitLabel;
  final Value<int?> quantityExpectedThreshold;
  final Value<int?> quantityWarningThreshold;
  final Value<int?> quantityDangerThreshold;
  final Value<int?> lastRefilledAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ResourcesCompanion({
    this.id = const Value.absent(),
    this.packId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.type = const Value.absent(),
    this.timeAnchorDate = const Value.absent(),
    this.timeDurationDays = const Value.absent(),
    this.timeExpectedBeforeDays = const Value.absent(),
    this.timeWarningBeforeDays = const Value.absent(),
    this.timeDangerBeforeDays = const Value.absent(),
    this.quantityCurrent = const Value.absent(),
    this.quantityUnitLabel = const Value.absent(),
    this.quantityExpectedThreshold = const Value.absent(),
    this.quantityWarningThreshold = const Value.absent(),
    this.quantityDangerThreshold = const Value.absent(),
    this.lastRefilledAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ResourcesCompanion.insert({
    this.id = const Value.absent(),
    required int packId,
    required String title,
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    required String type,
    this.timeAnchorDate = const Value.absent(),
    this.timeDurationDays = const Value.absent(),
    this.timeExpectedBeforeDays = const Value.absent(),
    this.timeWarningBeforeDays = const Value.absent(),
    this.timeDangerBeforeDays = const Value.absent(),
    this.quantityCurrent = const Value.absent(),
    this.quantityUnitLabel = const Value.absent(),
    this.quantityExpectedThreshold = const Value.absent(),
    this.quantityWarningThreshold = const Value.absent(),
    this.quantityDangerThreshold = const Value.absent(),
    this.lastRefilledAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : packId = Value(packId),
       title = Value(title),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ResourceRow> custom({
    Expression<int>? id,
    Expression<int>? packId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? status,
    Expression<String>? type,
    Expression<int>? timeAnchorDate,
    Expression<int>? timeDurationDays,
    Expression<int>? timeExpectedBeforeDays,
    Expression<int>? timeWarningBeforeDays,
    Expression<int>? timeDangerBeforeDays,
    Expression<int>? quantityCurrent,
    Expression<String>? quantityUnitLabel,
    Expression<int>? quantityExpectedThreshold,
    Expression<int>? quantityWarningThreshold,
    Expression<int>? quantityDangerThreshold,
    Expression<int>? lastRefilledAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packId != null) 'pack_id': packId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      if (timeAnchorDate != null) 'time_anchor_date': timeAnchorDate,
      if (timeDurationDays != null) 'time_duration_days': timeDurationDays,
      if (timeExpectedBeforeDays != null)
        'time_expected_before_days': timeExpectedBeforeDays,
      if (timeWarningBeforeDays != null)
        'time_warning_before_days': timeWarningBeforeDays,
      if (timeDangerBeforeDays != null)
        'time_danger_before_days': timeDangerBeforeDays,
      if (quantityCurrent != null) 'quantity_current': quantityCurrent,
      if (quantityUnitLabel != null) 'quantity_unit_label': quantityUnitLabel,
      if (quantityExpectedThreshold != null)
        'quantity_expected_threshold': quantityExpectedThreshold,
      if (quantityWarningThreshold != null)
        'quantity_warning_threshold': quantityWarningThreshold,
      if (quantityDangerThreshold != null)
        'quantity_danger_threshold': quantityDangerThreshold,
      if (lastRefilledAt != null) 'last_refilled_at': lastRefilledAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ResourcesCompanion copyWith({
    Value<int>? id,
    Value<int>? packId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? status,
    Value<String>? type,
    Value<int?>? timeAnchorDate,
    Value<int?>? timeDurationDays,
    Value<int?>? timeExpectedBeforeDays,
    Value<int?>? timeWarningBeforeDays,
    Value<int?>? timeDangerBeforeDays,
    Value<int?>? quantityCurrent,
    Value<String?>? quantityUnitLabel,
    Value<int?>? quantityExpectedThreshold,
    Value<int?>? quantityWarningThreshold,
    Value<int?>? quantityDangerThreshold,
    Value<int?>? lastRefilledAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ResourcesCompanion(
      id: id ?? this.id,
      packId: packId ?? this.packId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      type: type ?? this.type,
      timeAnchorDate: timeAnchorDate ?? this.timeAnchorDate,
      timeDurationDays: timeDurationDays ?? this.timeDurationDays,
      timeExpectedBeforeDays:
          timeExpectedBeforeDays ?? this.timeExpectedBeforeDays,
      timeWarningBeforeDays:
          timeWarningBeforeDays ?? this.timeWarningBeforeDays,
      timeDangerBeforeDays: timeDangerBeforeDays ?? this.timeDangerBeforeDays,
      quantityCurrent: quantityCurrent ?? this.quantityCurrent,
      quantityUnitLabel: quantityUnitLabel ?? this.quantityUnitLabel,
      quantityExpectedThreshold:
          quantityExpectedThreshold ?? this.quantityExpectedThreshold,
      quantityWarningThreshold:
          quantityWarningThreshold ?? this.quantityWarningThreshold,
      quantityDangerThreshold:
          quantityDangerThreshold ?? this.quantityDangerThreshold,
      lastRefilledAt: lastRefilledAt ?? this.lastRefilledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (packId.present) {
      map['pack_id'] = Variable<int>(packId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (timeAnchorDate.present) {
      map['time_anchor_date'] = Variable<int>(timeAnchorDate.value);
    }
    if (timeDurationDays.present) {
      map['time_duration_days'] = Variable<int>(timeDurationDays.value);
    }
    if (timeExpectedBeforeDays.present) {
      map['time_expected_before_days'] = Variable<int>(
        timeExpectedBeforeDays.value,
      );
    }
    if (timeWarningBeforeDays.present) {
      map['time_warning_before_days'] = Variable<int>(
        timeWarningBeforeDays.value,
      );
    }
    if (timeDangerBeforeDays.present) {
      map['time_danger_before_days'] = Variable<int>(
        timeDangerBeforeDays.value,
      );
    }
    if (quantityCurrent.present) {
      map['quantity_current'] = Variable<int>(quantityCurrent.value);
    }
    if (quantityUnitLabel.present) {
      map['quantity_unit_label'] = Variable<String>(quantityUnitLabel.value);
    }
    if (quantityExpectedThreshold.present) {
      map['quantity_expected_threshold'] = Variable<int>(
        quantityExpectedThreshold.value,
      );
    }
    if (quantityWarningThreshold.present) {
      map['quantity_warning_threshold'] = Variable<int>(
        quantityWarningThreshold.value,
      );
    }
    if (quantityDangerThreshold.present) {
      map['quantity_danger_threshold'] = Variable<int>(
        quantityDangerThreshold.value,
      );
    }
    if (lastRefilledAt.present) {
      map['last_refilled_at'] = Variable<int>(lastRefilledAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResourcesCompanion(')
          ..write('id: $id, ')
          ..write('packId: $packId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('timeAnchorDate: $timeAnchorDate, ')
          ..write('timeDurationDays: $timeDurationDays, ')
          ..write('timeExpectedBeforeDays: $timeExpectedBeforeDays, ')
          ..write('timeWarningBeforeDays: $timeWarningBeforeDays, ')
          ..write('timeDangerBeforeDays: $timeDangerBeforeDays, ')
          ..write('quantityCurrent: $quantityCurrent, ')
          ..write('quantityUnitLabel: $quantityUnitLabel, ')
          ..write('quantityExpectedThreshold: $quantityExpectedThreshold, ')
          ..write('quantityWarningThreshold: $quantityWarningThreshold, ')
          ..write('quantityDangerThreshold: $quantityDangerThreshold, ')
          ..write('lastRefilledAt: $lastRefilledAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ResourceConsumptionRulesTable extends ResourceConsumptionRules
    with TableInfo<$ResourceConsumptionRulesTable, ResourceConsumptionRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResourceConsumptionRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _resourceIdMeta = const VerificationMeta(
    'resourceId',
  );
  @override
  late final GeneratedColumn<int> resourceId = GeneratedColumn<int>(
    'resource_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES resources (id)',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _triggerActionTypeMeta = const VerificationMeta(
    'triggerActionType',
  );
  @override
  late final GeneratedColumn<String> triggerActionType =
      GeneratedColumn<String>(
        'trigger_action_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('done'),
      );
  static const VerificationMeta _consumeAmountMeta = const VerificationMeta(
    'consumeAmount',
  );
  @override
  late final GeneratedColumn<int> consumeAmount = GeneratedColumn<int>(
    'consume_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    resourceId,
    itemId,
    triggerActionType,
    consumeAmount,
    isEnabled,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'resource_consumption_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<ResourceConsumptionRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('resource_id')) {
      context.handle(
        _resourceIdMeta,
        resourceId.isAcceptableOrUnknown(data['resource_id']!, _resourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('trigger_action_type')) {
      context.handle(
        _triggerActionTypeMeta,
        triggerActionType.isAcceptableOrUnknown(
          data['trigger_action_type']!,
          _triggerActionTypeMeta,
        ),
      );
    }
    if (data.containsKey('consume_amount')) {
      context.handle(
        _consumeAmountMeta,
        consumeAmount.isAcceptableOrUnknown(
          data['consume_amount']!,
          _consumeAmountMeta,
        ),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ResourceConsumptionRuleRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResourceConsumptionRuleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      resourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resource_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      triggerActionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trigger_action_type'],
      )!,
      consumeAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consume_amount'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ResourceConsumptionRulesTable createAlias(String alias) {
    return $ResourceConsumptionRulesTable(attachedDatabase, alias);
  }
}

class ResourceConsumptionRuleRow extends DataClass
    implements Insertable<ResourceConsumptionRuleRow> {
  final int id;
  final int resourceId;
  final int itemId;
  final String triggerActionType;
  final int consumeAmount;
  final bool isEnabled;
  final int createdAt;
  final int updatedAt;
  const ResourceConsumptionRuleRow({
    required this.id,
    required this.resourceId,
    required this.itemId,
    required this.triggerActionType,
    required this.consumeAmount,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['resource_id'] = Variable<int>(resourceId);
    map['item_id'] = Variable<int>(itemId);
    map['trigger_action_type'] = Variable<String>(triggerActionType);
    map['consume_amount'] = Variable<int>(consumeAmount);
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ResourceConsumptionRulesCompanion toCompanion(bool nullToAbsent) {
    return ResourceConsumptionRulesCompanion(
      id: Value(id),
      resourceId: Value(resourceId),
      itemId: Value(itemId),
      triggerActionType: Value(triggerActionType),
      consumeAmount: Value(consumeAmount),
      isEnabled: Value(isEnabled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ResourceConsumptionRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ResourceConsumptionRuleRow(
      id: serializer.fromJson<int>(json['id']),
      resourceId: serializer.fromJson<int>(json['resourceId']),
      itemId: serializer.fromJson<int>(json['itemId']),
      triggerActionType: serializer.fromJson<String>(json['triggerActionType']),
      consumeAmount: serializer.fromJson<int>(json['consumeAmount']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'resourceId': serializer.toJson<int>(resourceId),
      'itemId': serializer.toJson<int>(itemId),
      'triggerActionType': serializer.toJson<String>(triggerActionType),
      'consumeAmount': serializer.toJson<int>(consumeAmount),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ResourceConsumptionRuleRow copyWith({
    int? id,
    int? resourceId,
    int? itemId,
    String? triggerActionType,
    int? consumeAmount,
    bool? isEnabled,
    int? createdAt,
    int? updatedAt,
  }) => ResourceConsumptionRuleRow(
    id: id ?? this.id,
    resourceId: resourceId ?? this.resourceId,
    itemId: itemId ?? this.itemId,
    triggerActionType: triggerActionType ?? this.triggerActionType,
    consumeAmount: consumeAmount ?? this.consumeAmount,
    isEnabled: isEnabled ?? this.isEnabled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ResourceConsumptionRuleRow copyWithCompanion(
    ResourceConsumptionRulesCompanion data,
  ) {
    return ResourceConsumptionRuleRow(
      id: data.id.present ? data.id.value : this.id,
      resourceId: data.resourceId.present
          ? data.resourceId.value
          : this.resourceId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      triggerActionType: data.triggerActionType.present
          ? data.triggerActionType.value
          : this.triggerActionType,
      consumeAmount: data.consumeAmount.present
          ? data.consumeAmount.value
          : this.consumeAmount,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ResourceConsumptionRuleRow(')
          ..write('id: $id, ')
          ..write('resourceId: $resourceId, ')
          ..write('itemId: $itemId, ')
          ..write('triggerActionType: $triggerActionType, ')
          ..write('consumeAmount: $consumeAmount, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    resourceId,
    itemId,
    triggerActionType,
    consumeAmount,
    isEnabled,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResourceConsumptionRuleRow &&
          other.id == this.id &&
          other.resourceId == this.resourceId &&
          other.itemId == this.itemId &&
          other.triggerActionType == this.triggerActionType &&
          other.consumeAmount == this.consumeAmount &&
          other.isEnabled == this.isEnabled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ResourceConsumptionRulesCompanion
    extends UpdateCompanion<ResourceConsumptionRuleRow> {
  final Value<int> id;
  final Value<int> resourceId;
  final Value<int> itemId;
  final Value<String> triggerActionType;
  final Value<int> consumeAmount;
  final Value<bool> isEnabled;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ResourceConsumptionRulesCompanion({
    this.id = const Value.absent(),
    this.resourceId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.triggerActionType = const Value.absent(),
    this.consumeAmount = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ResourceConsumptionRulesCompanion.insert({
    this.id = const Value.absent(),
    required int resourceId,
    required int itemId,
    this.triggerActionType = const Value.absent(),
    this.consumeAmount = const Value.absent(),
    this.isEnabled = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : resourceId = Value(resourceId),
       itemId = Value(itemId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ResourceConsumptionRuleRow> custom({
    Expression<int>? id,
    Expression<int>? resourceId,
    Expression<int>? itemId,
    Expression<String>? triggerActionType,
    Expression<int>? consumeAmount,
    Expression<bool>? isEnabled,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (resourceId != null) 'resource_id': resourceId,
      if (itemId != null) 'item_id': itemId,
      if (triggerActionType != null) 'trigger_action_type': triggerActionType,
      if (consumeAmount != null) 'consume_amount': consumeAmount,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ResourceConsumptionRulesCompanion copyWith({
    Value<int>? id,
    Value<int>? resourceId,
    Value<int>? itemId,
    Value<String>? triggerActionType,
    Value<int>? consumeAmount,
    Value<bool>? isEnabled,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ResourceConsumptionRulesCompanion(
      id: id ?? this.id,
      resourceId: resourceId ?? this.resourceId,
      itemId: itemId ?? this.itemId,
      triggerActionType: triggerActionType ?? this.triggerActionType,
      consumeAmount: consumeAmount ?? this.consumeAmount,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (resourceId.present) {
      map['resource_id'] = Variable<int>(resourceId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (triggerActionType.present) {
      map['trigger_action_type'] = Variable<String>(triggerActionType.value);
    }
    if (consumeAmount.present) {
      map['consume_amount'] = Variable<int>(consumeAmount.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResourceConsumptionRulesCompanion(')
          ..write('id: $id, ')
          ..write('resourceId: $resourceId, ')
          ..write('itemId: $itemId, ')
          ..write('triggerActionType: $triggerActionType, ')
          ..write('consumeAmount: $consumeAmount, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ItemActionRecordsTable extends ItemActionRecords
    with TableInfo<$ItemActionRecordsTable, ItemActionRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemActionRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionDateMeta = const VerificationMeta(
    'actionDate',
  );
  @override
  late final GeneratedColumn<int> actionDate = GeneratedColumn<int>(
    'action_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remarkMeta = const VerificationMeta('remark');
  @override
  late final GeneratedColumn<String> remark = GeneratedColumn<String>(
    'remark',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRevertedMeta = const VerificationMeta(
    'isReverted',
  );
  @override
  late final GeneratedColumn<bool> isReverted = GeneratedColumn<bool>(
    'is_reverted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_reverted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _revertedAtMeta = const VerificationMeta(
    'revertedAt',
  );
  @override
  late final GeneratedColumn<int> revertedAt = GeneratedColumn<int>(
    'reverted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revertedByActionRecordIdMeta =
      const VerificationMeta('revertedByActionRecordId');
  @override
  late final GeneratedColumn<int> revertedByActionRecordId =
      GeneratedColumn<int>(
        'reverted_by_action_record_id',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    actionType,
    actionDate,
    remark,
    payload,
    isReverted,
    revertedAt,
    revertedByActionRecordId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_action_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemActionRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('action_date')) {
      context.handle(
        _actionDateMeta,
        actionDate.isAcceptableOrUnknown(data['action_date']!, _actionDateMeta),
      );
    } else if (isInserting) {
      context.missing(_actionDateMeta);
    }
    if (data.containsKey('remark')) {
      context.handle(
        _remarkMeta,
        remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('is_reverted')) {
      context.handle(
        _isRevertedMeta,
        isReverted.isAcceptableOrUnknown(data['is_reverted']!, _isRevertedMeta),
      );
    }
    if (data.containsKey('reverted_at')) {
      context.handle(
        _revertedAtMeta,
        revertedAt.isAcceptableOrUnknown(data['reverted_at']!, _revertedAtMeta),
      );
    }
    if (data.containsKey('reverted_by_action_record_id')) {
      context.handle(
        _revertedByActionRecordIdMeta,
        revertedByActionRecordId.isAcceptableOrUnknown(
          data['reverted_by_action_record_id']!,
          _revertedByActionRecordIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemActionRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemActionRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      actionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}action_date'],
      )!,
      remark: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remark'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      ),
      isReverted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_reverted'],
      )!,
      revertedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reverted_at'],
      ),
      revertedByActionRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reverted_by_action_record_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ItemActionRecordsTable createAlias(String alias) {
    return $ItemActionRecordsTable(attachedDatabase, alias);
  }
}

class ItemActionRecordRow extends DataClass
    implements Insertable<ItemActionRecordRow> {
  final int id;
  final int itemId;
  final String actionType;
  final int actionDate;
  final String? remark;
  final String? payload;
  final bool isReverted;
  final int? revertedAt;
  final int? revertedByActionRecordId;
  final int createdAt;
  final int updatedAt;
  const ItemActionRecordRow({
    required this.id,
    required this.itemId,
    required this.actionType,
    required this.actionDate,
    this.remark,
    this.payload,
    required this.isReverted,
    this.revertedAt,
    this.revertedByActionRecordId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['action_type'] = Variable<String>(actionType);
    map['action_date'] = Variable<int>(actionDate);
    if (!nullToAbsent || remark != null) {
      map['remark'] = Variable<String>(remark);
    }
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    map['is_reverted'] = Variable<bool>(isReverted);
    if (!nullToAbsent || revertedAt != null) {
      map['reverted_at'] = Variable<int>(revertedAt);
    }
    if (!nullToAbsent || revertedByActionRecordId != null) {
      map['reverted_by_action_record_id'] = Variable<int>(
        revertedByActionRecordId,
      );
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ItemActionRecordsCompanion toCompanion(bool nullToAbsent) {
    return ItemActionRecordsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      actionType: Value(actionType),
      actionDate: Value(actionDate),
      remark: remark == null && nullToAbsent
          ? const Value.absent()
          : Value(remark),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      isReverted: Value(isReverted),
      revertedAt: revertedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(revertedAt),
      revertedByActionRecordId: revertedByActionRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(revertedByActionRecordId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ItemActionRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemActionRecordRow(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      actionType: serializer.fromJson<String>(json['actionType']),
      actionDate: serializer.fromJson<int>(json['actionDate']),
      remark: serializer.fromJson<String?>(json['remark']),
      payload: serializer.fromJson<String?>(json['payload']),
      isReverted: serializer.fromJson<bool>(json['isReverted']),
      revertedAt: serializer.fromJson<int?>(json['revertedAt']),
      revertedByActionRecordId: serializer.fromJson<int?>(
        json['revertedByActionRecordId'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'actionType': serializer.toJson<String>(actionType),
      'actionDate': serializer.toJson<int>(actionDate),
      'remark': serializer.toJson<String?>(remark),
      'payload': serializer.toJson<String?>(payload),
      'isReverted': serializer.toJson<bool>(isReverted),
      'revertedAt': serializer.toJson<int?>(revertedAt),
      'revertedByActionRecordId': serializer.toJson<int?>(
        revertedByActionRecordId,
      ),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ItemActionRecordRow copyWith({
    int? id,
    int? itemId,
    String? actionType,
    int? actionDate,
    Value<String?> remark = const Value.absent(),
    Value<String?> payload = const Value.absent(),
    bool? isReverted,
    Value<int?> revertedAt = const Value.absent(),
    Value<int?> revertedByActionRecordId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => ItemActionRecordRow(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    actionType: actionType ?? this.actionType,
    actionDate: actionDate ?? this.actionDate,
    remark: remark.present ? remark.value : this.remark,
    payload: payload.present ? payload.value : this.payload,
    isReverted: isReverted ?? this.isReverted,
    revertedAt: revertedAt.present ? revertedAt.value : this.revertedAt,
    revertedByActionRecordId: revertedByActionRecordId.present
        ? revertedByActionRecordId.value
        : this.revertedByActionRecordId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ItemActionRecordRow copyWithCompanion(ItemActionRecordsCompanion data) {
    return ItemActionRecordRow(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      actionDate: data.actionDate.present
          ? data.actionDate.value
          : this.actionDate,
      remark: data.remark.present ? data.remark.value : this.remark,
      payload: data.payload.present ? data.payload.value : this.payload,
      isReverted: data.isReverted.present
          ? data.isReverted.value
          : this.isReverted,
      revertedAt: data.revertedAt.present
          ? data.revertedAt.value
          : this.revertedAt,
      revertedByActionRecordId: data.revertedByActionRecordId.present
          ? data.revertedByActionRecordId.value
          : this.revertedByActionRecordId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemActionRecordRow(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('actionType: $actionType, ')
          ..write('actionDate: $actionDate, ')
          ..write('remark: $remark, ')
          ..write('payload: $payload, ')
          ..write('isReverted: $isReverted, ')
          ..write('revertedAt: $revertedAt, ')
          ..write('revertedByActionRecordId: $revertedByActionRecordId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    actionType,
    actionDate,
    remark,
    payload,
    isReverted,
    revertedAt,
    revertedByActionRecordId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemActionRecordRow &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.actionType == this.actionType &&
          other.actionDate == this.actionDate &&
          other.remark == this.remark &&
          other.payload == this.payload &&
          other.isReverted == this.isReverted &&
          other.revertedAt == this.revertedAt &&
          other.revertedByActionRecordId == this.revertedByActionRecordId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ItemActionRecordsCompanion extends UpdateCompanion<ItemActionRecordRow> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<String> actionType;
  final Value<int> actionDate;
  final Value<String?> remark;
  final Value<String?> payload;
  final Value<bool> isReverted;
  final Value<int?> revertedAt;
  final Value<int?> revertedByActionRecordId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ItemActionRecordsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.actionType = const Value.absent(),
    this.actionDate = const Value.absent(),
    this.remark = const Value.absent(),
    this.payload = const Value.absent(),
    this.isReverted = const Value.absent(),
    this.revertedAt = const Value.absent(),
    this.revertedByActionRecordId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ItemActionRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    required String actionType,
    required int actionDate,
    this.remark = const Value.absent(),
    this.payload = const Value.absent(),
    this.isReverted = const Value.absent(),
    this.revertedAt = const Value.absent(),
    this.revertedByActionRecordId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : itemId = Value(itemId),
       actionType = Value(actionType),
       actionDate = Value(actionDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ItemActionRecordRow> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<String>? actionType,
    Expression<int>? actionDate,
    Expression<String>? remark,
    Expression<String>? payload,
    Expression<bool>? isReverted,
    Expression<int>? revertedAt,
    Expression<int>? revertedByActionRecordId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (actionType != null) 'action_type': actionType,
      if (actionDate != null) 'action_date': actionDate,
      if (remark != null) 'remark': remark,
      if (payload != null) 'payload': payload,
      if (isReverted != null) 'is_reverted': isReverted,
      if (revertedAt != null) 'reverted_at': revertedAt,
      if (revertedByActionRecordId != null)
        'reverted_by_action_record_id': revertedByActionRecordId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ItemActionRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? itemId,
    Value<String>? actionType,
    Value<int>? actionDate,
    Value<String?>? remark,
    Value<String?>? payload,
    Value<bool>? isReverted,
    Value<int?>? revertedAt,
    Value<int?>? revertedByActionRecordId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ItemActionRecordsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      actionType: actionType ?? this.actionType,
      actionDate: actionDate ?? this.actionDate,
      remark: remark ?? this.remark,
      payload: payload ?? this.payload,
      isReverted: isReverted ?? this.isReverted,
      revertedAt: revertedAt ?? this.revertedAt,
      revertedByActionRecordId:
          revertedByActionRecordId ?? this.revertedByActionRecordId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (actionDate.present) {
      map['action_date'] = Variable<int>(actionDate.value);
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (isReverted.present) {
      map['is_reverted'] = Variable<bool>(isReverted.value);
    }
    if (revertedAt.present) {
      map['reverted_at'] = Variable<int>(revertedAt.value);
    }
    if (revertedByActionRecordId.present) {
      map['reverted_by_action_record_id'] = Variable<int>(
        revertedByActionRecordId.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemActionRecordsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('actionType: $actionType, ')
          ..write('actionDate: $actionDate, ')
          ..write('remark: $remark, ')
          ..write('payload: $payload, ')
          ..write('isReverted: $isReverted, ')
          ..write('revertedAt: $revertedAt, ')
          ..write('revertedByActionRecordId: $revertedByActionRecordId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ResourceActionRecordsTable extends ResourceActionRecords
    with TableInfo<$ResourceActionRecordsTable, ResourceActionRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResourceActionRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _resourceIdMeta = const VerificationMeta(
    'resourceId',
  );
  @override
  late final GeneratedColumn<int> resourceId = GeneratedColumn<int>(
    'resource_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES resources (id)',
    ),
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionDateMeta = const VerificationMeta(
    'actionDate',
  );
  @override
  late final GeneratedColumn<int> actionDate = GeneratedColumn<int>(
    'action_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resultingQuantityMeta = const VerificationMeta(
    'resultingQuantity',
  );
  @override
  late final GeneratedColumn<int> resultingQuantity = GeneratedColumn<int>(
    'resulting_quantity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedDaysMeta = const VerificationMeta(
    'addedDays',
  );
  @override
  late final GeneratedColumn<int> addedDays = GeneratedColumn<int>(
    'added_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resultingDurationDaysMeta =
      const VerificationMeta('resultingDurationDays');
  @override
  late final GeneratedColumn<int> resultingDurationDays = GeneratedColumn<int>(
    'resulting_duration_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceItemActionRecordIdMeta =
      const VerificationMeta('sourceItemActionRecordId');
  @override
  late final GeneratedColumn<int> sourceItemActionRecordId =
      GeneratedColumn<int>(
        'source_item_action_record_id',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES item_action_records (id)',
        ),
      );
  static const VerificationMeta _remarkMeta = const VerificationMeta('remark');
  @override
  late final GeneratedColumn<String> remark = GeneratedColumn<String>(
    'remark',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRevertedMeta = const VerificationMeta(
    'isReverted',
  );
  @override
  late final GeneratedColumn<bool> isReverted = GeneratedColumn<bool>(
    'is_reverted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_reverted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _revertedAtMeta = const VerificationMeta(
    'revertedAt',
  );
  @override
  late final GeneratedColumn<int> revertedAt = GeneratedColumn<int>(
    'reverted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revertedByActionRecordIdMeta =
      const VerificationMeta('revertedByActionRecordId');
  @override
  late final GeneratedColumn<int> revertedByActionRecordId =
      GeneratedColumn<int>(
        'reverted_by_action_record_id',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    resourceId,
    actionType,
    actionDate,
    amount,
    resultingQuantity,
    addedDays,
    resultingDurationDays,
    sourceItemActionRecordId,
    remark,
    isReverted,
    revertedAt,
    revertedByActionRecordId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'resource_action_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ResourceActionRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('resource_id')) {
      context.handle(
        _resourceIdMeta,
        resourceId.isAcceptableOrUnknown(data['resource_id']!, _resourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('action_date')) {
      context.handle(
        _actionDateMeta,
        actionDate.isAcceptableOrUnknown(data['action_date']!, _actionDateMeta),
      );
    } else if (isInserting) {
      context.missing(_actionDateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('resulting_quantity')) {
      context.handle(
        _resultingQuantityMeta,
        resultingQuantity.isAcceptableOrUnknown(
          data['resulting_quantity']!,
          _resultingQuantityMeta,
        ),
      );
    }
    if (data.containsKey('added_days')) {
      context.handle(
        _addedDaysMeta,
        addedDays.isAcceptableOrUnknown(data['added_days']!, _addedDaysMeta),
      );
    }
    if (data.containsKey('resulting_duration_days')) {
      context.handle(
        _resultingDurationDaysMeta,
        resultingDurationDays.isAcceptableOrUnknown(
          data['resulting_duration_days']!,
          _resultingDurationDaysMeta,
        ),
      );
    }
    if (data.containsKey('source_item_action_record_id')) {
      context.handle(
        _sourceItemActionRecordIdMeta,
        sourceItemActionRecordId.isAcceptableOrUnknown(
          data['source_item_action_record_id']!,
          _sourceItemActionRecordIdMeta,
        ),
      );
    }
    if (data.containsKey('remark')) {
      context.handle(
        _remarkMeta,
        remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta),
      );
    }
    if (data.containsKey('is_reverted')) {
      context.handle(
        _isRevertedMeta,
        isReverted.isAcceptableOrUnknown(data['is_reverted']!, _isRevertedMeta),
      );
    }
    if (data.containsKey('reverted_at')) {
      context.handle(
        _revertedAtMeta,
        revertedAt.isAcceptableOrUnknown(data['reverted_at']!, _revertedAtMeta),
      );
    }
    if (data.containsKey('reverted_by_action_record_id')) {
      context.handle(
        _revertedByActionRecordIdMeta,
        revertedByActionRecordId.isAcceptableOrUnknown(
          data['reverted_by_action_record_id']!,
          _revertedByActionRecordIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ResourceActionRecordRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResourceActionRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      resourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resource_id'],
      )!,
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      actionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}action_date'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      ),
      resultingQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resulting_quantity'],
      ),
      addedDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_days'],
      ),
      resultingDurationDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resulting_duration_days'],
      ),
      sourceItemActionRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_item_action_record_id'],
      ),
      remark: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remark'],
      ),
      isReverted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_reverted'],
      )!,
      revertedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reverted_at'],
      ),
      revertedByActionRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reverted_by_action_record_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ResourceActionRecordsTable createAlias(String alias) {
    return $ResourceActionRecordsTable(attachedDatabase, alias);
  }
}

class ResourceActionRecordRow extends DataClass
    implements Insertable<ResourceActionRecordRow> {
  final int id;
  final int resourceId;
  final String actionType;
  final int actionDate;
  final int? amount;
  final int? resultingQuantity;
  final int? addedDays;
  final int? resultingDurationDays;
  final int? sourceItemActionRecordId;
  final String? remark;
  final bool isReverted;
  final int? revertedAt;
  final int? revertedByActionRecordId;
  final int createdAt;
  final int updatedAt;
  const ResourceActionRecordRow({
    required this.id,
    required this.resourceId,
    required this.actionType,
    required this.actionDate,
    this.amount,
    this.resultingQuantity,
    this.addedDays,
    this.resultingDurationDays,
    this.sourceItemActionRecordId,
    this.remark,
    required this.isReverted,
    this.revertedAt,
    this.revertedByActionRecordId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['resource_id'] = Variable<int>(resourceId);
    map['action_type'] = Variable<String>(actionType);
    map['action_date'] = Variable<int>(actionDate);
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<int>(amount);
    }
    if (!nullToAbsent || resultingQuantity != null) {
      map['resulting_quantity'] = Variable<int>(resultingQuantity);
    }
    if (!nullToAbsent || addedDays != null) {
      map['added_days'] = Variable<int>(addedDays);
    }
    if (!nullToAbsent || resultingDurationDays != null) {
      map['resulting_duration_days'] = Variable<int>(resultingDurationDays);
    }
    if (!nullToAbsent || sourceItemActionRecordId != null) {
      map['source_item_action_record_id'] = Variable<int>(
        sourceItemActionRecordId,
      );
    }
    if (!nullToAbsent || remark != null) {
      map['remark'] = Variable<String>(remark);
    }
    map['is_reverted'] = Variable<bool>(isReverted);
    if (!nullToAbsent || revertedAt != null) {
      map['reverted_at'] = Variable<int>(revertedAt);
    }
    if (!nullToAbsent || revertedByActionRecordId != null) {
      map['reverted_by_action_record_id'] = Variable<int>(
        revertedByActionRecordId,
      );
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ResourceActionRecordsCompanion toCompanion(bool nullToAbsent) {
    return ResourceActionRecordsCompanion(
      id: Value(id),
      resourceId: Value(resourceId),
      actionType: Value(actionType),
      actionDate: Value(actionDate),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      resultingQuantity: resultingQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(resultingQuantity),
      addedDays: addedDays == null && nullToAbsent
          ? const Value.absent()
          : Value(addedDays),
      resultingDurationDays: resultingDurationDays == null && nullToAbsent
          ? const Value.absent()
          : Value(resultingDurationDays),
      sourceItemActionRecordId: sourceItemActionRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceItemActionRecordId),
      remark: remark == null && nullToAbsent
          ? const Value.absent()
          : Value(remark),
      isReverted: Value(isReverted),
      revertedAt: revertedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(revertedAt),
      revertedByActionRecordId: revertedByActionRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(revertedByActionRecordId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ResourceActionRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ResourceActionRecordRow(
      id: serializer.fromJson<int>(json['id']),
      resourceId: serializer.fromJson<int>(json['resourceId']),
      actionType: serializer.fromJson<String>(json['actionType']),
      actionDate: serializer.fromJson<int>(json['actionDate']),
      amount: serializer.fromJson<int?>(json['amount']),
      resultingQuantity: serializer.fromJson<int?>(json['resultingQuantity']),
      addedDays: serializer.fromJson<int?>(json['addedDays']),
      resultingDurationDays: serializer.fromJson<int?>(
        json['resultingDurationDays'],
      ),
      sourceItemActionRecordId: serializer.fromJson<int?>(
        json['sourceItemActionRecordId'],
      ),
      remark: serializer.fromJson<String?>(json['remark']),
      isReverted: serializer.fromJson<bool>(json['isReverted']),
      revertedAt: serializer.fromJson<int?>(json['revertedAt']),
      revertedByActionRecordId: serializer.fromJson<int?>(
        json['revertedByActionRecordId'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'resourceId': serializer.toJson<int>(resourceId),
      'actionType': serializer.toJson<String>(actionType),
      'actionDate': serializer.toJson<int>(actionDate),
      'amount': serializer.toJson<int?>(amount),
      'resultingQuantity': serializer.toJson<int?>(resultingQuantity),
      'addedDays': serializer.toJson<int?>(addedDays),
      'resultingDurationDays': serializer.toJson<int?>(resultingDurationDays),
      'sourceItemActionRecordId': serializer.toJson<int?>(
        sourceItemActionRecordId,
      ),
      'remark': serializer.toJson<String?>(remark),
      'isReverted': serializer.toJson<bool>(isReverted),
      'revertedAt': serializer.toJson<int?>(revertedAt),
      'revertedByActionRecordId': serializer.toJson<int?>(
        revertedByActionRecordId,
      ),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ResourceActionRecordRow copyWith({
    int? id,
    int? resourceId,
    String? actionType,
    int? actionDate,
    Value<int?> amount = const Value.absent(),
    Value<int?> resultingQuantity = const Value.absent(),
    Value<int?> addedDays = const Value.absent(),
    Value<int?> resultingDurationDays = const Value.absent(),
    Value<int?> sourceItemActionRecordId = const Value.absent(),
    Value<String?> remark = const Value.absent(),
    bool? isReverted,
    Value<int?> revertedAt = const Value.absent(),
    Value<int?> revertedByActionRecordId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => ResourceActionRecordRow(
    id: id ?? this.id,
    resourceId: resourceId ?? this.resourceId,
    actionType: actionType ?? this.actionType,
    actionDate: actionDate ?? this.actionDate,
    amount: amount.present ? amount.value : this.amount,
    resultingQuantity: resultingQuantity.present
        ? resultingQuantity.value
        : this.resultingQuantity,
    addedDays: addedDays.present ? addedDays.value : this.addedDays,
    resultingDurationDays: resultingDurationDays.present
        ? resultingDurationDays.value
        : this.resultingDurationDays,
    sourceItemActionRecordId: sourceItemActionRecordId.present
        ? sourceItemActionRecordId.value
        : this.sourceItemActionRecordId,
    remark: remark.present ? remark.value : this.remark,
    isReverted: isReverted ?? this.isReverted,
    revertedAt: revertedAt.present ? revertedAt.value : this.revertedAt,
    revertedByActionRecordId: revertedByActionRecordId.present
        ? revertedByActionRecordId.value
        : this.revertedByActionRecordId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ResourceActionRecordRow copyWithCompanion(
    ResourceActionRecordsCompanion data,
  ) {
    return ResourceActionRecordRow(
      id: data.id.present ? data.id.value : this.id,
      resourceId: data.resourceId.present
          ? data.resourceId.value
          : this.resourceId,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      actionDate: data.actionDate.present
          ? data.actionDate.value
          : this.actionDate,
      amount: data.amount.present ? data.amount.value : this.amount,
      resultingQuantity: data.resultingQuantity.present
          ? data.resultingQuantity.value
          : this.resultingQuantity,
      addedDays: data.addedDays.present ? data.addedDays.value : this.addedDays,
      resultingDurationDays: data.resultingDurationDays.present
          ? data.resultingDurationDays.value
          : this.resultingDurationDays,
      sourceItemActionRecordId: data.sourceItemActionRecordId.present
          ? data.sourceItemActionRecordId.value
          : this.sourceItemActionRecordId,
      remark: data.remark.present ? data.remark.value : this.remark,
      isReverted: data.isReverted.present
          ? data.isReverted.value
          : this.isReverted,
      revertedAt: data.revertedAt.present
          ? data.revertedAt.value
          : this.revertedAt,
      revertedByActionRecordId: data.revertedByActionRecordId.present
          ? data.revertedByActionRecordId.value
          : this.revertedByActionRecordId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ResourceActionRecordRow(')
          ..write('id: $id, ')
          ..write('resourceId: $resourceId, ')
          ..write('actionType: $actionType, ')
          ..write('actionDate: $actionDate, ')
          ..write('amount: $amount, ')
          ..write('resultingQuantity: $resultingQuantity, ')
          ..write('addedDays: $addedDays, ')
          ..write('resultingDurationDays: $resultingDurationDays, ')
          ..write('sourceItemActionRecordId: $sourceItemActionRecordId, ')
          ..write('remark: $remark, ')
          ..write('isReverted: $isReverted, ')
          ..write('revertedAt: $revertedAt, ')
          ..write('revertedByActionRecordId: $revertedByActionRecordId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    resourceId,
    actionType,
    actionDate,
    amount,
    resultingQuantity,
    addedDays,
    resultingDurationDays,
    sourceItemActionRecordId,
    remark,
    isReverted,
    revertedAt,
    revertedByActionRecordId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResourceActionRecordRow &&
          other.id == this.id &&
          other.resourceId == this.resourceId &&
          other.actionType == this.actionType &&
          other.actionDate == this.actionDate &&
          other.amount == this.amount &&
          other.resultingQuantity == this.resultingQuantity &&
          other.addedDays == this.addedDays &&
          other.resultingDurationDays == this.resultingDurationDays &&
          other.sourceItemActionRecordId == this.sourceItemActionRecordId &&
          other.remark == this.remark &&
          other.isReverted == this.isReverted &&
          other.revertedAt == this.revertedAt &&
          other.revertedByActionRecordId == this.revertedByActionRecordId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ResourceActionRecordsCompanion
    extends UpdateCompanion<ResourceActionRecordRow> {
  final Value<int> id;
  final Value<int> resourceId;
  final Value<String> actionType;
  final Value<int> actionDate;
  final Value<int?> amount;
  final Value<int?> resultingQuantity;
  final Value<int?> addedDays;
  final Value<int?> resultingDurationDays;
  final Value<int?> sourceItemActionRecordId;
  final Value<String?> remark;
  final Value<bool> isReverted;
  final Value<int?> revertedAt;
  final Value<int?> revertedByActionRecordId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ResourceActionRecordsCompanion({
    this.id = const Value.absent(),
    this.resourceId = const Value.absent(),
    this.actionType = const Value.absent(),
    this.actionDate = const Value.absent(),
    this.amount = const Value.absent(),
    this.resultingQuantity = const Value.absent(),
    this.addedDays = const Value.absent(),
    this.resultingDurationDays = const Value.absent(),
    this.sourceItemActionRecordId = const Value.absent(),
    this.remark = const Value.absent(),
    this.isReverted = const Value.absent(),
    this.revertedAt = const Value.absent(),
    this.revertedByActionRecordId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ResourceActionRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int resourceId,
    required String actionType,
    required int actionDate,
    this.amount = const Value.absent(),
    this.resultingQuantity = const Value.absent(),
    this.addedDays = const Value.absent(),
    this.resultingDurationDays = const Value.absent(),
    this.sourceItemActionRecordId = const Value.absent(),
    this.remark = const Value.absent(),
    this.isReverted = const Value.absent(),
    this.revertedAt = const Value.absent(),
    this.revertedByActionRecordId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : resourceId = Value(resourceId),
       actionType = Value(actionType),
       actionDate = Value(actionDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ResourceActionRecordRow> custom({
    Expression<int>? id,
    Expression<int>? resourceId,
    Expression<String>? actionType,
    Expression<int>? actionDate,
    Expression<int>? amount,
    Expression<int>? resultingQuantity,
    Expression<int>? addedDays,
    Expression<int>? resultingDurationDays,
    Expression<int>? sourceItemActionRecordId,
    Expression<String>? remark,
    Expression<bool>? isReverted,
    Expression<int>? revertedAt,
    Expression<int>? revertedByActionRecordId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (resourceId != null) 'resource_id': resourceId,
      if (actionType != null) 'action_type': actionType,
      if (actionDate != null) 'action_date': actionDate,
      if (amount != null) 'amount': amount,
      if (resultingQuantity != null) 'resulting_quantity': resultingQuantity,
      if (addedDays != null) 'added_days': addedDays,
      if (resultingDurationDays != null)
        'resulting_duration_days': resultingDurationDays,
      if (sourceItemActionRecordId != null)
        'source_item_action_record_id': sourceItemActionRecordId,
      if (remark != null) 'remark': remark,
      if (isReverted != null) 'is_reverted': isReverted,
      if (revertedAt != null) 'reverted_at': revertedAt,
      if (revertedByActionRecordId != null)
        'reverted_by_action_record_id': revertedByActionRecordId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ResourceActionRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? resourceId,
    Value<String>? actionType,
    Value<int>? actionDate,
    Value<int?>? amount,
    Value<int?>? resultingQuantity,
    Value<int?>? addedDays,
    Value<int?>? resultingDurationDays,
    Value<int?>? sourceItemActionRecordId,
    Value<String?>? remark,
    Value<bool>? isReverted,
    Value<int?>? revertedAt,
    Value<int?>? revertedByActionRecordId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ResourceActionRecordsCompanion(
      id: id ?? this.id,
      resourceId: resourceId ?? this.resourceId,
      actionType: actionType ?? this.actionType,
      actionDate: actionDate ?? this.actionDate,
      amount: amount ?? this.amount,
      resultingQuantity: resultingQuantity ?? this.resultingQuantity,
      addedDays: addedDays ?? this.addedDays,
      resultingDurationDays:
          resultingDurationDays ?? this.resultingDurationDays,
      sourceItemActionRecordId:
          sourceItemActionRecordId ?? this.sourceItemActionRecordId,
      remark: remark ?? this.remark,
      isReverted: isReverted ?? this.isReverted,
      revertedAt: revertedAt ?? this.revertedAt,
      revertedByActionRecordId:
          revertedByActionRecordId ?? this.revertedByActionRecordId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (resourceId.present) {
      map['resource_id'] = Variable<int>(resourceId.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (actionDate.present) {
      map['action_date'] = Variable<int>(actionDate.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (resultingQuantity.present) {
      map['resulting_quantity'] = Variable<int>(resultingQuantity.value);
    }
    if (addedDays.present) {
      map['added_days'] = Variable<int>(addedDays.value);
    }
    if (resultingDurationDays.present) {
      map['resulting_duration_days'] = Variable<int>(
        resultingDurationDays.value,
      );
    }
    if (sourceItemActionRecordId.present) {
      map['source_item_action_record_id'] = Variable<int>(
        sourceItemActionRecordId.value,
      );
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    if (isReverted.present) {
      map['is_reverted'] = Variable<bool>(isReverted.value);
    }
    if (revertedAt.present) {
      map['reverted_at'] = Variable<int>(revertedAt.value);
    }
    if (revertedByActionRecordId.present) {
      map['reverted_by_action_record_id'] = Variable<int>(
        revertedByActionRecordId.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResourceActionRecordsCompanion(')
          ..write('id: $id, ')
          ..write('resourceId: $resourceId, ')
          ..write('actionType: $actionType, ')
          ..write('actionDate: $actionDate, ')
          ..write('amount: $amount, ')
          ..write('resultingQuantity: $resultingQuantity, ')
          ..write('addedDays: $addedDays, ')
          ..write('resultingDurationDays: $resultingDurationDays, ')
          ..write('sourceItemActionRecordId: $sourceItemActionRecordId, ')
          ..write('remark: $remark, ')
          ..write('isReverted: $isReverted, ')
          ..write('revertedAt: $revertedAt, ')
          ..write('revertedByActionRecordId: $revertedByActionRecordId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StageTrackersTable extends StageTrackers
    with TableInfo<$StageTrackersTable, StageTrackerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StageTrackersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _packIdMeta = const VerificationMeta('packId');
  @override
  late final GeneratedColumn<int> packId = GeneratedColumn<int>(
    'pack_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES item_packs (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectNameMeta = const VerificationMeta(
    'subjectName',
  );
  @override
  late final GeneratedColumn<String> subjectName = GeneratedColumn<String>(
    'subject_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackingStartDateMeta = const VerificationMeta(
    'trackingStartDate',
  );
  @override
  late final GeneratedColumn<int> trackingStartDate = GeneratedColumn<int>(
    'tracking_start_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackingEndDateMeta = const VerificationMeta(
    'trackingEndDate',
  );
  @override
  late final GeneratedColumn<int> trackingEndDate = GeneratedColumn<int>(
    'tracking_end_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _isSystemDefaultMeta = const VerificationMeta(
    'isSystemDefault',
  );
  @override
  late final GeneratedColumn<bool> isSystemDefault = GeneratedColumn<bool>(
    'is_system_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _systemKeyMeta = const VerificationMeta(
    'systemKey',
  );
  @override
  late final GeneratedColumn<String> systemKey = GeneratedColumn<String>(
    'system_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isHiddenMeta = const VerificationMeta(
    'isHidden',
  );
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
    'is_hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    packId,
    title,
    subjectName,
    trackingStartDate,
    trackingEndDate,
    status,
    isSystemDefault,
    systemKey,
    isHidden,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stage_trackers';
  @override
  VerificationContext validateIntegrity(
    Insertable<StageTrackerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pack_id')) {
      context.handle(
        _packIdMeta,
        packId.isAcceptableOrUnknown(data['pack_id']!, _packIdMeta),
      );
    } else if (isInserting) {
      context.missing(_packIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subject_name')) {
      context.handle(
        _subjectNameMeta,
        subjectName.isAcceptableOrUnknown(
          data['subject_name']!,
          _subjectNameMeta,
        ),
      );
    }
    if (data.containsKey('tracking_start_date')) {
      context.handle(
        _trackingStartDateMeta,
        trackingStartDate.isAcceptableOrUnknown(
          data['tracking_start_date']!,
          _trackingStartDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackingStartDateMeta);
    }
    if (data.containsKey('tracking_end_date')) {
      context.handle(
        _trackingEndDateMeta,
        trackingEndDate.isAcceptableOrUnknown(
          data['tracking_end_date']!,
          _trackingEndDateMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('is_system_default')) {
      context.handle(
        _isSystemDefaultMeta,
        isSystemDefault.isAcceptableOrUnknown(
          data['is_system_default']!,
          _isSystemDefaultMeta,
        ),
      );
    }
    if (data.containsKey('system_key')) {
      context.handle(
        _systemKeyMeta,
        systemKey.isAcceptableOrUnknown(data['system_key']!, _systemKeyMeta),
      );
    }
    if (data.containsKey('is_hidden')) {
      context.handle(
        _isHiddenMeta,
        isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {systemKey},
  ];
  @override
  StageTrackerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StageTrackerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      packId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pack_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subjectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_name'],
      ),
      trackingStartDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tracking_start_date'],
      )!,
      trackingEndDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tracking_end_date'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      isSystemDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system_default'],
      )!,
      systemKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_key'],
      ),
      isHidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StageTrackersTable createAlias(String alias) {
    return $StageTrackersTable(attachedDatabase, alias);
  }
}

class StageTrackerRow extends DataClass implements Insertable<StageTrackerRow> {
  final int id;
  final int packId;
  final String title;
  final String? subjectName;
  final int trackingStartDate;
  final int? trackingEndDate;
  final String status;
  final bool isSystemDefault;
  final String? systemKey;
  final bool isHidden;
  final int createdAt;
  final int updatedAt;
  const StageTrackerRow({
    required this.id,
    required this.packId,
    required this.title,
    this.subjectName,
    required this.trackingStartDate,
    this.trackingEndDate,
    required this.status,
    required this.isSystemDefault,
    this.systemKey,
    required this.isHidden,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pack_id'] = Variable<int>(packId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subjectName != null) {
      map['subject_name'] = Variable<String>(subjectName);
    }
    map['tracking_start_date'] = Variable<int>(trackingStartDate);
    if (!nullToAbsent || trackingEndDate != null) {
      map['tracking_end_date'] = Variable<int>(trackingEndDate);
    }
    map['status'] = Variable<String>(status);
    map['is_system_default'] = Variable<bool>(isSystemDefault);
    if (!nullToAbsent || systemKey != null) {
      map['system_key'] = Variable<String>(systemKey);
    }
    map['is_hidden'] = Variable<bool>(isHidden);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  StageTrackersCompanion toCompanion(bool nullToAbsent) {
    return StageTrackersCompanion(
      id: Value(id),
      packId: Value(packId),
      title: Value(title),
      subjectName: subjectName == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectName),
      trackingStartDate: Value(trackingStartDate),
      trackingEndDate: trackingEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(trackingEndDate),
      status: Value(status),
      isSystemDefault: Value(isSystemDefault),
      systemKey: systemKey == null && nullToAbsent
          ? const Value.absent()
          : Value(systemKey),
      isHidden: Value(isHidden),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StageTrackerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StageTrackerRow(
      id: serializer.fromJson<int>(json['id']),
      packId: serializer.fromJson<int>(json['packId']),
      title: serializer.fromJson<String>(json['title']),
      subjectName: serializer.fromJson<String?>(json['subjectName']),
      trackingStartDate: serializer.fromJson<int>(json['trackingStartDate']),
      trackingEndDate: serializer.fromJson<int?>(json['trackingEndDate']),
      status: serializer.fromJson<String>(json['status']),
      isSystemDefault: serializer.fromJson<bool>(json['isSystemDefault']),
      systemKey: serializer.fromJson<String?>(json['systemKey']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'packId': serializer.toJson<int>(packId),
      'title': serializer.toJson<String>(title),
      'subjectName': serializer.toJson<String?>(subjectName),
      'trackingStartDate': serializer.toJson<int>(trackingStartDate),
      'trackingEndDate': serializer.toJson<int?>(trackingEndDate),
      'status': serializer.toJson<String>(status),
      'isSystemDefault': serializer.toJson<bool>(isSystemDefault),
      'systemKey': serializer.toJson<String?>(systemKey),
      'isHidden': serializer.toJson<bool>(isHidden),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  StageTrackerRow copyWith({
    int? id,
    int? packId,
    String? title,
    Value<String?> subjectName = const Value.absent(),
    int? trackingStartDate,
    Value<int?> trackingEndDate = const Value.absent(),
    String? status,
    bool? isSystemDefault,
    Value<String?> systemKey = const Value.absent(),
    bool? isHidden,
    int? createdAt,
    int? updatedAt,
  }) => StageTrackerRow(
    id: id ?? this.id,
    packId: packId ?? this.packId,
    title: title ?? this.title,
    subjectName: subjectName.present ? subjectName.value : this.subjectName,
    trackingStartDate: trackingStartDate ?? this.trackingStartDate,
    trackingEndDate: trackingEndDate.present
        ? trackingEndDate.value
        : this.trackingEndDate,
    status: status ?? this.status,
    isSystemDefault: isSystemDefault ?? this.isSystemDefault,
    systemKey: systemKey.present ? systemKey.value : this.systemKey,
    isHidden: isHidden ?? this.isHidden,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StageTrackerRow copyWithCompanion(StageTrackersCompanion data) {
    return StageTrackerRow(
      id: data.id.present ? data.id.value : this.id,
      packId: data.packId.present ? data.packId.value : this.packId,
      title: data.title.present ? data.title.value : this.title,
      subjectName: data.subjectName.present
          ? data.subjectName.value
          : this.subjectName,
      trackingStartDate: data.trackingStartDate.present
          ? data.trackingStartDate.value
          : this.trackingStartDate,
      trackingEndDate: data.trackingEndDate.present
          ? data.trackingEndDate.value
          : this.trackingEndDate,
      status: data.status.present ? data.status.value : this.status,
      isSystemDefault: data.isSystemDefault.present
          ? data.isSystemDefault.value
          : this.isSystemDefault,
      systemKey: data.systemKey.present ? data.systemKey.value : this.systemKey,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StageTrackerRow(')
          ..write('id: $id, ')
          ..write('packId: $packId, ')
          ..write('title: $title, ')
          ..write('subjectName: $subjectName, ')
          ..write('trackingStartDate: $trackingStartDate, ')
          ..write('trackingEndDate: $trackingEndDate, ')
          ..write('status: $status, ')
          ..write('isSystemDefault: $isSystemDefault, ')
          ..write('systemKey: $systemKey, ')
          ..write('isHidden: $isHidden, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    packId,
    title,
    subjectName,
    trackingStartDate,
    trackingEndDate,
    status,
    isSystemDefault,
    systemKey,
    isHidden,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StageTrackerRow &&
          other.id == this.id &&
          other.packId == this.packId &&
          other.title == this.title &&
          other.subjectName == this.subjectName &&
          other.trackingStartDate == this.trackingStartDate &&
          other.trackingEndDate == this.trackingEndDate &&
          other.status == this.status &&
          other.isSystemDefault == this.isSystemDefault &&
          other.systemKey == this.systemKey &&
          other.isHidden == this.isHidden &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StageTrackersCompanion extends UpdateCompanion<StageTrackerRow> {
  final Value<int> id;
  final Value<int> packId;
  final Value<String> title;
  final Value<String?> subjectName;
  final Value<int> trackingStartDate;
  final Value<int?> trackingEndDate;
  final Value<String> status;
  final Value<bool> isSystemDefault;
  final Value<String?> systemKey;
  final Value<bool> isHidden;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const StageTrackersCompanion({
    this.id = const Value.absent(),
    this.packId = const Value.absent(),
    this.title = const Value.absent(),
    this.subjectName = const Value.absent(),
    this.trackingStartDate = const Value.absent(),
    this.trackingEndDate = const Value.absent(),
    this.status = const Value.absent(),
    this.isSystemDefault = const Value.absent(),
    this.systemKey = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  StageTrackersCompanion.insert({
    this.id = const Value.absent(),
    required int packId,
    required String title,
    this.subjectName = const Value.absent(),
    required int trackingStartDate,
    this.trackingEndDate = const Value.absent(),
    this.status = const Value.absent(),
    this.isSystemDefault = const Value.absent(),
    this.systemKey = const Value.absent(),
    this.isHidden = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : packId = Value(packId),
       title = Value(title),
       trackingStartDate = Value(trackingStartDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StageTrackerRow> custom({
    Expression<int>? id,
    Expression<int>? packId,
    Expression<String>? title,
    Expression<String>? subjectName,
    Expression<int>? trackingStartDate,
    Expression<int>? trackingEndDate,
    Expression<String>? status,
    Expression<bool>? isSystemDefault,
    Expression<String>? systemKey,
    Expression<bool>? isHidden,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packId != null) 'pack_id': packId,
      if (title != null) 'title': title,
      if (subjectName != null) 'subject_name': subjectName,
      if (trackingStartDate != null) 'tracking_start_date': trackingStartDate,
      if (trackingEndDate != null) 'tracking_end_date': trackingEndDate,
      if (status != null) 'status': status,
      if (isSystemDefault != null) 'is_system_default': isSystemDefault,
      if (systemKey != null) 'system_key': systemKey,
      if (isHidden != null) 'is_hidden': isHidden,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  StageTrackersCompanion copyWith({
    Value<int>? id,
    Value<int>? packId,
    Value<String>? title,
    Value<String?>? subjectName,
    Value<int>? trackingStartDate,
    Value<int?>? trackingEndDate,
    Value<String>? status,
    Value<bool>? isSystemDefault,
    Value<String?>? systemKey,
    Value<bool>? isHidden,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return StageTrackersCompanion(
      id: id ?? this.id,
      packId: packId ?? this.packId,
      title: title ?? this.title,
      subjectName: subjectName ?? this.subjectName,
      trackingStartDate: trackingStartDate ?? this.trackingStartDate,
      trackingEndDate: trackingEndDate ?? this.trackingEndDate,
      status: status ?? this.status,
      isSystemDefault: isSystemDefault ?? this.isSystemDefault,
      systemKey: systemKey ?? this.systemKey,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (packId.present) {
      map['pack_id'] = Variable<int>(packId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subjectName.present) {
      map['subject_name'] = Variable<String>(subjectName.value);
    }
    if (trackingStartDate.present) {
      map['tracking_start_date'] = Variable<int>(trackingStartDate.value);
    }
    if (trackingEndDate.present) {
      map['tracking_end_date'] = Variable<int>(trackingEndDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isSystemDefault.present) {
      map['is_system_default'] = Variable<bool>(isSystemDefault.value);
    }
    if (systemKey.present) {
      map['system_key'] = Variable<String>(systemKey.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StageTrackersCompanion(')
          ..write('id: $id, ')
          ..write('packId: $packId, ')
          ..write('title: $title, ')
          ..write('subjectName: $subjectName, ')
          ..write('trackingStartDate: $trackingStartDate, ')
          ..write('trackingEndDate: $trackingEndDate, ')
          ..write('status: $status, ')
          ..write('isSystemDefault: $isSystemDefault, ')
          ..write('systemKey: $systemKey, ')
          ..write('isHidden: $isHidden, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StageRulesTable extends StageRules
    with TableInfo<$StageRulesTable, StageRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StageRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _stageTrackerIdMeta = const VerificationMeta(
    'stageTrackerId',
  );
  @override
  late final GeneratedColumn<int> stageTrackerId = GeneratedColumn<int>(
    'stage_tracker_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stage_trackers (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalValueMeta = const VerificationMeta(
    'intervalValue',
  );
  @override
  late final GeneratedColumn<int> intervalValue = GeneratedColumn<int>(
    'interval_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalUnitMeta = const VerificationMeta(
    'intervalUnit',
  );
  @override
  late final GeneratedColumn<String> intervalUnit = GeneratedColumn<String>(
    'interval_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelTemplateMeta = const VerificationMeta(
    'labelTemplate',
  );
  @override
  late final GeneratedColumn<String> labelTemplate = GeneratedColumn<String>(
    'label_template',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderOffsetDaysMeta =
      const VerificationMeta('reminderOffsetDays');
  @override
  late final GeneratedColumn<int> reminderOffsetDays = GeneratedColumn<int>(
    'reminder_offset_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    stageTrackerId,
    type,
    intervalValue,
    intervalUnit,
    labelTemplate,
    reminderOffsetDays,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stage_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<StageRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('stage_tracker_id')) {
      context.handle(
        _stageTrackerIdMeta,
        stageTrackerId.isAcceptableOrUnknown(
          data['stage_tracker_id']!,
          _stageTrackerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stageTrackerIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('interval_value')) {
      context.handle(
        _intervalValueMeta,
        intervalValue.isAcceptableOrUnknown(
          data['interval_value']!,
          _intervalValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalValueMeta);
    }
    if (data.containsKey('interval_unit')) {
      context.handle(
        _intervalUnitMeta,
        intervalUnit.isAcceptableOrUnknown(
          data['interval_unit']!,
          _intervalUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalUnitMeta);
    }
    if (data.containsKey('label_template')) {
      context.handle(
        _labelTemplateMeta,
        labelTemplate.isAcceptableOrUnknown(
          data['label_template']!,
          _labelTemplateMeta,
        ),
      );
    }
    if (data.containsKey('reminder_offset_days')) {
      context.handle(
        _reminderOffsetDaysMeta,
        reminderOffsetDays.isAcceptableOrUnknown(
          data['reminder_offset_days']!,
          _reminderOffsetDaysMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StageRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StageRuleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      stageTrackerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_tracker_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      intervalValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_value'],
      )!,
      intervalUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interval_unit'],
      )!,
      labelTemplate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_template'],
      ),
      reminderOffsetDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_offset_days'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StageRulesTable createAlias(String alias) {
    return $StageRulesTable(attachedDatabase, alias);
  }
}

class StageRuleRow extends DataClass implements Insertable<StageRuleRow> {
  final int id;
  final int stageTrackerId;
  final String type;
  final int intervalValue;
  final String intervalUnit;
  final String? labelTemplate;
  final int? reminderOffsetDays;
  final String status;
  final int createdAt;
  final int updatedAt;
  const StageRuleRow({
    required this.id,
    required this.stageTrackerId,
    required this.type,
    required this.intervalValue,
    required this.intervalUnit,
    this.labelTemplate,
    this.reminderOffsetDays,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['stage_tracker_id'] = Variable<int>(stageTrackerId);
    map['type'] = Variable<String>(type);
    map['interval_value'] = Variable<int>(intervalValue);
    map['interval_unit'] = Variable<String>(intervalUnit);
    if (!nullToAbsent || labelTemplate != null) {
      map['label_template'] = Variable<String>(labelTemplate);
    }
    if (!nullToAbsent || reminderOffsetDays != null) {
      map['reminder_offset_days'] = Variable<int>(reminderOffsetDays);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  StageRulesCompanion toCompanion(bool nullToAbsent) {
    return StageRulesCompanion(
      id: Value(id),
      stageTrackerId: Value(stageTrackerId),
      type: Value(type),
      intervalValue: Value(intervalValue),
      intervalUnit: Value(intervalUnit),
      labelTemplate: labelTemplate == null && nullToAbsent
          ? const Value.absent()
          : Value(labelTemplate),
      reminderOffsetDays: reminderOffsetDays == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderOffsetDays),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StageRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StageRuleRow(
      id: serializer.fromJson<int>(json['id']),
      stageTrackerId: serializer.fromJson<int>(json['stageTrackerId']),
      type: serializer.fromJson<String>(json['type']),
      intervalValue: serializer.fromJson<int>(json['intervalValue']),
      intervalUnit: serializer.fromJson<String>(json['intervalUnit']),
      labelTemplate: serializer.fromJson<String?>(json['labelTemplate']),
      reminderOffsetDays: serializer.fromJson<int?>(json['reminderOffsetDays']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'stageTrackerId': serializer.toJson<int>(stageTrackerId),
      'type': serializer.toJson<String>(type),
      'intervalValue': serializer.toJson<int>(intervalValue),
      'intervalUnit': serializer.toJson<String>(intervalUnit),
      'labelTemplate': serializer.toJson<String?>(labelTemplate),
      'reminderOffsetDays': serializer.toJson<int?>(reminderOffsetDays),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  StageRuleRow copyWith({
    int? id,
    int? stageTrackerId,
    String? type,
    int? intervalValue,
    String? intervalUnit,
    Value<String?> labelTemplate = const Value.absent(),
    Value<int?> reminderOffsetDays = const Value.absent(),
    String? status,
    int? createdAt,
    int? updatedAt,
  }) => StageRuleRow(
    id: id ?? this.id,
    stageTrackerId: stageTrackerId ?? this.stageTrackerId,
    type: type ?? this.type,
    intervalValue: intervalValue ?? this.intervalValue,
    intervalUnit: intervalUnit ?? this.intervalUnit,
    labelTemplate: labelTemplate.present
        ? labelTemplate.value
        : this.labelTemplate,
    reminderOffsetDays: reminderOffsetDays.present
        ? reminderOffsetDays.value
        : this.reminderOffsetDays,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StageRuleRow copyWithCompanion(StageRulesCompanion data) {
    return StageRuleRow(
      id: data.id.present ? data.id.value : this.id,
      stageTrackerId: data.stageTrackerId.present
          ? data.stageTrackerId.value
          : this.stageTrackerId,
      type: data.type.present ? data.type.value : this.type,
      intervalValue: data.intervalValue.present
          ? data.intervalValue.value
          : this.intervalValue,
      intervalUnit: data.intervalUnit.present
          ? data.intervalUnit.value
          : this.intervalUnit,
      labelTemplate: data.labelTemplate.present
          ? data.labelTemplate.value
          : this.labelTemplate,
      reminderOffsetDays: data.reminderOffsetDays.present
          ? data.reminderOffsetDays.value
          : this.reminderOffsetDays,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StageRuleRow(')
          ..write('id: $id, ')
          ..write('stageTrackerId: $stageTrackerId, ')
          ..write('type: $type, ')
          ..write('intervalValue: $intervalValue, ')
          ..write('intervalUnit: $intervalUnit, ')
          ..write('labelTemplate: $labelTemplate, ')
          ..write('reminderOffsetDays: $reminderOffsetDays, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    stageTrackerId,
    type,
    intervalValue,
    intervalUnit,
    labelTemplate,
    reminderOffsetDays,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StageRuleRow &&
          other.id == this.id &&
          other.stageTrackerId == this.stageTrackerId &&
          other.type == this.type &&
          other.intervalValue == this.intervalValue &&
          other.intervalUnit == this.intervalUnit &&
          other.labelTemplate == this.labelTemplate &&
          other.reminderOffsetDays == this.reminderOffsetDays &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StageRulesCompanion extends UpdateCompanion<StageRuleRow> {
  final Value<int> id;
  final Value<int> stageTrackerId;
  final Value<String> type;
  final Value<int> intervalValue;
  final Value<String> intervalUnit;
  final Value<String?> labelTemplate;
  final Value<int?> reminderOffsetDays;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const StageRulesCompanion({
    this.id = const Value.absent(),
    this.stageTrackerId = const Value.absent(),
    this.type = const Value.absent(),
    this.intervalValue = const Value.absent(),
    this.intervalUnit = const Value.absent(),
    this.labelTemplate = const Value.absent(),
    this.reminderOffsetDays = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  StageRulesCompanion.insert({
    this.id = const Value.absent(),
    required int stageTrackerId,
    required String type,
    required int intervalValue,
    required String intervalUnit,
    this.labelTemplate = const Value.absent(),
    this.reminderOffsetDays = const Value.absent(),
    this.status = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : stageTrackerId = Value(stageTrackerId),
       type = Value(type),
       intervalValue = Value(intervalValue),
       intervalUnit = Value(intervalUnit),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StageRuleRow> custom({
    Expression<int>? id,
    Expression<int>? stageTrackerId,
    Expression<String>? type,
    Expression<int>? intervalValue,
    Expression<String>? intervalUnit,
    Expression<String>? labelTemplate,
    Expression<int>? reminderOffsetDays,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stageTrackerId != null) 'stage_tracker_id': stageTrackerId,
      if (type != null) 'type': type,
      if (intervalValue != null) 'interval_value': intervalValue,
      if (intervalUnit != null) 'interval_unit': intervalUnit,
      if (labelTemplate != null) 'label_template': labelTemplate,
      if (reminderOffsetDays != null)
        'reminder_offset_days': reminderOffsetDays,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  StageRulesCompanion copyWith({
    Value<int>? id,
    Value<int>? stageTrackerId,
    Value<String>? type,
    Value<int>? intervalValue,
    Value<String>? intervalUnit,
    Value<String?>? labelTemplate,
    Value<int?>? reminderOffsetDays,
    Value<String>? status,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return StageRulesCompanion(
      id: id ?? this.id,
      stageTrackerId: stageTrackerId ?? this.stageTrackerId,
      type: type ?? this.type,
      intervalValue: intervalValue ?? this.intervalValue,
      intervalUnit: intervalUnit ?? this.intervalUnit,
      labelTemplate: labelTemplate ?? this.labelTemplate,
      reminderOffsetDays: reminderOffsetDays ?? this.reminderOffsetDays,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (stageTrackerId.present) {
      map['stage_tracker_id'] = Variable<int>(stageTrackerId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (intervalValue.present) {
      map['interval_value'] = Variable<int>(intervalValue.value);
    }
    if (intervalUnit.present) {
      map['interval_unit'] = Variable<String>(intervalUnit.value);
    }
    if (labelTemplate.present) {
      map['label_template'] = Variable<String>(labelTemplate.value);
    }
    if (reminderOffsetDays.present) {
      map['reminder_offset_days'] = Variable<int>(reminderOffsetDays.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StageRulesCompanion(')
          ..write('id: $id, ')
          ..write('stageTrackerId: $stageTrackerId, ')
          ..write('type: $type, ')
          ..write('intervalValue: $intervalValue, ')
          ..write('intervalUnit: $intervalUnit, ')
          ..write('labelTemplate: $labelTemplate, ')
          ..write('reminderOffsetDays: $reminderOffsetDays, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StageRecordsTable extends StageRecords
    with TableInfo<$StageRecordsTable, StageRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StageRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _stageTrackerIdMeta = const VerificationMeta(
    'stageTrackerId',
  );
  @override
  late final GeneratedColumn<int> stageTrackerId = GeneratedColumn<int>(
    'stage_tracker_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stage_trackers (id)',
    ),
  );
  static const VerificationMeta _stageRuleIdMeta = const VerificationMeta(
    'stageRuleId',
  );
  @override
  late final GeneratedColumn<int> stageRuleId = GeneratedColumn<int>(
    'stage_rule_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stage_rules (id)',
    ),
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurrenceIndexMeta = const VerificationMeta(
    'occurrenceIndex',
  );
  @override
  late final GeneratedColumn<int> occurrenceIndex = GeneratedColumn<int>(
    'occurrence_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurrenceDateMeta = const VerificationMeta(
    'occurrenceDate',
  );
  @override
  late final GeneratedColumn<int> occurrenceDate = GeneratedColumn<int>(
    'occurrence_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativeAmountMeta = const VerificationMeta(
    'relativeAmount',
  );
  @override
  late final GeneratedColumn<int> relativeAmount = GeneratedColumn<int>(
    'relative_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relativeUnitMeta = const VerificationMeta(
    'relativeUnit',
  );
  @override
  late final GeneratedColumn<String> relativeUnit = GeneratedColumn<String>(
    'relative_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderOffsetDaysMeta =
      const VerificationMeta('reminderOffsetDays');
  @override
  late final GeneratedColumn<int> reminderOffsetDays = GeneratedColumn<int>(
    'reminder_offset_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    stageTrackerId,
    stageRuleId,
    sourceType,
    occurrenceIndex,
    occurrenceDate,
    relativeAmount,
    relativeUnit,
    status,
    label,
    note,
    reminderOffsetDays,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stage_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StageRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('stage_tracker_id')) {
      context.handle(
        _stageTrackerIdMeta,
        stageTrackerId.isAcceptableOrUnknown(
          data['stage_tracker_id']!,
          _stageTrackerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stageTrackerIdMeta);
    }
    if (data.containsKey('stage_rule_id')) {
      context.handle(
        _stageRuleIdMeta,
        stageRuleId.isAcceptableOrUnknown(
          data['stage_rule_id']!,
          _stageRuleIdMeta,
        ),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('occurrence_index')) {
      context.handle(
        _occurrenceIndexMeta,
        occurrenceIndex.isAcceptableOrUnknown(
          data['occurrence_index']!,
          _occurrenceIndexMeta,
        ),
      );
    }
    if (data.containsKey('occurrence_date')) {
      context.handle(
        _occurrenceDateMeta,
        occurrenceDate.isAcceptableOrUnknown(
          data['occurrence_date']!,
          _occurrenceDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceDateMeta);
    }
    if (data.containsKey('relative_amount')) {
      context.handle(
        _relativeAmountMeta,
        relativeAmount.isAcceptableOrUnknown(
          data['relative_amount']!,
          _relativeAmountMeta,
        ),
      );
    }
    if (data.containsKey('relative_unit')) {
      context.handle(
        _relativeUnitMeta,
        relativeUnit.isAcceptableOrUnknown(
          data['relative_unit']!,
          _relativeUnitMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('reminder_offset_days')) {
      context.handle(
        _reminderOffsetDaysMeta,
        reminderOffsetDays.isAcceptableOrUnknown(
          data['reminder_offset_days']!,
          _reminderOffsetDaysMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {stageTrackerId, stageRuleId, occurrenceIndex},
  ];
  @override
  StageRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StageRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      stageTrackerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_tracker_id'],
      )!,
      stageRuleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_rule_id'],
      ),
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      occurrenceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurrence_index'],
      ),
      occurrenceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurrence_date'],
      )!,
      relativeAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}relative_amount'],
      ),
      relativeUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_unit'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      reminderOffsetDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_offset_days'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StageRecordsTable createAlias(String alias) {
    return $StageRecordsTable(attachedDatabase, alias);
  }
}

class StageRecordRow extends DataClass implements Insertable<StageRecordRow> {
  final int id;
  final int stageTrackerId;
  final int? stageRuleId;
  final String sourceType;
  final int? occurrenceIndex;
  final int occurrenceDate;
  final int? relativeAmount;
  final String? relativeUnit;
  final String status;
  final String label;
  final String? note;
  final int? reminderOffsetDays;
  final int createdAt;
  final int updatedAt;
  const StageRecordRow({
    required this.id,
    required this.stageTrackerId,
    this.stageRuleId,
    required this.sourceType,
    this.occurrenceIndex,
    required this.occurrenceDate,
    this.relativeAmount,
    this.relativeUnit,
    required this.status,
    required this.label,
    this.note,
    this.reminderOffsetDays,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['stage_tracker_id'] = Variable<int>(stageTrackerId);
    if (!nullToAbsent || stageRuleId != null) {
      map['stage_rule_id'] = Variable<int>(stageRuleId);
    }
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || occurrenceIndex != null) {
      map['occurrence_index'] = Variable<int>(occurrenceIndex);
    }
    map['occurrence_date'] = Variable<int>(occurrenceDate);
    if (!nullToAbsent || relativeAmount != null) {
      map['relative_amount'] = Variable<int>(relativeAmount);
    }
    if (!nullToAbsent || relativeUnit != null) {
      map['relative_unit'] = Variable<String>(relativeUnit);
    }
    map['status'] = Variable<String>(status);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || reminderOffsetDays != null) {
      map['reminder_offset_days'] = Variable<int>(reminderOffsetDays);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  StageRecordsCompanion toCompanion(bool nullToAbsent) {
    return StageRecordsCompanion(
      id: Value(id),
      stageTrackerId: Value(stageTrackerId),
      stageRuleId: stageRuleId == null && nullToAbsent
          ? const Value.absent()
          : Value(stageRuleId),
      sourceType: Value(sourceType),
      occurrenceIndex: occurrenceIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(occurrenceIndex),
      occurrenceDate: Value(occurrenceDate),
      relativeAmount: relativeAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(relativeAmount),
      relativeUnit: relativeUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(relativeUnit),
      status: Value(status),
      label: Value(label),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      reminderOffsetDays: reminderOffsetDays == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderOffsetDays),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StageRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StageRecordRow(
      id: serializer.fromJson<int>(json['id']),
      stageTrackerId: serializer.fromJson<int>(json['stageTrackerId']),
      stageRuleId: serializer.fromJson<int?>(json['stageRuleId']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      occurrenceIndex: serializer.fromJson<int?>(json['occurrenceIndex']),
      occurrenceDate: serializer.fromJson<int>(json['occurrenceDate']),
      relativeAmount: serializer.fromJson<int?>(json['relativeAmount']),
      relativeUnit: serializer.fromJson<String?>(json['relativeUnit']),
      status: serializer.fromJson<String>(json['status']),
      label: serializer.fromJson<String>(json['label']),
      note: serializer.fromJson<String?>(json['note']),
      reminderOffsetDays: serializer.fromJson<int?>(json['reminderOffsetDays']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'stageTrackerId': serializer.toJson<int>(stageTrackerId),
      'stageRuleId': serializer.toJson<int?>(stageRuleId),
      'sourceType': serializer.toJson<String>(sourceType),
      'occurrenceIndex': serializer.toJson<int?>(occurrenceIndex),
      'occurrenceDate': serializer.toJson<int>(occurrenceDate),
      'relativeAmount': serializer.toJson<int?>(relativeAmount),
      'relativeUnit': serializer.toJson<String?>(relativeUnit),
      'status': serializer.toJson<String>(status),
      'label': serializer.toJson<String>(label),
      'note': serializer.toJson<String?>(note),
      'reminderOffsetDays': serializer.toJson<int?>(reminderOffsetDays),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  StageRecordRow copyWith({
    int? id,
    int? stageTrackerId,
    Value<int?> stageRuleId = const Value.absent(),
    String? sourceType,
    Value<int?> occurrenceIndex = const Value.absent(),
    int? occurrenceDate,
    Value<int?> relativeAmount = const Value.absent(),
    Value<String?> relativeUnit = const Value.absent(),
    String? status,
    String? label,
    Value<String?> note = const Value.absent(),
    Value<int?> reminderOffsetDays = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => StageRecordRow(
    id: id ?? this.id,
    stageTrackerId: stageTrackerId ?? this.stageTrackerId,
    stageRuleId: stageRuleId.present ? stageRuleId.value : this.stageRuleId,
    sourceType: sourceType ?? this.sourceType,
    occurrenceIndex: occurrenceIndex.present
        ? occurrenceIndex.value
        : this.occurrenceIndex,
    occurrenceDate: occurrenceDate ?? this.occurrenceDate,
    relativeAmount: relativeAmount.present
        ? relativeAmount.value
        : this.relativeAmount,
    relativeUnit: relativeUnit.present ? relativeUnit.value : this.relativeUnit,
    status: status ?? this.status,
    label: label ?? this.label,
    note: note.present ? note.value : this.note,
    reminderOffsetDays: reminderOffsetDays.present
        ? reminderOffsetDays.value
        : this.reminderOffsetDays,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StageRecordRow copyWithCompanion(StageRecordsCompanion data) {
    return StageRecordRow(
      id: data.id.present ? data.id.value : this.id,
      stageTrackerId: data.stageTrackerId.present
          ? data.stageTrackerId.value
          : this.stageTrackerId,
      stageRuleId: data.stageRuleId.present
          ? data.stageRuleId.value
          : this.stageRuleId,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      occurrenceIndex: data.occurrenceIndex.present
          ? data.occurrenceIndex.value
          : this.occurrenceIndex,
      occurrenceDate: data.occurrenceDate.present
          ? data.occurrenceDate.value
          : this.occurrenceDate,
      relativeAmount: data.relativeAmount.present
          ? data.relativeAmount.value
          : this.relativeAmount,
      relativeUnit: data.relativeUnit.present
          ? data.relativeUnit.value
          : this.relativeUnit,
      status: data.status.present ? data.status.value : this.status,
      label: data.label.present ? data.label.value : this.label,
      note: data.note.present ? data.note.value : this.note,
      reminderOffsetDays: data.reminderOffsetDays.present
          ? data.reminderOffsetDays.value
          : this.reminderOffsetDays,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StageRecordRow(')
          ..write('id: $id, ')
          ..write('stageTrackerId: $stageTrackerId, ')
          ..write('stageRuleId: $stageRuleId, ')
          ..write('sourceType: $sourceType, ')
          ..write('occurrenceIndex: $occurrenceIndex, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('relativeAmount: $relativeAmount, ')
          ..write('relativeUnit: $relativeUnit, ')
          ..write('status: $status, ')
          ..write('label: $label, ')
          ..write('note: $note, ')
          ..write('reminderOffsetDays: $reminderOffsetDays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    stageTrackerId,
    stageRuleId,
    sourceType,
    occurrenceIndex,
    occurrenceDate,
    relativeAmount,
    relativeUnit,
    status,
    label,
    note,
    reminderOffsetDays,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StageRecordRow &&
          other.id == this.id &&
          other.stageTrackerId == this.stageTrackerId &&
          other.stageRuleId == this.stageRuleId &&
          other.sourceType == this.sourceType &&
          other.occurrenceIndex == this.occurrenceIndex &&
          other.occurrenceDate == this.occurrenceDate &&
          other.relativeAmount == this.relativeAmount &&
          other.relativeUnit == this.relativeUnit &&
          other.status == this.status &&
          other.label == this.label &&
          other.note == this.note &&
          other.reminderOffsetDays == this.reminderOffsetDays &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StageRecordsCompanion extends UpdateCompanion<StageRecordRow> {
  final Value<int> id;
  final Value<int> stageTrackerId;
  final Value<int?> stageRuleId;
  final Value<String> sourceType;
  final Value<int?> occurrenceIndex;
  final Value<int> occurrenceDate;
  final Value<int?> relativeAmount;
  final Value<String?> relativeUnit;
  final Value<String> status;
  final Value<String> label;
  final Value<String?> note;
  final Value<int?> reminderOffsetDays;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const StageRecordsCompanion({
    this.id = const Value.absent(),
    this.stageTrackerId = const Value.absent(),
    this.stageRuleId = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.occurrenceIndex = const Value.absent(),
    this.occurrenceDate = const Value.absent(),
    this.relativeAmount = const Value.absent(),
    this.relativeUnit = const Value.absent(),
    this.status = const Value.absent(),
    this.label = const Value.absent(),
    this.note = const Value.absent(),
    this.reminderOffsetDays = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  StageRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int stageTrackerId,
    this.stageRuleId = const Value.absent(),
    required String sourceType,
    this.occurrenceIndex = const Value.absent(),
    required int occurrenceDate,
    this.relativeAmount = const Value.absent(),
    this.relativeUnit = const Value.absent(),
    this.status = const Value.absent(),
    required String label,
    this.note = const Value.absent(),
    this.reminderOffsetDays = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : stageTrackerId = Value(stageTrackerId),
       sourceType = Value(sourceType),
       occurrenceDate = Value(occurrenceDate),
       label = Value(label),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StageRecordRow> custom({
    Expression<int>? id,
    Expression<int>? stageTrackerId,
    Expression<int>? stageRuleId,
    Expression<String>? sourceType,
    Expression<int>? occurrenceIndex,
    Expression<int>? occurrenceDate,
    Expression<int>? relativeAmount,
    Expression<String>? relativeUnit,
    Expression<String>? status,
    Expression<String>? label,
    Expression<String>? note,
    Expression<int>? reminderOffsetDays,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stageTrackerId != null) 'stage_tracker_id': stageTrackerId,
      if (stageRuleId != null) 'stage_rule_id': stageRuleId,
      if (sourceType != null) 'source_type': sourceType,
      if (occurrenceIndex != null) 'occurrence_index': occurrenceIndex,
      if (occurrenceDate != null) 'occurrence_date': occurrenceDate,
      if (relativeAmount != null) 'relative_amount': relativeAmount,
      if (relativeUnit != null) 'relative_unit': relativeUnit,
      if (status != null) 'status': status,
      if (label != null) 'label': label,
      if (note != null) 'note': note,
      if (reminderOffsetDays != null)
        'reminder_offset_days': reminderOffsetDays,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  StageRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? stageTrackerId,
    Value<int?>? stageRuleId,
    Value<String>? sourceType,
    Value<int?>? occurrenceIndex,
    Value<int>? occurrenceDate,
    Value<int?>? relativeAmount,
    Value<String?>? relativeUnit,
    Value<String>? status,
    Value<String>? label,
    Value<String?>? note,
    Value<int?>? reminderOffsetDays,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return StageRecordsCompanion(
      id: id ?? this.id,
      stageTrackerId: stageTrackerId ?? this.stageTrackerId,
      stageRuleId: stageRuleId ?? this.stageRuleId,
      sourceType: sourceType ?? this.sourceType,
      occurrenceIndex: occurrenceIndex ?? this.occurrenceIndex,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      relativeAmount: relativeAmount ?? this.relativeAmount,
      relativeUnit: relativeUnit ?? this.relativeUnit,
      status: status ?? this.status,
      label: label ?? this.label,
      note: note ?? this.note,
      reminderOffsetDays: reminderOffsetDays ?? this.reminderOffsetDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (stageTrackerId.present) {
      map['stage_tracker_id'] = Variable<int>(stageTrackerId.value);
    }
    if (stageRuleId.present) {
      map['stage_rule_id'] = Variable<int>(stageRuleId.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (occurrenceIndex.present) {
      map['occurrence_index'] = Variable<int>(occurrenceIndex.value);
    }
    if (occurrenceDate.present) {
      map['occurrence_date'] = Variable<int>(occurrenceDate.value);
    }
    if (relativeAmount.present) {
      map['relative_amount'] = Variable<int>(relativeAmount.value);
    }
    if (relativeUnit.present) {
      map['relative_unit'] = Variable<String>(relativeUnit.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (reminderOffsetDays.present) {
      map['reminder_offset_days'] = Variable<int>(reminderOffsetDays.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StageRecordsCompanion(')
          ..write('id: $id, ')
          ..write('stageTrackerId: $stageTrackerId, ')
          ..write('stageRuleId: $stageRuleId, ')
          ..write('sourceType: $sourceType, ')
          ..write('occurrenceIndex: $occurrenceIndex, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('relativeAmount: $relativeAmount, ')
          ..write('relativeUnit: $relativeUnit, ')
          ..write('status: $status, ')
          ..write('label: $label, ')
          ..write('note: $note, ')
          ..write('reminderOffsetDays: $reminderOffsetDays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StageRelatedItemsTable extends StageRelatedItems
    with TableInfo<$StageRelatedItemsTable, StageRelatedItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StageRelatedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _stageRecordIdMeta = const VerificationMeta(
    'stageRecordId',
  );
  @override
  late final GeneratedColumn<int> stageRecordId = GeneratedColumn<int>(
    'stage_record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stage_records (id)',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    stageRecordId,
    itemId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stage_related_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<StageRelatedItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('stage_record_id')) {
      context.handle(
        _stageRecordIdMeta,
        stageRecordId.isAcceptableOrUnknown(
          data['stage_record_id']!,
          _stageRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stageRecordIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StageRelatedItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StageRelatedItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      stageRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_record_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StageRelatedItemsTable createAlias(String alias) {
    return $StageRelatedItemsTable(attachedDatabase, alias);
  }
}

class StageRelatedItemRow extends DataClass
    implements Insertable<StageRelatedItemRow> {
  final int id;
  final int stageRecordId;
  final int itemId;
  final int createdAt;
  final int updatedAt;
  const StageRelatedItemRow({
    required this.id,
    required this.stageRecordId,
    required this.itemId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['stage_record_id'] = Variable<int>(stageRecordId);
    map['item_id'] = Variable<int>(itemId);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  StageRelatedItemsCompanion toCompanion(bool nullToAbsent) {
    return StageRelatedItemsCompanion(
      id: Value(id),
      stageRecordId: Value(stageRecordId),
      itemId: Value(itemId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StageRelatedItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StageRelatedItemRow(
      id: serializer.fromJson<int>(json['id']),
      stageRecordId: serializer.fromJson<int>(json['stageRecordId']),
      itemId: serializer.fromJson<int>(json['itemId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'stageRecordId': serializer.toJson<int>(stageRecordId),
      'itemId': serializer.toJson<int>(itemId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  StageRelatedItemRow copyWith({
    int? id,
    int? stageRecordId,
    int? itemId,
    int? createdAt,
    int? updatedAt,
  }) => StageRelatedItemRow(
    id: id ?? this.id,
    stageRecordId: stageRecordId ?? this.stageRecordId,
    itemId: itemId ?? this.itemId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StageRelatedItemRow copyWithCompanion(StageRelatedItemsCompanion data) {
    return StageRelatedItemRow(
      id: data.id.present ? data.id.value : this.id,
      stageRecordId: data.stageRecordId.present
          ? data.stageRecordId.value
          : this.stageRecordId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StageRelatedItemRow(')
          ..write('id: $id, ')
          ..write('stageRecordId: $stageRecordId, ')
          ..write('itemId: $itemId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, stageRecordId, itemId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StageRelatedItemRow &&
          other.id == this.id &&
          other.stageRecordId == this.stageRecordId &&
          other.itemId == this.itemId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StageRelatedItemsCompanion extends UpdateCompanion<StageRelatedItemRow> {
  final Value<int> id;
  final Value<int> stageRecordId;
  final Value<int> itemId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const StageRelatedItemsCompanion({
    this.id = const Value.absent(),
    this.stageRecordId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  StageRelatedItemsCompanion.insert({
    this.id = const Value.absent(),
    required int stageRecordId,
    required int itemId,
    required int createdAt,
    required int updatedAt,
  }) : stageRecordId = Value(stageRecordId),
       itemId = Value(itemId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StageRelatedItemRow> custom({
    Expression<int>? id,
    Expression<int>? stageRecordId,
    Expression<int>? itemId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stageRecordId != null) 'stage_record_id': stageRecordId,
      if (itemId != null) 'item_id': itemId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  StageRelatedItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? stageRecordId,
    Value<int>? itemId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return StageRelatedItemsCompanion(
      id: id ?? this.id,
      stageRecordId: stageRecordId ?? this.stageRecordId,
      itemId: itemId ?? this.itemId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (stageRecordId.present) {
      map['stage_record_id'] = Variable<int>(stageRecordId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StageRelatedItemsCompanion(')
          ..write('id: $id, ')
          ..write('stageRecordId: $stageRecordId, ')
          ..write('itemId: $itemId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsEntriesTable extends AppSettingsEntries
    with TableInfo<$AppSettingsEntriesTable, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _reminderToneMeta = const VerificationMeta(
    'reminderTone',
  );
  @override
  late final GeneratedColumn<String> reminderTone = GeneratedColumn<String>(
    'reminder_tone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('standard'),
  );
  static const VerificationMeta _notificationReminderTimeMeta =
      const VerificationMeta('notificationReminderTime');
  @override
  late final GeneratedColumn<String> notificationReminderTime =
      GeneratedColumn<String>(
        'notification_reminder_time',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('09:00'),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reminderTone,
    notificationReminderTime,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reminder_tone')) {
      context.handle(
        _reminderToneMeta,
        reminderTone.isAcceptableOrUnknown(
          data['reminder_tone']!,
          _reminderToneMeta,
        ),
      );
    }
    if (data.containsKey('notification_reminder_time')) {
      context.handle(
        _notificationReminderTimeMeta,
        notificationReminderTime.isAcceptableOrUnknown(
          data['notification_reminder_time']!,
          _notificationReminderTimeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reminderTone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_tone'],
      )!,
      notificationReminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notification_reminder_time'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsEntriesTable createAlias(String alias) {
    return $AppSettingsEntriesTable(attachedDatabase, alias);
  }
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final int id;
  final String reminderTone;
  final String notificationReminderTime;
  final int createdAt;
  final int updatedAt;
  const AppSettingsRow({
    required this.id,
    required this.reminderTone,
    required this.notificationReminderTime,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reminder_tone'] = Variable<String>(reminderTone);
    map['notification_reminder_time'] = Variable<String>(
      notificationReminderTime,
    );
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AppSettingsEntriesCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsEntriesCompanion(
      id: Value(id),
      reminderTone: Value(reminderTone),
      notificationReminderTime: Value(notificationReminderTime),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      reminderTone: serializer.fromJson<String>(json['reminderTone']),
      notificationReminderTime: serializer.fromJson<String>(
        json['notificationReminderTime'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reminderTone': serializer.toJson<String>(reminderTone),
      'notificationReminderTime': serializer.toJson<String>(
        notificationReminderTime,
      ),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AppSettingsRow copyWith({
    int? id,
    String? reminderTone,
    String? notificationReminderTime,
    int? createdAt,
    int? updatedAt,
  }) => AppSettingsRow(
    id: id ?? this.id,
    reminderTone: reminderTone ?? this.reminderTone,
    notificationReminderTime:
        notificationReminderTime ?? this.notificationReminderTime,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSettingsRow copyWithCompanion(AppSettingsEntriesCompanion data) {
    return AppSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      reminderTone: data.reminderTone.present
          ? data.reminderTone.value
          : this.reminderTone,
      notificationReminderTime: data.notificationReminderTime.present
          ? data.notificationReminderTime.value
          : this.notificationReminderTime,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('id: $id, ')
          ..write('reminderTone: $reminderTone, ')
          ..write('notificationReminderTime: $notificationReminderTime, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    reminderTone,
    notificationReminderTime,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.id == this.id &&
          other.reminderTone == this.reminderTone &&
          other.notificationReminderTime == this.notificationReminderTime &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsEntriesCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<int> id;
  final Value<String> reminderTone;
  final Value<String> notificationReminderTime;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const AppSettingsEntriesCompanion({
    this.id = const Value.absent(),
    this.reminderTone = const Value.absent(),
    this.notificationReminderTime = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppSettingsEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.reminderTone = const Value.absent(),
    this.notificationReminderTime = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AppSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? reminderTone,
    Expression<String>? notificationReminderTime,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reminderTone != null) 'reminder_tone': reminderTone,
      if (notificationReminderTime != null)
        'notification_reminder_time': notificationReminderTime,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppSettingsEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? reminderTone,
    Value<String>? notificationReminderTime,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return AppSettingsEntriesCompanion(
      id: id ?? this.id,
      reminderTone: reminderTone ?? this.reminderTone,
      notificationReminderTime:
          notificationReminderTime ?? this.notificationReminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reminderTone.present) {
      map['reminder_tone'] = Variable<String>(reminderTone.value);
    }
    if (notificationReminderTime.present) {
      map['notification_reminder_time'] = Variable<String>(
        notificationReminderTime.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsEntriesCompanion(')
          ..write('id: $id, ')
          ..write('reminderTone: $reminderTone, ')
          ..write('notificationReminderTime: $notificationReminderTime, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ItemPacksTable itemPacks = $ItemPacksTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $PackTemplatesTable packTemplates = $PackTemplatesTable(this);
  late final $PackTemplateItemsTable packTemplateItems =
      $PackTemplateItemsTable(this);
  late final $ResourcesTable resources = $ResourcesTable(this);
  late final $ResourceConsumptionRulesTable resourceConsumptionRules =
      $ResourceConsumptionRulesTable(this);
  late final $ItemActionRecordsTable itemActionRecords =
      $ItemActionRecordsTable(this);
  late final $ResourceActionRecordsTable resourceActionRecords =
      $ResourceActionRecordsTable(this);
  late final $StageTrackersTable stageTrackers = $StageTrackersTable(this);
  late final $StageRulesTable stageRules = $StageRulesTable(this);
  late final $StageRecordsTable stageRecords = $StageRecordsTable(this);
  late final $StageRelatedItemsTable stageRelatedItems =
      $StageRelatedItemsTable(this);
  late final $AppSettingsEntriesTable appSettingsEntries =
      $AppSettingsEntriesTable(this);
  late final ReminderDao reminderDao = ReminderDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    itemPacks,
    items,
    packTemplates,
    packTemplateItems,
    resources,
    resourceConsumptionRules,
    itemActionRecords,
    resourceActionRecords,
    stageTrackers,
    stageRules,
    stageRecords,
    stageRelatedItems,
    appSettingsEntries,
  ];
}

typedef $$ItemPacksTableCreateCompanionBuilder =
    ItemPacksCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> description,
      Value<String> iconEmoji,
      Value<int> orderIndex,
      Value<String> status,
      Value<bool> isSystemDefault,
      required int createdAt,
      required int updatedAt,
    });
typedef $$ItemPacksTableUpdateCompanionBuilder =
    ItemPacksCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> description,
      Value<String> iconEmoji,
      Value<int> orderIndex,
      Value<String> status,
      Value<bool> isSystemDefault,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$ItemPacksTableReferences
    extends BaseReferences<_$AppDatabase, $ItemPacksTable, ItemPackRow> {
  $$ItemPacksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ItemsTable, List<ItemRow>> _itemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.items,
    aliasName: $_aliasNameGenerator(db.itemPacks.id, db.items.packId),
  );

  $$ItemsTableProcessedTableManager get itemsRefs {
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.packId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ResourcesTable, List<ResourceRow>>
  _resourcesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.resources,
    aliasName: $_aliasNameGenerator(db.itemPacks.id, db.resources.packId),
  );

  $$ResourcesTableProcessedTableManager get resourcesRefs {
    final manager = $$ResourcesTableTableManager(
      $_db,
      $_db.resources,
    ).filter((f) => f.packId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_resourcesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StageTrackersTable, List<StageTrackerRow>>
  _stageTrackersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stageTrackers,
    aliasName: $_aliasNameGenerator(db.itemPacks.id, db.stageTrackers.packId),
  );

  $$StageTrackersTableProcessedTableManager get stageTrackersRefs {
    final manager = $$StageTrackersTableTableManager(
      $_db,
      $_db.stageTrackers,
    ).filter((f) => f.packId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stageTrackersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemPacksTableFilterComposer
    extends Composer<_$AppDatabase, $ItemPacksTable> {
  $$ItemPacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconEmoji => $composableBuilder(
    column: $table.iconEmoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystemDefault => $composableBuilder(
    column: $table.isSystemDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> itemsRefs(
    Expression<bool> Function($$ItemsTableFilterComposer f) f,
  ) {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.packId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> resourcesRefs(
    Expression<bool> Function($$ResourcesTableFilterComposer f) f,
  ) {
    final $$ResourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.packId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourcesTableFilterComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> stageTrackersRefs(
    Expression<bool> Function($$StageTrackersTableFilterComposer f) f,
  ) {
    final $$StageTrackersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stageTrackers,
      getReferencedColumn: (t) => t.packId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageTrackersTableFilterComposer(
            $db: $db,
            $table: $db.stageTrackers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemPacksTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemPacksTable> {
  $$ItemPacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconEmoji => $composableBuilder(
    column: $table.iconEmoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystemDefault => $composableBuilder(
    column: $table.isSystemDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemPacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemPacksTable> {
  $$ItemPacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconEmoji =>
      $composableBuilder(column: $table.iconEmoji, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isSystemDefault => $composableBuilder(
    column: $table.isSystemDefault,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> itemsRefs<T extends Object>(
    Expression<T> Function($$ItemsTableAnnotationComposer a) f,
  ) {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.packId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> resourcesRefs<T extends Object>(
    Expression<T> Function($$ResourcesTableAnnotationComposer a) f,
  ) {
    final $$ResourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.packId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> stageTrackersRefs<T extends Object>(
    Expression<T> Function($$StageTrackersTableAnnotationComposer a) f,
  ) {
    final $$StageTrackersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stageTrackers,
      getReferencedColumn: (t) => t.packId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageTrackersTableAnnotationComposer(
            $db: $db,
            $table: $db.stageTrackers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemPacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemPacksTable,
          ItemPackRow,
          $$ItemPacksTableFilterComposer,
          $$ItemPacksTableOrderingComposer,
          $$ItemPacksTableAnnotationComposer,
          $$ItemPacksTableCreateCompanionBuilder,
          $$ItemPacksTableUpdateCompanionBuilder,
          (ItemPackRow, $$ItemPacksTableReferences),
          ItemPackRow,
          PrefetchHooks Function({
            bool itemsRefs,
            bool resourcesRefs,
            bool stageTrackersRefs,
          })
        > {
  $$ItemPacksTableTableManager(_$AppDatabase db, $ItemPacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemPacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemPacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemPacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> iconEmoji = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isSystemDefault = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ItemPacksCompanion(
                id: id,
                title: title,
                description: description,
                iconEmoji: iconEmoji,
                orderIndex: orderIndex,
                status: status,
                isSystemDefault: isSystemDefault,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String> iconEmoji = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isSystemDefault = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ItemPacksCompanion.insert(
                id: id,
                title: title,
                description: description,
                iconEmoji: iconEmoji,
                orderIndex: orderIndex,
                status: status,
                isSystemDefault: isSystemDefault,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ItemPacksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                itemsRefs = false,
                resourcesRefs = false,
                stageTrackersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (itemsRefs) db.items,
                    if (resourcesRefs) db.resources,
                    if (stageTrackersRefs) db.stageTrackers,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (itemsRefs)
                        await $_getPrefetchedData<
                          ItemPackRow,
                          $ItemPacksTable,
                          ItemRow
                        >(
                          currentTable: table,
                          referencedTable: $$ItemPacksTableReferences
                              ._itemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemPacksTableReferences(
                                db,
                                table,
                                p0,
                              ).itemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.packId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (resourcesRefs)
                        await $_getPrefetchedData<
                          ItemPackRow,
                          $ItemPacksTable,
                          ResourceRow
                        >(
                          currentTable: table,
                          referencedTable: $$ItemPacksTableReferences
                              ._resourcesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemPacksTableReferences(
                                db,
                                table,
                                p0,
                              ).resourcesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.packId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (stageTrackersRefs)
                        await $_getPrefetchedData<
                          ItemPackRow,
                          $ItemPacksTable,
                          StageTrackerRow
                        >(
                          currentTable: table,
                          referencedTable: $$ItemPacksTableReferences
                              ._stageTrackersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemPacksTableReferences(
                                db,
                                table,
                                p0,
                              ).stageTrackersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.packId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ItemPacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemPacksTable,
      ItemPackRow,
      $$ItemPacksTableFilterComposer,
      $$ItemPacksTableOrderingComposer,
      $$ItemPacksTableAnnotationComposer,
      $$ItemPacksTableCreateCompanionBuilder,
      $$ItemPacksTableUpdateCompanionBuilder,
      (ItemPackRow, $$ItemPacksTableReferences),
      ItemPackRow,
      PrefetchHooks Function({
        bool itemsRefs,
        bool resourcesRefs,
        bool stageTrackersRefs,
      })
    >;
typedef $$ItemsTableCreateCompanionBuilder =
    ItemsCompanion Function({
      Value<int> id,
      required int packId,
      required String title,
      Value<String?> description,
      Value<String> status,
      required String type,
      Value<String> attentionPolicySource,
      Value<String?> fixedScheduleType,
      Value<int?> fixedScheduleInterval,
      Value<int?> fixedMonthlyDay,
      Value<String?> fixedRepeatRuleV2,
      Value<int?> fixedAnchorDate,
      Value<int?> fixedDueDate,
      Value<String?> fixedTimeOfDay,
      Value<String?> fixedOverduePolicy,
      Value<int?> fixedExpectedBeforeMinutes,
      Value<int?> fixedWarningBeforeMinutes,
      Value<int?> fixedDangerBeforeMinutes,
      Value<int?> stateAnchorDate,
      Value<int?> stateExpectedAfterMinutes,
      Value<int?> stateWarningAfterMinutes,
      Value<int?> stateDangerAfterMinutes,
      Value<int?> lastDoneAt,
      required int createdAt,
      required int updatedAt,
    });
typedef $$ItemsTableUpdateCompanionBuilder =
    ItemsCompanion Function({
      Value<int> id,
      Value<int> packId,
      Value<String> title,
      Value<String?> description,
      Value<String> status,
      Value<String> type,
      Value<String> attentionPolicySource,
      Value<String?> fixedScheduleType,
      Value<int?> fixedScheduleInterval,
      Value<int?> fixedMonthlyDay,
      Value<String?> fixedRepeatRuleV2,
      Value<int?> fixedAnchorDate,
      Value<int?> fixedDueDate,
      Value<String?> fixedTimeOfDay,
      Value<String?> fixedOverduePolicy,
      Value<int?> fixedExpectedBeforeMinutes,
      Value<int?> fixedWarningBeforeMinutes,
      Value<int?> fixedDangerBeforeMinutes,
      Value<int?> stateAnchorDate,
      Value<int?> stateExpectedAfterMinutes,
      Value<int?> stateWarningAfterMinutes,
      Value<int?> stateDangerAfterMinutes,
      Value<int?> lastDoneAt,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$ItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsTable, ItemRow> {
  $$ItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemPacksTable _packIdTable(_$AppDatabase db) => db.itemPacks
      .createAlias($_aliasNameGenerator(db.items.packId, db.itemPacks.id));

  $$ItemPacksTableProcessedTableManager get packId {
    final $_column = $_itemColumn<int>('pack_id')!;

    final manager = $$ItemPacksTableTableManager(
      $_db,
      $_db.itemPacks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_packIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ResourceConsumptionRulesTable,
    List<ResourceConsumptionRuleRow>
  >
  _resourceConsumptionRulesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.resourceConsumptionRules,
        aliasName: $_aliasNameGenerator(
          db.items.id,
          db.resourceConsumptionRules.itemId,
        ),
      );

  $$ResourceConsumptionRulesTableProcessedTableManager
  get resourceConsumptionRulesRefs {
    final manager = $$ResourceConsumptionRulesTableTableManager(
      $_db,
      $_db.resourceConsumptionRules,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _resourceConsumptionRulesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ItemActionRecordsTable, List<ItemActionRecordRow>>
  _itemActionRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.itemActionRecords,
        aliasName: $_aliasNameGenerator(
          db.items.id,
          db.itemActionRecords.itemId,
        ),
      );

  $$ItemActionRecordsTableProcessedTableManager get itemActionRecordsRefs {
    final manager = $$ItemActionRecordsTableTableManager(
      $_db,
      $_db.itemActionRecords,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _itemActionRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StageRelatedItemsTable, List<StageRelatedItemRow>>
  _stageRelatedItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.stageRelatedItems,
        aliasName: $_aliasNameGenerator(
          db.items.id,
          db.stageRelatedItems.itemId,
        ),
      );

  $$StageRelatedItemsTableProcessedTableManager get stageRelatedItemsRefs {
    final manager = $$StageRelatedItemsTableTableManager(
      $_db,
      $_db.stageRelatedItems,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _stageRelatedItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attentionPolicySource => $composableBuilder(
    column: $table.attentionPolicySource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixedScheduleType => $composableBuilder(
    column: $table.fixedScheduleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fixedScheduleInterval => $composableBuilder(
    column: $table.fixedScheduleInterval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fixedMonthlyDay => $composableBuilder(
    column: $table.fixedMonthlyDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixedRepeatRuleV2 => $composableBuilder(
    column: $table.fixedRepeatRuleV2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fixedAnchorDate => $composableBuilder(
    column: $table.fixedAnchorDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fixedDueDate => $composableBuilder(
    column: $table.fixedDueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixedTimeOfDay => $composableBuilder(
    column: $table.fixedTimeOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixedOverduePolicy => $composableBuilder(
    column: $table.fixedOverduePolicy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fixedExpectedBeforeMinutes => $composableBuilder(
    column: $table.fixedExpectedBeforeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fixedWarningBeforeMinutes => $composableBuilder(
    column: $table.fixedWarningBeforeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fixedDangerBeforeMinutes => $composableBuilder(
    column: $table.fixedDangerBeforeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stateAnchorDate => $composableBuilder(
    column: $table.stateAnchorDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stateExpectedAfterMinutes => $composableBuilder(
    column: $table.stateExpectedAfterMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stateWarningAfterMinutes => $composableBuilder(
    column: $table.stateWarningAfterMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stateDangerAfterMinutes => $composableBuilder(
    column: $table.stateDangerAfterMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastDoneAt => $composableBuilder(
    column: $table.lastDoneAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemPacksTableFilterComposer get packId {
    final $$ItemPacksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.itemPacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemPacksTableFilterComposer(
            $db: $db,
            $table: $db.itemPacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> resourceConsumptionRulesRefs(
    Expression<bool> Function($$ResourceConsumptionRulesTableFilterComposer f)
    f,
  ) {
    final $$ResourceConsumptionRulesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.resourceConsumptionRules,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ResourceConsumptionRulesTableFilterComposer(
                $db: $db,
                $table: $db.resourceConsumptionRules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> itemActionRecordsRefs(
    Expression<bool> Function($$ItemActionRecordsTableFilterComposer f) f,
  ) {
    final $$ItemActionRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemActionRecords,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemActionRecordsTableFilterComposer(
            $db: $db,
            $table: $db.itemActionRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> stageRelatedItemsRefs(
    Expression<bool> Function($$StageRelatedItemsTableFilterComposer f) f,
  ) {
    final $$StageRelatedItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stageRelatedItems,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageRelatedItemsTableFilterComposer(
            $db: $db,
            $table: $db.stageRelatedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attentionPolicySource => $composableBuilder(
    column: $table.attentionPolicySource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixedScheduleType => $composableBuilder(
    column: $table.fixedScheduleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fixedScheduleInterval => $composableBuilder(
    column: $table.fixedScheduleInterval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fixedMonthlyDay => $composableBuilder(
    column: $table.fixedMonthlyDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixedRepeatRuleV2 => $composableBuilder(
    column: $table.fixedRepeatRuleV2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fixedAnchorDate => $composableBuilder(
    column: $table.fixedAnchorDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fixedDueDate => $composableBuilder(
    column: $table.fixedDueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixedTimeOfDay => $composableBuilder(
    column: $table.fixedTimeOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixedOverduePolicy => $composableBuilder(
    column: $table.fixedOverduePolicy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fixedExpectedBeforeMinutes => $composableBuilder(
    column: $table.fixedExpectedBeforeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fixedWarningBeforeMinutes => $composableBuilder(
    column: $table.fixedWarningBeforeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fixedDangerBeforeMinutes => $composableBuilder(
    column: $table.fixedDangerBeforeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stateAnchorDate => $composableBuilder(
    column: $table.stateAnchorDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stateExpectedAfterMinutes => $composableBuilder(
    column: $table.stateExpectedAfterMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stateWarningAfterMinutes => $composableBuilder(
    column: $table.stateWarningAfterMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stateDangerAfterMinutes => $composableBuilder(
    column: $table.stateDangerAfterMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastDoneAt => $composableBuilder(
    column: $table.lastDoneAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemPacksTableOrderingComposer get packId {
    final $$ItemPacksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.itemPacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemPacksTableOrderingComposer(
            $db: $db,
            $table: $db.itemPacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get attentionPolicySource => $composableBuilder(
    column: $table.attentionPolicySource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fixedScheduleType => $composableBuilder(
    column: $table.fixedScheduleType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fixedScheduleInterval => $composableBuilder(
    column: $table.fixedScheduleInterval,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fixedMonthlyDay => $composableBuilder(
    column: $table.fixedMonthlyDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fixedRepeatRuleV2 => $composableBuilder(
    column: $table.fixedRepeatRuleV2,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fixedAnchorDate => $composableBuilder(
    column: $table.fixedAnchorDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fixedDueDate => $composableBuilder(
    column: $table.fixedDueDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fixedTimeOfDay => $composableBuilder(
    column: $table.fixedTimeOfDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fixedOverduePolicy => $composableBuilder(
    column: $table.fixedOverduePolicy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fixedExpectedBeforeMinutes => $composableBuilder(
    column: $table.fixedExpectedBeforeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fixedWarningBeforeMinutes => $composableBuilder(
    column: $table.fixedWarningBeforeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fixedDangerBeforeMinutes => $composableBuilder(
    column: $table.fixedDangerBeforeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stateAnchorDate => $composableBuilder(
    column: $table.stateAnchorDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stateExpectedAfterMinutes => $composableBuilder(
    column: $table.stateExpectedAfterMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stateWarningAfterMinutes => $composableBuilder(
    column: $table.stateWarningAfterMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stateDangerAfterMinutes => $composableBuilder(
    column: $table.stateDangerAfterMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastDoneAt => $composableBuilder(
    column: $table.lastDoneAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ItemPacksTableAnnotationComposer get packId {
    final $$ItemPacksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.itemPacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemPacksTableAnnotationComposer(
            $db: $db,
            $table: $db.itemPacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> resourceConsumptionRulesRefs<T extends Object>(
    Expression<T> Function($$ResourceConsumptionRulesTableAnnotationComposer a)
    f,
  ) {
    final $$ResourceConsumptionRulesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.resourceConsumptionRules,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ResourceConsumptionRulesTableAnnotationComposer(
                $db: $db,
                $table: $db.resourceConsumptionRules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> itemActionRecordsRefs<T extends Object>(
    Expression<T> Function($$ItemActionRecordsTableAnnotationComposer a) f,
  ) {
    final $$ItemActionRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.itemActionRecords,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ItemActionRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.itemActionRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> stageRelatedItemsRefs<T extends Object>(
    Expression<T> Function($$StageRelatedItemsTableAnnotationComposer a) f,
  ) {
    final $$StageRelatedItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.stageRelatedItems,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$StageRelatedItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.stageRelatedItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          ItemRow,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (ItemRow, $$ItemsTableReferences),
          ItemRow,
          PrefetchHooks Function({
            bool packId,
            bool resourceConsumptionRulesRefs,
            bool itemActionRecordsRefs,
            bool stageRelatedItemsRefs,
          })
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> packId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> attentionPolicySource = const Value.absent(),
                Value<String?> fixedScheduleType = const Value.absent(),
                Value<int?> fixedScheduleInterval = const Value.absent(),
                Value<int?> fixedMonthlyDay = const Value.absent(),
                Value<String?> fixedRepeatRuleV2 = const Value.absent(),
                Value<int?> fixedAnchorDate = const Value.absent(),
                Value<int?> fixedDueDate = const Value.absent(),
                Value<String?> fixedTimeOfDay = const Value.absent(),
                Value<String?> fixedOverduePolicy = const Value.absent(),
                Value<int?> fixedExpectedBeforeMinutes = const Value.absent(),
                Value<int?> fixedWarningBeforeMinutes = const Value.absent(),
                Value<int?> fixedDangerBeforeMinutes = const Value.absent(),
                Value<int?> stateAnchorDate = const Value.absent(),
                Value<int?> stateExpectedAfterMinutes = const Value.absent(),
                Value<int?> stateWarningAfterMinutes = const Value.absent(),
                Value<int?> stateDangerAfterMinutes = const Value.absent(),
                Value<int?> lastDoneAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                packId: packId,
                title: title,
                description: description,
                status: status,
                type: type,
                attentionPolicySource: attentionPolicySource,
                fixedScheduleType: fixedScheduleType,
                fixedScheduleInterval: fixedScheduleInterval,
                fixedMonthlyDay: fixedMonthlyDay,
                fixedRepeatRuleV2: fixedRepeatRuleV2,
                fixedAnchorDate: fixedAnchorDate,
                fixedDueDate: fixedDueDate,
                fixedTimeOfDay: fixedTimeOfDay,
                fixedOverduePolicy: fixedOverduePolicy,
                fixedExpectedBeforeMinutes: fixedExpectedBeforeMinutes,
                fixedWarningBeforeMinutes: fixedWarningBeforeMinutes,
                fixedDangerBeforeMinutes: fixedDangerBeforeMinutes,
                stateAnchorDate: stateAnchorDate,
                stateExpectedAfterMinutes: stateExpectedAfterMinutes,
                stateWarningAfterMinutes: stateWarningAfterMinutes,
                stateDangerAfterMinutes: stateDangerAfterMinutes,
                lastDoneAt: lastDoneAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int packId,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                required String type,
                Value<String> attentionPolicySource = const Value.absent(),
                Value<String?> fixedScheduleType = const Value.absent(),
                Value<int?> fixedScheduleInterval = const Value.absent(),
                Value<int?> fixedMonthlyDay = const Value.absent(),
                Value<String?> fixedRepeatRuleV2 = const Value.absent(),
                Value<int?> fixedAnchorDate = const Value.absent(),
                Value<int?> fixedDueDate = const Value.absent(),
                Value<String?> fixedTimeOfDay = const Value.absent(),
                Value<String?> fixedOverduePolicy = const Value.absent(),
                Value<int?> fixedExpectedBeforeMinutes = const Value.absent(),
                Value<int?> fixedWarningBeforeMinutes = const Value.absent(),
                Value<int?> fixedDangerBeforeMinutes = const Value.absent(),
                Value<int?> stateAnchorDate = const Value.absent(),
                Value<int?> stateExpectedAfterMinutes = const Value.absent(),
                Value<int?> stateWarningAfterMinutes = const Value.absent(),
                Value<int?> stateDangerAfterMinutes = const Value.absent(),
                Value<int?> lastDoneAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ItemsCompanion.insert(
                id: id,
                packId: packId,
                title: title,
                description: description,
                status: status,
                type: type,
                attentionPolicySource: attentionPolicySource,
                fixedScheduleType: fixedScheduleType,
                fixedScheduleInterval: fixedScheduleInterval,
                fixedMonthlyDay: fixedMonthlyDay,
                fixedRepeatRuleV2: fixedRepeatRuleV2,
                fixedAnchorDate: fixedAnchorDate,
                fixedDueDate: fixedDueDate,
                fixedTimeOfDay: fixedTimeOfDay,
                fixedOverduePolicy: fixedOverduePolicy,
                fixedExpectedBeforeMinutes: fixedExpectedBeforeMinutes,
                fixedWarningBeforeMinutes: fixedWarningBeforeMinutes,
                fixedDangerBeforeMinutes: fixedDangerBeforeMinutes,
                stateAnchorDate: stateAnchorDate,
                stateExpectedAfterMinutes: stateExpectedAfterMinutes,
                stateWarningAfterMinutes: stateWarningAfterMinutes,
                stateDangerAfterMinutes: stateDangerAfterMinutes,
                lastDoneAt: lastDoneAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ItemsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                packId = false,
                resourceConsumptionRulesRefs = false,
                itemActionRecordsRefs = false,
                stageRelatedItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (resourceConsumptionRulesRefs)
                      db.resourceConsumptionRules,
                    if (itemActionRecordsRefs) db.itemActionRecords,
                    if (stageRelatedItemsRefs) db.stageRelatedItems,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (packId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.packId,
                                    referencedTable: $$ItemsTableReferences
                                        ._packIdTable(db),
                                    referencedColumn: $$ItemsTableReferences
                                        ._packIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (resourceConsumptionRulesRefs)
                        await $_getPrefetchedData<
                          ItemRow,
                          $ItemsTable,
                          ResourceConsumptionRuleRow
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._resourceConsumptionRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).resourceConsumptionRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (itemActionRecordsRefs)
                        await $_getPrefetchedData<
                          ItemRow,
                          $ItemsTable,
                          ItemActionRecordRow
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._itemActionRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).itemActionRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (stageRelatedItemsRefs)
                        await $_getPrefetchedData<
                          ItemRow,
                          $ItemsTable,
                          StageRelatedItemRow
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._stageRelatedItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).stageRelatedItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      ItemRow,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (ItemRow, $$ItemsTableReferences),
      ItemRow,
      PrefetchHooks Function({
        bool packId,
        bool resourceConsumptionRulesRefs,
        bool itemActionRecordsRefs,
        bool stageRelatedItemsRefs,
      })
    >;
typedef $$PackTemplatesTableCreateCompanionBuilder =
    PackTemplatesCompanion Function({
      Value<int> id,
      required String templateName,
      Value<String> iconEmoji,
      Value<String?> description,
      required int createdAt,
      required int updatedAt,
    });
typedef $$PackTemplatesTableUpdateCompanionBuilder =
    PackTemplatesCompanion Function({
      Value<int> id,
      Value<String> templateName,
      Value<String> iconEmoji,
      Value<String?> description,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$PackTemplatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $PackTemplatesTable, PackTemplateRow> {
  $$PackTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PackTemplateItemsTable, List<PackTemplateItemRow>>
  _packTemplateItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.packTemplateItems,
        aliasName: $_aliasNameGenerator(
          db.packTemplates.id,
          db.packTemplateItems.templateId,
        ),
      );

  $$PackTemplateItemsTableProcessedTableManager get packTemplateItemsRefs {
    final manager = $$PackTemplateItemsTableTableManager(
      $_db,
      $_db.packTemplateItems,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _packTemplateItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PackTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $PackTemplatesTable> {
  $$PackTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateName => $composableBuilder(
    column: $table.templateName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconEmoji => $composableBuilder(
    column: $table.iconEmoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> packTemplateItemsRefs(
    Expression<bool> Function($$PackTemplateItemsTableFilterComposer f) f,
  ) {
    final $$PackTemplateItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.packTemplateItems,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PackTemplateItemsTableFilterComposer(
            $db: $db,
            $table: $db.packTemplateItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PackTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $PackTemplatesTable> {
  $$PackTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateName => $composableBuilder(
    column: $table.templateName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconEmoji => $composableBuilder(
    column: $table.iconEmoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PackTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PackTemplatesTable> {
  $$PackTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get templateName => $composableBuilder(
    column: $table.templateName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconEmoji =>
      $composableBuilder(column: $table.iconEmoji, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> packTemplateItemsRefs<T extends Object>(
    Expression<T> Function($$PackTemplateItemsTableAnnotationComposer a) f,
  ) {
    final $$PackTemplateItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.packTemplateItems,
          getReferencedColumn: (t) => t.templateId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PackTemplateItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.packTemplateItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PackTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PackTemplatesTable,
          PackTemplateRow,
          $$PackTemplatesTableFilterComposer,
          $$PackTemplatesTableOrderingComposer,
          $$PackTemplatesTableAnnotationComposer,
          $$PackTemplatesTableCreateCompanionBuilder,
          $$PackTemplatesTableUpdateCompanionBuilder,
          (PackTemplateRow, $$PackTemplatesTableReferences),
          PackTemplateRow,
          PrefetchHooks Function({bool packTemplateItemsRefs})
        > {
  $$PackTemplatesTableTableManager(_$AppDatabase db, $PackTemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PackTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PackTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PackTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> templateName = const Value.absent(),
                Value<String> iconEmoji = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => PackTemplatesCompanion(
                id: id,
                templateName: templateName,
                iconEmoji: iconEmoji,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String templateName,
                Value<String> iconEmoji = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => PackTemplatesCompanion.insert(
                id: id,
                templateName: templateName,
                iconEmoji: iconEmoji,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PackTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({packTemplateItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (packTemplateItemsRefs) db.packTemplateItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (packTemplateItemsRefs)
                    await $_getPrefetchedData<
                      PackTemplateRow,
                      $PackTemplatesTable,
                      PackTemplateItemRow
                    >(
                      currentTable: table,
                      referencedTable: $$PackTemplatesTableReferences
                          ._packTemplateItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PackTemplatesTableReferences(
                            db,
                            table,
                            p0,
                          ).packTemplateItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.templateId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PackTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PackTemplatesTable,
      PackTemplateRow,
      $$PackTemplatesTableFilterComposer,
      $$PackTemplatesTableOrderingComposer,
      $$PackTemplatesTableAnnotationComposer,
      $$PackTemplatesTableCreateCompanionBuilder,
      $$PackTemplatesTableUpdateCompanionBuilder,
      (PackTemplateRow, $$PackTemplatesTableReferences),
      PackTemplateRow,
      PrefetchHooks Function({bool packTemplateItemsRefs})
    >;
typedef $$PackTemplateItemsTableCreateCompanionBuilder =
    PackTemplateItemsCompanion Function({
      Value<int> id,
      required int templateId,
      Value<int> orderIndex,
      required String title,
      required String type,
      Value<String> attentionPolicySource,
      Value<String?> fixedScheduleType,
      Value<int?> fixedScheduleInterval,
      Value<int?> fixedMonthlyDay,
      Value<String?> fixedRepeatRuleV2,
      Value<String?> fixedTimeOfDay,
      Value<String?> fixedOverduePolicy,
      Value<int?> fixedExpectedBeforeMinutes,
      Value<int?> fixedWarningBeforeMinutes,
      Value<int?> fixedDangerBeforeMinutes,
      Value<int?> stateExpectedAfterMinutes,
      Value<int?> stateWarningAfterMinutes,
      Value<int?> stateDangerAfterMinutes,
      required int createdAt,
      required int updatedAt,
    });
typedef $$PackTemplateItemsTableUpdateCompanionBuilder =
    PackTemplateItemsCompanion Function({
      Value<int> id,
      Value<int> templateId,
      Value<int> orderIndex,
      Value<String> title,
      Value<String> type,
      Value<String> attentionPolicySource,
      Value<String?> fixedScheduleType,
      Value<int?> fixedScheduleInterval,
      Value<int?> fixedMonthlyDay,
      Value<String?> fixedRepeatRuleV2,
      Value<String?> fixedTimeOfDay,
      Value<String?> fixedOverduePolicy,
      Value<int?> fixedExpectedBeforeMinutes,
      Value<int?> fixedWarningBeforeMinutes,
      Value<int?> fixedDangerBeforeMinutes,
      Value<int?> stateExpectedAfterMinutes,
      Value<int?> stateWarningAfterMinutes,
      Value<int?> stateDangerAfterMinutes,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$PackTemplateItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PackTemplateItemsTable,
          PackTemplateItemRow
        > {
  $$PackTemplateItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PackTemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.packTemplates.createAlias(
        $_aliasNameGenerator(
          db.packTemplateItems.templateId,
          db.packTemplates.id,
        ),
      );

  $$PackTemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<int>('template_id')!;

    final manager = $$PackTemplatesTableTableManager(
      $_db,
      $_db.packTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PackTemplateItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PackTemplateItemsTable> {
  $$PackTemplateItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attentionPolicySource => $composableBuilder(
    column: $table.attentionPolicySource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixedScheduleType => $composableBuilder(
    column: $table.fixedScheduleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fixedScheduleInterval => $composableBuilder(
    column: $table.fixedScheduleInterval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fixedMonthlyDay => $composableBuilder(
    column: $table.fixedMonthlyDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixedRepeatRuleV2 => $composableBuilder(
    column: $table.fixedRepeatRuleV2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixedTimeOfDay => $composableBuilder(
    column: $table.fixedTimeOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixedOverduePolicy => $composableBuilder(
    column: $table.fixedOverduePolicy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fixedExpectedBeforeMinutes => $composableBuilder(
    column: $table.fixedExpectedBeforeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fixedWarningBeforeMinutes => $composableBuilder(
    column: $table.fixedWarningBeforeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fixedDangerBeforeMinutes => $composableBuilder(
    column: $table.fixedDangerBeforeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stateExpectedAfterMinutes => $composableBuilder(
    column: $table.stateExpectedAfterMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stateWarningAfterMinutes => $composableBuilder(
    column: $table.stateWarningAfterMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stateDangerAfterMinutes => $composableBuilder(
    column: $table.stateDangerAfterMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PackTemplatesTableFilterComposer get templateId {
    final $$PackTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.packTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PackTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.packTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PackTemplateItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PackTemplateItemsTable> {
  $$PackTemplateItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attentionPolicySource => $composableBuilder(
    column: $table.attentionPolicySource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixedScheduleType => $composableBuilder(
    column: $table.fixedScheduleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fixedScheduleInterval => $composableBuilder(
    column: $table.fixedScheduleInterval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fixedMonthlyDay => $composableBuilder(
    column: $table.fixedMonthlyDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixedRepeatRuleV2 => $composableBuilder(
    column: $table.fixedRepeatRuleV2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixedTimeOfDay => $composableBuilder(
    column: $table.fixedTimeOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixedOverduePolicy => $composableBuilder(
    column: $table.fixedOverduePolicy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fixedExpectedBeforeMinutes => $composableBuilder(
    column: $table.fixedExpectedBeforeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fixedWarningBeforeMinutes => $composableBuilder(
    column: $table.fixedWarningBeforeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fixedDangerBeforeMinutes => $composableBuilder(
    column: $table.fixedDangerBeforeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stateExpectedAfterMinutes => $composableBuilder(
    column: $table.stateExpectedAfterMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stateWarningAfterMinutes => $composableBuilder(
    column: $table.stateWarningAfterMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stateDangerAfterMinutes => $composableBuilder(
    column: $table.stateDangerAfterMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PackTemplatesTableOrderingComposer get templateId {
    final $$PackTemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.packTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PackTemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.packTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PackTemplateItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PackTemplateItemsTable> {
  $$PackTemplateItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get attentionPolicySource => $composableBuilder(
    column: $table.attentionPolicySource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fixedScheduleType => $composableBuilder(
    column: $table.fixedScheduleType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fixedScheduleInterval => $composableBuilder(
    column: $table.fixedScheduleInterval,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fixedMonthlyDay => $composableBuilder(
    column: $table.fixedMonthlyDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fixedRepeatRuleV2 => $composableBuilder(
    column: $table.fixedRepeatRuleV2,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fixedTimeOfDay => $composableBuilder(
    column: $table.fixedTimeOfDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fixedOverduePolicy => $composableBuilder(
    column: $table.fixedOverduePolicy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fixedExpectedBeforeMinutes => $composableBuilder(
    column: $table.fixedExpectedBeforeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fixedWarningBeforeMinutes => $composableBuilder(
    column: $table.fixedWarningBeforeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fixedDangerBeforeMinutes => $composableBuilder(
    column: $table.fixedDangerBeforeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stateExpectedAfterMinutes => $composableBuilder(
    column: $table.stateExpectedAfterMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stateWarningAfterMinutes => $composableBuilder(
    column: $table.stateWarningAfterMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stateDangerAfterMinutes => $composableBuilder(
    column: $table.stateDangerAfterMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PackTemplatesTableAnnotationComposer get templateId {
    final $$PackTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.packTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PackTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.packTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PackTemplateItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PackTemplateItemsTable,
          PackTemplateItemRow,
          $$PackTemplateItemsTableFilterComposer,
          $$PackTemplateItemsTableOrderingComposer,
          $$PackTemplateItemsTableAnnotationComposer,
          $$PackTemplateItemsTableCreateCompanionBuilder,
          $$PackTemplateItemsTableUpdateCompanionBuilder,
          (PackTemplateItemRow, $$PackTemplateItemsTableReferences),
          PackTemplateItemRow,
          PrefetchHooks Function({bool templateId})
        > {
  $$PackTemplateItemsTableTableManager(
    _$AppDatabase db,
    $PackTemplateItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PackTemplateItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PackTemplateItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PackTemplateItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> templateId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> attentionPolicySource = const Value.absent(),
                Value<String?> fixedScheduleType = const Value.absent(),
                Value<int?> fixedScheduleInterval = const Value.absent(),
                Value<int?> fixedMonthlyDay = const Value.absent(),
                Value<String?> fixedRepeatRuleV2 = const Value.absent(),
                Value<String?> fixedTimeOfDay = const Value.absent(),
                Value<String?> fixedOverduePolicy = const Value.absent(),
                Value<int?> fixedExpectedBeforeMinutes = const Value.absent(),
                Value<int?> fixedWarningBeforeMinutes = const Value.absent(),
                Value<int?> fixedDangerBeforeMinutes = const Value.absent(),
                Value<int?> stateExpectedAfterMinutes = const Value.absent(),
                Value<int?> stateWarningAfterMinutes = const Value.absent(),
                Value<int?> stateDangerAfterMinutes = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => PackTemplateItemsCompanion(
                id: id,
                templateId: templateId,
                orderIndex: orderIndex,
                title: title,
                type: type,
                attentionPolicySource: attentionPolicySource,
                fixedScheduleType: fixedScheduleType,
                fixedScheduleInterval: fixedScheduleInterval,
                fixedMonthlyDay: fixedMonthlyDay,
                fixedRepeatRuleV2: fixedRepeatRuleV2,
                fixedTimeOfDay: fixedTimeOfDay,
                fixedOverduePolicy: fixedOverduePolicy,
                fixedExpectedBeforeMinutes: fixedExpectedBeforeMinutes,
                fixedWarningBeforeMinutes: fixedWarningBeforeMinutes,
                fixedDangerBeforeMinutes: fixedDangerBeforeMinutes,
                stateExpectedAfterMinutes: stateExpectedAfterMinutes,
                stateWarningAfterMinutes: stateWarningAfterMinutes,
                stateDangerAfterMinutes: stateDangerAfterMinutes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int templateId,
                Value<int> orderIndex = const Value.absent(),
                required String title,
                required String type,
                Value<String> attentionPolicySource = const Value.absent(),
                Value<String?> fixedScheduleType = const Value.absent(),
                Value<int?> fixedScheduleInterval = const Value.absent(),
                Value<int?> fixedMonthlyDay = const Value.absent(),
                Value<String?> fixedRepeatRuleV2 = const Value.absent(),
                Value<String?> fixedTimeOfDay = const Value.absent(),
                Value<String?> fixedOverduePolicy = const Value.absent(),
                Value<int?> fixedExpectedBeforeMinutes = const Value.absent(),
                Value<int?> fixedWarningBeforeMinutes = const Value.absent(),
                Value<int?> fixedDangerBeforeMinutes = const Value.absent(),
                Value<int?> stateExpectedAfterMinutes = const Value.absent(),
                Value<int?> stateWarningAfterMinutes = const Value.absent(),
                Value<int?> stateDangerAfterMinutes = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => PackTemplateItemsCompanion.insert(
                id: id,
                templateId: templateId,
                orderIndex: orderIndex,
                title: title,
                type: type,
                attentionPolicySource: attentionPolicySource,
                fixedScheduleType: fixedScheduleType,
                fixedScheduleInterval: fixedScheduleInterval,
                fixedMonthlyDay: fixedMonthlyDay,
                fixedRepeatRuleV2: fixedRepeatRuleV2,
                fixedTimeOfDay: fixedTimeOfDay,
                fixedOverduePolicy: fixedOverduePolicy,
                fixedExpectedBeforeMinutes: fixedExpectedBeforeMinutes,
                fixedWarningBeforeMinutes: fixedWarningBeforeMinutes,
                fixedDangerBeforeMinutes: fixedDangerBeforeMinutes,
                stateExpectedAfterMinutes: stateExpectedAfterMinutes,
                stateWarningAfterMinutes: stateWarningAfterMinutes,
                stateDangerAfterMinutes: stateDangerAfterMinutes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PackTemplateItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (templateId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.templateId,
                                referencedTable:
                                    $$PackTemplateItemsTableReferences
                                        ._templateIdTable(db),
                                referencedColumn:
                                    $$PackTemplateItemsTableReferences
                                        ._templateIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PackTemplateItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PackTemplateItemsTable,
      PackTemplateItemRow,
      $$PackTemplateItemsTableFilterComposer,
      $$PackTemplateItemsTableOrderingComposer,
      $$PackTemplateItemsTableAnnotationComposer,
      $$PackTemplateItemsTableCreateCompanionBuilder,
      $$PackTemplateItemsTableUpdateCompanionBuilder,
      (PackTemplateItemRow, $$PackTemplateItemsTableReferences),
      PackTemplateItemRow,
      PrefetchHooks Function({bool templateId})
    >;
typedef $$ResourcesTableCreateCompanionBuilder =
    ResourcesCompanion Function({
      Value<int> id,
      required int packId,
      required String title,
      Value<String?> description,
      Value<String> status,
      required String type,
      Value<int?> timeAnchorDate,
      Value<int?> timeDurationDays,
      Value<int?> timeExpectedBeforeDays,
      Value<int?> timeWarningBeforeDays,
      Value<int?> timeDangerBeforeDays,
      Value<int?> quantityCurrent,
      Value<String?> quantityUnitLabel,
      Value<int?> quantityExpectedThreshold,
      Value<int?> quantityWarningThreshold,
      Value<int?> quantityDangerThreshold,
      Value<int?> lastRefilledAt,
      required int createdAt,
      required int updatedAt,
    });
typedef $$ResourcesTableUpdateCompanionBuilder =
    ResourcesCompanion Function({
      Value<int> id,
      Value<int> packId,
      Value<String> title,
      Value<String?> description,
      Value<String> status,
      Value<String> type,
      Value<int?> timeAnchorDate,
      Value<int?> timeDurationDays,
      Value<int?> timeExpectedBeforeDays,
      Value<int?> timeWarningBeforeDays,
      Value<int?> timeDangerBeforeDays,
      Value<int?> quantityCurrent,
      Value<String?> quantityUnitLabel,
      Value<int?> quantityExpectedThreshold,
      Value<int?> quantityWarningThreshold,
      Value<int?> quantityDangerThreshold,
      Value<int?> lastRefilledAt,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$ResourcesTableReferences
    extends BaseReferences<_$AppDatabase, $ResourcesTable, ResourceRow> {
  $$ResourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemPacksTable _packIdTable(_$AppDatabase db) => db.itemPacks
      .createAlias($_aliasNameGenerator(db.resources.packId, db.itemPacks.id));

  $$ItemPacksTableProcessedTableManager get packId {
    final $_column = $_itemColumn<int>('pack_id')!;

    final manager = $$ItemPacksTableTableManager(
      $_db,
      $_db.itemPacks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_packIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ResourceConsumptionRulesTable,
    List<ResourceConsumptionRuleRow>
  >
  _resourceConsumptionRulesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.resourceConsumptionRules,
        aliasName: $_aliasNameGenerator(
          db.resources.id,
          db.resourceConsumptionRules.resourceId,
        ),
      );

  $$ResourceConsumptionRulesTableProcessedTableManager
  get resourceConsumptionRulesRefs {
    final manager = $$ResourceConsumptionRulesTableTableManager(
      $_db,
      $_db.resourceConsumptionRules,
    ).filter((f) => f.resourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _resourceConsumptionRulesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ResourceActionRecordsTable,
    List<ResourceActionRecordRow>
  >
  _resourceActionRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.resourceActionRecords,
        aliasName: $_aliasNameGenerator(
          db.resources.id,
          db.resourceActionRecords.resourceId,
        ),
      );

  $$ResourceActionRecordsTableProcessedTableManager
  get resourceActionRecordsRefs {
    final manager = $$ResourceActionRecordsTableTableManager(
      $_db,
      $_db.resourceActionRecords,
    ).filter((f) => f.resourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _resourceActionRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ResourcesTableFilterComposer
    extends Composer<_$AppDatabase, $ResourcesTable> {
  $$ResourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeAnchorDate => $composableBuilder(
    column: $table.timeAnchorDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeDurationDays => $composableBuilder(
    column: $table.timeDurationDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeExpectedBeforeDays => $composableBuilder(
    column: $table.timeExpectedBeforeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeWarningBeforeDays => $composableBuilder(
    column: $table.timeWarningBeforeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeDangerBeforeDays => $composableBuilder(
    column: $table.timeDangerBeforeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityCurrent => $composableBuilder(
    column: $table.quantityCurrent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantityUnitLabel => $composableBuilder(
    column: $table.quantityUnitLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityExpectedThreshold => $composableBuilder(
    column: $table.quantityExpectedThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityWarningThreshold => $composableBuilder(
    column: $table.quantityWarningThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityDangerThreshold => $composableBuilder(
    column: $table.quantityDangerThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastRefilledAt => $composableBuilder(
    column: $table.lastRefilledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemPacksTableFilterComposer get packId {
    final $$ItemPacksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.itemPacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemPacksTableFilterComposer(
            $db: $db,
            $table: $db.itemPacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> resourceConsumptionRulesRefs(
    Expression<bool> Function($$ResourceConsumptionRulesTableFilterComposer f)
    f,
  ) {
    final $$ResourceConsumptionRulesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.resourceConsumptionRules,
          getReferencedColumn: (t) => t.resourceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ResourceConsumptionRulesTableFilterComposer(
                $db: $db,
                $table: $db.resourceConsumptionRules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> resourceActionRecordsRefs(
    Expression<bool> Function($$ResourceActionRecordsTableFilterComposer f) f,
  ) {
    final $$ResourceActionRecordsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.resourceActionRecords,
          getReferencedColumn: (t) => t.resourceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ResourceActionRecordsTableFilterComposer(
                $db: $db,
                $table: $db.resourceActionRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ResourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $ResourcesTable> {
  $$ResourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeAnchorDate => $composableBuilder(
    column: $table.timeAnchorDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeDurationDays => $composableBuilder(
    column: $table.timeDurationDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeExpectedBeforeDays => $composableBuilder(
    column: $table.timeExpectedBeforeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeWarningBeforeDays => $composableBuilder(
    column: $table.timeWarningBeforeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeDangerBeforeDays => $composableBuilder(
    column: $table.timeDangerBeforeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityCurrent => $composableBuilder(
    column: $table.quantityCurrent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityUnitLabel => $composableBuilder(
    column: $table.quantityUnitLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityExpectedThreshold => $composableBuilder(
    column: $table.quantityExpectedThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityWarningThreshold => $composableBuilder(
    column: $table.quantityWarningThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityDangerThreshold => $composableBuilder(
    column: $table.quantityDangerThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastRefilledAt => $composableBuilder(
    column: $table.lastRefilledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemPacksTableOrderingComposer get packId {
    final $$ItemPacksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.itemPacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemPacksTableOrderingComposer(
            $db: $db,
            $table: $db.itemPacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ResourcesTable> {
  $$ResourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get timeAnchorDate => $composableBuilder(
    column: $table.timeAnchorDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeDurationDays => $composableBuilder(
    column: $table.timeDurationDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeExpectedBeforeDays => $composableBuilder(
    column: $table.timeExpectedBeforeDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeWarningBeforeDays => $composableBuilder(
    column: $table.timeWarningBeforeDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeDangerBeforeDays => $composableBuilder(
    column: $table.timeDangerBeforeDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantityCurrent => $composableBuilder(
    column: $table.quantityCurrent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quantityUnitLabel => $composableBuilder(
    column: $table.quantityUnitLabel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantityExpectedThreshold => $composableBuilder(
    column: $table.quantityExpectedThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantityWarningThreshold => $composableBuilder(
    column: $table.quantityWarningThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantityDangerThreshold => $composableBuilder(
    column: $table.quantityDangerThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastRefilledAt => $composableBuilder(
    column: $table.lastRefilledAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ItemPacksTableAnnotationComposer get packId {
    final $$ItemPacksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.itemPacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemPacksTableAnnotationComposer(
            $db: $db,
            $table: $db.itemPacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> resourceConsumptionRulesRefs<T extends Object>(
    Expression<T> Function($$ResourceConsumptionRulesTableAnnotationComposer a)
    f,
  ) {
    final $$ResourceConsumptionRulesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.resourceConsumptionRules,
          getReferencedColumn: (t) => t.resourceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ResourceConsumptionRulesTableAnnotationComposer(
                $db: $db,
                $table: $db.resourceConsumptionRules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> resourceActionRecordsRefs<T extends Object>(
    Expression<T> Function($$ResourceActionRecordsTableAnnotationComposer a) f,
  ) {
    final $$ResourceActionRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.resourceActionRecords,
          getReferencedColumn: (t) => t.resourceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ResourceActionRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.resourceActionRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ResourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ResourcesTable,
          ResourceRow,
          $$ResourcesTableFilterComposer,
          $$ResourcesTableOrderingComposer,
          $$ResourcesTableAnnotationComposer,
          $$ResourcesTableCreateCompanionBuilder,
          $$ResourcesTableUpdateCompanionBuilder,
          (ResourceRow, $$ResourcesTableReferences),
          ResourceRow,
          PrefetchHooks Function({
            bool packId,
            bool resourceConsumptionRulesRefs,
            bool resourceActionRecordsRefs,
          })
        > {
  $$ResourcesTableTableManager(_$AppDatabase db, $ResourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ResourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> packId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int?> timeAnchorDate = const Value.absent(),
                Value<int?> timeDurationDays = const Value.absent(),
                Value<int?> timeExpectedBeforeDays = const Value.absent(),
                Value<int?> timeWarningBeforeDays = const Value.absent(),
                Value<int?> timeDangerBeforeDays = const Value.absent(),
                Value<int?> quantityCurrent = const Value.absent(),
                Value<String?> quantityUnitLabel = const Value.absent(),
                Value<int?> quantityExpectedThreshold = const Value.absent(),
                Value<int?> quantityWarningThreshold = const Value.absent(),
                Value<int?> quantityDangerThreshold = const Value.absent(),
                Value<int?> lastRefilledAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ResourcesCompanion(
                id: id,
                packId: packId,
                title: title,
                description: description,
                status: status,
                type: type,
                timeAnchorDate: timeAnchorDate,
                timeDurationDays: timeDurationDays,
                timeExpectedBeforeDays: timeExpectedBeforeDays,
                timeWarningBeforeDays: timeWarningBeforeDays,
                timeDangerBeforeDays: timeDangerBeforeDays,
                quantityCurrent: quantityCurrent,
                quantityUnitLabel: quantityUnitLabel,
                quantityExpectedThreshold: quantityExpectedThreshold,
                quantityWarningThreshold: quantityWarningThreshold,
                quantityDangerThreshold: quantityDangerThreshold,
                lastRefilledAt: lastRefilledAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int packId,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                required String type,
                Value<int?> timeAnchorDate = const Value.absent(),
                Value<int?> timeDurationDays = const Value.absent(),
                Value<int?> timeExpectedBeforeDays = const Value.absent(),
                Value<int?> timeWarningBeforeDays = const Value.absent(),
                Value<int?> timeDangerBeforeDays = const Value.absent(),
                Value<int?> quantityCurrent = const Value.absent(),
                Value<String?> quantityUnitLabel = const Value.absent(),
                Value<int?> quantityExpectedThreshold = const Value.absent(),
                Value<int?> quantityWarningThreshold = const Value.absent(),
                Value<int?> quantityDangerThreshold = const Value.absent(),
                Value<int?> lastRefilledAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ResourcesCompanion.insert(
                id: id,
                packId: packId,
                title: title,
                description: description,
                status: status,
                type: type,
                timeAnchorDate: timeAnchorDate,
                timeDurationDays: timeDurationDays,
                timeExpectedBeforeDays: timeExpectedBeforeDays,
                timeWarningBeforeDays: timeWarningBeforeDays,
                timeDangerBeforeDays: timeDangerBeforeDays,
                quantityCurrent: quantityCurrent,
                quantityUnitLabel: quantityUnitLabel,
                quantityExpectedThreshold: quantityExpectedThreshold,
                quantityWarningThreshold: quantityWarningThreshold,
                quantityDangerThreshold: quantityDangerThreshold,
                lastRefilledAt: lastRefilledAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ResourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                packId = false,
                resourceConsumptionRulesRefs = false,
                resourceActionRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (resourceConsumptionRulesRefs)
                      db.resourceConsumptionRules,
                    if (resourceActionRecordsRefs) db.resourceActionRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (packId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.packId,
                                    referencedTable: $$ResourcesTableReferences
                                        ._packIdTable(db),
                                    referencedColumn: $$ResourcesTableReferences
                                        ._packIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (resourceConsumptionRulesRefs)
                        await $_getPrefetchedData<
                          ResourceRow,
                          $ResourcesTable,
                          ResourceConsumptionRuleRow
                        >(
                          currentTable: table,
                          referencedTable: $$ResourcesTableReferences
                              ._resourceConsumptionRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ResourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).resourceConsumptionRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.resourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (resourceActionRecordsRefs)
                        await $_getPrefetchedData<
                          ResourceRow,
                          $ResourcesTable,
                          ResourceActionRecordRow
                        >(
                          currentTable: table,
                          referencedTable: $$ResourcesTableReferences
                              ._resourceActionRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ResourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).resourceActionRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.resourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ResourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ResourcesTable,
      ResourceRow,
      $$ResourcesTableFilterComposer,
      $$ResourcesTableOrderingComposer,
      $$ResourcesTableAnnotationComposer,
      $$ResourcesTableCreateCompanionBuilder,
      $$ResourcesTableUpdateCompanionBuilder,
      (ResourceRow, $$ResourcesTableReferences),
      ResourceRow,
      PrefetchHooks Function({
        bool packId,
        bool resourceConsumptionRulesRefs,
        bool resourceActionRecordsRefs,
      })
    >;
typedef $$ResourceConsumptionRulesTableCreateCompanionBuilder =
    ResourceConsumptionRulesCompanion Function({
      Value<int> id,
      required int resourceId,
      required int itemId,
      Value<String> triggerActionType,
      Value<int> consumeAmount,
      Value<bool> isEnabled,
      required int createdAt,
      required int updatedAt,
    });
typedef $$ResourceConsumptionRulesTableUpdateCompanionBuilder =
    ResourceConsumptionRulesCompanion Function({
      Value<int> id,
      Value<int> resourceId,
      Value<int> itemId,
      Value<String> triggerActionType,
      Value<int> consumeAmount,
      Value<bool> isEnabled,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$ResourceConsumptionRulesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ResourceConsumptionRulesTable,
          ResourceConsumptionRuleRow
        > {
  $$ResourceConsumptionRulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ResourcesTable _resourceIdTable(_$AppDatabase db) =>
      db.resources.createAlias(
        $_aliasNameGenerator(
          db.resourceConsumptionRules.resourceId,
          db.resources.id,
        ),
      );

  $$ResourcesTableProcessedTableManager get resourceId {
    final $_column = $_itemColumn<int>('resource_id')!;

    final manager = $$ResourcesTableTableManager(
      $_db,
      $_db.resources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_resourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.resourceConsumptionRules.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ResourceConsumptionRulesTableFilterComposer
    extends Composer<_$AppDatabase, $ResourceConsumptionRulesTable> {
  $$ResourceConsumptionRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get triggerActionType => $composableBuilder(
    column: $table.triggerActionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consumeAmount => $composableBuilder(
    column: $table.consumeAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ResourcesTableFilterComposer get resourceId {
    final $$ResourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourcesTableFilterComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResourceConsumptionRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $ResourceConsumptionRulesTable> {
  $$ResourceConsumptionRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get triggerActionType => $composableBuilder(
    column: $table.triggerActionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consumeAmount => $composableBuilder(
    column: $table.consumeAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ResourcesTableOrderingComposer get resourceId {
    final $$ResourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourcesTableOrderingComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResourceConsumptionRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ResourceConsumptionRulesTable> {
  $$ResourceConsumptionRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get triggerActionType => $composableBuilder(
    column: $table.triggerActionType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get consumeAmount => $composableBuilder(
    column: $table.consumeAmount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ResourcesTableAnnotationComposer get resourceId {
    final $$ResourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResourceConsumptionRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ResourceConsumptionRulesTable,
          ResourceConsumptionRuleRow,
          $$ResourceConsumptionRulesTableFilterComposer,
          $$ResourceConsumptionRulesTableOrderingComposer,
          $$ResourceConsumptionRulesTableAnnotationComposer,
          $$ResourceConsumptionRulesTableCreateCompanionBuilder,
          $$ResourceConsumptionRulesTableUpdateCompanionBuilder,
          (
            ResourceConsumptionRuleRow,
            $$ResourceConsumptionRulesTableReferences,
          ),
          ResourceConsumptionRuleRow,
          PrefetchHooks Function({bool resourceId, bool itemId})
        > {
  $$ResourceConsumptionRulesTableTableManager(
    _$AppDatabase db,
    $ResourceConsumptionRulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResourceConsumptionRulesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ResourceConsumptionRulesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ResourceConsumptionRulesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> resourceId = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<String> triggerActionType = const Value.absent(),
                Value<int> consumeAmount = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ResourceConsumptionRulesCompanion(
                id: id,
                resourceId: resourceId,
                itemId: itemId,
                triggerActionType: triggerActionType,
                consumeAmount: consumeAmount,
                isEnabled: isEnabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int resourceId,
                required int itemId,
                Value<String> triggerActionType = const Value.absent(),
                Value<int> consumeAmount = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ResourceConsumptionRulesCompanion.insert(
                id: id,
                resourceId: resourceId,
                itemId: itemId,
                triggerActionType: triggerActionType,
                consumeAmount: consumeAmount,
                isEnabled: isEnabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ResourceConsumptionRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({resourceId = false, itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (resourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.resourceId,
                                referencedTable:
                                    $$ResourceConsumptionRulesTableReferences
                                        ._resourceIdTable(db),
                                referencedColumn:
                                    $$ResourceConsumptionRulesTableReferences
                                        ._resourceIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable:
                                    $$ResourceConsumptionRulesTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$ResourceConsumptionRulesTableReferences
                                        ._itemIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ResourceConsumptionRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ResourceConsumptionRulesTable,
      ResourceConsumptionRuleRow,
      $$ResourceConsumptionRulesTableFilterComposer,
      $$ResourceConsumptionRulesTableOrderingComposer,
      $$ResourceConsumptionRulesTableAnnotationComposer,
      $$ResourceConsumptionRulesTableCreateCompanionBuilder,
      $$ResourceConsumptionRulesTableUpdateCompanionBuilder,
      (ResourceConsumptionRuleRow, $$ResourceConsumptionRulesTableReferences),
      ResourceConsumptionRuleRow,
      PrefetchHooks Function({bool resourceId, bool itemId})
    >;
typedef $$ItemActionRecordsTableCreateCompanionBuilder =
    ItemActionRecordsCompanion Function({
      Value<int> id,
      required int itemId,
      required String actionType,
      required int actionDate,
      Value<String?> remark,
      Value<String?> payload,
      Value<bool> isReverted,
      Value<int?> revertedAt,
      Value<int?> revertedByActionRecordId,
      required int createdAt,
      required int updatedAt,
    });
typedef $$ItemActionRecordsTableUpdateCompanionBuilder =
    ItemActionRecordsCompanion Function({
      Value<int> id,
      Value<int> itemId,
      Value<String> actionType,
      Value<int> actionDate,
      Value<String?> remark,
      Value<String?> payload,
      Value<bool> isReverted,
      Value<int?> revertedAt,
      Value<int?> revertedByActionRecordId,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$ItemActionRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ItemActionRecordsTable,
          ItemActionRecordRow
        > {
  $$ItemActionRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.itemActionRecords.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ResourceActionRecordsTable,
    List<ResourceActionRecordRow>
  >
  _resourceActionRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.resourceActionRecords,
        aliasName: $_aliasNameGenerator(
          db.itemActionRecords.id,
          db.resourceActionRecords.sourceItemActionRecordId,
        ),
      );

  $$ResourceActionRecordsTableProcessedTableManager
  get resourceActionRecordsRefs {
    final manager =
        $$ResourceActionRecordsTableTableManager(
          $_db,
          $_db.resourceActionRecords,
        ).filter(
          (f) =>
              f.sourceItemActionRecordId.id.sqlEquals($_itemColumn<int>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _resourceActionRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemActionRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemActionRecordsTable> {
  $$ItemActionRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actionDate => $composableBuilder(
    column: $table.actionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remark => $composableBuilder(
    column: $table.remark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isReverted => $composableBuilder(
    column: $table.isReverted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revertedAt => $composableBuilder(
    column: $table.revertedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revertedByActionRecordId => $composableBuilder(
    column: $table.revertedByActionRecordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> resourceActionRecordsRefs(
    Expression<bool> Function($$ResourceActionRecordsTableFilterComposer f) f,
  ) {
    final $$ResourceActionRecordsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.resourceActionRecords,
          getReferencedColumn: (t) => t.sourceItemActionRecordId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ResourceActionRecordsTableFilterComposer(
                $db: $db,
                $table: $db.resourceActionRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ItemActionRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemActionRecordsTable> {
  $$ItemActionRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actionDate => $composableBuilder(
    column: $table.actionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remark => $composableBuilder(
    column: $table.remark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isReverted => $composableBuilder(
    column: $table.isReverted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revertedAt => $composableBuilder(
    column: $table.revertedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revertedByActionRecordId => $composableBuilder(
    column: $table.revertedByActionRecordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemActionRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemActionRecordsTable> {
  $$ItemActionRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actionDate => $composableBuilder(
    column: $table.actionDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remark =>
      $composableBuilder(column: $table.remark, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<bool> get isReverted => $composableBuilder(
    column: $table.isReverted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revertedAt => $composableBuilder(
    column: $table.revertedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revertedByActionRecordId => $composableBuilder(
    column: $table.revertedByActionRecordId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> resourceActionRecordsRefs<T extends Object>(
    Expression<T> Function($$ResourceActionRecordsTableAnnotationComposer a) f,
  ) {
    final $$ResourceActionRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.resourceActionRecords,
          getReferencedColumn: (t) => t.sourceItemActionRecordId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ResourceActionRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.resourceActionRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ItemActionRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemActionRecordsTable,
          ItemActionRecordRow,
          $$ItemActionRecordsTableFilterComposer,
          $$ItemActionRecordsTableOrderingComposer,
          $$ItemActionRecordsTableAnnotationComposer,
          $$ItemActionRecordsTableCreateCompanionBuilder,
          $$ItemActionRecordsTableUpdateCompanionBuilder,
          (ItemActionRecordRow, $$ItemActionRecordsTableReferences),
          ItemActionRecordRow,
          PrefetchHooks Function({bool itemId, bool resourceActionRecordsRefs})
        > {
  $$ItemActionRecordsTableTableManager(
    _$AppDatabase db,
    $ItemActionRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemActionRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemActionRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemActionRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<int> actionDate = const Value.absent(),
                Value<String?> remark = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<bool> isReverted = const Value.absent(),
                Value<int?> revertedAt = const Value.absent(),
                Value<int?> revertedByActionRecordId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ItemActionRecordsCompanion(
                id: id,
                itemId: itemId,
                actionType: actionType,
                actionDate: actionDate,
                remark: remark,
                payload: payload,
                isReverted: isReverted,
                revertedAt: revertedAt,
                revertedByActionRecordId: revertedByActionRecordId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int itemId,
                required String actionType,
                required int actionDate,
                Value<String?> remark = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<bool> isReverted = const Value.absent(),
                Value<int?> revertedAt = const Value.absent(),
                Value<int?> revertedByActionRecordId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ItemActionRecordsCompanion.insert(
                id: id,
                itemId: itemId,
                actionType: actionType,
                actionDate: actionDate,
                remark: remark,
                payload: payload,
                isReverted: isReverted,
                revertedAt: revertedAt,
                revertedByActionRecordId: revertedByActionRecordId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ItemActionRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({itemId = false, resourceActionRecordsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (resourceActionRecordsRefs) db.resourceActionRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (itemId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.itemId,
                                    referencedTable:
                                        $$ItemActionRecordsTableReferences
                                            ._itemIdTable(db),
                                    referencedColumn:
                                        $$ItemActionRecordsTableReferences
                                            ._itemIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (resourceActionRecordsRefs)
                        await $_getPrefetchedData<
                          ItemActionRecordRow,
                          $ItemActionRecordsTable,
                          ResourceActionRecordRow
                        >(
                          currentTable: table,
                          referencedTable: $$ItemActionRecordsTableReferences
                              ._resourceActionRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemActionRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).resourceActionRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceItemActionRecordId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ItemActionRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemActionRecordsTable,
      ItemActionRecordRow,
      $$ItemActionRecordsTableFilterComposer,
      $$ItemActionRecordsTableOrderingComposer,
      $$ItemActionRecordsTableAnnotationComposer,
      $$ItemActionRecordsTableCreateCompanionBuilder,
      $$ItemActionRecordsTableUpdateCompanionBuilder,
      (ItemActionRecordRow, $$ItemActionRecordsTableReferences),
      ItemActionRecordRow,
      PrefetchHooks Function({bool itemId, bool resourceActionRecordsRefs})
    >;
typedef $$ResourceActionRecordsTableCreateCompanionBuilder =
    ResourceActionRecordsCompanion Function({
      Value<int> id,
      required int resourceId,
      required String actionType,
      required int actionDate,
      Value<int?> amount,
      Value<int?> resultingQuantity,
      Value<int?> addedDays,
      Value<int?> resultingDurationDays,
      Value<int?> sourceItemActionRecordId,
      Value<String?> remark,
      Value<bool> isReverted,
      Value<int?> revertedAt,
      Value<int?> revertedByActionRecordId,
      required int createdAt,
      required int updatedAt,
    });
typedef $$ResourceActionRecordsTableUpdateCompanionBuilder =
    ResourceActionRecordsCompanion Function({
      Value<int> id,
      Value<int> resourceId,
      Value<String> actionType,
      Value<int> actionDate,
      Value<int?> amount,
      Value<int?> resultingQuantity,
      Value<int?> addedDays,
      Value<int?> resultingDurationDays,
      Value<int?> sourceItemActionRecordId,
      Value<String?> remark,
      Value<bool> isReverted,
      Value<int?> revertedAt,
      Value<int?> revertedByActionRecordId,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$ResourceActionRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ResourceActionRecordsTable,
          ResourceActionRecordRow
        > {
  $$ResourceActionRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ResourcesTable _resourceIdTable(_$AppDatabase db) =>
      db.resources.createAlias(
        $_aliasNameGenerator(
          db.resourceActionRecords.resourceId,
          db.resources.id,
        ),
      );

  $$ResourcesTableProcessedTableManager get resourceId {
    final $_column = $_itemColumn<int>('resource_id')!;

    final manager = $$ResourcesTableTableManager(
      $_db,
      $_db.resources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_resourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ItemActionRecordsTable _sourceItemActionRecordIdTable(
    _$AppDatabase db,
  ) => db.itemActionRecords.createAlias(
    $_aliasNameGenerator(
      db.resourceActionRecords.sourceItemActionRecordId,
      db.itemActionRecords.id,
    ),
  );

  $$ItemActionRecordsTableProcessedTableManager? get sourceItemActionRecordId {
    final $_column = $_itemColumn<int>('source_item_action_record_id');
    if ($_column == null) return null;
    final manager = $$ItemActionRecordsTableTableManager(
      $_db,
      $_db.itemActionRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _sourceItemActionRecordIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ResourceActionRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ResourceActionRecordsTable> {
  $$ResourceActionRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actionDate => $composableBuilder(
    column: $table.actionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resultingQuantity => $composableBuilder(
    column: $table.resultingQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedDays => $composableBuilder(
    column: $table.addedDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resultingDurationDays => $composableBuilder(
    column: $table.resultingDurationDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remark => $composableBuilder(
    column: $table.remark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isReverted => $composableBuilder(
    column: $table.isReverted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revertedAt => $composableBuilder(
    column: $table.revertedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revertedByActionRecordId => $composableBuilder(
    column: $table.revertedByActionRecordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ResourcesTableFilterComposer get resourceId {
    final $$ResourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourcesTableFilterComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemActionRecordsTableFilterComposer get sourceItemActionRecordId {
    final $$ItemActionRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceItemActionRecordId,
      referencedTable: $db.itemActionRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemActionRecordsTableFilterComposer(
            $db: $db,
            $table: $db.itemActionRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResourceActionRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ResourceActionRecordsTable> {
  $$ResourceActionRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actionDate => $composableBuilder(
    column: $table.actionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resultingQuantity => $composableBuilder(
    column: $table.resultingQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedDays => $composableBuilder(
    column: $table.addedDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resultingDurationDays => $composableBuilder(
    column: $table.resultingDurationDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remark => $composableBuilder(
    column: $table.remark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isReverted => $composableBuilder(
    column: $table.isReverted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revertedAt => $composableBuilder(
    column: $table.revertedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revertedByActionRecordId => $composableBuilder(
    column: $table.revertedByActionRecordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ResourcesTableOrderingComposer get resourceId {
    final $$ResourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourcesTableOrderingComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemActionRecordsTableOrderingComposer get sourceItemActionRecordId {
    final $$ItemActionRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceItemActionRecordId,
      referencedTable: $db.itemActionRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemActionRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.itemActionRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResourceActionRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ResourceActionRecordsTable> {
  $$ResourceActionRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actionDate => $composableBuilder(
    column: $table.actionDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get resultingQuantity => $composableBuilder(
    column: $table.resultingQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addedDays =>
      $composableBuilder(column: $table.addedDays, builder: (column) => column);

  GeneratedColumn<int> get resultingDurationDays => $composableBuilder(
    column: $table.resultingDurationDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remark =>
      $composableBuilder(column: $table.remark, builder: (column) => column);

  GeneratedColumn<bool> get isReverted => $composableBuilder(
    column: $table.isReverted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revertedAt => $composableBuilder(
    column: $table.revertedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revertedByActionRecordId => $composableBuilder(
    column: $table.revertedByActionRecordId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ResourcesTableAnnotationComposer get resourceId {
    final $$ResourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemActionRecordsTableAnnotationComposer get sourceItemActionRecordId {
    final $$ItemActionRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sourceItemActionRecordId,
          referencedTable: $db.itemActionRecords,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ItemActionRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.itemActionRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ResourceActionRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ResourceActionRecordsTable,
          ResourceActionRecordRow,
          $$ResourceActionRecordsTableFilterComposer,
          $$ResourceActionRecordsTableOrderingComposer,
          $$ResourceActionRecordsTableAnnotationComposer,
          $$ResourceActionRecordsTableCreateCompanionBuilder,
          $$ResourceActionRecordsTableUpdateCompanionBuilder,
          (ResourceActionRecordRow, $$ResourceActionRecordsTableReferences),
          ResourceActionRecordRow,
          PrefetchHooks Function({
            bool resourceId,
            bool sourceItemActionRecordId,
          })
        > {
  $$ResourceActionRecordsTableTableManager(
    _$AppDatabase db,
    $ResourceActionRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResourceActionRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ResourceActionRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ResourceActionRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> resourceId = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<int> actionDate = const Value.absent(),
                Value<int?> amount = const Value.absent(),
                Value<int?> resultingQuantity = const Value.absent(),
                Value<int?> addedDays = const Value.absent(),
                Value<int?> resultingDurationDays = const Value.absent(),
                Value<int?> sourceItemActionRecordId = const Value.absent(),
                Value<String?> remark = const Value.absent(),
                Value<bool> isReverted = const Value.absent(),
                Value<int?> revertedAt = const Value.absent(),
                Value<int?> revertedByActionRecordId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ResourceActionRecordsCompanion(
                id: id,
                resourceId: resourceId,
                actionType: actionType,
                actionDate: actionDate,
                amount: amount,
                resultingQuantity: resultingQuantity,
                addedDays: addedDays,
                resultingDurationDays: resultingDurationDays,
                sourceItemActionRecordId: sourceItemActionRecordId,
                remark: remark,
                isReverted: isReverted,
                revertedAt: revertedAt,
                revertedByActionRecordId: revertedByActionRecordId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int resourceId,
                required String actionType,
                required int actionDate,
                Value<int?> amount = const Value.absent(),
                Value<int?> resultingQuantity = const Value.absent(),
                Value<int?> addedDays = const Value.absent(),
                Value<int?> resultingDurationDays = const Value.absent(),
                Value<int?> sourceItemActionRecordId = const Value.absent(),
                Value<String?> remark = const Value.absent(),
                Value<bool> isReverted = const Value.absent(),
                Value<int?> revertedAt = const Value.absent(),
                Value<int?> revertedByActionRecordId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ResourceActionRecordsCompanion.insert(
                id: id,
                resourceId: resourceId,
                actionType: actionType,
                actionDate: actionDate,
                amount: amount,
                resultingQuantity: resultingQuantity,
                addedDays: addedDays,
                resultingDurationDays: resultingDurationDays,
                sourceItemActionRecordId: sourceItemActionRecordId,
                remark: remark,
                isReverted: isReverted,
                revertedAt: revertedAt,
                revertedByActionRecordId: revertedByActionRecordId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ResourceActionRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({resourceId = false, sourceItemActionRecordId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (resourceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.resourceId,
                                    referencedTable:
                                        $$ResourceActionRecordsTableReferences
                                            ._resourceIdTable(db),
                                    referencedColumn:
                                        $$ResourceActionRecordsTableReferences
                                            ._resourceIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (sourceItemActionRecordId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn:
                                        table.sourceItemActionRecordId,
                                    referencedTable:
                                        $$ResourceActionRecordsTableReferences
                                            ._sourceItemActionRecordIdTable(db),
                                    referencedColumn:
                                        $$ResourceActionRecordsTableReferences
                                            ._sourceItemActionRecordIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ResourceActionRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ResourceActionRecordsTable,
      ResourceActionRecordRow,
      $$ResourceActionRecordsTableFilterComposer,
      $$ResourceActionRecordsTableOrderingComposer,
      $$ResourceActionRecordsTableAnnotationComposer,
      $$ResourceActionRecordsTableCreateCompanionBuilder,
      $$ResourceActionRecordsTableUpdateCompanionBuilder,
      (ResourceActionRecordRow, $$ResourceActionRecordsTableReferences),
      ResourceActionRecordRow,
      PrefetchHooks Function({bool resourceId, bool sourceItemActionRecordId})
    >;
typedef $$StageTrackersTableCreateCompanionBuilder =
    StageTrackersCompanion Function({
      Value<int> id,
      required int packId,
      required String title,
      Value<String?> subjectName,
      required int trackingStartDate,
      Value<int?> trackingEndDate,
      Value<String> status,
      Value<bool> isSystemDefault,
      Value<String?> systemKey,
      Value<bool> isHidden,
      required int createdAt,
      required int updatedAt,
    });
typedef $$StageTrackersTableUpdateCompanionBuilder =
    StageTrackersCompanion Function({
      Value<int> id,
      Value<int> packId,
      Value<String> title,
      Value<String?> subjectName,
      Value<int> trackingStartDate,
      Value<int?> trackingEndDate,
      Value<String> status,
      Value<bool> isSystemDefault,
      Value<String?> systemKey,
      Value<bool> isHidden,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$StageTrackersTableReferences
    extends
        BaseReferences<_$AppDatabase, $StageTrackersTable, StageTrackerRow> {
  $$StageTrackersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ItemPacksTable _packIdTable(_$AppDatabase db) =>
      db.itemPacks.createAlias(
        $_aliasNameGenerator(db.stageTrackers.packId, db.itemPacks.id),
      );

  $$ItemPacksTableProcessedTableManager get packId {
    final $_column = $_itemColumn<int>('pack_id')!;

    final manager = $$ItemPacksTableTableManager(
      $_db,
      $_db.itemPacks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_packIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StageRulesTable, List<StageRuleRow>>
  _stageRulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stageRules,
    aliasName: $_aliasNameGenerator(
      db.stageTrackers.id,
      db.stageRules.stageTrackerId,
    ),
  );

  $$StageRulesTableProcessedTableManager get stageRulesRefs {
    final manager = $$StageRulesTableTableManager(
      $_db,
      $_db.stageRules,
    ).filter((f) => f.stageTrackerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stageRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StageRecordsTable, List<StageRecordRow>>
  _stageRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stageRecords,
    aliasName: $_aliasNameGenerator(
      db.stageTrackers.id,
      db.stageRecords.stageTrackerId,
    ),
  );

  $$StageRecordsTableProcessedTableManager get stageRecordsRefs {
    final manager = $$StageRecordsTableTableManager(
      $_db,
      $_db.stageRecords,
    ).filter((f) => f.stageTrackerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stageRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StageTrackersTableFilterComposer
    extends Composer<_$AppDatabase, $StageTrackersTable> {
  $$StageTrackersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectName => $composableBuilder(
    column: $table.subjectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackingStartDate => $composableBuilder(
    column: $table.trackingStartDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackingEndDate => $composableBuilder(
    column: $table.trackingEndDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystemDefault => $composableBuilder(
    column: $table.isSystemDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get systemKey => $composableBuilder(
    column: $table.systemKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemPacksTableFilterComposer get packId {
    final $$ItemPacksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.itemPacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemPacksTableFilterComposer(
            $db: $db,
            $table: $db.itemPacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> stageRulesRefs(
    Expression<bool> Function($$StageRulesTableFilterComposer f) f,
  ) {
    final $$StageRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stageRules,
      getReferencedColumn: (t) => t.stageTrackerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageRulesTableFilterComposer(
            $db: $db,
            $table: $db.stageRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> stageRecordsRefs(
    Expression<bool> Function($$StageRecordsTableFilterComposer f) f,
  ) {
    final $$StageRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stageRecords,
      getReferencedColumn: (t) => t.stageTrackerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageRecordsTableFilterComposer(
            $db: $db,
            $table: $db.stageRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StageTrackersTableOrderingComposer
    extends Composer<_$AppDatabase, $StageTrackersTable> {
  $$StageTrackersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectName => $composableBuilder(
    column: $table.subjectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackingStartDate => $composableBuilder(
    column: $table.trackingStartDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackingEndDate => $composableBuilder(
    column: $table.trackingEndDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystemDefault => $composableBuilder(
    column: $table.isSystemDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get systemKey => $composableBuilder(
    column: $table.systemKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemPacksTableOrderingComposer get packId {
    final $$ItemPacksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.itemPacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemPacksTableOrderingComposer(
            $db: $db,
            $table: $db.itemPacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StageTrackersTableAnnotationComposer
    extends Composer<_$AppDatabase, $StageTrackersTable> {
  $$StageTrackersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subjectName => $composableBuilder(
    column: $table.subjectName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trackingStartDate => $composableBuilder(
    column: $table.trackingStartDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trackingEndDate => $composableBuilder(
    column: $table.trackingEndDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isSystemDefault => $composableBuilder(
    column: $table.isSystemDefault,
    builder: (column) => column,
  );

  GeneratedColumn<String> get systemKey =>
      $composableBuilder(column: $table.systemKey, builder: (column) => column);

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ItemPacksTableAnnotationComposer get packId {
    final $$ItemPacksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.itemPacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemPacksTableAnnotationComposer(
            $db: $db,
            $table: $db.itemPacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> stageRulesRefs<T extends Object>(
    Expression<T> Function($$StageRulesTableAnnotationComposer a) f,
  ) {
    final $$StageRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stageRules,
      getReferencedColumn: (t) => t.stageTrackerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.stageRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> stageRecordsRefs<T extends Object>(
    Expression<T> Function($$StageRecordsTableAnnotationComposer a) f,
  ) {
    final $$StageRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stageRecords,
      getReferencedColumn: (t) => t.stageTrackerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.stageRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StageTrackersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StageTrackersTable,
          StageTrackerRow,
          $$StageTrackersTableFilterComposer,
          $$StageTrackersTableOrderingComposer,
          $$StageTrackersTableAnnotationComposer,
          $$StageTrackersTableCreateCompanionBuilder,
          $$StageTrackersTableUpdateCompanionBuilder,
          (StageTrackerRow, $$StageTrackersTableReferences),
          StageTrackerRow,
          PrefetchHooks Function({
            bool packId,
            bool stageRulesRefs,
            bool stageRecordsRefs,
          })
        > {
  $$StageTrackersTableTableManager(_$AppDatabase db, $StageTrackersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StageTrackersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StageTrackersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StageTrackersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> packId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> subjectName = const Value.absent(),
                Value<int> trackingStartDate = const Value.absent(),
                Value<int?> trackingEndDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isSystemDefault = const Value.absent(),
                Value<String?> systemKey = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => StageTrackersCompanion(
                id: id,
                packId: packId,
                title: title,
                subjectName: subjectName,
                trackingStartDate: trackingStartDate,
                trackingEndDate: trackingEndDate,
                status: status,
                isSystemDefault: isSystemDefault,
                systemKey: systemKey,
                isHidden: isHidden,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int packId,
                required String title,
                Value<String?> subjectName = const Value.absent(),
                required int trackingStartDate,
                Value<int?> trackingEndDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isSystemDefault = const Value.absent(),
                Value<String?> systemKey = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => StageTrackersCompanion.insert(
                id: id,
                packId: packId,
                title: title,
                subjectName: subjectName,
                trackingStartDate: trackingStartDate,
                trackingEndDate: trackingEndDate,
                status: status,
                isSystemDefault: isSystemDefault,
                systemKey: systemKey,
                isHidden: isHidden,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StageTrackersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                packId = false,
                stageRulesRefs = false,
                stageRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (stageRulesRefs) db.stageRules,
                    if (stageRecordsRefs) db.stageRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (packId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.packId,
                                    referencedTable:
                                        $$StageTrackersTableReferences
                                            ._packIdTable(db),
                                    referencedColumn:
                                        $$StageTrackersTableReferences
                                            ._packIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (stageRulesRefs)
                        await $_getPrefetchedData<
                          StageTrackerRow,
                          $StageTrackersTable,
                          StageRuleRow
                        >(
                          currentTable: table,
                          referencedTable: $$StageTrackersTableReferences
                              ._stageRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StageTrackersTableReferences(
                                db,
                                table,
                                p0,
                              ).stageRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.stageTrackerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (stageRecordsRefs)
                        await $_getPrefetchedData<
                          StageTrackerRow,
                          $StageTrackersTable,
                          StageRecordRow
                        >(
                          currentTable: table,
                          referencedTable: $$StageTrackersTableReferences
                              ._stageRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StageTrackersTableReferences(
                                db,
                                table,
                                p0,
                              ).stageRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.stageTrackerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StageTrackersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StageTrackersTable,
      StageTrackerRow,
      $$StageTrackersTableFilterComposer,
      $$StageTrackersTableOrderingComposer,
      $$StageTrackersTableAnnotationComposer,
      $$StageTrackersTableCreateCompanionBuilder,
      $$StageTrackersTableUpdateCompanionBuilder,
      (StageTrackerRow, $$StageTrackersTableReferences),
      StageTrackerRow,
      PrefetchHooks Function({
        bool packId,
        bool stageRulesRefs,
        bool stageRecordsRefs,
      })
    >;
typedef $$StageRulesTableCreateCompanionBuilder =
    StageRulesCompanion Function({
      Value<int> id,
      required int stageTrackerId,
      required String type,
      required int intervalValue,
      required String intervalUnit,
      Value<String?> labelTemplate,
      Value<int?> reminderOffsetDays,
      Value<String> status,
      required int createdAt,
      required int updatedAt,
    });
typedef $$StageRulesTableUpdateCompanionBuilder =
    StageRulesCompanion Function({
      Value<int> id,
      Value<int> stageTrackerId,
      Value<String> type,
      Value<int> intervalValue,
      Value<String> intervalUnit,
      Value<String?> labelTemplate,
      Value<int?> reminderOffsetDays,
      Value<String> status,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$StageRulesTableReferences
    extends BaseReferences<_$AppDatabase, $StageRulesTable, StageRuleRow> {
  $$StageRulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StageTrackersTable _stageTrackerIdTable(_$AppDatabase db) =>
      db.stageTrackers.createAlias(
        $_aliasNameGenerator(db.stageRules.stageTrackerId, db.stageTrackers.id),
      );

  $$StageTrackersTableProcessedTableManager get stageTrackerId {
    final $_column = $_itemColumn<int>('stage_tracker_id')!;

    final manager = $$StageTrackersTableTableManager(
      $_db,
      $_db.stageTrackers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stageTrackerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StageRecordsTable, List<StageRecordRow>>
  _stageRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stageRecords,
    aliasName: $_aliasNameGenerator(
      db.stageRules.id,
      db.stageRecords.stageRuleId,
    ),
  );

  $$StageRecordsTableProcessedTableManager get stageRecordsRefs {
    final manager = $$StageRecordsTableTableManager(
      $_db,
      $_db.stageRecords,
    ).filter((f) => f.stageRuleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stageRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StageRulesTableFilterComposer
    extends Composer<_$AppDatabase, $StageRulesTable> {
  $$StageRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalValue => $composableBuilder(
    column: $table.intervalValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intervalUnit => $composableBuilder(
    column: $table.intervalUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelTemplate => $composableBuilder(
    column: $table.labelTemplate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderOffsetDays => $composableBuilder(
    column: $table.reminderOffsetDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StageTrackersTableFilterComposer get stageTrackerId {
    final $$StageTrackersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageTrackerId,
      referencedTable: $db.stageTrackers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageTrackersTableFilterComposer(
            $db: $db,
            $table: $db.stageTrackers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> stageRecordsRefs(
    Expression<bool> Function($$StageRecordsTableFilterComposer f) f,
  ) {
    final $$StageRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stageRecords,
      getReferencedColumn: (t) => t.stageRuleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageRecordsTableFilterComposer(
            $db: $db,
            $table: $db.stageRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StageRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $StageRulesTable> {
  $$StageRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalValue => $composableBuilder(
    column: $table.intervalValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intervalUnit => $composableBuilder(
    column: $table.intervalUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelTemplate => $composableBuilder(
    column: $table.labelTemplate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderOffsetDays => $composableBuilder(
    column: $table.reminderOffsetDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StageTrackersTableOrderingComposer get stageTrackerId {
    final $$StageTrackersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageTrackerId,
      referencedTable: $db.stageTrackers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageTrackersTableOrderingComposer(
            $db: $db,
            $table: $db.stageTrackers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StageRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StageRulesTable> {
  $$StageRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get intervalValue => $composableBuilder(
    column: $table.intervalValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get intervalUnit => $composableBuilder(
    column: $table.intervalUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get labelTemplate => $composableBuilder(
    column: $table.labelTemplate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderOffsetDays => $composableBuilder(
    column: $table.reminderOffsetDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$StageTrackersTableAnnotationComposer get stageTrackerId {
    final $$StageTrackersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageTrackerId,
      referencedTable: $db.stageTrackers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageTrackersTableAnnotationComposer(
            $db: $db,
            $table: $db.stageTrackers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> stageRecordsRefs<T extends Object>(
    Expression<T> Function($$StageRecordsTableAnnotationComposer a) f,
  ) {
    final $$StageRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stageRecords,
      getReferencedColumn: (t) => t.stageRuleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.stageRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StageRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StageRulesTable,
          StageRuleRow,
          $$StageRulesTableFilterComposer,
          $$StageRulesTableOrderingComposer,
          $$StageRulesTableAnnotationComposer,
          $$StageRulesTableCreateCompanionBuilder,
          $$StageRulesTableUpdateCompanionBuilder,
          (StageRuleRow, $$StageRulesTableReferences),
          StageRuleRow,
          PrefetchHooks Function({bool stageTrackerId, bool stageRecordsRefs})
        > {
  $$StageRulesTableTableManager(_$AppDatabase db, $StageRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StageRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StageRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StageRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> stageTrackerId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> intervalValue = const Value.absent(),
                Value<String> intervalUnit = const Value.absent(),
                Value<String?> labelTemplate = const Value.absent(),
                Value<int?> reminderOffsetDays = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => StageRulesCompanion(
                id: id,
                stageTrackerId: stageTrackerId,
                type: type,
                intervalValue: intervalValue,
                intervalUnit: intervalUnit,
                labelTemplate: labelTemplate,
                reminderOffsetDays: reminderOffsetDays,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int stageTrackerId,
                required String type,
                required int intervalValue,
                required String intervalUnit,
                Value<String?> labelTemplate = const Value.absent(),
                Value<int?> reminderOffsetDays = const Value.absent(),
                Value<String> status = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => StageRulesCompanion.insert(
                id: id,
                stageTrackerId: stageTrackerId,
                type: type,
                intervalValue: intervalValue,
                intervalUnit: intervalUnit,
                labelTemplate: labelTemplate,
                reminderOffsetDays: reminderOffsetDays,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StageRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({stageTrackerId = false, stageRecordsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (stageRecordsRefs) db.stageRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (stageTrackerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.stageTrackerId,
                                    referencedTable: $$StageRulesTableReferences
                                        ._stageTrackerIdTable(db),
                                    referencedColumn:
                                        $$StageRulesTableReferences
                                            ._stageTrackerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (stageRecordsRefs)
                        await $_getPrefetchedData<
                          StageRuleRow,
                          $StageRulesTable,
                          StageRecordRow
                        >(
                          currentTable: table,
                          referencedTable: $$StageRulesTableReferences
                              ._stageRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StageRulesTableReferences(
                                db,
                                table,
                                p0,
                              ).stageRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.stageRuleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StageRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StageRulesTable,
      StageRuleRow,
      $$StageRulesTableFilterComposer,
      $$StageRulesTableOrderingComposer,
      $$StageRulesTableAnnotationComposer,
      $$StageRulesTableCreateCompanionBuilder,
      $$StageRulesTableUpdateCompanionBuilder,
      (StageRuleRow, $$StageRulesTableReferences),
      StageRuleRow,
      PrefetchHooks Function({bool stageTrackerId, bool stageRecordsRefs})
    >;
typedef $$StageRecordsTableCreateCompanionBuilder =
    StageRecordsCompanion Function({
      Value<int> id,
      required int stageTrackerId,
      Value<int?> stageRuleId,
      required String sourceType,
      Value<int?> occurrenceIndex,
      required int occurrenceDate,
      Value<int?> relativeAmount,
      Value<String?> relativeUnit,
      Value<String> status,
      required String label,
      Value<String?> note,
      Value<int?> reminderOffsetDays,
      required int createdAt,
      required int updatedAt,
    });
typedef $$StageRecordsTableUpdateCompanionBuilder =
    StageRecordsCompanion Function({
      Value<int> id,
      Value<int> stageTrackerId,
      Value<int?> stageRuleId,
      Value<String> sourceType,
      Value<int?> occurrenceIndex,
      Value<int> occurrenceDate,
      Value<int?> relativeAmount,
      Value<String?> relativeUnit,
      Value<String> status,
      Value<String> label,
      Value<String?> note,
      Value<int?> reminderOffsetDays,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$StageRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $StageRecordsTable, StageRecordRow> {
  $$StageRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StageTrackersTable _stageTrackerIdTable(_$AppDatabase db) =>
      db.stageTrackers.createAlias(
        $_aliasNameGenerator(
          db.stageRecords.stageTrackerId,
          db.stageTrackers.id,
        ),
      );

  $$StageTrackersTableProcessedTableManager get stageTrackerId {
    final $_column = $_itemColumn<int>('stage_tracker_id')!;

    final manager = $$StageTrackersTableTableManager(
      $_db,
      $_db.stageTrackers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stageTrackerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StageRulesTable _stageRuleIdTable(_$AppDatabase db) =>
      db.stageRules.createAlias(
        $_aliasNameGenerator(db.stageRecords.stageRuleId, db.stageRules.id),
      );

  $$StageRulesTableProcessedTableManager? get stageRuleId {
    final $_column = $_itemColumn<int>('stage_rule_id');
    if ($_column == null) return null;
    final manager = $$StageRulesTableTableManager(
      $_db,
      $_db.stageRules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stageRuleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StageRelatedItemsTable, List<StageRelatedItemRow>>
  _stageRelatedItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.stageRelatedItems,
        aliasName: $_aliasNameGenerator(
          db.stageRecords.id,
          db.stageRelatedItems.stageRecordId,
        ),
      );

  $$StageRelatedItemsTableProcessedTableManager get stageRelatedItemsRefs {
    final manager = $$StageRelatedItemsTableTableManager(
      $_db,
      $_db.stageRelatedItems,
    ).filter((f) => f.stageRecordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _stageRelatedItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StageRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $StageRecordsTable> {
  $$StageRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurrenceIndex => $composableBuilder(
    column: $table.occurrenceIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get relativeAmount => $composableBuilder(
    column: $table.relativeAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativeUnit => $composableBuilder(
    column: $table.relativeUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderOffsetDays => $composableBuilder(
    column: $table.reminderOffsetDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StageTrackersTableFilterComposer get stageTrackerId {
    final $$StageTrackersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageTrackerId,
      referencedTable: $db.stageTrackers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageTrackersTableFilterComposer(
            $db: $db,
            $table: $db.stageTrackers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StageRulesTableFilterComposer get stageRuleId {
    final $$StageRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageRuleId,
      referencedTable: $db.stageRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageRulesTableFilterComposer(
            $db: $db,
            $table: $db.stageRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> stageRelatedItemsRefs(
    Expression<bool> Function($$StageRelatedItemsTableFilterComposer f) f,
  ) {
    final $$StageRelatedItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stageRelatedItems,
      getReferencedColumn: (t) => t.stageRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageRelatedItemsTableFilterComposer(
            $db: $db,
            $table: $db.stageRelatedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StageRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $StageRecordsTable> {
  $$StageRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurrenceIndex => $composableBuilder(
    column: $table.occurrenceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get relativeAmount => $composableBuilder(
    column: $table.relativeAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativeUnit => $composableBuilder(
    column: $table.relativeUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderOffsetDays => $composableBuilder(
    column: $table.reminderOffsetDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StageTrackersTableOrderingComposer get stageTrackerId {
    final $$StageTrackersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageTrackerId,
      referencedTable: $db.stageTrackers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageTrackersTableOrderingComposer(
            $db: $db,
            $table: $db.stageTrackers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StageRulesTableOrderingComposer get stageRuleId {
    final $$StageRulesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageRuleId,
      referencedTable: $db.stageRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageRulesTableOrderingComposer(
            $db: $db,
            $table: $db.stageRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StageRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StageRecordsTable> {
  $$StageRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get occurrenceIndex => $composableBuilder(
    column: $table.occurrenceIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get relativeAmount => $composableBuilder(
    column: $table.relativeAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relativeUnit => $composableBuilder(
    column: $table.relativeUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get reminderOffsetDays => $composableBuilder(
    column: $table.reminderOffsetDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$StageTrackersTableAnnotationComposer get stageTrackerId {
    final $$StageTrackersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageTrackerId,
      referencedTable: $db.stageTrackers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageTrackersTableAnnotationComposer(
            $db: $db,
            $table: $db.stageTrackers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StageRulesTableAnnotationComposer get stageRuleId {
    final $$StageRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageRuleId,
      referencedTable: $db.stageRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.stageRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> stageRelatedItemsRefs<T extends Object>(
    Expression<T> Function($$StageRelatedItemsTableAnnotationComposer a) f,
  ) {
    final $$StageRelatedItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.stageRelatedItems,
          getReferencedColumn: (t) => t.stageRecordId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$StageRelatedItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.stageRelatedItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$StageRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StageRecordsTable,
          StageRecordRow,
          $$StageRecordsTableFilterComposer,
          $$StageRecordsTableOrderingComposer,
          $$StageRecordsTableAnnotationComposer,
          $$StageRecordsTableCreateCompanionBuilder,
          $$StageRecordsTableUpdateCompanionBuilder,
          (StageRecordRow, $$StageRecordsTableReferences),
          StageRecordRow,
          PrefetchHooks Function({
            bool stageTrackerId,
            bool stageRuleId,
            bool stageRelatedItemsRefs,
          })
        > {
  $$StageRecordsTableTableManager(_$AppDatabase db, $StageRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StageRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StageRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StageRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> stageTrackerId = const Value.absent(),
                Value<int?> stageRuleId = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<int?> occurrenceIndex = const Value.absent(),
                Value<int> occurrenceDate = const Value.absent(),
                Value<int?> relativeAmount = const Value.absent(),
                Value<String?> relativeUnit = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> reminderOffsetDays = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => StageRecordsCompanion(
                id: id,
                stageTrackerId: stageTrackerId,
                stageRuleId: stageRuleId,
                sourceType: sourceType,
                occurrenceIndex: occurrenceIndex,
                occurrenceDate: occurrenceDate,
                relativeAmount: relativeAmount,
                relativeUnit: relativeUnit,
                status: status,
                label: label,
                note: note,
                reminderOffsetDays: reminderOffsetDays,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int stageTrackerId,
                Value<int?> stageRuleId = const Value.absent(),
                required String sourceType,
                Value<int?> occurrenceIndex = const Value.absent(),
                required int occurrenceDate,
                Value<int?> relativeAmount = const Value.absent(),
                Value<String?> relativeUnit = const Value.absent(),
                Value<String> status = const Value.absent(),
                required String label,
                Value<String?> note = const Value.absent(),
                Value<int?> reminderOffsetDays = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => StageRecordsCompanion.insert(
                id: id,
                stageTrackerId: stageTrackerId,
                stageRuleId: stageRuleId,
                sourceType: sourceType,
                occurrenceIndex: occurrenceIndex,
                occurrenceDate: occurrenceDate,
                relativeAmount: relativeAmount,
                relativeUnit: relativeUnit,
                status: status,
                label: label,
                note: note,
                reminderOffsetDays: reminderOffsetDays,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StageRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                stageTrackerId = false,
                stageRuleId = false,
                stageRelatedItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (stageRelatedItemsRefs) db.stageRelatedItems,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (stageTrackerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.stageTrackerId,
                                    referencedTable:
                                        $$StageRecordsTableReferences
                                            ._stageTrackerIdTable(db),
                                    referencedColumn:
                                        $$StageRecordsTableReferences
                                            ._stageTrackerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (stageRuleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.stageRuleId,
                                    referencedTable:
                                        $$StageRecordsTableReferences
                                            ._stageRuleIdTable(db),
                                    referencedColumn:
                                        $$StageRecordsTableReferences
                                            ._stageRuleIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (stageRelatedItemsRefs)
                        await $_getPrefetchedData<
                          StageRecordRow,
                          $StageRecordsTable,
                          StageRelatedItemRow
                        >(
                          currentTable: table,
                          referencedTable: $$StageRecordsTableReferences
                              ._stageRelatedItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StageRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).stageRelatedItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.stageRecordId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StageRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StageRecordsTable,
      StageRecordRow,
      $$StageRecordsTableFilterComposer,
      $$StageRecordsTableOrderingComposer,
      $$StageRecordsTableAnnotationComposer,
      $$StageRecordsTableCreateCompanionBuilder,
      $$StageRecordsTableUpdateCompanionBuilder,
      (StageRecordRow, $$StageRecordsTableReferences),
      StageRecordRow,
      PrefetchHooks Function({
        bool stageTrackerId,
        bool stageRuleId,
        bool stageRelatedItemsRefs,
      })
    >;
typedef $$StageRelatedItemsTableCreateCompanionBuilder =
    StageRelatedItemsCompanion Function({
      Value<int> id,
      required int stageRecordId,
      required int itemId,
      required int createdAt,
      required int updatedAt,
    });
typedef $$StageRelatedItemsTableUpdateCompanionBuilder =
    StageRelatedItemsCompanion Function({
      Value<int> id,
      Value<int> stageRecordId,
      Value<int> itemId,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$StageRelatedItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $StageRelatedItemsTable,
          StageRelatedItemRow
        > {
  $$StageRelatedItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StageRecordsTable _stageRecordIdTable(_$AppDatabase db) =>
      db.stageRecords.createAlias(
        $_aliasNameGenerator(
          db.stageRelatedItems.stageRecordId,
          db.stageRecords.id,
        ),
      );

  $$StageRecordsTableProcessedTableManager get stageRecordId {
    final $_column = $_itemColumn<int>('stage_record_id')!;

    final manager = $$StageRecordsTableTableManager(
      $_db,
      $_db.stageRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stageRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.stageRelatedItems.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StageRelatedItemsTableFilterComposer
    extends Composer<_$AppDatabase, $StageRelatedItemsTable> {
  $$StageRelatedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StageRecordsTableFilterComposer get stageRecordId {
    final $$StageRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageRecordId,
      referencedTable: $db.stageRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageRecordsTableFilterComposer(
            $db: $db,
            $table: $db.stageRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StageRelatedItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $StageRelatedItemsTable> {
  $$StageRelatedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StageRecordsTableOrderingComposer get stageRecordId {
    final $$StageRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageRecordId,
      referencedTable: $db.stageRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.stageRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StageRelatedItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StageRelatedItemsTable> {
  $$StageRelatedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$StageRecordsTableAnnotationComposer get stageRecordId {
    final $$StageRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageRecordId,
      referencedTable: $db.stageRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.stageRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StageRelatedItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StageRelatedItemsTable,
          StageRelatedItemRow,
          $$StageRelatedItemsTableFilterComposer,
          $$StageRelatedItemsTableOrderingComposer,
          $$StageRelatedItemsTableAnnotationComposer,
          $$StageRelatedItemsTableCreateCompanionBuilder,
          $$StageRelatedItemsTableUpdateCompanionBuilder,
          (StageRelatedItemRow, $$StageRelatedItemsTableReferences),
          StageRelatedItemRow,
          PrefetchHooks Function({bool stageRecordId, bool itemId})
        > {
  $$StageRelatedItemsTableTableManager(
    _$AppDatabase db,
    $StageRelatedItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StageRelatedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StageRelatedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StageRelatedItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> stageRecordId = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => StageRelatedItemsCompanion(
                id: id,
                stageRecordId: stageRecordId,
                itemId: itemId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int stageRecordId,
                required int itemId,
                required int createdAt,
                required int updatedAt,
              }) => StageRelatedItemsCompanion.insert(
                id: id,
                stageRecordId: stageRecordId,
                itemId: itemId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StageRelatedItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({stageRecordId = false, itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (stageRecordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.stageRecordId,
                                referencedTable:
                                    $$StageRelatedItemsTableReferences
                                        ._stageRecordIdTable(db),
                                referencedColumn:
                                    $$StageRelatedItemsTableReferences
                                        ._stageRecordIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable:
                                    $$StageRelatedItemsTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$StageRelatedItemsTableReferences
                                        ._itemIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StageRelatedItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StageRelatedItemsTable,
      StageRelatedItemRow,
      $$StageRelatedItemsTableFilterComposer,
      $$StageRelatedItemsTableOrderingComposer,
      $$StageRelatedItemsTableAnnotationComposer,
      $$StageRelatedItemsTableCreateCompanionBuilder,
      $$StageRelatedItemsTableUpdateCompanionBuilder,
      (StageRelatedItemRow, $$StageRelatedItemsTableReferences),
      StageRelatedItemRow,
      PrefetchHooks Function({bool stageRecordId, bool itemId})
    >;
typedef $$AppSettingsEntriesTableCreateCompanionBuilder =
    AppSettingsEntriesCompanion Function({
      Value<int> id,
      Value<String> reminderTone,
      Value<String> notificationReminderTime,
      required int createdAt,
      required int updatedAt,
    });
typedef $$AppSettingsEntriesTableUpdateCompanionBuilder =
    AppSettingsEntriesCompanion Function({
      Value<int> id,
      Value<String> reminderTone,
      Value<String> notificationReminderTime,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

class $$AppSettingsEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsEntriesTable> {
  $$AppSettingsEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTone => $composableBuilder(
    column: $table.reminderTone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notificationReminderTime => $composableBuilder(
    column: $table.notificationReminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsEntriesTable> {
  $$AppSettingsEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTone => $composableBuilder(
    column: $table.reminderTone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notificationReminderTime => $composableBuilder(
    column: $table.notificationReminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsEntriesTable> {
  $$AppSettingsEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reminderTone => $composableBuilder(
    column: $table.reminderTone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notificationReminderTime => $composableBuilder(
    column: $table.notificationReminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsEntriesTable,
          AppSettingsRow,
          $$AppSettingsEntriesTableFilterComposer,
          $$AppSettingsEntriesTableOrderingComposer,
          $$AppSettingsEntriesTableAnnotationComposer,
          $$AppSettingsEntriesTableCreateCompanionBuilder,
          $$AppSettingsEntriesTableUpdateCompanionBuilder,
          (
            AppSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $AppSettingsEntriesTable,
              AppSettingsRow
            >,
          ),
          AppSettingsRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsEntriesTableTableManager(
    _$AppDatabase db,
    $AppSettingsEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> reminderTone = const Value.absent(),
                Value<String> notificationReminderTime = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => AppSettingsEntriesCompanion(
                id: id,
                reminderTone: reminderTone,
                notificationReminderTime: notificationReminderTime,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> reminderTone = const Value.absent(),
                Value<String> notificationReminderTime = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => AppSettingsEntriesCompanion.insert(
                id: id,
                reminderTone: reminderTone,
                notificationReminderTime: notificationReminderTime,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsEntriesTable,
      AppSettingsRow,
      $$AppSettingsEntriesTableFilterComposer,
      $$AppSettingsEntriesTableOrderingComposer,
      $$AppSettingsEntriesTableAnnotationComposer,
      $$AppSettingsEntriesTableCreateCompanionBuilder,
      $$AppSettingsEntriesTableUpdateCompanionBuilder,
      (
        AppSettingsRow,
        BaseReferences<_$AppDatabase, $AppSettingsEntriesTable, AppSettingsRow>,
      ),
      AppSettingsRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ItemPacksTableTableManager get itemPacks =>
      $$ItemPacksTableTableManager(_db, _db.itemPacks);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$PackTemplatesTableTableManager get packTemplates =>
      $$PackTemplatesTableTableManager(_db, _db.packTemplates);
  $$PackTemplateItemsTableTableManager get packTemplateItems =>
      $$PackTemplateItemsTableTableManager(_db, _db.packTemplateItems);
  $$ResourcesTableTableManager get resources =>
      $$ResourcesTableTableManager(_db, _db.resources);
  $$ResourceConsumptionRulesTableTableManager get resourceConsumptionRules =>
      $$ResourceConsumptionRulesTableTableManager(
        _db,
        _db.resourceConsumptionRules,
      );
  $$ItemActionRecordsTableTableManager get itemActionRecords =>
      $$ItemActionRecordsTableTableManager(_db, _db.itemActionRecords);
  $$ResourceActionRecordsTableTableManager get resourceActionRecords =>
      $$ResourceActionRecordsTableTableManager(_db, _db.resourceActionRecords);
  $$StageTrackersTableTableManager get stageTrackers =>
      $$StageTrackersTableTableManager(_db, _db.stageTrackers);
  $$StageRulesTableTableManager get stageRules =>
      $$StageRulesTableTableManager(_db, _db.stageRules);
  $$StageRecordsTableTableManager get stageRecords =>
      $$StageRecordsTableTableManager(_db, _db.stageRecords);
  $$StageRelatedItemsTableTableManager get stageRelatedItems =>
      $$StageRelatedItemsTableTableManager(_db, _db.stageRelatedItems);
  $$AppSettingsEntriesTableTableManager get appSettingsEntries =>
      $$AppSettingsEntriesTableTableManager(_db, _db.appSettingsEntries);
}
