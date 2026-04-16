import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/history_providers.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  static const routeName = 'history';
  static const routePath = '/history';

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  static const _pageSize = 10;

  int _milestonePage = 0;

  @override
  Widget build(BuildContext context) {
    final milestoneHistoryAsync = ref.watch(milestoneHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(ReminderUiText.historyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            ReminderUiText.responsibilityHistoryTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(ReminderUiText.noResponsibilityHistory),
          const Divider(height: 32),
          const Text(
            ReminderUiText.milestoneHistoryTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          milestoneHistoryAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text(ReminderUiText.noMilestoneHistory);
              }
              final totalPages = _pageCount(items.length);
              final page = min(_milestonePage, totalPages - 1);
              final pageItems = _pageSlice(items, page);
              return Column(
                children: [
                  ...pageItems.map(
                    (item) => ListTile(
                      key: Key('milestone-history-${item.record.id}'),
                      title: Text(item.timeline.title),
                      subtitle: Text(
                        '${ReminderFormatters.milestoneHistory(item)}\n'
                        '${ReminderFormatters.milestoneHistoryUpdatedAt(item)}',
                      ),
                      isThreeLine: true,
                      trailing: const Text('Milestone'),
                    ),
                  ),
                  _PaginationControls(
                    keyPrefix: 'milestone-history',
                    currentPage: page,
                    totalPages: totalPages,
                    onPrevious: () {
                      setState(() {
                        _milestonePage = max(0, page - 1);
                      });
                    },
                    onNext: () {
                      setState(() {
                        _milestonePage = min(totalPages - 1, page + 1);
                      });
                    },
                  ),
                ],
              );
            },
            error: (error, stack) => Text('讀取失敗: $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  int _pageCount(int itemCount) {
    return max(1, (itemCount / _pageSize).ceil());
  }

  List<T> _pageSlice<T>(List<T> items, int page) {
    final start = page * _pageSize;
    final end = min(start + _pageSize, items.length);
    return items.sublist(start, end);
  }
}

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.keyPrefix,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final String keyPrefix;
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('${currentPage + 1} / $totalPages'),
          const SizedBox(width: 12),
          TextButton(
            key: Key('$keyPrefix-prev'),
            onPressed: currentPage == 0 ? null : onPrevious,
            child: const Text(ReminderUiText.previousPageAction),
          ),
          TextButton(
            key: Key('$keyPrefix-next'),
            onPressed: currentPage >= totalPages - 1 ? null : onNext,
            child: const Text(ReminderUiText.nextPageAction),
          ),
        ],
      ),
    );
  }
}
