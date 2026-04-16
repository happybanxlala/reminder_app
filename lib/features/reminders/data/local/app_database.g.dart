// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ResponsibilityPacksTable extends ResponsibilityPacks
    with TableInfo<$ResponsibilityPacksTable, ResponsibilityPackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResponsibilityPacksTable(this.attachedDatabase, [this._alias]);
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
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'responsibility_packs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ResponsibilityPackRow> instance, {
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
  ResponsibilityPackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResponsibilityPackRow(
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
  $ResponsibilityPacksTable createAlias(String alias) {
    return $ResponsibilityPacksTable(attachedDatabase, alias);
  }
}

class ResponsibilityPackRow extends DataClass
    implements Insertable<ResponsibilityPackRow> {
  final int id;
  final String title;
  final String? description;
  final int createdAt;
  final int updatedAt;
  const ResponsibilityPackRow({
    required this.id,
    required this.title,
    this.description,
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
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ResponsibilityPacksCompanion toCompanion(bool nullToAbsent) {
    return ResponsibilityPacksCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ResponsibilityPackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ResponsibilityPackRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
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
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ResponsibilityPackRow copyWith({
    int? id,
    String? title,
    Value<String?> description = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => ResponsibilityPackRow(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ResponsibilityPackRow copyWithCompanion(ResponsibilityPacksCompanion data) {
    return ResponsibilityPackRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ResponsibilityPackRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResponsibilityPackRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ResponsibilityPacksCompanion
    extends UpdateCompanion<ResponsibilityPackRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ResponsibilityPacksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ResponsibilityPacksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ResponsibilityPackRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ResponsibilityPacksCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ResponsibilityPacksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
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
    return (StringBuffer('ResponsibilityPacksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ResponsibilityItemsTable extends ResponsibilityItems
    with TableInfo<$ResponsibilityItemsTable, ResponsibilityItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResponsibilityItemsTable(this.attachedDatabase, [this._alias]);
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
      'REFERENCES responsibility_packs (id)',
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
  static const VerificationMeta _stateExpectedIntervalMinutesMeta =
      const VerificationMeta('stateExpectedIntervalMinutes');
  @override
  late final GeneratedColumn<int> stateExpectedIntervalMinutes =
      GeneratedColumn<int>(
        'state_expected_interval_minutes',
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
  static const VerificationMeta _resourceEstimatedDurationMinutesMeta =
      const VerificationMeta('resourceEstimatedDurationMinutes');
  @override
  late final GeneratedColumn<int> resourceEstimatedDurationMinutes =
      GeneratedColumn<int>(
        'resource_estimated_duration_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resourceWarningBeforeDepletionMinutesMeta =
      const VerificationMeta('resourceWarningBeforeDepletionMinutes');
  @override
  late final GeneratedColumn<int> resourceWarningBeforeDepletionMinutes =
      GeneratedColumn<int>(
        'resource_warning_before_depletion_minutes',
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
    type,
    fixedScheduleType,
    fixedAnchorDate,
    fixedTimeOfDay,
    stateExpectedIntervalMinutes,
    stateWarningAfterMinutes,
    stateDangerAfterMinutes,
    resourceEstimatedDurationMinutes,
    resourceWarningBeforeDepletionMinutes,
    lastDoneAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'responsibility_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ResponsibilityItemRow> instance, {
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
    if (data.containsKey('fixed_anchor_date')) {
      context.handle(
        _fixedAnchorDateMeta,
        fixedAnchorDate.isAcceptableOrUnknown(
          data['fixed_anchor_date']!,
          _fixedAnchorDateMeta,
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
    if (data.containsKey('state_expected_interval_minutes')) {
      context.handle(
        _stateExpectedIntervalMinutesMeta,
        stateExpectedIntervalMinutes.isAcceptableOrUnknown(
          data['state_expected_interval_minutes']!,
          _stateExpectedIntervalMinutesMeta,
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
    if (data.containsKey('resource_estimated_duration_minutes')) {
      context.handle(
        _resourceEstimatedDurationMinutesMeta,
        resourceEstimatedDurationMinutes.isAcceptableOrUnknown(
          data['resource_estimated_duration_minutes']!,
          _resourceEstimatedDurationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('resource_warning_before_depletion_minutes')) {
      context.handle(
        _resourceWarningBeforeDepletionMinutesMeta,
        resourceWarningBeforeDepletionMinutes.isAcceptableOrUnknown(
          data['resource_warning_before_depletion_minutes']!,
          _resourceWarningBeforeDepletionMinutesMeta,
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
  ResponsibilityItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResponsibilityItemRow(
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
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      fixedScheduleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_schedule_type'],
      ),
      fixedAnchorDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_anchor_date'],
      ),
      fixedTimeOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_time_of_day'],
      ),
      stateExpectedIntervalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state_expected_interval_minutes'],
      ),
      stateWarningAfterMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state_warning_after_minutes'],
      ),
      stateDangerAfterMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state_danger_after_minutes'],
      ),
      resourceEstimatedDurationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resource_estimated_duration_minutes'],
      ),
      resourceWarningBeforeDepletionMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resource_warning_before_depletion_minutes'],
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
  $ResponsibilityItemsTable createAlias(String alias) {
    return $ResponsibilityItemsTable(attachedDatabase, alias);
  }
}

class ResponsibilityItemRow extends DataClass
    implements Insertable<ResponsibilityItemRow> {
  final int id;
  final int packId;
  final String title;
  final String? description;
  final String type;
  final String? fixedScheduleType;
  final int? fixedAnchorDate;
  final String? fixedTimeOfDay;
  final int? stateExpectedIntervalMinutes;
  final int? stateWarningAfterMinutes;
  final int? stateDangerAfterMinutes;
  final int? resourceEstimatedDurationMinutes;
  final int? resourceWarningBeforeDepletionMinutes;
  final int? lastDoneAt;
  final int createdAt;
  final int updatedAt;
  const ResponsibilityItemRow({
    required this.id,
    required this.packId,
    required this.title,
    this.description,
    required this.type,
    this.fixedScheduleType,
    this.fixedAnchorDate,
    this.fixedTimeOfDay,
    this.stateExpectedIntervalMinutes,
    this.stateWarningAfterMinutes,
    this.stateDangerAfterMinutes,
    this.resourceEstimatedDurationMinutes,
    this.resourceWarningBeforeDepletionMinutes,
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
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || fixedScheduleType != null) {
      map['fixed_schedule_type'] = Variable<String>(fixedScheduleType);
    }
    if (!nullToAbsent || fixedAnchorDate != null) {
      map['fixed_anchor_date'] = Variable<int>(fixedAnchorDate);
    }
    if (!nullToAbsent || fixedTimeOfDay != null) {
      map['fixed_time_of_day'] = Variable<String>(fixedTimeOfDay);
    }
    if (!nullToAbsent || stateExpectedIntervalMinutes != null) {
      map['state_expected_interval_minutes'] = Variable<int>(
        stateExpectedIntervalMinutes,
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
    if (!nullToAbsent || resourceEstimatedDurationMinutes != null) {
      map['resource_estimated_duration_minutes'] = Variable<int>(
        resourceEstimatedDurationMinutes,
      );
    }
    if (!nullToAbsent || resourceWarningBeforeDepletionMinutes != null) {
      map['resource_warning_before_depletion_minutes'] = Variable<int>(
        resourceWarningBeforeDepletionMinutes,
      );
    }
    if (!nullToAbsent || lastDoneAt != null) {
      map['last_done_at'] = Variable<int>(lastDoneAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ResponsibilityItemsCompanion toCompanion(bool nullToAbsent) {
    return ResponsibilityItemsCompanion(
      id: Value(id),
      packId: Value(packId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      type: Value(type),
      fixedScheduleType: fixedScheduleType == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedScheduleType),
      fixedAnchorDate: fixedAnchorDate == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedAnchorDate),
      fixedTimeOfDay: fixedTimeOfDay == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedTimeOfDay),
      stateExpectedIntervalMinutes:
          stateExpectedIntervalMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(stateExpectedIntervalMinutes),
      stateWarningAfterMinutes: stateWarningAfterMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(stateWarningAfterMinutes),
      stateDangerAfterMinutes: stateDangerAfterMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(stateDangerAfterMinutes),
      resourceEstimatedDurationMinutes:
          resourceEstimatedDurationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceEstimatedDurationMinutes),
      resourceWarningBeforeDepletionMinutes:
          resourceWarningBeforeDepletionMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceWarningBeforeDepletionMinutes),
      lastDoneAt: lastDoneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDoneAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ResponsibilityItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ResponsibilityItemRow(
      id: serializer.fromJson<int>(json['id']),
      packId: serializer.fromJson<int>(json['packId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      type: serializer.fromJson<String>(json['type']),
      fixedScheduleType: serializer.fromJson<String?>(
        json['fixedScheduleType'],
      ),
      fixedAnchorDate: serializer.fromJson<int?>(json['fixedAnchorDate']),
      fixedTimeOfDay: serializer.fromJson<String?>(json['fixedTimeOfDay']),
      stateExpectedIntervalMinutes: serializer.fromJson<int?>(
        json['stateExpectedIntervalMinutes'],
      ),
      stateWarningAfterMinutes: serializer.fromJson<int?>(
        json['stateWarningAfterMinutes'],
      ),
      stateDangerAfterMinutes: serializer.fromJson<int?>(
        json['stateDangerAfterMinutes'],
      ),
      resourceEstimatedDurationMinutes: serializer.fromJson<int?>(
        json['resourceEstimatedDurationMinutes'],
      ),
      resourceWarningBeforeDepletionMinutes: serializer.fromJson<int?>(
        json['resourceWarningBeforeDepletionMinutes'],
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
      'type': serializer.toJson<String>(type),
      'fixedScheduleType': serializer.toJson<String?>(fixedScheduleType),
      'fixedAnchorDate': serializer.toJson<int?>(fixedAnchorDate),
      'fixedTimeOfDay': serializer.toJson<String?>(fixedTimeOfDay),
      'stateExpectedIntervalMinutes': serializer.toJson<int?>(
        stateExpectedIntervalMinutes,
      ),
      'stateWarningAfterMinutes': serializer.toJson<int?>(
        stateWarningAfterMinutes,
      ),
      'stateDangerAfterMinutes': serializer.toJson<int?>(
        stateDangerAfterMinutes,
      ),
      'resourceEstimatedDurationMinutes': serializer.toJson<int?>(
        resourceEstimatedDurationMinutes,
      ),
      'resourceWarningBeforeDepletionMinutes': serializer.toJson<int?>(
        resourceWarningBeforeDepletionMinutes,
      ),
      'lastDoneAt': serializer.toJson<int?>(lastDoneAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ResponsibilityItemRow copyWith({
    int? id,
    int? packId,
    String? title,
    Value<String?> description = const Value.absent(),
    String? type,
    Value<String?> fixedScheduleType = const Value.absent(),
    Value<int?> fixedAnchorDate = const Value.absent(),
    Value<String?> fixedTimeOfDay = const Value.absent(),
    Value<int?> stateExpectedIntervalMinutes = const Value.absent(),
    Value<int?> stateWarningAfterMinutes = const Value.absent(),
    Value<int?> stateDangerAfterMinutes = const Value.absent(),
    Value<int?> resourceEstimatedDurationMinutes = const Value.absent(),
    Value<int?> resourceWarningBeforeDepletionMinutes = const Value.absent(),
    Value<int?> lastDoneAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => ResponsibilityItemRow(
    id: id ?? this.id,
    packId: packId ?? this.packId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    type: type ?? this.type,
    fixedScheduleType: fixedScheduleType.present
        ? fixedScheduleType.value
        : this.fixedScheduleType,
    fixedAnchorDate: fixedAnchorDate.present
        ? fixedAnchorDate.value
        : this.fixedAnchorDate,
    fixedTimeOfDay: fixedTimeOfDay.present
        ? fixedTimeOfDay.value
        : this.fixedTimeOfDay,
    stateExpectedIntervalMinutes: stateExpectedIntervalMinutes.present
        ? stateExpectedIntervalMinutes.value
        : this.stateExpectedIntervalMinutes,
    stateWarningAfterMinutes: stateWarningAfterMinutes.present
        ? stateWarningAfterMinutes.value
        : this.stateWarningAfterMinutes,
    stateDangerAfterMinutes: stateDangerAfterMinutes.present
        ? stateDangerAfterMinutes.value
        : this.stateDangerAfterMinutes,
    resourceEstimatedDurationMinutes: resourceEstimatedDurationMinutes.present
        ? resourceEstimatedDurationMinutes.value
        : this.resourceEstimatedDurationMinutes,
    resourceWarningBeforeDepletionMinutes:
        resourceWarningBeforeDepletionMinutes.present
        ? resourceWarningBeforeDepletionMinutes.value
        : this.resourceWarningBeforeDepletionMinutes,
    lastDoneAt: lastDoneAt.present ? lastDoneAt.value : this.lastDoneAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ResponsibilityItemRow copyWithCompanion(ResponsibilityItemsCompanion data) {
    return ResponsibilityItemRow(
      id: data.id.present ? data.id.value : this.id,
      packId: data.packId.present ? data.packId.value : this.packId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      type: data.type.present ? data.type.value : this.type,
      fixedScheduleType: data.fixedScheduleType.present
          ? data.fixedScheduleType.value
          : this.fixedScheduleType,
      fixedAnchorDate: data.fixedAnchorDate.present
          ? data.fixedAnchorDate.value
          : this.fixedAnchorDate,
      fixedTimeOfDay: data.fixedTimeOfDay.present
          ? data.fixedTimeOfDay.value
          : this.fixedTimeOfDay,
      stateExpectedIntervalMinutes: data.stateExpectedIntervalMinutes.present
          ? data.stateExpectedIntervalMinutes.value
          : this.stateExpectedIntervalMinutes,
      stateWarningAfterMinutes: data.stateWarningAfterMinutes.present
          ? data.stateWarningAfterMinutes.value
          : this.stateWarningAfterMinutes,
      stateDangerAfterMinutes: data.stateDangerAfterMinutes.present
          ? data.stateDangerAfterMinutes.value
          : this.stateDangerAfterMinutes,
      resourceEstimatedDurationMinutes:
          data.resourceEstimatedDurationMinutes.present
          ? data.resourceEstimatedDurationMinutes.value
          : this.resourceEstimatedDurationMinutes,
      resourceWarningBeforeDepletionMinutes:
          data.resourceWarningBeforeDepletionMinutes.present
          ? data.resourceWarningBeforeDepletionMinutes.value
          : this.resourceWarningBeforeDepletionMinutes,
      lastDoneAt: data.lastDoneAt.present
          ? data.lastDoneAt.value
          : this.lastDoneAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ResponsibilityItemRow(')
          ..write('id: $id, ')
          ..write('packId: $packId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('fixedScheduleType: $fixedScheduleType, ')
          ..write('fixedAnchorDate: $fixedAnchorDate, ')
          ..write('fixedTimeOfDay: $fixedTimeOfDay, ')
          ..write(
            'stateExpectedIntervalMinutes: $stateExpectedIntervalMinutes, ',
          )
          ..write('stateWarningAfterMinutes: $stateWarningAfterMinutes, ')
          ..write('stateDangerAfterMinutes: $stateDangerAfterMinutes, ')
          ..write(
            'resourceEstimatedDurationMinutes: $resourceEstimatedDurationMinutes, ',
          )
          ..write(
            'resourceWarningBeforeDepletionMinutes: $resourceWarningBeforeDepletionMinutes, ',
          )
          ..write('lastDoneAt: $lastDoneAt, ')
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
    type,
    fixedScheduleType,
    fixedAnchorDate,
    fixedTimeOfDay,
    stateExpectedIntervalMinutes,
    stateWarningAfterMinutes,
    stateDangerAfterMinutes,
    resourceEstimatedDurationMinutes,
    resourceWarningBeforeDepletionMinutes,
    lastDoneAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResponsibilityItemRow &&
          other.id == this.id &&
          other.packId == this.packId &&
          other.title == this.title &&
          other.description == this.description &&
          other.type == this.type &&
          other.fixedScheduleType == this.fixedScheduleType &&
          other.fixedAnchorDate == this.fixedAnchorDate &&
          other.fixedTimeOfDay == this.fixedTimeOfDay &&
          other.stateExpectedIntervalMinutes ==
              this.stateExpectedIntervalMinutes &&
          other.stateWarningAfterMinutes == this.stateWarningAfterMinutes &&
          other.stateDangerAfterMinutes == this.stateDangerAfterMinutes &&
          other.resourceEstimatedDurationMinutes ==
              this.resourceEstimatedDurationMinutes &&
          other.resourceWarningBeforeDepletionMinutes ==
              this.resourceWarningBeforeDepletionMinutes &&
          other.lastDoneAt == this.lastDoneAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ResponsibilityItemsCompanion
    extends UpdateCompanion<ResponsibilityItemRow> {
  final Value<int> id;
  final Value<int> packId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> type;
  final Value<String?> fixedScheduleType;
  final Value<int?> fixedAnchorDate;
  final Value<String?> fixedTimeOfDay;
  final Value<int?> stateExpectedIntervalMinutes;
  final Value<int?> stateWarningAfterMinutes;
  final Value<int?> stateDangerAfterMinutes;
  final Value<int?> resourceEstimatedDurationMinutes;
  final Value<int?> resourceWarningBeforeDepletionMinutes;
  final Value<int?> lastDoneAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ResponsibilityItemsCompanion({
    this.id = const Value.absent(),
    this.packId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.fixedScheduleType = const Value.absent(),
    this.fixedAnchorDate = const Value.absent(),
    this.fixedTimeOfDay = const Value.absent(),
    this.stateExpectedIntervalMinutes = const Value.absent(),
    this.stateWarningAfterMinutes = const Value.absent(),
    this.stateDangerAfterMinutes = const Value.absent(),
    this.resourceEstimatedDurationMinutes = const Value.absent(),
    this.resourceWarningBeforeDepletionMinutes = const Value.absent(),
    this.lastDoneAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ResponsibilityItemsCompanion.insert({
    this.id = const Value.absent(),
    required int packId,
    required String title,
    this.description = const Value.absent(),
    required String type,
    this.fixedScheduleType = const Value.absent(),
    this.fixedAnchorDate = const Value.absent(),
    this.fixedTimeOfDay = const Value.absent(),
    this.stateExpectedIntervalMinutes = const Value.absent(),
    this.stateWarningAfterMinutes = const Value.absent(),
    this.stateDangerAfterMinutes = const Value.absent(),
    this.resourceEstimatedDurationMinutes = const Value.absent(),
    this.resourceWarningBeforeDepletionMinutes = const Value.absent(),
    this.lastDoneAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : packId = Value(packId),
       title = Value(title),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ResponsibilityItemRow> custom({
    Expression<int>? id,
    Expression<int>? packId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? type,
    Expression<String>? fixedScheduleType,
    Expression<int>? fixedAnchorDate,
    Expression<String>? fixedTimeOfDay,
    Expression<int>? stateExpectedIntervalMinutes,
    Expression<int>? stateWarningAfterMinutes,
    Expression<int>? stateDangerAfterMinutes,
    Expression<int>? resourceEstimatedDurationMinutes,
    Expression<int>? resourceWarningBeforeDepletionMinutes,
    Expression<int>? lastDoneAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packId != null) 'pack_id': packId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (fixedScheduleType != null) 'fixed_schedule_type': fixedScheduleType,
      if (fixedAnchorDate != null) 'fixed_anchor_date': fixedAnchorDate,
      if (fixedTimeOfDay != null) 'fixed_time_of_day': fixedTimeOfDay,
      if (stateExpectedIntervalMinutes != null)
        'state_expected_interval_minutes': stateExpectedIntervalMinutes,
      if (stateWarningAfterMinutes != null)
        'state_warning_after_minutes': stateWarningAfterMinutes,
      if (stateDangerAfterMinutes != null)
        'state_danger_after_minutes': stateDangerAfterMinutes,
      if (resourceEstimatedDurationMinutes != null)
        'resource_estimated_duration_minutes': resourceEstimatedDurationMinutes,
      if (resourceWarningBeforeDepletionMinutes != null)
        'resource_warning_before_depletion_minutes':
            resourceWarningBeforeDepletionMinutes,
      if (lastDoneAt != null) 'last_done_at': lastDoneAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ResponsibilityItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? packId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? type,
    Value<String?>? fixedScheduleType,
    Value<int?>? fixedAnchorDate,
    Value<String?>? fixedTimeOfDay,
    Value<int?>? stateExpectedIntervalMinutes,
    Value<int?>? stateWarningAfterMinutes,
    Value<int?>? stateDangerAfterMinutes,
    Value<int?>? resourceEstimatedDurationMinutes,
    Value<int?>? resourceWarningBeforeDepletionMinutes,
    Value<int?>? lastDoneAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ResponsibilityItemsCompanion(
      id: id ?? this.id,
      packId: packId ?? this.packId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      fixedScheduleType: fixedScheduleType ?? this.fixedScheduleType,
      fixedAnchorDate: fixedAnchorDate ?? this.fixedAnchorDate,
      fixedTimeOfDay: fixedTimeOfDay ?? this.fixedTimeOfDay,
      stateExpectedIntervalMinutes:
          stateExpectedIntervalMinutes ?? this.stateExpectedIntervalMinutes,
      stateWarningAfterMinutes:
          stateWarningAfterMinutes ?? this.stateWarningAfterMinutes,
      stateDangerAfterMinutes:
          stateDangerAfterMinutes ?? this.stateDangerAfterMinutes,
      resourceEstimatedDurationMinutes:
          resourceEstimatedDurationMinutes ??
          this.resourceEstimatedDurationMinutes,
      resourceWarningBeforeDepletionMinutes:
          resourceWarningBeforeDepletionMinutes ??
          this.resourceWarningBeforeDepletionMinutes,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (fixedScheduleType.present) {
      map['fixed_schedule_type'] = Variable<String>(fixedScheduleType.value);
    }
    if (fixedAnchorDate.present) {
      map['fixed_anchor_date'] = Variable<int>(fixedAnchorDate.value);
    }
    if (fixedTimeOfDay.present) {
      map['fixed_time_of_day'] = Variable<String>(fixedTimeOfDay.value);
    }
    if (stateExpectedIntervalMinutes.present) {
      map['state_expected_interval_minutes'] = Variable<int>(
        stateExpectedIntervalMinutes.value,
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
    if (resourceEstimatedDurationMinutes.present) {
      map['resource_estimated_duration_minutes'] = Variable<int>(
        resourceEstimatedDurationMinutes.value,
      );
    }
    if (resourceWarningBeforeDepletionMinutes.present) {
      map['resource_warning_before_depletion_minutes'] = Variable<int>(
        resourceWarningBeforeDepletionMinutes.value,
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
    return (StringBuffer('ResponsibilityItemsCompanion(')
          ..write('id: $id, ')
          ..write('packId: $packId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('fixedScheduleType: $fixedScheduleType, ')
          ..write('fixedAnchorDate: $fixedAnchorDate, ')
          ..write('fixedTimeOfDay: $fixedTimeOfDay, ')
          ..write(
            'stateExpectedIntervalMinutes: $stateExpectedIntervalMinutes, ',
          )
          ..write('stateWarningAfterMinutes: $stateWarningAfterMinutes, ')
          ..write('stateDangerAfterMinutes: $stateDangerAfterMinutes, ')
          ..write(
            'resourceEstimatedDurationMinutes: $resourceEstimatedDurationMinutes, ',
          )
          ..write(
            'resourceWarningBeforeDepletionMinutes: $resourceWarningBeforeDepletionMinutes, ',
          )
          ..write('lastDoneAt: $lastDoneAt, ')
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
  late final $ResponsibilityPacksTable responsibilityPacks =
      $ResponsibilityPacksTable(this);
  late final $ResponsibilityItemsTable responsibilityItems =
      $ResponsibilityItemsTable(this);
  late final $TimelinesTable timelines = $TimelinesTable(this);
  late final $TimelineMilestoneRulesTable timelineMilestoneRules =
      $TimelineMilestoneRulesTable(this);
  late final $TimelineMilestoneRecordsTable timelineMilestoneRecords =
      $TimelineMilestoneRecordsTable(this);
  late final ResponsibilityTimelineDao responsibilityTimelineDao =
      ResponsibilityTimelineDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    responsibilityPacks,
    responsibilityItems,
    timelines,
    timelineMilestoneRules,
    timelineMilestoneRecords,
  ];
}

typedef $$ResponsibilityPacksTableCreateCompanionBuilder =
    ResponsibilityPacksCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> description,
      required int createdAt,
      required int updatedAt,
    });
typedef $$ResponsibilityPacksTableUpdateCompanionBuilder =
    ResponsibilityPacksCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> description,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$ResponsibilityPacksTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ResponsibilityPacksTable,
          ResponsibilityPackRow
        > {
  $$ResponsibilityPacksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $ResponsibilityItemsTable,
    List<ResponsibilityItemRow>
  >
  _responsibilityItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.responsibilityItems,
        aliasName: $_aliasNameGenerator(
          db.responsibilityPacks.id,
          db.responsibilityItems.packId,
        ),
      );

  $$ResponsibilityItemsTableProcessedTableManager get responsibilityItemsRefs {
    final manager = $$ResponsibilityItemsTableTableManager(
      $_db,
      $_db.responsibilityItems,
    ).filter((f) => f.packId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _responsibilityItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ResponsibilityPacksTableFilterComposer
    extends Composer<_$AppDatabase, $ResponsibilityPacksTable> {
  $$ResponsibilityPacksTableFilterComposer({
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

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> responsibilityItemsRefs(
    Expression<bool> Function($$ResponsibilityItemsTableFilterComposer f) f,
  ) {
    final $$ResponsibilityItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.responsibilityItems,
      getReferencedColumn: (t) => t.packId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResponsibilityItemsTableFilterComposer(
            $db: $db,
            $table: $db.responsibilityItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ResponsibilityPacksTableOrderingComposer
    extends Composer<_$AppDatabase, $ResponsibilityPacksTable> {
  $$ResponsibilityPacksTableOrderingComposer({
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

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ResponsibilityPacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ResponsibilityPacksTable> {
  $$ResponsibilityPacksTableAnnotationComposer({
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

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> responsibilityItemsRefs<T extends Object>(
    Expression<T> Function($$ResponsibilityItemsTableAnnotationComposer a) f,
  ) {
    final $$ResponsibilityItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.responsibilityItems,
          getReferencedColumn: (t) => t.packId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ResponsibilityItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.responsibilityItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ResponsibilityPacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ResponsibilityPacksTable,
          ResponsibilityPackRow,
          $$ResponsibilityPacksTableFilterComposer,
          $$ResponsibilityPacksTableOrderingComposer,
          $$ResponsibilityPacksTableAnnotationComposer,
          $$ResponsibilityPacksTableCreateCompanionBuilder,
          $$ResponsibilityPacksTableUpdateCompanionBuilder,
          (ResponsibilityPackRow, $$ResponsibilityPacksTableReferences),
          ResponsibilityPackRow,
          PrefetchHooks Function({bool responsibilityItemsRefs})
        > {
  $$ResponsibilityPacksTableTableManager(
    _$AppDatabase db,
    $ResponsibilityPacksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResponsibilityPacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResponsibilityPacksTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ResponsibilityPacksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ResponsibilityPacksCompanion(
                id: id,
                title: title,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ResponsibilityPacksCompanion.insert(
                id: id,
                title: title,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ResponsibilityPacksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({responsibilityItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (responsibilityItemsRefs) db.responsibilityItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (responsibilityItemsRefs)
                    await $_getPrefetchedData<
                      ResponsibilityPackRow,
                      $ResponsibilityPacksTable,
                      ResponsibilityItemRow
                    >(
                      currentTable: table,
                      referencedTable: $$ResponsibilityPacksTableReferences
                          ._responsibilityItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ResponsibilityPacksTableReferences(
                            db,
                            table,
                            p0,
                          ).responsibilityItemsRefs,
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

typedef $$ResponsibilityPacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ResponsibilityPacksTable,
      ResponsibilityPackRow,
      $$ResponsibilityPacksTableFilterComposer,
      $$ResponsibilityPacksTableOrderingComposer,
      $$ResponsibilityPacksTableAnnotationComposer,
      $$ResponsibilityPacksTableCreateCompanionBuilder,
      $$ResponsibilityPacksTableUpdateCompanionBuilder,
      (ResponsibilityPackRow, $$ResponsibilityPacksTableReferences),
      ResponsibilityPackRow,
      PrefetchHooks Function({bool responsibilityItemsRefs})
    >;
typedef $$ResponsibilityItemsTableCreateCompanionBuilder =
    ResponsibilityItemsCompanion Function({
      Value<int> id,
      required int packId,
      required String title,
      Value<String?> description,
      required String type,
      Value<String?> fixedScheduleType,
      Value<int?> fixedAnchorDate,
      Value<String?> fixedTimeOfDay,
      Value<int?> stateExpectedIntervalMinutes,
      Value<int?> stateWarningAfterMinutes,
      Value<int?> stateDangerAfterMinutes,
      Value<int?> resourceEstimatedDurationMinutes,
      Value<int?> resourceWarningBeforeDepletionMinutes,
      Value<int?> lastDoneAt,
      required int createdAt,
      required int updatedAt,
    });
typedef $$ResponsibilityItemsTableUpdateCompanionBuilder =
    ResponsibilityItemsCompanion Function({
      Value<int> id,
      Value<int> packId,
      Value<String> title,
      Value<String?> description,
      Value<String> type,
      Value<String?> fixedScheduleType,
      Value<int?> fixedAnchorDate,
      Value<String?> fixedTimeOfDay,
      Value<int?> stateExpectedIntervalMinutes,
      Value<int?> stateWarningAfterMinutes,
      Value<int?> stateDangerAfterMinutes,
      Value<int?> resourceEstimatedDurationMinutes,
      Value<int?> resourceWarningBeforeDepletionMinutes,
      Value<int?> lastDoneAt,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$ResponsibilityItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ResponsibilityItemsTable,
          ResponsibilityItemRow
        > {
  $$ResponsibilityItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ResponsibilityPacksTable _packIdTable(_$AppDatabase db) =>
      db.responsibilityPacks.createAlias(
        $_aliasNameGenerator(
          db.responsibilityItems.packId,
          db.responsibilityPacks.id,
        ),
      );

  $$ResponsibilityPacksTableProcessedTableManager get packId {
    final $_column = $_itemColumn<int>('pack_id')!;

    final manager = $$ResponsibilityPacksTableTableManager(
      $_db,
      $_db.responsibilityPacks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_packIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ResponsibilityItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ResponsibilityItemsTable> {
  $$ResponsibilityItemsTableFilterComposer({
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

  ColumnFilters<int> get fixedAnchorDate => $composableBuilder(
    column: $table.fixedAnchorDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixedTimeOfDay => $composableBuilder(
    column: $table.fixedTimeOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stateExpectedIntervalMinutes => $composableBuilder(
    column: $table.stateExpectedIntervalMinutes,
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

  ColumnFilters<int> get resourceEstimatedDurationMinutes => $composableBuilder(
    column: $table.resourceEstimatedDurationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resourceWarningBeforeDepletionMinutes =>
      $composableBuilder(
        column: $table.resourceWarningBeforeDepletionMinutes,
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

  $$ResponsibilityPacksTableFilterComposer get packId {
    final $$ResponsibilityPacksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packId,
      referencedTable: $db.responsibilityPacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResponsibilityPacksTableFilterComposer(
            $db: $db,
            $table: $db.responsibilityPacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResponsibilityItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ResponsibilityItemsTable> {
  $$ResponsibilityItemsTableOrderingComposer({
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

  ColumnOrderings<int> get fixedAnchorDate => $composableBuilder(
    column: $table.fixedAnchorDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixedTimeOfDay => $composableBuilder(
    column: $table.fixedTimeOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stateExpectedIntervalMinutes => $composableBuilder(
    column: $table.stateExpectedIntervalMinutes,
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

  ColumnOrderings<int> get resourceEstimatedDurationMinutes =>
      $composableBuilder(
        column: $table.resourceEstimatedDurationMinutes,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<int> get resourceWarningBeforeDepletionMinutes =>
      $composableBuilder(
        column: $table.resourceWarningBeforeDepletionMinutes,
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

  $$ResponsibilityPacksTableOrderingComposer get packId {
    final $$ResponsibilityPacksTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.packId,
          referencedTable: $db.responsibilityPacks,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ResponsibilityPacksTableOrderingComposer(
                $db: $db,
                $table: $db.responsibilityPacks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ResponsibilityItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ResponsibilityItemsTable> {
  $$ResponsibilityItemsTableAnnotationComposer({
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

  GeneratedColumn<int> get fixedAnchorDate => $composableBuilder(
    column: $table.fixedAnchorDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fixedTimeOfDay => $composableBuilder(
    column: $table.fixedTimeOfDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stateExpectedIntervalMinutes => $composableBuilder(
    column: $table.stateExpectedIntervalMinutes,
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

  GeneratedColumn<int> get resourceEstimatedDurationMinutes =>
      $composableBuilder(
        column: $table.resourceEstimatedDurationMinutes,
        builder: (column) => column,
      );

  GeneratedColumn<int> get resourceWarningBeforeDepletionMinutes =>
      $composableBuilder(
        column: $table.resourceWarningBeforeDepletionMinutes,
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

  $$ResponsibilityPacksTableAnnotationComposer get packId {
    final $$ResponsibilityPacksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.packId,
          referencedTable: $db.responsibilityPacks,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ResponsibilityPacksTableAnnotationComposer(
                $db: $db,
                $table: $db.responsibilityPacks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ResponsibilityItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ResponsibilityItemsTable,
          ResponsibilityItemRow,
          $$ResponsibilityItemsTableFilterComposer,
          $$ResponsibilityItemsTableOrderingComposer,
          $$ResponsibilityItemsTableAnnotationComposer,
          $$ResponsibilityItemsTableCreateCompanionBuilder,
          $$ResponsibilityItemsTableUpdateCompanionBuilder,
          (ResponsibilityItemRow, $$ResponsibilityItemsTableReferences),
          ResponsibilityItemRow,
          PrefetchHooks Function({bool packId})
        > {
  $$ResponsibilityItemsTableTableManager(
    _$AppDatabase db,
    $ResponsibilityItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResponsibilityItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResponsibilityItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ResponsibilityItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> packId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> fixedScheduleType = const Value.absent(),
                Value<int?> fixedAnchorDate = const Value.absent(),
                Value<String?> fixedTimeOfDay = const Value.absent(),
                Value<int?> stateExpectedIntervalMinutes = const Value.absent(),
                Value<int?> stateWarningAfterMinutes = const Value.absent(),
                Value<int?> stateDangerAfterMinutes = const Value.absent(),
                Value<int?> resourceEstimatedDurationMinutes =
                    const Value.absent(),
                Value<int?> resourceWarningBeforeDepletionMinutes =
                    const Value.absent(),
                Value<int?> lastDoneAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ResponsibilityItemsCompanion(
                id: id,
                packId: packId,
                title: title,
                description: description,
                type: type,
                fixedScheduleType: fixedScheduleType,
                fixedAnchorDate: fixedAnchorDate,
                fixedTimeOfDay: fixedTimeOfDay,
                stateExpectedIntervalMinutes: stateExpectedIntervalMinutes,
                stateWarningAfterMinutes: stateWarningAfterMinutes,
                stateDangerAfterMinutes: stateDangerAfterMinutes,
                resourceEstimatedDurationMinutes:
                    resourceEstimatedDurationMinutes,
                resourceWarningBeforeDepletionMinutes:
                    resourceWarningBeforeDepletionMinutes,
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
                required String type,
                Value<String?> fixedScheduleType = const Value.absent(),
                Value<int?> fixedAnchorDate = const Value.absent(),
                Value<String?> fixedTimeOfDay = const Value.absent(),
                Value<int?> stateExpectedIntervalMinutes = const Value.absent(),
                Value<int?> stateWarningAfterMinutes = const Value.absent(),
                Value<int?> stateDangerAfterMinutes = const Value.absent(),
                Value<int?> resourceEstimatedDurationMinutes =
                    const Value.absent(),
                Value<int?> resourceWarningBeforeDepletionMinutes =
                    const Value.absent(),
                Value<int?> lastDoneAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ResponsibilityItemsCompanion.insert(
                id: id,
                packId: packId,
                title: title,
                description: description,
                type: type,
                fixedScheduleType: fixedScheduleType,
                fixedAnchorDate: fixedAnchorDate,
                fixedTimeOfDay: fixedTimeOfDay,
                stateExpectedIntervalMinutes: stateExpectedIntervalMinutes,
                stateWarningAfterMinutes: stateWarningAfterMinutes,
                stateDangerAfterMinutes: stateDangerAfterMinutes,
                resourceEstimatedDurationMinutes:
                    resourceEstimatedDurationMinutes,
                resourceWarningBeforeDepletionMinutes:
                    resourceWarningBeforeDepletionMinutes,
                lastDoneAt: lastDoneAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ResponsibilityItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({packId = false}) {
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
                    if (packId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.packId,
                                referencedTable:
                                    $$ResponsibilityItemsTableReferences
                                        ._packIdTable(db),
                                referencedColumn:
                                    $$ResponsibilityItemsTableReferences
                                        ._packIdTable(db)
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

typedef $$ResponsibilityItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ResponsibilityItemsTable,
      ResponsibilityItemRow,
      $$ResponsibilityItemsTableFilterComposer,
      $$ResponsibilityItemsTableOrderingComposer,
      $$ResponsibilityItemsTableAnnotationComposer,
      $$ResponsibilityItemsTableCreateCompanionBuilder,
      $$ResponsibilityItemsTableUpdateCompanionBuilder,
      (ResponsibilityItemRow, $$ResponsibilityItemsTableReferences),
      ResponsibilityItemRow,
      PrefetchHooks Function({bool packId})
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
  $$ResponsibilityPacksTableTableManager get responsibilityPacks =>
      $$ResponsibilityPacksTableTableManager(_db, _db.responsibilityPacks);
  $$ResponsibilityItemsTableTableManager get responsibilityItems =>
      $$ResponsibilityItemsTableTableManager(_db, _db.responsibilityItems);
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
