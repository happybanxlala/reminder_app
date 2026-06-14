package com.example.reminder_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
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
        private const val maxRows = 5
        private const val prefsName = "reminder_home_widget"
        private const val selectedTabKey = "selected_tab"

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
                views.addView(R.id.widget_rows, rowView(context, entry))
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
                snapshot,
                ReminderHomeWidgetTabs.needsHandling,
                selected,
            )
            configureTab(
                context,
                views,
                R.id.widget_tab_attention,
                snapshot,
                ReminderHomeWidgetTabs.attention,
                selected,
            )
            configureTab(
                context,
                views,
                R.id.widget_tab_today_completed,
                snapshot,
                ReminderHomeWidgetTabs.todayCompleted,
                selected,
            )
        }

        private fun configureTab(
            context: Context,
            views: RemoteViews,
            viewId: Int,
            snapshot: ReminderHomeWidgetSnapshot,
            tabId: String,
            selected: String,
        ) {
            val tab = snapshot.tab(tabId)
            val label = tab?.label ?: ReminderHomeWidgetTabs.labelFor(tabId)
            val count = tab?.count ?: 0
            views.setTextViewText(viewId, "$label $count")
            views.setInt(
                viewId,
                "setBackgroundResource",
                if (tabId == selected) {
                    R.drawable.reminder_home_widget_tab_selected
                } else {
                    R.drawable.reminder_home_widget_tab
                },
            )
            views.setOnClickPendingIntent(
                viewId,
                ReminderHomeWidgetActionReceiver.tabPendingIntent(context, tabId),
            )
        }

        private fun rowView(context: Context, entry: ReminderHomeWidgetEntry): RemoteViews {
            val row = RemoteViews(context.packageName, R.layout.reminder_home_widget_row)
            row.setTextViewText(R.id.widget_row_title, entry.title)
            row.setTextViewText(R.id.widget_row_status, entry.statusText)
            if (entry.canAct && !entry.buttonText.isNullOrBlank() && !entry.action.isNullOrBlank()) {
                row.setViewVisibility(R.id.widget_row_action, View.VISIBLE)
                row.setTextViewText(R.id.widget_row_action, entry.buttonText)
                row.setOnClickPendingIntent(
                    R.id.widget_row_action,
                    ReminderHomeWidgetActionReceiver.entryActionPendingIntent(
                        context,
                        entry.entryId,
                        entry.action,
                    ),
                )
            } else {
                row.setViewVisibility(R.id.widget_row_action, View.GONE)
            }
            return row
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
            configureFallbackTab(views, R.id.widget_tab_needs_handling, "需要處理")
            configureFallbackTab(views, R.id.widget_tab_attention, "要留意")
            configureFallbackTab(views, R.id.widget_tab_today_completed, "今天已完成")
        }

        private fun configureFallbackTab(views: RemoteViews, viewId: Int, label: String) {
            views.setTextViewText(viewId, label)
            views.setInt(viewId, "setBackgroundResource", R.drawable.reminder_home_widget_tab)
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
