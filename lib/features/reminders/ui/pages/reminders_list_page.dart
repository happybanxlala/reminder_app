import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/reminder_repository.dart';
import '../../domain/reminder.dart';
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
  final GlobalKey<_PendingListState> _pendingListKey = GlobalKey<_PendingListState>();
  bool _isFlushingPending = false;
  int _stagedPendingCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
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
    if (_tabController.index != 0) {
      unawaited(_commitAndResetPendingSession());
    }
  }

  Future<void> _commitAndResetPendingSession() async {
    await _flushPendingCompletions();
  }

  Future<void> _flushPendingCompletions() async {
    if (_isFlushingPending) {
      return;
    }
    final pendingListState = _pendingListKey.currentState;
    if (pendingListState == null) {
      return;
    }

    final stagedIds = pendingListState.stagedReminderIds;
    if (stagedIds.isEmpty) {
      pendingListState.clearStaged();
      return;
    }

    _isFlushingPending = true;
    if (mounted) {
      setState(() {});
    }
    try {
      await ref.read(reminderRepositoryProvider).commitStagedCompletions(stagedIds);
      if (mounted) {
        pendingListState.clearStaged();
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
    final pendingAsync = ref.watch(activePendingProvider);
    final historyAsync = ref.watch(completedOrSkippedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          if (_tabController.index == 0 && _stagedPendingCount > 0)
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
            if (index != 0) {
              unawaited(_commitAndResetPendingSession());
            }
          },
          tabs: const [
            Tab(text: '進行中'),
            Tab(text: '完成/跳過'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          pendingAsync.when(
            data: (items) => _PendingList(
              key: _pendingListKey,
              items: items,
              onStagedChanged: (count) {
                if (!mounted || _stagedPendingCount == count) {
                  return;
                }
                setState(() {
                  _stagedPendingCount = count;
                });
              },
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
            data: (items) => _HistoryList(items: items),
            error: (error, stack) => Center(child: Text('讀取失敗: $error')),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _commitAndResetPendingSession();
          if (!context.mounted) {
            return;
          }
          context.pushNamed(ReminderEditPage.newRouteName);
        },
        icon: const Icon(Icons.add),
        label: const Text('新增'),
      ),
    );
  }
}

class _PendingList extends ConsumerStatefulWidget {
  const _PendingList({
    super.key,
    required this.items,
    required this.onStagedChanged,
    required this.onEditReminder,
  });

  final List<ReminderModel> items;
  final ValueChanged<int> onStagedChanged;
  final Future<void> Function(int reminderId) onEditReminder;

  @override
  ConsumerState<_PendingList> createState() => _PendingListState();
}

class _PendingListState extends ConsumerState<_PendingList> {
  final Map<int, ReminderModel> _recentDone = <int, ReminderModel>{};

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
      return const Center(child: Text('目前沒有進行中的提醒。'));
    }

    final repository = ref.read(reminderRepositoryProvider);
    final visibleItems = widget.items
        .where((item) => !_recentDone.containsKey(item.id))
        .toList(growable: false);

    final rows = <Widget>[
      ...visibleItems.map(
        (reminder) => PendingReminderTile(
          reminder: reminder,
          remainingLabel: _remainingLabel(reminder),
          onToggleDone: () async {
            setState(() {
              _recentDone[reminder.id] = reminder;
            });
            widget.onStagedChanged(_recentDone.length);
          },
          onSkip: () async {
            await repository.skip(reminder.id);
          },
          onCancel: () async {
            final confirmed = await _confirmCancel(context);
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
            reminder: reminder,
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

  String _remainingLabel(ReminderModel item) {
    if (item.isCountUp) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final start = DateTime(item.startAt.year, item.startAt.month, item.startAt.day);
      final accumulated = today.difference(start).inDays;
      if (accumulated <= 0) {
        return '今天起計';
      }
      return '已累積 $accumulated 天';
    }

    if (item.dueAt == null) {
      return '未設定到期時間';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(item.dueAt!.year, item.dueAt!.month, item.dueAt!.day);
    final diff = due.difference(today).inDays;

    if (diff > 0) {
      return '剩餘 $diff 天';
    }
    if (diff == 0) {
      final endOfDueDay = due.add(const Duration(days: 1));
      final remainingHours = endOfDueDay.difference(now).inHours;
      final safeHours = remainingHours <= 0 ? 1 : remainingHours;
      return '剩餘 $safeHours 小時';
    }
    return '逾期 ${diff.abs()} 天';
  }

  Future<bool> _confirmCancel(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('取消提醒'),
          content: const Text('確定要取消這筆提醒嗎？'),
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
          title: const Text('恢復未完成'),
          content: const Text('確定要把這筆提醒恢復為未完成嗎？'),
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
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.items});

  final List<ReminderModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('目前沒有完成或跳過的提醒。'));
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '僅顯示近期 30 筆資料',
              style: TextStyle(color: Colors.grey),
            ),
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
