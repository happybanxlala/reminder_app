package com.example.reminder_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews

class ReminderHomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    companion object {
        private const val maxRows = 3
        private const val prefsName = "reminder_home_widget"
        private const val selectedTabKey = "selected_tab"
        private const val colorTextSecondary = "#6F6256"
        private const val colorDanger = "#D96B5F"
        private const val colorWarning = "#E09620"
        private const val colorCompleted = "#6F9A55"
        private const val colorResource = "#B98542"
        private const val colorStage = "#7FA77B"

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, ReminderHomeWidgetProvider::class.java)
            updateWidgets(context, manager, manager.getAppWidgetIds(component))
        }

        fun selectedTab(context: Context, snapshot: ReminderHomeWidgetSnapshot): String {
            val stored = context
                .getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                .getString(selectedTabKey, null)
            return when {
                stored != null && ReminderHomeWidgetTabs.isKnown(stored) -> stored
                ReminderHomeWidgetTabs.isKnown(snapshot.selectedTab) -> snapshot.selectedTab
                else -> ReminderHomeWidgetTabs.needsHandling
            }
        }

        fun persistSelectedTab(context: Context, tab: String) {
            if (!ReminderHomeWidgetTabs.isKnown(tab)) {
                return
            }
            context
                .getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                .edit()
                .putString(selectedTabKey, tab)
                .apply()
        }

        private fun updateWidgets(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray,
        ) {
            for (appWidgetId in appWidgetIds) {
                appWidgetManager.updateAppWidget(appWidgetId, buildRemoteViews(context))
            }
        }

        private fun buildRemoteViews(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.reminder_home_widget)
            views.setOnClickPendingIntent(R.id.widget_root, openAppPendingIntent(context))
            views.removeAllViews(R.id.widget_rows)

            when (val result = ReminderHomeWidgetSnapshotReader.read(context)) {
                is ReminderHomeWidgetSnapshotResult.Ready -> renderSnapshot(
                    context,
                    views,
                    result.snapshot,
                )
                is ReminderHomeWidgetSnapshotResult.Unavailable -> renderFallback(
                    context,
                    views,
                    result.reason,
                )
            }

            return views
        }

        private fun renderSnapshot(
            context: Context,
            views: RemoteViews,
            snapshot: ReminderHomeWidgetSnapshot,
        ) {
            val selected = selectedTab(context, snapshot)
            val selectedTab = snapshot.tab(selected) ?: snapshot.tab(ReminderHomeWidgetTabs.needsHandling)
            views.setViewVisibility(R.id.widget_fallback, View.GONE)
            views.setViewVisibility(R.id.widget_rows, View.VISIBLE)
            configureTabs(context, views, snapshot, selected)

            if (selectedTab == null || selectedTab.entries.isEmpty()) {
                val empty = RemoteViews(context.packageName, R.layout.reminder_home_widget_empty)
                empty.setTextViewText(
                    R.id.widget_empty_text,
                    ReminderHomeWidgetTabs.emptyTextFor(selected),
                )
                views.addView(R.id.widget_rows, empty)
                return
            }

            selectedTab.entries.take(maxRows).forEach { entry ->
                views.addView(R.id.widget_rows, rowView(context, entry, selected))
            }
        }

        private fun configureTabs(
            context: Context,
            views: RemoteViews,
            snapshot: ReminderHomeWidgetSnapshot,
            selected: String,
        ) {
            configureTab(
                context,
                views,
                R.id.widget_tab_needs_handling,
                R.id.widget_tab_needs_handling_icon,
                R.id.widget_tab_needs_handling_label,
                R.id.widget_tab_needs_handling_count,
                snapshot,
                ReminderHomeWidgetTabs.needsHandling,
                selected,
            )
            configureTab(
                context,
                views,
                R.id.widget_tab_attention,
                R.id.widget_tab_attention_icon,
                R.id.widget_tab_attention_label,
                R.id.widget_tab_attention_count,
                snapshot,
                ReminderHomeWidgetTabs.attention,
                selected,
            )
            configureTab(
                context,
                views,
                R.id.widget_tab_today_completed,
                R.id.widget_tab_today_completed_icon,
                R.id.widget_tab_today_completed_label,
                R.id.widget_tab_today_completed_count,
                snapshot,
                ReminderHomeWidgetTabs.todayCompleted,
                selected,
            )
        }

        private fun configureTab(
            context: Context,
            views: RemoteViews,
            viewId: Int,
            iconViewId: Int,
            labelViewId: Int,
            countViewId: Int,
            snapshot: ReminderHomeWidgetSnapshot,
            tabId: String,
            selected: String,
        ) {
            val tab = snapshot.tab(tabId)
            val label = tab?.label ?: ReminderHomeWidgetTabs.labelFor(tabId)
            val count = tab?.count ?: 0
            val isSelected = tabId == selected
            val accent = tabAccentColor(tabId)
            views.setTextViewText(labelViewId, label)
            views.setTextViewText(countViewId, count.toString())
            views.setTextColor(labelViewId, Color.parseColor(if (isSelected) accent else colorTextSecondary))
            views.setTextColor(countViewId, Color.parseColor(if (isSelected) accent else colorTextSecondary))
            views.setImageViewResource(iconViewId, tabIcon(tabId))
            views.setInt(iconViewId, "setColorFilter", Color.parseColor(if (isSelected) accent else colorTextSecondary))
            views.setInt(
                viewId,
                "setBackgroundResource",
                if (isSelected) {
                    selectedTabBackground(tabId)
                } else {
                    R.drawable.reminder_home_widget_tab
                },
            )
            views.setOnClickPendingIntent(
                viewId,
                ReminderHomeWidgetActionReceiver.tabPendingIntent(context, tabId),
            )
        }

        private fun rowView(
            context: Context,
            entry: ReminderHomeWidgetEntry,
            selectedTab: String,
        ): RemoteViews {
            val row = RemoteViews(context.packageName, R.layout.reminder_home_widget_row)
            row.setTextViewText(R.id.widget_row_title, entry.title)
            row.setTextViewText(R.id.widget_row_status, entry.statusLine())
            row.setInt(
                R.id.widget_row_accent,
                "setBackgroundResource",
                rowAccentBackground(selectedTab, entry.type),
            )
            configureRowIcon(row, entry)
            configureRowAction(context, row, entry)
            return row
        }

        private fun configureRowIcon(row: RemoteViews, entry: ReminderHomeWidgetEntry) {
            val displayIcon = entry.displayIcon
            if (!displayIcon.isNullOrBlank()) {
                row.setViewVisibility(R.id.widget_row_display_icon, View.VISIBLE)
                row.setViewVisibility(R.id.widget_row_fallback_icon, View.GONE)
                row.setTextViewText(R.id.widget_row_display_icon, displayIcon)
            } else {
                row.setViewVisibility(R.id.widget_row_display_icon, View.GONE)
                row.setViewVisibility(R.id.widget_row_fallback_icon, View.VISIBLE)
                row.setImageViewResource(R.id.widget_row_fallback_icon, rowFallbackIcon(entry.type))
                row.setInt(
                    R.id.widget_row_fallback_icon,
                    "setColorFilter",
                    Color.parseColor(rowFallbackColor(entry.type)),
                )
            }
        }

        private fun configureRowAction(
            context: Context,
            row: RemoteViews,
            entry: ReminderHomeWidgetEntry,
        ) {
            val action = entry.action
            if (entry.canAct && !action.isNullOrBlank()) {
                row.setViewVisibility(R.id.widget_row_action, View.VISIBLE)
                row.setImageViewResource(R.id.widget_row_action, actionIcon(action))
                row.setInt(R.id.widget_row_action, "setBackgroundResource", actionBackground(action))
                row.setInt(R.id.widget_row_action, "setColorFilter", Color.parseColor(actionColor(action)))
                if (action == "complete" || action == "undo") {
                    row.setOnClickPendingIntent(
                        R.id.widget_row_action,
                        ReminderHomeWidgetActionReceiver.entryActionPendingIntent(
                            context,
                            entry.entryId,
                            action,
                        ),
                    )
                } else {
                    row.setOnClickPendingIntent(
                        R.id.widget_row_action,
                        openAppPendingIntent(context),
                    )
                }
            } else {
                row.setViewVisibility(R.id.widget_row_action, View.GONE)
            }
        }

        private fun ReminderHomeWidgetEntry.statusLine(): String {
            val sync = syncLabel?.takeIf { it.isNotBlank() }
            return if (sync == null) {
                statusText
            } else {
                "$statusText · $sync"
            }
        }

        private fun renderFallback(
            context: Context,
            views: RemoteViews,
            reason: ReminderHomeWidgetSnapshotProblem,
        ) {
            views.setViewVisibility(R.id.widget_rows, View.GONE)
            views.setViewVisibility(R.id.widget_fallback, View.VISIBLE)
            views.setTextViewText(R.id.widget_fallback_title, fallbackTitle(reason))
            views.setTextViewText(R.id.widget_fallback_body, "打開 app 以更新主畫面 widget。")
            views.setOnClickPendingIntent(R.id.widget_fallback_button, openAppPendingIntent(context))
            configureFallbackTab(
                views,
                R.id.widget_tab_needs_handling,
                R.id.widget_tab_needs_handling_icon,
                R.id.widget_tab_needs_handling_label,
                R.id.widget_tab_needs_handling_count,
                ReminderHomeWidgetTabs.needsHandling,
            )
            configureFallbackTab(
                views,
                R.id.widget_tab_attention,
                R.id.widget_tab_attention_icon,
                R.id.widget_tab_attention_label,
                R.id.widget_tab_attention_count,
                ReminderHomeWidgetTabs.attention,
            )
            configureFallbackTab(
                views,
                R.id.widget_tab_today_completed,
                R.id.widget_tab_today_completed_icon,
                R.id.widget_tab_today_completed_label,
                R.id.widget_tab_today_completed_count,
                ReminderHomeWidgetTabs.todayCompleted,
            )
        }

        private fun configureFallbackTab(
            views: RemoteViews,
            viewId: Int,
            iconViewId: Int,
            labelViewId: Int,
            countViewId: Int,
            tabId: String,
        ) {
            views.setTextViewText(labelViewId, ReminderHomeWidgetTabs.labelFor(tabId))
            views.setTextViewText(countViewId, "0")
            views.setTextColor(labelViewId, Color.parseColor(colorTextSecondary))
            views.setTextColor(countViewId, Color.parseColor(colorTextSecondary))
            views.setImageViewResource(iconViewId, tabIcon(tabId))
            views.setInt(iconViewId, "setColorFilter", Color.parseColor(colorTextSecondary))
            views.setInt(viewId, "setBackgroundResource", R.drawable.reminder_home_widget_tab)
        }

        private fun selectedTabBackground(tabId: String): Int {
            return when (tabId) {
                ReminderHomeWidgetTabs.needsHandling -> R.drawable.reminder_home_widget_tab_danger
                ReminderHomeWidgetTabs.attention -> R.drawable.reminder_home_widget_tab_warning
                ReminderHomeWidgetTabs.todayCompleted -> R.drawable.reminder_home_widget_tab_completed
                else -> R.drawable.reminder_home_widget_tab_selected
            }
        }

        private fun tabIcon(tabId: String): Int {
            return when (tabId) {
                ReminderHomeWidgetTabs.needsHandling -> R.drawable.reminder_home_widget_ic_warning
                ReminderHomeWidgetTabs.attention -> R.drawable.reminder_home_widget_ic_eye
                ReminderHomeWidgetTabs.todayCompleted -> R.drawable.reminder_home_widget_ic_check_circle
                else -> R.drawable.reminder_home_widget_ic_check_circle
            }
        }

        private fun tabAccentColor(tabId: String): String {
            return when (tabId) {
                ReminderHomeWidgetTabs.needsHandling -> colorDanger
                ReminderHomeWidgetTabs.attention -> colorWarning
                ReminderHomeWidgetTabs.todayCompleted -> colorCompleted
                else -> colorTextSecondary
            }
        }

        private fun rowAccentBackground(selectedTab: String, type: String): Int {
            if (selectedTab == ReminderHomeWidgetTabs.needsHandling) {
                return R.drawable.reminder_home_widget_accent_danger
            }
            if (selectedTab == ReminderHomeWidgetTabs.attention) {
                return R.drawable.reminder_home_widget_accent_warning
            }
            return when (type) {
                "completedResource" -> R.drawable.reminder_home_widget_accent_resource
                "completedStage" -> R.drawable.reminder_home_widget_accent_stage
                else -> R.drawable.reminder_home_widget_accent_completed
            }
        }

        private fun rowFallbackIcon(type: String): Int {
            return when (type) {
                "resourceAttention", "completedResource" -> R.drawable.reminder_home_widget_ic_resource
                "completedStage" -> R.drawable.reminder_home_widget_ic_stage
                "completedItem" -> R.drawable.reminder_home_widget_ic_check_circle
                else -> R.drawable.reminder_home_widget_ic_checklist
            }
        }

        private fun rowFallbackColor(type: String): String {
            return when (type) {
                "resourceAttention", "completedResource" -> colorResource
                "completedStage" -> colorStage
                "completedItem" -> colorCompleted
                else -> "#D9852B"
            }
        }

        private fun actionIcon(action: String): Int {
            return when (action) {
                "undo" -> R.drawable.reminder_home_widget_ic_undo
                "add" -> R.drawable.reminder_home_widget_ic_plus
                else -> R.drawable.reminder_home_widget_ic_check
            }
        }

        private fun actionBackground(action: String): Int {
            return when (action) {
                "undo" -> R.drawable.reminder_home_widget_action_undo
                "add" -> R.drawable.reminder_home_widget_action_add
                else -> R.drawable.reminder_home_widget_action_check
            }
        }

        private fun actionColor(action: String): String {
            return when (action) {
                "undo" -> "#B86712"
                "add" -> colorResource
                else -> colorCompleted
            }
        }

        private fun fallbackTitle(reason: ReminderHomeWidgetSnapshotProblem): String {
            return when (reason) {
                ReminderHomeWidgetSnapshotProblem.Missing -> "尚未有 widget 資料"
                ReminderHomeWidgetSnapshotProblem.Corrupt -> "widget 資料讀取失敗"
                ReminderHomeWidgetSnapshotProblem.UnsupportedSchema -> "widget 資料需要更新"
                ReminderHomeWidgetSnapshotProblem.Stale -> "widget 資料已過期"
            }
        }

        fun openAppPendingIntent(
            context: Context,
            action: String? = null,
            entryId: String? = null,
        ): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
                action?.let { putExtra("homeWidgetAction", it) }
                entryId?.let { putExtra("homeWidgetEntryId", it) }
            }
            val requestCode = ("open:${action.orEmpty()}:$entryId").hashCode()
            return PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
