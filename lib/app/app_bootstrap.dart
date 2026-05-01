import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/reminders/domain/attention_summary.dart';
import '../features/reminders/providers/attention_service_providers.dart';
import '../features/reminders/providers/attention_summary_providers.dart';
import '../features/reminders/ui/pages/home_page.dart';
import 'router.dart';

class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap>
    with WidgetsBindingObserver {
  ProviderSubscription<AsyncValue<AttentionSummary>>? _summarySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final syncService = ref.read(attentionSyncServiceProvider);
    final router = ref.read(appRouterProvider);

    _summarySubscription = ref.listenManual<AsyncValue<AttentionSummary>>(
      liveAttentionSummaryProvider,
      (previous, next) {
        next.whenData((summary) {
          unawaited(syncService.syncSummary(summary));
        });
      },
    );

    await syncService.initialize(
      onOpenHome: () => router.go(HomePage.routePath),
    );
    await syncService.refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(attentionSyncServiceProvider).refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _summarySubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
