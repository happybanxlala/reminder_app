import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/auth_repository.dart';
import 'package:reminder_app/features/reminders/data/supabase_config.dart';
import 'package:reminder_app/features/reminders/providers/identity_providers.dart';

void main() {
  test('missing config is safe and produces disabled auth repository', () {
    const runtime = SupabaseRuntime.missingConfig();
    final container = ProviderContainer(
      overrides: [supabaseRuntimeProvider.overrideWithValue(runtime)],
    );
    addTearDown(container.dispose);

    expect(runtime.config.isConfigured, isFalse);
    expect(container.read(supabaseRuntimeStatusProvider), runtime.status);
    expect(
      container.read(authRepositoryProvider),
      isA<DisabledAuthRepository>(),
    );
  });

  test(
    'configured values can be represented without initializing Supabase',
    () {
      const config = SupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon-key',
      );
      final runtime = SupabaseRuntime(
        config: config,
        status: SupabaseRuntimeStatus.initializationFailed,
        error: StateError('not initialized in test'),
      );
      final container = ProviderContainer(
        overrides: [supabaseRuntimeProvider.overrideWithValue(runtime)],
      );
      addTearDown(container.dispose);

      expect(config.isConfigured, isTrue);
      expect(
        container.read(authRepositoryProvider),
        isA<DisabledAuthRepository>(),
      );
    },
  );

  test('auth repository can be overridden with fake auth', () async {
    final fake = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final identity = await container
        .read(authRepositoryProvider)
        .signInAnonymously();

    expect(identity.provider.name, 'supabaseAnonymous');
    expect(identity.isAnonymous, isTrue);
  });
}
