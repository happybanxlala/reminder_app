enum RemoteBackedPackRefreshStatus {
  refreshed,
  notRemoteBacked,
  missingRemoteMapping,
  configMissing,
  remoteAuthRequired,
  remoteRlsRejected,
  accessLost,
  networkFailed,
  importFailed,
  partialImport,
  hasPendingLocalMutations,
  unknownFailure,
}

class RemoteBackedPackRefreshSummary {
  const RemoteBackedPackRefreshSummary({
    required this.localPackId,
    this.remotePackId,
    this.importedItemCount = 0,
    this.updatedItemCount = 0,
    this.importedCompletionCount = 0,
    this.updatedCompletionCount = 0,
    this.importedActivityCount = 0,
    this.updatedActivityCount = 0,
    this.hasPendingLocalMutations = false,
    this.pendingMutationCount = 0,
    this.failedMutationCount = 0,
    this.staleBeforeRefresh = false,
    this.staleAfterRefresh = false,
    this.warnings = const [],
  });

  final int localPackId;
  final String? remotePackId;
  final int importedItemCount;
  final int updatedItemCount;
  final int importedCompletionCount;
  final int updatedCompletionCount;
  final int importedActivityCount;
  final int updatedActivityCount;
  final bool hasPendingLocalMutations;
  final int pendingMutationCount;
  final int failedMutationCount;
  final bool staleBeforeRefresh;
  final bool staleAfterRefresh;
  final List<String> warnings;

  int get importedCount =>
      importedItemCount + importedCompletionCount + importedActivityCount;

  int get updatedCount =>
      updatedItemCount + updatedCompletionCount + updatedActivityCount;
}

class RemoteBackedPackRefreshResult {
  const RemoteBackedPackRefreshResult({
    required this.status,
    required this.summary,
    this.message,
  });

  final RemoteBackedPackRefreshStatus status;
  final RemoteBackedPackRefreshSummary summary;
  final String? message;

  bool get succeeded =>
      status == RemoteBackedPackRefreshStatus.refreshed ||
      status == RemoteBackedPackRefreshStatus.partialImport ||
      status == RemoteBackedPackRefreshStatus.hasPendingLocalMutations;
}
