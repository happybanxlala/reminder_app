import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/reminder_repository.dart';
import '../../domain/reminder.dart';
import '../../presentation/reminder_view_models.dart';
import '../widgets/reminder_list_tile.dart';
import 'reminder_edit_page.dart';

class RemindersListPage extends ConsumerStatefulWidget {
  const RemindersListPage({super.key});

  static const routeName = 'reminders-list';
  static const routePath = '/';

  @override
  ConsumerState<RemindersListPage> createState() => _RemindersListPageState();
}

class _RemindersListPageState extends ConsumerState<RemindersListPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController;
  final GlobalKey<_PendingListState> _todayListKey =
      GlobalKey<_PendingListState>();
  final GlobalKey<_PendingListState> _upcomingListKey =
      GlobalKey<_PendingListState>();
  bool _isFlushingPending = false;
  int _stagedPendingCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_commitAndResetPendingSession());
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      return;
    }
    if (_tabController.index > 1) {
      unawaited(_commitAndResetPendingSession());
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _commitAndResetPendingSession() async {
    await _flushPendingCompletions();
  }

  Future<void> _flushPendingCompletions() async {
    if (_isFlushingPending) {
      return;
    }
    final pendingListStates = [
      _todayListKey.currentState,
      _upcomingListKey.currentState,
    ].whereType<_PendingListState>().toList(growable: false);
    if (pendingListStates.isEmpty) {
      return;
    }

    final stagedIds = pendingListStates
        .expand((state) => state.stagedReminderIds)
        .toSet()
        .toList(growable: false);
    if (stagedIds.isEmpty) {
      for (final state in pendingListStates) {
        state.clearStaged();
      }
      return;
    }

    _isFlushingPending = true;
    if (mounted) {
      setState(() {});
    }
    try {
      await ref
          .read(reminderRepositoryProvider)
          .commitStagedCompletions(stagedIds);
      if (mounted) {
        for (final state in pendingListStates) {
          state.clearStaged();
        }
      }
    } finally {
      _isFlushingPending = false;
      if (mounted) {
        setState(() {
          _stagedPendingCount = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayPendingProvider);
    final upcomingAsync = ref.watch(activePendingProvider);
    final historyAsync = ref.watch(completedOrSkippedProvider);
    final recurringAsync = ref.watch(recurringRemindersProvider);
    final isTaskTab = _tabController.index == 0 || _tabController.index == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text(ReminderUiText.appTitle),
        actions: [
          if (isTaskTab && _stagedPendingCount > 0)
            IconButton(
              key: const Key('commit-staged-button'),
              onPressed: _isFlushingPending
                  ? null
                  : () async {
                      await _commitAndResetPendingSession();
                    },
              tooltip: '批次完成',
              icon: const Icon(Icons.done_all),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            if (index > 1) {
              unawaited(_commitAndResetPendingSession());
            }
          },
          tabs: const [
            Tab(text: ReminderUiText.todayTab),
            Tab(text: ReminderUiText.upcomingTab),
            Tab(text: ReminderUiText.completedTab),
            Tab(text: ReminderUiText.habitTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          todayAsync.when(
            data: (items) => _PendingList(
              key: _todayListKey,
              items: items
                  .map(PendingReminderItemViewModel.fromDomain)
                  .toList(growable: false),
              emptyMessage: ReminderUiText.noTodayTasks,
              onStagedChanged: (_) => _refreshStagedPendingCount(),
              onEditReminder: (reminderId) async {
                await _commitAndResetPendingSession();
                if (!context.mounted) {
                  return;
                }
                context.pushNamed(
                  ReminderEditPage.editRouteName,
                  pathParameters: {'id': reminderId.toString()},
                );
              },
            ),
            error: (error, stack) => Center(child: Text('讀取失敗: $error')),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          upcomingAsync.when(
            data: (items) => _PendingList(
              key: _upcomingListKey,
              items: items
                  .where((item) => !_isTodayPendingReminder(item))
                  .map(PendingReminderItemViewModel.fromDomain)
                  .toList(growable: false),
              emptyMessage: ReminderUiText.noUpcomingTasks,
              onStagedChanged: (_) => _refreshStagedPendingCount(),
              onEditReminder: (reminderId) async {
                await _commitAndResetPendingSession();
                if (!context.mounted) {
                  return;
                }
                context.pushNamed(
                  ReminderEditPage.editRouteName,
                  pathParameters: {'id': reminderId.toString()},
                );
              },
            ),
            error: (error, stack) => Center(child: Text('讀取失敗: $error')),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          historyAsync.when(
            data: (items) => _HistoryList(
              items: items
                  .map(HistoryReminderItemViewModel.fromDomain)
                  .toList(growable: false),
            ),
            error: (error, stack) => Center(child: Text('讀取失敗: $error')),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          recurringAsync.when(
            data: (items) => _RecurringReminderList(
              items: items
                  .map(RecurringReminderItemViewModel.fromDomain)
                  .toList(growable: false),
              onEditRecurringReminder: (recurringReminderId) async {
                await _commitAndResetPendingSession();
                if (!context.mounted) {
                  return;
                }
                context.pushNamed(
                  ReminderEditPage.recurringEditRouteName,
                  pathParameters: {'id': recurringReminderId.toString()},
                );
              },
            ),
            error: (error, stack) => Center(child: Text('讀取失敗: $error')),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 3
          ? null
          : FloatingActionButton.extended(
              key: const Key('add-reminder-button'),
              onPressed: () async {
                await _commitAndResetPendingSession();
                if (!context.mounted) {
                  return;
                }
                context.pushNamed(ReminderEditPage.newRouteName);
              },
              icon: const Icon(Icons.add),
              label: const Text(ReminderUiText.addTask),
            ),
    );
  }

  void _refreshStagedPendingCount() {
    if (!mounted) {
      return;
    }
    final count =
        (_todayListKey.currentState?.stagedReminderIds.length ?? 0) +
        (_upcomingListKey.currentState?.stagedReminderIds.length ?? 0);
    if (_stagedPendingCount == count) {
      return;
    }
    setState(() {
      _stagedPendingCount = count;
    });
  }

  bool _isTodayPendingReminder(ReminderModel reminder) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (reminder.trackingMode == ReminderTrackingMode.countdown) {
      final dueAt = reminder.deferredDueAt ?? reminder.dueAt;
      if (dueAt == null) {
        return false;
      }
      return _isSameDate(dueAt, today);
    }

    final target = reminder.startAt.add(
      Duration(days: reminder.triggerOffsetDays ?? 0),
    );
    return _isSameDate(target, today);
  }

  bool _isSameDate(DateTime value, DateTime date) {
    return value.year == date.year &&
        value.month == date.month &&
        value.day == date.day;
  }
}

class _PendingList extends ConsumerStatefulWidget {
  const _PendingList({
    super.key,
    required this.items,
    required this.emptyMessage,
    required this.onStagedChanged,
    required this.onEditReminder,
  });

  final List<PendingReminderItemViewModel> items;
  final String emptyMessage;
  final ValueChanged<int> onStagedChanged;
  final Future<void> Function(int reminderId) onEditReminder;

  @override
  ConsumerState<_PendingList> createState() => _PendingListState();
}

class _PendingListState extends ConsumerState<_PendingList> {
  final Map<int, PendingReminderItemViewModel> _recentDone =
      <int, PendingReminderItemViewModel>{};

  List<int> get stagedReminderIds => _recentDone.keys.toList(growable: false);

  void clearStaged() {
    if (!mounted) {
      return;
    }
    setState(_recentDone.clear);
    widget.onStagedChanged(_recentDone.length);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && _recentDone.isEmpty) {
      return Center(child: Text(widget.emptyMessage));
    }

    final repository = ref.read(reminderRepositoryProvider);
    final visibleItems = widget.items
        .where((item) => !_recentDone.containsKey(item.id))
        .toList(growable: false);

    final rows = <Widget>[
      ...visibleItems.map(
        (reminder) => PendingReminderTile(
          reminder: reminder,
          onToggleDone: () async {
            setState(() {
              _recentDone[reminder.id] = reminder;
            });
            widget.onStagedChanged(_recentDone.length);
          },
          onDefer: () async {
            final days = await _promptDeferDays(context, reminder);
            if (days == null) {
              return;
            }
            final success = await repository.defer(reminder.id, days);
            if (!success || !context.mounted) {
              return;
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('已延期 $days 天')));
          },
          onSkip: () async {
            await repository.skip(reminder.id);
          },
          onCancel: () async {
            final confirmed = await _confirmCancel(context, reminder);
            if (!confirmed) {
              return;
            }
            await repository.cancel(reminder.id);
          },
          onLongPress: () async {
            await widget.onEditReminder(reminder.id);
          },
        ),
      ),
    ];

    if (_recentDone.isNotEmpty) {
      rows.add(
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            '已完成（可恢復）',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ),
      );

      rows.addAll(
        _recentDone.values.map(
          (reminder) => CompletedPendingTile(
            reminder: CompletedPendingReminderItemViewModel(
              id: reminder.id,
              title: reminder.title,
            ),
            onRestore: () async {
              final confirmed = await _confirmRestore(context);
              if (!confirmed) {
                return;
              }
              if (!mounted) {
                return;
              }
              setState(() {
                _recentDone.remove(reminder.id);
              });
              widget.onStagedChanged(_recentDone.length);
            },
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => rows[index],
    );
  }

  Future<bool> _confirmCancel(
    BuildContext context,
    PendingReminderItemViewModel reminder,
  ) async {
    final content = reminder.isRecurring
        ? '確定要取消這筆任務嗎？\n這會同時暫停所屬習慣，並取消這個習慣目前所有未完成任務。'
        : '確定要取消這筆任務嗎？';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(ReminderUiText.cancelTask),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('否'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('是'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<bool> _confirmRestore(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(ReminderUiText.restorePendingTitle),
          content: const Text(ReminderUiText.restorePendingMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('否'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('是'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<int?> _promptDeferDays(
    BuildContext context,
    PendingReminderItemViewModel reminder,
  ) async {
    if (!reminder.canDefer) {
      return null;
    }

    final controller = TextEditingController(text: '1');
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(ReminderUiText.deferTask),
          content: TextField(
            key: const Key('defer-days-field'),
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '延期天數',
              hintText: '請輸入 1 或以上',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final days = int.tryParse(controller.text.trim());
                if (days == null || days < 1) {
                  return;
                }
                Navigator.of(context).pop(days);
              },
              child: const Text('確認'),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.items});

  final List<HistoryReminderItemViewModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text(ReminderUiText.noHistoryTasks));
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('僅顯示近期 30 筆資料', style: TextStyle(color: Colors.grey)),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return HistoryReminderTile(reminder: items[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _RecurringReminderList extends ConsumerWidget {
  const _RecurringReminderList({
    required this.items,
    required this.onEditRecurringReminder,
  });

  final List<RecurringReminderItemViewModel> items;
  final Future<void> Function(int recurringReminderId) onEditRecurringReminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Center(child: Text(ReminderUiText.noHabits));
    }

    final repository = ref.read(reminderRepositoryProvider);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final habit = items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('狀態: ${habit.statusLabel}'),
                Text('類型: ${habit.trackingModeLabel}'),
                Text('規則摘要: ${habit.repeatRuleLabel}'),
                if (habit.categoryLabel.isNotEmpty)
                  Text('分類: ${habit.categoryLabel}'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!habit.isCanceled)
                      OutlinedButton(
                        key: Key('recurring-edit-button-${habit.id}'),
                        onPressed: () => onEditRecurringReminder(habit.id),
                        child: const Text('編輯'),
                      ),
                    if (habit.isPending)
                      OutlinedButton(
                        key: Key('recurring-stop-button-${habit.id}'),
                        onPressed: () async {
                          final confirmed =
                              await _confirmRecurringReminderAction(
                                context,
                                title: ReminderUiText.stopHabit,
                                content: '確定要暫停這個習慣嗎？\n這會同時取消目前這個習慣所有未完成任務。',
                              );
                          if (!confirmed) {
                            return;
                          }
                          await repository.stopRecurringReminderById(habit.id);
                        },
                        child: const Text('暫停'),
                      ),
                    if (habit.isPending)
                      FilledButton.tonal(
                        key: Key('recurring-cancel-button-${habit.id}'),
                        onPressed: () async {
                          final confirmed =
                              await _confirmRecurringReminderAction(
                                context,
                                title: ReminderUiText.cancelHabit,
                                content: '確定要取消這個習慣嗎？\n這會同時取消目前這個習慣所有未完成任務。',
                              );
                          if (!confirmed) {
                            return;
                          }
                          await repository.cancelRecurringReminderById(
                            habit.id,
                          );
                        },
                        child: const Text('取消'),
                      ),
                    if (habit.isStopped)
                      FilledButton(
                        key: Key('recurring-reactivate-button-${habit.id}'),
                        onPressed: () async {
                          final reactivation = await _showReactivateDialog(
                            context,
                            habit,
                          );
                          if (reactivation == null) {
                            return;
                          }
                          await repository.reactivateRecurringReminderById(
                            habit.id,
                            dueAt: reactivation.dueAt,
                            startAt: reactivation.startAt,
                          );
                        },
                        child: const Text('啟用'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmRecurringReminderAction(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('否'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('是'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<_RecurringReminderReactivationInput?> _showReactivateDialog(
    BuildContext context,
    RecurringReminderItemViewModel habit,
  ) async {
    final option = await showDialog<_RecurringReminderReactivationOption>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(ReminderUiText.reactivateHabit),
          content: Text(habit.isFixedTime ? '選擇新的固定時間方式。' : '選擇新的開始日期方式。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(
                context,
              ).pop(_RecurringReminderReactivationOption.todayBased),
              child: Text(habit.isFixedTime ? '依今天推算下一次固定時間' : '從今天開始'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pop(_RecurringReminderReactivationOption.manualDate),
              child: Text(habit.isFixedTime ? '重新選擇固定時間' : '重新選擇開始日期'),
            ),
          ],
        );
      },
    );

    if (option == null) {
      return null;
    }
    if (!context.mounted) {
      return null;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (option == _RecurringReminderReactivationOption.todayBased) {
      return habit.isFixedTime
          ? _RecurringReminderReactivationInput(
              dueAt: habit.nextFixedTimeFrom(today),
            )
          : _RecurringReminderReactivationInput(startAt: today);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) {
      return null;
    }

    final normalized = DateTime(picked.year, picked.month, picked.day);
    return habit.isFixedTime
        ? _RecurringReminderReactivationInput(dueAt: normalized)
        : _RecurringReminderReactivationInput(startAt: normalized);
  }
}

enum _RecurringReminderReactivationOption { todayBased, manualDate }

class _RecurringReminderReactivationInput {
  const _RecurringReminderReactivationInput({this.dueAt, this.startAt});

  final DateTime? dueAt;
  final DateTime? startAt;
}
