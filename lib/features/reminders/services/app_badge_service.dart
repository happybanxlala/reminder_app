import 'dart:async';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';

import '../domain/attention_summary.dart';

abstract class AppBadgeClient {
  Future<bool> isSupported();

  Future<void> updateBadge(int count);
}

class AppBadgeService {
  AppBadgeService({required AppBadgeClient client}) : _client = client;

  final AppBadgeClient _client;

  Future<void> syncBadge(AttentionSummary summary) async {
    try {
      final isSupported = await _client.isSupported();
      if (!isSupported) {
        return;
      }
      await _client.updateBadge(summary.totalCount);
    } catch (error) {
      debugPrint('badge update skipped: $error');
    }
  }
}

class AppBadgePlusClient implements AppBadgeClient {
  @override
  Future<bool> isSupported() async {
    return AppBadgePlus.isSupported();
  }

  @override
  Future<void> updateBadge(int count) async {
    await Future.sync(() => AppBadgePlus.updateBadge(count));
  }
}
