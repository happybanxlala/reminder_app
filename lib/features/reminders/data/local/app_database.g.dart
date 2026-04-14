// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TaskTemplatesTable extends TaskTemplates
    with TableInfo<$TaskTemplatesTable, TaskTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskTemplatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
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
  static const VerificationMeta _firstDueDateMeta = const VerificationMeta(
    'firstDueDate',
  );
  @override
  late final GeneratedColumn<int> firstDueDate = GeneratedColumn<int>(
    'first_due_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _reminderRuleMeta = const VerificationMeta(
    'reminderRule',
  );
  @override
  late final GeneratedColumn<String> reminderRule = GeneratedColumn<String>(
    'reminder_rule',
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
    categoryId,
    note,
    kind,
    status,
    firstDueDate,
    repeatRule,
    reminderRule,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskTemplateRow> instance, {
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
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('first_due_date')) {
      context.handle(
        _firstDueDateMeta,
        firstDueDate.isAcceptableOrUnknown(
          data['first_due_date']!,
          _firstDueDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstDueDateMeta);
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(
        _repeatRuleMeta,
        repeatRule.isAcceptableOrUnknown(data['repeat_rule']!, _repeatRuleMeta),
      );
    }
    if (data.containsKey('reminder_rule')) {
      context.handle(
        _reminderRuleMeta,
        reminderRule.isAcceptableOrUnknown(
          data['reminder_rule']!,
          _reminderRuleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reminderRuleMeta);
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
  TaskTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      firstDueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_due_date'],
      )!,
      repeatRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_rule'],
      ),
      reminderRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_rule'],
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
  $TaskTemplatesTable createAlias(String alias) {
    return $TaskTemplatesTable(attachedDatabase, alias);
  }
}

class TaskTemplateRow extends DataClass implements Insertable<TaskTemplateRow> {
  final int id;
  final String title;
  final int? categoryId;
  final String? note;
  final String kind;
  final String status;
  final int firstDueDate;
  final String? repeatRule;
  final String reminderRule;
  final int createdAt;
  final int updatedAt;
  const TaskTemplateRow({
    required this.id,
    required this.title,
    this.categoryId,
    this.note,
    required this.kind,
    required this.status,
    required this.firstDueDate,
    this.repeatRule,
    required this.reminderRule,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['kind'] = Variable<String>(kind);
    map['status'] = Variable<String>(status);
    map['first_due_date'] = Variable<int>(firstDueDate);
    if (!nullToAbsent || repeatRule != null) {
      map['repeat_rule'] = Variable<String>(repeatRule);
    }
    map['reminder_rule'] = Variable<String>(reminderRule);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TaskTemplatesCompanion toCompanion(bool nullToAbsent) {
    return TaskTemplatesCompanion(
      id: Value(id),
      title: Value(title),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      kind: Value(kind),
      status: Value(status),
      firstDueDate: Value(firstDueDate),
      repeatRule: repeatRule == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatRule),
      reminderRule: Value(reminderRule),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TaskTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTemplateRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      note: serializer.fromJson<String?>(json['note']),
      kind: serializer.fromJson<String>(json['kind']),
      status: serializer.fromJson<String>(json['status']),
      firstDueDate: serializer.fromJson<int>(json['firstDueDate']),
      repeatRule: serializer.fromJson<String?>(json['repeatRule']),
      reminderRule: serializer.fromJson<String>(json['reminderRule']),
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
      'categoryId': serializer.toJson<int?>(categoryId),
      'note': serializer.toJson<String?>(note),
      'kind': serializer.toJson<String>(kind),
      'status': serializer.toJson<String>(status),
      'firstDueDate': serializer.toJson<int>(firstDueDate),
      'repeatRule': serializer.toJson<String?>(repeatRule),
      'reminderRule': serializer.toJson<String>(reminderRule),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  TaskTemplateRow copyWith({
    int? id,
    String? title,
    Value<int?> categoryId = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? kind,
    String? status,
    int? firstDueDate,
    Value<String?> repeatRule = const Value.absent(),
    String? reminderRule,
    int? createdAt,
    int? updatedAt,
  }) => TaskTemplateRow(
    id: id ?? this.id,
    title: title ?? this.title,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    note: note.present ? note.value : this.note,
    kind: kind ?? this.kind,
    status: status ?? this.status,
    firstDueDate: firstDueDate ?? this.firstDueDate,
    repeatRule: repeatRule.present ? repeatRule.value : this.repeatRule,
    reminderRule: reminderRule ?? this.reminderRule,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TaskTemplateRow copyWithCompanion(TaskTemplatesCompanion data) {
    return TaskTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      note: data.note.present ? data.note.value : this.note,
      kind: data.kind.present ? data.kind.value : this.kind,
      status: data.status.present ? data.status.value : this.status,
      firstDueDate: data.firstDueDate.present
          ? data.firstDueDate.value
          : this.firstDueDate,
      repeatRule: data.repeatRule.present
          ? data.repeatRule.value
          : this.repeatRule,
      reminderRule: data.reminderRule.present
          ? data.reminderRule.value
          : this.reminderRule,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTemplateRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('categoryId: $categoryId, ')
          ..write('note: $note, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('firstDueDate: $firstDueDate, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('reminderRule: $reminderRule, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    categoryId,
    note,
    kind,
    status,
    firstDueDate,
    repeatRule,
    reminderRule,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTemplateRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.categoryId == this.categoryId &&
          other.note == this.note &&
          other.kind == this.kind &&
          other.status == this.status &&
          other.firstDueDate == this.firstDueDate &&
          other.repeatRule == this.repeatRule &&
          other.reminderRule == this.reminderRule &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TaskTemplatesCompanion extends UpdateCompanion<TaskTemplateRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<int?> categoryId;
  final Value<String?> note;
  final Value<String> kind;
  final Value<String> status;
  final Value<int> firstDueDate;
  final Value<String?> repeatRule;
  final Value<String> reminderRule;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const TaskTemplatesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.note = const Value.absent(),
    this.kind = const Value.absent(),
    this.status = const Value.absent(),
    this.firstDueDate = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.reminderRule = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TaskTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.categoryId = const Value.absent(),
    this.note = const Value.absent(),
    required String kind,
    required String status,
    required int firstDueDate,
    this.repeatRule = const Value.absent(),
    required String reminderRule,
    required int createdAt,
    required int updatedAt,
  }) : title = Value(title),
       kind = Value(kind),
       status = Value(status),
       firstDueDate = Value(firstDueDate),
       reminderRule = Value(reminderRule),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TaskTemplateRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? categoryId,
    Expression<String>? note,
    Expression<String>? kind,
    Expression<String>? status,
    Expression<int>? firstDueDate,
    Expression<String>? repeatRule,
    Expression<String>? reminderRule,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (categoryId != null) 'category_id': categoryId,
      if (note != null) 'note': note,
      if (kind != null) 'kind': kind,
      if (status != null) 'status': status,
      if (firstDueDate != null) 'first_due_date': firstDueDate,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (reminderRule != null) 'reminder_rule': reminderRule,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TaskTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<int?>? categoryId,
    Value<String?>? note,
    Value<String>? kind,
    Value<String>? status,
    Value<int>? firstDueDate,
    Value<String?>? repeatRule,
    Value<String>? reminderRule,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return TaskTemplatesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      firstDueDate: firstDueDate ?? this.firstDueDate,
      repeatRule: repeatRule ?? this.repeatRule,
      reminderRule: reminderRule ?? this.reminderRule,
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
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (firstDueDate.present) {
      map['first_due_date'] = Variable<int>(firstDueDate.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (reminderRule.present) {
      map['reminder_rule'] = Variable<String>(reminderRule.value);
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
    return (StringBuffer('TaskTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('categoryId: $categoryId, ')
          ..write('note: $note, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('firstDueDate: $firstDueDate, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('reminderRule: $reminderRule, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
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
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleSnapshotMeta = const VerificationMeta(
    'titleSnapshot',
  );
  @override
  late final GeneratedColumn<String> titleSnapshot = GeneratedColumn<String>(
    'title_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteSnapshotMeta = const VerificationMeta(
    'noteSnapshot',
  );
  @override
  late final GeneratedColumn<String> noteSnapshot = GeneratedColumn<String>(
    'note_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<int> dueDate = GeneratedColumn<int>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _reminderRuleMeta = const VerificationMeta(
    'reminderRule',
  );
  @override
  late final GeneratedColumn<String> reminderRule = GeneratedColumn<String>(
    'reminder_rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deferredDueDateMeta = const VerificationMeta(
    'deferredDueDate',
  );
  @override
  late final GeneratedColumn<int> deferredDueDate = GeneratedColumn<int>(
    'deferred_due_date',
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
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<int> resolvedAt = GeneratedColumn<int>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    kind,
    titleSnapshot,
    noteSnapshot,
    categoryId,
    dueDate,
    repeatRule,
    reminderRule,
    deferredDueDate,
    status,
    createdAt,
    updatedAt,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRow> instance, {
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
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('title_snapshot')) {
      context.handle(
        _titleSnapshotMeta,
        titleSnapshot.isAcceptableOrUnknown(
          data['title_snapshot']!,
          _titleSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_titleSnapshotMeta);
    }
    if (data.containsKey('note_snapshot')) {
      context.handle(
        _noteSnapshotMeta,
        noteSnapshot.isAcceptableOrUnknown(
          data['note_snapshot']!,
          _noteSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(
        _repeatRuleMeta,
        repeatRule.isAcceptableOrUnknown(data['repeat_rule']!, _repeatRuleMeta),
      );
    }
    if (data.containsKey('reminder_rule')) {
      context.handle(
        _reminderRuleMeta,
        reminderRule.isAcceptableOrUnknown(
          data['reminder_rule']!,
          _reminderRuleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reminderRuleMeta);
    }
    if (data.containsKey('deferred_due_date')) {
      context.handle(
        _deferredDueDateMeta,
        deferredDueDate.isAcceptableOrUnknown(
          data['deferred_due_date']!,
          _deferredDueDateMeta,
        ),
      );
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
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      titleSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_snapshot'],
      )!,
      noteSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_snapshot'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_date'],
      )!,
      repeatRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_rule'],
      ),
      reminderRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_rule'],
      )!,
      deferredDueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deferred_due_date'],
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
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resolved_at'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  final int id;
  final int? templateId;
  final String kind;
  final String titleSnapshot;
  final String? noteSnapshot;
  final int? categoryId;
  final int dueDate;
  final String? repeatRule;
  final String reminderRule;
  final int? deferredDueDate;
  final String status;
  final int createdAt;
  final int updatedAt;
  final int? resolvedAt;
  const TaskRow({
    required this.id,
    this.templateId,
    required this.kind,
    required this.titleSnapshot,
    this.noteSnapshot,
    this.categoryId,
    required this.dueDate,
    this.repeatRule,
    required this.reminderRule,
    this.deferredDueDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<int>(templateId);
    }
    map['kind'] = Variable<String>(kind);
    map['title_snapshot'] = Variable<String>(titleSnapshot);
    if (!nullToAbsent || noteSnapshot != null) {
      map['note_snapshot'] = Variable<String>(noteSnapshot);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['due_date'] = Variable<int>(dueDate);
    if (!nullToAbsent || repeatRule != null) {
      map['repeat_rule'] = Variable<String>(repeatRule);
    }
    map['reminder_rule'] = Variable<String>(reminderRule);
    if (!nullToAbsent || deferredDueDate != null) {
      map['deferred_due_date'] = Variable<int>(deferredDueDate);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<int>(resolvedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      kind: Value(kind),
      titleSnapshot: Value(titleSnapshot),
      noteSnapshot: noteSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(noteSnapshot),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      dueDate: Value(dueDate),
      repeatRule: repeatRule == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatRule),
      reminderRule: Value(reminderRule),
      deferredDueDate: deferredDueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(deferredDueDate),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory TaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<int>(json['id']),
      templateId: serializer.fromJson<int?>(json['templateId']),
      kind: serializer.fromJson<String>(json['kind']),
      titleSnapshot: serializer.fromJson<String>(json['titleSnapshot']),
      noteSnapshot: serializer.fromJson<String?>(json['noteSnapshot']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      dueDate: serializer.fromJson<int>(json['dueDate']),
      repeatRule: serializer.fromJson<String?>(json['repeatRule']),
      reminderRule: serializer.fromJson<String>(json['reminderRule']),
      deferredDueDate: serializer.fromJson<int?>(json['deferredDueDate']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      resolvedAt: serializer.fromJson<int?>(json['resolvedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateId': serializer.toJson<int?>(templateId),
      'kind': serializer.toJson<String>(kind),
      'titleSnapshot': serializer.toJson<String>(titleSnapshot),
      'noteSnapshot': serializer.toJson<String?>(noteSnapshot),
      'categoryId': serializer.toJson<int?>(categoryId),
      'dueDate': serializer.toJson<int>(dueDate),
      'repeatRule': serializer.toJson<String?>(repeatRule),
      'reminderRule': serializer.toJson<String>(reminderRule),
      'deferredDueDate': serializer.toJson<int?>(deferredDueDate),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'resolvedAt': serializer.toJson<int?>(resolvedAt),
    };
  }

  TaskRow copyWith({
    int? id,
    Value<int?> templateId = const Value.absent(),
    String? kind,
    String? titleSnapshot,
    Value<String?> noteSnapshot = const Value.absent(),
    Value<int?> categoryId = const Value.absent(),
    int? dueDate,
    Value<String?> repeatRule = const Value.absent(),
    String? reminderRule,
    Value<int?> deferredDueDate = const Value.absent(),
    String? status,
    int? createdAt,
    int? updatedAt,
    Value<int?> resolvedAt = const Value.absent(),
  }) => TaskRow(
    id: id ?? this.id,
    templateId: templateId.present ? templateId.value : this.templateId,
    kind: kind ?? this.kind,
    titleSnapshot: titleSnapshot ?? this.titleSnapshot,
    noteSnapshot: noteSnapshot.present ? noteSnapshot.value : this.noteSnapshot,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    dueDate: dueDate ?? this.dueDate,
    repeatRule: repeatRule.present ? repeatRule.value : this.repeatRule,
    reminderRule: reminderRule ?? this.reminderRule,
    deferredDueDate: deferredDueDate.present
        ? deferredDueDate.value
        : this.deferredDueDate,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
  );
  TaskRow copyWithCompanion(TasksCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      kind: data.kind.present ? data.kind.value : this.kind,
      titleSnapshot: data.titleSnapshot.present
          ? data.titleSnapshot.value
          : this.titleSnapshot,
      noteSnapshot: data.noteSnapshot.present
          ? data.noteSnapshot.value
          : this.noteSnapshot,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      repeatRule: data.repeatRule.present
          ? data.repeatRule.value
          : this.repeatRule,
      reminderRule: data.reminderRule.present
          ? data.reminderRule.value
          : this.reminderRule,
      deferredDueDate: data.deferredDueDate.present
          ? data.deferredDueDate.value
          : this.deferredDueDate,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('kind: $kind, ')
          ..write('titleSnapshot: $titleSnapshot, ')
          ..write('noteSnapshot: $noteSnapshot, ')
          ..write('categoryId: $categoryId, ')
          ..write('dueDate: $dueDate, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('reminderRule: $reminderRule, ')
          ..write('deferredDueDate: $deferredDueDate, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    kind,
    titleSnapshot,
    noteSnapshot,
    categoryId,
    dueDate,
    repeatRule,
    reminderRule,
    deferredDueDate,
    status,
    createdAt,
    updatedAt,
    resolvedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.kind == this.kind &&
          other.titleSnapshot == this.titleSnapshot &&
          other.noteSnapshot == this.noteSnapshot &&
          other.categoryId == this.categoryId &&
          other.dueDate == this.dueDate &&
          other.repeatRule == this.repeatRule &&
          other.reminderRule == this.reminderRule &&
          other.deferredDueDate == this.deferredDueDate &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.resolvedAt == this.resolvedAt);
}

class TasksCompanion extends UpdateCompanion<TaskRow> {
  final Value<int> id;
  final Value<int?> templateId;
  final Value<String> kind;
  final Value<String> titleSnapshot;
  final Value<String?> noteSnapshot;
  final Value<int?> categoryId;
  final Value<int> dueDate;
  final Value<String?> repeatRule;
  final Value<String> reminderRule;
  final Value<int?> deferredDueDate;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> resolvedAt;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.kind = const Value.absent(),
    this.titleSnapshot = const Value.absent(),
    this.noteSnapshot = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.reminderRule = const Value.absent(),
    this.deferredDueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    required String kind,
    required String titleSnapshot,
    this.noteSnapshot = const Value.absent(),
    this.categoryId = const Value.absent(),
    required int dueDate,
    this.repeatRule = const Value.absent(),
    required String reminderRule,
    this.deferredDueDate = const Value.absent(),
    required String status,
    required int createdAt,
    required int updatedAt,
    this.resolvedAt = const Value.absent(),
  }) : kind = Value(kind),
       titleSnapshot = Value(titleSnapshot),
       dueDate = Value(dueDate),
       reminderRule = Value(reminderRule),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TaskRow> custom({
    Expression<int>? id,
    Expression<int>? templateId,
    Expression<String>? kind,
    Expression<String>? titleSnapshot,
    Expression<String>? noteSnapshot,
    Expression<int>? categoryId,
    Expression<int>? dueDate,
    Expression<String>? repeatRule,
    Expression<String>? reminderRule,
    Expression<int>? deferredDueDate,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? resolvedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (kind != null) 'kind': kind,
      if (titleSnapshot != null) 'title_snapshot': titleSnapshot,
      if (noteSnapshot != null) 'note_snapshot': noteSnapshot,
      if (categoryId != null) 'category_id': categoryId,
      if (dueDate != null) 'due_date': dueDate,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (reminderRule != null) 'reminder_rule': reminderRule,
      if (deferredDueDate != null) 'deferred_due_date': deferredDueDate,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<int?>? templateId,
    Value<String>? kind,
    Value<String>? titleSnapshot,
    Value<String?>? noteSnapshot,
    Value<int?>? categoryId,
    Value<int>? dueDate,
    Value<String?>? repeatRule,
    Value<String>? reminderRule,
    Value<int?>? deferredDueDate,
    Value<String>? status,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? resolvedAt,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      kind: kind ?? this.kind,
      titleSnapshot: titleSnapshot ?? this.titleSnapshot,
      noteSnapshot: noteSnapshot ?? this.noteSnapshot,
      categoryId: categoryId ?? this.categoryId,
      dueDate: dueDate ?? this.dueDate,
      repeatRule: repeatRule ?? this.repeatRule,
      reminderRule: reminderRule ?? this.reminderRule,
      deferredDueDate: deferredDueDate ?? this.deferredDueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
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
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (titleSnapshot.present) {
      map['title_snapshot'] = Variable<String>(titleSnapshot.value);
    }
    if (noteSnapshot.present) {
      map['note_snapshot'] = Variable<String>(noteSnapshot.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<int>(dueDate.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (reminderRule.present) {
      map['reminder_rule'] = Variable<String>(reminderRule.value);
    }
    if (deferredDueDate.present) {
      map['deferred_due_date'] = Variable<int>(deferredDueDate.value);
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
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<int>(resolvedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('kind: $kind, ')
          ..write('titleSnapshot: $titleSnapshot, ')
          ..write('noteSnapshot: $noteSnapshot, ')
          ..write('categoryId: $categoryId, ')
          ..write('dueDate: $dueDate, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('reminderRule: $reminderRule, ')
          ..write('deferredDueDate: $deferredDueDate, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('resolvedAt: $resolvedAt')
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
  );
  static const VerificationMeta _ruleIdMeta = const VerificationMeta('ruleId');
  @override
  late final GeneratedColumn<int> ruleId = GeneratedColumn<int>(
    'rule_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  late final $TaskTemplatesTable taskTemplates = $TaskTemplatesTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $TimelinesTable timelines = $TimelinesTable(this);
  late final $TimelineMilestoneRulesTable timelineMilestoneRules =
      $TimelineMilestoneRulesTable(this);
  late final $TimelineMilestoneRecordsTable timelineMilestoneRecords =
      $TimelineMilestoneRecordsTable(this);
  late final TaskTimelineDao taskTimelineDao = TaskTimelineDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    taskTemplates,
    tasks,
    timelines,
    timelineMilestoneRules,
    timelineMilestoneRecords,
  ];
}

typedef $$TaskTemplatesTableCreateCompanionBuilder =
    TaskTemplatesCompanion Function({
      Value<int> id,
      required String title,
      Value<int?> categoryId,
      Value<String?> note,
      required String kind,
      required String status,
      required int firstDueDate,
      Value<String?> repeatRule,
      required String reminderRule,
      required int createdAt,
      required int updatedAt,
    });
typedef $$TaskTemplatesTableUpdateCompanionBuilder =
    TaskTemplatesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<int?> categoryId,
      Value<String?> note,
      Value<String> kind,
      Value<String> status,
      Value<int> firstDueDate,
      Value<String?> repeatRule,
      Value<String> reminderRule,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

class $$TaskTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $TaskTemplatesTable> {
  $$TaskTemplatesTableFilterComposer({
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

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstDueDate => $composableBuilder(
    column: $table.firstDueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderRule => $composableBuilder(
    column: $table.reminderRule,
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

class $$TaskTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskTemplatesTable> {
  $$TaskTemplatesTableOrderingComposer({
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

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstDueDate => $composableBuilder(
    column: $table.firstDueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderRule => $composableBuilder(
    column: $table.reminderRule,
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

class $$TaskTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskTemplatesTable> {
  $$TaskTemplatesTableAnnotationComposer({
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

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get firstDueDate => $composableBuilder(
    column: $table.firstDueDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderRule => $composableBuilder(
    column: $table.reminderRule,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TaskTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskTemplatesTable,
          TaskTemplateRow,
          $$TaskTemplatesTableFilterComposer,
          $$TaskTemplatesTableOrderingComposer,
          $$TaskTemplatesTableAnnotationComposer,
          $$TaskTemplatesTableCreateCompanionBuilder,
          $$TaskTemplatesTableUpdateCompanionBuilder,
          (
            TaskTemplateRow,
            BaseReferences<_$AppDatabase, $TaskTemplatesTable, TaskTemplateRow>,
          ),
          TaskTemplateRow,
          PrefetchHooks Function()
        > {
  $$TaskTemplatesTableTableManager(_$AppDatabase db, $TaskTemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> firstDueDate = const Value.absent(),
                Value<String?> repeatRule = const Value.absent(),
                Value<String> reminderRule = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => TaskTemplatesCompanion(
                id: id,
                title: title,
                categoryId: categoryId,
                note: note,
                kind: kind,
                status: status,
                firstDueDate: firstDueDate,
                repeatRule: repeatRule,
                reminderRule: reminderRule,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<int?> categoryId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required String kind,
                required String status,
                required int firstDueDate,
                Value<String?> repeatRule = const Value.absent(),
                required String reminderRule,
                required int createdAt,
                required int updatedAt,
              }) => TaskTemplatesCompanion.insert(
                id: id,
                title: title,
                categoryId: categoryId,
                note: note,
                kind: kind,
                status: status,
                firstDueDate: firstDueDate,
                repeatRule: repeatRule,
                reminderRule: reminderRule,
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

typedef $$TaskTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskTemplatesTable,
      TaskTemplateRow,
      $$TaskTemplatesTableFilterComposer,
      $$TaskTemplatesTableOrderingComposer,
      $$TaskTemplatesTableAnnotationComposer,
      $$TaskTemplatesTableCreateCompanionBuilder,
      $$TaskTemplatesTableUpdateCompanionBuilder,
      (
        TaskTemplateRow,
        BaseReferences<_$AppDatabase, $TaskTemplatesTable, TaskTemplateRow>,
      ),
      TaskTemplateRow,
      PrefetchHooks Function()
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      Value<int?> templateId,
      required String kind,
      required String titleSnapshot,
      Value<String?> noteSnapshot,
      Value<int?> categoryId,
      required int dueDate,
      Value<String?> repeatRule,
      required String reminderRule,
      Value<int?> deferredDueDate,
      required String status,
      required int createdAt,
      required int updatedAt,
      Value<int?> resolvedAt,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      Value<int?> templateId,
      Value<String> kind,
      Value<String> titleSnapshot,
      Value<String?> noteSnapshot,
      Value<int?> categoryId,
      Value<int> dueDate,
      Value<String?> repeatRule,
      Value<String> reminderRule,
      Value<int?> deferredDueDate,
      Value<String> status,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> resolvedAt,
    });

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
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

  ColumnFilters<int> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleSnapshot => $composableBuilder(
    column: $table.titleSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteSnapshot => $composableBuilder(
    column: $table.noteSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderRule => $composableBuilder(
    column: $table.reminderRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deferredDueDate => $composableBuilder(
    column: $table.deferredDueDate,
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

  ColumnFilters<int> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
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

  ColumnOrderings<int> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleSnapshot => $composableBuilder(
    column: $table.titleSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteSnapshot => $composableBuilder(
    column: $table.noteSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderRule => $composableBuilder(
    column: $table.reminderRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deferredDueDate => $composableBuilder(
    column: $table.deferredDueDate,
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

  ColumnOrderings<int> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get titleSnapshot => $composableBuilder(
    column: $table.titleSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get noteSnapshot => $composableBuilder(
    column: $table.noteSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderRule => $composableBuilder(
    column: $table.reminderRule,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deferredDueDate => $composableBuilder(
    column: $table.deferredDueDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          TaskRow,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskRow, BaseReferences<_$AppDatabase, $TasksTable, TaskRow>),
          TaskRow,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> templateId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> titleSnapshot = const Value.absent(),
                Value<String?> noteSnapshot = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int> dueDate = const Value.absent(),
                Value<String?> repeatRule = const Value.absent(),
                Value<String> reminderRule = const Value.absent(),
                Value<int?> deferredDueDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> resolvedAt = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                templateId: templateId,
                kind: kind,
                titleSnapshot: titleSnapshot,
                noteSnapshot: noteSnapshot,
                categoryId: categoryId,
                dueDate: dueDate,
                repeatRule: repeatRule,
                reminderRule: reminderRule,
                deferredDueDate: deferredDueDate,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                resolvedAt: resolvedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> templateId = const Value.absent(),
                required String kind,
                required String titleSnapshot,
                Value<String?> noteSnapshot = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                required int dueDate,
                Value<String?> repeatRule = const Value.absent(),
                required String reminderRule,
                Value<int?> deferredDueDate = const Value.absent(),
                required String status,
                required int createdAt,
                required int updatedAt,
                Value<int?> resolvedAt = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                templateId: templateId,
                kind: kind,
                titleSnapshot: titleSnapshot,
                noteSnapshot: noteSnapshot,
                categoryId: categoryId,
                dueDate: dueDate,
                repeatRule: repeatRule,
                reminderRule: reminderRule,
                deferredDueDate: deferredDueDate,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                resolvedAt: resolvedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      TaskRow,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskRow, BaseReferences<_$AppDatabase, $TasksTable, TaskRow>),
      TaskRow,
      PrefetchHooks Function()
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
          (
            TimelineRow,
            BaseReferences<_$AppDatabase, $TimelinesTable, TimelineRow>,
          ),
          TimelineRow,
          PrefetchHooks Function()
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (
        TimelineRow,
        BaseReferences<_$AppDatabase, $TimelinesTable, TimelineRow>,
      ),
      TimelineRow,
      PrefetchHooks Function()
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

  ColumnFilters<int> get timelineId => $composableBuilder(
    column: $table.timelineId,
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

  ColumnOrderings<int> get timelineId => $composableBuilder(
    column: $table.timelineId,
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

  GeneratedColumn<int> get timelineId => $composableBuilder(
    column: $table.timelineId,
    builder: (column) => column,
  );

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
          (
            TimelineMilestoneRuleRow,
            BaseReferences<
              _$AppDatabase,
              $TimelineMilestoneRulesTable,
              TimelineMilestoneRuleRow
            >,
          ),
          TimelineMilestoneRuleRow,
          PrefetchHooks Function()
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (
        TimelineMilestoneRuleRow,
        BaseReferences<
          _$AppDatabase,
          $TimelineMilestoneRulesTable,
          TimelineMilestoneRuleRow
        >,
      ),
      TimelineMilestoneRuleRow,
      PrefetchHooks Function()
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

  ColumnFilters<int> get timelineId => $composableBuilder(
    column: $table.timelineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ruleId => $composableBuilder(
    column: $table.ruleId,
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

  ColumnOrderings<int> get timelineId => $composableBuilder(
    column: $table.timelineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ruleId => $composableBuilder(
    column: $table.ruleId,
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

  GeneratedColumn<int> get timelineId => $composableBuilder(
    column: $table.timelineId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ruleId =>
      $composableBuilder(column: $table.ruleId, builder: (column) => column);

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
            BaseReferences<
              _$AppDatabase,
              $TimelineMilestoneRecordsTable,
              TimelineMilestoneRecordRow
            >,
          ),
          TimelineMilestoneRecordRow,
          PrefetchHooks Function()
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (
        TimelineMilestoneRecordRow,
        BaseReferences<
          _$AppDatabase,
          $TimelineMilestoneRecordsTable,
          TimelineMilestoneRecordRow
        >,
      ),
      TimelineMilestoneRecordRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TaskTemplatesTableTableManager get taskTemplates =>
      $$TaskTemplatesTableTableManager(_db, _db.taskTemplates);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
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
