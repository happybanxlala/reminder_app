import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  const SupabaseConfig.fromEnvironment()
    : url = const String.fromEnvironment('SUPABASE_URL'),
      anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

  const SupabaseConfig.disabled() : url = '', anonKey = '';

  final String url;
  final String anonKey;

  bool get isConfigured => url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
}

enum SupabaseRuntimeStatus { configured, missingConfig, initializationFailed }

class SupabaseRuntime {
  const SupabaseRuntime({
    required this.config,
    required this.status,
    this.client,
    this.error,
  });

  const SupabaseRuntime.missingConfig()
    : config = const SupabaseConfig.disabled(),
      status = SupabaseRuntimeStatus.missingConfig,
      client = null,
      error = null;

  final SupabaseConfig config;
  final SupabaseRuntimeStatus status;
  final SupabaseClient? client;
  final Object? error;

  bool get isAvailable =>
      status == SupabaseRuntimeStatus.configured && client != null;
}

SupabaseRuntime _currentReminderSupabaseRuntime =
    const SupabaseRuntime.missingConfig();

SupabaseRuntime currentReminderSupabaseRuntime() {
  return _currentReminderSupabaseRuntime;
}

Future<SupabaseRuntime> initializeReminderSupabase({
  SupabaseConfig config = const SupabaseConfig.fromEnvironment(),
}) async {
  if (!config.isConfigured) {
    _currentReminderSupabaseRuntime = SupabaseRuntime(
      config: config,
      status: SupabaseRuntimeStatus.missingConfig,
    );
    return _currentReminderSupabaseRuntime;
  }

  try {
    final supabase = await Supabase.initialize(
      url: config.url,
      publishableKey: config.anonKey,
    );
    _currentReminderSupabaseRuntime = SupabaseRuntime(
      config: config,
      status: SupabaseRuntimeStatus.configured,
      client: supabase.client,
    );
  } catch (error) {
    _currentReminderSupabaseRuntime = SupabaseRuntime(
      config: config,
      status: SupabaseRuntimeStatus.initializationFailed,
      error: error,
    );
  }
  return _currentReminderSupabaseRuntime;
}
