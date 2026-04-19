import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/item_providers.dart';

class ItemHistoryPage extends ConsumerWidget {
  const ItemHistoryPage({super.key, required this.itemId});

  static const routeName = 'item-history';
  static const routePath = '/item/:id/history';

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemProvider(itemId));
    final historyAsync = ref.watch(itemActionHistoryProvider(itemId));

    final title = itemAsync.valueOrNull?.item.title;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title == null
              ? ReminderUiText.itemHistoryTitle
              : '$title · ${ReminderUiText.itemHistoryTitle}',
        ),
      ),
      body: historyAsync.when(
        data: (records) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (records.isEmpty)
              const Text(ReminderUiText.noItemHistory)
            else
              ...records.map(
                (record) => ListTile(
                  key: Key('item-history-${record.id}'),
                  title: Text(ReminderFormatters.itemActionRecord(record)),
                  subtitle: Text(
                    '${ReminderUiText.updatedAtLabel}：${ReminderFormatters.dateTime(record.updatedAt)}',
                  ),
                ),
              ),
          ],
        ),
        error: (error, stack) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('讀取失敗: $error'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
