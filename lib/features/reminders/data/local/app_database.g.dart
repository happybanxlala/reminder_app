// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
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
  static const VerificationMeta _startIdMeta = const VerificationMeta(
    'startId',
  );
  @override
  late final GeneratedColumn<int> startId = GeneratedColumn<int>(
    'start_id',
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
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<int> isDone = GeneratedColumn<int>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _isCanceledMeta = const VerificationMeta(
    'isCanceled',
  );
  @override
  late final GeneratedColumn<bool> isCanceled = GeneratedColumn<bool>(
    'is_canceled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_canceled" IN (0, 1))',
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
    startId,
    title,
    note,
    remindDays,
    dueAt,
    repeatRule,
    isDone,
    extendAt,
    isCanceled,
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
    if (data.containsKey('start_id')) {
      context.handle(
        _startIdMeta,
        startId.isAcceptableOrUnknown(data['start_id']!, _startIdMeta),
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
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(
        _repeatRuleMeta,
        repeatRule.isAcceptableOrUnknown(data['repeat_rule']!, _repeatRuleMeta),
      );
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    if (data.containsKey('extend_at')) {
      context.handle(
        _extendAtMeta,
        extendAt.isAcceptableOrUnknown(data['extend_at']!, _extendAtMeta),
      );
    }
    if (data.containsKey('is_canceled')) {
      context.handle(
        _isCanceledMeta,
        isCanceled.isAcceptableOrUnknown(data['is_canceled']!, _isCanceledMeta),
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
      startId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_id'],
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
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_at'],
      ),
      repeatRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_rule'],
      ),
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_done'],
      )!,
      extendAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}extend_at'],
      ),
      isCanceled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_canceled'],
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
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final int id;
  final int startId;
  final String title;
  final String? note;
  final int remindDays;

  /// Epoch milliseconds, nullable when no due date is set.
  final int? dueAt;

  /// Null means no recurrence, otherwise D25 / W3 / N1 / Y1.
  final String? repeatRule;

  /// 0: pending, 1: done, 2: skipped.
  final int isDone;
  final int? extendAt;
  final bool isCanceled;
  final int createdAt;
  final int updatedAt;
  const Reminder({
    required this.id,
    required this.startId,
    required this.title,
    this.note,
    required this.remindDays,
    this.dueAt,
    this.repeatRule,
    required this.isDone,
    this.extendAt,
    required this.isCanceled,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_id'] = Variable<int>(startId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['remind_days'] = Variable<int>(remindDays);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<int>(dueAt);
    }
    if (!nullToAbsent || repeatRule != null) {
      map['repeat_rule'] = Variable<String>(repeatRule);
    }
    map['is_done'] = Variable<int>(isDone);
    if (!nullToAbsent || extendAt != null) {
      map['extend_at'] = Variable<int>(extendAt);
    }
    map['is_canceled'] = Variable<bool>(isCanceled);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      startId: Value(startId),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      remindDays: Value(remindDays),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      repeatRule: repeatRule == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatRule),
      isDone: Value(isDone),
      extendAt: extendAt == null && nullToAbsent
          ? const Value.absent()
          : Value(extendAt),
      isCanceled: Value(isCanceled),
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
      startId: serializer.fromJson<int>(json['startId']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      remindDays: serializer.fromJson<int>(json['remindDays']),
      dueAt: serializer.fromJson<int?>(json['dueAt']),
      repeatRule: serializer.fromJson<String?>(json['repeatRule']),
      isDone: serializer.fromJson<int>(json['isDone']),
      extendAt: serializer.fromJson<int?>(json['extendAt']),
      isCanceled: serializer.fromJson<bool>(json['isCanceled']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startId': serializer.toJson<int>(startId),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String?>(note),
      'remindDays': serializer.toJson<int>(remindDays),
      'dueAt': serializer.toJson<int?>(dueAt),
      'repeatRule': serializer.toJson<String?>(repeatRule),
      'isDone': serializer.toJson<int>(isDone),
      'extendAt': serializer.toJson<int?>(extendAt),
      'isCanceled': serializer.toJson<bool>(isCanceled),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Reminder copyWith({
    int? id,
    int? startId,
    String? title,
    Value<String?> note = const Value.absent(),
    int? remindDays,
    Value<int?> dueAt = const Value.absent(),
    Value<String?> repeatRule = const Value.absent(),
    int? isDone,
    Value<int?> extendAt = const Value.absent(),
    bool? isCanceled,
    int? createdAt,
    int? updatedAt,
  }) => Reminder(
    id: id ?? this.id,
    startId: startId ?? this.startId,
    title: title ?? this.title,
    note: note.present ? note.value : this.note,
    remindDays: remindDays ?? this.remindDays,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    repeatRule: repeatRule.present ? repeatRule.value : this.repeatRule,
    isDone: isDone ?? this.isDone,
    extendAt: extendAt.present ? extendAt.value : this.extendAt,
    isCanceled: isCanceled ?? this.isCanceled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      startId: data.startId.present ? data.startId.value : this.startId,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      remindDays: data.remindDays.present
          ? data.remindDays.value
          : this.remindDays,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      repeatRule: data.repeatRule.present
          ? data.repeatRule.value
          : this.repeatRule,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      extendAt: data.extendAt.present ? data.extendAt.value : this.extendAt,
      isCanceled: data.isCanceled.present
          ? data.isCanceled.value
          : this.isCanceled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('startId: $startId, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('remindDays: $remindDays, ')
          ..write('dueAt: $dueAt, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('isDone: $isDone, ')
          ..write('extendAt: $extendAt, ')
          ..write('isCanceled: $isCanceled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startId,
    title,
    note,
    remindDays,
    dueAt,
    repeatRule,
    isDone,
    extendAt,
    isCanceled,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.startId == this.startId &&
          other.title == this.title &&
          other.note == this.note &&
          other.remindDays == this.remindDays &&
          other.dueAt == this.dueAt &&
          other.repeatRule == this.repeatRule &&
          other.isDone == this.isDone &&
          other.extendAt == this.extendAt &&
          other.isCanceled == this.isCanceled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<int> id;
  final Value<int> startId;
  final Value<String> title;
  final Value<String?> note;
  final Value<int> remindDays;
  final Value<int?> dueAt;
  final Value<String?> repeatRule;
  final Value<int> isDone;
  final Value<int?> extendAt;
  final Value<bool> isCanceled;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.startId = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.remindDays = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.isDone = const Value.absent(),
    this.extendAt = const Value.absent(),
    this.isCanceled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    this.startId = const Value.absent(),
    required String title,
    this.note = const Value.absent(),
    this.remindDays = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.isDone = const Value.absent(),
    this.extendAt = const Value.absent(),
    this.isCanceled = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Reminder> custom({
    Expression<int>? id,
    Expression<int>? startId,
    Expression<String>? title,
    Expression<String>? note,
    Expression<int>? remindDays,
    Expression<int>? dueAt,
    Expression<String>? repeatRule,
    Expression<int>? isDone,
    Expression<int>? extendAt,
    Expression<bool>? isCanceled,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startId != null) 'start_id': startId,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (remindDays != null) 'remind_days': remindDays,
      if (dueAt != null) 'due_at': dueAt,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (isDone != null) 'is_done': isDone,
      if (extendAt != null) 'extend_at': extendAt,
      if (isCanceled != null) 'is_canceled': isCanceled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<int>? startId,
    Value<String>? title,
    Value<String?>? note,
    Value<int>? remindDays,
    Value<int?>? dueAt,
    Value<String?>? repeatRule,
    Value<int>? isDone,
    Value<int?>? extendAt,
    Value<bool>? isCanceled,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      startId: startId ?? this.startId,
      title: title ?? this.title,
      note: note ?? this.note,
      remindDays: remindDays ?? this.remindDays,
      dueAt: dueAt ?? this.dueAt,
      repeatRule: repeatRule ?? this.repeatRule,
      isDone: isDone ?? this.isDone,
      extendAt: extendAt ?? this.extendAt,
      isCanceled: isCanceled ?? this.isCanceled,
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
    if (startId.present) {
      map['start_id'] = Variable<int>(startId.value);
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
    if (dueAt.present) {
      map['due_at'] = Variable<int>(dueAt.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<int>(isDone.value);
    }
    if (extendAt.present) {
      map['extend_at'] = Variable<int>(extendAt.value);
    }
    if (isCanceled.present) {
      map['is_canceled'] = Variable<bool>(isCanceled.value);
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
          ..write('startId: $startId, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('remindDays: $remindDays, ')
          ..write('dueAt: $dueAt, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('isDone: $isDone, ')
          ..write('extendAt: $extendAt, ')
          ..write('isCanceled: $isCanceled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final ReminderDao reminderDao = ReminderDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [reminders];
}

typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      Value<int> startId,
      required String title,
      Value<String?> note,
      Value<int> remindDays,
      Value<int?> dueAt,
      Value<String?> repeatRule,
      Value<int> isDone,
      Value<int?> extendAt,
      Value<bool> isCanceled,
      required int createdAt,
      required int updatedAt,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      Value<int> startId,
      Value<String> title,
      Value<String?> note,
      Value<int> remindDays,
      Value<int?> dueAt,
      Value<String?> repeatRule,
      Value<int> isDone,
      Value<int?> extendAt,
      Value<bool> isCanceled,
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

  ColumnFilters<int> get startId => $composableBuilder(
    column: $table.startId,
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

  ColumnFilters<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get extendAt => $composableBuilder(
    column: $table.extendAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCanceled => $composableBuilder(
    column: $table.isCanceled,
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

  ColumnOrderings<int> get startId => $composableBuilder(
    column: $table.startId,
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

  ColumnOrderings<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get extendAt => $composableBuilder(
    column: $table.extendAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCanceled => $composableBuilder(
    column: $table.isCanceled,
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

  GeneratedColumn<int> get startId =>
      $composableBuilder(column: $table.startId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get remindDays => $composableBuilder(
    column: $table.remindDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<int> get extendAt =>
      $composableBuilder(column: $table.extendAt, builder: (column) => column);

  GeneratedColumn<bool> get isCanceled => $composableBuilder(
    column: $table.isCanceled,
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
                Value<int> startId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> remindDays = const Value.absent(),
                Value<int?> dueAt = const Value.absent(),
                Value<String?> repeatRule = const Value.absent(),
                Value<int> isDone = const Value.absent(),
                Value<int?> extendAt = const Value.absent(),
                Value<bool> isCanceled = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                startId: startId,
                title: title,
                note: note,
                remindDays: remindDays,
                dueAt: dueAt,
                repeatRule: repeatRule,
                isDone: isDone,
                extendAt: extendAt,
                isCanceled: isCanceled,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> startId = const Value.absent(),
                required String title,
                Value<String?> note = const Value.absent(),
                Value<int> remindDays = const Value.absent(),
                Value<int?> dueAt = const Value.absent(),
                Value<String?> repeatRule = const Value.absent(),
                Value<int> isDone = const Value.absent(),
                Value<int?> extendAt = const Value.absent(),
                Value<bool> isCanceled = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => RemindersCompanion.insert(
                id: id,
                startId: startId,
                title: title,
                note: note,
                remindDays: remindDays,
                dueAt: dueAt,
                repeatRule: repeatRule,
                isDone: isDone,
                extendAt: extendAt,
                isCanceled: isCanceled,
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
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
}
