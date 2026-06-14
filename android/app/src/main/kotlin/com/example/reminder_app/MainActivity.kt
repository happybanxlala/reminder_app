package com.example.reminder_app

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var homeWidgetChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        homeWidgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            homeWidgetChannelName,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "readAndClearPendingAction" -> {
                        result.success(
                            ReminderHomeWidgetActionReceiver.readAndClearPendingAction(this),
                        )
                    }
                    "reloadHomeWidgets" -> {
                        ReminderHomeWidgetProvider.updateAll(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        persistPendingActionFromIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (persistPendingActionFromIntent(intent)) {
            homeWidgetChannel?.invokeMethod("homeWidgetPendingActionAvailable", null)
        }
    }

    override fun onResume() {
        super.onResume()
        ReminderHomeWidgetProvider.updateAll(this)
    }

    override fun onPause() {
        ReminderHomeWidgetProvider.updateAll(this)
        super.onPause()
    }

    private fun persistPendingActionFromIntent(intent: Intent?): Boolean {
        val action = intent?.getStringExtra(homeWidgetActionExtra)
        val entryId = intent?.getStringExtra(homeWidgetEntryIdExtra)
        val persisted = ReminderHomeWidgetActionReceiver.persistPendingAction(this, action, entryId)
        if (persisted) {
            intent?.removeExtra(homeWidgetActionExtra)
            intent?.removeExtra(homeWidgetEntryIdExtra)
        }
        return persisted
    }

    companion object {
        private const val homeWidgetChannelName = "reminder_app/home_widget"
        private const val homeWidgetActionExtra = "homeWidgetAction"
        private const val homeWidgetEntryIdExtra = "homeWidgetEntryId"
    }
}
