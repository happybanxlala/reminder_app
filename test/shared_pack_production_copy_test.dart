import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production shared sync copy avoids old remote wording', () {
    const productionFiles = [
      'lib/features/reminders/data/attention_summary_repository.dart',
      'lib/features/home_widget/application/home_widget_snapshot_service.dart',
      'lib/features/reminders/providers/shared_pack_care_providers.dart',
      'lib/features/reminders/providers/remote_backed_sync_coordinator.dart',
      'lib/features/reminders/presentation/sync_status_label.dart',
      'lib/features/reminders/ui/pages/feature_management_items.dart',
      'lib/features/reminders/ui/pages/feature_management_resources.dart',
      'lib/features/reminders/ui/pages/feature_page_activity.dart',
      'lib/features/reminders/ui/pages/feature_page_packs.dart',
      'lib/features/reminders/ui/pages/home_page.dart',
      'lib/features/reminders/ui/pages/stage_tracker_detail.dart',
      'lib/features/reminders/ui/pages/stage_tracker_management.dart',
    ];

    final source = productionFiles
        .map((path) => File(path).readAsStringSync())
        .join('\n');

    expect(source, contains('有新的更新，請刷新'));
    expect(source, contains('已無法存取'));
    expect(source, isNot(contains('遠端狀態可能已更新')));
    expect(source, isNot(contains('已失去遠端存取權')));
    expect(source, isNot(contains('Remote-backed Pack POC')));
    expect(source, isNot(contains('Supabase 遠端 POC')));
  });
}
