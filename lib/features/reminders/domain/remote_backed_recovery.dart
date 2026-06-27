import 'remote_sync.dart';

enum RemoteBackedRecoveryState {
  pending,
  syncing,
  synced,
  retryableFailed,
  nonRetryableFailed,
  noOp,
  conflict,
  cancelled,
  stale,
  accessLost,
}

enum RemoteBackedMutationRecoveryKind {
  none,
  waitingSync,
  retryableFailure,
  nonRetryableFailure,
  needsRefresh,
  accessLost,
  terminal,
}

enum RemoteBackedSyncProblem {
  none,
  waitingSync,
  retryableFailure,
  nonRetryableFailure,
  needsRefresh,
  accessLost,
}

enum RemoteBackedRecoveryResult {
  retried,
  synced,
  failed,
  skipped,
  noOp,
  accessLost,
  missingMapping,
}

class RemoteBackedMutationRecoveryView {
  const RemoteBackedMutationRecoveryView({
    required this.mutationId,
    required this.localPackId,
    this.localItemId,
    this.localEntityId,
    this.remoteItemId,
    required this.actionType,
    required this.status,
    required this.recoveryState,
    required this.recoveryKind,
    required this.problem,
    required this.canRetry,
    required this.needsRefresh,
    this.lastError,
  });

  final int mutationId;
  final int localPackId;
  final int? localItemId;
  final int? localEntityId;
  final String? remoteItemId;
  final SyncOutboxActionType actionType;
  final SyncOutboxStatus status;
  final RemoteBackedRecoveryState recoveryState;
  final RemoteBackedMutationRecoveryKind recoveryKind;
  final RemoteBackedSyncProblem problem;
  final bool canRetry;
  final bool needsRefresh;
  final String? lastError;

  String? get shortRemoteItemId =>
      RemoteBackedRecoveryClassifier.shortId(remoteItemId);
}

class RemoteBackedRetryMutationResult {
  const RemoteBackedRetryMutationResult({
    required this.mutationId,
    required this.actionType,
    required this.result,
    required this.beforeStatus,
    required this.afterStatus,
    this.localPackId,
    this.localItemId,
    this.remoteItemId,
    this.message,
  });

  final int mutationId;
  final SyncOutboxActionType actionType;
  final RemoteBackedRecoveryResult result;
  final SyncOutboxStatus beforeStatus;
  final SyncOutboxStatus afterStatus;
  final int? localPackId;
  final int? localItemId;
  final String? remoteItemId;
  final String? message;

  bool get succeeded =>
      result == RemoteBackedRecoveryResult.synced ||
      result == RemoteBackedRecoveryResult.noOp;
}

class RemoteBackedRetrySummary {
  const RemoteBackedRetrySummary({
    this.processedCount = 0,
    this.retriedCount = 0,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.noOpCount = 0,
    this.skippedCount = 0,
    this.accessLostCount = 0,
    this.needsRefreshCount = 0,
    this.results = const [],
  });

  final int processedCount;
  final int retriedCount;
  final int syncedCount;
  final int failedCount;
  final int noOpCount;
  final int skippedCount;
  final int accessLostCount;
  final int needsRefreshCount;
  final List<RemoteBackedRetryMutationResult> results;

  bool get hasRetried => retriedCount > 0;

  bool get hasFailure => failedCount > 0 || accessLostCount > 0;
}

class RemoteBackedPackRecoverySummary {
  const RemoteBackedPackRecoverySummary({
    required this.localPackId,
    this.pendingCount = 0,
    this.syncingCount = 0,
    this.retryableFailedCount = 0,
    this.nonRetryableFailedCount = 0,
    this.noOpCount = 0,
    this.conflictCount = 0,
    this.accessLostCount = 0,
    this.stalePackCount = 0,
    this.firstFailedMutation,
  });

  final int localPackId;
  final int pendingCount;
  final int syncingCount;
  final int retryableFailedCount;
  final int nonRetryableFailedCount;
  final int noOpCount;
  final int conflictCount;
  final int accessLostCount;
  final int stalePackCount;
  final RemoteBackedMutationRecoveryView? firstFailedMutation;

  bool get hasRetryableFailures => retryableFailedCount > 0;

  int get totalProblems =>
      pendingCount +
      syncingCount +
      retryableFailedCount +
      nonRetryableFailedCount +
      noOpCount +
      conflictCount +
      accessLostCount +
      stalePackCount;
}

class RemoteBackedSyncProblemSummary {
  const RemoteBackedSyncProblemSummary({
    this.pendingCount = 0,
    this.syncingCount = 0,
    this.retryableFailedCount = 0,
    this.nonRetryableFailedCount = 0,
    this.noOpCount = 0,
    this.conflictCount = 0,
    this.accessLostCount = 0,
    this.stalePackCount = 0,
    this.firstFailedMutation,
  });

  final int pendingCount;
  final int syncingCount;
  final int retryableFailedCount;
  final int nonRetryableFailedCount;
  final int noOpCount;
  final int conflictCount;
  final int accessLostCount;
  final int stalePackCount;
  final RemoteBackedMutationRecoveryView? firstFailedMutation;

  int get totalProblems =>
      pendingCount +
      syncingCount +
      retryableFailedCount +
      nonRetryableFailedCount +
      noOpCount +
      conflictCount +
      accessLostCount +
      stalePackCount;

  bool get hasRetryableFailures => retryableFailedCount > 0;
}

class RemoteBackedRecoveryClassifier {
  const RemoteBackedRecoveryClassifier._();

  static const retryableErrors = {
    'supabaseConfigMissing',
    'configMissing',
    'remoteAuthRequired',
    'remoteNetworkFailed',
    'networkFailed',
  };

  static const nonRetryableErrors = {
    'remoteRlsRejected',
    'localUserNotPackMember',
    'remoteInviteNotHost',
    'remoteAccessLost',
    'permissionRevoked',
    'missing_remote_item_mapping',
    'malformedRemoteData',
    'invalid_payload',
    'already_completed_remote',
    'already_not_completed',
  };

  static RemoteBackedMutationRecoveryView classifyMutation(
    SyncOutboxEntry mutation, {
    RemotePackSyncMetadataEntry? packMetadata,
    int? localItemId,
  }) {
    final accessLost = isAccessLost(packMetadata);
    if (accessLost) {
      return _view(
        mutation,
        localItemId: localItemId,
        state: RemoteBackedRecoveryState.accessLost,
        kind: RemoteBackedMutationRecoveryKind.accessLost,
        problem: RemoteBackedSyncProblem.accessLost,
        canRetry: false,
        needsRefresh: true,
      );
    }

    return switch (mutation.status) {
      SyncOutboxStatus.pending => _view(
        mutation,
        localItemId: localItemId,
        state: RemoteBackedRecoveryState.pending,
        kind: RemoteBackedMutationRecoveryKind.waitingSync,
        problem: RemoteBackedSyncProblem.waitingSync,
        canRetry: false,
      ),
      SyncOutboxStatus.syncing => _view(
        mutation,
        localItemId: localItemId,
        state: RemoteBackedRecoveryState.syncing,
        kind: RemoteBackedMutationRecoveryKind.waitingSync,
        problem: RemoteBackedSyncProblem.waitingSync,
        canRetry: false,
      ),
      SyncOutboxStatus.synced => _view(
        mutation,
        localItemId: localItemId,
        state: RemoteBackedRecoveryState.synced,
        kind: RemoteBackedMutationRecoveryKind.none,
        problem: RemoteBackedSyncProblem.none,
        canRetry: false,
      ),
      SyncOutboxStatus.failed => _failedView(
        mutation,
        localItemId: localItemId,
      ),
      SyncOutboxStatus.noOp => _view(
        mutation,
        localItemId: localItemId,
        state: RemoteBackedRecoveryState.noOp,
        kind: RemoteBackedMutationRecoveryKind.needsRefresh,
        problem: RemoteBackedSyncProblem.needsRefresh,
        canRetry: false,
        needsRefresh: true,
      ),
      SyncOutboxStatus.conflict => _view(
        mutation,
        localItemId: localItemId,
        state: RemoteBackedRecoveryState.conflict,
        kind: RemoteBackedMutationRecoveryKind.needsRefresh,
        problem: RemoteBackedSyncProblem.needsRefresh,
        canRetry: false,
        needsRefresh: true,
      ),
      SyncOutboxStatus.cancelled => _view(
        mutation,
        localItemId: localItemId,
        state: RemoteBackedRecoveryState.cancelled,
        kind: RemoteBackedMutationRecoveryKind.terminal,
        problem: RemoteBackedSyncProblem.nonRetryableFailure,
        canRetry: false,
      ),
    };
  }

  static bool isAccessLost(RemotePackSyncMetadataEntry? metadata) {
    return metadata?.syncState == RemotePackSyncState.accessLost ||
        metadata?.syncState == RemotePackSyncState.removed ||
        metadata?.currentUserRemoteStatus == RemoteUserStatus.removed;
  }

  static bool isPackStale(RemotePackSyncMetadataEntry? metadata) {
    return metadata?.syncState == RemotePackSyncState.stale ||
        metadata?.syncState == RemotePackSyncState.conflict;
  }

  static String? shortId(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return value.length <= 12 ? value : '${value.substring(0, 8)}...';
  }

  static RemoteBackedMutationRecoveryView _failedView(
    SyncOutboxEntry mutation, {
    int? localItemId,
  }) {
    final error = mutation.lastError;
    final retryable = error != null && retryableErrors.contains(error);
    final knownNonRetryable =
        error == null ||
        nonRetryableErrors.contains(error) ||
        !retryableErrors.contains(error);
    return _view(
      mutation,
      localItemId: localItemId,
      state: retryable
          ? RemoteBackedRecoveryState.retryableFailed
          : RemoteBackedRecoveryState.nonRetryableFailed,
      kind: retryable
          ? RemoteBackedMutationRecoveryKind.retryableFailure
          : RemoteBackedMutationRecoveryKind.nonRetryableFailure,
      problem: retryable
          ? RemoteBackedSyncProblem.retryableFailure
          : RemoteBackedSyncProblem.nonRetryableFailure,
      canRetry: retryable && !knownNonRetryable,
    );
  }

  static RemoteBackedMutationRecoveryView _view(
    SyncOutboxEntry mutation, {
    required RemoteBackedRecoveryState state,
    required RemoteBackedMutationRecoveryKind kind,
    required RemoteBackedSyncProblem problem,
    required bool canRetry,
    int? localItemId,
    bool needsRefresh = false,
  }) {
    return RemoteBackedMutationRecoveryView(
      mutationId: mutation.id,
      localPackId: mutation.localPackId,
      localItemId: localItemId,
      localEntityId: mutation.localEntityId,
      remoteItemId: mutation.remoteEntityId,
      actionType: mutation.actionType,
      status: mutation.status,
      recoveryState: state,
      recoveryKind: kind,
      problem: problem,
      canRetry: canRetry,
      needsRefresh: needsRefresh,
      lastError: mutation.lastError,
    );
  }
}
