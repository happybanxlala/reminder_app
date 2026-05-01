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
  final String status;
  final bool isSystemDefault;
  final int createdAt;
  final int updatedAt;
  const ItemPackRow({
    required this.id,
    required this.title,
    this.description,
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
    String? status,
    bool? isSystemDefault,
    int? createdAt,
    int? updatedAt,
  }) => ItemPackRow(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
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
          other.status == this.status &&
          other.isSystemDefault == this.isSystemDefault &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ItemPacksCompanion extends UpdateCompanion<ItemPackRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> status;
  final Value<bool> isSystemDefault;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ItemPacksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.isSystemDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ItemPacksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
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
    Expression<String>? status,
    Expression<bool>? isSystemDefault,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
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
    Value<String>? status,
    Value<bool>? isSystemDefault,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ItemPacksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
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
  static const VerificationMeta _resourceAnchorDateMeta =
      const VerificationMeta('resourceAnchorDate');
  @override
  late final GeneratedColumn<int> resourceAnchorDate = GeneratedColumn<int>(
    'resource_anchor_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resourceDurationDaysMeta =
      const VerificationMeta('resourceDurationDays');
  @override
  late final GeneratedColumn<int> resourceDurationDays = GeneratedColumn<int>(
    'resource_duration_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resourceExpectedBeforeDaysMeta =
      const VerificationMeta('resourceExpectedBeforeDays');
  @override
  late final GeneratedColumn<int> resourceExpectedBeforeDays =
      GeneratedColumn<int>(
        'resource_expected_before_days',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resourceWarningBeforeDaysMeta =
      const VerificationMeta('resourceWarningBeforeDays');
  @override
  late final GeneratedColumn<int> resourceWarningBeforeDays =
      GeneratedColumn<int>(
        'resource_warning_before_days',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resourceDangerBeforeDaysMeta =
      const VerificationMeta('resourceDangerBeforeDays');
  @override
  late final GeneratedColumn<int> resourceDangerBeforeDays =
      GeneratedColumn<int>(
        'resource_danger_before_days',
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
    fixedScheduleType,
    fixedScheduleInterval,
    fixedMonthlyDay,
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
    resourceAnchorDate,
    resourceDurationDays,
    resourceExpectedBeforeDays,
    resourceWarningBeforeDays,
    resourceDangerBeforeDays,
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
    if (data.containsKey('resource_anchor_date')) {
      context.handle(
        _resourceAnchorDateMeta,
        resourceAnchorDate.isAcceptableOrUnknown(
          data['resource_anchor_date']!,
          _resourceAnchorDateMeta,
        ),
      );
    }
    if (data.containsKey('resource_duration_days')) {
      context.handle(
        _resourceDurationDaysMeta,
        resourceDurationDays.isAcceptableOrUnknown(
          data['resource_duration_days']!,
          _resourceDurationDaysMeta,
        ),
      );
    }
    if (data.containsKey('resource_expected_before_days')) {
      context.handle(
        _resourceExpectedBeforeDaysMeta,
        resourceExpectedBeforeDays.isAcceptableOrUnknown(
          data['resource_expected_before_days']!,
          _resourceExpectedBeforeDaysMeta,
        ),
      );
    }
    if (data.containsKey('resource_warning_before_days')) {
      context.handle(
        _resourceWarningBeforeDaysMeta,
        resourceWarningBeforeDays.isAcceptableOrUnknown(
          data['resource_warning_before_days']!,
          _resourceWarningBeforeDaysMeta,
        ),
      );
    }
    if (data.containsKey('resource_danger_before_days')) {
      context.handle(
        _resourceDangerBeforeDaysMeta,
        resourceDangerBeforeDays.isAcceptableOrUnknown(
          data['resource_danger_before_days']!,
          _resourceDangerBeforeDaysMeta,
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
      resourceAnchorDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resource_anchor_date'],
      ),
      resourceDurationDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resource_duration_days'],
      ),
      resourceExpectedBeforeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resource_expected_before_days'],
      ),
      resourceWarningBeforeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resource_warning_before_days'],
      ),
      resourceDangerBeforeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resource_danger_before_days'],
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
  final String? fixedScheduleType;
  final int? fixedScheduleInterval;
  final int? fixedMonthlyDay;
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
  final int? resourceAnchorDate;
  final int? resourceDurationDays;
  final int? resourceExpectedBeforeDays;
  final int? resourceWarningBeforeDays;
  final int? resourceDangerBeforeDays;
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
    this.fixedScheduleType,
    this.fixedScheduleInterval,
    this.fixedMonthlyDay,
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
    this.resourceAnchorDate,
    this.resourceDurationDays,
    this.resourceExpectedBeforeDays,
    this.resourceWarningBeforeDays,
    this.resourceDangerBeforeDays,
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
    if (!nullToAbsent || fixedScheduleType != null) {
      map['fixed_schedule_type'] = Variable<String>(fixedScheduleType);
    }
    if (!nullToAbsent || fixedScheduleInterval != null) {
      map['fixed_schedule_interval'] = Variable<int>(fixedScheduleInterval);
    }
    if (!nullToAbsent || fixedMonthlyDay != null) {
      map['fixed_monthly_day'] = Variable<int>(fixedMonthlyDay);
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
    if (!nullToAbsent || resourceAnchorDate != null) {
      map['resource_anchor_date'] = Variable<int>(resourceAnchorDate);
    }
    if (!nullToAbsent || resourceDurationDays != null) {
      map['resource_duration_days'] = Variable<int>(resourceDurationDays);
    }
    if (!nullToAbsent || resourceExpectedBeforeDays != null) {
      map['resource_expected_before_days'] = Variable<int>(
        resourceExpectedBeforeDays,
      );
    }
    if (!nullToAbsent || resourceWarningBeforeDays != null) {
      map['resource_warning_before_days'] = Variable<int>(
        resourceWarningBeforeDays,
      );
    }
    if (!nullToAbsent || resourceDangerBeforeDays != null) {
      map['resource_danger_before_days'] = Variable<int>(
        resourceDangerBeforeDays,
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
      fixedScheduleType: fixedScheduleType == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedScheduleType),
      fixedScheduleInterval: fixedScheduleInterval == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedScheduleInterval),
      fixedMonthlyDay: fixedMonthlyDay == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedMonthlyDay),
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
      resourceAnchorDate: resourceAnchorDate == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceAnchorDate),
      resourceDurationDays: resourceDurationDays == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceDurationDays),
      resourceExpectedBeforeDays:
          resourceExpectedBeforeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceExpectedBeforeDays),
      resourceWarningBeforeDays:
          resourceWarningBeforeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceWarningBeforeDays),
      resourceDangerBeforeDays: resourceDangerBeforeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceDangerBeforeDays),
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
      fixedScheduleType: serializer.fromJson<String?>(
        json['fixedScheduleType'],
      ),
      fixedScheduleInterval: serializer.fromJson<int?>(
        json['fixedScheduleInterval'],
      ),
      fixedMonthlyDay: serializer.fromJson<int?>(json['fixedMonthlyDay']),
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
      resourceAnchorDate: serializer.fromJson<int?>(json['resourceAnchorDate']),
      resourceDurationDays: serializer.fromJson<int?>(
        json['resourceDurationDays'],
      ),
      resourceExpectedBeforeDays: serializer.fromJson<int?>(
        json['resourceExpectedBeforeDays'],
      ),
      resourceWarningBeforeDays: serializer.fromJson<int?>(
        json['resourceWarningBeforeDays'],
      ),
      resourceDangerBeforeDays: serializer.fromJson<int?>(
        json['resourceDangerBeforeDays'],
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
      'fixedScheduleType': serializer.toJson<String?>(fixedScheduleType),
      'fixedScheduleInterval': serializer.toJson<int?>(fixedScheduleInterval),
      'fixedMonthlyDay': serializer.toJson<int?>(fixedMonthlyDay),
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
      'resourceAnchorDate': serializer.toJson<int?>(resourceAnchorDate),
      'resourceDurationDays': serializer.toJson<int?>(resourceDurationDays),
      'resourceExpectedBeforeDays': serializer.toJson<int?>(
        resourceExpectedBeforeDays,
      ),
      'resourceWarningBeforeDays': serializer.toJson<int?>(
        resourceWarningBeforeDays,
      ),
      'resourceDangerBeforeDays': serializer.toJson<int?>(
        resourceDangerBeforeDays,
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
    Value<String?> fixedScheduleType = const Value.absent(),
    Value<int?> fixedScheduleInterval = const Value.absent(),
    Value<int?> fixedMonthlyDay = const Value.absent(),
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
    Value<int?> resourceAnchorDate = const Value.absent(),
    Value<int?> resourceDurationDays = const Value.absent(),
    Value<int?> resourceExpectedBeforeDays = const Value.absent(),
    Value<int?> resourceWarningBeforeDays = const Value.absent(),
    Value<int?> resourceDangerBeforeDays = const Value.absent(),
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
    fixedScheduleType: fixedScheduleType.present
        ? fixedScheduleType.value
        : this.fixedScheduleType,
    fixedScheduleInterval: fixedScheduleInterval.present
        ? fixedScheduleInterval.value
        : this.fixedScheduleInterval,
    fixedMonthlyDay: fixedMonthlyDay.present
        ? fixedMonthlyDay.value
        : this.fixedMonthlyDay,
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
    resourceAnchorDate: resourceAnchorDate.present
        ? resourceAnchorDate.value
        : this.resourceAnchorDate,
    resourceDurationDays: resourceDurationDays.present
        ? resourceDurationDays.value
        : this.resourceDurationDays,
    resourceExpectedBeforeDays: resourceExpectedBeforeDays.present
        ? resourceExpectedBeforeDays.value
        : this.resourceExpectedBeforeDays,
    resourceWarningBeforeDays: resourceWarningBeforeDays.present
        ? resourceWarningBeforeDays.value
        : this.resourceWarningBeforeDays,
    resourceDangerBeforeDays: resourceDangerBeforeDays.present
        ? resourceDangerBeforeDays.value
        : this.resourceDangerBeforeDays,
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
      fixedScheduleType: data.fixedScheduleType.present
          ? data.fixedScheduleType.value
          : this.fixedScheduleType,
      fixedScheduleInterval: data.fixedScheduleInterval.present
          ? data.fixedScheduleInterval.value
          : this.fixedScheduleInterval,
      fixedMonthlyDay: data.fixedMonthlyDay.present
          ? data.fixedMonthlyDay.value
          : this.fixedMonthlyDay,
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
      resourceAnchorDate: data.resourceAnchorDate.present
          ? data.resourceAnchorDate.value
          : this.resourceAnchorDate,
      resourceDurationDays: data.resourceDurationDays.present
          ? data.resourceDurationDays.value
          : this.resourceDurationDays,
      resourceExpectedBeforeDays: data.resourceExpectedBeforeDays.present
          ? data.resourceExpectedBeforeDays.value
          : this.resourceExpectedBeforeDays,
      resourceWarningBeforeDays: data.resourceWarningBeforeDays.present
          ? data.resourceWarningBeforeDays.value
          : this.resourceWarningBeforeDays,
      resourceDangerBeforeDays: data.resourceDangerBeforeDays.present
          ? data.resourceDangerBeforeDays.value
          : this.resourceDangerBeforeDays,
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
          ..write('fixedScheduleType: $fixedScheduleType, ')
          ..write('fixedScheduleInterval: $fixedScheduleInterval, ')
          ..write('fixedMonthlyDay: $fixedMonthlyDay, ')
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
          ..write('resourceAnchorDate: $resourceAnchorDate, ')
          ..write('resourceDurationDays: $resourceDurationDays, ')
          ..write('resourceExpectedBeforeDays: $resourceExpectedBeforeDays, ')
          ..write('resourceWarningBeforeDays: $resourceWarningBeforeDays, ')
          ..write('resourceDangerBeforeDays: $resourceDangerBeforeDays, ')
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
    fixedScheduleType,
    fixedScheduleInterval,
    fixedMonthlyDay,
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
    resourceAnchorDate,
    resourceDurationDays,
    resourceExpectedBeforeDays,
    resourceWarningBeforeDays,
    resourceDangerBeforeDays,
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
          other.fixedScheduleType == this.fixedScheduleType &&
          other.fixedScheduleInterval == this.fixedScheduleInterval &&
          other.fixedMonthlyDay == this.fixedMonthlyDay &&
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
          other.resourceAnchorDate == this.resourceAnchorDate &&
          other.resourceDurationDays == this.resourceDurationDays &&
          other.resourceExpectedBeforeDays == this.resourceExpectedBeforeDays &&
          other.resourceWarningBeforeDays == this.resourceWarningBeforeDays &&
          other.resourceDangerBeforeDays == this.resourceDangerBeforeDays &&
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
  final Value<String?> fixedScheduleType;
  final Value<int?> fixedScheduleInterval;
  final Value<int?> fixedMonthlyDay;
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
  final Value<int?> resourceAnchorDate;
  final Value<int?> resourceDurationDays;
  final Value<int?> resourceExpectedBeforeDays;
  final Value<int?> resourceWarningBeforeDays;
  final Value<int?> resourceDangerBeforeDays;
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
    this.fixedScheduleType = const Value.absent(),
    this.fixedScheduleInterval = const Value.absent(),
    this.fixedMonthlyDay = const Value.absent(),
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
    this.resourceAnchorDate = const Value.absent(),
    this.resourceDurationDays = const Value.absent(),
    this.resourceExpectedBeforeDays = const Value.absent(),
    this.resourceWarningBeforeDays = const Value.absent(),
    this.resourceDangerBeforeDays = const Value.absent(),
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
    this.fixedScheduleType = const Value.absent(),
    this.fixedScheduleInterval = const Value.absent(),
    this.fixedMonthlyDay = const Value.absent(),
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
    this.resourceAnchorDate = const Value.absent(),
    this.resourceDurationDays = const Value.absent(),
    this.resourceExpectedBeforeDays = const Value.absent(),
    this.resourceWarningBeforeDays = const Value.absent(),
    this.resourceDangerBeforeDays = const Value.absent(),
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
    Expression<String>? fixedScheduleType,
    Expression<int>? fixedScheduleInterval,
    Expression<int>? fixedMonthlyDay,
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
    Expression<int>? resourceAnchorDate,
    Expression<int>? resourceDurationDays,
    Expression<int>? resourceExpectedBeforeDays,
    Expression<int>? resourceWarningBeforeDays,
    Expression<int>? resourceDangerBeforeDays,
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
      if (fixedScheduleType != null) 'fixed_schedule_type': fixedScheduleType,
      if (fixedScheduleInterval != null)
        'fixed_schedule_interval': fixedScheduleInterval,
      if (fixedMonthlyDay != null) 'fixed_monthly_day': fixedMonthlyDay,
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
      if (resourceAnchorDate != null)
        'resource_anchor_date': resourceAnchorDate,
      if (resourceDurationDays != null)
        'resource_duration_days': resourceDurationDays,
      if (resourceExpectedBeforeDays != null)
        'resource_expected_before_days': resourceExpectedBeforeDays,
      if (resourceWarningBeforeDays != null)
        'resource_warning_before_days': resourceWarningBeforeDays,
      if (resourceDangerBeforeDays != null)
        'resource_danger_before_days': resourceDangerBeforeDays,
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
    Value<String?>? fixedScheduleType,
    Value<int?>? fixedScheduleInterval,
    Value<int?>? fixedMonthlyDay,
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
    Value<int?>? resourceAnchorDate,
    Value<int?>? resourceDurationDays,
    Value<int?>? resourceExpectedBeforeDays,
    Value<int?>? resourceWarningBeforeDays,
    Value<int?>? resourceDangerBeforeDays,
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
      fixedScheduleType: fixedScheduleType ?? this.fixedScheduleType,
      fixedScheduleInterval:
          fixedScheduleInterval ?? this.fixedScheduleInterval,
      fixedMonthlyDay: fixedMonthlyDay ?? this.fixedMonthlyDay,
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
      resourceAnchorDate: resourceAnchorDate ?? this.resourceAnchorDate,
      resourceDurationDays: resourceDurationDays ?? this.resourceDurationDays,
      resourceExpectedBeforeDays:
          resourceExpectedBeforeDays ?? this.resourceExpectedBeforeDays,
      resourceWarningBeforeDays:
          resourceWarningBeforeDays ?? this.resourceWarningBeforeDays,
      resourceDangerBeforeDays:
          resourceDangerBeforeDays ?? this.resourceDangerBeforeDays,
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
    if (resourceAnchorDate.present) {
      map['resource_anchor_date'] = Variable<int>(resourceAnchorDate.value);
    }
    if (resourceDurationDays.present) {
      map['resource_duration_days'] = Variable<int>(resourceDurationDays.value);
    }
    if (resourceExpectedBeforeDays.present) {
      map['resource_expected_before_days'] = Variable<int>(
        resourceExpectedBeforeDays.value,
      );
    }
    if (resourceWarningBeforeDays.present) {
      map['resource_warning_before_days'] = Variable<int>(
        resourceWarningBeforeDays.value,
      );
    }
    if (resourceDangerBeforeDays.present) {
      map['resource_danger_before_days'] = Variable<int>(
        resourceDangerBeforeDays.value,
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
          ..write('fixedScheduleType: $fixedScheduleType, ')
          ..write('fixedScheduleInterval: $fixedScheduleInterval, ')
          ..write('fixedMonthlyDay: $fixedMonthlyDay, ')
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
          ..write('resourceAnchorDate: $resourceAnchorDate, ')
          ..write('resourceDurationDays: $resourceDurationDays, ')
          ..write('resourceExpectedBeforeDays: $resourceExpectedBeforeDays, ')
          ..write('resourceWarningBeforeDays: $resourceWarningBeforeDays, ')
          ..write('resourceDangerBeforeDays: $resourceDangerBeforeDays, ')
          ..write('lastDoneAt: $lastDoneAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ItemPackTemplatesTable extends ItemPackTemplates
    with TableInfo<$ItemPackTemplatesTable, ItemPackTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemPackTemplatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    name,
    category,
    description,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_pack_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemPackTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
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
  ItemPackTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemPackTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
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
  $ItemPackTemplatesTable createAlias(String alias) {
    return $ItemPackTemplatesTable(attachedDatabase, alias);
  }
}

class ItemPackTemplateRow extends DataClass
    implements Insertable<ItemPackTemplateRow> {
  final int id;
  final String name;
  final String category;
  final String description;
  final int createdAt;
  final int updatedAt;
  const ItemPackTemplateRow({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['description'] = Variable<String>(description);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ItemPackTemplatesCompanion toCompanion(bool nullToAbsent) {
    return ItemPackTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      description: Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ItemPackTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemPackTemplateRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      description: serializer.fromJson<String>(json['description']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'description': serializer.toJson<String>(description),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ItemPackTemplateRow copyWith({
    int? id,
    String? name,
    String? category,
    String? description,
    int? createdAt,
    int? updatedAt,
  }) => ItemPackTemplateRow(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ItemPackTemplateRow copyWithCompanion(ItemPackTemplatesCompanion data) {
    return ItemPackTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemPackTemplateRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, category, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemPackTemplateRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ItemPackTemplatesCompanion extends UpdateCompanion<ItemPackTemplateRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> category;
  final Value<String> description;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ItemPackTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ItemPackTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String category,
    required String description,
    required int createdAt,
    required int updatedAt,
  }) : name = Value(name),
       category = Value(category),
       description = Value(description),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ItemPackTemplateRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? description,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ItemPackTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? category,
    Value<String>? description,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ItemPackTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
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
    return (StringBuffer('ItemPackTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ItemTemplateItemsTable extends ItemTemplateItems
    with TableInfo<$ItemTemplateItemsTable, ItemTemplateItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemTemplateItemsTable(this.attachedDatabase, [this._alias]);
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
      'REFERENCES item_pack_templates (id)',
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _resourceDurationDaysMeta =
      const VerificationMeta('resourceDurationDays');
  @override
  late final GeneratedColumn<int> resourceDurationDays = GeneratedColumn<int>(
    'resource_duration_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resourceExpectedBeforeDaysMeta =
      const VerificationMeta('resourceExpectedBeforeDays');
  @override
  late final GeneratedColumn<int> resourceExpectedBeforeDays =
      GeneratedColumn<int>(
        'resource_expected_before_days',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resourceWarningBeforeDaysMeta =
      const VerificationMeta('resourceWarningBeforeDays');
  @override
  late final GeneratedColumn<int> resourceWarningBeforeDays =
      GeneratedColumn<int>(
        'resource_warning_before_days',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resourceDangerBeforeDaysMeta =
      const VerificationMeta('resourceDangerBeforeDays');
  @override
  late final GeneratedColumn<int> resourceDangerBeforeDays =
      GeneratedColumn<int>(
        'resource_danger_before_days',
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
    title,
    description,
    type,
    fixedScheduleType,
    fixedScheduleInterval,
    fixedMonthlyDay,
    fixedTimeOfDay,
    fixedOverduePolicy,
    fixedExpectedBeforeMinutes,
    fixedWarningBeforeMinutes,
    fixedDangerBeforeMinutes,
    stateExpectedAfterMinutes,
    stateWarningAfterMinutes,
    stateDangerAfterMinutes,
    resourceDurationDays,
    resourceExpectedBeforeDays,
    resourceWarningBeforeDays,
    resourceDangerBeforeDays,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_template_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemTemplateItemRow> instance, {
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
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
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
    if (data.containsKey('resource_duration_days')) {
      context.handle(
        _resourceDurationDaysMeta,
        resourceDurationDays.isAcceptableOrUnknown(
          data['resource_duration_days']!,
          _resourceDurationDaysMeta,
        ),
      );
    }
    if (data.containsKey('resource_expected_before_days')) {
      context.handle(
        _resourceExpectedBeforeDaysMeta,
        resourceExpectedBeforeDays.isAcceptableOrUnknown(
          data['resource_expected_before_days']!,
          _resourceExpectedBeforeDaysMeta,
        ),
      );
    }
    if (data.containsKey('resource_warning_before_days')) {
      context.handle(
        _resourceWarningBeforeDaysMeta,
        resourceWarningBeforeDays.isAcceptableOrUnknown(
          data['resource_warning_before_days']!,
          _resourceWarningBeforeDaysMeta,
        ),
      );
    }
    if (data.containsKey('resource_danger_before_days')) {
      context.handle(
        _resourceDangerBeforeDaysMeta,
        resourceDangerBeforeDays.isAcceptableOrUnknown(
          data['resource_danger_before_days']!,
          _resourceDangerBeforeDaysMeta,
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
  ItemTemplateItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemTemplateItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
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
      resourceDurationDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resource_duration_days'],
      ),
      resourceExpectedBeforeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resource_expected_before_days'],
      ),
      resourceWarningBeforeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resource_warning_before_days'],
      ),
      resourceDangerBeforeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resource_danger_before_days'],
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
  $ItemTemplateItemsTable createAlias(String alias) {
    return $ItemTemplateItemsTable(attachedDatabase, alias);
  }
}

class ItemTemplateItemRow extends DataClass
    implements Insertable<ItemTemplateItemRow> {
  final int id;
  final int templateId;
  final String title;
  final String? description;
  final String type;
  final String? fixedScheduleType;
  final int? fixedScheduleInterval;
  final int? fixedMonthlyDay;
  final String? fixedTimeOfDay;
  final String? fixedOverduePolicy;
  final int? fixedExpectedBeforeMinutes;
  final int? fixedWarningBeforeMinutes;
  final int? fixedDangerBeforeMinutes;
  final int? stateExpectedAfterMinutes;
  final int? stateWarningAfterMinutes;
  final int? stateDangerAfterMinutes;
  final int? resourceDurationDays;
  final int? resourceExpectedBeforeDays;
  final int? resourceWarningBeforeDays;
  final int? resourceDangerBeforeDays;
  final int createdAt;
  final int updatedAt;
  const ItemTemplateItemRow({
    required this.id,
    required this.templateId,
    required this.title,
    this.description,
    required this.type,
    this.fixedScheduleType,
    this.fixedScheduleInterval,
    this.fixedMonthlyDay,
    this.fixedTimeOfDay,
    this.fixedOverduePolicy,
    this.fixedExpectedBeforeMinutes,
    this.fixedWarningBeforeMinutes,
    this.fixedDangerBeforeMinutes,
    this.stateExpectedAfterMinutes,
    this.stateWarningAfterMinutes,
    this.stateDangerAfterMinutes,
    this.resourceDurationDays,
    this.resourceExpectedBeforeDays,
    this.resourceWarningBeforeDays,
    this.resourceDangerBeforeDays,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template_id'] = Variable<int>(templateId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || fixedScheduleType != null) {
      map['fixed_schedule_type'] = Variable<String>(fixedScheduleType);
    }
    if (!nullToAbsent || fixedScheduleInterval != null) {
      map['fixed_schedule_interval'] = Variable<int>(fixedScheduleInterval);
    }
    if (!nullToAbsent || fixedMonthlyDay != null) {
      map['fixed_monthly_day'] = Variable<int>(fixedMonthlyDay);
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
    if (!nullToAbsent || resourceDurationDays != null) {
      map['resource_duration_days'] = Variable<int>(resourceDurationDays);
    }
    if (!nullToAbsent || resourceExpectedBeforeDays != null) {
      map['resource_expected_before_days'] = Variable<int>(
        resourceExpectedBeforeDays,
      );
    }
    if (!nullToAbsent || resourceWarningBeforeDays != null) {
      map['resource_warning_before_days'] = Variable<int>(
        resourceWarningBeforeDays,
      );
    }
    if (!nullToAbsent || resourceDangerBeforeDays != null) {
      map['resource_danger_before_days'] = Variable<int>(
        resourceDangerBeforeDays,
      );
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ItemTemplateItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemTemplateItemsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      type: Value(type),
      fixedScheduleType: fixedScheduleType == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedScheduleType),
      fixedScheduleInterval: fixedScheduleInterval == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedScheduleInterval),
      fixedMonthlyDay: fixedMonthlyDay == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedMonthlyDay),
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
      resourceDurationDays: resourceDurationDays == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceDurationDays),
      resourceExpectedBeforeDays:
          resourceExpectedBeforeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceExpectedBeforeDays),
      resourceWarningBeforeDays:
          resourceWarningBeforeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceWarningBeforeDays),
      resourceDangerBeforeDays: resourceDangerBeforeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceDangerBeforeDays),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ItemTemplateItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemTemplateItemRow(
      id: serializer.fromJson<int>(json['id']),
      templateId: serializer.fromJson<int>(json['templateId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      type: serializer.fromJson<String>(json['type']),
      fixedScheduleType: serializer.fromJson<String?>(
        json['fixedScheduleType'],
      ),
      fixedScheduleInterval: serializer.fromJson<int?>(
        json['fixedScheduleInterval'],
      ),
      fixedMonthlyDay: serializer.fromJson<int?>(json['fixedMonthlyDay']),
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
      resourceDurationDays: serializer.fromJson<int?>(
        json['resourceDurationDays'],
      ),
      resourceExpectedBeforeDays: serializer.fromJson<int?>(
        json['resourceExpectedBeforeDays'],
      ),
      resourceWarningBeforeDays: serializer.fromJson<int?>(
        json['resourceWarningBeforeDays'],
      ),
      resourceDangerBeforeDays: serializer.fromJson<int?>(
        json['resourceDangerBeforeDays'],
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
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'type': serializer.toJson<String>(type),
      'fixedScheduleType': serializer.toJson<String?>(fixedScheduleType),
      'fixedScheduleInterval': serializer.toJson<int?>(fixedScheduleInterval),
      'fixedMonthlyDay': serializer.toJson<int?>(fixedMonthlyDay),
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
      'resourceDurationDays': serializer.toJson<int?>(resourceDurationDays),
      'resourceExpectedBeforeDays': serializer.toJson<int?>(
        resourceExpectedBeforeDays,
      ),
      'resourceWarningBeforeDays': serializer.toJson<int?>(
        resourceWarningBeforeDays,
      ),
      'resourceDangerBeforeDays': serializer.toJson<int?>(
        resourceDangerBeforeDays,
      ),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ItemTemplateItemRow copyWith({
    int? id,
    int? templateId,
    String? title,
    Value<String?> description = const Value.absent(),
    String? type,
    Value<String?> fixedScheduleType = const Value.absent(),
    Value<int?> fixedScheduleInterval = const Value.absent(),
    Value<int?> fixedMonthlyDay = const Value.absent(),
    Value<String?> fixedTimeOfDay = const Value.absent(),
    Value<String?> fixedOverduePolicy = const Value.absent(),
    Value<int?> fixedExpectedBeforeMinutes = const Value.absent(),
    Value<int?> fixedWarningBeforeMinutes = const Value.absent(),
    Value<int?> fixedDangerBeforeMinutes = const Value.absent(),
    Value<int?> stateExpectedAfterMinutes = const Value.absent(),
    Value<int?> stateWarningAfterMinutes = const Value.absent(),
    Value<int?> stateDangerAfterMinutes = const Value.absent(),
    Value<int?> resourceDurationDays = const Value.absent(),
    Value<int?> resourceExpectedBeforeDays = const Value.absent(),
    Value<int?> resourceWarningBeforeDays = const Value.absent(),
    Value<int?> resourceDangerBeforeDays = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => ItemTemplateItemRow(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    type: type ?? this.type,
    fixedScheduleType: fixedScheduleType.present
        ? fixedScheduleType.value
        : this.fixedScheduleType,
    fixedScheduleInterval: fixedScheduleInterval.present
        ? fixedScheduleInterval.value
        : this.fixedScheduleInterval,
    fixedMonthlyDay: fixedMonthlyDay.present
        ? fixedMonthlyDay.value
        : this.fixedMonthlyDay,
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
    resourceDurationDays: resourceDurationDays.present
        ? resourceDurationDays.value
        : this.resourceDurationDays,
    resourceExpectedBeforeDays: resourceExpectedBeforeDays.present
        ? resourceExpectedBeforeDays.value
        : this.resourceExpectedBeforeDays,
    resourceWarningBeforeDays: resourceWarningBeforeDays.present
        ? resourceWarningBeforeDays.value
        : this.resourceWarningBeforeDays,
    resourceDangerBeforeDays: resourceDangerBeforeDays.present
        ? resourceDangerBeforeDays.value
        : this.resourceDangerBeforeDays,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ItemTemplateItemRow copyWithCompanion(ItemTemplateItemsCompanion data) {
    return ItemTemplateItemRow(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      type: data.type.present ? data.type.value : this.type,
      fixedScheduleType: data.fixedScheduleType.present
          ? data.fixedScheduleType.value
          : this.fixedScheduleType,
      fixedScheduleInterval: data.fixedScheduleInterval.present
          ? data.fixedScheduleInterval.value
          : this.fixedScheduleInterval,
      fixedMonthlyDay: data.fixedMonthlyDay.present
          ? data.fixedMonthlyDay.value
          : this.fixedMonthlyDay,
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
      resourceDurationDays: data.resourceDurationDays.present
          ? data.resourceDurationDays.value
          : this.resourceDurationDays,
      resourceExpectedBeforeDays: data.resourceExpectedBeforeDays.present
          ? data.resourceExpectedBeforeDays.value
          : this.resourceExpectedBeforeDays,
      resourceWarningBeforeDays: data.resourceWarningBeforeDays.present
          ? data.resourceWarningBeforeDays.value
          : this.resourceWarningBeforeDays,
      resourceDangerBeforeDays: data.resourceDangerBeforeDays.present
          ? data.resourceDangerBeforeDays.value
          : this.resourceDangerBeforeDays,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemTemplateItemRow(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('fixedScheduleType: $fixedScheduleType, ')
          ..write('fixedScheduleInterval: $fixedScheduleInterval, ')
          ..write('fixedMonthlyDay: $fixedMonthlyDay, ')
          ..write('fixedTimeOfDay: $fixedTimeOfDay, ')
          ..write('fixedOverduePolicy: $fixedOverduePolicy, ')
          ..write('fixedExpectedBeforeMinutes: $fixedExpectedBeforeMinutes, ')
          ..write('fixedWarningBeforeMinutes: $fixedWarningBeforeMinutes, ')
          ..write('fixedDangerBeforeMinutes: $fixedDangerBeforeMinutes, ')
          ..write('stateExpectedAfterMinutes: $stateExpectedAfterMinutes, ')
          ..write('stateWarningAfterMinutes: $stateWarningAfterMinutes, ')
          ..write('stateDangerAfterMinutes: $stateDangerAfterMinutes, ')
          ..write('resourceDurationDays: $resourceDurationDays, ')
          ..write('resourceExpectedBeforeDays: $resourceExpectedBeforeDays, ')
          ..write('resourceWarningBeforeDays: $resourceWarningBeforeDays, ')
          ..write('resourceDangerBeforeDays: $resourceDangerBeforeDays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    templateId,
    title,
    description,
    type,
    fixedScheduleType,
    fixedScheduleInterval,
    fixedMonthlyDay,
    fixedTimeOfDay,
    fixedOverduePolicy,
    fixedExpectedBeforeMinutes,
    fixedWarningBeforeMinutes,
    fixedDangerBeforeMinutes,
    stateExpectedAfterMinutes,
    stateWarningAfterMinutes,
    stateDangerAfterMinutes,
    resourceDurationDays,
    resourceExpectedBeforeDays,
    resourceWarningBeforeDays,
    resourceDangerBeforeDays,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemTemplateItemRow &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.title == this.title &&
          other.description == this.description &&
          other.type == this.type &&
          other.fixedScheduleType == this.fixedScheduleType &&
          other.fixedScheduleInterval == this.fixedScheduleInterval &&
          other.fixedMonthlyDay == this.fixedMonthlyDay &&
          other.fixedTimeOfDay == this.fixedTimeOfDay &&
          other.fixedOverduePolicy == this.fixedOverduePolicy &&
          other.fixedExpectedBeforeMinutes == this.fixedExpectedBeforeMinutes &&
          other.fixedWarningBeforeMinutes == this.fixedWarningBeforeMinutes &&
          other.fixedDangerBeforeMinutes == this.fixedDangerBeforeMinutes &&
          other.stateExpectedAfterMinutes == this.stateExpectedAfterMinutes &&
          other.stateWarningAfterMinutes == this.stateWarningAfterMinutes &&
          other.stateDangerAfterMinutes == this.stateDangerAfterMinutes &&
          other.resourceDurationDays == this.resourceDurationDays &&
          other.resourceExpectedBeforeDays == this.resourceExpectedBeforeDays &&
          other.resourceWarningBeforeDays == this.resourceWarningBeforeDays &&
          other.resourceDangerBeforeDays == this.resourceDangerBeforeDays &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ItemTemplateItemsCompanion extends UpdateCompanion<ItemTemplateItemRow> {
  final Value<int> id;
  final Value<int> templateId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> type;
  final Value<String?> fixedScheduleType;
  final Value<int?> fixedScheduleInterval;
  final Value<int?> fixedMonthlyDay;
  final Value<String?> fixedTimeOfDay;
  final Value<String?> fixedOverduePolicy;
  final Value<int?> fixedExpectedBeforeMinutes;
  final Value<int?> fixedWarningBeforeMinutes;
  final Value<int?> fixedDangerBeforeMinutes;
  final Value<int?> stateExpectedAfterMinutes;
  final Value<int?> stateWarningAfterMinutes;
  final Value<int?> stateDangerAfterMinutes;
  final Value<int?> resourceDurationDays;
  final Value<int?> resourceExpectedBeforeDays;
  final Value<int?> resourceWarningBeforeDays;
  final Value<int?> resourceDangerBeforeDays;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ItemTemplateItemsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.fixedScheduleType = const Value.absent(),
    this.fixedScheduleInterval = const Value.absent(),
    this.fixedMonthlyDay = const Value.absent(),
    this.fixedTimeOfDay = const Value.absent(),
    this.fixedOverduePolicy = const Value.absent(),
    this.fixedExpectedBeforeMinutes = const Value.absent(),
    this.fixedWarningBeforeMinutes = const Value.absent(),
    this.fixedDangerBeforeMinutes = const Value.absent(),
    this.stateExpectedAfterMinutes = const Value.absent(),
    this.stateWarningAfterMinutes = const Value.absent(),
    this.stateDangerAfterMinutes = const Value.absent(),
    this.resourceDurationDays = const Value.absent(),
    this.resourceExpectedBeforeDays = const Value.absent(),
    this.resourceWarningBeforeDays = const Value.absent(),
    this.resourceDangerBeforeDays = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ItemTemplateItemsCompanion.insert({
    this.id = const Value.absent(),
    required int templateId,
    required String title,
    this.description = const Value.absent(),
    required String type,
    this.fixedScheduleType = const Value.absent(),
    this.fixedScheduleInterval = const Value.absent(),
    this.fixedMonthlyDay = const Value.absent(),
    this.fixedTimeOfDay = const Value.absent(),
    this.fixedOverduePolicy = const Value.absent(),
    this.fixedExpectedBeforeMinutes = const Value.absent(),
    this.fixedWarningBeforeMinutes = const Value.absent(),
    this.fixedDangerBeforeMinutes = const Value.absent(),
    this.stateExpectedAfterMinutes = const Value.absent(),
    this.stateWarningAfterMinutes = const Value.absent(),
    this.stateDangerAfterMinutes = const Value.absent(),
    this.resourceDurationDays = const Value.absent(),
    this.resourceExpectedBeforeDays = const Value.absent(),
    this.resourceWarningBeforeDays = const Value.absent(),
    this.resourceDangerBeforeDays = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : templateId = Value(templateId),
       title = Value(title),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ItemTemplateItemRow> custom({
    Expression<int>? id,
    Expression<int>? templateId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? type,
    Expression<String>? fixedScheduleType,
    Expression<int>? fixedScheduleInterval,
    Expression<int>? fixedMonthlyDay,
    Expression<String>? fixedTimeOfDay,
    Expression<String>? fixedOverduePolicy,
    Expression<int>? fixedExpectedBeforeMinutes,
    Expression<int>? fixedWarningBeforeMinutes,
    Expression<int>? fixedDangerBeforeMinutes,
    Expression<int>? stateExpectedAfterMinutes,
    Expression<int>? stateWarningAfterMinutes,
    Expression<int>? stateDangerAfterMinutes,
    Expression<int>? resourceDurationDays,
    Expression<int>? resourceExpectedBeforeDays,
    Expression<int>? resourceWarningBeforeDays,
    Expression<int>? resourceDangerBeforeDays,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (fixedScheduleType != null) 'fixed_schedule_type': fixedScheduleType,
      if (fixedScheduleInterval != null)
        'fixed_schedule_interval': fixedScheduleInterval,
      if (fixedMonthlyDay != null) 'fixed_monthly_day': fixedMonthlyDay,
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
      if (resourceDurationDays != null)
        'resource_duration_days': resourceDurationDays,
      if (resourceExpectedBeforeDays != null)
        'resource_expected_before_days': resourceExpectedBeforeDays,
      if (resourceWarningBeforeDays != null)
        'resource_warning_before_days': resourceWarningBeforeDays,
      if (resourceDangerBeforeDays != null)
        'resource_danger_before_days': resourceDangerBeforeDays,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ItemTemplateItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? templateId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? type,
    Value<String?>? fixedScheduleType,
    Value<int?>? fixedScheduleInterval,
    Value<int?>? fixedMonthlyDay,
    Value<String?>? fixedTimeOfDay,
    Value<String?>? fixedOverduePolicy,
    Value<int?>? fixedExpectedBeforeMinutes,
    Value<int?>? fixedWarningBeforeMinutes,
    Value<int?>? fixedDangerBeforeMinutes,
    Value<int?>? stateExpectedAfterMinutes,
    Value<int?>? stateWarningAfterMinutes,
    Value<int?>? stateDangerAfterMinutes,
    Value<int?>? resourceDurationDays,
    Value<int?>? resourceExpectedBeforeDays,
    Value<int?>? resourceWarningBeforeDays,
    Value<int?>? resourceDangerBeforeDays,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ItemTemplateItemsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      fixedScheduleType: fixedScheduleType ?? this.fixedScheduleType,
      fixedScheduleInterval:
          fixedScheduleInterval ?? this.fixedScheduleInterval,
      fixedMonthlyDay: fixedMonthlyDay ?? this.fixedMonthlyDay,
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
      resourceDurationDays: resourceDurationDays ?? this.resourceDurationDays,
      resourceExpectedBeforeDays:
          resourceExpectedBeforeDays ?? this.resourceExpectedBeforeDays,
      resourceWarningBeforeDays:
          resourceWarningBeforeDays ?? this.resourceWarningBeforeDays,
      resourceDangerBeforeDays:
          resourceDangerBeforeDays ?? this.resourceDangerBeforeDays,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
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
    if (resourceDurationDays.present) {
      map['resource_duration_days'] = Variable<int>(resourceDurationDays.value);
    }
    if (resourceExpectedBeforeDays.present) {
      map['resource_expected_before_days'] = Variable<int>(
        resourceExpectedBeforeDays.value,
      );
    }
    if (resourceWarningBeforeDays.present) {
      map['resource_warning_before_days'] = Variable<int>(
        resourceWarningBeforeDays.value,
      );
    }
    if (resourceDangerBeforeDays.present) {
      map['resource_danger_before_days'] = Variable<int>(
        resourceDangerBeforeDays.value,
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
    return (StringBuffer('ItemTemplateItemsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('fixedScheduleType: $fixedScheduleType, ')
          ..write('fixedScheduleInterval: $fixedScheduleInterval, ')
          ..write('fixedMonthlyDay: $fixedMonthlyDay, ')
          ..write('fixedTimeOfDay: $fixedTimeOfDay, ')
          ..write('fixedOverduePolicy: $fixedOverduePolicy, ')
          ..write('fixedExpectedBeforeMinutes: $fixedExpectedBeforeMinutes, ')
          ..write('fixedWarningBeforeMinutes: $fixedWarningBeforeMinutes, ')
          ..write('fixedDangerBeforeMinutes: $fixedDangerBeforeMinutes, ')
          ..write('stateExpectedAfterMinutes: $stateExpectedAfterMinutes, ')
          ..write('stateWarningAfterMinutes: $stateWarningAfterMinutes, ')
          ..write('stateDangerAfterMinutes: $stateDangerAfterMinutes, ')
          ..write('resourceDurationDays: $resourceDurationDays, ')
          ..write('resourceExpectedBeforeDays: $resourceExpectedBeforeDays, ')
          ..write('resourceWarningBeforeDays: $resourceWarningBeforeDays, ')
          ..write('resourceDangerBeforeDays: $resourceDangerBeforeDays, ')
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
  final int createdAt;
  final int updatedAt;
  const ItemActionRecordRow({
    required this.id,
    required this.itemId,
    required this.actionType,
    required this.actionDate,
    this.remark,
    this.payload,
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
    int? createdAt,
    int? updatedAt,
  }) => ItemActionRecordRow(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    actionType: actionType ?? this.actionType,
    actionDate: actionDate ?? this.actionDate,
    remark: remark.present ? remark.value : this.remark,
    payload: payload.present ? payload.value : this.payload,
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
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ItemActionRecordsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.actionType = const Value.absent(),
    this.actionDate = const Value.absent(),
    this.remark = const Value.absent(),
    this.payload = const Value.absent(),
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
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TimelinesTable extends Timelines
    with TableInfo<$TimelinesTable, TimelineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimelinesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<int> startDate = GeneratedColumn<int>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayUnitMeta = const VerificationMeta(
    'displayUnit',
  );
  @override
  late final GeneratedColumn<String> displayUnit = GeneratedColumn<String>(
    'display_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    startDate,
    displayUnit,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timelines';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimelineRow> instance, {
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
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('display_unit')) {
      context.handle(
        _displayUnitMeta,
        displayUnit.isAcceptableOrUnknown(
          data['display_unit']!,
          _displayUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayUnitMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
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
  TimelineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimelineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_date'],
      )!,
      displayUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_unit'],
      )!,
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
  $TimelinesTable createAlias(String alias) {
    return $TimelinesTable(attachedDatabase, alias);
  }
}

class TimelineRow extends DataClass implements Insertable<TimelineRow> {
  final int id;
  final String title;
  final int startDate;
  final String displayUnit;
  final String status;
  final int createdAt;
  final int updatedAt;
  const TimelineRow({
    required this.id,
    required this.title,
    required this.startDate,
    required this.displayUnit,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['start_date'] = Variable<int>(startDate);
    map['display_unit'] = Variable<String>(displayUnit);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TimelinesCompanion toCompanion(bool nullToAbsent) {
    return TimelinesCompanion(
      id: Value(id),
      title: Value(title),
      startDate: Value(startDate),
      displayUnit: Value(displayUnit),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TimelineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimelineRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      startDate: serializer.fromJson<int>(json['startDate']),
      displayUnit: serializer.fromJson<String>(json['displayUnit']),
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
      'title': serializer.toJson<String>(title),
      'startDate': serializer.toJson<int>(startDate),
      'displayUnit': serializer.toJson<String>(displayUnit),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  TimelineRow copyWith({
    int? id,
    String? title,
    int? startDate,
    String? displayUnit,
    String? status,
    int? createdAt,
    int? updatedAt,
  }) => TimelineRow(
    id: id ?? this.id,
    title: title ?? this.title,
    startDate: startDate ?? this.startDate,
    displayUnit: displayUnit ?? this.displayUnit,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TimelineRow copyWithCompanion(TimelinesCompanion data) {
    return TimelineRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      displayUnit: data.displayUnit.present
          ? data.displayUnit.value
          : this.displayUnit,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimelineRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('startDate: $startDate, ')
          ..write('displayUnit: $displayUnit, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    startDate,
    displayUnit,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimelineRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.startDate == this.startDate &&
          other.displayUnit == this.displayUnit &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TimelinesCompanion extends UpdateCompanion<TimelineRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<int> startDate;
  final Value<String> displayUnit;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const TimelinesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.startDate = const Value.absent(),
    this.displayUnit = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TimelinesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required int startDate,
    required String displayUnit,
    required String status,
    required int createdAt,
    required int updatedAt,
  }) : title = Value(title),
       startDate = Value(startDate),
       displayUnit = Value(displayUnit),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TimelineRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? startDate,
    Expression<String>? displayUnit,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (startDate != null) 'start_date': startDate,
      if (displayUnit != null) 'display_unit': displayUnit,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TimelinesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<int>? startDate,
    Value<String>? displayUnit,
    Value<String>? status,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return TimelinesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      displayUnit: displayUnit ?? this.displayUnit,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<int>(startDate.value);
    }
    if (displayUnit.present) {
      map['display_unit'] = Variable<String>(displayUnit.value);
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
    return (StringBuffer('TimelinesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('startDate: $startDate, ')
          ..write('displayUnit: $displayUnit, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TimelineMilestoneRulesTable extends TimelineMilestoneRules
    with TableInfo<$TimelineMilestoneRulesTable, TimelineMilestoneRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimelineMilestoneRulesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _timelineIdMeta = const VerificationMeta(
    'timelineId',
  );
  @override
  late final GeneratedColumn<int> timelineId = GeneratedColumn<int>(
    'timeline_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES timelines (id)',
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
    timelineId,
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
  static const String $name = 'timeline_milestone_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimelineMilestoneRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timeline_id')) {
      context.handle(
        _timelineIdMeta,
        timelineId.isAcceptableOrUnknown(data['timeline_id']!, _timelineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_timelineIdMeta);
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
  TimelineMilestoneRuleRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimelineMilestoneRuleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timelineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timeline_id'],
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
      )!,
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
  $TimelineMilestoneRulesTable createAlias(String alias) {
    return $TimelineMilestoneRulesTable(attachedDatabase, alias);
  }
}

class TimelineMilestoneRuleRow extends DataClass
    implements Insertable<TimelineMilestoneRuleRow> {
  final int id;
  final int timelineId;
  final String type;
  final int intervalValue;
  final String intervalUnit;
  final String? labelTemplate;
  final int reminderOffsetDays;
  final String status;
  final int createdAt;
  final int updatedAt;
  const TimelineMilestoneRuleRow({
    required this.id,
    required this.timelineId,
    required this.type,
    required this.intervalValue,
    required this.intervalUnit,
    this.labelTemplate,
    required this.reminderOffsetDays,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timeline_id'] = Variable<int>(timelineId);
    map['type'] = Variable<String>(type);
    map['interval_value'] = Variable<int>(intervalValue);
    map['interval_unit'] = Variable<String>(intervalUnit);
    if (!nullToAbsent || labelTemplate != null) {
      map['label_template'] = Variable<String>(labelTemplate);
    }
    map['reminder_offset_days'] = Variable<int>(reminderOffsetDays);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TimelineMilestoneRulesCompanion toCompanion(bool nullToAbsent) {
    return TimelineMilestoneRulesCompanion(
      id: Value(id),
      timelineId: Value(timelineId),
      type: Value(type),
      intervalValue: Value(intervalValue),
      intervalUnit: Value(intervalUnit),
      labelTemplate: labelTemplate == null && nullToAbsent
          ? const Value.absent()
          : Value(labelTemplate),
      reminderOffsetDays: Value(reminderOffsetDays),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TimelineMilestoneRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimelineMilestoneRuleRow(
      id: serializer.fromJson<int>(json['id']),
      timelineId: serializer.fromJson<int>(json['timelineId']),
      type: serializer.fromJson<String>(json['type']),
      intervalValue: serializer.fromJson<int>(json['intervalValue']),
      intervalUnit: serializer.fromJson<String>(json['intervalUnit']),
      labelTemplate: serializer.fromJson<String?>(json['labelTemplate']),
      reminderOffsetDays: serializer.fromJson<int>(json['reminderOffsetDays']),
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
      'timelineId': serializer.toJson<int>(timelineId),
      'type': serializer.toJson<String>(type),
      'intervalValue': serializer.toJson<int>(intervalValue),
      'intervalUnit': serializer.toJson<String>(intervalUnit),
      'labelTemplate': serializer.toJson<String?>(labelTemplate),
      'reminderOffsetDays': serializer.toJson<int>(reminderOffsetDays),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  TimelineMilestoneRuleRow copyWith({
    int? id,
    int? timelineId,
    String? type,
    int? intervalValue,
    String? intervalUnit,
    Value<String?> labelTemplate = const Value.absent(),
    int? reminderOffsetDays,
    String? status,
    int? createdAt,
    int? updatedAt,
  }) => TimelineMilestoneRuleRow(
    id: id ?? this.id,
    timelineId: timelineId ?? this.timelineId,
    type: type ?? this.type,
    intervalValue: intervalValue ?? this.intervalValue,
    intervalUnit: intervalUnit ?? this.intervalUnit,
    labelTemplate: labelTemplate.present
        ? labelTemplate.value
        : this.labelTemplate,
    reminderOffsetDays: reminderOffsetDays ?? this.reminderOffsetDays,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TimelineMilestoneRuleRow copyWithCompanion(
    TimelineMilestoneRulesCompanion data,
  ) {
    return TimelineMilestoneRuleRow(
      id: data.id.present ? data.id.value : this.id,
      timelineId: data.timelineId.present
          ? data.timelineId.value
          : this.timelineId,
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
    return (StringBuffer('TimelineMilestoneRuleRow(')
          ..write('id: $id, ')
          ..write('timelineId: $timelineId, ')
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
    timelineId,
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
      (other is TimelineMilestoneRuleRow &&
          other.id == this.id &&
          other.timelineId == this.timelineId &&
          other.type == this.type &&
          other.intervalValue == this.intervalValue &&
          other.intervalUnit == this.intervalUnit &&
          other.labelTemplate == this.labelTemplate &&
          other.reminderOffsetDays == this.reminderOffsetDays &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TimelineMilestoneRulesCompanion
    extends UpdateCompanion<TimelineMilestoneRuleRow> {
  final Value<int> id;
  final Value<int> timelineId;
  final Value<String> type;
  final Value<int> intervalValue;
  final Value<String> intervalUnit;
  final Value<String?> labelTemplate;
  final Value<int> reminderOffsetDays;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const TimelineMilestoneRulesCompanion({
    this.id = const Value.absent(),
    this.timelineId = const Value.absent(),
    this.type = const Value.absent(),
    this.intervalValue = const Value.absent(),
    this.intervalUnit = const Value.absent(),
    this.labelTemplate = const Value.absent(),
    this.reminderOffsetDays = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TimelineMilestoneRulesCompanion.insert({
    this.id = const Value.absent(),
    required int timelineId,
    required String type,
    required int intervalValue,
    required String intervalUnit,
    this.labelTemplate = const Value.absent(),
    this.reminderOffsetDays = const Value.absent(),
    this.status = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : timelineId = Value(timelineId),
       type = Value(type),
       intervalValue = Value(intervalValue),
       intervalUnit = Value(intervalUnit),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TimelineMilestoneRuleRow> custom({
    Expression<int>? id,
    Expression<int>? timelineId,
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
      if (timelineId != null) 'timeline_id': timelineId,
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

  TimelineMilestoneRulesCompanion copyWith({
    Value<int>? id,
    Value<int>? timelineId,
    Value<String>? type,
    Value<int>? intervalValue,
    Value<String>? intervalUnit,
    Value<String?>? labelTemplate,
    Value<int>? reminderOffsetDays,
    Value<String>? status,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return TimelineMilestoneRulesCompanion(
      id: id ?? this.id,
      timelineId: timelineId ?? this.timelineId,
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
    if (timelineId.present) {
      map['timeline_id'] = Variable<int>(timelineId.value);
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
    return (StringBuffer('TimelineMilestoneRulesCompanion(')
          ..write('id: $id, ')
          ..write('timelineId: $timelineId, ')
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

class $TimelineMilestoneRecordsTable extends TimelineMilestoneRecords
    with TableInfo<$TimelineMilestoneRecordsTable, TimelineMilestoneRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimelineMilestoneRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _timelineIdMeta = const VerificationMeta(
    'timelineId',
  );
  @override
  late final GeneratedColumn<int> timelineId = GeneratedColumn<int>(
    'timeline_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES timelines (id)',
    ),
  );
  static const VerificationMeta _ruleIdMeta = const VerificationMeta('ruleId');
  @override
  late final GeneratedColumn<int> ruleId = GeneratedColumn<int>(
    'rule_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES timeline_milestone_rules (id)',
    ),
  );
  static const VerificationMeta _occurrenceIndexMeta = const VerificationMeta(
    'occurrenceIndex',
  );
  @override
  late final GeneratedColumn<int> occurrenceIndex = GeneratedColumn<int>(
    'occurrence_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<int> targetDate = GeneratedColumn<int>(
    'target_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notifiedAtMeta = const VerificationMeta(
    'notifiedAt',
  );
  @override
  late final GeneratedColumn<int> notifiedAt = GeneratedColumn<int>(
    'notified_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actedAtMeta = const VerificationMeta(
    'actedAt',
  );
  @override
  late final GeneratedColumn<int> actedAt = GeneratedColumn<int>(
    'acted_at',
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
    timelineId,
    ruleId,
    occurrenceIndex,
    targetDate,
    status,
    notifiedAt,
    actedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timeline_milestone_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimelineMilestoneRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timeline_id')) {
      context.handle(
        _timelineIdMeta,
        timelineId.isAcceptableOrUnknown(data['timeline_id']!, _timelineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_timelineIdMeta);
    }
    if (data.containsKey('rule_id')) {
      context.handle(
        _ruleIdMeta,
        ruleId.isAcceptableOrUnknown(data['rule_id']!, _ruleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleIdMeta);
    }
    if (data.containsKey('occurrence_index')) {
      context.handle(
        _occurrenceIndexMeta,
        occurrenceIndex.isAcceptableOrUnknown(
          data['occurrence_index']!,
          _occurrenceIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceIndexMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('notified_at')) {
      context.handle(
        _notifiedAtMeta,
        notifiedAt.isAcceptableOrUnknown(data['notified_at']!, _notifiedAtMeta),
      );
    }
    if (data.containsKey('acted_at')) {
      context.handle(
        _actedAtMeta,
        actedAt.isAcceptableOrUnknown(data['acted_at']!, _actedAtMeta),
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
    {timelineId, ruleId, occurrenceIndex},
  ];
  @override
  TimelineMilestoneRecordRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimelineMilestoneRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timelineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timeline_id'],
      )!,
      ruleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rule_id'],
      )!,
      occurrenceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurrence_index'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      notifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notified_at'],
      ),
      actedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}acted_at'],
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
  $TimelineMilestoneRecordsTable createAlias(String alias) {
    return $TimelineMilestoneRecordsTable(attachedDatabase, alias);
  }
}

class TimelineMilestoneRecordRow extends DataClass
    implements Insertable<TimelineMilestoneRecordRow> {
  final int id;
  final int timelineId;
  final int ruleId;
  final int occurrenceIndex;
  final int targetDate;
  final String status;
  final int? notifiedAt;
  final int? actedAt;
  final int createdAt;
  final int updatedAt;
  const TimelineMilestoneRecordRow({
    required this.id,
    required this.timelineId,
    required this.ruleId,
    required this.occurrenceIndex,
    required this.targetDate,
    required this.status,
    this.notifiedAt,
    this.actedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timeline_id'] = Variable<int>(timelineId);
    map['rule_id'] = Variable<int>(ruleId);
    map['occurrence_index'] = Variable<int>(occurrenceIndex);
    map['target_date'] = Variable<int>(targetDate);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notifiedAt != null) {
      map['notified_at'] = Variable<int>(notifiedAt);
    }
    if (!nullToAbsent || actedAt != null) {
      map['acted_at'] = Variable<int>(actedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TimelineMilestoneRecordsCompanion toCompanion(bool nullToAbsent) {
    return TimelineMilestoneRecordsCompanion(
      id: Value(id),
      timelineId: Value(timelineId),
      ruleId: Value(ruleId),
      occurrenceIndex: Value(occurrenceIndex),
      targetDate: Value(targetDate),
      status: Value(status),
      notifiedAt: notifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(notifiedAt),
      actedAt: actedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(actedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TimelineMilestoneRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimelineMilestoneRecordRow(
      id: serializer.fromJson<int>(json['id']),
      timelineId: serializer.fromJson<int>(json['timelineId']),
      ruleId: serializer.fromJson<int>(json['ruleId']),
      occurrenceIndex: serializer.fromJson<int>(json['occurrenceIndex']),
      targetDate: serializer.fromJson<int>(json['targetDate']),
      status: serializer.fromJson<String>(json['status']),
      notifiedAt: serializer.fromJson<int?>(json['notifiedAt']),
      actedAt: serializer.fromJson<int?>(json['actedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timelineId': serializer.toJson<int>(timelineId),
      'ruleId': serializer.toJson<int>(ruleId),
      'occurrenceIndex': serializer.toJson<int>(occurrenceIndex),
      'targetDate': serializer.toJson<int>(targetDate),
      'status': serializer.toJson<String>(status),
      'notifiedAt': serializer.toJson<int?>(notifiedAt),
      'actedAt': serializer.toJson<int?>(actedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  TimelineMilestoneRecordRow copyWith({
    int? id,
    int? timelineId,
    int? ruleId,
    int? occurrenceIndex,
    int? targetDate,
    String? status,
    Value<int?> notifiedAt = const Value.absent(),
    Value<int?> actedAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => TimelineMilestoneRecordRow(
    id: id ?? this.id,
    timelineId: timelineId ?? this.timelineId,
    ruleId: ruleId ?? this.ruleId,
    occurrenceIndex: occurrenceIndex ?? this.occurrenceIndex,
    targetDate: targetDate ?? this.targetDate,
    status: status ?? this.status,
    notifiedAt: notifiedAt.present ? notifiedAt.value : this.notifiedAt,
    actedAt: actedAt.present ? actedAt.value : this.actedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TimelineMilestoneRecordRow copyWithCompanion(
    TimelineMilestoneRecordsCompanion data,
  ) {
    return TimelineMilestoneRecordRow(
      id: data.id.present ? data.id.value : this.id,
      timelineId: data.timelineId.present
          ? data.timelineId.value
          : this.timelineId,
      ruleId: data.ruleId.present ? data.ruleId.value : this.ruleId,
      occurrenceIndex: data.occurrenceIndex.present
          ? data.occurrenceIndex.value
          : this.occurrenceIndex,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      status: data.status.present ? data.status.value : this.status,
      notifiedAt: data.notifiedAt.present
          ? data.notifiedAt.value
          : this.notifiedAt,
      actedAt: data.actedAt.present ? data.actedAt.value : this.actedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimelineMilestoneRecordRow(')
          ..write('id: $id, ')
          ..write('timelineId: $timelineId, ')
          ..write('ruleId: $ruleId, ')
          ..write('occurrenceIndex: $occurrenceIndex, ')
          ..write('targetDate: $targetDate, ')
          ..write('status: $status, ')
          ..write('notifiedAt: $notifiedAt, ')
          ..write('actedAt: $actedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timelineId,
    ruleId,
    occurrenceIndex,
    targetDate,
    status,
    notifiedAt,
    actedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimelineMilestoneRecordRow &&
          other.id == this.id &&
          other.timelineId == this.timelineId &&
          other.ruleId == this.ruleId &&
          other.occurrenceIndex == this.occurrenceIndex &&
          other.targetDate == this.targetDate &&
          other.status == this.status &&
          other.notifiedAt == this.notifiedAt &&
          other.actedAt == this.actedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TimelineMilestoneRecordsCompanion
    extends UpdateCompanion<TimelineMilestoneRecordRow> {
  final Value<int> id;
  final Value<int> timelineId;
  final Value<int> ruleId;
  final Value<int> occurrenceIndex;
  final Value<int> targetDate;
  final Value<String> status;
  final Value<int?> notifiedAt;
  final Value<int?> actedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const TimelineMilestoneRecordsCompanion({
    this.id = const Value.absent(),
    this.timelineId = const Value.absent(),
    this.ruleId = const Value.absent(),
    this.occurrenceIndex = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.status = const Value.absent(),
    this.notifiedAt = const Value.absent(),
    this.actedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TimelineMilestoneRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int timelineId,
    required int ruleId,
    required int occurrenceIndex,
    required int targetDate,
    required String status,
    this.notifiedAt = const Value.absent(),
    this.actedAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : timelineId = Value(timelineId),
       ruleId = Value(ruleId),
       occurrenceIndex = Value(occurrenceIndex),
       targetDate = Value(targetDate),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TimelineMilestoneRecordRow> custom({
    Expression<int>? id,
    Expression<int>? timelineId,
    Expression<int>? ruleId,
    Expression<int>? occurrenceIndex,
    Expression<int>? targetDate,
    Expression<String>? status,
    Expression<int>? notifiedAt,
    Expression<int>? actedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timelineId != null) 'timeline_id': timelineId,
      if (ruleId != null) 'rule_id': ruleId,
      if (occurrenceIndex != null) 'occurrence_index': occurrenceIndex,
      if (targetDate != null) 'target_date': targetDate,
      if (status != null) 'status': status,
      if (notifiedAt != null) 'notified_at': notifiedAt,
      if (actedAt != null) 'acted_at': actedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TimelineMilestoneRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? timelineId,
    Value<int>? ruleId,
    Value<int>? occurrenceIndex,
    Value<int>? targetDate,
    Value<String>? status,
    Value<int?>? notifiedAt,
    Value<int?>? actedAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return TimelineMilestoneRecordsCompanion(
      id: id ?? this.id,
      timelineId: timelineId ?? this.timelineId,
      ruleId: ruleId ?? this.ruleId,
      occurrenceIndex: occurrenceIndex ?? this.occurrenceIndex,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      actedAt: actedAt ?? this.actedAt,
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
    if (timelineId.present) {
      map['timeline_id'] = Variable<int>(timelineId.value);
    }
    if (ruleId.present) {
      map['rule_id'] = Variable<int>(ruleId.value);
    }
    if (occurrenceIndex.present) {
      map['occurrence_index'] = Variable<int>(occurrenceIndex.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<int>(targetDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notifiedAt.present) {
      map['notified_at'] = Variable<int>(notifiedAt.value);
    }
    if (actedAt.present) {
      map['acted_at'] = Variable<int>(actedAt.value);
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
    return (StringBuffer('TimelineMilestoneRecordsCompanion(')
          ..write('id: $id, ')
          ..write('timelineId: $timelineId, ')
          ..write('ruleId: $ruleId, ')
          ..write('occurrenceIndex: $occurrenceIndex, ')
          ..write('targetDate: $targetDate, ')
          ..write('status: $status, ')
          ..write('notifiedAt: $notifiedAt, ')
          ..write('actedAt: $actedAt, ')
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
  late final $ItemPackTemplatesTable itemPackTemplates =
      $ItemPackTemplatesTable(this);
  late final $ItemTemplateItemsTable itemTemplateItems =
      $ItemTemplateItemsTable(this);
  late final $ItemActionRecordsTable itemActionRecords =
      $ItemActionRecordsTable(this);
  late final $TimelinesTable timelines = $TimelinesTable(this);
  late final $TimelineMilestoneRulesTable timelineMilestoneRules =
      $TimelineMilestoneRulesTable(this);
  late final $TimelineMilestoneRecordsTable timelineMilestoneRecords =
      $TimelineMilestoneRecordsTable(this);
  late final ItemTimelineDao itemTimelineDao = ItemTimelineDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    itemPacks,
    items,
    itemPackTemplates,
    itemTemplateItems,
    itemActionRecords,
    timelines,
    timelineMilestoneRules,
    timelineMilestoneRecords,
  ];
}

typedef $$ItemPacksTableCreateCompanionBuilder =
    ItemPacksCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> description,
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
          PrefetchHooks Function({bool itemsRefs})
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
                Value<String> status = const Value.absent(),
                Value<bool> isSystemDefault = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ItemPacksCompanion(
                id: id,
                title: title,
                description: description,
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
                Value<String> status = const Value.absent(),
                Value<bool> isSystemDefault = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ItemPacksCompanion.insert(
                id: id,
                title: title,
                description: description,
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
          prefetchHooksCallback: ({itemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (itemsRefs) db.items],
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
                          $$ItemPacksTableReferences(db, table, p0).itemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.packId == item.id),
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
      PrefetchHooks Function({bool itemsRefs})
    >;
typedef $$ItemsTableCreateCompanionBuilder =
    ItemsCompanion Function({
      Value<int> id,
      required int packId,
      required String title,
      Value<String?> description,
      Value<String> status,
      required String type,
      Value<String?> fixedScheduleType,
      Value<int?> fixedScheduleInterval,
      Value<int?> fixedMonthlyDay,
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
      Value<int?> resourceAnchorDate,
      Value<int?> resourceDurationDays,
      Value<int?> resourceExpectedBeforeDays,
      Value<int?> resourceWarningBeforeDays,
      Value<int?> resourceDangerBeforeDays,
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
      Value<String?> fixedScheduleType,
      Value<int?> fixedScheduleInterval,
      Value<int?> fixedMonthlyDay,
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
      Value<int?> resourceAnchorDate,
      Value<int?> resourceDurationDays,
      Value<int?> resourceExpectedBeforeDays,
      Value<int?> resourceWarningBeforeDays,
      Value<int?> resourceDangerBeforeDays,
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

  ColumnFilters<int> get resourceAnchorDate => $composableBuilder(
    column: $table.resourceAnchorDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resourceDurationDays => $composableBuilder(
    column: $table.resourceDurationDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resourceExpectedBeforeDays => $composableBuilder(
    column: $table.resourceExpectedBeforeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resourceWarningBeforeDays => $composableBuilder(
    column: $table.resourceWarningBeforeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resourceDangerBeforeDays => $composableBuilder(
    column: $table.resourceDangerBeforeDays,
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

  ColumnOrderings<int> get resourceAnchorDate => $composableBuilder(
    column: $table.resourceAnchorDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resourceDurationDays => $composableBuilder(
    column: $table.resourceDurationDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resourceExpectedBeforeDays => $composableBuilder(
    column: $table.resourceExpectedBeforeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resourceWarningBeforeDays => $composableBuilder(
    column: $table.resourceWarningBeforeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resourceDangerBeforeDays => $composableBuilder(
    column: $table.resourceDangerBeforeDays,
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

  GeneratedColumn<int> get resourceAnchorDate => $composableBuilder(
    column: $table.resourceAnchorDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get resourceDurationDays => $composableBuilder(
    column: $table.resourceDurationDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get resourceExpectedBeforeDays => $composableBuilder(
    column: $table.resourceExpectedBeforeDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get resourceWarningBeforeDays => $composableBuilder(
    column: $table.resourceWarningBeforeDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get resourceDangerBeforeDays => $composableBuilder(
    column: $table.resourceDangerBeforeDays,
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
          PrefetchHooks Function({bool packId, bool itemActionRecordsRefs})
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
                Value<String?> fixedScheduleType = const Value.absent(),
                Value<int?> fixedScheduleInterval = const Value.absent(),
                Value<int?> fixedMonthlyDay = const Value.absent(),
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
                Value<int?> resourceAnchorDate = const Value.absent(),
                Value<int?> resourceDurationDays = const Value.absent(),
                Value<int?> resourceExpectedBeforeDays = const Value.absent(),
                Value<int?> resourceWarningBeforeDays = const Value.absent(),
                Value<int?> resourceDangerBeforeDays = const Value.absent(),
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
                fixedScheduleType: fixedScheduleType,
                fixedScheduleInterval: fixedScheduleInterval,
                fixedMonthlyDay: fixedMonthlyDay,
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
                resourceAnchorDate: resourceAnchorDate,
                resourceDurationDays: resourceDurationDays,
                resourceExpectedBeforeDays: resourceExpectedBeforeDays,
                resourceWarningBeforeDays: resourceWarningBeforeDays,
                resourceDangerBeforeDays: resourceDangerBeforeDays,
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
                Value<String?> fixedScheduleType = const Value.absent(),
                Value<int?> fixedScheduleInterval = const Value.absent(),
                Value<int?> fixedMonthlyDay = const Value.absent(),
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
                Value<int?> resourceAnchorDate = const Value.absent(),
                Value<int?> resourceDurationDays = const Value.absent(),
                Value<int?> resourceExpectedBeforeDays = const Value.absent(),
                Value<int?> resourceWarningBeforeDays = const Value.absent(),
                Value<int?> resourceDangerBeforeDays = const Value.absent(),
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
                fixedScheduleType: fixedScheduleType,
                fixedScheduleInterval: fixedScheduleInterval,
                fixedMonthlyDay: fixedMonthlyDay,
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
                resourceAnchorDate: resourceAnchorDate,
                resourceDurationDays: resourceDurationDays,
                resourceExpectedBeforeDays: resourceExpectedBeforeDays,
                resourceWarningBeforeDays: resourceWarningBeforeDays,
                resourceDangerBeforeDays: resourceDangerBeforeDays,
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
              ({packId = false, itemActionRecordsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (itemActionRecordsRefs) db.itemActionRecords,
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
      PrefetchHooks Function({bool packId, bool itemActionRecordsRefs})
    >;
typedef $$ItemPackTemplatesTableCreateCompanionBuilder =
    ItemPackTemplatesCompanion Function({
      Value<int> id,
      required String name,
      required String category,
      required String description,
      required int createdAt,
      required int updatedAt,
    });
typedef $$ItemPackTemplatesTableUpdateCompanionBuilder =
    ItemPackTemplatesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> category,
      Value<String> description,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$ItemPackTemplatesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ItemPackTemplatesTable,
          ItemPackTemplateRow
        > {
  $$ItemPackTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ItemTemplateItemsTable, List<ItemTemplateItemRow>>
  _itemTemplateItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.itemTemplateItems,
        aliasName: $_aliasNameGenerator(
          db.itemPackTemplates.id,
          db.itemTemplateItems.templateId,
        ),
      );

  $$ItemTemplateItemsTableProcessedTableManager get itemTemplateItemsRefs {
    final manager = $$ItemTemplateItemsTableTableManager(
      $_db,
      $_db.itemTemplateItems,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _itemTemplateItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemPackTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $ItemPackTemplatesTable> {
  $$ItemPackTemplatesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
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

  Expression<bool> itemTemplateItemsRefs(
    Expression<bool> Function($$ItemTemplateItemsTableFilterComposer f) f,
  ) {
    final $$ItemTemplateItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemTemplateItems,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemTemplateItemsTableFilterComposer(
            $db: $db,
            $table: $db.itemTemplateItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemPackTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemPackTemplatesTable> {
  $$ItemPackTemplatesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
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

class $$ItemPackTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemPackTemplatesTable> {
  $$ItemPackTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> itemTemplateItemsRefs<T extends Object>(
    Expression<T> Function($$ItemTemplateItemsTableAnnotationComposer a) f,
  ) {
    final $$ItemTemplateItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.itemTemplateItems,
          getReferencedColumn: (t) => t.templateId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ItemTemplateItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.itemTemplateItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ItemPackTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemPackTemplatesTable,
          ItemPackTemplateRow,
          $$ItemPackTemplatesTableFilterComposer,
          $$ItemPackTemplatesTableOrderingComposer,
          $$ItemPackTemplatesTableAnnotationComposer,
          $$ItemPackTemplatesTableCreateCompanionBuilder,
          $$ItemPackTemplatesTableUpdateCompanionBuilder,
          (ItemPackTemplateRow, $$ItemPackTemplatesTableReferences),
          ItemPackTemplateRow,
          PrefetchHooks Function({bool itemTemplateItemsRefs})
        > {
  $$ItemPackTemplatesTableTableManager(
    _$AppDatabase db,
    $ItemPackTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemPackTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemPackTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemPackTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ItemPackTemplatesCompanion(
                id: id,
                name: name,
                category: category,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String category,
                required String description,
                required int createdAt,
                required int updatedAt,
              }) => ItemPackTemplatesCompanion.insert(
                id: id,
                name: name,
                category: category,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ItemPackTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemTemplateItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (itemTemplateItemsRefs) db.itemTemplateItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itemTemplateItemsRefs)
                    await $_getPrefetchedData<
                      ItemPackTemplateRow,
                      $ItemPackTemplatesTable,
                      ItemTemplateItemRow
                    >(
                      currentTable: table,
                      referencedTable: $$ItemPackTemplatesTableReferences
                          ._itemTemplateItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ItemPackTemplatesTableReferences(
                            db,
                            table,
                            p0,
                          ).itemTemplateItemsRefs,
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

typedef $$ItemPackTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemPackTemplatesTable,
      ItemPackTemplateRow,
      $$ItemPackTemplatesTableFilterComposer,
      $$ItemPackTemplatesTableOrderingComposer,
      $$ItemPackTemplatesTableAnnotationComposer,
      $$ItemPackTemplatesTableCreateCompanionBuilder,
      $$ItemPackTemplatesTableUpdateCompanionBuilder,
      (ItemPackTemplateRow, $$ItemPackTemplatesTableReferences),
      ItemPackTemplateRow,
      PrefetchHooks Function({bool itemTemplateItemsRefs})
    >;
typedef $$ItemTemplateItemsTableCreateCompanionBuilder =
    ItemTemplateItemsCompanion Function({
      Value<int> id,
      required int templateId,
      required String title,
      Value<String?> description,
      required String type,
      Value<String?> fixedScheduleType,
      Value<int?> fixedScheduleInterval,
      Value<int?> fixedMonthlyDay,
      Value<String?> fixedTimeOfDay,
      Value<String?> fixedOverduePolicy,
      Value<int?> fixedExpectedBeforeMinutes,
      Value<int?> fixedWarningBeforeMinutes,
      Value<int?> fixedDangerBeforeMinutes,
      Value<int?> stateExpectedAfterMinutes,
      Value<int?> stateWarningAfterMinutes,
      Value<int?> stateDangerAfterMinutes,
      Value<int?> resourceDurationDays,
      Value<int?> resourceExpectedBeforeDays,
      Value<int?> resourceWarningBeforeDays,
      Value<int?> resourceDangerBeforeDays,
      required int createdAt,
      required int updatedAt,
    });
typedef $$ItemTemplateItemsTableUpdateCompanionBuilder =
    ItemTemplateItemsCompanion Function({
      Value<int> id,
      Value<int> templateId,
      Value<String> title,
      Value<String?> description,
      Value<String> type,
      Value<String?> fixedScheduleType,
      Value<int?> fixedScheduleInterval,
      Value<int?> fixedMonthlyDay,
      Value<String?> fixedTimeOfDay,
      Value<String?> fixedOverduePolicy,
      Value<int?> fixedExpectedBeforeMinutes,
      Value<int?> fixedWarningBeforeMinutes,
      Value<int?> fixedDangerBeforeMinutes,
      Value<int?> stateExpectedAfterMinutes,
      Value<int?> stateWarningAfterMinutes,
      Value<int?> stateDangerAfterMinutes,
      Value<int?> resourceDurationDays,
      Value<int?> resourceExpectedBeforeDays,
      Value<int?> resourceWarningBeforeDays,
      Value<int?> resourceDangerBeforeDays,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$ItemTemplateItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ItemTemplateItemsTable,
          ItemTemplateItemRow
        > {
  $$ItemTemplateItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ItemPackTemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.itemPackTemplates.createAlias(
        $_aliasNameGenerator(
          db.itemTemplateItems.templateId,
          db.itemPackTemplates.id,
        ),
      );

  $$ItemPackTemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<int>('template_id')!;

    final manager = $$ItemPackTemplatesTableTableManager(
      $_db,
      $_db.itemPackTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItemTemplateItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemTemplateItemsTable> {
  $$ItemTemplateItemsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
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

  ColumnFilters<int> get resourceDurationDays => $composableBuilder(
    column: $table.resourceDurationDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resourceExpectedBeforeDays => $composableBuilder(
    column: $table.resourceExpectedBeforeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resourceWarningBeforeDays => $composableBuilder(
    column: $table.resourceWarningBeforeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resourceDangerBeforeDays => $composableBuilder(
    column: $table.resourceDangerBeforeDays,
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

  $$ItemPackTemplatesTableFilterComposer get templateId {
    final $$ItemPackTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.itemPackTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemPackTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.itemPackTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemTemplateItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemTemplateItemsTable> {
  $$ItemTemplateItemsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
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

  ColumnOrderings<int> get resourceDurationDays => $composableBuilder(
    column: $table.resourceDurationDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resourceExpectedBeforeDays => $composableBuilder(
    column: $table.resourceExpectedBeforeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resourceWarningBeforeDays => $composableBuilder(
    column: $table.resourceWarningBeforeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resourceDangerBeforeDays => $composableBuilder(
    column: $table.resourceDangerBeforeDays,
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

  $$ItemPackTemplatesTableOrderingComposer get templateId {
    final $$ItemPackTemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.itemPackTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemPackTemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.itemPackTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemTemplateItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemTemplateItemsTable> {
  $$ItemTemplateItemsTableAnnotationComposer({
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

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

  GeneratedColumn<int> get resourceDurationDays => $composableBuilder(
    column: $table.resourceDurationDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get resourceExpectedBeforeDays => $composableBuilder(
    column: $table.resourceExpectedBeforeDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get resourceWarningBeforeDays => $composableBuilder(
    column: $table.resourceWarningBeforeDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get resourceDangerBeforeDays => $composableBuilder(
    column: $table.resourceDangerBeforeDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ItemPackTemplatesTableAnnotationComposer get templateId {
    final $$ItemPackTemplatesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.templateId,
          referencedTable: $db.itemPackTemplates,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ItemPackTemplatesTableAnnotationComposer(
                $db: $db,
                $table: $db.itemPackTemplates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ItemTemplateItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemTemplateItemsTable,
          ItemTemplateItemRow,
          $$ItemTemplateItemsTableFilterComposer,
          $$ItemTemplateItemsTableOrderingComposer,
          $$ItemTemplateItemsTableAnnotationComposer,
          $$ItemTemplateItemsTableCreateCompanionBuilder,
          $$ItemTemplateItemsTableUpdateCompanionBuilder,
          (ItemTemplateItemRow, $$ItemTemplateItemsTableReferences),
          ItemTemplateItemRow,
          PrefetchHooks Function({bool templateId})
        > {
  $$ItemTemplateItemsTableTableManager(
    _$AppDatabase db,
    $ItemTemplateItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemTemplateItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemTemplateItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemTemplateItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> templateId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> fixedScheduleType = const Value.absent(),
                Value<int?> fixedScheduleInterval = const Value.absent(),
                Value<int?> fixedMonthlyDay = const Value.absent(),
                Value<String?> fixedTimeOfDay = const Value.absent(),
                Value<String?> fixedOverduePolicy = const Value.absent(),
                Value<int?> fixedExpectedBeforeMinutes = const Value.absent(),
                Value<int?> fixedWarningBeforeMinutes = const Value.absent(),
                Value<int?> fixedDangerBeforeMinutes = const Value.absent(),
                Value<int?> stateExpectedAfterMinutes = const Value.absent(),
                Value<int?> stateWarningAfterMinutes = const Value.absent(),
                Value<int?> stateDangerAfterMinutes = const Value.absent(),
                Value<int?> resourceDurationDays = const Value.absent(),
                Value<int?> resourceExpectedBeforeDays = const Value.absent(),
                Value<int?> resourceWarningBeforeDays = const Value.absent(),
                Value<int?> resourceDangerBeforeDays = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ItemTemplateItemsCompanion(
                id: id,
                templateId: templateId,
                title: title,
                description: description,
                type: type,
                fixedScheduleType: fixedScheduleType,
                fixedScheduleInterval: fixedScheduleInterval,
                fixedMonthlyDay: fixedMonthlyDay,
                fixedTimeOfDay: fixedTimeOfDay,
                fixedOverduePolicy: fixedOverduePolicy,
                fixedExpectedBeforeMinutes: fixedExpectedBeforeMinutes,
                fixedWarningBeforeMinutes: fixedWarningBeforeMinutes,
                fixedDangerBeforeMinutes: fixedDangerBeforeMinutes,
                stateExpectedAfterMinutes: stateExpectedAfterMinutes,
                stateWarningAfterMinutes: stateWarningAfterMinutes,
                stateDangerAfterMinutes: stateDangerAfterMinutes,
                resourceDurationDays: resourceDurationDays,
                resourceExpectedBeforeDays: resourceExpectedBeforeDays,
                resourceWarningBeforeDays: resourceWarningBeforeDays,
                resourceDangerBeforeDays: resourceDangerBeforeDays,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int templateId,
                required String title,
                Value<String?> description = const Value.absent(),
                required String type,
                Value<String?> fixedScheduleType = const Value.absent(),
                Value<int?> fixedScheduleInterval = const Value.absent(),
                Value<int?> fixedMonthlyDay = const Value.absent(),
                Value<String?> fixedTimeOfDay = const Value.absent(),
                Value<String?> fixedOverduePolicy = const Value.absent(),
                Value<int?> fixedExpectedBeforeMinutes = const Value.absent(),
                Value<int?> fixedWarningBeforeMinutes = const Value.absent(),
                Value<int?> fixedDangerBeforeMinutes = const Value.absent(),
                Value<int?> stateExpectedAfterMinutes = const Value.absent(),
                Value<int?> stateWarningAfterMinutes = const Value.absent(),
                Value<int?> stateDangerAfterMinutes = const Value.absent(),
                Value<int?> resourceDurationDays = const Value.absent(),
                Value<int?> resourceExpectedBeforeDays = const Value.absent(),
                Value<int?> resourceWarningBeforeDays = const Value.absent(),
                Value<int?> resourceDangerBeforeDays = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ItemTemplateItemsCompanion.insert(
                id: id,
                templateId: templateId,
                title: title,
                description: description,
                type: type,
                fixedScheduleType: fixedScheduleType,
                fixedScheduleInterval: fixedScheduleInterval,
                fixedMonthlyDay: fixedMonthlyDay,
                fixedTimeOfDay: fixedTimeOfDay,
                fixedOverduePolicy: fixedOverduePolicy,
                fixedExpectedBeforeMinutes: fixedExpectedBeforeMinutes,
                fixedWarningBeforeMinutes: fixedWarningBeforeMinutes,
                fixedDangerBeforeMinutes: fixedDangerBeforeMinutes,
                stateExpectedAfterMinutes: stateExpectedAfterMinutes,
                stateWarningAfterMinutes: stateWarningAfterMinutes,
                stateDangerAfterMinutes: stateDangerAfterMinutes,
                resourceDurationDays: resourceDurationDays,
                resourceExpectedBeforeDays: resourceExpectedBeforeDays,
                resourceWarningBeforeDays: resourceWarningBeforeDays,
                resourceDangerBeforeDays: resourceDangerBeforeDays,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ItemTemplateItemsTableReferences(db, table, e),
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
                                    $$ItemTemplateItemsTableReferences
                                        ._templateIdTable(db),
                                referencedColumn:
                                    $$ItemTemplateItemsTableReferences
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

typedef $$ItemTemplateItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemTemplateItemsTable,
      ItemTemplateItemRow,
      $$ItemTemplateItemsTableFilterComposer,
      $$ItemTemplateItemsTableOrderingComposer,
      $$ItemTemplateItemsTableAnnotationComposer,
      $$ItemTemplateItemsTableCreateCompanionBuilder,
      $$ItemTemplateItemsTableUpdateCompanionBuilder,
      (ItemTemplateItemRow, $$ItemTemplateItemsTableReferences),
      ItemTemplateItemRow,
      PrefetchHooks Function({bool templateId})
    >;
typedef $$ItemActionRecordsTableCreateCompanionBuilder =
    ItemActionRecordsCompanion Function({
      Value<int> id,
      required int itemId,
      required String actionType,
      required int actionDate,
      Value<String?> remark,
      Value<String?> payload,
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
          PrefetchHooks Function({bool itemId})
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
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ItemActionRecordsCompanion(
                id: id,
                itemId: itemId,
                actionType: actionType,
                actionDate: actionDate,
                remark: remark,
                payload: payload,
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
                required int createdAt,
                required int updatedAt,
              }) => ItemActionRecordsCompanion.insert(
                id: id,
                itemId: itemId,
                actionType: actionType,
                actionDate: actionDate,
                remark: remark,
                payload: payload,
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
          prefetchHooksCallback: ({itemId = false}) {
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
                return [];
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
      PrefetchHooks Function({bool itemId})
    >;
typedef $$TimelinesTableCreateCompanionBuilder =
    TimelinesCompanion Function({
      Value<int> id,
      required String title,
      required int startDate,
      required String displayUnit,
      required String status,
      required int createdAt,
      required int updatedAt,
    });
typedef $$TimelinesTableUpdateCompanionBuilder =
    TimelinesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<int> startDate,
      Value<String> displayUnit,
      Value<String> status,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$TimelinesTableReferences
    extends BaseReferences<_$AppDatabase, $TimelinesTable, TimelineRow> {
  $$TimelinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $TimelineMilestoneRulesTable,
    List<TimelineMilestoneRuleRow>
  >
  _timelineMilestoneRulesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.timelineMilestoneRules,
        aliasName: $_aliasNameGenerator(
          db.timelines.id,
          db.timelineMilestoneRules.timelineId,
        ),
      );

  $$TimelineMilestoneRulesTableProcessedTableManager
  get timelineMilestoneRulesRefs {
    final manager = $$TimelineMilestoneRulesTableTableManager(
      $_db,
      $_db.timelineMilestoneRules,
    ).filter((f) => f.timelineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _timelineMilestoneRulesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TimelineMilestoneRecordsTable,
    List<TimelineMilestoneRecordRow>
  >
  _timelineMilestoneRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.timelineMilestoneRecords,
        aliasName: $_aliasNameGenerator(
          db.timelines.id,
          db.timelineMilestoneRecords.timelineId,
        ),
      );

  $$TimelineMilestoneRecordsTableProcessedTableManager
  get timelineMilestoneRecordsRefs {
    final manager = $$TimelineMilestoneRecordsTableTableManager(
      $_db,
      $_db.timelineMilestoneRecords,
    ).filter((f) => f.timelineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _timelineMilestoneRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TimelinesTableFilterComposer
    extends Composer<_$AppDatabase, $TimelinesTable> {
  $$TimelinesTableFilterComposer({
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

  ColumnFilters<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayUnit => $composableBuilder(
    column: $table.displayUnit,
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

  Expression<bool> timelineMilestoneRulesRefs(
    Expression<bool> Function($$TimelineMilestoneRulesTableFilterComposer f) f,
  ) {
    final $$TimelineMilestoneRulesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.timelineMilestoneRules,
          getReferencedColumn: (t) => t.timelineId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TimelineMilestoneRulesTableFilterComposer(
                $db: $db,
                $table: $db.timelineMilestoneRules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> timelineMilestoneRecordsRefs(
    Expression<bool> Function($$TimelineMilestoneRecordsTableFilterComposer f)
    f,
  ) {
    final $$TimelineMilestoneRecordsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.timelineMilestoneRecords,
          getReferencedColumn: (t) => t.timelineId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TimelineMilestoneRecordsTableFilterComposer(
                $db: $db,
                $table: $db.timelineMilestoneRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TimelinesTableOrderingComposer
    extends Composer<_$AppDatabase, $TimelinesTable> {
  $$TimelinesTableOrderingComposer({
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

  ColumnOrderings<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayUnit => $composableBuilder(
    column: $table.displayUnit,
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
}

class $$TimelinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimelinesTable> {
  $$TimelinesTableAnnotationComposer({
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

  GeneratedColumn<int> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get displayUnit => $composableBuilder(
    column: $table.displayUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> timelineMilestoneRulesRefs<T extends Object>(
    Expression<T> Function($$TimelineMilestoneRulesTableAnnotationComposer a) f,
  ) {
    final $$TimelineMilestoneRulesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.timelineMilestoneRules,
          getReferencedColumn: (t) => t.timelineId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TimelineMilestoneRulesTableAnnotationComposer(
                $db: $db,
                $table: $db.timelineMilestoneRules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> timelineMilestoneRecordsRefs<T extends Object>(
    Expression<T> Function($$TimelineMilestoneRecordsTableAnnotationComposer a)
    f,
  ) {
    final $$TimelineMilestoneRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.timelineMilestoneRecords,
          getReferencedColumn: (t) => t.timelineId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TimelineMilestoneRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.timelineMilestoneRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TimelinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimelinesTable,
          TimelineRow,
          $$TimelinesTableFilterComposer,
          $$TimelinesTableOrderingComposer,
          $$TimelinesTableAnnotationComposer,
          $$TimelinesTableCreateCompanionBuilder,
          $$TimelinesTableUpdateCompanionBuilder,
          (TimelineRow, $$TimelinesTableReferences),
          TimelineRow,
          PrefetchHooks Function({
            bool timelineMilestoneRulesRefs,
            bool timelineMilestoneRecordsRefs,
          })
        > {
  $$TimelinesTableTableManager(_$AppDatabase db, $TimelinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimelinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimelinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimelinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> startDate = const Value.absent(),
                Value<String> displayUnit = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => TimelinesCompanion(
                id: id,
                title: title,
                startDate: startDate,
                displayUnit: displayUnit,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required int startDate,
                required String displayUnit,
                required String status,
                required int createdAt,
                required int updatedAt,
              }) => TimelinesCompanion.insert(
                id: id,
                title: title,
                startDate: startDate,
                displayUnit: displayUnit,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TimelinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                timelineMilestoneRulesRefs = false,
                timelineMilestoneRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (timelineMilestoneRulesRefs) db.timelineMilestoneRules,
                    if (timelineMilestoneRecordsRefs)
                      db.timelineMilestoneRecords,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (timelineMilestoneRulesRefs)
                        await $_getPrefetchedData<
                          TimelineRow,
                          $TimelinesTable,
                          TimelineMilestoneRuleRow
                        >(
                          currentTable: table,
                          referencedTable: $$TimelinesTableReferences
                              ._timelineMilestoneRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TimelinesTableReferences(
                                db,
                                table,
                                p0,
                              ).timelineMilestoneRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.timelineId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (timelineMilestoneRecordsRefs)
                        await $_getPrefetchedData<
                          TimelineRow,
                          $TimelinesTable,
                          TimelineMilestoneRecordRow
                        >(
                          currentTable: table,
                          referencedTable: $$TimelinesTableReferences
                              ._timelineMilestoneRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TimelinesTableReferences(
                                db,
                                table,
                                p0,
                              ).timelineMilestoneRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.timelineId == item.id,
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

typedef $$TimelinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimelinesTable,
      TimelineRow,
      $$TimelinesTableFilterComposer,
      $$TimelinesTableOrderingComposer,
      $$TimelinesTableAnnotationComposer,
      $$TimelinesTableCreateCompanionBuilder,
      $$TimelinesTableUpdateCompanionBuilder,
      (TimelineRow, $$TimelinesTableReferences),
      TimelineRow,
      PrefetchHooks Function({
        bool timelineMilestoneRulesRefs,
        bool timelineMilestoneRecordsRefs,
      })
    >;
typedef $$TimelineMilestoneRulesTableCreateCompanionBuilder =
    TimelineMilestoneRulesCompanion Function({
      Value<int> id,
      required int timelineId,
      required String type,
      required int intervalValue,
      required String intervalUnit,
      Value<String?> labelTemplate,
      Value<int> reminderOffsetDays,
      Value<String> status,
      required int createdAt,
      required int updatedAt,
    });
typedef $$TimelineMilestoneRulesTableUpdateCompanionBuilder =
    TimelineMilestoneRulesCompanion Function({
      Value<int> id,
      Value<int> timelineId,
      Value<String> type,
      Value<int> intervalValue,
      Value<String> intervalUnit,
      Value<String?> labelTemplate,
      Value<int> reminderOffsetDays,
      Value<String> status,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$TimelineMilestoneRulesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TimelineMilestoneRulesTable,
          TimelineMilestoneRuleRow
        > {
  $$TimelineMilestoneRulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TimelinesTable _timelineIdTable(_$AppDatabase db) =>
      db.timelines.createAlias(
        $_aliasNameGenerator(
          db.timelineMilestoneRules.timelineId,
          db.timelines.id,
        ),
      );

  $$TimelinesTableProcessedTableManager get timelineId {
    final $_column = $_itemColumn<int>('timeline_id')!;

    final manager = $$TimelinesTableTableManager(
      $_db,
      $_db.timelines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_timelineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $TimelineMilestoneRecordsTable,
    List<TimelineMilestoneRecordRow>
  >
  _timelineMilestoneRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.timelineMilestoneRecords,
        aliasName: $_aliasNameGenerator(
          db.timelineMilestoneRules.id,
          db.timelineMilestoneRecords.ruleId,
        ),
      );

  $$TimelineMilestoneRecordsTableProcessedTableManager
  get timelineMilestoneRecordsRefs {
    final manager = $$TimelineMilestoneRecordsTableTableManager(
      $_db,
      $_db.timelineMilestoneRecords,
    ).filter((f) => f.ruleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _timelineMilestoneRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TimelineMilestoneRulesTableFilterComposer
    extends Composer<_$AppDatabase, $TimelineMilestoneRulesTable> {
  $$TimelineMilestoneRulesTableFilterComposer({
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

  $$TimelinesTableFilterComposer get timelineId {
    final $$TimelinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timelineId,
      referencedTable: $db.timelines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelinesTableFilterComposer(
            $db: $db,
            $table: $db.timelines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> timelineMilestoneRecordsRefs(
    Expression<bool> Function($$TimelineMilestoneRecordsTableFilterComposer f)
    f,
  ) {
    final $$TimelineMilestoneRecordsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.timelineMilestoneRecords,
          getReferencedColumn: (t) => t.ruleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TimelineMilestoneRecordsTableFilterComposer(
                $db: $db,
                $table: $db.timelineMilestoneRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TimelineMilestoneRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $TimelineMilestoneRulesTable> {
  $$TimelineMilestoneRulesTableOrderingComposer({
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

  $$TimelinesTableOrderingComposer get timelineId {
    final $$TimelinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timelineId,
      referencedTable: $db.timelines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelinesTableOrderingComposer(
            $db: $db,
            $table: $db.timelines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimelineMilestoneRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimelineMilestoneRulesTable> {
  $$TimelineMilestoneRulesTableAnnotationComposer({
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

  $$TimelinesTableAnnotationComposer get timelineId {
    final $$TimelinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timelineId,
      referencedTable: $db.timelines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelinesTableAnnotationComposer(
            $db: $db,
            $table: $db.timelines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> timelineMilestoneRecordsRefs<T extends Object>(
    Expression<T> Function($$TimelineMilestoneRecordsTableAnnotationComposer a)
    f,
  ) {
    final $$TimelineMilestoneRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.timelineMilestoneRecords,
          getReferencedColumn: (t) => t.ruleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TimelineMilestoneRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.timelineMilestoneRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TimelineMilestoneRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimelineMilestoneRulesTable,
          TimelineMilestoneRuleRow,
          $$TimelineMilestoneRulesTableFilterComposer,
          $$TimelineMilestoneRulesTableOrderingComposer,
          $$TimelineMilestoneRulesTableAnnotationComposer,
          $$TimelineMilestoneRulesTableCreateCompanionBuilder,
          $$TimelineMilestoneRulesTableUpdateCompanionBuilder,
          (TimelineMilestoneRuleRow, $$TimelineMilestoneRulesTableReferences),
          TimelineMilestoneRuleRow,
          PrefetchHooks Function({
            bool timelineId,
            bool timelineMilestoneRecordsRefs,
          })
        > {
  $$TimelineMilestoneRulesTableTableManager(
    _$AppDatabase db,
    $TimelineMilestoneRulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimelineMilestoneRulesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TimelineMilestoneRulesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TimelineMilestoneRulesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> timelineId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> intervalValue = const Value.absent(),
                Value<String> intervalUnit = const Value.absent(),
                Value<String?> labelTemplate = const Value.absent(),
                Value<int> reminderOffsetDays = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => TimelineMilestoneRulesCompanion(
                id: id,
                timelineId: timelineId,
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
                required int timelineId,
                required String type,
                required int intervalValue,
                required String intervalUnit,
                Value<String?> labelTemplate = const Value.absent(),
                Value<int> reminderOffsetDays = const Value.absent(),
                Value<String> status = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => TimelineMilestoneRulesCompanion.insert(
                id: id,
                timelineId: timelineId,
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
                  $$TimelineMilestoneRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({timelineId = false, timelineMilestoneRecordsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (timelineMilestoneRecordsRefs)
                      db.timelineMilestoneRecords,
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
                        if (timelineId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.timelineId,
                                    referencedTable:
                                        $$TimelineMilestoneRulesTableReferences
                                            ._timelineIdTable(db),
                                    referencedColumn:
                                        $$TimelineMilestoneRulesTableReferences
                                            ._timelineIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (timelineMilestoneRecordsRefs)
                        await $_getPrefetchedData<
                          TimelineMilestoneRuleRow,
                          $TimelineMilestoneRulesTable,
                          TimelineMilestoneRecordRow
                        >(
                          currentTable: table,
                          referencedTable:
                              $$TimelineMilestoneRulesTableReferences
                                  ._timelineMilestoneRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TimelineMilestoneRulesTableReferences(
                                db,
                                table,
                                p0,
                              ).timelineMilestoneRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ruleId == item.id,
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

typedef $$TimelineMilestoneRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimelineMilestoneRulesTable,
      TimelineMilestoneRuleRow,
      $$TimelineMilestoneRulesTableFilterComposer,
      $$TimelineMilestoneRulesTableOrderingComposer,
      $$TimelineMilestoneRulesTableAnnotationComposer,
      $$TimelineMilestoneRulesTableCreateCompanionBuilder,
      $$TimelineMilestoneRulesTableUpdateCompanionBuilder,
      (TimelineMilestoneRuleRow, $$TimelineMilestoneRulesTableReferences),
      TimelineMilestoneRuleRow,
      PrefetchHooks Function({
        bool timelineId,
        bool timelineMilestoneRecordsRefs,
      })
    >;
typedef $$TimelineMilestoneRecordsTableCreateCompanionBuilder =
    TimelineMilestoneRecordsCompanion Function({
      Value<int> id,
      required int timelineId,
      required int ruleId,
      required int occurrenceIndex,
      required int targetDate,
      required String status,
      Value<int?> notifiedAt,
      Value<int?> actedAt,
      required int createdAt,
      required int updatedAt,
    });
typedef $$TimelineMilestoneRecordsTableUpdateCompanionBuilder =
    TimelineMilestoneRecordsCompanion Function({
      Value<int> id,
      Value<int> timelineId,
      Value<int> ruleId,
      Value<int> occurrenceIndex,
      Value<int> targetDate,
      Value<String> status,
      Value<int?> notifiedAt,
      Value<int?> actedAt,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$TimelineMilestoneRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TimelineMilestoneRecordsTable,
          TimelineMilestoneRecordRow
        > {
  $$TimelineMilestoneRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TimelinesTable _timelineIdTable(_$AppDatabase db) =>
      db.timelines.createAlias(
        $_aliasNameGenerator(
          db.timelineMilestoneRecords.timelineId,
          db.timelines.id,
        ),
      );

  $$TimelinesTableProcessedTableManager get timelineId {
    final $_column = $_itemColumn<int>('timeline_id')!;

    final manager = $$TimelinesTableTableManager(
      $_db,
      $_db.timelines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_timelineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TimelineMilestoneRulesTable _ruleIdTable(_$AppDatabase db) =>
      db.timelineMilestoneRules.createAlias(
        $_aliasNameGenerator(
          db.timelineMilestoneRecords.ruleId,
          db.timelineMilestoneRules.id,
        ),
      );

  $$TimelineMilestoneRulesTableProcessedTableManager get ruleId {
    final $_column = $_itemColumn<int>('rule_id')!;

    final manager = $$TimelineMilestoneRulesTableTableManager(
      $_db,
      $_db.timelineMilestoneRules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ruleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TimelineMilestoneRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $TimelineMilestoneRecordsTable> {
  $$TimelineMilestoneRecordsTableFilterComposer({
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

  ColumnFilters<int> get occurrenceIndex => $composableBuilder(
    column: $table.occurrenceIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notifiedAt => $composableBuilder(
    column: $table.notifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actedAt => $composableBuilder(
    column: $table.actedAt,
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

  $$TimelinesTableFilterComposer get timelineId {
    final $$TimelinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timelineId,
      referencedTable: $db.timelines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelinesTableFilterComposer(
            $db: $db,
            $table: $db.timelines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TimelineMilestoneRulesTableFilterComposer get ruleId {
    final $$TimelineMilestoneRulesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.ruleId,
          referencedTable: $db.timelineMilestoneRules,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TimelineMilestoneRulesTableFilterComposer(
                $db: $db,
                $table: $db.timelineMilestoneRules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$TimelineMilestoneRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $TimelineMilestoneRecordsTable> {
  $$TimelineMilestoneRecordsTableOrderingComposer({
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

  ColumnOrderings<int> get occurrenceIndex => $composableBuilder(
    column: $table.occurrenceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notifiedAt => $composableBuilder(
    column: $table.notifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actedAt => $composableBuilder(
    column: $table.actedAt,
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

  $$TimelinesTableOrderingComposer get timelineId {
    final $$TimelinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timelineId,
      referencedTable: $db.timelines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelinesTableOrderingComposer(
            $db: $db,
            $table: $db.timelines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TimelineMilestoneRulesTableOrderingComposer get ruleId {
    final $$TimelineMilestoneRulesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.ruleId,
          referencedTable: $db.timelineMilestoneRules,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TimelineMilestoneRulesTableOrderingComposer(
                $db: $db,
                $table: $db.timelineMilestoneRules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$TimelineMilestoneRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimelineMilestoneRecordsTable> {
  $$TimelineMilestoneRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get occurrenceIndex => $composableBuilder(
    column: $table.occurrenceIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get notifiedAt => $composableBuilder(
    column: $table.notifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actedAt =>
      $composableBuilder(column: $table.actedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TimelinesTableAnnotationComposer get timelineId {
    final $$TimelinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timelineId,
      referencedTable: $db.timelines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelinesTableAnnotationComposer(
            $db: $db,
            $table: $db.timelines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TimelineMilestoneRulesTableAnnotationComposer get ruleId {
    final $$TimelineMilestoneRulesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.ruleId,
          referencedTable: $db.timelineMilestoneRules,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TimelineMilestoneRulesTableAnnotationComposer(
                $db: $db,
                $table: $db.timelineMilestoneRules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$TimelineMilestoneRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimelineMilestoneRecordsTable,
          TimelineMilestoneRecordRow,
          $$TimelineMilestoneRecordsTableFilterComposer,
          $$TimelineMilestoneRecordsTableOrderingComposer,
          $$TimelineMilestoneRecordsTableAnnotationComposer,
          $$TimelineMilestoneRecordsTableCreateCompanionBuilder,
          $$TimelineMilestoneRecordsTableUpdateCompanionBuilder,
          (
            TimelineMilestoneRecordRow,
            $$TimelineMilestoneRecordsTableReferences,
          ),
          TimelineMilestoneRecordRow,
          PrefetchHooks Function({bool timelineId, bool ruleId})
        > {
  $$TimelineMilestoneRecordsTableTableManager(
    _$AppDatabase db,
    $TimelineMilestoneRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimelineMilestoneRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TimelineMilestoneRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TimelineMilestoneRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> timelineId = const Value.absent(),
                Value<int> ruleId = const Value.absent(),
                Value<int> occurrenceIndex = const Value.absent(),
                Value<int> targetDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> notifiedAt = const Value.absent(),
                Value<int?> actedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => TimelineMilestoneRecordsCompanion(
                id: id,
                timelineId: timelineId,
                ruleId: ruleId,
                occurrenceIndex: occurrenceIndex,
                targetDate: targetDate,
                status: status,
                notifiedAt: notifiedAt,
                actedAt: actedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int timelineId,
                required int ruleId,
                required int occurrenceIndex,
                required int targetDate,
                required String status,
                Value<int?> notifiedAt = const Value.absent(),
                Value<int?> actedAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => TimelineMilestoneRecordsCompanion.insert(
                id: id,
                timelineId: timelineId,
                ruleId: ruleId,
                occurrenceIndex: occurrenceIndex,
                targetDate: targetDate,
                status: status,
                notifiedAt: notifiedAt,
                actedAt: actedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TimelineMilestoneRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({timelineId = false, ruleId = false}) {
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
                    if (timelineId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.timelineId,
                                referencedTable:
                                    $$TimelineMilestoneRecordsTableReferences
                                        ._timelineIdTable(db),
                                referencedColumn:
                                    $$TimelineMilestoneRecordsTableReferences
                                        ._timelineIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (ruleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ruleId,
                                referencedTable:
                                    $$TimelineMilestoneRecordsTableReferences
                                        ._ruleIdTable(db),
                                referencedColumn:
                                    $$TimelineMilestoneRecordsTableReferences
                                        ._ruleIdTable(db)
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

typedef $$TimelineMilestoneRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimelineMilestoneRecordsTable,
      TimelineMilestoneRecordRow,
      $$TimelineMilestoneRecordsTableFilterComposer,
      $$TimelineMilestoneRecordsTableOrderingComposer,
      $$TimelineMilestoneRecordsTableAnnotationComposer,
      $$TimelineMilestoneRecordsTableCreateCompanionBuilder,
      $$TimelineMilestoneRecordsTableUpdateCompanionBuilder,
      (TimelineMilestoneRecordRow, $$TimelineMilestoneRecordsTableReferences),
      TimelineMilestoneRecordRow,
      PrefetchHooks Function({bool timelineId, bool ruleId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ItemPacksTableTableManager get itemPacks =>
      $$ItemPacksTableTableManager(_db, _db.itemPacks);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$ItemPackTemplatesTableTableManager get itemPackTemplates =>
      $$ItemPackTemplatesTableTableManager(_db, _db.itemPackTemplates);
  $$ItemTemplateItemsTableTableManager get itemTemplateItems =>
      $$ItemTemplateItemsTableTableManager(_db, _db.itemTemplateItems);
  $$ItemActionRecordsTableTableManager get itemActionRecords =>
      $$ItemActionRecordsTableTableManager(_db, _db.itemActionRecords);
  $$TimelinesTableTableManager get timelines =>
      $$TimelinesTableTableManager(_db, _db.timelines);
  $$TimelineMilestoneRulesTableTableManager get timelineMilestoneRules =>
      $$TimelineMilestoneRulesTableTableManager(
        _db,
        _db.timelineMilestoneRules,
      );
  $$TimelineMilestoneRecordsTableTableManager get timelineMilestoneRecords =>
      $$TimelineMilestoneRecordsTableTableManager(
        _db,
        _db.timelineMilestoneRecords,
      );
}
