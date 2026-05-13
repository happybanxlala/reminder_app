import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../providers/resource_providers.dart';

class ResourceHistoryPage extends ConsumerWidget {
  const ResourceHistoryPage({super.key, required this.resourceId});

  static const routeName = 'resource-history';
  static const routePath = '/resource/:id/history';

  final int resourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourceAsync = ref.watch(resourceProvider(resourceId));
    final historyAsync = ref.watch(resourceActionHistoryProvider(resourceId));

    final title = resourceAsync.valueOrNull?.resource.title;
    return Scaffold(
      appBar: AppBar(title: Text(title == null ? '資源歷史紀錄' : '$title · 資源歷史紀錄')),
      body: historyAsync.when(
        data: (records) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (records.isEmpty)
              const Text('目前沒有資源歷史紀錄。')
            else
              ...records.map(
                (record) => ListTile(
                  key: Key('resource-history-${record.id}'),
                  title: Text(ReminderFormatters.resourceActionRecord(record)),
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
