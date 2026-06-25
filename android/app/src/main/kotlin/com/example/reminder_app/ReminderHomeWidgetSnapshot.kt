package com.example.reminder_app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.time.Duration
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeParseException

data class ReminderHomeWidgetSnapshot(
    val schemaVersion: Int,
    val updatedAt: Instant?,
    val selectedTab: String,
    val tabs: List<ReminderHomeWidgetTab>,
) {
    fun tab(id: String): ReminderHomeWidgetTab? = tabs.firstOrNull { it.id == id }
}

data class ReminderHomeWidgetTab(
    val id: String,
    val label: String,
    val count: Int,
    val entries: List<ReminderHomeWidgetEntry>,
)

data class ReminderHomeWidgetEntry(
    val entryId: String,
    val type: String,
    val targetId: Int?,
    val actionRecordId: Int?,
    val title: String,
    val statusText: String,
    val displayIcon: String?,
    val buttonText: String?,
    val action: String?,
    val canAct: Boolean,
    val isRemoteBacked: Boolean,
    val syncLabel: String?,
    val syncStatus: String,
    val hasPendingMutation: Boolean,
    val pendingAction: String?,
    val actionDisabledReason: String?,
)

sealed class ReminderHomeWidgetSnapshotResult {
    data class Ready(val snapshot: ReminderHomeWidgetSnapshot) : ReminderHomeWidgetSnapshotResult()
    data class Unavailable(val reason: ReminderHomeWidgetSnapshotProblem) : ReminderHomeWidgetSnapshotResult()
}

enum class ReminderHomeWidgetSnapshotProblem {
    Missing,
    Corrupt,
    UnsupportedSchema,
    Stale,
}

object ReminderHomeWidgetSnapshotReader {
    private const val snapshotFileName = "home_widget_snapshot.json"
    private const val supportedSchemaVersion = 1
    private val staleAfter = Duration.ofHours(24)

    fun read(context: Context, now: Instant = Instant.now()): ReminderHomeWidgetSnapshotResult {
        val file = File(context.filesDir, snapshotFileName)
        if (!file.exists()) {
            return ReminderHomeWidgetSnapshotResult.Unavailable(
                ReminderHomeWidgetSnapshotProblem.Missing,
            )
        }

        val snapshot = try {
            parse(file.readText())
        } catch (_: Exception) {
            return ReminderHomeWidgetSnapshotResult.Unavailable(
                ReminderHomeWidgetSnapshotProblem.Corrupt,
            )
        }

        if (snapshot.schemaVersion != supportedSchemaVersion) {
            return ReminderHomeWidgetSnapshotResult.Unavailable(
                ReminderHomeWidgetSnapshotProblem.UnsupportedSchema,
            )
        }

        val updatedAt = snapshot.updatedAt
        if (updatedAt == null || Duration.between(updatedAt, now) > staleAfter) {
            return ReminderHomeWidgetSnapshotResult.Unavailable(
                ReminderHomeWidgetSnapshotProblem.Stale,
            )
        }

        return ReminderHomeWidgetSnapshotResult.Ready(snapshot)
    }

    fun parse(source: String): ReminderHomeWidgetSnapshot {
        val json = JSONObject(source)
        return ReminderHomeWidgetSnapshot(
            schemaVersion = json.optInt("schemaVersion", supportedSchemaVersion),
            updatedAt = parseInstant(json.optString("updatedAt", "")),
            selectedTab = json.optString("selectedTab", ReminderHomeWidgetTabs.needsHandling),
            tabs = parseTabs(json.optJSONArray("tabs") ?: JSONArray()),
        )
    }

    private fun parseTabs(tabsJson: JSONArray): List<ReminderHomeWidgetTab> {
        return buildList {
            for (index in 0 until tabsJson.length()) {
                val tabJson = tabsJson.optJSONObject(index) ?: continue
                val id = tabJson.optString("id", "")
                add(
                    ReminderHomeWidgetTab(
                        id = id,
                        label = tabJson.optString("label", ReminderHomeWidgetTabs.labelFor(id)),
                        count = tabJson.optInt("count", 0),
                        entries = parseEntries(tabJson.optJSONArray("entries") ?: JSONArray()),
                    ),
                )
            }
        }
    }

    private fun parseEntries(entriesJson: JSONArray): List<ReminderHomeWidgetEntry> {
        return buildList {
            for (index in 0 until entriesJson.length()) {
                val entryJson = entriesJson.optJSONObject(index) ?: continue
                add(
                    ReminderHomeWidgetEntry(
                        entryId = entryJson.optString("entryId", ""),
                        type = entryJson.optString("type", ""),
                        targetId = entryJson.optionalInt("targetId"),
                        actionRecordId = entryJson.optionalInt("actionRecordId"),
                        title = entryJson.optString("title", ""),
                        statusText = entryJson.optString("statusText", ""),
                        displayIcon = entryJson.optionalString("displayIcon"),
                        buttonText = entryJson.optionalString("buttonText"),
                        action = entryJson.optionalString("action"),
                        canAct = entryJson.optBoolean("canAct", false),
                        isRemoteBacked = entryJson.optBoolean("isRemoteBacked", false),
                        syncLabel = entryJson.optionalString("syncLabel"),
                        syncStatus = entryJson.optString("syncStatus", "none"),
                        hasPendingMutation = entryJson.optBoolean("hasPendingMutation", false),
                        pendingAction = entryJson.optionalString("pendingAction"),
                        actionDisabledReason = entryJson.optionalString("actionDisabledReason"),
                    ),
                )
            }
        }
    }

    private fun parseInstant(value: String): Instant? {
        if (value.isBlank()) {
            return null
        }
        return try {
            Instant.parse(value)
        } catch (_: DateTimeParseException) {
            try {
                LocalDateTime.parse(value).atZone(ZoneId.systemDefault()).toInstant()
            } catch (_: DateTimeParseException) {
                null
            }
        }
    }

    private fun JSONObject.optionalString(name: String): String? {
        if (!has(name) || isNull(name)) {
            return null
        }
        return optString(name)
    }

    private fun JSONObject.optionalInt(name: String): Int? {
        if (!has(name) || isNull(name)) {
            return null
        }
        return optInt(name)
    }
}

object ReminderHomeWidgetTabs {
    const val needsHandling = "needsHandling"
    const val attention = "attention"
    const val todayCompleted = "todayCompleted"

    val all = listOf(needsHandling, attention, todayCompleted)

    fun isKnown(value: String): Boolean = value in all

    fun labelFor(value: String): String {
        return when (value) {
            needsHandling -> "需要處理"
            attention -> "要留意"
            todayCompleted -> "今天已完成"
            else -> "需要處理"
        }
    }

    fun emptyTextFor(value: String): String {
        return when (value) {
            needsHandling -> "沒有需要處理"
            attention -> "沒有要留意"
            todayCompleted -> "今天還未完成事項"
            else -> "沒有需要處理"
        }
    }
}
