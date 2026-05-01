import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/attention_summary.dart';

abstract class ReminderNotificationClient {
  Future<void> initialize({
    required DidReceiveNotificationResponseCallback
    onDidReceiveNotificationResponse,
  });

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
  });

  Future<void> cancel(int id);

  Future<void> requestPermissions();
}

abstract class LocalTimeZoneResolver {
  Future<String?> getLocalTimeZoneName();
}

class ReminderNotificationService {
  ReminderNotificationService({
    required ReminderNotificationClient client,
    required LocalTimeZoneResolver timeZoneResolver,
    DateTime Function()? clock,
  }) : _client = client,
       _timeZoneResolver = timeZoneResolver,
       _clock = clock ?? DateTime.now;

  static const attentionNotificationId = 9001;
  static const attentionPayload = 'home';

  final ReminderNotificationClient _client;
  final LocalTimeZoneResolver _timeZoneResolver;
  final DateTime Function() _clock;

  bool _isInitialized = false;

  Future<void> initialize({required VoidCallback onOpenHome}) async {
    if (_isInitialized) {
      return;
    }

    tz_data.initializeTimeZones();
    try {
      final timeZoneName = await _timeZoneResolver.getLocalTimeZoneName();
      if (timeZoneName != null && timeZoneName.isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      }
    } catch (error) {
      debugPrint('notification timezone init skipped: $error');
    }

    await _client.initialize(
      onDidReceiveNotificationResponse: (_) => onOpenHome(),
    );
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    if (!_isInitialized) {
      return;
    }
    await _client.requestPermissions();
  }

  Future<void> syncDailyNotification(AttentionSummary summary) async {
    if (!_isInitialized) {
      return;
    }

    if (!summary.hasAttention) {
      await _client.cancel(attentionNotificationId);
      return;
    }

    await _client.schedule(
      id: attentionNotificationId,
      title: '今天有 ${summary.totalCount} 件事需要處理',
      body: '打開看看哪些事情需要留意',
      scheduledDate: _nextNineAm(),
      payload: attentionPayload,
    );
  }

  tz.TZDateTime _nextNineAm() {
    final now = tz.TZDateTime.from(_clock(), tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

class FlutterReminderNotificationClient implements ReminderNotificationClient {
  FlutterReminderNotificationClient({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'daily_attention';
  static const _channelName = 'Daily Attention';
  static const _channelDescription = 'Daily reminder attention summary';

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize({
    required DidReceiveNotificationResponseCallback
    onDidReceiveNotificationResponse,
  }) async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
  }) {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) {
    return _plugin.cancel(id: id);
  }

  @override
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return;
    }

    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }
}

class FlutterLocalTimeZoneResolver implements LocalTimeZoneResolver {
  @override
  Future<String?> getLocalTimeZoneName() async {
    final timeZone = await FlutterTimezone.getLocalTimezone();
    return timeZone.identifier;
  }
}
