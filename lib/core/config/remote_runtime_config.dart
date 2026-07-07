enum RemoteRuntimeConfigStatus { missing, placeholder, valid }

class RemoteRuntimeConfigValidationResult {
  const RemoteRuntimeConfigValidationResult({
    required this.status,
    required this.issues,
  });

  final RemoteRuntimeConfigStatus status;
  final List<String> issues;

  bool get isUsable => status == RemoteRuntimeConfigStatus.valid;
}

abstract class RemoteRuntimeConfigSource {
  const RemoteRuntimeConfigSource();

  RemoteRuntimeConfig load();
}

class DartDefineRemoteRuntimeConfigSource extends RemoteRuntimeConfigSource {
  const DartDefineRemoteRuntimeConfigSource();

  static const supabaseUrlDefineName = 'REMINDER_SUPABASE_URL';
  static const supabaseAnonKeyDefineName = 'REMINDER_SUPABASE_ANON_KEY';

  @override
  RemoteRuntimeConfig load() {
    return const RemoteRuntimeConfig(
      supabaseUrl: String.fromEnvironment(supabaseUrlDefineName),
      supabaseAnonKey: String.fromEnvironment(supabaseAnonKeyDefineName),
    );
  }
}

class RemoteRuntimeConfig {
  const RemoteRuntimeConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  RemoteRuntimeConfigValidationResult validate() {
    final issues = <String>[];
    final url = supabaseUrl.trim();
    final anonKey = supabaseAnonKey.trim();

    if (url.isEmpty) {
      issues.add(
        'Missing ${DartDefineRemoteRuntimeConfigSource.supabaseUrlDefineName}.',
      );
    }
    if (anonKey.isEmpty) {
      issues.add(
        'Missing ${DartDefineRemoteRuntimeConfigSource.supabaseAnonKeyDefineName}.',
      );
    }
    if (issues.isNotEmpty) {
      return RemoteRuntimeConfigValidationResult(
        status: RemoteRuntimeConfigStatus.missing,
        issues: List.unmodifiable(issues),
      );
    }

    _addPlaceholderIssues(issues, 'Supabase URL', url);
    _addPlaceholderIssues(issues, 'Supabase anon key', anonKey);
    _addForbiddenValueIssues(issues, 'Supabase URL', url);
    _addForbiddenValueIssues(issues, 'Supabase anon key', anonKey);

    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      issues.add('Supabase URL must be an absolute http or https URL.');
    }

    return RemoteRuntimeConfigValidationResult(
      status: issues.isEmpty
          ? RemoteRuntimeConfigStatus.valid
          : RemoteRuntimeConfigStatus.placeholder,
      issues: List.unmodifiable(issues),
    );
  }

  String redactedSummary() {
    final uri = Uri.tryParse(supabaseUrl.trim());
    final host = uri?.host.isNotEmpty == true ? uri!.host : 'unavailable';
    final anonKeyLength = supabaseAnonKey.trim().length;
    final status = validate().status.name;

    return 'RemoteRuntimeConfig('
        'supabaseUrlHost: $host, '
        'supabaseAnonKeyLength: $anonKeyLength, '
        'status: $status'
        ')';
  }

  static void _addPlaceholderIssues(
    List<String> issues,
    String label,
    String value,
  ) {
    final normalized = value.toLowerCase();
    const markers = [
      'your_',
      'your-',
      'your project',
      'replace_me',
      'replace-me',
      'todo',
      'placeholder',
    ];

    if (markers.any(normalized.contains)) {
      issues.add('$label still contains a placeholder value.');
    }
  }

  static void _addForbiddenValueIssues(
    List<String> issues,
    String label,
    String value,
  ) {
    final normalized = value.toLowerCase();

    if (normalized.contains('service_role')) {
      issues.add('$label must not contain a service role key.');
    }
    if (normalized.contains('database_url') ||
        normalized.startsWith(
          'postgresql'
          '://',
        ) ||
        normalized.startsWith('postgres://')) {
      issues.add('$label must not contain a database connection string.');
    }
    if (normalized.contains('access_token') ||
        normalized.contains('refresh_token') ||
        normalized.contains('provider_token') ||
        normalized.startsWith('bearer ')) {
      issues.add('$label must not contain runtime credential tokens.');
    }
  }
}
