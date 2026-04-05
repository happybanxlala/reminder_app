import 'package:drift/drift.dart';

import '../../domain/reminder.dart';
import '../../domain/recurring_reminder.dart';
import '../../domain/repeat_rule.dart';
import 'app_database.dart';
import 'tables.dart';

part 'daos.g.dart';

class ReminderRecord {
  const ReminderRecord({
    required this.reminder,
    this.recurringReminder,
    this.topicCategory,
    this.actionCategory,
  });

  final Reminder reminder;
  final RecurringReminder? recurringReminder;
  final TopicCategory? topicCategory;
  final ActionCategory? actionCategory;
}

class RecurringReminderRecord {
  const RecurringReminderRecord({
    required this.recurringReminder,
    this.topicCategory,
    this.actionCategory,
  });

  final RecurringReminder recurringReminder;
  final TopicCategory? topicCategory;
  final ActionCategory? actionCategory;
}

@DriftAccessor(
  tables: [RecurringReminders, TopicCategories, ActionCategories, Reminders],
)
class ReminderDao extends DatabaseAccessor<AppDatabase>
    with _$ReminderDaoMixin {
  ReminderDao(super.attachedDatabase);

  static const int _dayMs = 86400000;

  Stream<List<ReminderRecord>> watchAll() {
    return _watchRecords(
      where: (t) => t.status.isNotValue(ReminderStatus.canceled),
      orderBy: [
        (t) => OrderingTerm.asc(t.status),
        (t) => OrderingTerm.asc(t.dueAt),
        (t) => OrderingTerm.asc(t.startAt),
        (t) => OrderingTerm.desc(t.updatedAt),
      ],
    );
  }

  Stream<List<ReminderRecord>> watchActivePending() {
    final now = DateTime.now();
    final todayStartMs = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;
    final countdownBase = coalesce<int>([
      reminders.deferredDueAt,
      reminders.dueAt,
    ]);
    final triggerOffsetDaysExpr = coalesce<int>([
      reminders.triggerOffsetDays,
      const Constant(0),
    ]);
    final countdownStart =
        countdownBase - (triggerOffsetDaysExpr * const Constant(_dayMs));
    final countUpStart =
        reminders.startAt + (triggerOffsetDaysExpr * const Constant(_dayMs));

    return _watchRecords(
      where: (t) {
        final countdownActive =
            t.trackingMode.equals(ReminderTrackingMode.countdown) &
            ((t.triggerMode.equals(ReminderTriggerMode.inRange) &
                    countdownStart.isSmallerOrEqualValue(todayStartMs)) |
                t.triggerMode.equals(ReminderTriggerMode.immediate) |
                (t.triggerMode.equals(ReminderTriggerMode.onPoint) &
                    countdownBase.isNotNull() &
                    countdownBase.isSmallerOrEqualValue(todayStartMs)));
        final countUpActive =
            t.trackingMode.equals(ReminderTrackingMode.countUp) &
            countUpStart.isSmallerOrEqualValue(todayStartMs);

        return t.status.equals(ReminderStatus.pending) &
            (countdownActive | countUpActive);
      },
      orderBy: [
        (t) => OrderingTerm.asc(t.dueAt),
        (t) => OrderingTerm.asc(t.startAt),
        (t) => OrderingTerm.desc(t.updatedAt),
      ],
    );
  }

  Stream<List<ReminderRecord>> watchTodayPending() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final startMs = startOfDay.millisecondsSinceEpoch;
    final endMs = endOfDay.millisecondsSinceEpoch;
    final countdownBase = coalesce<int>([
      reminders.deferredDueAt,
      reminders.dueAt,
    ]);
    final triggerOffsetDaysExpr = coalesce<int>([
      reminders.triggerOffsetDays,
      const Constant(0),
    ]);
    final countUpTarget =
        reminders.startAt + (triggerOffsetDaysExpr * const Constant(_dayMs));

    return _watchRecords(
      where: (t) {
        final countdownToday =
            t.trackingMode.equals(ReminderTrackingMode.countdown) &
            countdownBase.isNotNull() &
            countdownBase.isBiggerOrEqualValue(startMs) &
            countdownBase.isSmallerThanValue(endMs);
        final countUpToday =
            t.trackingMode.equals(ReminderTrackingMode.countUp) &
            countUpTarget.isBiggerOrEqualValue(startMs) &
            countUpTarget.isSmallerThanValue(endMs);
        return t.status.equals(ReminderStatus.pending) &
            (countdownToday | countUpToday);
      },
      orderBy: [
        (t) => OrderingTerm.asc(t.dueAt),
        (t) => OrderingTerm.asc(t.startAt),
      ],
    );
  }

  Stream<List<ReminderRecord>> watchCompletedOrSkipped({int limit = 30}) {
    return _watchRecords(
      where: (t) =>
          t.status.equals(ReminderStatus.done) |
          t.status.equals(ReminderStatus.skipped),
      orderBy: [(t) => OrderingTerm.desc(t.updatedAt)],
      limit: limit,
    );
  }

  Stream<ReminderRecord?> watchNextReminder() {
    final query = _joinedQuery(
      where: (t) => t.status.equals(ReminderStatus.pending),
      orderBy: [
        (t) => OrderingTerm.asc(t.dueAt),
        (t) => OrderingTerm.asc(t.startAt),
      ],
      limit: 1,
    );

    return query.watch().map((rows) {
      if (rows.isEmpty) {
        return null;
      }
      return _mapRecord(rows.first);
    });
  }

  Future<ReminderRecord?> getById(int id) async {
    final rows = await _joinedQuery(
      where: (t) => t.id.equals(id),
      limit: 1,
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return _mapRecord(rows.first);
  }

  Future<ReminderRecord?> getEditableById(int id) async {
    final rows = await _joinedQuery(
      where: (t) => t.id.equals(id) & t.status.equals(ReminderStatus.pending),
      limit: 1,
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return _mapRecord(rows.first);
  }

  Stream<List<RecurringReminderRecord>> watchAllRecurringReminders() {
    return _recurringReminderJoinedQuery().watch().map(
      (rows) => rows.map(_mapRecurringReminderRecord).toList(),
    );
  }

  Future<RecurringReminder?> getRecurringReminderById(int id) {
    return (select(
      recurringReminders,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<RecurringReminderRecord?> getRecurringReminderRecordById(
    int id,
  ) async {
    final rows = await _recurringReminderJoinedQuery(
      where: (t) => t.id.equals(id),
      limit: 1,
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return _mapRecurringReminderRecord(rows.first);
  }

  Future<List<TopicCategory>> listTopicCategories() {
    return (select(
      topicCategories,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Future<List<ActionCategory>> listActionCategories() {
    return (select(
      actionCategories,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Future<int> insertRecurringReminder(RecurringRemindersCompanion entry) {
    return into(recurringReminders).insert(entry);
  }

  Future<bool> updateRecurringReminder(RecurringReminder entry) {
    return update(recurringReminders).replace(entry);
  }

  Future<void> stopRecurringReminder(int id) async {
    await _setRecurringReminderStatus(
      id,
      RecurringReminderStatus.stopped,
      cancelPendingReminders: true,
    );
  }

  Future<void> cancelRecurringReminder(int id) async {
    await _setRecurringReminderStatus(
      id,
      RecurringReminderStatus.canceled,
      cancelPendingReminders: true,
    );
  }

  Future<int> insertReminder(RemindersCompanion entry) {
    return into(reminders).insert(entry);
  }

  Future<bool> updateReminder(Reminder reminder) {
    return update(reminders).replace(reminder);
  }

  Future<int> deleteReminder(int id) {
    return (delete(reminders)..where((t) => t.id.equals(id))).go();
  }

  Future<void> complete(int id) => commitCompleted([id]);

  Future<void> skip(int id) =>
      _transitionAndMaybeRepeat(id, ReminderStatus.skipped);

  Future<void> cancel(int id) =>
      _transitionAndMaybeRepeat(id, ReminderStatus.canceled);

  Future<bool> deferReminder(int id, int days) async {
    if (days < 1) {
      return false;
    }

    final source = await getById(id);
    if (source == null ||
        source.reminder.status != ReminderStatus.pending ||
        source.reminder.trackingMode != ReminderTrackingMode.countdown) {
      return false;
    }

    final baseDueAt = source.reminder.deferredDueAt ?? source.reminder.dueAt;
    if (baseDueAt == null) {
      return false;
    }

    final deferredDueAt = DateTime.fromMillisecondsSinceEpoch(
      baseDueAt,
    ).add(Duration(days: days)).millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;

    final updatedRows = await (update(reminders)..where((t) => t.id.equals(id)))
        .write(
          RemindersCompanion(
            deferredDueAt: Value(deferredDueAt),
            updatedAt: Value(now),
          ),
        );
    return updatedRows > 0;
  }

  Future<void> restore(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(reminders)..where((t) => t.id.equals(id))).write(
      RemindersCompanion(
        status: const Value(ReminderStatus.pending),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> commitCompleted(List<int> ids) async {
    if (ids.isEmpty) {
      return;
    }
    for (final id in ids.toSet()) {
      await _transitionAndMaybeRepeat(id, ReminderStatus.done);
    }
  }

  Future<void> _transitionAndMaybeRepeat(int id, int nextStatus) async {
    await transaction(() async {
      final source = await getById(id);
      if (source == null || source.reminder.status != ReminderStatus.pending) {
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      await (update(reminders)..where((t) => t.id.equals(id))).write(
        RemindersCompanion(status: Value(nextStatus), updatedAt: Value(now)),
      );

      if ((nextStatus == ReminderStatus.done ||
              nextStatus == ReminderStatus.skipped) &&
          source.reminder.recurringReminderId != null &&
          source.recurringReminder != null &&
          source.recurringReminder!.status == RecurringReminderStatus.pending) {
        await createNextReminderFromRecurringReminder(
          source.reminder,
          source.recurringReminder!,
          now,
        );
      }

      if (nextStatus == ReminderStatus.canceled &&
          source.reminder.recurringReminderId != null) {
        await _setRecurringReminderStatus(
          source.reminder.recurringReminderId!,
          RecurringReminderStatus.stopped,
          cancelPendingReminders: true,
          nowEpochMs: now,
        );
      }
    });
  }

  Future<int?> reactivateRecurringReminder(
    int id, {
    int? dueAtEpochMs,
    int? startAtEpochMs,
  }) async {
    return transaction(() async {
      final recurringReminder = await getRecurringReminderById(id);
      if (recurringReminder == null ||
          recurringReminder.status != RecurringReminderStatus.stopped) {
        return null;
      }
      if (recurringReminder.trackingMode == ReminderTrackingMode.countdown &&
          dueAtEpochMs == null) {
        return null;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      await _cancelPendingOccurrencesForRecurringReminder(id, now);
      await (update(recurringReminders)..where((t) => t.id.equals(id))).write(
        RecurringRemindersCompanion(
          status: const Value(RecurringReminderStatus.pending),
          updatedAt: Value(now),
        ),
      );

      final latestReminder = await _getLatestReminderOccurrence(id);
      final reminderStartAt =
          recurringReminder.trackingMode == ReminderTrackingMode.countUp
          ? (startAtEpochMs ?? now)
          : now;
      final reminderDueAt =
          recurringReminder.trackingMode == ReminderTrackingMode.countdown
          ? dueAtEpochMs
          : null;

      return insertReminder(
        RemindersCompanion.insert(
          recurringReminderId: Value(recurringReminder.id),
          previousOccurrenceId: Value(latestReminder?.id),
          trackingMode: recurringReminder.trackingMode,
          triggerMode: recurringReminder.triggerMode,
          title: recurringReminder.title,
          note: Value(recurringReminder.note),
          triggerOffsetDays: Value(recurringReminder.triggerOffsetDays),
          statusNote: const Value.absent(),
          dueAt: Value(reminderDueAt),
          startAt: reminderStartAt,
          deferredDueAt: const Value.absent(),
          topicCategoryId: Value(recurringReminder.topicCategoryId),
          actionCategoryId: Value(recurringReminder.actionCategoryId),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });
  }

  Future<int?> createNextReminderFromRecurringReminder(
    Reminder source,
    RecurringReminder recurringReminder,
    int nowEpochMs,
  ) async {
    final rule = RepeatRule.parse(recurringReminder.repeatRule);
    if (rule == null) {
      return null;
    }

    final baseDueAt = source.deferredDueAt ?? source.dueAt;
    final nextDueAt =
        source.trackingMode == ReminderTrackingMode.countdown &&
            baseDueAt != null
        ? rule.advance(DateTime.fromMillisecondsSinceEpoch(baseDueAt))
        : null;
    final nextStartAt = source.trackingMode == ReminderTrackingMode.countUp
        ? rule
              .advance(DateTime.fromMillisecondsSinceEpoch(source.startAt))
              .millisecondsSinceEpoch
        : nowEpochMs;

    return insertReminder(
      RemindersCompanion.insert(
        recurringReminderId: Value(recurringReminder.id),
        previousOccurrenceId: Value(source.id),
        trackingMode: recurringReminder.trackingMode,
        triggerMode: recurringReminder.triggerMode,
        title: recurringReminder.title,
        note: Value(recurringReminder.note),
        triggerOffsetDays: Value(recurringReminder.triggerOffsetDays),
        statusNote: const Value.absent(),
        dueAt: Value(nextDueAt?.millisecondsSinceEpoch),
        startAt: nextStartAt,
        deferredDueAt: const Value.absent(),
        topicCategoryId: Value(recurringReminder.topicCategoryId),
        actionCategoryId: Value(recurringReminder.actionCategoryId),
        createdAt: nowEpochMs,
        updatedAt: nowEpochMs,
      ),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _joinedQuery({
    required Expression<bool> Function($RemindersTable t) where,
    List<OrderingTerm Function($RemindersTable t)> orderBy = const [],
    int? limit,
  }) {
    final query = select(reminders).join([
      leftOuterJoin(
        recurringReminders,
        recurringReminders.id.equalsExp(reminders.recurringReminderId),
      ),
      leftOuterJoin(
        topicCategories,
        topicCategories.id.equalsExp(reminders.topicCategoryId),
      ),
      leftOuterJoin(
        actionCategories,
        actionCategories.id.equalsExp(reminders.actionCategoryId),
      ),
    ]);
    query.where(where(reminders));
    if (orderBy.isNotEmpty) {
      query.orderBy(orderBy.map((builder) => builder(reminders)).toList());
    }
    if (limit != null) {
      query.limit(limit);
    }
    return query;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _recurringReminderJoinedQuery({
    Expression<bool> Function($RecurringRemindersTable t)? where,
    int? limit,
  }) {
    final query = select(recurringReminders).join([
      leftOuterJoin(
        topicCategories,
        topicCategories.id.equalsExp(recurringReminders.topicCategoryId),
      ),
      leftOuterJoin(
        actionCategories,
        actionCategories.id.equalsExp(recurringReminders.actionCategoryId),
      ),
    ]);
    if (where != null) {
      query.where(where(recurringReminders));
    }
    query.orderBy([
      OrderingTerm.asc(recurringReminders.status),
      OrderingTerm.desc(recurringReminders.updatedAt),
      OrderingTerm.asc(recurringReminders.id),
    ]);
    if (limit != null) {
      query.limit(limit);
    }
    return query;
  }

  Stream<List<ReminderRecord>> _watchRecords({
    required Expression<bool> Function($RemindersTable t) where,
    List<OrderingTerm Function($RemindersTable t)> orderBy = const [],
    int? limit,
  }) {
    return _joinedQuery(
      where: where,
      orderBy: orderBy,
      limit: limit,
    ).watch().map((rows) => rows.map(_mapRecord).toList());
  }

  ReminderRecord _mapRecord(TypedResult row) {
    return ReminderRecord(
      reminder: row.readTable(reminders),
      recurringReminder: row.readTableOrNull(recurringReminders),
      topicCategory: row.readTableOrNull(topicCategories),
      actionCategory: row.readTableOrNull(actionCategories),
    );
  }

  RecurringReminderRecord _mapRecurringReminderRecord(TypedResult row) {
    return RecurringReminderRecord(
      recurringReminder: row.readTable(recurringReminders),
      topicCategory: row.readTableOrNull(topicCategories),
      actionCategory: row.readTableOrNull(actionCategories),
    );
  }

  Future<void> _setRecurringReminderStatus(
    int id,
    int nextStatus, {
    required bool cancelPendingReminders,
    int? nowEpochMs,
  }) async {
    await transaction(() async {
      final now = nowEpochMs ?? DateTime.now().millisecondsSinceEpoch;
      await (update(recurringReminders)..where((t) => t.id.equals(id))).write(
        RecurringRemindersCompanion(
          status: Value(nextStatus),
          updatedAt: Value(now),
        ),
      );
      if (cancelPendingReminders) {
        await _cancelPendingOccurrencesForRecurringReminder(id, now);
      }
    });
  }

  Future<void> _cancelPendingOccurrencesForRecurringReminder(
    int recurringReminderId,
    int nowEpochMs,
  ) async {
    await (update(reminders)..where(
          (t) =>
              t.recurringReminderId.equals(recurringReminderId) &
              t.status.equals(ReminderStatus.pending),
        ))
        .write(
          RemindersCompanion(
            status: const Value(ReminderStatus.canceled),
            updatedAt: Value(nowEpochMs),
          ),
        );
  }

  Future<Reminder?> _getLatestReminderOccurrence(int recurringReminderId) {
    return (select(reminders)
          ..where((t) => t.recurringReminderId.equals(recurringReminderId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(1))
        .getSingleOrNull();
  }
}
