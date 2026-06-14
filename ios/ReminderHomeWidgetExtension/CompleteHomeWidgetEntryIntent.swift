import AppIntents
import Foundation

struct CompleteHomeWidgetEntryIntent: AppIntent {
  static var title: LocalizedStringResource = "完成提醒"
  static var openAppWhenRun: Bool = true

  @Parameter(title: "Entry ID")
  var entryId: String

  init() {
    entryId = ""
  }

  init(entryId: String) {
    self.entryId = entryId
  }

  func perform() async throws -> some IntentResult {
    let trimmedEntryId = entryId.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedEntryId.isEmpty {
      _ = ReminderHomeWidgetShared.writePendingAction(
        "complete",
        entryId: trimmedEntryId
      )
      ReminderHomeWidgetShared.reloadWidget()
    } else {
      #if DEBUG
      print("ReminderHomeWidget complete intent ignored blank entry id")
      #endif
    }
    return .result()
  }
}
