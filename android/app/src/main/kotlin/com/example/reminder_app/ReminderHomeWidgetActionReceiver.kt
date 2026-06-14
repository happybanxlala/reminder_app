package com.example.reminder_app

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.util.UUID

class ReminderHomeWidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            actionSwitchTab -> {
                val tab = intent.getStringExtra(extraTabId).orEmpty()
                ReminderHomeWidgetProvider.persistSelectedTab(context, tab)
                ReminderHomeWidgetProvider.updateAll(context)
            }
            actionCompleteEntry -> handleEntryAction(context, intent, "complete")
            actionUndoEntry -> handleEntryAction(context, intent, "undo")
        }
    }

    private fun handleEntryAction(context: Context, intent: Intent, action: String) {
        val entryId = intent.getStringExtra(extraEntryId)
        ReminderHomeWidgetProvider.updateAll(context)
        if (entryId.isNullOrBlank()) {
            return
        }
        persistPendingAction(context, action, entryId)
        try {
            ReminderHomeWidgetProvider.openAppPendingIntent(context).send()
        } catch (_: PendingIntent.CanceledException) {
            // The widget has already refreshed; do not fake action success.
        }
    }

    companion object {
        private const val actionSwitchTab =
            "com.example.reminder_app.homewidget.action.SWITCH_TAB"
        private const val actionCompleteEntry =
            "com.example.reminder_app.homewidget.action.COMPLETE_ENTRY"
        private const val actionUndoEntry =
            "com.example.reminder_app.homewidget.action.UNDO_ENTRY"
        private const val extraTabId = "tabId"
        private const val extraEntryId = "entryId"
        private const val pendingPrefsName = "reminder_home_widget_pending_action"
        private const val pendingActionKey = "pending_action"
        private const val pendingEntryIdKey = "pending_entry_id"
        private const val pendingCreatedAtKey = "pending_action_created_at"
        private const val pendingNonceKey = "pending_action_nonce"

        fun persistPendingAction(context: Context, action: String?, entryId: String?): Boolean {
            if (action.isNullOrBlank() || entryId.isNullOrBlank()) {
                return false
            }
            context
                .getSharedPreferences(pendingPrefsName, Context.MODE_PRIVATE)
                .edit()
                .putString(pendingActionKey, action)
                .putString(pendingEntryIdKey, entryId)
                .putLong(pendingCreatedAtKey, System.currentTimeMillis())
                .putString(pendingNonceKey, UUID.randomUUID().toString())
                .apply()
            return true
        }

        fun readAndClearPendingAction(context: Context): Map<String, Any?>? {
            val prefs = context.getSharedPreferences(pendingPrefsName, Context.MODE_PRIVATE)
            val action = prefs.getString(pendingActionKey, null)
            val entryId = prefs.getString(pendingEntryIdKey, null)
            val createdAt = if (prefs.contains(pendingCreatedAtKey)) {
                prefs.getLong(pendingCreatedAtKey, 0L)
            } else {
                null
            }
            val nonce = prefs.getString(pendingNonceKey, null)
            prefs
                .edit()
                .remove(pendingActionKey)
                .remove(pendingEntryIdKey)
                .remove(pendingCreatedAtKey)
                .remove(pendingNonceKey)
                .apply()
            if (action == null && entryId == null && nonce == null) {
                return null
            }
            return mapOf(
                "action" to action.orEmpty(),
                "entryId" to entryId.orEmpty(),
                "sourcePlatform" to "android",
                "createdAt" to createdAt,
                "nonce" to nonce,
            )
        }

        fun tabPendingIntent(context: Context, tabId: String): PendingIntent {
            val intent = Intent(context, ReminderHomeWidgetActionReceiver::class.java).apply {
                action = actionSwitchTab
                putExtra(extraTabId, tabId)
            }
            return PendingIntent.getBroadcast(
                context,
                "tab:$tabId".hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        fun entryActionPendingIntent(
            context: Context,
            entryId: String,
            entryAction: String,
        ): PendingIntent {
            val receiverAction = when (entryAction) {
                "complete" -> actionCompleteEntry
                "undo" -> actionUndoEntry
                else -> actionCompleteEntry
            }
            val intent = Intent(context, ReminderHomeWidgetActionReceiver::class.java).apply {
                action = receiverAction
                putExtra(extraEntryId, entryId)
            }
            return PendingIntent.getBroadcast(
                context,
                "entry:$entryAction:$entryId".hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
