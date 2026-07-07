enum AccountBindingStatus {
  unbound,
  binding,
  bound,
  bindingFailed,
  needsReauth,
}

class AccountIdentity {
  factory AccountIdentity({
    required String accountId,
    String? displayLabel,
    String? providerLabel,
    DateTime? boundAt,
    DateTime? lastVerifiedAt,
  }) {
    final normalizedAccountId = accountId.trim();
    if (normalizedAccountId.isEmpty) {
      throw ArgumentError.value(accountId, 'accountId', 'Must not be empty.');
    }
    if (_looksLikeSecret(normalizedAccountId)) {
      throw ArgumentError.value(
        accountId,
        'accountId',
        'Must be a stable non-secret account identifier.',
      );
    }

    return AccountIdentity._(
      accountId: normalizedAccountId,
      displayLabel: _safeOptionalLabel(displayLabel),
      providerLabel: _safeOptionalLabel(providerLabel),
      boundAt: boundAt,
      lastVerifiedAt: lastVerifiedAt,
    );
  }

  const AccountIdentity._({
    required this.accountId,
    this.displayLabel,
    this.providerLabel,
    this.boundAt,
    this.lastVerifiedAt,
  });

  final String accountId;
  final String? displayLabel;
  final String? providerLabel;
  final DateTime? boundAt;
  final DateTime? lastVerifiedAt;

  static String? _safeOptionalLabel(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (_looksLikeSecret(normalized)) {
      throw ArgumentError.value(value, 'label', 'Must not contain secrets.');
    }
    return normalized;
  }

  static bool _looksLikeSecret(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('access_token') ||
        normalized.contains('refresh_token') ||
        normalized.contains('provider_token') ||
        normalized.contains('service_role') ||
        normalized.contains('database_url') ||
        normalized.startsWith(
          'postgresql'
          '://',
        ) ||
        normalized.startsWith('postgres://') ||
        normalized.startsWith('bearer ') ||
        normalized.contains('anon_key');
  }
}

class AccountIdentitySnapshot {
  factory AccountIdentitySnapshot({
    required AccountBindingStatus status,
    AccountIdentity? identity,
    String? failureMessage,
    DateTime? updatedAt,
  }) {
    switch (status) {
      case AccountBindingStatus.unbound:
      case AccountBindingStatus.binding:
      case AccountBindingStatus.bindingFailed:
        if (identity != null) {
          throw ArgumentError.value(
            identity,
            'identity',
            '$status snapshot must not include account identity.',
          );
        }
        break;
      case AccountBindingStatus.bound:
        if (identity == null) {
          throw ArgumentError.notNull('identity');
        }
        break;
      case AccountBindingStatus.needsReauth:
        break;
    }

    return AccountIdentitySnapshot._(
      status: status,
      identity: identity,
      failureMessage: _safeFailureMessage(failureMessage),
      updatedAt: updatedAt,
    );
  }

  factory AccountIdentitySnapshot.unbound({DateTime? updatedAt}) {
    return AccountIdentitySnapshot(
      status: AccountBindingStatus.unbound,
      updatedAt: updatedAt,
    );
  }

  factory AccountIdentitySnapshot.bound({
    required AccountIdentity identity,
    DateTime? updatedAt,
  }) {
    return AccountIdentitySnapshot(
      status: AccountBindingStatus.bound,
      identity: identity,
      updatedAt: updatedAt,
    );
  }

  const AccountIdentitySnapshot._({
    required this.status,
    this.identity,
    this.failureMessage,
    this.updatedAt,
  });

  final AccountBindingStatus status;
  final AccountIdentity? identity;
  final String? failureMessage;
  final DateTime? updatedAt;

  bool get canProvideIdentityForRemoteWrites =>
      status == AccountBindingStatus.bound && identity != null;

  static String? _safeFailureMessage(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (AccountIdentity._looksLikeSecret(normalized)) {
      throw ArgumentError.value(
        value,
        'failureMessage',
        'Must not contain secrets.',
      );
    }
    return normalized;
  }
}
