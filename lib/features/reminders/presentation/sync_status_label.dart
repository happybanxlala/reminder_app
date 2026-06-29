import '../domain/remote_sync.dart';
import 'text/reminder_ui_text.dart';

String? compactRemoteBackedSyncStatusLabel({
  required bool isRemoteBacked,
  required bool isAccessLost,
  required bool hasFailedMutation,
  required bool isStale,
  SyncOutboxStatus? pendingMutationStatus,
  String? lastSyncError,
}) {
  if (!isRemoteBacked) {
    return null;
  }
  if (isAccessLost) {
    return ReminderUiText.syncAccessLostLabel;
  }
  if (hasFailedMutation || (lastSyncError?.trim().isNotEmpty ?? false)) {
    return ReminderUiText.syncFailedLabel;
  }
  if (pendingMutationStatus == SyncOutboxStatus.syncing) {
    return ReminderUiText.syncSyncingLabel;
  }
  if (pendingMutationStatus == SyncOutboxStatus.pending) {
    return ReminderUiText.syncPendingLabel;
  }
  if (isStale) {
    return ReminderUiText.syncNeedsRefreshLabel;
  }
  return null;
}
