// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ReminderSeriesEntriesTable extends ReminderSeriesEntries
    with TableInfo<$ReminderSeriesEntriesTable, ReminderSeriesEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderSeriesEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _timeBasisMeta = const VerificationMeta(
    'timeBasis',
  );
  @override
  late final GeneratedColumn<int> timeBasis = GeneratedColumn<int>(
    'time_basis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notifyStrategyMeta = const VerificationMeta(
    'notifyStrategy',
  );
  @override
  late final GeneratedColumn<int> notifyStrategy = GeneratedColumn<int>(
    'notify_strategy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remindDaysMeta = const VerificationMeta(
    'remindDays',
  );
  @override
  late final GeneratedColumn<int> remindDays = GeneratedColumn<int>(
    'remind_days',
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
  static const VerificationMeta _issueTypeIdMeta = const VerificationMeta(
    'issueTypeId',
  );
  @override
  late final GeneratedColumn<int> issueTypeId = GeneratedColumn<int>(
    'issue_type_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _handleTypeIdMeta = const VerificationMeta(
    'handleTypeId',
  );
  @override
  late final GeneratedColumn<int> handleTypeId = GeneratedColumn<int>(
    'handle_type_id',
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
    timeBasis,
    notifyStrategy,
    remindDays,
    repeatRule,
    issueTypeId,
    handleTypeId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_series';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderSeriesEntry> instance, {
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
    if (data.containsKey('time_basis')) {
      context.handle(
        _timeBasisMeta,
        timeBasis.isAcceptableOrUnknown(data['time_basis']!, _timeBasisMeta),
      );
    } else if (isInserting) {
      context.missing(_timeBasisMeta);
    }
    if (data.containsKey('notify_strategy')) {
      context.handle(
        _notifyStrategyMeta,
        notifyStrategy.isAcceptableOrUnknown(
          data['notify_strategy']!,
          _notifyStrategyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notifyStrategyMeta);
    }
    if (data.containsKey('remind_days')) {
      context.handle(
        _remindDaysMeta,
        remindDays.isAcceptableOrUnknown(data['remind_days']!, _remindDaysMeta),
      );
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(
        _repeatRuleMeta,
        repeatRule.isAcceptableOrUnknown(data['repeat_rule']!, _repeatRuleMeta),
      );
    }
    if (data.containsKey('issue_type_id')) {
      context.handle(
        _issueTypeIdMeta,
        issueTypeId.isAcceptableOrUnknown(
          data['issue_type_id']!,
          _issueTypeIdMeta,
        ),
      );
    }
    if (data.containsKey('handle_type_id')) {
      context.handle(
        _handleTypeIdMeta,
        handleTypeId.isAcceptableOrUnknown(
          data['handle_type_id']!,
          _handleTypeIdMeta,
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
  ReminderSeriesEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderSeriesEntry(
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
      timeBasis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_basis'],
      )!,
      notifyStrategy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notify_strategy'],
      )!,
      remindDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remind_days'],
      ),
      repeatRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_rule'],
      ),
      issueTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}issue_type_id'],
      ),
      handleTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}handle_type_id'],
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
  $ReminderSeriesEntriesTable createAlias(String alias) {
    return $ReminderSeriesEntriesTable(attachedDatabase, alias);
  }
}

class ReminderSeriesEntry extends DataClass
    implements Insertable<ReminderSeriesEntry> {
  final int id;

  /// 0: pending, 1: stopped, 2: canceled.
  final int status;
  final String title;
  final String? note;

  /// 1: countdown, 2: count-up.
  final int timeBasis;

  /// 1: in-range, 2: on-point.
  final int notifyStrategy;
  final int? remindDays;

  /// Null means not recurring; otherwise D25 / W3 / M1 / Y1.
  final String? repeatRule;
  final int? issueTypeId;
  final int? handleTypeId;
  final int createdAt;
  final int updatedAt;
  const ReminderSeriesEntry({
    required this.id,
    required this.status,
    required this.title,
    this.note,
    required this.timeBasis,
    required this.notifyStrategy,
    this.remindDays,
    this.repeatRule,
    this.issueTypeId,
    this.handleTypeId,
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
    map['time_basis'] = Variable<int>(timeBasis);
    map['notify_strategy'] = Variable<int>(notifyStrategy);
    if (!nullToAbsent || remindDays != null) {
      map['remind_days'] = Variable<int>(remindDays);
    }
    if (!nullToAbsent || repeatRule != null) {
      map['repeat_rule'] = Variable<String>(repeatRule);
    }
    if (!nullToAbsent || issueTypeId != null) {
      map['issue_type_id'] = Variable<int>(issueTypeId);
    }
    if (!nullToAbsent || handleTypeId != null) {
      map['handle_type_id'] = Variable<int>(handleTypeId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ReminderSeriesEntriesCompanion toCompanion(bool nullToAbsent) {
    return ReminderSeriesEntriesCompanion(
      id: Value(id),
      status: Value(status),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      timeBasis: Value(timeBasis),
      notifyStrategy: Value(notifyStrategy),
      remindDays: remindDays == null && nullToAbsent
          ? const Value.absent()
          : Value(remindDays),
      repeatRule: repeatRule == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatRule),
      issueTypeId: issueTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(issueTypeId),
      handleTypeId: handleTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(handleTypeId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReminderSeriesEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderSeriesEntry(
      id: serializer.fromJson<int>(json['id']),
      status: serializer.fromJson<int>(json['status']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      timeBasis: serializer.fromJson<int>(json['timeBasis']),
      notifyStrategy: serializer.fromJson<int>(json['notifyStrategy']),
      remindDays: serializer.fromJson<int?>(json['remindDays']),
      repeatRule: serializer.fromJson<String?>(json['repeatRule']),
      issueTypeId: serializer.fromJson<int?>(json['issueTypeId']),
      handleTypeId: serializer.fromJson<int?>(json['handleTypeId']),
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
      'timeBasis': serializer.toJson<int>(timeBasis),
      'notifyStrategy': serializer.toJson<int>(notifyStrategy),
      'remindDays': serializer.toJson<int?>(remindDays),
      'repeatRule': serializer.toJson<String?>(repeatRule),
      'issueTypeId': serializer.toJson<int?>(issueTypeId),
      'handleTypeId': serializer.toJson<int?>(handleTypeId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ReminderSeriesEntry copyWith({
    int? id,
    int? status,
    String? title,
    Value<String?> note = const Value.absent(),
    int? timeBasis,
    int? notifyStrategy,
    Value<int?> remindDays = const Value.absent(),
    Value<String?> repeatRule = const Value.absent(),
    Value<int?> issueTypeId = const Value.absent(),
    Value<int?> handleTypeId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => ReminderSeriesEntry(
    id: id ?? this.id,
    status: status ?? this.status,
    title: title ?? this.title,
    note: note.present ? note.value : this.note,
    timeBasis: timeBasis ?? this.timeBasis,
    notifyStrategy: notifyStrategy ?? this.notifyStrategy,
    remindDays: remindDays.present ? remindDays.value : this.remindDays,
    repeatRule: repeatRule.present ? repeatRule.value : this.repeatRule,
    issueTypeId: issueTypeId.present ? issueTypeId.value : this.issueTypeId,
    handleTypeId: handleTypeId.present ? handleTypeId.value : this.handleTypeId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReminderSeriesEntry copyWithCompanion(ReminderSeriesEntriesCompanion data) {
    return ReminderSeriesEntry(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      timeBasis: data.timeBasis.present ? data.timeBasis.value : this.timeBasis,
      notifyStrategy: data.notifyStrategy.present
          ? data.notifyStrategy.value
          : this.notifyStrategy,
      remindDays: data.remindDays.present
          ? data.remindDays.value
          : this.remindDays,
      repeatRule: data.repeatRule.present
          ? data.repeatRule.value
          : this.repeatRule,
      issueTypeId: data.issueTypeId.present
          ? data.issueTypeId.value
          : this.issueTypeId,
      handleTypeId: data.handleTypeId.present
          ? data.handleTypeId.value
          : this.handleTypeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderSeriesEntry(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('timeBasis: $timeBasis, ')
          ..write('notifyStrategy: $notifyStrategy, ')
          ..write('remindDays: $remindDays, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('issueTypeId: $issueTypeId, ')
          ..write('handleTypeId: $handleTypeId, ')
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
    timeBasis,
    notifyStrategy,
    remindDays,
    repeatRule,
    issueTypeId,
    handleTypeId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderSeriesEntry &&
          other.id == this.id &&
          other.status == this.status &&
          other.title == this.title &&
          other.note == this.note &&
          other.timeBasis == this.timeBasis &&
          other.notifyStrategy == this.notifyStrategy &&
          other.remindDays == this.remindDays &&
          other.repeatRule == this.repeatRule &&
          other.issueTypeId == this.issueTypeId &&
          other.handleTypeId == this.handleTypeId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ReminderSeriesEntriesCompanion
    extends UpdateCompanion<ReminderSeriesEntry> {
  final Value<int> id;
  final Value<int> status;
  final Value<String> title;
  final Value<String?> note;
  final Value<int> timeBasis;
  final Value<int> notifyStrategy;
  final Value<int?> remindDays;
  final Value<String?> repeatRule;
  final Value<int?> issueTypeId;
  final Value<int?> handleTypeId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ReminderSeriesEntriesCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.timeBasis = const Value.absent(),
    this.notifyStrategy = const Value.absent(),
    this.remindDays = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.issueTypeId = const Value.absent(),
    this.handleTypeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ReminderSeriesEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    required String title,
    this.note = const Value.absent(),
    required int timeBasis,
    required int notifyStrategy,
    this.remindDays = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.issueTypeId = const Value.absent(),
    this.handleTypeId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : title = Value(title),
       timeBasis = Value(timeBasis),
       notifyStrategy = Value(notifyStrategy),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ReminderSeriesEntry> custom({
    Expression<int>? id,
    Expression<int>? status,
    Expression<String>? title,
    Expression<String>? note,
    Expression<int>? timeBasis,
    Expression<int>? notifyStrategy,
    Expression<int>? remindDays,
    Expression<String>? repeatRule,
    Expression<int>? issueTypeId,
    Expression<int>? handleTypeId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (timeBasis != null) 'time_basis': timeBasis,
      if (notifyStrategy != null) 'notify_strategy': notifyStrategy,
      if (remindDays != null) 'remind_days': remindDays,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (issueTypeId != null) 'issue_type_id': issueTypeId,
      if (handleTypeId != null) 'handle_type_id': handleTypeId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ReminderSeriesEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? status,
    Value<String>? title,
    Value<String?>? note,
    Value<int>? timeBasis,
    Value<int>? notifyStrategy,
    Value<int?>? remindDays,
    Value<String?>? repeatRule,
    Value<int?>? issueTypeId,
    Value<int?>? handleTypeId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ReminderSeriesEntriesCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      title: title ?? this.title,
      note: note ?? this.note,
      timeBasis: timeBasis ?? this.timeBasis,
      notifyStrategy: notifyStrategy ?? this.notifyStrategy,
      remindDays: remindDays ?? this.remindDays,
      repeatRule: repeatRule ?? this.repeatRule,
      issueTypeId: issueTypeId ?? this.issueTypeId,
      handleTypeId: handleTypeId ?? this.handleTypeId,
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
    if (timeBasis.present) {
      map['time_basis'] = Variable<int>(timeBasis.value);
    }
    if (notifyStrategy.present) {
      map['notify_strategy'] = Variable<int>(notifyStrategy.value);
    }
    if (remindDays.present) {
      map['remind_days'] = Variable<int>(remindDays.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (issueTypeId.present) {
      map['issue_type_id'] = Variable<int>(issueTypeId.value);
    }
    if (handleTypeId.present) {
      map['handle_type_id'] = Variable<int>(handleTypeId.value);
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
    return (StringBuffer('ReminderSeriesEntriesCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('timeBasis: $timeBasis, ')
          ..write('notifyStrategy: $notifyStrategy, ')
          ..write('remindDays: $remindDays, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('issueTypeId: $issueTypeId, ')
          ..write('handleTypeId: $handleTypeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $IssueTypesTable extends IssueTypes
    with TableInfo<$IssueTypesTable, IssueType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IssueTypesTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'issue_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<IssueType> instance, {
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
  IssueType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IssueType(
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
  $IssueTypesTable createAlias(String alias) {
    return $IssueTypesTable(attachedDatabase, alias);
  }
}

class IssueType extends DataClass implements Insertable<IssueType> {
  final int id;
  final String name;
  final String? description;
  final int createdAt;
  final int updatedAt;
  const IssueType({
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

  IssueTypesCompanion toCompanion(bool nullToAbsent) {
    return IssueTypesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory IssueType.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IssueType(
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

  IssueType copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => IssueType(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  IssueType copyWithCompanion(IssueTypesCompanion data) {
    return IssueType(
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
    return (StringBuffer('IssueType(')
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
      (other is IssueType &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class IssueTypesCompanion extends UpdateCompanion<IssueType> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const IssueTypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  IssueTypesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<IssueType> custom({
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

  IssueTypesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return IssueTypesCompanion(
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
    return (StringBuffer('IssueTypesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $HandleTypesTable extends HandleTypes
    with TableInfo<$HandleTypesTable, HandleType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HandleTypesTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'handle_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<HandleType> instance, {
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
  HandleType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HandleType(
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
  $HandleTypesTable createAlias(String alias) {
    return $HandleTypesTable(attachedDatabase, alias);
  }
}

class HandleType extends DataClass implements Insertable<HandleType> {
  final int id;
  final String name;
  final String? description;
  final int createdAt;
  final int updatedAt;
  const HandleType({
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

  HandleTypesCompanion toCompanion(bool nullToAbsent) {
    return HandleTypesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HandleType.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HandleType(
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

  HandleType copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => HandleType(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HandleType copyWithCompanion(HandleTypesCompanion data) {
    return HandleType(
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
    return (StringBuffer('HandleType(')
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
      (other is HandleType &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HandleTypesCompanion extends UpdateCompanion<HandleType> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const HandleTypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  HandleTypesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<HandleType> custom({
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

  HandleTypesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return HandleTypesCompanion(
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
    return (StringBuffer('HandleTypesCompanion(')
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
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _previousReminderIdMeta =
      const VerificationMeta('previousReminderId');
  @override
  late final GeneratedColumn<int> previousReminderId = GeneratedColumn<int>(
    'previous_reminder_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeBasisMeta = const VerificationMeta(
    'timeBasis',
  );
  @override
  late final GeneratedColumn<int> timeBasis = GeneratedColumn<int>(
    'time_basis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notifyStrategyMeta = const VerificationMeta(
    'notifyStrategy',
  );
  @override
  late final GeneratedColumn<int> notifyStrategy = GeneratedColumn<int>(
    'notify_strategy',
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
  static const VerificationMeta _remindDaysMeta = const VerificationMeta(
    'remindDays',
  );
  @override
  late final GeneratedColumn<int> remindDays = GeneratedColumn<int>(
    'remind_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _extendAtMeta = const VerificationMeta(
    'extendAt',
  );
  @override
  late final GeneratedColumn<int> extendAt = GeneratedColumn<int>(
    'extend_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issueTypeIdMeta = const VerificationMeta(
    'issueTypeId',
  );
  @override
  late final GeneratedColumn<int> issueTypeId = GeneratedColumn<int>(
    'issue_type_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _handleTypeIdMeta = const VerificationMeta(
    'handleTypeId',
  );
  @override
  late final GeneratedColumn<int> handleTypeId = GeneratedColumn<int>(
    'handle_type_id',
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
    seriesId,
    previousReminderId,
    timeBasis,
    notifyStrategy,
    status,
    title,
    note,
    remindDays,
    remark,
    dueAt,
    startAt,
    extendAt,
    issueTypeId,
    handleTypeId,
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
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('previous_reminder_id')) {
      context.handle(
        _previousReminderIdMeta,
        previousReminderId.isAcceptableOrUnknown(
          data['previous_reminder_id']!,
          _previousReminderIdMeta,
        ),
      );
    }
    if (data.containsKey('time_basis')) {
      context.handle(
        _timeBasisMeta,
        timeBasis.isAcceptableOrUnknown(data['time_basis']!, _timeBasisMeta),
      );
    } else if (isInserting) {
      context.missing(_timeBasisMeta);
    }
    if (data.containsKey('notify_strategy')) {
      context.handle(
        _notifyStrategyMeta,
        notifyStrategy.isAcceptableOrUnknown(
          data['notify_strategy']!,
          _notifyStrategyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notifyStrategyMeta);
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
    if (data.containsKey('remind_days')) {
      context.handle(
        _remindDaysMeta,
        remindDays.isAcceptableOrUnknown(data['remind_days']!, _remindDaysMeta),
      );
    }
    if (data.containsKey('remark')) {
      context.handle(
        _remarkMeta,
        remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta),
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
    if (data.containsKey('extend_at')) {
      context.handle(
        _extendAtMeta,
        extendAt.isAcceptableOrUnknown(data['extend_at']!, _extendAtMeta),
      );
    }
    if (data.containsKey('issue_type_id')) {
      context.handle(
        _issueTypeIdMeta,
        issueTypeId.isAcceptableOrUnknown(
          data['issue_type_id']!,
          _issueTypeIdMeta,
        ),
      );
    }
    if (data.containsKey('handle_type_id')) {
      context.handle(
        _handleTypeIdMeta,
        handleTypeId.isAcceptableOrUnknown(
          data['handle_type_id']!,
          _handleTypeIdMeta,
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
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_id'],
      ),
      previousReminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}previous_reminder_id'],
      ),
      timeBasis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_basis'],
      )!,
      notifyStrategy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notify_strategy'],
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
      remindDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remind_days'],
      ),
      remark: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remark'],
      ),
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_at'],
      ),
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_at'],
      )!,
      extendAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}extend_at'],
      ),
      issueTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}issue_type_id'],
      ),
      handleTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}handle_type_id'],
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
  final int? seriesId;
  final int? previousReminderId;

  /// 1: countdown, 2: count-up.
  final int timeBasis;

  /// 1: in-range, 2: on-point.
  final int notifyStrategy;

  /// 0: pending, 1: done, 2: skipped, 3: canceled.
  final int status;
  final String title;
  final String? note;
  final int? remindDays;
  final String? remark;
  final int? dueAt;
  final int startAt;
  final int? extendAt;
  final int? issueTypeId;
  final int? handleTypeId;
  final int createdAt;
  final int updatedAt;
  const Reminder({
    required this.id,
    this.seriesId,
    this.previousReminderId,
    required this.timeBasis,
    required this.notifyStrategy,
    required this.status,
    required this.title,
    this.note,
    this.remindDays,
    this.remark,
    this.dueAt,
    required this.startAt,
    this.extendAt,
    this.issueTypeId,
    this.handleTypeId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<int>(seriesId);
    }
    if (!nullToAbsent || previousReminderId != null) {
      map['previous_reminder_id'] = Variable<int>(previousReminderId);
    }
    map['time_basis'] = Variable<int>(timeBasis);
    map['notify_strategy'] = Variable<int>(notifyStrategy);
    map['status'] = Variable<int>(status);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || remindDays != null) {
      map['remind_days'] = Variable<int>(remindDays);
    }
    if (!nullToAbsent || remark != null) {
      map['remark'] = Variable<String>(remark);
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<int>(dueAt);
    }
    map['start_at'] = Variable<int>(startAt);
    if (!nullToAbsent || extendAt != null) {
      map['extend_at'] = Variable<int>(extendAt);
    }
    if (!nullToAbsent || issueTypeId != null) {
      map['issue_type_id'] = Variable<int>(issueTypeId);
    }
    if (!nullToAbsent || handleTypeId != null) {
      map['handle_type_id'] = Variable<int>(handleTypeId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      previousReminderId: previousReminderId == null && nullToAbsent
          ? const Value.absent()
          : Value(previousReminderId),
      timeBasis: Value(timeBasis),
      notifyStrategy: Value(notifyStrategy),
      status: Value(status),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      remindDays: remindDays == null && nullToAbsent
          ? const Value.absent()
          : Value(remindDays),
      remark: remark == null && nullToAbsent
          ? const Value.absent()
          : Value(remark),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      startAt: Value(startAt),
      extendAt: extendAt == null && nullToAbsent
          ? const Value.absent()
          : Value(extendAt),
      issueTypeId: issueTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(issueTypeId),
      handleTypeId: handleTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(handleTypeId),
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
      seriesId: serializer.fromJson<int?>(json['seriesId']),
      previousReminderId: serializer.fromJson<int?>(json['previousReminderId']),
      timeBasis: serializer.fromJson<int>(json['timeBasis']),
      notifyStrategy: serializer.fromJson<int>(json['notifyStrategy']),
      status: serializer.fromJson<int>(json['status']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      remindDays: serializer.fromJson<int?>(json['remindDays']),
      remark: serializer.fromJson<String?>(json['remark']),
      dueAt: serializer.fromJson<int?>(json['dueAt']),
      startAt: serializer.fromJson<int>(json['startAt']),
      extendAt: serializer.fromJson<int?>(json['extendAt']),
      issueTypeId: serializer.fromJson<int?>(json['issueTypeId']),
      handleTypeId: serializer.fromJson<int?>(json['handleTypeId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'seriesId': serializer.toJson<int?>(seriesId),
      'previousReminderId': serializer.toJson<int?>(previousReminderId),
      'timeBasis': serializer.toJson<int>(timeBasis),
      'notifyStrategy': serializer.toJson<int>(notifyStrategy),
      'status': serializer.toJson<int>(status),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String?>(note),
      'remindDays': serializer.toJson<int?>(remindDays),
      'remark': serializer.toJson<String?>(remark),
      'dueAt': serializer.toJson<int?>(dueAt),
      'startAt': serializer.toJson<int>(startAt),
      'extendAt': serializer.toJson<int?>(extendAt),
      'issueTypeId': serializer.toJson<int?>(issueTypeId),
      'handleTypeId': serializer.toJson<int?>(handleTypeId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Reminder copyWith({
    int? id,
    Value<int?> seriesId = const Value.absent(),
    Value<int?> previousReminderId = const Value.absent(),
    int? timeBasis,
    int? notifyStrategy,
    int? status,
    String? title,
    Value<String?> note = const Value.absent(),
    Value<int?> remindDays = const Value.absent(),
    Value<String?> remark = const Value.absent(),
    Value<int?> dueAt = const Value.absent(),
    int? startAt,
    Value<int?> extendAt = const Value.absent(),
    Value<int?> issueTypeId = const Value.absent(),
    Value<int?> handleTypeId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Reminder(
    id: id ?? this.id,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    previousReminderId: previousReminderId.present
        ? previousReminderId.value
        : this.previousReminderId,
    timeBasis: timeBasis ?? this.timeBasis,
    notifyStrategy: notifyStrategy ?? this.notifyStrategy,
    status: status ?? this.status,
    title: title ?? this.title,
    note: note.present ? note.value : this.note,
    remindDays: remindDays.present ? remindDays.value : this.remindDays,
    remark: remark.present ? remark.value : this.remark,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    startAt: startAt ?? this.startAt,
    extendAt: extendAt.present ? extendAt.value : this.extendAt,
    issueTypeId: issueTypeId.present ? issueTypeId.value : this.issueTypeId,
    handleTypeId: handleTypeId.present ? handleTypeId.value : this.handleTypeId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      previousReminderId: data.previousReminderId.present
          ? data.previousReminderId.value
          : this.previousReminderId,
      timeBasis: data.timeBasis.present ? data.timeBasis.value : this.timeBasis,
      notifyStrategy: data.notifyStrategy.present
          ? data.notifyStrategy.value
          : this.notifyStrategy,
      status: data.status.present ? data.status.value : this.status,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      remindDays: data.remindDays.present
          ? data.remindDays.value
          : this.remindDays,
      remark: data.remark.present ? data.remark.value : this.remark,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      extendAt: data.extendAt.present ? data.extendAt.value : this.extendAt,
      issueTypeId: data.issueTypeId.present
          ? data.issueTypeId.value
          : this.issueTypeId,
      handleTypeId: data.handleTypeId.present
          ? data.handleTypeId.value
          : this.handleTypeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('previousReminderId: $previousReminderId, ')
          ..write('timeBasis: $timeBasis, ')
          ..write('notifyStrategy: $notifyStrategy, ')
          ..write('status: $status, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('remindDays: $remindDays, ')
          ..write('remark: $remark, ')
          ..write('dueAt: $dueAt, ')
          ..write('startAt: $startAt, ')
          ..write('extendAt: $extendAt, ')
          ..write('issueTypeId: $issueTypeId, ')
          ..write('handleTypeId: $handleTypeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    seriesId,
    previousReminderId,
    timeBasis,
    notifyStrategy,
    status,
    title,
    note,
    remindDays,
    remark,
    dueAt,
    startAt,
    extendAt,
    issueTypeId,
    handleTypeId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.previousReminderId == this.previousReminderId &&
          other.timeBasis == this.timeBasis &&
          other.notifyStrategy == this.notifyStrategy &&
          other.status == this.status &&
          other.title == this.title &&
          other.note == this.note &&
          other.remindDays == this.remindDays &&
          other.remark == this.remark &&
          other.dueAt == this.dueAt &&
          other.startAt == this.startAt &&
          other.extendAt == this.extendAt &&
          other.issueTypeId == this.issueTypeId &&
          other.handleTypeId == this.handleTypeId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<int> id;
  final Value<int?> seriesId;
  final Value<int?> previousReminderId;
  final Value<int> timeBasis;
  final Value<int> notifyStrategy;
  final Value<int> status;
  final Value<String> title;
  final Value<String?> note;
  final Value<int?> remindDays;
  final Value<String?> remark;
  final Value<int?> dueAt;
  final Value<int> startAt;
  final Value<int?> extendAt;
  final Value<int?> issueTypeId;
  final Value<int?> handleTypeId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.previousReminderId = const Value.absent(),
    this.timeBasis = const Value.absent(),
    this.notifyStrategy = const Value.absent(),
    this.status = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.remindDays = const Value.absent(),
    this.remark = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.startAt = const Value.absent(),
    this.extendAt = const Value.absent(),
    this.issueTypeId = const Value.absent(),
    this.handleTypeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.previousReminderId = const Value.absent(),
    required int timeBasis,
    required int notifyStrategy,
    this.status = const Value.absent(),
    required String title,
    this.note = const Value.absent(),
    this.remindDays = const Value.absent(),
    this.remark = const Value.absent(),
    this.dueAt = const Value.absent(),
    required int startAt,
    this.extendAt = const Value.absent(),
    this.issueTypeId = const Value.absent(),
    this.handleTypeId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : timeBasis = Value(timeBasis),
       notifyStrategy = Value(notifyStrategy),
       title = Value(title),
       startAt = Value(startAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Reminder> custom({
    Expression<int>? id,
    Expression<int>? seriesId,
    Expression<int>? previousReminderId,
    Expression<int>? timeBasis,
    Expression<int>? notifyStrategy,
    Expression<int>? status,
    Expression<String>? title,
    Expression<String>? note,
    Expression<int>? remindDays,
    Expression<String>? remark,
    Expression<int>? dueAt,
    Expression<int>? startAt,
    Expression<int>? extendAt,
    Expression<int>? issueTypeId,
    Expression<int>? handleTypeId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (previousReminderId != null)
        'previous_reminder_id': previousReminderId,
      if (timeBasis != null) 'time_basis': timeBasis,
      if (notifyStrategy != null) 'notify_strategy': notifyStrategy,
      if (status != null) 'status': status,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (remindDays != null) 'remind_days': remindDays,
      if (remark != null) 'remark': remark,
      if (dueAt != null) 'due_at': dueAt,
      if (startAt != null) 'start_at': startAt,
      if (extendAt != null) 'extend_at': extendAt,
      if (issueTypeId != null) 'issue_type_id': issueTypeId,
      if (handleTypeId != null) 'handle_type_id': handleTypeId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<int?>? seriesId,
    Value<int?>? previousReminderId,
    Value<int>? timeBasis,
    Value<int>? notifyStrategy,
    Value<int>? status,
    Value<String>? title,
    Value<String?>? note,
    Value<int?>? remindDays,
    Value<String?>? remark,
    Value<int?>? dueAt,
    Value<int>? startAt,
    Value<int?>? extendAt,
    Value<int?>? issueTypeId,
    Value<int?>? handleTypeId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      previousReminderId: previousReminderId ?? this.previousReminderId,
      timeBasis: timeBasis ?? this.timeBasis,
      notifyStrategy: notifyStrategy ?? this.notifyStrategy,
      status: status ?? this.status,
      title: title ?? this.title,
      note: note ?? this.note,
      remindDays: remindDays ?? this.remindDays,
      remark: remark ?? this.remark,
      dueAt: dueAt ?? this.dueAt,
      startAt: startAt ?? this.startAt,
      extendAt: extendAt ?? this.extendAt,
      issueTypeId: issueTypeId ?? this.issueTypeId,
      handleTypeId: handleTypeId ?? this.handleTypeId,
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
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (previousReminderId.present) {
      map['previous_reminder_id'] = Variable<int>(previousReminderId.value);
    }
    if (timeBasis.present) {
      map['time_basis'] = Variable<int>(timeBasis.value);
    }
    if (notifyStrategy.present) {
      map['notify_strategy'] = Variable<int>(notifyStrategy.value);
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
    if (remindDays.present) {
      map['remind_days'] = Variable<int>(remindDays.value);
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<int>(dueAt.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<int>(startAt.value);
    }
    if (extendAt.present) {
      map['extend_at'] = Variable<int>(extendAt.value);
    }
    if (issueTypeId.present) {
      map['issue_type_id'] = Variable<int>(issueTypeId.value);
    }
    if (handleTypeId.present) {
      map['handle_type_id'] = Variable<int>(handleTypeId.value);
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
          ..write('seriesId: $seriesId, ')
          ..write('previousReminderId: $previousReminderId, ')
          ..write('timeBasis: $timeBasis, ')
          ..write('notifyStrategy: $notifyStrategy, ')
          ..write('status: $status, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('remindDays: $remindDays, ')
          ..write('remark: $remark, ')
          ..write('dueAt: $dueAt, ')
          ..write('startAt: $startAt, ')
          ..write('extendAt: $extendAt, ')
          ..write('issueTypeId: $issueTypeId, ')
          ..write('handleTypeId: $handleTypeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReminderSeriesEntriesTable reminderSeriesEntries =
      $ReminderSeriesEntriesTable(this);
  late final $IssueTypesTable issueTypes = $IssueTypesTable(this);
  late final $HandleTypesTable handleTypes = $HandleTypesTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final ReminderDao reminderDao = ReminderDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    reminderSeriesEntries,
    issueTypes,
    handleTypes,
    reminders,
  ];
}

typedef $$ReminderSeriesEntriesTableCreateCompanionBuilder =
    ReminderSeriesEntriesCompanion Function({
      Value<int> id,
      Value<int> status,
      required String title,
      Value<String?> note,
      required int timeBasis,
      required int notifyStrategy,
      Value<int?> remindDays,
      Value<String?> repeatRule,
      Value<int?> issueTypeId,
      Value<int?> handleTypeId,
      required int createdAt,
      required int updatedAt,
    });
typedef $$ReminderSeriesEntriesTableUpdateCompanionBuilder =
    ReminderSeriesEntriesCompanion Function({
      Value<int> id,
      Value<int> status,
      Value<String> title,
      Value<String?> note,
      Value<int> timeBasis,
      Value<int> notifyStrategy,
      Value<int?> remindDays,
      Value<String?> repeatRule,
      Value<int?> issueTypeId,
      Value<int?> handleTypeId,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

class $$ReminderSeriesEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ReminderSeriesEntriesTable> {
  $$ReminderSeriesEntriesTableFilterComposer({
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

  ColumnFilters<int> get timeBasis => $composableBuilder(
    column: $table.timeBasis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notifyStrategy => $composableBuilder(
    column: $table.notifyStrategy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remindDays => $composableBuilder(
    column: $table.remindDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get issueTypeId => $composableBuilder(
    column: $table.issueTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get handleTypeId => $composableBuilder(
    column: $table.handleTypeId,
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

class $$ReminderSeriesEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReminderSeriesEntriesTable> {
  $$ReminderSeriesEntriesTableOrderingComposer({
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

  ColumnOrderings<int> get timeBasis => $composableBuilder(
    column: $table.timeBasis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notifyStrategy => $composableBuilder(
    column: $table.notifyStrategy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remindDays => $composableBuilder(
    column: $table.remindDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get issueTypeId => $composableBuilder(
    column: $table.issueTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get handleTypeId => $composableBuilder(
    column: $table.handleTypeId,
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

class $$ReminderSeriesEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReminderSeriesEntriesTable> {
  $$ReminderSeriesEntriesTableAnnotationComposer({
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

  GeneratedColumn<int> get timeBasis =>
      $composableBuilder(column: $table.timeBasis, builder: (column) => column);

  GeneratedColumn<int> get notifyStrategy => $composableBuilder(
    column: $table.notifyStrategy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remindDays => $composableBuilder(
    column: $table.remindDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => column,
  );

  GeneratedColumn<int> get issueTypeId => $composableBuilder(
    column: $table.issueTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get handleTypeId => $composableBuilder(
    column: $table.handleTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReminderSeriesEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReminderSeriesEntriesTable,
          ReminderSeriesEntry,
          $$ReminderSeriesEntriesTableFilterComposer,
          $$ReminderSeriesEntriesTableOrderingComposer,
          $$ReminderSeriesEntriesTableAnnotationComposer,
          $$ReminderSeriesEntriesTableCreateCompanionBuilder,
          $$ReminderSeriesEntriesTableUpdateCompanionBuilder,
          (
            ReminderSeriesEntry,
            BaseReferences<
              _$AppDatabase,
              $ReminderSeriesEntriesTable,
              ReminderSeriesEntry
            >,
          ),
          ReminderSeriesEntry,
          PrefetchHooks Function()
        > {
  $$ReminderSeriesEntriesTableTableManager(
    _$AppDatabase db,
    $ReminderSeriesEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderSeriesEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ReminderSeriesEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ReminderSeriesEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> timeBasis = const Value.absent(),
                Value<int> notifyStrategy = const Value.absent(),
                Value<int?> remindDays = const Value.absent(),
                Value<String?> repeatRule = const Value.absent(),
                Value<int?> issueTypeId = const Value.absent(),
                Value<int?> handleTypeId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ReminderSeriesEntriesCompanion(
                id: id,
                status: status,
                title: title,
                note: note,
                timeBasis: timeBasis,
                notifyStrategy: notifyStrategy,
                remindDays: remindDays,
                repeatRule: repeatRule,
                issueTypeId: issueTypeId,
                handleTypeId: handleTypeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> status = const Value.absent(),
                required String title,
                Value<String?> note = const Value.absent(),
                required int timeBasis,
                required int notifyStrategy,
                Value<int?> remindDays = const Value.absent(),
                Value<String?> repeatRule = const Value.absent(),
                Value<int?> issueTypeId = const Value.absent(),
                Value<int?> handleTypeId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ReminderSeriesEntriesCompanion.insert(
                id: id,
                status: status,
                title: title,
                note: note,
                timeBasis: timeBasis,
                notifyStrategy: notifyStrategy,
                remindDays: remindDays,
                repeatRule: repeatRule,
                issueTypeId: issueTypeId,
                handleTypeId: handleTypeId,
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

typedef $$ReminderSeriesEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReminderSeriesEntriesTable,
      ReminderSeriesEntry,
      $$ReminderSeriesEntriesTableFilterComposer,
      $$ReminderSeriesEntriesTableOrderingComposer,
      $$ReminderSeriesEntriesTableAnnotationComposer,
      $$ReminderSeriesEntriesTableCreateCompanionBuilder,
      $$ReminderSeriesEntriesTableUpdateCompanionBuilder,
      (
        ReminderSeriesEntry,
        BaseReferences<
          _$AppDatabase,
          $ReminderSeriesEntriesTable,
          ReminderSeriesEntry
        >,
      ),
      ReminderSeriesEntry,
      PrefetchHooks Function()
    >;
typedef $$IssueTypesTableCreateCompanionBuilder =
    IssueTypesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      required int createdAt,
      required int updatedAt,
    });
typedef $$IssueTypesTableUpdateCompanionBuilder =
    IssueTypesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

class $$IssueTypesTableFilterComposer
    extends Composer<_$AppDatabase, $IssueTypesTable> {
  $$IssueTypesTableFilterComposer({
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

class $$IssueTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $IssueTypesTable> {
  $$IssueTypesTableOrderingComposer({
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

class $$IssueTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IssueTypesTable> {
  $$IssueTypesTableAnnotationComposer({
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

class $$IssueTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IssueTypesTable,
          IssueType,
          $$IssueTypesTableFilterComposer,
          $$IssueTypesTableOrderingComposer,
          $$IssueTypesTableAnnotationComposer,
          $$IssueTypesTableCreateCompanionBuilder,
          $$IssueTypesTableUpdateCompanionBuilder,
          (
            IssueType,
            BaseReferences<_$AppDatabase, $IssueTypesTable, IssueType>,
          ),
          IssueType,
          PrefetchHooks Function()
        > {
  $$IssueTypesTableTableManager(_$AppDatabase db, $IssueTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IssueTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IssueTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IssueTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => IssueTypesCompanion(
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
              }) => IssueTypesCompanion.insert(
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

typedef $$IssueTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IssueTypesTable,
      IssueType,
      $$IssueTypesTableFilterComposer,
      $$IssueTypesTableOrderingComposer,
      $$IssueTypesTableAnnotationComposer,
      $$IssueTypesTableCreateCompanionBuilder,
      $$IssueTypesTableUpdateCompanionBuilder,
      (IssueType, BaseReferences<_$AppDatabase, $IssueTypesTable, IssueType>),
      IssueType,
      PrefetchHooks Function()
    >;
typedef $$HandleTypesTableCreateCompanionBuilder =
    HandleTypesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      required int createdAt,
      required int updatedAt,
    });
typedef $$HandleTypesTableUpdateCompanionBuilder =
    HandleTypesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

class $$HandleTypesTableFilterComposer
    extends Composer<_$AppDatabase, $HandleTypesTable> {
  $$HandleTypesTableFilterComposer({
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

class $$HandleTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $HandleTypesTable> {
  $$HandleTypesTableOrderingComposer({
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

class $$HandleTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HandleTypesTable> {
  $$HandleTypesTableAnnotationComposer({
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

class $$HandleTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HandleTypesTable,
          HandleType,
          $$HandleTypesTableFilterComposer,
          $$HandleTypesTableOrderingComposer,
          $$HandleTypesTableAnnotationComposer,
          $$HandleTypesTableCreateCompanionBuilder,
          $$HandleTypesTableUpdateCompanionBuilder,
          (
            HandleType,
            BaseReferences<_$AppDatabase, $HandleTypesTable, HandleType>,
          ),
          HandleType,
          PrefetchHooks Function()
        > {
  $$HandleTypesTableTableManager(_$AppDatabase db, $HandleTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HandleTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HandleTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HandleTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => HandleTypesCompanion(
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
              }) => HandleTypesCompanion.insert(
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

typedef $$HandleTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HandleTypesTable,
      HandleType,
      $$HandleTypesTableFilterComposer,
      $$HandleTypesTableOrderingComposer,
      $$HandleTypesTableAnnotationComposer,
      $$HandleTypesTableCreateCompanionBuilder,
      $$HandleTypesTableUpdateCompanionBuilder,
      (
        HandleType,
        BaseReferences<_$AppDatabase, $HandleTypesTable, HandleType>,
      ),
      HandleType,
      PrefetchHooks Function()
    >;
typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      Value<int?> seriesId,
      Value<int?> previousReminderId,
      required int timeBasis,
      required int notifyStrategy,
      Value<int> status,
      required String title,
      Value<String?> note,
      Value<int?> remindDays,
      Value<String?> remark,
      Value<int?> dueAt,
      required int startAt,
      Value<int?> extendAt,
      Value<int?> issueTypeId,
      Value<int?> handleTypeId,
      required int createdAt,
      required int updatedAt,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      Value<int?> seriesId,
      Value<int?> previousReminderId,
      Value<int> timeBasis,
      Value<int> notifyStrategy,
      Value<int> status,
      Value<String> title,
      Value<String?> note,
      Value<int?> remindDays,
      Value<String?> remark,
      Value<int?> dueAt,
      Value<int> startAt,
      Value<int?> extendAt,
      Value<int?> issueTypeId,
      Value<int?> handleTypeId,
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

  ColumnFilters<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get previousReminderId => $composableBuilder(
    column: $table.previousReminderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeBasis => $composableBuilder(
    column: $table.timeBasis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notifyStrategy => $composableBuilder(
    column: $table.notifyStrategy,
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

  ColumnFilters<int> get remindDays => $composableBuilder(
    column: $table.remindDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remark => $composableBuilder(
    column: $table.remark,
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

  ColumnFilters<int> get extendAt => $composableBuilder(
    column: $table.extendAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get issueTypeId => $composableBuilder(
    column: $table.issueTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get handleTypeId => $composableBuilder(
    column: $table.handleTypeId,
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

  ColumnOrderings<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get previousReminderId => $composableBuilder(
    column: $table.previousReminderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeBasis => $composableBuilder(
    column: $table.timeBasis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notifyStrategy => $composableBuilder(
    column: $table.notifyStrategy,
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

  ColumnOrderings<int> get remindDays => $composableBuilder(
    column: $table.remindDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remark => $composableBuilder(
    column: $table.remark,
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

  ColumnOrderings<int> get extendAt => $composableBuilder(
    column: $table.extendAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get issueTypeId => $composableBuilder(
    column: $table.issueTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get handleTypeId => $composableBuilder(
    column: $table.handleTypeId,
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

  GeneratedColumn<int> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<int> get previousReminderId => $composableBuilder(
    column: $table.previousReminderId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeBasis =>
      $composableBuilder(column: $table.timeBasis, builder: (column) => column);

  GeneratedColumn<int> get notifyStrategy => $composableBuilder(
    column: $table.notifyStrategy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get remindDays => $composableBuilder(
    column: $table.remindDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remark =>
      $composableBuilder(column: $table.remark, builder: (column) => column);

  GeneratedColumn<int> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<int> get extendAt =>
      $composableBuilder(column: $table.extendAt, builder: (column) => column);

  GeneratedColumn<int> get issueTypeId => $composableBuilder(
    column: $table.issueTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get handleTypeId => $composableBuilder(
    column: $table.handleTypeId,
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
                Value<int?> seriesId = const Value.absent(),
                Value<int?> previousReminderId = const Value.absent(),
                Value<int> timeBasis = const Value.absent(),
                Value<int> notifyStrategy = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> remindDays = const Value.absent(),
                Value<String?> remark = const Value.absent(),
                Value<int?> dueAt = const Value.absent(),
                Value<int> startAt = const Value.absent(),
                Value<int?> extendAt = const Value.absent(),
                Value<int?> issueTypeId = const Value.absent(),
                Value<int?> handleTypeId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                seriesId: seriesId,
                previousReminderId: previousReminderId,
                timeBasis: timeBasis,
                notifyStrategy: notifyStrategy,
                status: status,
                title: title,
                note: note,
                remindDays: remindDays,
                remark: remark,
                dueAt: dueAt,
                startAt: startAt,
                extendAt: extendAt,
                issueTypeId: issueTypeId,
                handleTypeId: handleTypeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> seriesId = const Value.absent(),
                Value<int?> previousReminderId = const Value.absent(),
                required int timeBasis,
                required int notifyStrategy,
                Value<int> status = const Value.absent(),
                required String title,
                Value<String?> note = const Value.absent(),
                Value<int?> remindDays = const Value.absent(),
                Value<String?> remark = const Value.absent(),
                Value<int?> dueAt = const Value.absent(),
                required int startAt,
                Value<int?> extendAt = const Value.absent(),
                Value<int?> issueTypeId = const Value.absent(),
                Value<int?> handleTypeId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => RemindersCompanion.insert(
                id: id,
                seriesId: seriesId,
                previousReminderId: previousReminderId,
                timeBasis: timeBasis,
                notifyStrategy: notifyStrategy,
                status: status,
                title: title,
                note: note,
                remindDays: remindDays,
                remark: remark,
                dueAt: dueAt,
                startAt: startAt,
                extendAt: extendAt,
                issueTypeId: issueTypeId,
                handleTypeId: handleTypeId,
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
  $$ReminderSeriesEntriesTableTableManager get reminderSeriesEntries =>
      $$ReminderSeriesEntriesTableTableManager(_db, _db.reminderSeriesEntries);
  $$IssueTypesTableTableManager get issueTypes =>
      $$IssueTypesTableTableManager(_db, _db.issueTypes);
  $$HandleTypesTableTableManager get handleTypes =>
      $$HandleTypesTableTableManager(_db, _db.handleTypes);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
}
