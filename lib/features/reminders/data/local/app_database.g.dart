// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RecurringRemindersTable extends RecurringReminders
    with TableInfo<$RecurringRemindersTable, RecurringReminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringRemindersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
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
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackingModeMeta = const VerificationMeta(
    'trackingMode',
  );
  @override
  late final GeneratedColumn<int> trackingMode = GeneratedColumn<int>(
    'tracking_mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggerModeMeta = const VerificationMeta(
    'triggerMode',
  );
  @override
  late final GeneratedColumn<int> triggerMode = GeneratedColumn<int>(
    'trigger_mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggerOffsetDaysMeta = const VerificationMeta(
    'triggerOffsetDays',
  );
  @override
  late final GeneratedColumn<int> triggerOffsetDays = GeneratedColumn<int>(
    'trigger_offset_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatRuleMeta = const VerificationMeta(
    'repeatRule',
  );
  @override
  late final GeneratedColumn<String> repeatRule = GeneratedColumn<String>(
    'repeat_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicCategoryIdMeta = const VerificationMeta(
    'topicCategoryId',
  );
  @override
  late final GeneratedColumn<int> topicCategoryId = GeneratedColumn<int>(
    'topic_category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionCategoryIdMeta = const VerificationMeta(
    'actionCategoryId',
  );
  @override
  late final GeneratedColumn<int> actionCategoryId = GeneratedColumn<int>(
    'action_category_id',
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
    status,
    title,
    note,
    trackingMode,
    triggerMode,
    triggerOffsetDays,
    repeatRule,
    topicCategoryId,
    actionCategoryId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringReminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
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
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('tracking_mode')) {
      context.handle(
        _trackingModeMeta,
        trackingMode.isAcceptableOrUnknown(
          data['tracking_mode']!,
          _trackingModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackingModeMeta);
    }
    if (data.containsKey('trigger_mode')) {
      context.handle(
        _triggerModeMeta,
        triggerMode.isAcceptableOrUnknown(
          data['trigger_mode']!,
          _triggerModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_triggerModeMeta);
    }
    if (data.containsKey('trigger_offset_days')) {
      context.handle(
        _triggerOffsetDaysMeta,
        triggerOffsetDays.isAcceptableOrUnknown(
          data['trigger_offset_days']!,
          _triggerOffsetDaysMeta,
        ),
      );
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(
        _repeatRuleMeta,
        repeatRule.isAcceptableOrUnknown(data['repeat_rule']!, _repeatRuleMeta),
      );
    }
    if (data.containsKey('topic_category_id')) {
      context.handle(
        _topicCategoryIdMeta,
        topicCategoryId.isAcceptableOrUnknown(
          data['topic_category_id']!,
          _topicCategoryIdMeta,
        ),
      );
    }
    if (data.containsKey('action_category_id')) {
      context.handle(
        _actionCategoryIdMeta,
        actionCategoryId.isAcceptableOrUnknown(
          data['action_category_id']!,
          _actionCategoryIdMeta,
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
  RecurringReminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringReminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      trackingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tracking_mode'],
      )!,
      triggerMode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trigger_mode'],
      )!,
      triggerOffsetDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trigger_offset_days'],
      ),
      repeatRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_rule'],
      ),
      topicCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}topic_category_id'],
      ),
      actionCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}action_category_id'],
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
  $RecurringRemindersTable createAlias(String alias) {
    return $RecurringRemindersTable(attachedDatabase, alias);
  }
}

class RecurringReminder extends DataClass
    implements Insertable<RecurringReminder> {
  final int id;

  /// 0: pending, 1: stopped, 2: canceled.
  final int status;
  final String title;
  final String? note;

  /// 1: countdown, 2: count-up.
  final int trackingMode;

  /// 1: in-range, 2: immediate, 3: on-point.
  final int triggerMode;
  final int? triggerOffsetDays;

  /// Null means not recurring; otherwise D25 / W3 / M1 / Y1.
  final String? repeatRule;
  final int? topicCategoryId;
  final int? actionCategoryId;
  final int createdAt;
  final int updatedAt;
  const RecurringReminder({
    required this.id,
    required this.status,
    required this.title,
    this.note,
    required this.trackingMode,
    required this.triggerMode,
    this.triggerOffsetDays,
    this.repeatRule,
    this.topicCategoryId,
    this.actionCategoryId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['status'] = Variable<int>(status);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['tracking_mode'] = Variable<int>(trackingMode);
    map['trigger_mode'] = Variable<int>(triggerMode);
    if (!nullToAbsent || triggerOffsetDays != null) {
      map['trigger_offset_days'] = Variable<int>(triggerOffsetDays);
    }
    if (!nullToAbsent || repeatRule != null) {
      map['repeat_rule'] = Variable<String>(repeatRule);
    }
    if (!nullToAbsent || topicCategoryId != null) {
      map['topic_category_id'] = Variable<int>(topicCategoryId);
    }
    if (!nullToAbsent || actionCategoryId != null) {
      map['action_category_id'] = Variable<int>(actionCategoryId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  RecurringRemindersCompanion toCompanion(bool nullToAbsent) {
    return RecurringRemindersCompanion(
      id: Value(id),
      status: Value(status),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      trackingMode: Value(trackingMode),
      triggerMode: Value(triggerMode),
      triggerOffsetDays: triggerOffsetDays == null && nullToAbsent
          ? const Value.absent()
          : Value(triggerOffsetDays),
      repeatRule: repeatRule == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatRule),
      topicCategoryId: topicCategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(topicCategoryId),
      actionCategoryId: actionCategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(actionCategoryId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RecurringReminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringReminder(
      id: serializer.fromJson<int>(json['id']),
      status: serializer.fromJson<int>(json['status']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      trackingMode: serializer.fromJson<int>(json['trackingMode']),
      triggerMode: serializer.fromJson<int>(json['triggerMode']),
      triggerOffsetDays: serializer.fromJson<int?>(json['triggerOffsetDays']),
      repeatRule: serializer.fromJson<String?>(json['repeatRule']),
      topicCategoryId: serializer.fromJson<int?>(json['topicCategoryId']),
      actionCategoryId: serializer.fromJson<int?>(json['actionCategoryId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'status': serializer.toJson<int>(status),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String?>(note),
      'trackingMode': serializer.toJson<int>(trackingMode),
      'triggerMode': serializer.toJson<int>(triggerMode),
      'triggerOffsetDays': serializer.toJson<int?>(triggerOffsetDays),
      'repeatRule': serializer.toJson<String?>(repeatRule),
      'topicCategoryId': serializer.toJson<int?>(topicCategoryId),
      'actionCategoryId': serializer.toJson<int?>(actionCategoryId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  RecurringReminder copyWith({
    int? id,
    int? status,
    String? title,
    Value<String?> note = const Value.absent(),
    int? trackingMode,
    int? triggerMode,
    Value<int?> triggerOffsetDays = const Value.absent(),
    Value<String?> repeatRule = const Value.absent(),
    Value<int?> topicCategoryId = const Value.absent(),
    Value<int?> actionCategoryId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => RecurringReminder(
    id: id ?? this.id,
    status: status ?? this.status,
    title: title ?? this.title,
    note: note.present ? note.value : this.note,
    trackingMode: trackingMode ?? this.trackingMode,
    triggerMode: triggerMode ?? this.triggerMode,
    triggerOffsetDays: triggerOffsetDays.present
        ? triggerOffsetDays.value
        : this.triggerOffsetDays,
    repeatRule: repeatRule.present ? repeatRule.value : this.repeatRule,
    topicCategoryId: topicCategoryId.present
        ? topicCategoryId.value
        : this.topicCategoryId,
    actionCategoryId: actionCategoryId.present
        ? actionCategoryId.value
        : this.actionCategoryId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RecurringReminder copyWithCompanion(RecurringRemindersCompanion data) {
    return RecurringReminder(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      trackingMode: data.trackingMode.present
          ? data.trackingMode.value
          : this.trackingMode,
      triggerMode: data.triggerMode.present
          ? data.triggerMode.value
          : this.triggerMode,
      triggerOffsetDays: data.triggerOffsetDays.present
          ? data.triggerOffsetDays.value
          : this.triggerOffsetDays,
      repeatRule: data.repeatRule.present
          ? data.repeatRule.value
          : this.repeatRule,
      topicCategoryId: data.topicCategoryId.present
          ? data.topicCategoryId.value
          : this.topicCategoryId,
      actionCategoryId: data.actionCategoryId.present
          ? data.actionCategoryId.value
          : this.actionCategoryId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringReminder(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('trackingMode: $trackingMode, ')
          ..write('triggerMode: $triggerMode, ')
          ..write('triggerOffsetDays: $triggerOffsetDays, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('topicCategoryId: $topicCategoryId, ')
          ..write('actionCategoryId: $actionCategoryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    status,
    title,
    note,
    trackingMode,
    triggerMode,
    triggerOffsetDays,
    repeatRule,
    topicCategoryId,
    actionCategoryId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringReminder &&
          other.id == this.id &&
          other.status == this.status &&
          other.title == this.title &&
          other.note == this.note &&
          other.trackingMode == this.trackingMode &&
          other.triggerMode == this.triggerMode &&
          other.triggerOffsetDays == this.triggerOffsetDays &&
          other.repeatRule == this.repeatRule &&
          other.topicCategoryId == this.topicCategoryId &&
          other.actionCategoryId == this.actionCategoryId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RecurringRemindersCompanion extends UpdateCompanion<RecurringReminder> {
  final Value<int> id;
  final Value<int> status;
  final Value<String> title;
  final Value<String?> note;
  final Value<int> trackingMode;
  final Value<int> triggerMode;
  final Value<int?> triggerOffsetDays;
  final Value<String?> repeatRule;
  final Value<int?> topicCategoryId;
  final Value<int?> actionCategoryId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const RecurringRemindersCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.trackingMode = const Value.absent(),
    this.triggerMode = const Value.absent(),
    this.triggerOffsetDays = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.topicCategoryId = const Value.absent(),
    this.actionCategoryId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RecurringRemindersCompanion.insert({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    required String title,
    this.note = const Value.absent(),
    required int trackingMode,
    required int triggerMode,
    this.triggerOffsetDays = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.topicCategoryId = const Value.absent(),
    this.actionCategoryId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : title = Value(title),
       trackingMode = Value(trackingMode),
       triggerMode = Value(triggerMode),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<RecurringReminder> custom({
    Expression<int>? id,
    Expression<int>? status,
    Expression<String>? title,
    Expression<String>? note,
    Expression<int>? trackingMode,
    Expression<int>? triggerMode,
    Expression<int>? triggerOffsetDays,
    Expression<String>? repeatRule,
    Expression<int>? topicCategoryId,
    Expression<int>? actionCategoryId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (trackingMode != null) 'tracking_mode': trackingMode,
      if (triggerMode != null) 'trigger_mode': triggerMode,
      if (triggerOffsetDays != null) 'trigger_offset_days': triggerOffsetDays,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (topicCategoryId != null) 'topic_category_id': topicCategoryId,
      if (actionCategoryId != null) 'action_category_id': actionCategoryId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RecurringRemindersCompanion copyWith({
    Value<int>? id,
    Value<int>? status,
    Value<String>? title,
    Value<String?>? note,
    Value<int>? trackingMode,
    Value<int>? triggerMode,
    Value<int?>? triggerOffsetDays,
    Value<String?>? repeatRule,
    Value<int?>? topicCategoryId,
    Value<int?>? actionCategoryId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return RecurringRemindersCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      title: title ?? this.title,
      note: note ?? this.note,
      trackingMode: trackingMode ?? this.trackingMode,
      triggerMode: triggerMode ?? this.triggerMode,
      triggerOffsetDays: triggerOffsetDays ?? this.triggerOffsetDays,
      repeatRule: repeatRule ?? this.repeatRule,
      topicCategoryId: topicCategoryId ?? this.topicCategoryId,
      actionCategoryId: actionCategoryId ?? this.actionCategoryId,
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
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (trackingMode.present) {
      map['tracking_mode'] = Variable<int>(trackingMode.value);
    }
    if (triggerMode.present) {
      map['trigger_mode'] = Variable<int>(triggerMode.value);
    }
    if (triggerOffsetDays.present) {
      map['trigger_offset_days'] = Variable<int>(triggerOffsetDays.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (topicCategoryId.present) {
      map['topic_category_id'] = Variable<int>(topicCategoryId.value);
    }
    if (actionCategoryId.present) {
      map['action_category_id'] = Variable<int>(actionCategoryId.value);
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
    return (StringBuffer('RecurringRemindersCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('trackingMode: $trackingMode, ')
          ..write('triggerMode: $triggerMode, ')
          ..write('triggerOffsetDays: $triggerOffsetDays, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('topicCategoryId: $topicCategoryId, ')
          ..write('actionCategoryId: $actionCategoryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TopicCategoriesTable extends TopicCategories
    with TableInfo<$TopicCategoriesTable, TopicCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopicCategoriesTable(this.attachedDatabase, [this._alias]);
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
    name,
    description,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'topic_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<TopicCategory> instance, {
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
  TopicCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TopicCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
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
  $TopicCategoriesTable createAlias(String alias) {
    return $TopicCategoriesTable(attachedDatabase, alias);
  }
}

class TopicCategory extends DataClass implements Insertable<TopicCategory> {
  final int id;
  final String name;
  final String? description;
  final int createdAt;
  final int updatedAt;
  const TopicCategory({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TopicCategoriesCompanion toCompanion(bool nullToAbsent) {
    return TopicCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TopicCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TopicCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
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
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  TopicCategory copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => TopicCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TopicCategory copyWithCompanion(TopicCategoriesCompanion data) {
    return TopicCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TopicCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TopicCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TopicCategoriesCompanion extends UpdateCompanion<TopicCategory> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const TopicCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TopicCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TopicCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TopicCategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return TopicCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
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
    return (StringBuffer('TopicCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ActionCategoriesTable extends ActionCategories
    with TableInfo<$ActionCategoriesTable, ActionCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActionCategoriesTable(this.attachedDatabase, [this._alias]);
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
    name,
    description,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'action_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActionCategory> instance, {
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
  ActionCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActionCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
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
  $ActionCategoriesTable createAlias(String alias) {
    return $ActionCategoriesTable(attachedDatabase, alias);
  }
}

class ActionCategory extends DataClass implements Insertable<ActionCategory> {
  final int id;
  final String name;
  final String? description;
  final int createdAt;
  final int updatedAt;
  const ActionCategory({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ActionCategoriesCompanion toCompanion(bool nullToAbsent) {
    return ActionCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ActionCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActionCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
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
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ActionCategory copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => ActionCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ActionCategory copyWithCompanion(ActionCategoriesCompanion data) {
    return ActionCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActionCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActionCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ActionCategoriesCompanion extends UpdateCompanion<ActionCategory> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ActionCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ActionCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ActionCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ActionCategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ActionCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
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
    return (StringBuffer('ActionCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _recurringReminderIdMeta =
      const VerificationMeta('recurringReminderId');
  @override
  late final GeneratedColumn<int> recurringReminderId = GeneratedColumn<int>(
    'recurring_reminder_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _previousOccurrenceIdMeta =
      const VerificationMeta('previousOccurrenceId');
  @override
  late final GeneratedColumn<int> previousOccurrenceId = GeneratedColumn<int>(
    'previous_occurrence_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackingModeMeta = const VerificationMeta(
    'trackingMode',
  );
  @override
  late final GeneratedColumn<int> trackingMode = GeneratedColumn<int>(
    'tracking_mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggerModeMeta = const VerificationMeta(
    'triggerMode',
  );
  @override
  late final GeneratedColumn<int> triggerMode = GeneratedColumn<int>(
    'trigger_mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
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
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _triggerOffsetDaysMeta = const VerificationMeta(
    'triggerOffsetDays',
  );
  @override
  late final GeneratedColumn<int> triggerOffsetDays = GeneratedColumn<int>(
    'trigger_offset_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusNoteMeta = const VerificationMeta(
    'statusNote',
  );
  @override
  late final GeneratedColumn<String> statusNote = GeneratedColumn<String>(
    'status_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<int> dueAt = GeneratedColumn<int>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<int> startAt = GeneratedColumn<int>(
    'start_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deferredDueAtMeta = const VerificationMeta(
    'deferredDueAt',
  );
  @override
  late final GeneratedColumn<int> deferredDueAt = GeneratedColumn<int>(
    'deferred_due_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicCategoryIdMeta = const VerificationMeta(
    'topicCategoryId',
  );
  @override
  late final GeneratedColumn<int> topicCategoryId = GeneratedColumn<int>(
    'topic_category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionCategoryIdMeta = const VerificationMeta(
    'actionCategoryId',
  );
  @override
  late final GeneratedColumn<int> actionCategoryId = GeneratedColumn<int>(
    'action_category_id',
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
    recurringReminderId,
    previousOccurrenceId,
    trackingMode,
    triggerMode,
    status,
    title,
    note,
    triggerOffsetDays,
    statusNote,
    dueAt,
    startAt,
    deferredDueAt,
    topicCategoryId,
    actionCategoryId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recurring_reminder_id')) {
      context.handle(
        _recurringReminderIdMeta,
        recurringReminderId.isAcceptableOrUnknown(
          data['recurring_reminder_id']!,
          _recurringReminderIdMeta,
        ),
      );
    }
    if (data.containsKey('previous_occurrence_id')) {
      context.handle(
        _previousOccurrenceIdMeta,
        previousOccurrenceId.isAcceptableOrUnknown(
          data['previous_occurrence_id']!,
          _previousOccurrenceIdMeta,
        ),
      );
    }
    if (data.containsKey('tracking_mode')) {
      context.handle(
        _trackingModeMeta,
        trackingMode.isAcceptableOrUnknown(
          data['tracking_mode']!,
          _trackingModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackingModeMeta);
    }
    if (data.containsKey('trigger_mode')) {
      context.handle(
        _triggerModeMeta,
        triggerMode.isAcceptableOrUnknown(
          data['trigger_mode']!,
          _triggerModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_triggerModeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
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
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('trigger_offset_days')) {
      context.handle(
        _triggerOffsetDaysMeta,
        triggerOffsetDays.isAcceptableOrUnknown(
          data['trigger_offset_days']!,
          _triggerOffsetDaysMeta,
        ),
      );
    }
    if (data.containsKey('status_note')) {
      context.handle(
        _statusNoteMeta,
        statusNote.isAcceptableOrUnknown(data['status_note']!, _statusNoteMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('deferred_due_at')) {
      context.handle(
        _deferredDueAtMeta,
        deferredDueAt.isAcceptableOrUnknown(
          data['deferred_due_at']!,
          _deferredDueAtMeta,
        ),
      );
    }
    if (data.containsKey('topic_category_id')) {
      context.handle(
        _topicCategoryIdMeta,
        topicCategoryId.isAcceptableOrUnknown(
          data['topic_category_id']!,
          _topicCategoryIdMeta,
        ),
      );
    }
    if (data.containsKey('action_category_id')) {
      context.handle(
        _actionCategoryIdMeta,
        actionCategoryId.isAcceptableOrUnknown(
          data['action_category_id']!,
          _actionCategoryIdMeta,
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
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recurringReminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurring_reminder_id'],
      ),
      previousOccurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}previous_occurrence_id'],
      ),
      trackingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tracking_mode'],
      )!,
      triggerMode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trigger_mode'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      triggerOffsetDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trigger_offset_days'],
      ),
      statusNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_note'],
      ),
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_at'],
      ),
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_at'],
      )!,
      deferredDueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deferred_due_at'],
      ),
      topicCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}topic_category_id'],
      ),
      actionCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}action_category_id'],
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
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final int id;
  final int? recurringReminderId;
  final int? previousOccurrenceId;

  /// 1: countdown, 2: count-up.
  final int trackingMode;

  /// 1: in-range, 2: immediate, 3: on-point.
  final int triggerMode;

  /// 0: pending, 1: done, 2: skipped, 3: canceled.
  final int status;
  final String title;
  final String? note;
  final int? triggerOffsetDays;
  final String? statusNote;
  final int? dueAt;
  final int startAt;
  final int? deferredDueAt;
  final int? topicCategoryId;
  final int? actionCategoryId;
  final int createdAt;
  final int updatedAt;
  const Reminder({
    required this.id,
    this.recurringReminderId,
    this.previousOccurrenceId,
    required this.trackingMode,
    required this.triggerMode,
    required this.status,
    required this.title,
    this.note,
    this.triggerOffsetDays,
    this.statusNote,
    this.dueAt,
    required this.startAt,
    this.deferredDueAt,
    this.topicCategoryId,
    this.actionCategoryId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || recurringReminderId != null) {
      map['recurring_reminder_id'] = Variable<int>(recurringReminderId);
    }
    if (!nullToAbsent || previousOccurrenceId != null) {
      map['previous_occurrence_id'] = Variable<int>(previousOccurrenceId);
    }
    map['tracking_mode'] = Variable<int>(trackingMode);
    map['trigger_mode'] = Variable<int>(triggerMode);
    map['status'] = Variable<int>(status);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || triggerOffsetDays != null) {
      map['trigger_offset_days'] = Variable<int>(triggerOffsetDays);
    }
    if (!nullToAbsent || statusNote != null) {
      map['status_note'] = Variable<String>(statusNote);
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<int>(dueAt);
    }
    map['start_at'] = Variable<int>(startAt);
    if (!nullToAbsent || deferredDueAt != null) {
      map['deferred_due_at'] = Variable<int>(deferredDueAt);
    }
    if (!nullToAbsent || topicCategoryId != null) {
      map['topic_category_id'] = Variable<int>(topicCategoryId);
    }
    if (!nullToAbsent || actionCategoryId != null) {
      map['action_category_id'] = Variable<int>(actionCategoryId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      recurringReminderId: recurringReminderId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringReminderId),
      previousOccurrenceId: previousOccurrenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(previousOccurrenceId),
      trackingMode: Value(trackingMode),
      triggerMode: Value(triggerMode),
      status: Value(status),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      triggerOffsetDays: triggerOffsetDays == null && nullToAbsent
          ? const Value.absent()
          : Value(triggerOffsetDays),
      statusNote: statusNote == null && nullToAbsent
          ? const Value.absent()
          : Value(statusNote),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      startAt: Value(startAt),
      deferredDueAt: deferredDueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deferredDueAt),
      topicCategoryId: topicCategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(topicCategoryId),
      actionCategoryId: actionCategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(actionCategoryId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<int>(json['id']),
      recurringReminderId: serializer.fromJson<int?>(
        json['recurringReminderId'],
      ),
      previousOccurrenceId: serializer.fromJson<int?>(
        json['previousOccurrenceId'],
      ),
      trackingMode: serializer.fromJson<int>(json['trackingMode']),
      triggerMode: serializer.fromJson<int>(json['triggerMode']),
      status: serializer.fromJson<int>(json['status']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      triggerOffsetDays: serializer.fromJson<int?>(json['triggerOffsetDays']),
      statusNote: serializer.fromJson<String?>(json['statusNote']),
      dueAt: serializer.fromJson<int?>(json['dueAt']),
      startAt: serializer.fromJson<int>(json['startAt']),
      deferredDueAt: serializer.fromJson<int?>(json['deferredDueAt']),
      topicCategoryId: serializer.fromJson<int?>(json['topicCategoryId']),
      actionCategoryId: serializer.fromJson<int?>(json['actionCategoryId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recurringReminderId': serializer.toJson<int?>(recurringReminderId),
      'previousOccurrenceId': serializer.toJson<int?>(previousOccurrenceId),
      'trackingMode': serializer.toJson<int>(trackingMode),
      'triggerMode': serializer.toJson<int>(triggerMode),
      'status': serializer.toJson<int>(status),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String?>(note),
      'triggerOffsetDays': serializer.toJson<int?>(triggerOffsetDays),
      'statusNote': serializer.toJson<String?>(statusNote),
      'dueAt': serializer.toJson<int?>(dueAt),
      'startAt': serializer.toJson<int>(startAt),
      'deferredDueAt': serializer.toJson<int?>(deferredDueAt),
      'topicCategoryId': serializer.toJson<int?>(topicCategoryId),
      'actionCategoryId': serializer.toJson<int?>(actionCategoryId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Reminder copyWith({
    int? id,
    Value<int?> recurringReminderId = const Value.absent(),
    Value<int?> previousOccurrenceId = const Value.absent(),
    int? trackingMode,
    int? triggerMode,
    int? status,
    String? title,
    Value<String?> note = const Value.absent(),
    Value<int?> triggerOffsetDays = const Value.absent(),
    Value<String?> statusNote = const Value.absent(),
    Value<int?> dueAt = const Value.absent(),
    int? startAt,
    Value<int?> deferredDueAt = const Value.absent(),
    Value<int?> topicCategoryId = const Value.absent(),
    Value<int?> actionCategoryId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Reminder(
    id: id ?? this.id,
    recurringReminderId: recurringReminderId.present
        ? recurringReminderId.value
        : this.recurringReminderId,
    previousOccurrenceId: previousOccurrenceId.present
        ? previousOccurrenceId.value
        : this.previousOccurrenceId,
    trackingMode: trackingMode ?? this.trackingMode,
    triggerMode: triggerMode ?? this.triggerMode,
    status: status ?? this.status,
    title: title ?? this.title,
    note: note.present ? note.value : this.note,
    triggerOffsetDays: triggerOffsetDays.present
        ? triggerOffsetDays.value
        : this.triggerOffsetDays,
    statusNote: statusNote.present ? statusNote.value : this.statusNote,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    startAt: startAt ?? this.startAt,
    deferredDueAt: deferredDueAt.present
        ? deferredDueAt.value
        : this.deferredDueAt,
    topicCategoryId: topicCategoryId.present
        ? topicCategoryId.value
        : this.topicCategoryId,
    actionCategoryId: actionCategoryId.present
        ? actionCategoryId.value
        : this.actionCategoryId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      recurringReminderId: data.recurringReminderId.present
          ? data.recurringReminderId.value
          : this.recurringReminderId,
      previousOccurrenceId: data.previousOccurrenceId.present
          ? data.previousOccurrenceId.value
          : this.previousOccurrenceId,
      trackingMode: data.trackingMode.present
          ? data.trackingMode.value
          : this.trackingMode,
      triggerMode: data.triggerMode.present
          ? data.triggerMode.value
          : this.triggerMode,
      status: data.status.present ? data.status.value : this.status,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      triggerOffsetDays: data.triggerOffsetDays.present
          ? data.triggerOffsetDays.value
          : this.triggerOffsetDays,
      statusNote: data.statusNote.present
          ? data.statusNote.value
          : this.statusNote,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      deferredDueAt: data.deferredDueAt.present
          ? data.deferredDueAt.value
          : this.deferredDueAt,
      topicCategoryId: data.topicCategoryId.present
          ? data.topicCategoryId.value
          : this.topicCategoryId,
      actionCategoryId: data.actionCategoryId.present
          ? data.actionCategoryId.value
          : this.actionCategoryId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('recurringReminderId: $recurringReminderId, ')
          ..write('previousOccurrenceId: $previousOccurrenceId, ')
          ..write('trackingMode: $trackingMode, ')
          ..write('triggerMode: $triggerMode, ')
          ..write('status: $status, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('triggerOffsetDays: $triggerOffsetDays, ')
          ..write('statusNote: $statusNote, ')
          ..write('dueAt: $dueAt, ')
          ..write('startAt: $startAt, ')
          ..write('deferredDueAt: $deferredDueAt, ')
          ..write('topicCategoryId: $topicCategoryId, ')
          ..write('actionCategoryId: $actionCategoryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recurringReminderId,
    previousOccurrenceId,
    trackingMode,
    triggerMode,
    status,
    title,
    note,
    triggerOffsetDays,
    statusNote,
    dueAt,
    startAt,
    deferredDueAt,
    topicCategoryId,
    actionCategoryId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.recurringReminderId == this.recurringReminderId &&
          other.previousOccurrenceId == this.previousOccurrenceId &&
          other.trackingMode == this.trackingMode &&
          other.triggerMode == this.triggerMode &&
          other.status == this.status &&
          other.title == this.title &&
          other.note == this.note &&
          other.triggerOffsetDays == this.triggerOffsetDays &&
          other.statusNote == this.statusNote &&
          other.dueAt == this.dueAt &&
          other.startAt == this.startAt &&
          other.deferredDueAt == this.deferredDueAt &&
          other.topicCategoryId == this.topicCategoryId &&
          other.actionCategoryId == this.actionCategoryId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<int> id;
  final Value<int?> recurringReminderId;
  final Value<int?> previousOccurrenceId;
  final Value<int> trackingMode;
  final Value<int> triggerMode;
  final Value<int> status;
  final Value<String> title;
  final Value<String?> note;
  final Value<int?> triggerOffsetDays;
  final Value<String?> statusNote;
  final Value<int?> dueAt;
  final Value<int> startAt;
  final Value<int?> deferredDueAt;
  final Value<int?> topicCategoryId;
  final Value<int?> actionCategoryId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.recurringReminderId = const Value.absent(),
    this.previousOccurrenceId = const Value.absent(),
    this.trackingMode = const Value.absent(),
    this.triggerMode = const Value.absent(),
    this.status = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.triggerOffsetDays = const Value.absent(),
    this.statusNote = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.startAt = const Value.absent(),
    this.deferredDueAt = const Value.absent(),
    this.topicCategoryId = const Value.absent(),
    this.actionCategoryId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    this.recurringReminderId = const Value.absent(),
    this.previousOccurrenceId = const Value.absent(),
    required int trackingMode,
    required int triggerMode,
    this.status = const Value.absent(),
    required String title,
    this.note = const Value.absent(),
    this.triggerOffsetDays = const Value.absent(),
    this.statusNote = const Value.absent(),
    this.dueAt = const Value.absent(),
    required int startAt,
    this.deferredDueAt = const Value.absent(),
    this.topicCategoryId = const Value.absent(),
    this.actionCategoryId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : trackingMode = Value(trackingMode),
       triggerMode = Value(triggerMode),
       title = Value(title),
       startAt = Value(startAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Reminder> custom({
    Expression<int>? id,
    Expression<int>? recurringReminderId,
    Expression<int>? previousOccurrenceId,
    Expression<int>? trackingMode,
    Expression<int>? triggerMode,
    Expression<int>? status,
    Expression<String>? title,
    Expression<String>? note,
    Expression<int>? triggerOffsetDays,
    Expression<String>? statusNote,
    Expression<int>? dueAt,
    Expression<int>? startAt,
    Expression<int>? deferredDueAt,
    Expression<int>? topicCategoryId,
    Expression<int>? actionCategoryId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recurringReminderId != null)
        'recurring_reminder_id': recurringReminderId,
      if (previousOccurrenceId != null)
        'previous_occurrence_id': previousOccurrenceId,
      if (trackingMode != null) 'tracking_mode': trackingMode,
      if (triggerMode != null) 'trigger_mode': triggerMode,
      if (status != null) 'status': status,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (triggerOffsetDays != null) 'trigger_offset_days': triggerOffsetDays,
      if (statusNote != null) 'status_note': statusNote,
      if (dueAt != null) 'due_at': dueAt,
      if (startAt != null) 'start_at': startAt,
      if (deferredDueAt != null) 'deferred_due_at': deferredDueAt,
      if (topicCategoryId != null) 'topic_category_id': topicCategoryId,
      if (actionCategoryId != null) 'action_category_id': actionCategoryId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<int?>? recurringReminderId,
    Value<int?>? previousOccurrenceId,
    Value<int>? trackingMode,
    Value<int>? triggerMode,
    Value<int>? status,
    Value<String>? title,
    Value<String?>? note,
    Value<int?>? triggerOffsetDays,
    Value<String?>? statusNote,
    Value<int?>? dueAt,
    Value<int>? startAt,
    Value<int?>? deferredDueAt,
    Value<int?>? topicCategoryId,
    Value<int?>? actionCategoryId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      recurringReminderId: recurringReminderId ?? this.recurringReminderId,
      previousOccurrenceId: previousOccurrenceId ?? this.previousOccurrenceId,
      trackingMode: trackingMode ?? this.trackingMode,
      triggerMode: triggerMode ?? this.triggerMode,
      status: status ?? this.status,
      title: title ?? this.title,
      note: note ?? this.note,
      triggerOffsetDays: triggerOffsetDays ?? this.triggerOffsetDays,
      statusNote: statusNote ?? this.statusNote,
      dueAt: dueAt ?? this.dueAt,
      startAt: startAt ?? this.startAt,
      deferredDueAt: deferredDueAt ?? this.deferredDueAt,
      topicCategoryId: topicCategoryId ?? this.topicCategoryId,
      actionCategoryId: actionCategoryId ?? this.actionCategoryId,
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
    if (recurringReminderId.present) {
      map['recurring_reminder_id'] = Variable<int>(recurringReminderId.value);
    }
    if (previousOccurrenceId.present) {
      map['previous_occurrence_id'] = Variable<int>(previousOccurrenceId.value);
    }
    if (trackingMode.present) {
      map['tracking_mode'] = Variable<int>(trackingMode.value);
    }
    if (triggerMode.present) {
      map['trigger_mode'] = Variable<int>(triggerMode.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (triggerOffsetDays.present) {
      map['trigger_offset_days'] = Variable<int>(triggerOffsetDays.value);
    }
    if (statusNote.present) {
      map['status_note'] = Variable<String>(statusNote.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<int>(dueAt.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<int>(startAt.value);
    }
    if (deferredDueAt.present) {
      map['deferred_due_at'] = Variable<int>(deferredDueAt.value);
    }
    if (topicCategoryId.present) {
      map['topic_category_id'] = Variable<int>(topicCategoryId.value);
    }
    if (actionCategoryId.present) {
      map['action_category_id'] = Variable<int>(actionCategoryId.value);
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
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('recurringReminderId: $recurringReminderId, ')
          ..write('previousOccurrenceId: $previousOccurrenceId, ')
          ..write('trackingMode: $trackingMode, ')
          ..write('triggerMode: $triggerMode, ')
          ..write('status: $status, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('triggerOffsetDays: $triggerOffsetDays, ')
          ..write('statusNote: $statusNote, ')
          ..write('dueAt: $dueAt, ')
          ..write('startAt: $startAt, ')
          ..write('deferredDueAt: $deferredDueAt, ')
          ..write('topicCategoryId: $topicCategoryId, ')
          ..write('actionCategoryId: $actionCategoryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RecurringRemindersTable recurringReminders =
      $RecurringRemindersTable(this);
  late final $TopicCategoriesTable topicCategories = $TopicCategoriesTable(
    this,
  );
  late final $ActionCategoriesTable actionCategories = $ActionCategoriesTable(
    this,
  );
  late final $RemindersTable reminders = $RemindersTable(this);
  late final ReminderDao reminderDao = ReminderDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    recurringReminders,
    topicCategories,
    actionCategories,
    reminders,
  ];
}

typedef $$RecurringRemindersTableCreateCompanionBuilder =
    RecurringRemindersCompanion Function({
      Value<int> id,
      Value<int> status,
      required String title,
      Value<String?> note,
      required int trackingMode,
      required int triggerMode,
      Value<int?> triggerOffsetDays,
      Value<String?> repeatRule,
      Value<int?> topicCategoryId,
      Value<int?> actionCategoryId,
      required int createdAt,
      required int updatedAt,
    });
typedef $$RecurringRemindersTableUpdateCompanionBuilder =
    RecurringRemindersCompanion Function({
      Value<int> id,
      Value<int> status,
      Value<String> title,
      Value<String?> note,
      Value<int> trackingMode,
      Value<int> triggerMode,
      Value<int?> triggerOffsetDays,
      Value<String?> repeatRule,
      Value<int?> topicCategoryId,
      Value<int?> actionCategoryId,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

class $$RecurringRemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringRemindersTable> {
  $$RecurringRemindersTableFilterComposer({
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

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackingMode => $composableBuilder(
    column: $table.trackingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get triggerMode => $composableBuilder(
    column: $table.triggerMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get triggerOffsetDays => $composableBuilder(
    column: $table.triggerOffsetDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get topicCategoryId => $composableBuilder(
    column: $table.topicCategoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actionCategoryId => $composableBuilder(
    column: $table.actionCategoryId,
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

class $$RecurringRemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringRemindersTable> {
  $$RecurringRemindersTableOrderingComposer({
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

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackingMode => $composableBuilder(
    column: $table.trackingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get triggerMode => $composableBuilder(
    column: $table.triggerMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get triggerOffsetDays => $composableBuilder(
    column: $table.triggerOffsetDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get topicCategoryId => $composableBuilder(
    column: $table.topicCategoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actionCategoryId => $composableBuilder(
    column: $table.actionCategoryId,
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

class $$RecurringRemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringRemindersTable> {
  $$RecurringRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get trackingMode => $composableBuilder(
    column: $table.trackingMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get triggerMode => $composableBuilder(
    column: $table.triggerMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get triggerOffsetDays => $composableBuilder(
    column: $table.triggerOffsetDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => column,
  );

  GeneratedColumn<int> get topicCategoryId => $composableBuilder(
    column: $table.topicCategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actionCategoryId => $composableBuilder(
    column: $table.actionCategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RecurringRemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringRemindersTable,
          RecurringReminder,
          $$RecurringRemindersTableFilterComposer,
          $$RecurringRemindersTableOrderingComposer,
          $$RecurringRemindersTableAnnotationComposer,
          $$RecurringRemindersTableCreateCompanionBuilder,
          $$RecurringRemindersTableUpdateCompanionBuilder,
          (
            RecurringReminder,
            BaseReferences<
              _$AppDatabase,
              $RecurringRemindersTable,
              RecurringReminder
            >,
          ),
          RecurringReminder,
          PrefetchHooks Function()
        > {
  $$RecurringRemindersTableTableManager(
    _$AppDatabase db,
    $RecurringRemindersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringRemindersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> trackingMode = const Value.absent(),
                Value<int> triggerMode = const Value.absent(),
                Value<int?> triggerOffsetDays = const Value.absent(),
                Value<String?> repeatRule = const Value.absent(),
                Value<int?> topicCategoryId = const Value.absent(),
                Value<int?> actionCategoryId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => RecurringRemindersCompanion(
                id: id,
                status: status,
                title: title,
                note: note,
                trackingMode: trackingMode,
                triggerMode: triggerMode,
                triggerOffsetDays: triggerOffsetDays,
                repeatRule: repeatRule,
                topicCategoryId: topicCategoryId,
                actionCategoryId: actionCategoryId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> status = const Value.absent(),
                required String title,
                Value<String?> note = const Value.absent(),
                required int trackingMode,
                required int triggerMode,
                Value<int?> triggerOffsetDays = const Value.absent(),
                Value<String?> repeatRule = const Value.absent(),
                Value<int?> topicCategoryId = const Value.absent(),
                Value<int?> actionCategoryId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => RecurringRemindersCompanion.insert(
                id: id,
                status: status,
                title: title,
                note: note,
                trackingMode: trackingMode,
                triggerMode: triggerMode,
                triggerOffsetDays: triggerOffsetDays,
                repeatRule: repeatRule,
                topicCategoryId: topicCategoryId,
                actionCategoryId: actionCategoryId,
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

typedef $$RecurringRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringRemindersTable,
      RecurringReminder,
      $$RecurringRemindersTableFilterComposer,
      $$RecurringRemindersTableOrderingComposer,
      $$RecurringRemindersTableAnnotationComposer,
      $$RecurringRemindersTableCreateCompanionBuilder,
      $$RecurringRemindersTableUpdateCompanionBuilder,
      (
        RecurringReminder,
        BaseReferences<
          _$AppDatabase,
          $RecurringRemindersTable,
          RecurringReminder
        >,
      ),
      RecurringReminder,
      PrefetchHooks Function()
    >;
typedef $$TopicCategoriesTableCreateCompanionBuilder =
    TopicCategoriesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      required int createdAt,
      required int updatedAt,
    });
typedef $$TopicCategoriesTableUpdateCompanionBuilder =
    TopicCategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

class $$TopicCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $TopicCategoriesTable> {
  $$TopicCategoriesTableFilterComposer({
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
}

class $$TopicCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TopicCategoriesTable> {
  $$TopicCategoriesTableOrderingComposer({
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

class $$TopicCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TopicCategoriesTable> {
  $$TopicCategoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TopicCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TopicCategoriesTable,
          TopicCategory,
          $$TopicCategoriesTableFilterComposer,
          $$TopicCategoriesTableOrderingComposer,
          $$TopicCategoriesTableAnnotationComposer,
          $$TopicCategoriesTableCreateCompanionBuilder,
          $$TopicCategoriesTableUpdateCompanionBuilder,
          (
            TopicCategory,
            BaseReferences<_$AppDatabase, $TopicCategoriesTable, TopicCategory>,
          ),
          TopicCategory,
          PrefetchHooks Function()
        > {
  $$TopicCategoriesTableTableManager(
    _$AppDatabase db,
    $TopicCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopicCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopicCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TopicCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => TopicCategoriesCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => TopicCategoriesCompanion.insert(
                id: id,
                name: name,
                description: description,
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

typedef $$TopicCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TopicCategoriesTable,
      TopicCategory,
      $$TopicCategoriesTableFilterComposer,
      $$TopicCategoriesTableOrderingComposer,
      $$TopicCategoriesTableAnnotationComposer,
      $$TopicCategoriesTableCreateCompanionBuilder,
      $$TopicCategoriesTableUpdateCompanionBuilder,
      (
        TopicCategory,
        BaseReferences<_$AppDatabase, $TopicCategoriesTable, TopicCategory>,
      ),
      TopicCategory,
      PrefetchHooks Function()
    >;
typedef $$ActionCategoriesTableCreateCompanionBuilder =
    ActionCategoriesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      required int createdAt,
      required int updatedAt,
    });
typedef $$ActionCategoriesTableUpdateCompanionBuilder =
    ActionCategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

class $$ActionCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $ActionCategoriesTable> {
  $$ActionCategoriesTableFilterComposer({
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
}

class $$ActionCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ActionCategoriesTable> {
  $$ActionCategoriesTableOrderingComposer({
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

class $$ActionCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActionCategoriesTable> {
  $$ActionCategoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ActionCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActionCategoriesTable,
          ActionCategory,
          $$ActionCategoriesTableFilterComposer,
          $$ActionCategoriesTableOrderingComposer,
          $$ActionCategoriesTableAnnotationComposer,
          $$ActionCategoriesTableCreateCompanionBuilder,
          $$ActionCategoriesTableUpdateCompanionBuilder,
          (
            ActionCategory,
            BaseReferences<
              _$AppDatabase,
              $ActionCategoriesTable,
              ActionCategory
            >,
          ),
          ActionCategory,
          PrefetchHooks Function()
        > {
  $$ActionCategoriesTableTableManager(
    _$AppDatabase db,
    $ActionCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActionCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActionCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActionCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ActionCategoriesCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ActionCategoriesCompanion.insert(
                id: id,
                name: name,
                description: description,
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

typedef $$ActionCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActionCategoriesTable,
      ActionCategory,
      $$ActionCategoriesTableFilterComposer,
      $$ActionCategoriesTableOrderingComposer,
      $$ActionCategoriesTableAnnotationComposer,
      $$ActionCategoriesTableCreateCompanionBuilder,
      $$ActionCategoriesTableUpdateCompanionBuilder,
      (
        ActionCategory,
        BaseReferences<_$AppDatabase, $ActionCategoriesTable, ActionCategory>,
      ),
      ActionCategory,
      PrefetchHooks Function()
    >;
typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      Value<int?> recurringReminderId,
      Value<int?> previousOccurrenceId,
      required int trackingMode,
      required int triggerMode,
      Value<int> status,
      required String title,
      Value<String?> note,
      Value<int?> triggerOffsetDays,
      Value<String?> statusNote,
      Value<int?> dueAt,
      required int startAt,
      Value<int?> deferredDueAt,
      Value<int?> topicCategoryId,
      Value<int?> actionCategoryId,
      required int createdAt,
      required int updatedAt,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      Value<int?> recurringReminderId,
      Value<int?> previousOccurrenceId,
      Value<int> trackingMode,
      Value<int> triggerMode,
      Value<int> status,
      Value<String> title,
      Value<String?> note,
      Value<int?> triggerOffsetDays,
      Value<String?> statusNote,
      Value<int?> dueAt,
      Value<int> startAt,
      Value<int?> deferredDueAt,
      Value<int?> topicCategoryId,
      Value<int?> actionCategoryId,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
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

  ColumnFilters<int> get recurringReminderId => $composableBuilder(
    column: $table.recurringReminderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get previousOccurrenceId => $composableBuilder(
    column: $table.previousOccurrenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackingMode => $composableBuilder(
    column: $table.trackingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get triggerMode => $composableBuilder(
    column: $table.triggerMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get triggerOffsetDays => $composableBuilder(
    column: $table.triggerOffsetDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statusNote => $composableBuilder(
    column: $table.statusNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deferredDueAt => $composableBuilder(
    column: $table.deferredDueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get topicCategoryId => $composableBuilder(
    column: $table.topicCategoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actionCategoryId => $composableBuilder(
    column: $table.actionCategoryId,
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

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
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

  ColumnOrderings<int> get recurringReminderId => $composableBuilder(
    column: $table.recurringReminderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get previousOccurrenceId => $composableBuilder(
    column: $table.previousOccurrenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackingMode => $composableBuilder(
    column: $table.trackingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get triggerMode => $composableBuilder(
    column: $table.triggerMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get triggerOffsetDays => $composableBuilder(
    column: $table.triggerOffsetDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusNote => $composableBuilder(
    column: $table.statusNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deferredDueAt => $composableBuilder(
    column: $table.deferredDueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get topicCategoryId => $composableBuilder(
    column: $table.topicCategoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actionCategoryId => $composableBuilder(
    column: $table.actionCategoryId,
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

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get recurringReminderId => $composableBuilder(
    column: $table.recurringReminderId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get previousOccurrenceId => $composableBuilder(
    column: $table.previousOccurrenceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trackingMode => $composableBuilder(
    column: $table.trackingMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get triggerMode => $composableBuilder(
    column: $table.triggerMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get triggerOffsetDays => $composableBuilder(
    column: $table.triggerOffsetDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statusNote => $composableBuilder(
    column: $table.statusNote,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<int> get deferredDueAt => $composableBuilder(
    column: $table.deferredDueAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get topicCategoryId => $composableBuilder(
    column: $table.topicCategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actionCategoryId => $composableBuilder(
    column: $table.actionCategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
          Reminder,
          PrefetchHooks Function()
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> recurringReminderId = const Value.absent(),
                Value<int?> previousOccurrenceId = const Value.absent(),
                Value<int> trackingMode = const Value.absent(),
                Value<int> triggerMode = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> triggerOffsetDays = const Value.absent(),
                Value<String?> statusNote = const Value.absent(),
                Value<int?> dueAt = const Value.absent(),
                Value<int> startAt = const Value.absent(),
                Value<int?> deferredDueAt = const Value.absent(),
                Value<int?> topicCategoryId = const Value.absent(),
                Value<int?> actionCategoryId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                recurringReminderId: recurringReminderId,
                previousOccurrenceId: previousOccurrenceId,
                trackingMode: trackingMode,
                triggerMode: triggerMode,
                status: status,
                title: title,
                note: note,
                triggerOffsetDays: triggerOffsetDays,
                statusNote: statusNote,
                dueAt: dueAt,
                startAt: startAt,
                deferredDueAt: deferredDueAt,
                topicCategoryId: topicCategoryId,
                actionCategoryId: actionCategoryId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> recurringReminderId = const Value.absent(),
                Value<int?> previousOccurrenceId = const Value.absent(),
                required int trackingMode,
                required int triggerMode,
                Value<int> status = const Value.absent(),
                required String title,
                Value<String?> note = const Value.absent(),
                Value<int?> triggerOffsetDays = const Value.absent(),
                Value<String?> statusNote = const Value.absent(),
                Value<int?> dueAt = const Value.absent(),
                required int startAt,
                Value<int?> deferredDueAt = const Value.absent(),
                Value<int?> topicCategoryId = const Value.absent(),
                Value<int?> actionCategoryId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => RemindersCompanion.insert(
                id: id,
                recurringReminderId: recurringReminderId,
                previousOccurrenceId: previousOccurrenceId,
                trackingMode: trackingMode,
                triggerMode: triggerMode,
                status: status,
                title: title,
                note: note,
                triggerOffsetDays: triggerOffsetDays,
                statusNote: statusNote,
                dueAt: dueAt,
                startAt: startAt,
                deferredDueAt: deferredDueAt,
                topicCategoryId: topicCategoryId,
                actionCategoryId: actionCategoryId,
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

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
      Reminder,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RecurringRemindersTableTableManager get recurringReminders =>
      $$RecurringRemindersTableTableManager(_db, _db.recurringReminders);
  $$TopicCategoriesTableTableManager get topicCategories =>
      $$TopicCategoriesTableTableManager(_db, _db.topicCategories);
  $$ActionCategoriesTableTableManager get actionCategories =>
      $$ActionCategoriesTableTableManager(_db, _db.actionCategories);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
}
