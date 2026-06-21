import 'package:supabase_flutter/supabase_flutter.dart';

import 'remote_shared_pack_models.dart';
import 'supabase_config.dart';

class RemotePackChangeSignal {
  const RemotePackChangeSignal({
    required this.remotePackId,
    this.activityEventId,
    this.action,
    this.entityType,
    this.actorUserId,
    this.createdAt,
    required this.receivedAt,
  });

  final String remotePackId;
  final String? activityEventId;
  final String? action;
  final String? entityType;
  final String? actorUserId;
  final DateTime? createdAt;
  final DateTime receivedAt;
}

abstract class RemotePackChangeSubscription {
  String get remotePackId;
  bool get isActive;
  Future<void> unsubscribe();
}

abstract class RemoteSharedPackRealtimeDataSource {
  RemotePackChangeSubscription subscribeToRemotePackChanges({
    required String remotePackId,
    required void Function(RemotePackChangeSignal signal) onSignal,
    required void Function(Object error) onError,
    required void Function() onSubscribed,
  });
}

class DisabledRemoteSharedPackRealtimeDataSource
    implements RemoteSharedPackRealtimeDataSource {
  const DisabledRemoteSharedPackRealtimeDataSource(this.reason);

  final RemoteSharedPackFailureReason reason;

  @override
  RemotePackChangeSubscription subscribeToRemotePackChanges({
    required String remotePackId,
    required void Function(RemotePackChangeSignal signal) onSignal,
    required void Function(Object error) onError,
    required void Function() onSubscribed,
  }) {
    onError(RemoteSharedPackException(reason));
    return _NoopRemotePackChangeSubscription(remotePackId);
  }
}

class SupabaseRemoteSharedPackRealtimeDataSource
    implements RemoteSharedPackRealtimeDataSource {
  const SupabaseRemoteSharedPackRealtimeDataSource(this._runtime);

  final SupabaseRuntime _runtime;

  SupabaseClient get _client {
    final client = _runtime.client;
    if (client == null) {
      final reason = _runtime.status == SupabaseRuntimeStatus.missingConfig
          ? RemoteSharedPackFailureReason.supabaseConfigMissing
          : RemoteSharedPackFailureReason.remoteNetworkFailed;
      throw RemoteSharedPackException(reason, _runtime.error);
    }
    return client;
  }

  @override
  RemotePackChangeSubscription subscribeToRemotePackChanges({
    required String remotePackId,
    required void Function(RemotePackChangeSignal signal) onSignal,
    required void Function(Object error) onError,
    required void Function() onSubscribed,
  }) {
    try {
      final client = _client;
      final channel = client.channel('remote-pack-activity-$remotePackId');
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'activity_events',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'pack_id',
              value: remotePackId,
            ),
            callback: (payload) {
              try {
                onSignal(_signalFromRecord(payload.newRecord));
              } catch (error) {
                onError(error);
              }
            },
          )
          .subscribe((status, error) {
            switch (status) {
              case RealtimeSubscribeStatus.subscribed:
                onSubscribed();
              case RealtimeSubscribeStatus.channelError:
              case RealtimeSubscribeStatus.timedOut:
              case RealtimeSubscribeStatus.closed:
                onError(
                  error ??
                      RemoteSharedPackException(
                        RemoteSharedPackFailureReason.remoteNetworkFailed,
                      ),
                );
            }
          });
      return _SupabaseRemotePackChangeSubscription(
        remotePackId: remotePackId,
        client: client,
        channel: channel,
      );
    } catch (error) {
      onError(error);
      return _NoopRemotePackChangeSubscription(remotePackId);
    }
  }
}

class _SupabaseRemotePackChangeSubscription
    implements RemotePackChangeSubscription {
  _SupabaseRemotePackChangeSubscription({
    required this.remotePackId,
    required SupabaseClient client,
    required RealtimeChannel channel,
  }) : _client = client,
       _channel = channel;

  @override
  final String remotePackId;
  final SupabaseClient _client;
  final RealtimeChannel _channel;
  bool _isActive = true;

  @override
  bool get isActive => _isActive;

  @override
  Future<void> unsubscribe() async {
    if (!_isActive) {
      return;
    }
    _isActive = false;
    await _client.removeChannel(_channel);
  }
}

class _NoopRemotePackChangeSubscription
    implements RemotePackChangeSubscription {
  _NoopRemotePackChangeSubscription(this.remotePackId);

  @override
  final String remotePackId;
  bool _isActive = false;

  @override
  bool get isActive => _isActive;

  @override
  Future<void> unsubscribe() async {
    _isActive = false;
  }
}

RemotePackChangeSignal _signalFromRecord(Map<String, dynamic> row) {
  return RemotePackChangeSignal(
    remotePackId: _requiredString(row, 'pack_id'),
    activityEventId: _optionalString(row, 'id'),
    action: _optionalString(row, 'action'),
    entityType: _optionalString(row, 'entity_type'),
    actorUserId: _optionalString(row, 'actor_user_id'),
    createdAt: _optionalDate(row, 'created_at'),
    receivedAt: DateTime.now(),
  );
}

String _requiredString(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw const RemoteSharedPackException(
    RemoteSharedPackFailureReason.malformedRemoteData,
  );
}

String? _optionalString(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
}

DateTime? _optionalDate(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  throw const RemoteSharedPackException(
    RemoteSharedPackFailureReason.malformedRemoteData,
  );
}
