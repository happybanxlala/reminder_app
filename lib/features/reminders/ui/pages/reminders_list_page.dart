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
  int _pendingSession = 0;

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
      _resetPendingSession();
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      return;
    }
    if (_tabController.index != 0) {
      _resetPendingSession();
    }
  }

  void _resetPendingSession() {
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingSession++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(activePendingProvider);
    final historyAsync = ref.watch(completedOrSkippedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        bottom: TabBar(
          controller: _tabController,
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
              key: ValueKey('pending-session-$_pendingSession'),
              items: items,
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
        onPressed: () {
          _resetPendingSession();
          context.pushNamed(ReminderEditPage.newRouteName);
        },
        icon: const Icon(Icons.add),
        label: const Text('新增'),
      ),
    );
  }
}

class _PendingList extends ConsumerStatefulWidget {
  const _PendingList({super.key, required this.items});

  final List<ReminderModel> items;

  @override
  ConsumerState<_PendingList> createState() => _PendingListState();
}

class _PendingListState extends ConsumerState<_PendingList> {
  final Map<int, ReminderModel> _recentDone = <int, ReminderModel>{};

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && _recentDone.isEmpty) {
      return const Center(child: Text('目前沒有進行中的提醒。'));
    }

    final repository = ref.read(reminderRepositoryProvider);
    final rows = <Widget>[
      ...widget.items.map(
        (reminder) => PendingReminderTile(
          reminder: reminder,
          remainingLabel: _remainingLabel(reminder),
          onToggleDone: () async {
            setState(() {
              _recentDone[reminder.id] = reminder;
            });
            await repository.complete(reminder.id);
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
          onLongPress: () {
            context.pushNamed(
              ReminderEditPage.editRouteName,
              pathParameters: {'id': reminder.id.toString()},
            );
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
              await repository.restore(reminder.id);
              if (!mounted) {
                return;
              }
              setState(() {
                _recentDone.remove(reminder.id);
              });
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
    if (item.dueAt == null) {
      return '無到期時間';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(item.dueAt!.year, item.dueAt!.month, item.dueAt!.day);
    final diff = due.difference(today).inDays;

    if (diff > 0) {
      return '剩餘 $diff 天';
    }
    if (diff == 0) {
      return '今天到期';
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
