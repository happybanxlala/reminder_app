import 'package:drift/drift.dart';

import '../../domain/reminder.dart';
import '../../domain/reminder_series.dart';
import '../../domain/repeat_rule.dart';
import 'app_database.dart';
import 'tables.dart';

part 'daos.g.dart';

class ReminderRecord {
  const ReminderRecord({
    required this.reminder,
    this.series,
    this.issueType,
    this.handleType,
  });

  final Reminder reminder;
  final ReminderSeriesEntry? series;
  final IssueType? issueType;
  final HandleType? handleType;
}

@DriftAccessor(
  tables: [ReminderSeriesEntries, IssueTypes, HandleTypes, Reminders],
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
    final countdownBase = coalesce<int>([reminders.extendAt, reminders.dueAt]);
    final remindDaysExpr = coalesce<int>([
      reminders.remindDays,
      const Constant(0),
    ]);
    final countdownStart = countdownBase - (remindDaysExpr * const Constant(_dayMs));
    final countUpStart = reminders.startAt + (remindDaysExpr * const Constant(_dayMs));

    return _watchRecords(
      where: (t) {
        final countdownActive =
            t.timeBasis.equals(ReminderTimeBasis.countdown) &
            ((t.notifyStrategy.equals(ReminderNotifyStrategy.inRange) &
                    countdownStart.isSmallerOrEqualValue(todayStartMs)) |
                t.notifyStrategy.equals(ReminderNotifyStrategy.immediate) |
                (t.notifyStrategy.equals(ReminderNotifyStrategy.onPoint) &
                    countdownBase.isNotNull() &
                    countdownBase.isSmallerOrEqualValue(todayStartMs)));
        final countUpActive =
            t.timeBasis.equals(ReminderTimeBasis.countUp) &
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
    final remindDaysExpr = coalesce<int>([
      reminders.remindDays,
      const Constant(0),
    ]);
    final countUpTarget = reminders.startAt + (remindDaysExpr * const Constant(_dayMs));

    return _watchRecords(
      where: (t) {
        final countdownToday =
            t.timeBasis.equals(ReminderTimeBasis.countdown) &
            t.dueAt.isNotNull() &
            t.dueAt.isBiggerOrEqualValue(startMs) &
            t.dueAt.isSmallerThanValue(endMs);
        final countUpToday =
            t.timeBasis.equals(ReminderTimeBasis.countUp) &
            countUpTarget.isBiggerOrEqualValue(startMs) &
            countUpTarget.isSmallerThanValue(endMs);
        return t.status.equals(ReminderStatus.pending) &
            (countdownToday | countUpToday);
      },
      orderBy: [(t) => OrderingTerm.asc(t.dueAt), (t) => OrderingTerm.asc(t.startAt)],
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
      orderBy: [(t) => OrderingTerm.asc(t.dueAt), (t) => OrderingTerm.asc(t.startAt)],
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
      where: (t) =>
          t.id.equals(id) & t.status.equals(ReminderStatus.pending),
      limit: 1,
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return _mapRecord(rows.first);
  }

  Future<ReminderSeriesEntry?> getSeriesById(int id) {
    return (select(reminderSeriesEntries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<IssueType>> listIssueTypes() {
    return (select(issueTypes)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Future<List<HandleType>> listHandleTypes() {
    return (select(handleTypes)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Future<int> insertSeries(ReminderSeriesEntriesCompanion entry) {
    return into(reminderSeriesEntries).insert(entry);
  }

  Future<bool> updateSeries(ReminderSeriesEntry entry) {
    return update(reminderSeriesEntries).replace(entry);
  }

  Future<void> stopSeries(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(reminderSeriesEntries)..where((t) => t.id.equals(id))).write(
      ReminderSeriesEntriesCompanion(
        status: const Value(ReminderSeriesStatus.stopped),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> cancelSeries(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(reminderSeriesEntries)..where((t) => t.id.equals(id))).write(
      ReminderSeriesEntriesCompanion(
        status: const Value(ReminderSeriesStatus.canceled),
        updatedAt: Value(now),
      ),
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

  Future<void> skip(int id) => _transitionAndMaybeRepeat(id, ReminderStatus.skipped);

  Future<void> cancel(int id) => _transitionAndMaybeRepeat(id, ReminderStatus.canceled);

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
          source.reminder.seriesId != null &&
          source.series != null &&
          source.series!.status == ReminderSeriesStatus.pending) {
        await createNextReminderFromSeries(source.reminder, source.series!, now);
      }

      if (nextStatus == ReminderStatus.canceled && source.reminder.seriesId != null) {
        await cancelSeries(source.reminder.seriesId!);
      }
    });
  }

  Future<int?> createNextReminderFromSeries(
    Reminder source,
    ReminderSeriesEntry series,
    int nowEpochMs,
  ) async {
    final rule = RepeatRule.parse(series.repeatRule);
    if (rule == null) {
      return null;
    }

    final baseDueAt = source.extendAt ?? source.dueAt;
    final nextDueAt = source.timeBasis == ReminderTimeBasis.countdown &&
            baseDueAt != null
        ? rule.advance(DateTime.fromMillisecondsSinceEpoch(baseDueAt))
        : null;
    final nextStartAt = source.timeBasis == ReminderTimeBasis.countUp
        ? rule
            .advance(DateTime.fromMillisecondsSinceEpoch(source.startAt))
            .millisecondsSinceEpoch
        : nowEpochMs;

    return insertReminder(
      RemindersCompanion.insert(
        seriesId: Value(series.id),
        previousReminderId: Value(source.id),
        timeBasis: series.timeBasis,
        notifyStrategy: series.notifyStrategy,
        title: series.title,
        note: Value(series.note),
        remindDays: Value(series.remindDays),
        remark: const Value.absent(),
        dueAt: Value(nextDueAt?.millisecondsSinceEpoch),
        startAt: nextStartAt,
        extendAt: const Value.absent(),
        issueTypeId: Value(series.issueTypeId),
        handleTypeId: Value(series.handleTypeId),
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
        reminderSeriesEntries,
        reminderSeriesEntries.id.equalsExp(reminders.seriesId),
      ),
      leftOuterJoin(issueTypes, issueTypes.id.equalsExp(reminders.issueTypeId)),
      leftOuterJoin(
        handleTypes,
        handleTypes.id.equalsExp(reminders.handleTypeId),
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

  Stream<List<ReminderRecord>> _watchRecords({
    required Expression<bool> Function($RemindersTable t) where,
    List<OrderingTerm Function($RemindersTable t)> orderBy = const [],
    int? limit,
  }) {
    return _joinedQuery(where: where, orderBy: orderBy, limit: limit)
        .watch()
        .map((rows) => rows.map(_mapRecord).toList());
  }

  ReminderRecord _mapRecord(TypedResult row) {
    return ReminderRecord(
      reminder: row.readTable(reminders),
      series: row.readTableOrNull(reminderSeriesEntries),
      issueType: row.readTableOrNull(issueTypes),
      handleType: row.readTableOrNull(handleTypes),
    );
  }
}
