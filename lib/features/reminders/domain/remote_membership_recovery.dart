enum RemoteMembershipRecoveryStatus {
  restored,
  partiallyRecovered,
  nothingToRecover,
  accountNotProtected,
  remoteSessionMissing,
  remoteAuthRequired,
  configMissing,
  accessDenied,
  networkFailed,
  importFailed,
  unknownFailure,
}

class RemoteMembershipRecoverySummary {
  const RemoteMembershipRecoverySummary({
    required this.discoveredCount,
    required this.eligibleCount,
    required this.createdLocalMirrorCount,
    required this.refreshedExistingCount,
    required this.skippedCount,
    required this.archivedSkippedCount,
    required this.failedCount,
    this.restoredLocalPackIds = const [],
    this.warnings = const [],
  });

  final int discoveredCount;
  final int eligibleCount;
  final int createdLocalMirrorCount;
  final int refreshedExistingCount;
  final int skippedCount;
  final int archivedSkippedCount;
  final int failedCount;
  final List<int> restoredLocalPackIds;
  final List<String> warnings;

  int get importedCount => createdLocalMirrorCount;

  int get updatedCount => refreshedExistingCount;

  bool get hasImportedAny =>
      createdLocalMirrorCount + refreshedExistingCount > 0;
}

class RemoteMembershipRecoveryResult {
  const RemoteMembershipRecoveryResult({
    required this.status,
    required this.summary,
    required this.message,
  });

  final RemoteMembershipRecoveryStatus status;
  final RemoteMembershipRecoverySummary summary;
  final String message;

  bool get succeeded =>
      status == RemoteMembershipRecoveryStatus.restored ||
      status == RemoteMembershipRecoveryStatus.partiallyRecovered;
}
