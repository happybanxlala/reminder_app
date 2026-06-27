enum RemotePackFreshnessStatus {
  upToDate,
  possiblyStale,
  noSyncReport,
  accessUnknown,
}

class RemotePackMemberFreshness {
  const RemotePackMemberFreshness({
    required this.remoteUserId,
    this.displayName,
    required this.role,
    required this.memberStatus,
    required this.status,
    this.latestActivityEventId,
    this.latestActivityAt,
    this.lastImportedAt,
    this.lastSeenActivityEventId,
    this.lastSeenActivityAt,
  });

  final String remoteUserId;
  final String? displayName;
  final String role;
  final String memberStatus;
  final RemotePackFreshnessStatus status;
  final String? latestActivityEventId;
  final DateTime? latestActivityAt;
  final DateTime? lastImportedAt;
  final String? lastSeenActivityEventId;
  final DateTime? lastSeenActivityAt;
}

enum RemotePackSnapshotReportStatus {
  reported,
  notMember,
  accessDenied,
  configMissing,
  remoteAuthRequired,
  networkFailed,
  unknownFailure,
}

class RemotePackSnapshotReportResult {
  const RemotePackSnapshotReportResult({required this.status, this.message});

  final RemotePackSnapshotReportStatus status;
  final String? message;

  bool get succeeded => status == RemotePackSnapshotReportStatus.reported;
}

enum RemotePackFreshnessQueryStatus {
  loaded,
  notMember,
  accessDenied,
  configMissing,
  remoteAuthRequired,
  networkFailed,
  unknownFailure,
}

class RemotePackFreshnessQueryResult {
  const RemotePackFreshnessQueryResult({
    required this.status,
    this.members = const [],
    this.message,
  });

  final RemotePackFreshnessQueryStatus status;
  final List<RemotePackMemberFreshness> members;
  final String? message;

  bool get succeeded => status == RemotePackFreshnessQueryStatus.loaded;
}
